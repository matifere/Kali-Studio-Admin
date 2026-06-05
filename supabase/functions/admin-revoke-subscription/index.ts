import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * admin-revoke-subscription
 *
 * Función administrativa que revoca inmediatamente la suscripción de un usuario
 * dado su email. A diferencia de cancel-saas-subscription (accesible por el usuario),
 * esta función:
 *   - NO es invocable desde la app (requiere ADMIN_SECRET)
 *   - Desactiva TODO de forma inmediata (sin esperar fin de ciclo)
 *   - Cancela la suscripción en Mercado Pago
 *   - Desactiva profiles, institutions, y tenant_subscriptions
 *
 * Uso (curl):
 *   curl -X POST https://<SUPABASE_URL>/functions/v1/admin-revoke-subscription \
 *     -H "Content-Type: application/json" \
 *     -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
 *     -d '{ "email": "usuario@ejemplo.com", "admin_secret": "<ADMIN_SECRET>" }'
 */

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { status: 200 });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const ADMIN_SECRET = Deno.env.get("ADMIN_SECRET");
    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!ADMIN_SECRET || !MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      return jsonResponse({ error: "Variables de entorno incompletas." }, 500);
    }

    const body = await req.json().catch(() => ({}));
    const { email, admin_secret } = body;

    // ── Autenticación: verificar secret de admin ──────────────────────────
    if (!admin_secret || admin_secret !== ADMIN_SECRET) {
      console.error(`[admin-revoke] Intento no autorizado. IP: ${req.headers.get("x-forwarded-for") ?? "desconocida"}`);
      return jsonResponse({ error: "No autorizado." }, 403);
    }

    if (!email || typeof email !== "string") {
      return jsonResponse({ error: "Falta el parámetro 'email'." }, 400);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── 1. Buscar el usuario por email ────────────────────────────────────
    const { data: usersData, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) throw new Error(`Error listando usuarios: ${listError.message}`);

    const user = usersData.users.find(
      (u: { email?: string }) => u.email?.toLowerCase() === email.toLowerCase()
    );

    if (!user) {
      return jsonResponse({ error: `No se encontró un usuario con el email '${email}'.` }, 404);
    }

    console.log(`[admin-revoke] Usuario encontrado: ${user.id} (${email})`);

    // ── 2. Obtener su perfil e institution_id ─────────────────────────────
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("institution_id, role")
      .eq("id", user.id)
      .maybeSingle();

    if (profileError) throw new Error(`Error obteniendo perfil: ${profileError.message}`);

    if (!profile?.institution_id) {
      return jsonResponse({ error: `El usuario '${email}' no tiene una institución asociada.` }, 404);
    }

    const institutionId = profile.institution_id;
    console.log(`[admin-revoke] Institución: ${institutionId}`);

    // ── 3. Obtener suscripción actual ─────────────────────────────────────
    const { data: sub } = await supabase
      .from("tenant_subscriptions")
      .select("mp_preapproval_id, status")
      .eq("institution_id", institutionId)
      .maybeSingle();

    const actions: string[] = [];

    // ── 4. Cancelar en Mercado Pago si hay suscripción activa ─────────────
    if (sub?.mp_preapproval_id && (sub.status === "active" || sub.status === "authorized")) {
      try {
        const cancelRes = await fetch(
          `https://api.mercadopago.com/preapproval/${sub.mp_preapproval_id}`,
          {
            method: "PUT",
            headers: {
              "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ status: "cancelled" }),
          }
        );

        if (cancelRes.ok) {
          actions.push(`Suscripción MP ${sub.mp_preapproval_id} cancelada.`);
          console.log(`[admin-revoke] Sub MP ${sub.mp_preapproval_id} cancelada.`);
        } else {
          const errText = await cancelRes.text();
          actions.push(`Error cancelando en MP (${cancelRes.status}): ${errText}. Continuando con cancelación local.`);
          console.warn(`[admin-revoke] Error MP ${cancelRes.status}: ${errText}`);
        }
      } catch (err) {
        actions.push(`Excepción cancelando en MP: ${err}. Continuando con cancelación local.`);
        console.error(`[admin-revoke] Excepción MP:`, err);
      }
    } else {
      actions.push("No hay suscripción activa en MP para cancelar.");
    }

    // ── 5. Revocar en base de datos (inmediato, sin esperar fin de ciclo) ─
    // 5a. tenant_subscriptions → cancelled
    const { error: subError } = await supabase
      .from("tenant_subscriptions")
      .update({ status: "cancelled", current_period_end: new Date().toISOString() })
      .eq("institution_id", institutionId);

    if (subError) {
      actions.push(`Error actualizando tenant_subscriptions: ${subError.message}`);
    } else {
      actions.push("tenant_subscriptions → cancelled (periodo forzado a ahora).");
    }

    // 5b. profiles → is_active = false (solo el perfil sudo de la institución)
    const { error: profilesError } = await supabase
      .from("profiles")
      .update({ is_active: false })
      .eq("institution_id", institutionId)
      .eq("role", "sudo");

    if (profilesError) {
      actions.push(`Error desactivando profiles: ${profilesError.message}`);
    } else {
      actions.push("Todos los profiles de la institución desactivados.");
    }

    // 5c. institutions → is_active = false
    const { error: instError } = await supabase
      .from("institutions")
      .update({ is_active: false })
      .eq("id", institutionId);

    if (instError) {
      actions.push(`Error desactivando institution: ${instError.message}`);
    } else {
      actions.push("Institución desactivada.");
    }

    console.log(`[admin-revoke] Completado para ${email}. Acciones: ${JSON.stringify(actions)}`);

    return jsonResponse({
      ok: true,
      email,
      institution_id: institutionId,
      actions,
    });

  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[admin-revoke] Error fatal:`, msg);
    return jsonResponse({ error: msg }, 500);
  }
});

function jsonResponse(data: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
