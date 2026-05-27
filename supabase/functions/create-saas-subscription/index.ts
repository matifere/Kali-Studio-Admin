import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
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

    const { institution_id, saas_plan_id } = await req.json();

    if (!institution_id || !saas_plan_id) {
      throw new Error(
        "Faltan parámetros requeridos: institution_id, saas_plan_id.",
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Obtener los datos del plan desde la base de datos
    const { data: plan, error: planError } = await supabase
      .from("saas_plans")
      .select("*")
      .eq("id", saas_plan_id)
      .eq("is_active", true)
      .single();

    if (planError || !plan) {
      throw new Error(
        `El plan seleccionado no es válido o no existe. ID: ${saas_plan_id}`,
      );
    }

    // 2. Crear la suscripción (Preapproval) en Mercado Pago.
    // Flujo: "suscripción sin plan asociado con pago pendiente".
    // MP devuelve un init_point (checkout web) donde el comprador
    // ingresa su medio de pago. No se requiere card_token_id ni payer_email.
    const idempotencyKey = `${institution_id}-${saas_plan_id}-${Date.now()}`;

    // El header X-scope: stage es requerido por MP para el entorno sandbox (tokens TEST-).
    const isSandbox = MP_ACCESS_TOKEN.startsWith("TEST-");
    const mpHeaders: Record<string, string> = {
      "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
      "Content-Type": "application/json",
      "X-Idempotency-Key": idempotencyKey,
    };
    if (isSandbox) {
      mpHeaders["X-scope"] = "stage";
    }

    const mpResponse = await fetch("https://api.mercadopago.com/preapproval", {
      method: "POST",
      headers: mpHeaders,
      body: JSON.stringify({
        reason: `Suscripción Chimpancé: ${plan.name}`,
        auto_recurring: {
          frequency: 1,
          frequency_type: "months",
          transaction_amount: plan.price,
          currency_id: plan.currency,
        },
        back_url:
          "https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/mp-webhook",
        external_reference: institution_id,
      }),
    });

    const mpData = await mpResponse.json();

    if (!mpResponse.ok) {
      // Mostrar el JSON completo de MP para diagnóstico
      throw new Error(
        `MP ${mpResponse.status}: ${JSON.stringify(mpData)}`,
      );
    }

    // 3. Registrar la suscripción como 'pending' en la base de datos
    const { error: dbError } = await supabase
      .from("tenant_subscriptions")
      .upsert({
        institution_id,
        saas_plan_id,
        status: "pending",
        mp_preapproval_id: mpData.id,
      }, { onConflict: "institution_id" });

    if (dbError) {
      throw new Error(`Error en base de datos: ${dbError.message}`);
    }

    // 4. Devolver el init_point al cliente para abrir el checkout
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
