import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Estructura de las cabeceras CORS para permitir llamadas desde Flutter Web/Escritorio
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  // Manejar la petición de pre-vuelo (CORS)
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Faltan variables de configuración en el servidor.");
    }

    // Recibir parámetros desde Flutter
    const { institution_id, saas_plan_id, payer_email } = await req.json();

    if (!institution_id || !saas_plan_id || !payer_email) {
      throw new Error("Faltan parámetros requeridos: institution_id, saas_plan_id, payer_email.");
    }

    // Inicializar el cliente de Supabase con la clave service_role para ignorar las políticas RLS
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Obtener los datos reales del plan desde la base de datos
    const { data: plan, error: planError } = await supabase
      .from("saas_plans")
      .select("*")
      .eq("id", saas_plan_id)
      .eq("is_active", true)
      .single();

    if (planError || !plan) {
      console.error("Error al obtener plan:", planError);
      throw new Error(`El plan seleccionado no es válido o no existe. ID: ${saas_plan_id}`);
    }

    // 2. Crear la suscripción (Preapproval) en la API de Mercado Pago
    // En sandbox (TEST-...) MP requiere que el payer_email sea el de una cuenta de prueba de tipo
    // Comprador creada en el panel de MP. En producción se usa el email real del usuario.
    const isSandbox = MP_ACCESS_TOKEN.startsWith("TEST-");
    const MP_TEST_PAYER_EMAIL = Deno.env.get("MP_TEST_PAYER_EMAIL");
    const effectivePayerEmail = isSandbox && MP_TEST_PAYER_EMAIL
      ? MP_TEST_PAYER_EMAIL
      : payer_email;

    if (isSandbox && !MP_TEST_PAYER_EMAIL) {
      console.warn(
        "AVISO: Token de prueba detectado pero MP_TEST_PAYER_EMAIL no está configurado. " +
        "Esto puede causar error 'Both payer and collector must be real or test users'. " +
        "Configurá el secret MP_TEST_PAYER_EMAIL con el email del usuario Comprador de prueba de MP."
      );
    }

    const idempotencyKey = `${institution_id}-${saas_plan_id}-${Date.now()}`;

    // DEBUG TEMPORAL: ver qué email se está usando
    console.log(`[DEBUG] isSandbox=${isSandbox} | MP_TEST_PAYER_EMAIL_defined=${!!MP_TEST_PAYER_EMAIL} | effectivePayerEmail=${effectivePayerEmail} | original_payer_email=${payer_email}`);

    const mpResponse = await fetch("https://api.mercadopago.com/preapproval", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
        "X-Idempotency-Key": idempotencyKey,
      },
      body: JSON.stringify({
        // payer_email: el email real del usuario logueado.
        // IMPORTANTE: con token de producción (APP_USR-...) NO usar emails de test users de MP.
        // Con token de test (TEST-...) usar email de test buyer creado en el panel de MP Argentina.
        payer_email: effectivePayerEmail,
        reason: `Suscripción Chimpancé: ${plan.name}`,
        auto_recurring: {
          frequency: 1,
          frequency_type: "months",
          transaction_amount: plan.price,
          currency_id: plan.currency,
        },
        back_url: "https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/mp-webhook",
        external_reference: institution_id,
      }),
    });

    const mpData = await mpResponse.json();

    if (!mpResponse.ok) {
      console.error("Error de Mercado Pago:", mpData);
      const mpErrorMsg = mpData?.message || mpData?.error || JSON.stringify(mpData);
      throw new Error(
        `Error de Mercado Pago (${mpResponse.status}): ${mpErrorMsg} | [DEBUG] isSandbox=${isSandbox} MP_TEST_EMAIL_defined=${!!MP_TEST_PAYER_EMAIL} effectiveEmail=${effectivePayerEmail}`
      );
    }

    // 3. Registrar o actualizar la suscripción como 'pending'
    // Se usa upsert debido a la restricción UNIQUE que pusimos en la tabla
    const { error: dbError } = await supabase
      .from("tenant_subscriptions")
      .upsert({
        institution_id,
        saas_plan_id,
        status: "pending",
        mp_preapproval_id: mpData.id,
      }, { onConflict: "institution_id" });

    if (dbError) {
      console.error("Error al guardar suscripción en BD:", dbError);
      throw new Error(`Error en base de datos: ${dbError.message}`);
    }

    // Retornar el punto de inicio del checkout para que Flutter lo abra
    return new Response(
      JSON.stringify({
        init_point: mpData.init_point,
        sandbox_init_point: mpData.sandbox_init_point,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
