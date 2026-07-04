#!/bin/bash

# Script para activar pagos manuales en la base de datos de Supabase
# Se conecta por SSH al servidor de producción y ejecuta los comandos SQL en el contenedor supabase-db.

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "================================================================"
  echo "Uso: ./activar_pago.sh <email_del_usuario> <fecha_vencimiento> [nombre_plan]"
  echo "Ejemplo: ./activar_pago.sh usuario@gmail.com \"2027-01-01\" \"Premium\""
  echo "================================================================"
  exit 1
fi

if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo "ERROR: No se encontró el archivo .env"
  exit 1
fi

EMAIL=$1
FECHA=$2
PLAN_NAME=$3

echo "Conectando al servidor ($SERVER_IP) para activar pago manual..."
echo "Usuario: $EMAIL"
echo "Válido hasta: $FECHA"
if [ -n "$PLAN_NAME" ]; then
  echo "Plan solicitado: $PLAN_NAME"
fi

# Bloque SQL a ejecutar
SQL="
DO \$\$
DECLARE
    v_institution_id uuid;
    v_saas_plan_id uuid;
BEGIN
    -- 1. Buscar la institución asociada al email
    SELECT institution_id INTO v_institution_id FROM profiles WHERE email = '$EMAIL' LIMIT 1;
    
    IF v_institution_id IS NULL THEN
        RAISE EXCEPTION 'ERROR: No se encontró ninguna institución asociada al email %', '$EMAIL';
    END IF;

    RAISE NOTICE 'Institución encontrada: %', v_institution_id;

    -- 2. Obtener un plan para asignar
    IF '$PLAN_NAME' != '' THEN
        SELECT id INTO v_saas_plan_id FROM saas_plans WHERE name ILIKE '$PLAN_NAME' AND is_active = true LIMIT 1;
        IF v_saas_plan_id IS NULL THEN
            RAISE EXCEPTION 'ERROR: No se encontró un plan activo con el nombre %', '$PLAN_NAME';
        END IF;
    ELSE
        SELECT id INTO v_saas_plan_id FROM saas_plans WHERE is_active = true ORDER BY price ASC LIMIT 1;
        IF v_saas_plan_id IS NULL THEN
            RAISE EXCEPTION 'ERROR: No hay planes SaaS activos en la base de datos para asignar.';
        END IF;
    END IF;

    -- 3. Actualizar o insertar la suscripción
    UPDATE tenant_subscriptions 
    SET status = 'active', 
        current_period_end = '$FECHA 23:59:59', 
        saas_plan_id = v_saas_plan_id,
        mp_preapproval_id = 'manual_payment',
        updated_at = NOW()
    WHERE institution_id = v_institution_id;

    IF NOT FOUND THEN
        INSERT INTO tenant_subscriptions (institution_id, saas_plan_id, status, current_period_end, mp_preapproval_id)
        VALUES (v_institution_id, v_saas_plan_id, 'active', '$FECHA 23:59:59', 'manual_payment');
    END IF;

    RAISE NOTICE '✅ Suscripción activada exitosamente hasta el %', '$FECHA';
END \$\$;
"

# Ejecutamos el SQL a través de SSH pasando la contraseña de sudo en la primera línea del stdin
ssh $SERVER_USER@$SERVER_IP "sudo -S docker exec -i supabase-db psql -U postgres -d postgres" << EOF
$SERVER_PASS
$SQL
EOF

echo "Proceso terminado."
