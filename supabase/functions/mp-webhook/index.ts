import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);

  try {
    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN")!;
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return new Response("Config error", { status: 500 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── GET: redirección del browser tras suscribirse ───────────────────────────────────
    if (req.method === "GET") {
      // institution_id viene en el back_url que seteamos al crear el plan
      const institutionId = url.searchParams.get("institution_id");
      const preapprovalId = url.searchParams.get("preapproval_id");
      const status = url.searchParams.get("status") ?? url.searchParams.get("collection_status");

      console.log(`[GET] status=${status} institution=${institutionId} preapproval=${preapprovalId}`);

      if (institutionId && (status === "authorized" || status === "approved")) {
        await activateInstitution(supabase, institutionId, preapprovalId ?? "redirect");
      }

      return new Response(
        "<html><body><script>window.close();</script><p>Suscripción procesada. Podés cerrar esta ventana y volver a la app.</p></body></html>",
        { status: 200, headers: { "Content-Type": "text/html" } },
      );
    }

    // ── POST: notificación IPN de MP o verificación manual ────────────────────
    if (req.method === "POST") {
      const payload = await req.json().catch(() => ({}));
      console.log(`[POST] type=${payload.type} action=${payload.action}`);

      // Verificación manual desde Flutter (botón "Ya Pagué")
      if (payload.type === "manual_verify" && payload.institution_id) {
        await manualVerify(supabase, MP_ACCESS_TOKEN, String(payload.institution_id));
        return new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // ⚙️ Desactivación manual para testing — simula vencimiento sin depender de MP
      if (payload.type === "manual_deactivate" && payload.institution_id) {
        await deactivateInstitution(supabase, String(payload.institution_id));
        return new Response(JSON.stringify({ ok: true, action: "deactivated" }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Evento de suscripción (preapproval) — activación inicial o cambio de estado
      if (payload.type === "subscription_preapproval" && payload.data?.id) {
        await processPreapproval(supabase, MP_ACCESS_TOKEN, String(payload.data.id));
      }

      // Evento de pago recurrente autorizado
      if (payload.type === "subscription_authorized_payment" && payload.data?.id) {
        await processAuthorizedPayment(supabase, MP_ACCESS_TOKEN, String(payload.data.id));
      }

      // Evento de pago común (por compatibilidad con Checkout Pro)
      if (payload.type === "payment" && payload.data?.id) {
        await processPayment(supabase, MP_ACCESS_TOKEN, String(payload.data.id));
      }

      return new Response("OK", { status: 200, headers: corsHeaders });
    }

    return new Response("Method not allowed", { status: 405 });
  } catch (error) {
    console.error("Error en webhook:", error);
    return new Response("Error", { status: 500 });
  }
});

// ── Verificación manual: busca suscripción activa por preapproval_plan_id ────────────
async function manualVerify(
  supabase: ReturnType<typeof createClient>,
  token: string,
  institutionId: string,
) {
  console.log(`[manualVerify] institution=${institutionId}`);

  // Ver si ya está activa en DB
  const { data: sub } = await supabase
    .from("tenant_subscriptions")
    .select("status, mp_preapproval_id")
    .eq("institution_id", institutionId)
    .maybeSingle();

  if (sub?.status === "active") {
    await activateInstitution(supabase, institutionId, "already_active");
    return;
  }

  // mp_preapproval_id almacena el preapproval_plan_id — buscar suscripciones activas de ese plan
  const mpPlanId = sub?.mp_preapproval_id;
  if (mpPlanId) {
    const res = await fetch(
      `https://api.mercadopago.com/preapproval/search?preapproval_plan_id=${encodeURIComponent(mpPlanId)}&status=authorized`,
      { headers: { "Authorization": `Bearer ${token}` } },
    );

    if (res.ok) {
      const data = await res.json();
      const subs = data.results ?? [];
      console.log(`[manualVerify] suscripciones autorizadas encontradas: ${subs.length}`);
      if (subs.length > 0) {
        await activateInstitution(supabase, institutionId, subs[0].id);
        return;
      }
    }
  }

  // Fallback: buscar pagos por external_reference
  await searchAndActivate(supabase, token, institutionId);
}

// ── Consulta estado de una suscripción preapproval en MP ─────────────────────
async function processPreapproval(
  supabase: ReturnType<typeof createClient>,
  token: string,
  preapprovalId: string,
) {
  console.log(`[processPreapproval] id=${preapprovalId}`);

  const res = await fetch(`https://api.mercadopago.com/preapproval/${preapprovalId}`, {
    headers: { "Authorization": `Bearer ${token}` },
  });

  if (!res.ok) {
    console.error(`Error obteniendo preapproval ${preapprovalId}: ${res.status}`);
    return;
  }

  const data = await res.json();
  const status: string = data.status; // "authorized", "pending", "cancelled", "paused"
  const institutionId: string = data.external_reference;

  console.log(`[processPreapproval] status=${status} institution=${institutionId}`);

  if (!institutionId) return;

  if (status === "authorized") {
    await activateInstitution(supabase, institutionId, preapprovalId);
  } else if (status === "cancelled" || status === "expired") {
    // 'expired' ocurre cuando MP no puede cobrar en reiterados intentos
    await deactivateInstitution(supabase, institutionId);
  } else if (status === "paused") {
    // Paused: mantener activa pero registrar estado
    await supabase
      .from("tenant_subscriptions")
      .update({ status: "paused" })
      .eq("institution_id", institutionId);
  }
}

// ── Proceso pago recurrente autorizado (cobro mensual) ────────────────────────
async function processAuthorizedPayment(
  supabase: ReturnType<typeof createClient>,
  token: string,
  invoiceId: string,
) {
  console.log(`[processAuthorizedPayment] invoice=${invoiceId}`);

  const res = await fetch(
    `https://api.mercadopago.com/authorized_payments/${invoiceId}`,
    { headers: { "Authorization": `Bearer ${token}` } },
  );

  if (!res.ok) return;

  const data = await res.json();
  if (data.preapproval_id) {
    // Verificar el preapproval padre para obtener el external_reference
    await processPreapproval(supabase, token, data.preapproval_id);
  }
}

// ── Proceso pago único (compatibilidad Checkout Pro) ──────────────────────────
async function processPayment(
  supabase: ReturnType<typeof createClient>,
  token: string,
  paymentId: string,
) {
  const res = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
    headers: { "Authorization": `Bearer ${token}` },
  });
  if (!res.ok) return;

  const payment = await res.json();
  if (payment.status === "approved" && payment.external_reference) {
    await activateInstitution(supabase, payment.external_reference, paymentId);
  }
}

// ── Busca suscripciones activas por external_reference (fallback) ─────────────
async function searchAndActivate(
  supabase: ReturnType<typeof createClient>,
  token: string,
  institutionId: string,
) {
  // Buscar preapprovals por external_reference
  const res = await fetch(
    `https://api.mercadopago.com/preapproval/search?external_reference=${encodeURIComponent(institutionId)}&status=authorized`,
    { headers: { "Authorization": `Bearer ${token}` } },
  );

  if (!res.ok) {
    // Fallback: buscar pagos normales
    const payRes = await fetch(
      `https://api.mercadopago.com/v1/payments/search?external_reference=${encodeURIComponent(institutionId)}&sort=date_created&criteria=desc`,
      { headers: { "Authorization": `Bearer ${token}` } },
    );
    if (payRes.ok) {
      const payData = await payRes.json();
      const approved = (payData.results ?? []).find((p: { status: string }) => p.status === "approved");
      if (approved) {
        await activateInstitution(supabase, institutionId, String(approved.id));
      }
    }
    return;
  }

  const data = await res.json();
  const preapprovals = data.results ?? [];
  console.log(`[searchAndActivate] preapprovals encontrados: ${preapprovals.length}`);

  if (preapprovals.length > 0) {
    await activateInstitution(supabase, institutionId, preapprovals[0].id);
  }
}

// ── Activa la institución ─────────────────────────────────────────────────────
async function activateInstitution(
  supabase: ReturnType<typeof createClient>,
  institutionId: string,
  ref: string,
) {
  console.log(`[activateInstitution] institution=${institutionId} ref=${ref}`);

  // Valores sentinel que NO deben sobreescribir un mp_preapproval_id real ya guardado
  const SENTINEL_VALUES = ["already_active", "redirect", "manual"];
  const isRealId = ref && !SENTINEL_VALUES.includes(ref);

  const updatePayload: Record<string, unknown> = { status: "active" };
  if (isRealId) updatePayload.mp_preapproval_id = ref;

  await supabase
    .from("tenant_subscriptions")
    .update(updatePayload)
    .eq("institution_id", institutionId);

  const { error } = await supabase
    .from("profiles")
    .update({ is_active: true })
    .eq("institution_id", institutionId)
    .eq("role", "sudo");

  if (error) console.error("[activateInstitution] Error profiles:", error);

  await supabase
    .from("institutions")
    .update({ is_active: true })
    .eq("id", institutionId);
}


// ── Desactiva la institución (suscripción cancelada) ─────────────────────────
async function deactivateInstitution(
  supabase: ReturnType<typeof createClient>,
  institutionId: string,
) {
  console.log(`[deactivateInstitution] institution=${institutionId}`);

  await supabase
    .from("tenant_subscriptions")
    .update({ status: "cancelled" })
    .eq("institution_id", institutionId);

  await supabase
    .from("profiles")
    .update({ is_active: false })
    .eq("institution_id", institutionId)
    .eq("role", "sudo");

  // Espejo de activateInstitution: también desactivar la institución
  await supabase
    .from("institutions")
    .update({ is_active: false })
    .eq("id", institutionId);
}
