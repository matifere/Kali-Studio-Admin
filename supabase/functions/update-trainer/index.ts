import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * update-trainer
 *
 * Edita nombre y/o email de un entrenador (rol 'admin'). Cambiar el email
 * toca `auth.users`, lo que requiere el service_role key que NO puede vivir en
 * la app cliente; por eso esta operación se hace acá.
 *
 * Seguridad:
 *   - Autentica al staff que llama vía su JWT (header Authorization).
 *   - Solo permite continuar si el llamador es 'sudo' o 'admin'.
 *   - Solo permite editar entrenadores (rol 'admin') de la MISMA institución.
 *     El dueño (sudo) no se edita por esta vía.
 *
 * Body: {
 *   "trainer_id": "<uuid>",
 *   "full_name"?: string,
 *   "email"?: string,
 *   "password"?: string   // mínimo 6 caracteres; resetea la contraseña
 * }
 */
export async function handleRequest(
  req: Request,
  envGetter: (key: string) => string | undefined,
  createSupabaseClient = createClient,
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Falta el token de autorización");

    const SUPABASE_URL = envGetter("SUPABASE_URL");
    const SUPABASE_ANON_KEY = envGetter("SUPABASE_ANON_KEY");
    const SUPABASE_SERVICE_ROLE_KEY = envGetter("SUPABASE_SERVICE_ROLE_KEY");

    if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Variables de entorno incompletas");
    }

    const body = await req.json();
    const trainer_id = body?.trainer_id;
    if (!trainer_id || typeof trainer_id !== "string") {
      throw new Error("Falta el parámetro 'trainer_id'");
    }

    // Normalizar campos: solo actualizamos los que vienen presentes y válidos.
    const fullName = typeof body?.full_name === "string" ? body.full_name.trim() : undefined;
    const email = typeof body?.email === "string" ? body.email.trim().toLowerCase() : undefined;
    // La contraseña NO se trimea: los espacios pueden ser intencionales.
    const password = typeof body?.password === "string" && body.password.length > 0
      ? body.password
      : undefined;

    if (fullName === undefined && email === undefined && password === undefined) {
      throw new Error("No hay cambios para aplicar");
    }
    if (fullName !== undefined && fullName.length === 0) {
      throw new Error("El nombre no puede estar vacío");
    }
    if (email !== undefined && !EMAIL_RE.test(email)) {
      throw new Error("El email no tiene un formato válido");
    }
    if (password !== undefined && password.length < 6) {
      throw new Error("La contraseña debe tener al menos 6 caracteres");
    }

    // ── 1. Identificar al staff que llama (vía su JWT) ────────────────────
    const supabaseCaller = createSupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userAuth, error: authError } = await supabaseCaller.auth.getUser();
    if (authError || !userAuth.user) throw new Error("No autorizado");

    const callerId = userAuth.user.id;

    // ── 2. Cliente con service role para verificar permisos y actualizar ──
    const supabaseAdmin = createSupabaseClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: caller, error: callerError } = await supabaseAdmin
      .from("profiles")
      .select("role, institution_id")
      .eq("id", callerId)
      .maybeSingle();

    if (callerError) throw new Error(`Error obteniendo perfil del staff: ${callerError.message}`);
    if (!caller) throw new Error("No se encontró el perfil del staff");

    if (caller.role !== "sudo" && caller.role !== "admin") {
      throw new Error("No tenés permisos para editar entrenadores");
    }

    // ── 3. Verificar que el entrenador pertenezca a la institución ────────
    const { data: trainer, error: trainerError } = await supabaseAdmin
      .from("profiles")
      .select("id, institution_id, role")
      .eq("id", trainer_id)
      .maybeSingle();

    if (trainerError) throw new Error(`Error obteniendo perfil del entrenador: ${trainerError.message}`);
    if (!trainer) throw new Error("El entrenador no existe");

    if (trainer.institution_id !== caller.institution_id) {
      throw new Error("No podés editar entrenadores de otra institución");
    }

    // Solo se editan entrenadores ('admin'); sin esto se podría cambiar el
    // email del dueño (sudo) de la institución.
    if (trainer.role !== "admin") {
      throw new Error("Solo se pueden editar perfiles de entrenadores");
    }

    // ── 4. Actualizar auth.users (email y/o contraseña) ───────────────────
    if (email !== undefined || password !== undefined) {
      const authPatch: Record<string, unknown> = {};
      if (email !== undefined) {
        authPatch.email = email;
        authPatch.email_confirm = true;
      }
      if (password !== undefined) authPatch.password = password;

      const { error: authUpdateError } = await supabaseAdmin.auth.admin.updateUserById(
        trainer_id,
        authPatch,
      );
      if (authUpdateError) {
        // Ej. email ya en uso por otro usuario.
        throw new Error(`No se pudo actualizar la cuenta: ${authUpdateError.message}`);
      }
    }

    // ── 5. Actualizar profiles (nombre y/o email espejo) ──────────────────
    const profilePatch: Record<string, unknown> = {};
    if (fullName !== undefined) profilePatch.full_name = fullName;
    if (email !== undefined) profilePatch.email = email;

    const { data: updated, error: updateError } = await supabaseAdmin
      .from("profiles")
      .update(profilePatch)
      .eq("id", trainer_id)
      .select("id, full_name, email, is_active, role")
      .maybeSingle();

    if (updateError) throw new Error(`Error actualizando el perfil: ${updateError.message}`);

    console.log(`[update-trainer] Entrenador ${trainer_id} editado por ${callerId}`);

    return new Response(
      JSON.stringify({ ok: true, trainer: updated }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[update-trainer] Error:`, msg);
    return new Response(
      JSON.stringify({ error: msg }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
}

// Only serve if not running in test mode
if (Deno.env.get("DENO_ENV") !== "test") {
  Deno.serve((req) => handleRequest(req, (k) => Deno.env.get(k)));
}
