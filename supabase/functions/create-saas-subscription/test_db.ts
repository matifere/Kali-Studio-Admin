import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
const res = await supabase.from("tenant_subscriptions").select("*").limit(1);
console.log(JSON.stringify(res.data));
