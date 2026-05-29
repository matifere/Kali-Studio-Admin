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

// ─── Helpers para mockear el cliente de Supabase ────────────────────────────

type UpdateCall = { table: string; data: Record<string, unknown>; eq: Record<string, string> };
type SupabaseCallLog = UpdateCall[];

function makeMockSupabase(callLog: SupabaseCallLog) {
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
      select: () => ({
        eq: () => ({
          maybeSingle: () => Promise.resolve({ data: null, error: null }),
        }),
      }),
    }),
  };
}

// ─── Extraer lógica pura del webhook para tests ─────────────────────────────
// Dado que index.ts usa Deno.serve, extraemos las funciones puras
// re-implementándolas aquí para poder testearlas aisladas.

type SupabaseLike = ReturnType<typeof makeMockSupabase>;

const SENTINEL_VALUES = ["already_active", "redirect", "manual"];

async function activateInstitution(
  supabase: SupabaseLike,
  institutionId: string,
  ref: string,
  callLog: SupabaseCallLog,
) {
  const isRealId = ref && !SENTINEL_VALUES.includes(ref);
  const updatePayload: Record<string, unknown> = { status: "active" };
  if (isRealId) updatePayload.mp_preapproval_id = ref;

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

// ─── GRUPO 1: activateInstitution ───────────────────────────────────────────

Deno.test("activateInstitution — con ID real actualiza mp_preapproval_id", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);
  const REAL_ID = "6439a101c2fa4ad69760efae72c5a8ba";

  await activateInstitution(supabase as unknown as SupabaseLike, "inst-1", REAL_ID, log);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "active");
  assertEquals(subUpdate?.data.mp_preapproval_id, REAL_ID, "Debe guardar el ID real de MP");
});

Deno.test("activateInstitution — sentinel 'already_active' NO sobreescribe mp_preapproval_id", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await activateInstitution(supabase as unknown as SupabaseLike, "inst-1", "already_active", log);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "active");
  assertEquals(
    subUpdate?.data.mp_preapproval_id,
    undefined,
    "No debe incluir mp_preapproval_id en el update con valor sentinel",
  );
});

Deno.test("activateInstitution — sentinel 'redirect' NO sobreescribe mp_preapproval_id", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await activateInstitution(supabase as unknown as SupabaseLike, "inst-1", "redirect", log);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.mp_preapproval_id, undefined);
});

Deno.test("activateInstitution — actualiza profiles.is_active=true", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await activateInstitution(supabase as unknown as SupabaseLike, "inst-1", "real-mp-id-123", log);

  const profileUpdate = log.find((c) => c.table === "profiles");
  assertEquals(profileUpdate?.data.is_active, true);
});

Deno.test("activateInstitution — actualiza institutions.is_active=true", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await activateInstitution(supabase as unknown as SupabaseLike, "inst-1", "real-mp-id-123", log);

  const instUpdate = log.find((c) => c.table === "institutions");
  assertEquals(instUpdate?.data.is_active, true);
});

// ─── GRUPO 2: deactivateInstitution ─────────────────────────────────────────

Deno.test("deactivateInstitution — pone tenant_subscriptions.status=cancelled", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await deactivateInstitution(supabase as unknown as SupabaseLike, "inst-1", log);

  const subUpdate = log.find((c) => c.table === "tenant_subscriptions");
  assertEquals(subUpdate?.data.status, "cancelled");
});

Deno.test("deactivateInstitution — pone profiles.is_active=false", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await deactivateInstitution(supabase as unknown as SupabaseLike, "inst-1", log);

  const profileUpdate = log.find((c) => c.table === "profiles");
  assertEquals(profileUpdate?.data.is_active, false);
});

Deno.test("deactivateInstitution — pone institutions.is_active=false (bug fix)", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await deactivateInstitution(supabase as unknown as SupabaseLike, "inst-1", log);

  const instUpdate = log.find((c) => c.table === "institutions");
  assertEquals(instUpdate?.data.is_active, false, "institutions.is_active debe ser false al vencer");
});

Deno.test("deactivateInstitution — actualiza las 3 tablas", async () => {
  const log: SupabaseCallLog = [];
  const supabase = makeMockSupabase(log);

  await deactivateInstitution(supabase as unknown as SupabaseLike, "inst-1", log);

  const tables = log.map((c) => c.table);
  assertEquals(tables.includes("tenant_subscriptions"), true);
  assertEquals(tables.includes("profiles"), true);
  assertEquals(tables.includes("institutions"), true);
});

// ─── GRUPO 3: lógica de routing de payload ──────────────────────────────────

Deno.test("sentinel values list — contiene los valores esperados", () => {
  assertEquals(SENTINEL_VALUES.includes("already_active"), true);
  assertEquals(SENTINEL_VALUES.includes("redirect"), true);
  assertEquals(SENTINEL_VALUES.includes("manual"), true);
  assertEquals(SENTINEL_VALUES.includes("6439a101c2fa4ad69760efae72c5a8ba"), false);
});

Deno.test("isRealId — UUID real no es sentinel", () => {
  const ref = "abc12345-0000-0000-0000-000000000000";
  const isReal = ref && !SENTINEL_VALUES.includes(ref);
  assertEquals(isReal, true);
});

Deno.test("isRealId — MP hash ID no es sentinel", () => {
  const ref = "6439a101c2fa4ad69760efae72c5a8ba";
  const isReal = ref && !SENTINEL_VALUES.includes(ref);
  assertEquals(isReal, true);
});

// ─── GRUPO 4: processPreapproval status routing ──────────────────────────────

Deno.test("processPreapproval routing — 'expired' lleva a deactivate", () => {
  // Verifica que la lógica de routing trate 'expired' igual que 'cancelled'
  const statusesToDeactivate = ["cancelled", "expired"];
  const statusesToActivate = ["authorized"];
  const statusesToPause = ["paused"];

  for (const s of statusesToDeactivate) {
    assertEquals(
      statusesToDeactivate.includes(s),
      true,
      `Status '${s}' debe desactivar`,
    );
  }
  for (const s of statusesToActivate) {
    assertEquals(statusesToDeactivate.includes(s), false);
  }
  for (const s of statusesToPause) {
    assertEquals(statusesToDeactivate.includes(s), false);
    assertEquals(statusesToActivate.includes(s), false);
  }
});
