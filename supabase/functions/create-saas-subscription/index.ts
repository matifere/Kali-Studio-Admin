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

    // Inicializar el cliente de Supabase con la clave service_role para ignorar las políticas RLS
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Obtener los datos reales del plan desde la base de datos
    const { data: plan, error: planError } = await supabase
      .from("saas_plans")
      .select("*")
      .eq("id", saas_plan_id)
      .single();

    if (planError || !plan) {
      throw new Error("El plan seleccionado no es válido o no existe.");
    }

    // 2. Crear la suscripción (Preapproval) en la API de Mercado Pago
    const mpResponse = await fetch("https://api.mercadopago.com/preapproval", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        reason: `Suscripción: ${plan.name}`,
        auto_recurring: {
          frequency: 1,
          frequency_type: "months",
          transaction_amount: plan.price,
          currency_id: plan.currency,
        },
        payer_email: payer_email,
        back_url: "https://tu-aplicacion.com/dashboard", // URL de retorno para el usuario
        external_reference: institution_id, // Asociamos el pago con el ID de la institución para el Webhook
      }),
    });

    const mpData = await mpResponse.json();

    if (!mpResponse.ok) {
      throw new Error(
        mpData.message || "Error al comunicarse con Mercado Pago.",
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
      throw new Error(`Error en base de datos: ${dbError.message}`);
    }

    // Retornar el punto de inicio del checkout para que Flutter lo abra
    return new Response(
      JSON.stringify({ init_point: mpData.init_point }),
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
