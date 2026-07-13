#!/bin/bash

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
CONTAINER_NAME=${DB_CONTAINER:-supabase-db}

echo "Conectando al servidor ($SERVER_IP) para desactivar pago..."
echo "Usuario: $EMAIL"

SQL="
DO \$\$
DECLARE
    v_institution_id uuid;
BEGIN
    SELECT institution_id INTO v_institution_id FROM profiles WHERE email = '$EMAIL' LIMIT 1;
    
    IF v_institution_id IS NULL THEN
        RAISE EXCEPTION 'ERROR: No se encontró ninguna institución asociada al email %', '$EMAIL';
    END IF;

    UPDATE tenant_subscriptions 
    SET status = 'cancelled', 
        updated_at = NOW()
    WHERE institution_id = v_institution_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ERROR: La institución % no tiene ninguna suscripción activa.', v_institution_id;
    END IF;

    RAISE NOTICE '❌ Suscripción desactivada (cancelada) exitosamente para %', '$EMAIL';
END \$\$;
"

if [ -n "$SUPABASE_DB_URL" ]; then
  ssh $SERVER_USER@$SERVER_IP "sudo -S docker exec -i $CONTAINER_NAME psql \"$SUPABASE_DB_URL\"" << EOI
$SERVER_PASS
$SQL
EOI
else
  ssh $SERVER_USER@$SERVER_IP "sudo -S docker exec -i $CONTAINER_NAME psql -U postgres -d postgres" << EOI
$SERVER_PASS
$SQL
EOI
fi
echo "Proceso terminado."
