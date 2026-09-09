import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * check-expired-subscriptions
 *
 * Consulta la API de Mercado Pago por cada suscripción marcada como 'active'
 * en tenant_subscriptions y desactiva las que ya no están autorizadas.
 *
 * Invocación:
 *   POST https://<project>.supabase.co/functions/v1/check-expired-subscriptions
 *   Authorization: Bearer <SERVICE_ROLE_KEY>
 *
 * También puede ser invocada como cron job via pg_cron o Supabase Scheduled Functions.
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN")!;
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return new Response(
        JSON.stringify({ error: "Faltan variables de entorno" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // 1. Obtener todas las suscripciones activas con un preapproval registrado
    const { data: activeSubs, error: dbError } = await supabase
      .from("tenant_subscriptions")
      .select("institution_id, mp_preapproval_id, status")
      .eq("status", "active")
      .not("mp_preapproval_id", "is", null);

    if (dbError) {
      throw new Error(`Error leyendo DB: ${dbError.message}`);
    }

    if (!activeSubs || activeSubs.length === 0) {
      return new Response(
        JSON.stringify({ message: "No hay suscripciones activas para verificar.", checked: 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log(`[check-expired] Verificando ${activeSubs.length} suscripción(es) activa(s)...`);

    const results: Array<{
      institution_id: string;
      mp_id: string;
      mp_status: string | null;
      action: string;
    }> = [];

    for (const sub of activeSubs) {
      const institutionId: string = sub.institution_id;
      const mpId: string = sub.mp_preapproval_id;

      let mpStatus: string | null = null;
      let action = "no_change";

      try {
        // Intentar primero como preapproval individual
        const preapprovalRes = await fetch(
          `https://api.mercadopago.com/preapproval/${mpId}`,
          { headers: { "Authorization": `Bearer ${MP_ACCESS_TOKEN}` } },
        );

        if (preapprovalRes.ok) {
          const preapproval = await preapprovalRes.json();
          mpStatus = preapproval.status;
          console.log(`[check-expired] institution=${institutionId} preapproval_id=${mpId} status=${mpStatus}`);
        } else {
          // Si no encontró como preapproval, intentar como preapproval_plan
          // y buscar suscripciones activas bajo ese plan
          const planSearchRes = await fetch(
            `https://api.mercadopago.com/preapproval/search?preapproval_plan_id=${encodeURIComponent(mpId)}`,
            { headers: { "Authorization": `Bearer ${MP_ACCESS_TOKEN}` } },
          );

          if (planSearchRes.ok) {
            const planData = await planSearchRes.json();
            const activeSubsList = (planData.results ?? []).filter((s: { status: string }) => s.status === "authorized" || s.status === "pending");
            const authorized = activeSubsList.length > 0;
            mpStatus = authorized ? activeSubsList[0].status : "not_found";
            console.log(
              `[check-expired] institution=${institutionId} plan_id=${mpId} valid_subs=${activeSubsList.length}`,
            );
          } else {
            mpStatus = "api_error";
            console.warn(`[check-expired] No se pudo consultar MP para institution=${institutionId}`);
          }
        }

        // 2. Si el estado no es 'authorized' ni 'pending', desactivar
        if (mpStatus !== null && mpStatus !== "authorized" && mpStatus !== "pending") {
          await deactivateInstitution(supabase, institutionId, mpStatus);
          action = `deactivated (mp_status=${mpStatus})`;
        }
      } catch (err) {
        console.error(`[check-expired] Error procesando institution=${institutionId}:`, err);
        action = `error: ${err}`;
      }

      results.push({ institution_id: institutionId, mp_id: mpId, mp_status: mpStatus, action });
    }

    console.log("[check-expired] Resultados:", JSON.stringify(results));

    return new Response(
      JSON.stringify({ checked: results.length, results }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    console.error("[check-expired] Error fatal:", msg);
    return new Response(
      JSON.stringify({ error: msg }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});

// ── Desactiva institución o aplica plan futuro ─────────────────────────────────
async function deactivateInstitution(supabase, institutionId, reason) {
  console.log(`[deactivateInstitution] institution=${institutionId} reason=${reason}`);
  
  const { data: sub } = await supabase
    .from("tenant_subscriptions")
    .select("current_period_end, next_saas_plan_id")
    .eq("institution_id", institutionId)
    .maybeSingle();

  // Si tiene un vencimiento futuro, no cortamos acceso todavía
  if (sub?.current_period_end) {
    const end = new Date(sub.current_period_end);
    if (end > new Date()) {
      console.log(`[deactivateInstitution] El periodo vence el ${end.toISOString()}. Mantenemos acceso.`);
      await supabase.from("tenant_subscriptions").update({ status: "cancelled" }).eq("institution_id", institutionId);
      return;
    }
  }

  // Si llegamos acá, el periodo terminó o no tenía. Verificamos si hay plan futuro.
  if (sub?.next_saas_plan_id) {
    console.log(`[deactivateInstitution] Periodo expirado, migrando al plan futuro: ${sub.next_saas_plan_id}`);
    
    // Obtenemos si el plan futuro es gratuito
    const { data: nextPlan } = await supabase
      .from("saas_plans")
      .select("price")
      .eq("id", sub.next_saas_plan_id)
      .maybeSingle();
      
    if (nextPlan && Number(nextPlan.price) === 0) {
      await supabase.from("tenant_subscriptions").update({
        saas_plan_id: sub.next_saas_plan_id,
        next_saas_plan_id: null,
        status: "active",
        mp_preapproval_id: null,
        current_period_end: new Date(new Date().setFullYear(new Date().getFullYear() + 10)).toISOString()
      }).eq("institution_id", institutionId);
      return; // Migrado a gratis, no desactivar
    } else {
      // Es un downgrade a plan pago (raro, pero posible). Queda inactivo a la espera de pago.
      await supabase.from("tenant_subscriptions").update({
        saas_plan_id: sub.next_saas_plan_id,
        next_saas_plan_id: null,
        status: "pending",
        mp_preapproval_id: null
      }).eq("institution_id", institutionId);
    }
  } else {
    // Sin plan futuro, cancelar normalmente
    const internalStatus = reason === "cancelled" ? "cancelled" : reason === "expired" ? "expired" : reason === "paused" ? "paused" : "cancelled";
    await supabase.from("tenant_subscriptions").update({ status: internalStatus }).eq("institution_id", institutionId);
  }

  // Cortamos acceso
  const { error } = await supabase.from("profiles").update({ is_active: false }).eq("institution_id", institutionId).eq("role", "sudo");
  if (error) console.error("[deactivateInstitution] Error al actualizar profiles:", error);
  await supabase.from("institutions").update({ is_active: false }).eq("id", institutionId);
}
