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

    // 1. Obtener datos del plan de nuestra DB
    const { data: plan, error: planError } = await supabase
      .from("saas_plans")
      .select("*")
      .eq("id", saas_plan_id)
      .single();

    if (planError || !plan) {
      throw new Error("El plan seleccionado no es válido o no existe.");
    }

    // 2. Crear un preapproval_plan en MP con el institution_id codificado en back_url.
    //
    // Usamos preapproval_plan directamente (sin preapproval individual) porque
    // el endpoint /preapproval requiere permisos adicionales en cuentas de prueba.
    //
    // El institution_id se pasa en el back_url para que el webhook pueda
    // identificar qué institución completó la suscripción.
    const webhookUrl = `${SUPABASE_URL}/functions/v1/mp-webhook`;
    const backUrl = `${webhookUrl}?institution_id=${encodeURIComponent(institution_id)}&saas_plan_id=${encodeURIComponent(saas_plan_id)}`;

    const mpRes = await fetch("https://api.mercadopago.com/preapproval_plan", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        reason: `Suscripción Chimpancé: ${plan.name}`,
        auto_recurring: {
          frequency: 1,
          frequency_type: "months",
          transaction_amount: Number(plan.price),
          currency_id: plan.currency ?? "ARS",
        },
        back_url: backUrl,
        external_reference: institution_id,
      }),
    });

    const mpData = await mpRes.json();

    if (!mpRes.ok) {
      throw new Error(
        `MP preapproval_plan ${mpRes.status}: ${JSON.stringify(mpData)}`,
      );
    }

    console.log(
      `[create-sub] Plan creado: ${mpData.id} init_point=${mpData.init_point}`,
    );

    // 3. Registrar el intento de suscripción como 'pending' si no está activa.
    // Si ya está activa (upgrade), no sobreescribimos el mp_preapproval_id 
    // para poder cancelarlo cuando el usuario pague el nuevo.
    const { data: currentSub } = await supabase
      .from("tenant_subscriptions")
      .select("status")
      .eq("institution_id", institution_id)
      .maybeSingle();

    if (currentSub?.status !== "active") {
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
    }

    // 4. Devolver el init_point del plan al cliente
    return new Response(
      JSON.stringify({
        init_point: mpData.init_point,
        sandbox_init_point: mpData.init_point, // mismo link, MP detecta el entorno
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error("[create-sub] Error:", errorMessage);
    return new Response(
      JSON.stringify({ error: errorMessage }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
