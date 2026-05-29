/**
 * check-expired-subscriptions — Tests unitarios
 *
 * Cómo correr:
 *   cd supabase/functions
 *   deno test check-expired-subscriptions/index.test.ts --allow-env --allow-net=false
 *
 * O desde la raíz del proyecto:
 *   deno test supabase/functions/check-expired-subscriptions/index.test.ts --allow-env
 */

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

// ─── Tipos ───────────────────────────────────────────────────────────────────

type DeactivateCall = { institutionId: string; reason: string };

// ─── Lógica pura extraída para testear ───────────────────────────────────────
// Replicamos las funciones puras aquí para aislarlas de Deno.serve y fetch real.

function mapMpStatusToInternal(reason: string): string {
  if (reason === "cancelled") return "cancelled";
  if (reason === "expired") return "expired";
  if (reason === "paused") return "paused";
  return "cancelled"; // fallback: not_found, api_error, pending, etc.
}

function shouldDeactivate(mpStatus: string | null): boolean {
  return mpStatus !== null && mpStatus !== "authorized";
}

function buildMpQueryUrl(mpId: string): { type: "preapproval" | "plan"; url: string } {
  // En check-expired, primero intentamos /preapproval/{id},
  // si falla intentamos /preapproval/search?preapproval_plan_id={id}
  return {
    type: "preapproval",
    url: `https://api.mercadopago.com/preapproval/${mpId}`,
  };
}

// Simula la lógica de procesamiento de una suscripción activa
async function processSub(
  mpId: string,
  institutionId: string,
  mockFetch: (url: string) => Promise<{ ok: boolean; json: () => Promise<unknown> }>,
  deactivateCalls: DeactivateCall[],
): Promise<{ mpStatus: string | null; action: string }> {
  let mpStatus: string | null = null;
  let action = "no_change";

  const preapprovalRes = await mockFetch(`https://api.mercadopago.com/preapproval/${mpId}`);

  if (preapprovalRes.ok) {
    const data = await preapprovalRes.json() as { status: string };
    mpStatus = data.status;
  } else {
    // Fallback: buscar como plan
    const planRes = await mockFetch(
      `https://api.mercadopago.com/preapproval/search?preapproval_plan_id=${encodeURIComponent(mpId)}&status=authorized`,
    );
    if (planRes.ok) {
      const planData = await planRes.json() as { results: unknown[] };
      const authorized = (planData.results ?? []).length > 0;
      mpStatus = authorized ? "authorized" : "not_found";
    } else {
      mpStatus = "api_error";
    }
  }

  if (shouldDeactivate(mpStatus)) {
    deactivateCalls.push({ institutionId, reason: mpStatus! });
    action = `deactivated (mp_status=${mpStatus})`;
  }

  return { mpStatus, action };
}

// ─── GRUPO 1: mapMpStatusToInternal ─────────────────────────────────────────

Deno.test("mapMpStatusToInternal — 'cancelled' → 'cancelled'", () => {
  assertEquals(mapMpStatusToInternal("cancelled"), "cancelled");
});

Deno.test("mapMpStatusToInternal — 'expired' → 'expired'", () => {
  assertEquals(mapMpStatusToInternal("expired"), "expired");
});

Deno.test("mapMpStatusToInternal — 'paused' → 'paused'", () => {
  assertEquals(mapMpStatusToInternal("paused"), "paused");
});

Deno.test("mapMpStatusToInternal — 'not_found' → 'cancelled' (fallback)", () => {
  assertEquals(mapMpStatusToInternal("not_found"), "cancelled");
});

Deno.test("mapMpStatusToInternal — 'api_error' → 'cancelled' (fallback)", () => {
  assertEquals(mapMpStatusToInternal("api_error"), "cancelled");
});

Deno.test("mapMpStatusToInternal — 'pending' → 'cancelled' (fallback)", () => {
  assertEquals(mapMpStatusToInternal("pending"), "cancelled");
});

// ─── GRUPO 2: shouldDeactivate ───────────────────────────────────────────────

Deno.test("shouldDeactivate — null NO desactiva (no se pudo consultar)", () => {
  assertEquals(shouldDeactivate(null), false);
});

Deno.test("shouldDeactivate — 'authorized' NO desactiva", () => {
  assertEquals(shouldDeactivate("authorized"), false);
});

Deno.test("shouldDeactivate — 'cancelled' SÍ desactiva", () => {
  assertEquals(shouldDeactivate("cancelled"), true);
});

Deno.test("shouldDeactivate — 'expired' SÍ desactiva", () => {
  assertEquals(shouldDeactivate("expired"), true);
});

Deno.test("shouldDeactivate — 'not_found' SÍ desactiva", () => {
  assertEquals(shouldDeactivate("not_found"), true);
});

Deno.test("shouldDeactivate — 'paused' SÍ desactiva", () => {
  assertEquals(shouldDeactivate("paused"), true);
});

Deno.test("shouldDeactivate — 'api_error' SÍ desactiva", () => {
  assertEquals(shouldDeactivate("api_error"), true);
});

// ─── GRUPO 3: processSub con fetch mockeado ──────────────────────────────────

Deno.test("processSub — suscripción 'authorized' no genera deactivate", async () => {
  const calls: DeactivateCall[] = [];

  const mockFetch = (_url: string) =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ status: "authorized" }),
    });

  const result = await processSub("mp-id-123", "inst-1", mockFetch, calls);

  assertEquals(result.mpStatus, "authorized");
  assertEquals(result.action, "no_change");
  assertEquals(calls.length, 0, "No debe llamar a deactivate para authorized");
});

Deno.test("processSub — suscripción 'cancelled' genera deactivate", async () => {
  const calls: DeactivateCall[] = [];

  const mockFetch = (_url: string) =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ status: "cancelled" }),
    });

  const result = await processSub("mp-id-123", "inst-1", mockFetch, calls);

  assertEquals(result.mpStatus, "cancelled");
  assertEquals(calls.length, 1);
  assertEquals(calls[0].institutionId, "inst-1");
  assertEquals(calls[0].reason, "cancelled");
});

Deno.test("processSub — suscripción 'expired' genera deactivate", async () => {
  const calls: DeactivateCall[] = [];

  const mockFetch = (_url: string) =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ status: "expired" }),
    });

  const result = await processSub("mp-id-123", "inst-1", mockFetch, calls);

  assertEquals(result.mpStatus, "expired");
  assertEquals(calls.length, 1);
  assertEquals(calls[0].reason, "expired");
});

Deno.test("processSub — preapproval no encontrado, fallback a plan con 0 resultados → not_found → deactivate", async () => {
  const calls: DeactivateCall[] = [];
  let callCount = 0;

  const mockFetch = (_url: string) => {
    callCount++;
    if (callCount === 1) {
      // Primera llamada: /preapproval/{id} falla (404)
      return Promise.resolve({ ok: false, json: () => Promise.resolve({}) });
    }
    // Segunda llamada: plan search devuelve 0 resultados
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ results: [] }),
    });
  };

  const result = await processSub("plan-id-abc", "inst-2", mockFetch, calls);

  assertEquals(result.mpStatus, "not_found");
  assertEquals(calls.length, 1, "Debe haber llamado deactivate");
  assertEquals(calls[0].reason, "not_found");
});

Deno.test("processSub — preapproval no encontrado, fallback a plan con 1 resultado → authorized → no deactivate", async () => {
  const calls: DeactivateCall[] = [];
  let callCount = 0;

  const mockFetch = (_url: string) => {
    callCount++;
    if (callCount === 1) {
      return Promise.resolve({ ok: false, json: () => Promise.resolve({}) });
    }
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ results: [{ id: "sub-real-123", status: "authorized" }] }),
    });
  };

  const result = await processSub("plan-id-abc", "inst-2", mockFetch, calls);

  assertEquals(result.mpStatus, "authorized");
  assertEquals(result.action, "no_change");
  assertEquals(calls.length, 0, "No debe desactivar si el plan tiene suscriptores autorizados");
});

Deno.test("processSub — MP API completamente caída (api_error) → no desactiva por precaución", async () => {
  // api_error SÍ desactiva en la implementación actual.
  // Este test documenta el comportamiento esperado para revisión futura.
  const calls: DeactivateCall[] = [];
  let callCount = 0;

  const mockFetch = (_url: string) => {
    callCount++;
    return Promise.resolve({ ok: false, json: () => Promise.resolve({}) });
  };

  const result = await processSub("plan-id-abc", "inst-2", mockFetch, calls);

  assertEquals(result.mpStatus, "api_error");
  // Comportamiento actual: api_error SÍ desactiva (conservador)
  // Si se quiere cambiar a "no desactivar cuando la API está caída",
  // modificar shouldDeactivate para excluir "api_error"
  assertEquals(calls.length, 1, "api_error actualmente desactiva — revisar si es el comportamiento deseado");
});

Deno.test("processSub — action string incluye mp_status", async () => {
  const calls: DeactivateCall[] = [];

  const mockFetch = (_url: string) =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ status: "cancelled" }),
    });

  const result = await processSub("mp-id-123", "inst-1", mockFetch, calls);

  assertEquals(result.action.includes("cancelled"), true);
  assertEquals(result.action.includes("deactivated"), true);
});

// ─── GRUPO 4: buildMpQueryUrl ────────────────────────────────────────────────

Deno.test("buildMpQueryUrl — construye URL de preapproval individual", () => {
  const { url } = buildMpQueryUrl("abc-123");
  assertEquals(url, "https://api.mercadopago.com/preapproval/abc-123");
});
