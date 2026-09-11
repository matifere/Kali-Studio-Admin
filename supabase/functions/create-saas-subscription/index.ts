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

    // La función corre con verify_jwt=false: validamos acá que el caller sea
    // el sudo de la institución. Sin esto, cualquiera podría upsertear una
    // tenant_subscription 'pending' (que AuthWrapper acepta como válida) para
    // una institución arbitraria.
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    const { data: userData, error: userError } = await supabase.auth.getUser(token);
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: "No autorizado" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: callerProfile } = await supabase
      .from("profiles")
      .select("role, institution_id")
      .eq("id", userData.user.id)
      .maybeSingle();

    if (
      !callerProfile ||
      callerProfile.role !== "sudo" ||
      String(callerProfile.institution_id) !== String(institution_id)
    ) {
      return new Response(JSON.stringify({ error: "No tenés permisos sobre esta institución" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 1. Obtener datos del plan de nuestra DB
    const { data: plan, error: planError } = await supabase
      .from("saas_plans")
      .select("*")
      .eq("id", saas_plan_id)
      .single();

    if (planError || !plan) {
      throw new Error("El plan seleccionado no es válido o no existe.");
    }

    // === DETECCIÓN DE DOWNGRADE DE FUNCIONALIDADES ===
    let isDowngrade = false;
    const { data: currentSub } = await supabase
      .from("tenant_subscriptions")
      .select("status, mp_preapproval_id, saas_plans!saas_plan_id(features)")
      .eq("institution_id", institution_id)
      .maybeSingle();

    if (currentSub?.status === "active") {
      // Comparar features para ver si pierde alguna
      const oldFeatures = currentSub.saas_plans?.features || {};
      const newFeatures = plan.features || {};
      for (const [key, value] of Object.entries(oldFeatures)) {
        if (value === true && newFeatures[key] !== true) {
          isDowngrade = true;
          break;
        }
      }
    }

    if (isDowngrade) {
      console.log(`[create-saas-subscription] Downgrade de features detectado.`);
      
      if (currentSub.mp_preapproval_id && !currentSub.mp_preapproval_id.startsWith("test_bypass")) {
        console.log(`[create-saas-subscription] Cancelando MP para programar downgrade: ${currentSub.mp_preapproval_id}`);
        try {
          await fetch(`https://api.mercadopago.com/preapproval/${currentSub.mp_preapproval_id}`, {
            method: "PUT",
            headers: { "Authorization": `Bearer ${MP_ACCESS_TOKEN}`, "Content-Type": "application/json" },
            body: JSON.stringify({ status: "cancelled" })
          });
        } catch (e) {
          console.error("Error al cancelar MP en downgrade:", e);
        }
      }

      const { error: dbError } = await supabase
        .from("tenant_subscriptions")
        .update({
          next_saas_plan_id: saas_plan_id,
        })
        .eq("institution_id", institution_id);

      if (dbError) throw new Error(dbError.message);

      return new Response(
        JSON.stringify({
          init_point: null,
          status: "downgrade_scheduled",
          message: "El plan actual seguirá activo hasta tu próxima facturación, luego pasarás al nuevo plan."
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    // =================================================

    // 2. Manejo de planes gratuitos (evita error en Mercado Pago)
    if (Number(plan.price) === 0) {
      // Verificamos si el usuario tenía una suscripción de pago y la cancelamos en MP
      const { data: oldSub } = await supabase
        .from("tenant_subscriptions")
        .select("mp_preapproval_id, status")
        .eq("institution_id", institution_id)
        .maybeSingle();

      if (oldSub?.status === "active" && oldSub.mp_preapproval_id) {
        console.log(`[create-saas-subscription] Downgrade a GRATIS. Cancelando MP: ${oldSub.mp_preapproval_id}`);
        try {
          const cancelRes = await fetch(`https://api.mercadopago.com/preapproval/${oldSub.mp_preapproval_id}`, {
            method: "PUT",
            headers: {
              "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
              "Content-Type": "application/json"
            },
            body: JSON.stringify({ status: "cancelled" })
          });
          if (!cancelRes.ok) {
            console.error(`Error cancelando en MP: ${cancelRes.status} ${await cancelRes.text()}`);
          }
        } catch (err) {
          console.error("Error en fetch de cancelación:", err);
        }
      }

      const { error: dbError } = await supabase
        .from("tenant_subscriptions")
        .upsert(
          {
            institution_id,
            saas_plan_id,
            status: "active",
            mp_preapproval_id: null,
            current_period_end: new Date(new Date().setFullYear(new Date().getFullYear() + 10)).toISOString(), // Vencimiento en 10 años
          },
          { onConflict: "institution_id" },
        );

      if (dbError) {
        throw new Error(`Error en base de datos al activar plan gratuito: ${dbError.message}`);
      }

      return new Response(
        JSON.stringify({
          init_point: null,
          status: "active",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // === MODO PRUEBAS: SALTAR MERCADO PAGO PARA PLANES PAGOS ===
    const SKIP_MP_TESTING = false; // CAMBIAR A FALSE EN PRODUCCIÓN

    if (SKIP_MP_TESTING && Number(plan.price) > 0) {
      console.log(`[create-saas-subscription] BYPASS MODO PRUEBAS: Activando plan ${plan.name} sin cobrar.`);
      
      const { data: oldSub } = await supabase
        .from("tenant_subscriptions")
        .select("mp_preapproval_id, status")
        .eq("institution_id", institution_id)
        .maybeSingle();

      if (oldSub?.status === "active" && oldSub.mp_preapproval_id) {
        // En pruebas no hace falta cancelar en MP real si saltamos MP, pero lo dejamos por consistencia
        console.log(`[create-saas-subscription] Cancelando MP viejo en modo pruebas: ${oldSub.mp_preapproval_id}`);
      }

      const { error: dbError } = await supabase
        .from("tenant_subscriptions")
        .upsert(
          {
            institution_id,
            saas_plan_id,
            status: "active",
            mp_preapproval_id: "test_bypass_paid_" + Date.now(),
            current_period_end: new Date(new Date().setFullYear(new Date().getFullYear() + 10)).toISOString(),
          },
          { onConflict: "institution_id" },
        );

      if (dbError) throw new Error(`Error en BD al activar plan de pruebas: ${dbError.message}`);

      return new Response(
        JSON.stringify({
          init_point: null,
          status: "active",
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }
    // ==============================================================

    // 3. Crear un preapproval_plan en MP con el institution_id codificado en back_url.
    //
    // Usamos preapproval_plan directamente (sin preapproval individual) porque
    // el endpoint /preapproval requiere permisos adicionales en cuentas de prueba.
    //
    // El institution_id se pasa en el back_url para que el webhook pueda
    // identificar qué institución completó la suscripción.
    // MercadoPago no acepta URLs locales o HTTP. Usamos un dominio válido como fallback en local.
    let baseUrl = Deno.env.get("SUPABASE_PUBLIC_URL") || SUPABASE_URL;
    if (!baseUrl.startsWith("https://")) {
      baseUrl = "https://dbturnos.argity.com";
    }
    const webhookUrl = `${baseUrl}/functions/v1/mp-webhook`;
    const backUrl = `${webhookUrl}?institution_id=${encodeURIComponent(institution_id)}&saas_plan_id=${encodeURIComponent(saas_plan_id)}`;

    const mpRes = await fetch("https://api.mercadopago.com/preapproval_plan", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        reason: `Suscripción ArgityTurnos: ${plan.name}`,
        auto_recurring: {
          frequency: plan.interval === "year" || plan.billing_cycle === "yearly" || plan.name?.toLowerCase().includes("anual") ? 12 : 1,
          frequency_type: "months",
          transaction_amount: Number(plan.price),
          currency_id: plan.currency ?? "ARS",
          free_trial: {
            frequency: 7,
            frequency_type: "days"
          }
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
    const { data: existingSub } = await supabase
      .from("tenant_subscriptions")
      .select("status")
      .eq("institution_id", institution_id)
      .maybeSingle();

    if (existingSub?.status !== "active") {
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
