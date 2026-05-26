import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  // Mercado Pago envía peticiones POST al Webhook
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const MP_ACCESS_TOKEN = Deno.env.get("MP_ACCESS_TOKEN");
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!MP_ACCESS_TOKEN || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
      throw new Error("Faltan variables de configuración en el servidor.");
    }

    const payload = await req.json();

    // Verificamos si es una actualización de suscripción
    if (payload.type === "subscription_preapproval" && payload.data && payload.data.id) {
      const preapprovalId = payload.data.id;

      // 1. Consultar el estado real de la suscripción en la API de Mercado Pago
      const mpResponse = await fetch(`https://api.mercadopago.com/preapproval/${preapprovalId}`, {
        method: "GET",
        headers: {
          "Authorization": `Bearer ${MP_ACCESS_TOKEN}`,
        },
      });

      if (!mpResponse.ok) {
        throw new Error(`Error al consultar MP API: ${mpResponse.statusText}`);
      }

      const preapprovalData = await mpResponse.json();
      const status = preapprovalData.status; // ej: 'authorized', 'pending', 'cancelled'
      const institutionId = preapprovalData.external_reference;

      if (!institutionId) {
        throw new Error("El preapproval no tiene un external_reference (institution_id).");
      }

      // Inicializamos el cliente de Supabase ignorando RLS
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

      // Si el pago/suscripción fue autorizado
      if (status === "authorized") {
        // Actualizamos la suscripción a active
        const { error: subError } = await supabase
          .from("tenant_subscriptions")
          .update({ status: "active" })
          .eq("institution_id", institutionId);

        if (subError) {
          console.error("Error al actualizar tenant_subscriptions:", subError);
        }

        // Habilitamos únicamente al usuario con rol 'sudo' de esa institución
        const { error: profileError } = await supabase
          .from("profiles")
          .update({ is_active: true })
          .eq("institution_id", institutionId)
          .eq("role", "sudo");

        if (profileError) {
          console.error("Error al activar perfil sudo:", profileError);
        }
      } else if (status === "cancelled") {
        // Opcional: manejar cancelaciones
        await supabase
          .from("tenant_subscriptions")
          .update({ status: "cancelled" })
          .eq("institution_id", institutionId);

        await supabase
          .from("profiles")
          .update({ is_active: false })
          .eq("institution_id", institutionId)
          .eq("role", "sudo");
      }
    }

    // Mercado Pago requiere un HTTP 200/201 OK rápido
    return new Response("OK", { status: 200 });
  } catch (error) {
    console.error("Error en el Webhook:", error);
    // Aun en error, devolvemos 200 o 400 para que MP no reintente indefinidamente si es fallo lógico
    // pero si es un fallo de token, podríamos devolver 500
    return new Response("Error procesando webhook", { status: 500 });
  }
});
