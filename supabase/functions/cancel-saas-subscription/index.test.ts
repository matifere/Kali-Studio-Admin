import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { handleRequest } from "./index.ts";

Deno.test("cancel-saas-subscription - Cancels successfully and updates DB", async () => {
  const envGetter = (key: string) => {
    if (key === "MP_ACCESS_TOKEN") return "TEST_TOKEN";
    if (key === "SUPABASE_URL") return "http://localhost:54321";
    if (key === "SUPABASE_ANON_KEY") return "anon";
    if (key === "SUPABASE_SERVICE_ROLE_KEY") return "service";
    return undefined;
  };

  let updateCalled = false;
  let putCalled = false;

  const makeChain = (table: string) => {
    const filters: Record<string, string> = {};
    const chain = {
      eq: (col: string, val: string) => { filters[col] = val; return chain; },
      single: () => Promise.resolve({ data: { institution_id: "inst-123" }, error: null }),
      maybeSingle: () => {
        if (table === "tenant_subscriptions") {
          return Promise.resolve({
            data: { mp_preapproval_id: "preapp-999", status: "active" },
            error: null
          });
        }
        return Promise.resolve({ data: null, error: null });
      },
      select: () => chain,
    };
    return chain;
  };

  const createSupabaseClient = (url: string, key: string, opts?: any) => {
    return {
      auth: {
        getUser: () => Promise.resolve({ data: { user: { id: "user-123" } }, error: null }),
      },
      from: (table: string) => ({
        select: (cols?: string) => makeChain(table),
        update: (data: any) => {
          if (table === "tenant_subscriptions") {
            assertEquals(data.status, "cancelled");
            updateCalled = true;
          }
          return makeChain(table);
        }
      })
    };
  };

  const fetchFn = async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const url = input.toString();
    if (url.includes("api.mercadopago.com/preapproval/preapp-999") && init?.method === "PUT") {
      const body = JSON.parse(init.body as string);
      assertEquals(body.status, "cancelled");
      assertEquals((init.headers as Record<string, string>)["Authorization"], "Bearer TEST_TOKEN");
      putCalled = true;
      return new Response(JSON.stringify({
        id: "preapp-999",
        status: "cancelled",
      }), { status: 200, headers: { "Content-Type": "application/json" } });
    }
    return new Response("Not found", { status: 404 });
  };

  const req = new Request("http://localhost/cancel-saas-subscription", {
    method: "POST",
    headers: {
      "Authorization": "Bearer fake_jwt",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ institution_id: "inst-123" }),
  });

  const res = await handleRequest(req, envGetter, createSupabaseClient as any, fetchFn as any);
  
  assertEquals(res.status, 200);
  assertEquals(updateCalled, true);
  assertEquals(putCalled, true);
});
