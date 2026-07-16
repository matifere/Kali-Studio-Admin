import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    // El webhook debe configurarse en Mercado Pago (desde la app de clientes) pasando el ID de la institución
    // Ejemplo: https://<project>.supabase.co/functions/v1/mp-client-webhook?institution_id=UUID
    const institutionId = url.searchParams.get("institution_id");

    if (!institutionId) {
      console.error("[mp-client-webhook] Falta institution_id en la URL");
      return new Response("Missing institution_id", { status: 400 });
    }

    const payload = await req.json().catch(() => ({}));
    console.log(`[mp-client-webhook] type=${payload.type} action=${payload.action}`);

    // Solo nos interesan los pagos
    if (payload.type === "payment" && payload.data?.id) {
      const paymentId = payload.data.id;

      const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
      const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
      const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

      // 1. Obtener el token de Mercado Pago de la institución
      const { data: inst } = await supabase
        .from("institutions")
        .select("mp_token_secret_name")
        .eq("id", institutionId)
        .single();
      
      if (!inst?.mp_token_secret_name) {
        console.error(`[mp-client-webhook] La institución ${institutionId} no tiene token de Mercado Pago configurado`);
        return new Response("Institution has no MP token", { status: 400 });
      }
      
      const mpToken = inst.mp_token_secret_name;

      // 2. Consultar el estado real del pago a la API de Mercado Pago
      const res = await fetch(`https://api.mercadopago.com/v1/payments/${paymentId}`, {
        headers: { "Authorization": `Bearer ${mpToken}` },
      });

      if (!res.ok) {
        console.error(`[mp-client-webhook] Error consultando MP: ${res.status}`);
        return new Response("Error fetching payment from MP", { status: 500 });
      }

      const mpPayment = await res.json();
      const status = mpPayment.status; // 'approved', 'pending', 'rejected', etc.
      
      // La app cliente debe configurar el external_reference con el ID de la suscripción
      const externalReference = mpPayment.external_reference; 
      
      console.log(`[mp-client-webhook] Pago ${paymentId} status=${status} external_reference=${externalReference}`);

      if (status === "approved" && externalReference) {
        const subscriptionId = externalReference;

        // 3. Activar la suscripción (o actualizar si es necesario)
        const { error: subError } = await supabase
          .from("subscriptions")
          .update({ status: "active" })
          .eq("id", subscriptionId);

        if (subError) {
          console.error(`[mp-client-webhook] Error actualizando suscripción: ${subError.message}`);
        }

        // 4. Registrar el pago en la tabla payments
        // Obtenemos info de la suscripción para el user_id
        const { data: subData } = await supabase
          .from("subscriptions")
          .select("user_id, plan_id")
          .eq("id", subscriptionId)
          .maybeSingle();

        if (subData) {
          // Buscamos si ya existe el registro de este pago
          const { data: existingPayment } = await supabase
            .from("payments")
            .select("id")
            .eq("preference_id", paymentId) // Guardamos el paymentId de MP acá
            .maybeSingle();

          if (!existingPayment) {
            await supabase.from("payments").insert({
              user_id: subData.user_id,
              subscription_id: subscriptionId,
              amount: mpPayment.transaction_amount,
              currency: mpPayment.currency_id,
              method: "mercadopago",
              status: "completed",
              payment_date: new Date().toISOString(),
              preference_id: paymentId,
              institution_id: institutionId,
              notes: "Pago automatizado vía MP Client Webhook",
            });
          }
        }
      }
    }

    return new Response("OK", { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error("[mp-client-webhook] Error general:", error);
    return new Response("Error", { status: 500 });
  }
});
