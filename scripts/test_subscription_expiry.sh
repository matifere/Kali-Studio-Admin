#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
#  test_subscription_expiry.sh
#  Prueba completa del flujo de vencimiento de suscripción MP
# ═══════════════════════════════════════════════════════════════════
# Uso:
#   chmod +x scripts/test_subscription_expiry.sh
#   ./scripts/test_subscription_expiry.sh
#
# Variables requeridas en .env:
#   URL=https://tmfcnvtjzmtpqhzvfxos.supabase.co
#   ANON=<anon key>
#   SERVICE_ROLE=<service role key>   ← agregar si no existe
#   INSTITUTION_ID=<uuid>             ← override opcional
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

log()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERR]${NC}   $*"; }
step() { echo -e "\n${BOLD}${BLUE}══ $* ${NC}"; }

# ── Cargar .env ───────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  err "No se encontró .env en $ENV_FILE"
  exit 1
fi

# shellcheck disable=SC1090
set -o allexport
source "$ENV_FILE"
set +o allexport

SUPABASE_URL="${URL:?'Falta URL en .env'}"
ANON_KEY="${ANON:?'Falta ANON en .env'}"
# SERVICE_ROLE puede estar en .env o seteado como variable de entorno
SERVICE_ROLE="${SERVICE_ROLE:-}"

if [[ -z "$SERVICE_ROLE" ]]; then
  warn "SERVICE_ROLE no encontrado en .env. Podés setearlo así:"
  echo "  export SERVICE_ROLE='eyJhbGci...'"
  echo ""
  warn "Sin SERVICE_ROLE, solo se puede llamar a check-expired-subscriptions con ANON key (fallará por RLS)."
  echo ""
fi

WEBHOOK_URL="$SUPABASE_URL/functions/v1/mp-webhook"
CHECK_URL="$SUPABASE_URL/functions/v1/check-expired-subscriptions"
REST_URL="$SUPABASE_URL/rest/v1"

AUTH_HEADER="apikey: $ANON_KEY"
SERVICE_HEADER="${SERVICE_ROLE:+Authorization: Bearer $SERVICE_ROLE}"

# Inicializar con valor por defecto para que set -u no explote
INSTITUTION_ID="${INSTITUTION_ID:-}"
MP_PREAPPROVAL_ID=""

# ── Descubrir institution_id ──────────────────────────────────────────
step "1. Descubriendo institution activa en DB"

# tenant_subscriptions tiene RLS — necesitamos SERVICE_ROLE para leerla.
# Si no está disponible, pedimos el INSTITUTION_ID directamente al usuario.
if [[ -n "$INSTITUTION_ID" ]]; then
  log "Usando INSTITUTION_ID provisto por variable de entorno."
  MP_PREAPPROVAL_ID=""
elif [[ -n "$SERVICE_ROLE" ]]; then
  log "Consultando DB con SERVICE_ROLE (bypassa RLS)..."

  ACTIVE_SUB=$(curl -sf \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    "$REST_URL/tenant_subscriptions?select=institution_id,status,mp_preapproval_id&status=eq.active&limit=1" \
    2>/dev/null || echo "[]")

  INSTITUTION_ID=$(echo "$ACTIVE_SUB" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d[0]['institution_id'] if d else '')" \
    2>/dev/null || echo "")
  MP_PREAPPROVAL_ID=$(echo "$ACTIVE_SUB" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d[0].get('mp_preapproval_id','') if d else '')" \
    2>/dev/null || echo "")

  if [[ -z "$INSTITUTION_ID" ]]; then
    err "La DB no devolvió suscripciones activas con SERVICE_ROLE."
    err "Verificá que exista al menos una fila con status='active' en tenant_subscriptions."
    exit 1
  fi
else
  warn "SERVICE_ROLE no configurado — no puedo consultar la DB con RLS activo."
  warn "Opciones:"
  echo "  1) Pasá el INSTITUTION_ID manualmente:"
  echo "     INSTITUTION_ID=<uuid> ./scripts/test_subscription_expiry.sh"
  echo ""
  echo "  2) Agregá SERVICE_ROLE al .env (lo encontrás en Supabase → Project Settings → API):"
  echo "     SERVICE_ROLE='eyJ...' ./scripts/test_subscription_expiry.sh"
  echo ""
  read -r -p "O ingresá el INSTITUTION_ID ahora (Enter para cancelar): " INSTITUTION_ID
  if [[ -z "$INSTITUTION_ID" ]]; then
    err "INSTITUTION_ID requerido. Cancelando."
    exit 1
  fi
  MP_PREAPPROVAL_ID=""
fi

ok "institution_id = $INSTITUTION_ID"
log "mp_preapproval_id = ${MP_PREAPPROVAL_ID:-'(vacío)'}"

# Helper: construir headers para curl con o sin SERVICE_ROLE
# Uso: curl $(db_auth_headers) ...
db_auth_headers() {
  if [[ -n "$SERVICE_ROLE" ]]; then
    echo "-H 'apikey: $ANON_KEY' -H 'Authorization: Bearer $SERVICE_ROLE'"
  else
    echo "-H 'apikey: $ANON_KEY' -H 'Authorization: Bearer $ANON_KEY'"
  fi
}

# ── Estado inicial ────────────────────────────────────────────────────
step "2. Estado inicial de profiles (before)"

if [[ -n "$SERVICE_ROLE" ]]; then
  PROFILES_BEFORE=$(curl -sf \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    "$REST_URL/profiles?select=id,role,is_active&institution_id=eq.$INSTITUTION_ID&role=eq.sudo" \
    2>/dev/null || echo "[]")
else
  PROFILES_BEFORE=$(curl -sf \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ANON_KEY" \
    "$REST_URL/profiles?select=id,role,is_active&institution_id=eq.$INSTITUTION_ID&role=eq.sudo" \
    2>/dev/null || echo "[]")
fi

echo "$PROFILES_BEFORE" | python3 -c "
import sys, json
profiles = json.load(sys.stdin)
if not profiles:
    print('  ⚠️  No se encontraron perfiles sudo para esta institución')
else:
    for p in profiles:
        status = '✅ ACTIVO' if p.get('is_active') else '❌ INACTIVO'
        print(f\"  {status}  id={p['id']}  role={p['role']}\")
"

INITIAL_ACTIVE=$(echo "$PROFILES_BEFORE" | python3 -c "
import sys, json
profiles = json.load(sys.stdin)
print('true' if profiles and profiles[0].get('is_active') else 'false')
" 2>/dev/null || echo "unknown")

if [[ "$INITIAL_ACTIVE" == "false" ]]; then
  warn "El perfil ya está inactivo. Primero activalo con:"
  echo "  curl -X POST '$WEBHOOK_URL' -H 'Content-Type: application/json' \\"
  echo "    -d '{\"type\":\"manual_verify\",\"institution_id\":\"$INSTITUTION_ID\"}'"
  echo ""
  read -r -p "¿Continuar igual? (s/N): " CONTINUE
  [[ "$CONTINUE" =~ ^[sS]$ ]] || exit 0
fi

# ══════════════════════════════════════════════════════════════
# TEST A: Simulación directa de vencimiento via manual_deactivate
# ══════════════════════════════════════════════════════════════
step "3A. TEST A — Simular vencimiento via manual_deactivate"
log "Enviando payload de desactivación al webhook..."

DEACTIVATE_RESPONSE=$(curl -sf -X POST \
  -H "Content-Type: application/json" \
  -H "$AUTH_HEADER" \
  "$WEBHOOK_URL" \
  -d "{\"type\":\"manual_deactivate\",\"institution_id\":\"$INSTITUTION_ID\"}" \
  2>/dev/null || echo '{"error":"curl failed"}')

echo "  Respuesta: $DEACTIVATE_RESPONSE"

if echo "$DEACTIVATE_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('ok') else 1)" 2>/dev/null; then
  ok "Webhook respondió OK"
else
  err "El webhook no respondió como esperado"
fi

# ── Verificar estado después ──────────────────────────────────────────
step "4. Estado después de manual_deactivate"

sleep 1  # pequeño delay para asegurar que el update se propagó

if [[ -n "$SERVICE_ROLE" ]]; then
  PROFILES_AFTER=$(curl -sf \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    "$REST_URL/profiles?select=id,role,is_active&institution_id=eq.$INSTITUTION_ID&role=eq.sudo" \
    2>/dev/null || echo "[]")
else
  PROFILES_AFTER=$(curl -sf \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $ANON_KEY" \
    "$REST_URL/profiles?select=id,role,is_active&institution_id=eq.$INSTITUTION_ID&role=eq.sudo" \
    2>/dev/null || echo "[]")
fi

echo "$PROFILES_AFTER" | python3 -c "
import sys, json
profiles = json.load(sys.stdin)
if not profiles:
    print('  ⚠️  No se encontraron perfiles sudo')
else:
    for p in profiles:
        status = '✅ ACTIVO' if p.get('is_active') else '❌ INACTIVO'
        print(f\"  {status}  id={p['id']}  role={p['role']}\")
"

FINAL_ACTIVE=$(echo "$PROFILES_AFTER" | python3 -c "
import sys, json
profiles = json.load(sys.stdin)
print('true' if profiles and profiles[0].get('is_active') else 'false')
" 2>/dev/null || echo "unknown")

if [[ -n "$SERVICE_ROLE" ]]; then
  SUB_STATUS=$(curl -sf \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    "$REST_URL/tenant_subscriptions?select=status&institution_id=eq.$INSTITUTION_ID" \
    2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['status'] if d else 'N/A')" 2>/dev/null || echo "N/A")
else
  SUB_STATUS="N/A (sin SERVICE_ROLE)"
fi

log "tenant_subscriptions.status = $SUB_STATUS"

# ── Resultado TEST A ──────────────────────────────────────────────────
step "Resultado TEST A"
if [[ "$FINAL_ACTIVE" == "false" && "$SUB_STATUS" == "cancelled" ]]; then
  ok "✅ TEST A PASSED: is_active=false y subscription=cancelled"
else
  err "❌ TEST A FAILED"
  err "   is_active=$FINAL_ACTIVE (esperado: false)"
  err "   subscription_status=$SUB_STATUS (esperado: cancelled)"
fi

# ══════════════════════════════════════════════════════════════
# TEST B: check-expired-subscriptions contra API de MP
# ══════════════════════════════════════════════════════════════
step "5. TEST B — check-expired-subscriptions (requiere SERVICE_ROLE)"

if [[ -z "$SERVICE_ROLE" ]]; then
  warn "SERVICE_ROLE no configurado — saltando TEST B"
  warn "Para correrlo: export SERVICE_ROLE='eyJ...' && ./scripts/test_subscription_expiry.sh"
else
  log "Primero re-activando la institución para poder testear la verificación..."

  REACTIVATE_RESPONSE=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    "$WEBHOOK_URL" \
    -d "{\"type\":\"manual_verify\",\"institution_id\":\"$INSTITUTION_ID\"}" \
    2>/dev/null || echo '{"error":"curl failed"}')

  log "Re-activación: $REACTIVATE_RESPONSE"
  sleep 1

  log "Llamando a check-expired-subscriptions..."
  CHECK_RESPONSE=$(curl -sf -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_ROLE" \
    "$CHECK_URL" \
    2>/dev/null || echo '{"error":"curl failed"}')

  echo "  Respuesta: $(echo "$CHECK_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$CHECK_RESPONSE")"

  step "Resultado TEST B"
  CHECK_ACTION=$(echo "$CHECK_RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
results = d.get('results', [])
if results:
    print(results[0].get('action', 'unknown'))
else:
    print('no_results')
" 2>/dev/null || echo "unknown")

  log "Acción tomada por check-expired: $CHECK_ACTION"

  if echo "$CHECK_ACTION" | grep -q "deactivated\|no_change"; then
    ok "✅ TEST B: check-expired-subscriptions consultó MP API correctamente"
    log "   Si la suscripción está activa en MP → no_change (correcto)"
    log "   Si la suscripción no existe en MP → deactivated (correcto)"
  else
    warn "⚠️  TEST B: respuesta inesperada — revisá los logs de la Edge Function en Supabase Dashboard"
  fi
fi

# ── Resumen final ─────────────────────────────────────────────────────
step "══ RESUMEN ══"
echo ""
echo -e "  Institution ID : ${BOLD}$INSTITUTION_ID${NC}"
echo -e "  MP Preapproval : ${BOLD}${MP_PREAPPROVAL_ID:-'(no registrado)'}${NC}"
echo ""
echo -e "  ${BOLD}TEST A (manual_deactivate)${NC}"
if [[ "$FINAL_ACTIVE" == "false" && "$SUB_STATUS" == "cancelled" ]]; then
  echo -e "    ${GREEN}✅ PASS${NC} — is_active=false, subscription=cancelled"
else
  echo -e "    ${RED}❌ FAIL${NC} — is_active=$FINAL_ACTIVE, subscription=$SUB_STATUS"
fi
echo ""
echo -e "  Podés ver los logs de las Edge Functions en:"
echo -e "  ${BLUE}https://supabase.com/dashboard/project/tmfcnvtjzmtpqhzvfxos/functions${NC}"
echo ""
