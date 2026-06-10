import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/**
 * delete-student
 *
 * Elimina un alumno por completo: tanto su fila en `profiles` como su usuario
 * en `auth.users`. Borrar de auth requiere el service_role key, que NO puede
 * vivir en la app cliente; por eso esta operación se hace acá.
 *
 * Seguridad:
 *   - Autentica al staff que llama vía su JWT (header Authorization).
 *   - Solo permite continuar si el llamador es 'sudo' o 'admin'.
 *   - Solo permite borrar alumnos de la MISMA institución que el staff.
 *
 * Body: { "student_id": "<uuid del alumno>" }
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

    const { student_id } = await req.json();
    if (!student_id || typeof student_id !== "string") {
      throw new Error("Falta el parámetro 'student_id'");
    }

    // ── 1. Identificar al staff que llama (vía su JWT) ────────────────────
    const supabaseCaller = createSupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userAuth, error: authError } = await supabaseCaller.auth.getUser();
    if (authError || !userAuth.user) throw new Error("No autorizado");

    const callerId = userAuth.user.id;

    // ── 2. Cliente con service role para verificar permisos y borrar ──────
    const supabaseAdmin = createSupabaseClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: caller, error: callerError } = await supabaseAdmin
      .from("profiles")
      .select("role, institution_id")
      .eq("id", callerId)
      .maybeSingle();

    if (callerError) throw new Error(`Error obteniendo perfil del staff: ${callerError.message}`);
    if (!caller) throw new Error("No se encontró el perfil del staff");

    if (caller.role !== "sudo" && caller.role !== "admin") {
      throw new Error("No tenés permisos para eliminar alumnos");
    }

    // ── 3. Verificar que el alumno pertenezca a la institución del staff ──
    const { data: student, error: studentError } = await supabaseAdmin
      .from("profiles")
      .select("id, institution_id, role")
      .eq("id", student_id)
      .maybeSingle();

    if (studentError) throw new Error(`Error obteniendo perfil del alumno: ${studentError.message}`);
    if (!student) throw new Error("El alumno no existe");

    if (student.institution_id !== caller.institution_id) {
      throw new Error("No podés eliminar alumnos de otra institución");
    }

    if (student.id === callerId) {
      throw new Error("No podés eliminarte a vos mismo");
    }

    // Solo se pueden eliminar alumnos ('client'); sin esto un profesor podría
    // borrar al dueño de la institución o a otro profesor.
    if (student.role !== "client") {
      throw new Error("Solo se pueden eliminar perfiles de alumnos");
    }

    // ── 4. Borrar el perfil ───────────────────────────────────────────────
    const { error: deleteProfileError } = await supabaseAdmin
      .from("profiles")
      .delete()
      .eq("id", student_id);

    if (deleteProfileError) {
      throw new Error(`Error eliminando el perfil: ${deleteProfileError.message}`);
    }

    // ── 5. Borrar el usuario de auth.users ────────────────────────────────
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(student_id);

    if (deleteAuthError) {
      // El perfil ya se borró; reportamos el fallo de auth para que se
      // pueda limpiar manualmente, pero no lo tratamos como éxito.
      throw new Error(`Perfil borrado, pero falló al borrar en auth: ${deleteAuthError.message}`);
    }

    console.log(`[delete-student] Alumno ${student_id} eliminado por ${callerId}`);

    return new Response(
      JSON.stringify({ ok: true, student_id }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[delete-student] Error:`, msg);
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
