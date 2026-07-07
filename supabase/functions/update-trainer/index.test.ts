import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { handleRequest } from "./index.ts";

const envGetter = (key: string) => {
  if (key === "SUPABASE_URL") return "http://localhost:54321";
  if (key === "SUPABASE_ANON_KEY") return "anon";
  if (key === "SUPABASE_SERVICE_ROLE_KEY") return "service";
  return undefined;
};

const CALLER_ID = "caller-123";
const TRAINER_ID = "trainer-456";

/**
 * Construye un cliente Supabase falso.
 *
 * @param caller   Perfil devuelto para el staff que llama (role/institution_id).
 * @param trainer  Perfil devuelto para el entrenador objetivo.
 * @param spies    Objeto donde se registran las llamadas para poder asertarlas.
 */
function makeClient(
  caller: Record<string, unknown> | null,
  trainer: Record<string, unknown> | null,
  spies: {
    authPatch?: Record<string, unknown>;
    profilePatch?: Record<string, unknown>;
    authUpdateError?: { message: string } | null;
  },
) {
  const makeChain = (table: string, op: "select" | "update", patch?: any) => {
    const filters: Record<string, string> = {};
    const chain: any = {
      eq: (col: string, val: string) => {
        filters[col] = val;
        return chain;
      },
      select: () => chain,
      maybeSingle: () => {
        if (table !== "profiles") return Promise.resolve({ data: null, error: null });
        if (op === "update") {
          spies.profilePatch = patch;
          return Promise.resolve({
            data: { id: filters["id"], ...patch },
            error: null,
          });
        }
        // op === "select": distinguir caller vs trainer por el id filtrado.
        if (filters["id"] === CALLER_ID) {
          return Promise.resolve({ data: caller, error: null });
        }
        if (filters["id"] === TRAINER_ID) {
          return Promise.resolve({ data: trainer, error: null });
        }
        return Promise.resolve({ data: null, error: null });
      },
    };
    return chain;
  };

  return {
    auth: {
      getUser: () =>
        Promise.resolve({ data: { user: { id: CALLER_ID } }, error: null }),
      admin: {
        updateUserById: (_id: string, patch: Record<string, unknown>) => {
          spies.authPatch = patch;
          return Promise.resolve({
            error: spies.authUpdateError ?? null,
          });
        },
      },
    },
    from: (table: string) => ({
      select: () => makeChain(table, "select"),
      update: (patch: any) => makeChain(table, "update", patch),
    }),
  };
}

function makeReq(body: unknown, withAuth = true) {
  return new Request("http://localhost/update-trainer", {
    method: "POST",
    headers: {
      ...(withAuth ? { Authorization: "Bearer fake_jwt" } : {}),
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

Deno.test("update-trainer - actualiza nombre, email y contraseña", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "sudo", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "admin" },
    spies,
  );

  const req = makeReq({
    trainer_id: TRAINER_ID,
    full_name: "Valentina López",
    email: "VALE@Ejemplo.com",
    password: "nueva-clave",
  });

  const res = await handleRequest(req, envGetter, (() => client) as any);
  const json = await res.json();

  assertEquals(res.status, 200);
  assertEquals(json.ok, true);
  // Email normalizado a minúsculas y email_confirm forzado.
  assertEquals(spies.authPatch.email, "vale@ejemplo.com");
  assertEquals(spies.authPatch.email_confirm, true);
  assertEquals(spies.authPatch.password, "nueva-clave");
  // El perfil espeja nombre y email.
  assertEquals(spies.profilePatch.full_name, "Valentina López");
  assertEquals(spies.profilePatch.email, "vale@ejemplo.com");
});

Deno.test("update-trainer - solo nombre no toca auth.users", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "admin", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "admin" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, full_name: "Nuevo Nombre" }),
    envGetter,
    (() => client) as any,
  );

  assertEquals(res.status, 200);
  assertEquals(spies.authPatch, undefined); // no se llamó a updateUserById
  assertEquals(spies.profilePatch.full_name, "Nuevo Nombre");
});

Deno.test("update-trainer - rechaza a un llamador sin permisos", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "client", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "admin" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, full_name: "X" }),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "No tenés permisos para editar entrenadores");
});

Deno.test("update-trainer - no permite editar otra institución", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "admin", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-OTRA", role: "admin" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, email: "x@y.com" }),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "No podés editar entrenadores de otra institución");
});

Deno.test("update-trainer - no permite editar a un dueño (sudo)", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "sudo", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "sudo" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, full_name: "X" }),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "Solo se pueden editar perfiles de entrenadores");
});

Deno.test("update-trainer - falla sin cambios", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "admin", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "admin" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID }),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "No hay cambios para aplicar");
});

Deno.test("update-trainer - rechaza email inválido", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "admin", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "admin" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, email: "no-es-un-email" }),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "El email no tiene un formato válido");
});

Deno.test("update-trainer - rechaza contraseña corta", async () => {
  const spies: any = {};
  const client = makeClient(
    { role: "admin", institution_id: "inst-1" },
    { id: TRAINER_ID, institution_id: "inst-1", role: "admin" },
    spies,
  );

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, password: "123" }),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "La contraseña debe tener al menos 6 caracteres");
});

Deno.test("update-trainer - falla sin token de autorización", async () => {
  const spies: any = {};
  const client = makeClient(null, null, spies);

  const res = await handleRequest(
    makeReq({ trainer_id: TRAINER_ID, full_name: "X" }, false),
    envGetter,
    (() => client) as any,
  );
  const json = await res.json();

  assertEquals(res.status, 400);
  assertEquals(json.error, "Falta el token de autorización");
});
