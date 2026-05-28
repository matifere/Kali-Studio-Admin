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
      throw new Error("Faltan parámetros: institution_id, saas_plan_id.");
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Obtener datos del plan
    const { data: plan, error: planError } = await supabase
      .from("saas_plans")
      .select("*")
      .eq("id", saas_plan_id)
      .single();

    if (planError || !plan) {
      throw new Error("El plan seleccionado no es válido o no existe.");
    }

    // 2. Crear preferencia de pago via Checkout Pro.
    // Este endpoint es el estándar de MP, funciona en sandbox y producción
    // sin restricciones de permisos adicionales.
    const webhookUrl = `${SUPABASE_URL}/functions/v1/mp-webhook`;

    const mpResponse = await fetch(
      "https://api.mercadopago.com/checkout/preferences",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          items: [
            {
              id: saas_plan_id,
              title: `Suscripción Chimpancé: ${plan.name}`,
              description: plan.description ?? "",
              quantity: 1,
              unit_price: Number(plan.price),
              currency_id: plan.currency ?? "ARS",
            },
          ],
          back_urls: {
            success: webhookUrl,
            failure: webhookUrl,
            pending: webhookUrl,
          },
          auto_return: "approved",
          notification_url: webhookUrl,
          external_reference: institution_id,
          statement_descriptor: "Chimpance SaaS",
        }),
      },
    );

    const mpData = await mpResponse.json();

    if (!mpResponse.ok) {
      throw new Error(`MP ${mpResponse.status}: ${JSON.stringify(mpData)}`);
    }

    // 3. Registrar el intento de pago como 'pending'
    const { error: dbError } = await supabase
      .from("tenant_subscriptions")
      .upsert(
        {
          institution_id,
          saas_plan_id,
          status: "pending",
          mp_preapproval_id: mpData.id,
        },
        { onConflict: "institution_id" },
      );

    if (dbError) {
      throw new Error(`Error en base de datos: ${dbError.message}`);
    }

    // 4. Devolver los links de checkout
    // sandbox_init_point: checkout de pruebas (sin cobro real)
    // init_point: checkout de producción
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
