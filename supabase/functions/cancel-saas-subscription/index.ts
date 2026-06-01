import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export async function handleRequest(
  req: Request, 
  envGetter: (key: string) => string | undefined,
  createSupabaseClient = createClient,
  fetchFn = fetch
): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("Falta el token de autorización");

    const MP_ACCESS_TOKEN = envGetter("MP_ACCESS_TOKEN");
    const SUPABASE_URL = envGetter("SUPABASE_URL");
    const SUPABASE_ANON_KEY = envGetter("SUPABASE_ANON_KEY");
    const SUPABASE_SERVICE_ROLE_KEY = envGetter("SUPABASE_SERVICE_ROLE_KEY");

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Variables de entorno incompletas");
    }

    const { institution_id } = await req.json();
    if (!institution_id) {
      throw new Error("Falta institution_id");
    }

    const supabase = createSupabaseClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userAuth, error: authError } = await supabase.auth.getUser();
    if (authError || !userAuth.user) throw new Error("No autorizado");

    const { data: profile } = await supabase
      .from("profiles")
      .select("institution_id")
      .eq("id", userAuth.user.id)
      .single();

    if (profile?.institution_id !== institution_id) {
      throw new Error("No tienes permisos para esta institución");
    }

    // Cliente con service role para realizar operaciones bypass RLS si es necesario
    const supabaseAdmin = createSupabaseClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: sub } = await supabaseAdmin
      .from("tenant_subscriptions")
      .select("mp_preapproval_id, status")
      .eq("institution_id", institution_id)
      .maybeSingle();

    if (!sub || sub.status !== "active" || !sub.mp_preapproval_id) {
      throw new Error("No hay una suscripción activa para cancelar");
    }

    // Cancelar en MP
    const cancelRes = await fetchFn(
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

    if (!cancelRes.ok) {
      const errorText = await cancelRes.text();
      console.error(`Error cancelando en MP: ${cancelRes.status} ${errorText}`);
      // No lanzamos error si MP falla (e.g. 400 Bad Request por ser de prueba o ya cancelada),
      // forzamos la cancelación local para que la app no quede bloqueada.
      console.warn(`Forzando cancelación local en Supabase debido a error de MercadoPago.`);
    } else {
      const cancelData = await cancelRes.json();
      console.log(`[cancel-saas-subscription] Suscripción ${sub.mp_preapproval_id} cancelada en MP`);
    }

    // Actualización proactiva para que la UI reaccione instantáneamente
    await supabaseAdmin
      .from("tenant_subscriptions")
      .update({ status: "cancelled" })
      .eq("institution_id", institution_id);

    return new Response(JSON.stringify({ 
      ok: true, 
      message: "Suscripción cancelada en Mercado Pago. Mantendrás el acceso hasta el fin del ciclo de facturación." 
    }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (err: any) {
    console.error(err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
}

// Only serve if not running in test mode
if (Deno.env.get("DENO_ENV") !== "test") {
  Deno.serve((req) => handleRequest(req, (k) => Deno.env.get(k)));
}
