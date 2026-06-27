#!/bin/bash

# Script para desactivar/cancelar suscripciones manualmente en la base de datos de Supabase.
# Se conecta por SSH al servidor de producción y ejecuta los comandos SQL en el contenedor supabase-db.

if [ -z "$1" ]; then
  echo "================================================================"
  echo "Uso: ./desactivar_pago.sh <email_del_usuario>"
  echo "Ejemplo: ./desactivar_pago.sh usuario@gmail.com"
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

echo "Conectando al servidor ($SERVER_IP) para dar de baja..."
echo "Usuario a desactivar: $EMAIL"

# Bloque SQL a ejecutar
SQL="
DO \$\$
DECLARE
    v_institution_id uuid;
BEGIN
    -- 1. Buscar la institución asociada al email
    SELECT institution_id INTO v_institution_id FROM profiles WHERE email = '$EMAIL' LIMIT 1;
    
    IF v_institution_id IS NULL THEN
        RAISE EXCEPTION 'ERROR: No se encontró ninguna institución asociada al email %', '$EMAIL';
    END IF;

    RAISE NOTICE 'Institución encontrada: %', v_institution_id;

    -- 2. Cancelar la suscripción y fijar el fin del periodo a AYER para forzar el bloqueo
    UPDATE tenant_subscriptions 
    SET status = 'cancelled', 
        current_period_end = NOW() - INTERVAL '1 day', 
        updated_at = NOW()
    WHERE institution_id = v_institution_id;

    RAISE NOTICE '❌ Suscripción y acceso dados de baja exitosamente para %', '$EMAIL';
END \$\$;
"

# Ejecutamos el SQL a través de SSH pasando la contraseña de sudo en la primera línea del stdin
ssh $SERVER_USER@$SERVER_IP "sudo -S docker exec -i supabase-db psql -U postgres -d postgres" << EOF
$SERVER_PASS
$SQL
EOF

echo "Proceso terminado."
