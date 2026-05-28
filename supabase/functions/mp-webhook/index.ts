import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

Deno.serve(async (req) => {
  // Preflight CORS — debe estar primero
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);

  try {

    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return new Response("Config error", { status: 500 });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── GET: redirección del browser tras el pago ──────────────────────────
    if (req.method === "GET") {
      const paymentId = url.searchParams.get("payment_id") ?? url.searchParams.get("collection_id");
      const status = url.searchParams.get("status") ?? url.searchParams.get("collection_status");
      const institutionId = url.searchParams.get("external_reference");

      console.log(`[GET] payment_id=${paymentId} status=${status} institution=${institutionId}`);

      if ((status === "approved") && institutionId) {
        if (paymentId) {
          await processPayment(supabase, MP_ACCESS_TOKEN, paymentId);
        } else {
          await activateInstitution(supabase, institutionId, "redirect");
        }
      }

      return new Response("<html><body><script>window.close();</script><p>Pago procesado. Podés cerrar esta ventana.</p></body></html>", {
        status: 200,
        headers: { "Content-Type": "text/html" },
      });
    }

    // ── POST: notificación IPN de MP o verificación manual ─────────────────
    if (req.method === "POST") {
      const payload = await req.json().catch(() => ({}));
      console.log(`[POST] type=${payload.type}`);


      // Verificación manual desde la app Flutter
      if (payload.type === "manual_verify" && payload.institution_id) {
        const institutionId = payload.institution_id as string;
        await manualVerify(supabase, MP_ACCESS_TOKEN, institutionId);
        return new Response(JSON.stringify({ ok: true }), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Notificación de pago (Checkout Pro)
      if (payload.type === "payment" && payload.data?.id) {
        await processPayment(supabase, MP_ACCESS_TOKEN, String(payload.data.id));
      }

      // Notificación de preapproval (compatibilidad)
      if (payload.type === "subscription_preapproval" && payload.data?.id) {
        await processPreapproval(supabase, MP_ACCESS_TOKEN, String(payload.data.id));
      }

      return new Response("OK", {
        status: 200,
        headers: corsHeaders,
      });
    }

    return new Response("Method not allowed", { status: 405 });
  } catch (error) {
    console.error("Error en webhook:", error);
    return new Response("Error", { status: 500 });
  }
});

// ── Verifica el último pago en MP para la institución ─────────────────────────
async function manualVerify(
  supabase: ReturnType<typeof createClient>,
  token: string,
  institutionId: string,
) {
  console.log(`[manualVerify] institution=${institutionId}`);

  // Verificar si la suscripción ya está activa en nuestra DB
  const { data: sub } = await supabase
    .from("tenant_subscriptions")
    .select("status")
    .eq("institution_id", institutionId)
    .maybeSingle();

  if (sub?.status === "active") {
    // Ya está activo en DB, solo activar el perfil por si acaso
    await activateInstitution(supabase, institutionId, "already_active");
    return;
  }

  // Buscar pagos aprobados en MP usando external_reference = institution_id
  // Esta es la forma correcta: el preference_id no es el payment_id.
  const searchUrl =
    `https://api.mercadopago.com/v1/payments/search` +
    `?external_reference=${encodeURIComponent(institutionId)}` +
    `&sort=date_created&criteria=desc`;

  const res = await fetch(searchUrl, {
    headers: { "Authorization": `Bearer ${token}` },
  });

  if (!res.ok) {
    console.error(`[manualVerify] Error buscando pagos: ${res.status} ${await res.text()}`);
    return;
  }

  const data = await res.json();
  const payments: Array<{ id: string; status: string; external_reference: string }> =
    data.results ?? [];

  console.log(`[manualVerify] pagos encontrados: ${payments.length}`);

  const approved = payments.find((p) => p.status === "approved");
  if (approved) {
    await activateInstitution(supabase, institutionId, String(approved.id));
  } else {
    console.log(`[manualVerify] Sin pagos aprobados para institution=${institutionId}`);
  }
}


// ── Consulta un pago en MP y activa si está aprobado ─────────────────────────
async function processPayment(
  supabase: ReturnType<typeof createClient>,
  token: string,
  paymentId: string,
) {
  console.log(`[processPayment] id=${paymentId}`);

  const res = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
    headers: { "Authorization": `Bearer ${token}` },
  });

  if (!res.ok) {
    console.error(`Error al obtener pago ${paymentId}: ${res.status} ${await res.text()}`);
    return;
  }

  const payment = await res.json();
  const status: string = payment.status;
  const institutionId: string = payment.external_reference;

  console.log(`[processPayment] status=${status} institution=${institutionId}`);

  if (status === "approved" && institutionId) {
    await activateInstitution(supabase, institutionId, paymentId);
  }
}

// ── Consulta un preapproval en MP y activa si está autorizado ────────────────
async function processPreapproval(
  supabase: ReturnType<typeof createClient>,
  token: string,
  preapprovalId: string,
) {
  const res = await fetch(`https://api.mercadopago.com/preapproval/${preapprovalId}`, {
    headers: { "Authorization": `Bearer ${token}` },
  });

  if (!res.ok) return;

  const data = await res.json();
  if (data.status === "authorized" && data.external_reference) {
    await activateInstitution(supabase, data.external_reference, preapprovalId);
  }
}

// ── Activa la institución: profiles + tenant_subscriptions ────────────────────
async function activateInstitution(
  supabase: ReturnType<typeof createClient>,
  institutionId: string,
  paymentRef: string,
) {
  console.log(`[activateInstitution] institution=${institutionId} ref=${paymentRef}`);

  const { error: subError } = await supabase
    .from("tenant_subscriptions")
    .update({ status: "active", mp_preapproval_id: paymentRef })
    .eq("institution_id", institutionId);

  if (subError) console.error("Error en tenant_subscriptions:", subError);

  const { error: profileError } = await supabase
    .from("profiles")
    .update({ is_active: true })
    .eq("institution_id", institutionId)
    .eq("role", "sudo");

  if (profileError) console.error("Error en profiles:", profileError);

  // Intentar activar la institución si tiene campo is_active
  await supabase
    .from("institutions")
    .update({ is_active: true })
    .eq("id", institutionId);
}
