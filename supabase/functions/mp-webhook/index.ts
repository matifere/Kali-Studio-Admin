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

      console.log(`[GET] institution=${institutionId} preapproval=${preapprovalId}`);

      // SEGURIDAD: NUNCA confiar en query params del browser (status, collection_status).
      // En cambio, validamos contra la API real de Mercado Pago.
      if (institutionId) {
        if (preapprovalId) {
          // Caso ideal: MP envió el preapproval_id → verificamos directamente
          const verified = await verifyPreapprovalWithMP(MP_ACCESS_TOKEN, preapprovalId, institutionId);
          if (verified) {
            await activateInstitution(supabase, MP_ACCESS_TOKEN, institutionId, preapprovalId);
          } else {
            console.log(`[GET] Preapproval ${preapprovalId} NO verificado para institution ${institutionId}. No se activa.`);
          }
        } else {
          // Fallback: MP no envió preapproval_id en la URL (común con preapproval_plan).
          // Buscamos en la API de MP por external_reference para verificar si hay un pago real.
          await searchAndActivate(supabase, MP_ACCESS_TOKEN, institutionId);
        }
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

      // Las verificaciones internas (desde Flutter/Edge Functions) no llevan firma de MP
      const isInternalRequest = payload.type === "manual_verify" || payload.type === "manual_deactivate";

      // El botón de "Probar" en el dashboard de Mercado Pago envía un payload de prueba
      // que suele fallar la validación de firma (faltan headers o el hash no coincide).
      // Lo dejamos pasar con un 200 OK para que la URL quede validada en el panel.
      const isMpDashboardTest = payload.type === "subscription_preapproval" && payload.data?.id === "123456";
      if (isMpDashboardTest) {
        console.log("[POST] Evento de prueba del dashboard de MP recibido. OK.");
        return new Response("Test OK", { status: 200 });
      }

      // Validar firma de MP para eventos IPN reales (no internos)
      if (!isInternalRequest) {
        const MP_WEBHOOK_SECRET = Deno.env.get("MP_WEBHOOK_SECRET");
        if (MP_WEBHOOK_SECRET) {
          const xSignature = req.headers.get("x-signature");
          const xRequestId = req.headers.get("x-request-id");

          if (!xSignature || !xRequestId) {
            console.error("[POST] Evento IPN sin headers de firma. Rechazado.");
            return new Response("Unauthorized", { status: 401 });
          }

          // Parsear x-signature: "ts=TIMESTAMP,v1=HASH"
          const parts: Record<string, string> = {};
          for (const part of xSignature.split(",")) {
            const [key, ...rest] = part.split("=");
            parts[key.trim()] = rest.join("=").trim();
          }

          const ts = parts["ts"];
          const v1 = parts["v1"];
          if (!ts || !v1) {
            console.error("[POST] Formato de x-signature inválido. Rechazado.");
            return new Response("Unauthorized", { status: 401 });
          }

          // Construir el string a firmar según docs de MP
          const dataId = payload.data?.id ?? "";
          const manifest = `id:${dataId};request-id:${xRequestId};ts:${ts};`;

          // Calcular HMAC-SHA256
          const key = await crypto.subtle.importKey(
            "raw",
            new TextEncoder().encode(MP_WEBHOOK_SECRET),
            { name: "HMAC", hash: "SHA-256" },
            false,
            ["sign"],
          );
          const signature = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(manifest));
          const computed = Array.from(new Uint8Array(signature))
            .map((b) => b.toString(16).padStart(2, "0"))
            .join("");

          if (computed !== v1) {
            console.error(`[POST] Firma inválida. Esperada: ${computed}, Recibida: ${v1}. Rechazado.`);
            return new Response("Unauthorized", { status: 401 });
          }

          console.log("[POST] Firma de MP verificada ✓");
        }
      }

      // Verificación manual desde Flutter (botón "Verificar Estado del Pago")
      if (payload.type === "manual_verify" && payload.institution_id) {
        const paymentFound = await manualVerify(supabase, MP_ACCESS_TOKEN, String(payload.institution_id));
        return new Response(JSON.stringify({ ok: true, payment_found: paymentFound }), {
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

// ── Verifica un preapproval_id contra la API de Mercado Pago ─────────────────
// Retorna true solo si el preapproval existe, está autorizado, y pertenece a la institución.
async function verifyPreapprovalWithMP(
  token: string,
  preapprovalId: string,
  expectedInstitutionId: string,
): Promise<boolean> {
  try {
    const res = await fetch(`https://api.mercadopago.com/preapproval/${preapprovalId}`, {
      headers: { "Authorization": `Bearer ${token}` },
    });

    if (!res.ok) {
      console.log(`[verifyPreapprovalWithMP] MP respondió ${res.status} para preapproval ${preapprovalId}`);
      return false;
    }

    const data = await res.json();
    const status: string = data.status;
    const externalRef: string = data.external_reference;

    console.log(`[verifyPreapprovalWithMP] id=${preapprovalId} status=${status} ref=${externalRef} expected=${expectedInstitutionId}`);

    // Solo es válido si está autorizado o pendiente (por free trial) Y pertenece a la institución correcta
    if (status !== "authorized" && status !== "pending") return false;
    if (externalRef !== expectedInstitutionId) {
      console.error(`[verifyPreapprovalWithMP] ALERTA: external_reference (${externalRef}) no coincide con institution_id (${expectedInstitutionId})`);
      return false;
    }

    return true;
  } catch (err) {
    console.error("[verifyPreapprovalWithMP] Error:", err);
    return false;
  }
}

// ── Verificación manual: busca suscripción activa por preapproval_plan_id ────────────
// Retorna true si se encontró un pago válido y se activó, false si no.
async function manualVerify(
  supabase: ReturnType<typeof createClient>,
  token: string,
  institutionId: string,
): Promise<boolean> {
  console.log(`[manualVerify] institution=${institutionId}`);

  // Ver si ya está activa en DB
  const { data: sub } = await supabase
    .from("tenant_subscriptions")
    .select("status, mp_preapproval_id")
    .eq("institution_id", institutionId)
    .maybeSingle();

  if (sub?.status === "active") {
    // Ya está activa, asegurar que profiles/institutions estén sincronizados
    await activateInstitution(supabase, token, institutionId, "already_active");
    return true;
  }

  // mp_preapproval_id almacena el preapproval_plan_id — buscar suscripciones activas de ese plan
  const mpPlanId = sub?.mp_preapproval_id;
  if (mpPlanId) {
    const res = await fetch(
      `https://api.mercadopago.com/preapproval/search?preapproval_plan_id=${encodeURIComponent(mpPlanId)}`,
      { headers: { "Authorization": `Bearer ${token}` } },
    );

    if (res.ok) {
      const data = await res.json();
      const subs = data.results ?? [];
      console.log(`[manualVerify] suscripciones autorizadas encontradas: ${subs.length}`);
      if (subs.length > 0) {
        // Verificar que el external_reference coincida con nuestra institución y esté en estado válido
        const matchingSub = subs.find((s: { external_reference: string, status: string }) => 
          s.external_reference === institutionId && 
          (s.status === "authorized" || s.status === "pending")
        );
        if (matchingSub) {
          await activateInstitution(supabase, token, institutionId, matchingSub.id);
          return true;
        }
        console.log(`[manualVerify] Suscripciones encontradas pero ninguna con external_reference=${institutionId}`);
      }
    }
  }

  // Fallback: buscar pagos por external_reference
  return await searchAndActivate(supabase, token, institutionId);
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

  // Extraer saas_plan_id de back_url si es posible
  let saasPlanId: string | undefined;
  if (data.back_url) {
    const match = data.back_url.match(/saas_plan_id=([^&]+)/);
    if (match) saasPlanId = decodeURIComponent(match[1]);
  }

  console.log(`[processPreapproval] status=${status} institution=${institutionId} saasPlanId=${saasPlanId}`);

  if (!institutionId) return;

  if (status === "authorized" || status === "pending") {
    const nextPaymentDate = data.next_payment_date;
    await activateInstitution(supabase, token, institutionId, preapprovalId, saasPlanId, nextPaymentDate);
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
    await activateInstitution(supabase, token, payment.external_reference, paymentId);
  }
}

// ── Busca suscripciones activas por external_reference (fallback) ─────────────
// Retorna true si encontró un pago válido y activó, false si no.
async function searchAndActivate(
  supabase: ReturnType<typeof createClient>,
  token: string,
  institutionId: string,
): Promise<boolean> {
  // Buscar preapprovals por external_reference sin filtrar status en la URL para obtener todos
  const res = await fetch(
    `https://api.mercadopago.com/preapproval/search?external_reference=${encodeURIComponent(institutionId)}`,
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
        await activateInstitution(supabase, token, institutionId, String(approved.id));
        return true;
      }
    }
    return false;
  }

  const data = await res.json();
  const preapprovals = data.results ?? [];
  console.log(`[searchAndActivate] preapprovals encontrados: ${preapprovals.length}`);

  if (preapprovals.length > 0) {
    const validPreapprovals = preapprovals.filter((p: { status: string }) => p.status === "authorized" || p.status === "pending");
    if (validPreapprovals.length > 0) {
      await activateInstitution(supabase, token, institutionId, validPreapprovals[0].id);
      return true;
    }
  }

  return false;
}

// ── Activa la institución ─────────────────────────────────────────────────────
async function activateInstitution(
  supabase: ReturnType<typeof createClient>,
  token: string,
  institutionId: string,
  ref: string,
  saasPlanId?: string,
  nextPaymentDate?: string,
) {
  console.log(`[activateInstitution] institution=${institutionId} ref=${ref}`);

  // Valores sentinel que NO deben sobreescribir un mp_preapproval_id real ya guardado
  const SENTINEL_VALUES = ["already_active", "redirect", "manual"];
  const isRealId = ref && !SENTINEL_VALUES.includes(ref);

  if (isRealId) {
    // Lógica de upgrade: Verificar si existe una suscripción anterior diferente y cancelarla en MP
    const { data: oldSub } = await supabase
      .from("tenant_subscriptions")
      .select("status, mp_preapproval_id")
      .eq("institution_id", institutionId)
      .maybeSingle();

    if (
      oldSub?.status === "active" &&
      oldSub.mp_preapproval_id &&
      oldSub.mp_preapproval_id !== ref
    ) {
      console.log(`[activateInstitution] UPGRADE DETECTADO! Cancelando sub vieja: ${oldSub.mp_preapproval_id}`);
      try {
        const cancelRes = await fetch(`https://api.mercadopago.com/preapproval/${oldSub.mp_preapproval_id}`, {
          method: "PUT",
          headers: {
            "Authorization": `Bearer ${token}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ status: "cancelled" })
        });
        if (!cancelRes.ok) {
          console.error(`Error de MP al cancelar sub vieja: ${cancelRes.status}`);
        } else {
          console.log(`[activateInstitution] Sub vieja ${oldSub.mp_preapproval_id} cancelada con éxito.`);
        }
      } catch (err) {
        console.error("Error ejecutando fetch de cancelación:", err);
      }
    }
  }

  const updatePayload: Record<string, unknown> = { status: "active" };
  if (isRealId) updatePayload.mp_preapproval_id = ref;
  if (saasPlanId) updatePayload.saas_plan_id = saasPlanId;
  if (nextPaymentDate) updatePayload.current_period_end = nextPaymentDate;

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

  // Buscamos si la suscripción tiene tiempo restante
  const { data: sub } = await supabase
    .from("tenant_subscriptions")
    .select("current_period_end")
    .eq("institution_id", institutionId)
    .maybeSingle();

  await supabase
    .from("tenant_subscriptions")
    .update({ status: "cancelled" })
    .eq("institution_id", institutionId);

  if (sub?.current_period_end) {
    const end = new Date(sub.current_period_end);
    if (end > new Date()) {
      console.log(`[deactivateInstitution] Periodo vence el ${end.toISOString()}. No desactivamos profiles hoy.`);
      return;
    }
  }

  const { error } = await supabase
    .from("profiles")
    .update({ is_active: false })
    .eq("institution_id", institutionId)
    .eq("role", "sudo");

  if (error) console.error("[deactivateInstitution] Error profiles:", error);

  await supabase
    .from("institutions")
    .update({ is_active: false })
    .eq("id", institutionId);
}
