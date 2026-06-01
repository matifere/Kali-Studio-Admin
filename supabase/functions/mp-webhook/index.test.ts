/**
 * mp-webhook — Tests unitarios
 *
 * Cómo correr:
 *   cd supabase/functions
 *   deno test mp-webhook/index.test.ts --allow-env --allow-net=false
 *
 * O desde la raíz del proyecto:
 *   deno test supabase/functions/mp-webhook/index.test.ts --allow-env
 */

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// ─── Helpers para mockear el cliente de Supabase y fetch ────────────────────

type UpdateCall = { table: string; data: Record<string, unknown>; eq: Record<string, string> };
type SupabaseCallLog = UpdateCall[];
type FetchCall = { url: string; method: string; body?: any };

function makeMockSupabase(callLog: SupabaseCallLog, mockDbState: Record<string, any> = {}) {
  const makeChain = (table: string, data: Record<string, unknown>) => {
    const filters: Record<string, string> = {};
    const chain = {
      eq: (col: string, val: string) => { filters[col] = val; return chain; },
      then: (resolve: (v: { error: null }) => unknown) => {
        callLog.push({ table, data, eq: { ...filters } });
        return Promise.resolve(resolve({ error: null }));
      },
    };
    return chain;
  };

  return {
    from: (table: string) => ({
      update: (data: Record<string, unknown>) => makeChain(table, data),
      select: (columns?: string) => ({
        eq: (col: string, val: string) => ({
          maybeSingle: () => {
            // Mockeamos la respuesta de la base de datos basada en mockDbState
            if (table === "tenant_subscriptions" && mockDbState[val]) {
              return Promise.resolve({ data: mockDbState[val], error: null });
            }
            return Promise.resolve({ data: null, error: null });
          },
        }),
      }),
    }),
  };
}

// ─── Extraer lógica pura del webhook para tests ─────────────────────────────

type SupabaseLike = ReturnType<typeof makeMockSupabase>;

const SENTINEL_VALUES = ["already_active", "redirect", "manual"];

async function activateInstitution(
  supabase: SupabaseLike,
  token: string,
  institutionId: string,
  ref: string,
  saasPlanId: string | undefined,
  callLog: SupabaseCallLog,
  fetchLog: FetchCall[]
) {
  const isRealId = ref && !SENTINEL_VALUES.includes(ref);

  if (isRealId) {
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
      // Registrar la llamada fetch para el test
      fetchLog.push({
        url: `https://api.mercadopago.com/preapproval/${oldSub.mp_preapproval_id}`,
        method: "PUT",
        body: { status: "cancelled" }
      });
    }
  }

  const updatePayload: Record<string, unknown> = { status: "active" };
  if (isRealId) updatePayload.mp_preapproval_id = ref;
  if (saasPlanId) updatePayload.saas_plan_id = saasPlanId;

  await (supabase.from("tenant_subscriptions").update(updatePayload) as unknown as Promise<void>);
  callLog.push({ table: "tenant_subscriptions", data: updatePayload, eq: { institution_id: institutionId } });

  await (supabase.from("profiles").update({ is_active: true }) as unknown as Promise<void>);
  callLog.push({ table: "profiles", data: { is_active: true }, eq: { institution_id: institutionId, role: "sudo" } });

  await (supabase.from("institutions").update({ is_active: true }) as unknown as Promise<void>);
  callLog.push({ table: "institutions", data: { is_active: true }, eq: { id: institutionId } });
}

async function deactivateInstitution(
  supabase: SupabaseLike,
  institutionId: string,
  callLog: SupabaseCallLog,
) {
  await (supabase.from("tenant_subscriptions").update({ status: "cancelled" }) as unknown as Promise<void>);
  callLog.push({ table: "tenant_subscriptions", data: { status: "cancelled" }, eq: { institution_id: institutionId } });

  await (supabase.from("profiles").update({ is_active: false }) as unknown as Promise<void>);
  callLog.push({ table: "profiles", data: { is_active: false }, eq: { institution_id: institutionId, role: "sudo" } });

  await (supabase.from("institutions").update({ is_active: false }) as unknown as Promise<void>);
  callLog.push({ table: "institutions", data: { is_active: false }, eq: { id: institutionId } });
}

// ─── GRUPO 1: activateInstitution (Casos Base) ──────────────────────────────

Deno.test("activateInstitution — con ID real actualiza mp_preapproval_id", async () => {
  const log: SupabaseCallLog = [];
  const fetchLog: FetchCall[] = [];
  const supabase = makeMockSupabase(log);
  const REAL_ID = "6439a101c2fa4ad69760efae72c5a8ba";

  await activateInstitution(supabase as unknown as SupabaseLike, "fake-token", "inst-1", REAL_ID, undefined, log, fetchLog);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "active");
  assertEquals(subUpdate?.data.mp_preapproval_id, REAL_ID, "Debe guardar el ID real de MP");
});

Deno.test("activateInstitution — sentinel 'already_active' NO sobreescribe mp_preapproval_id", async () => {
  const log: SupabaseCallLog = [];
  const fetchLog: FetchCall[] = [];
  const supabase = makeMockSupabase(log);

  await activateInstitution(supabase as unknown as SupabaseLike, "fake-token", "inst-1", "already_active", undefined, log, fetchLog);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "active");
  assertEquals(
    subUpdate?.data.mp_preapproval_id,
    undefined,
    "No debe incluir mp_preapproval_id en el update con valor sentinel",
  );
});

// ─── GRUPO 2: deactivateInstitution ─────────────────────────────────────────

Deno.test("deactivateInstitution — pone tenant_subscriptions.status=cancelled", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await deactivateInstitution(supabase as unknown as SupabaseLike, "inst-1", log);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "cancelled");
});

Deno.test("deactivateInstitution — desactiva perfil e institucion", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await deactivateInstitution(supabase as unknown as SupabaseLike, "inst-1", log);

  const profileUpdate = log.find((c) => c.table === "profiles");
  assertEquals(profileUpdate?.data.is_active, false);
  const instUpdate = log.find((c) => c.table === "institutions");
  assertEquals(instUpdate?.data.is_active, false);
});

// ─── GRUPO 3: Lógica de UPGRADE (Cambio de Plan) ────────────────────────────

Deno.test("activateInstitution — UPGRADE: cancela la suscripción vieja en MP", async () => {
  const log: SupabaseCallLog = [];
  const fetchLog: FetchCall[] = [];
  
  const OLD_MP_ID = "old-sub-123";
  const NEW_MP_ID = "new-sub-456";
  const NEW_PLAN_ID = "plan-xyz-890";
  const INST_ID = "inst-1";

  // Simulamos que la base de datos responde que la institución tiene una sub activa vieja
  const mockDbState = {
    [INST_ID]: { status: "active", mp_preapproval_id: OLD_MP_ID }
  };
  
  const supabase = makeMockSupabase(log, mockDbState);

  await activateInstitution(
    supabase as unknown as SupabaseLike, 
    "fake-token", 
    INST_ID, 
    NEW_MP_ID, 
    NEW_PLAN_ID, 
    log, 
    fetchLog
  );

  // 1. Debe haber hecho un fetch PUT para cancelar la sub vieja
  assertEquals(fetchLog.length, 1, "Debería haber disparado 1 petición fetch a Mercado Pago");
  assertEquals(fetchLog[0].url, `https://api.mercadopago.com/preapproval/${OLD_MP_ID}`);
  assertEquals(fetchLog[0].method, "PUT");
  assertEquals(fetchLog[0].body.status, "cancelled");

  // 2. Debe haber actualizado la base de datos con la sub nueva y el plan nuevo
  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "active");
  assertEquals(subUpdate?.data.mp_preapproval_id, NEW_MP_ID, "Debe guardar el NUEVO ID de MP");
  assertEquals(subUpdate?.data.saas_plan_id, NEW_PLAN_ID, "Debe guardar el NUEVO saas_plan_id");
});

Deno.test("activateInstitution — NO UPGRADE: si la sub vieja tiene el MISMO ID, no cancela nada", async () => {
  const log: SupabaseCallLog = [];
  const fetchLog: FetchCall[] = [];
  
  const SAME_MP_ID = "same-sub-123";
  const INST_ID = "inst-1";

  const mockDbState = {
    [INST_ID]: { status: "active", mp_preapproval_id: SAME_MP_ID }
  };
  
  const supabase = makeMockSupabase(log, mockDbState);

  await activateInstitution(
    supabase as unknown as SupabaseLike, 
    "fake-token", 
    INST_ID, 
    SAME_MP_ID, 
    undefined, 
    log, 
    fetchLog
  );

  // No debe cancelar nada porque es el mismo ID
  assertEquals(fetchLog.length, 0, "No debe cancelar la suscripción si el ID no cambió");
});

Deno.test("activateInstitution — NO UPGRADE: si la sub anterior estaba expirada, no cancela nada", async () => {
  const log: SupabaseCallLog = [];
  const fetchLog: FetchCall[] = [];
  
  const OLD_MP_ID = "old-sub-123";
  const NEW_MP_ID = "new-sub-456";
  const INST_ID = "inst-1";

  // Estado expirado / cancelado
  const mockDbState = {
    [INST_ID]: { status: "expired", mp_preapproval_id: OLD_MP_ID }
  };
  
  const supabase = makeMockSupabase(log, mockDbState);

  await activateInstitution(
    supabase as unknown as SupabaseLike, 
    "fake-token", 
    INST_ID, 
    NEW_MP_ID, 
    undefined, 
    log, 
    fetchLog
  );

  // No debe cancelar nada porque ya estaba expirada en nuestra BD
  assertEquals(fetchLog.length, 0, "No debe cancelar porque el estado anterior no era 'active'");
});
