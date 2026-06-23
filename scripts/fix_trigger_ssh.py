import paramiko

host = '192.168.0.41'
user = 'mati'
password = '2102'

script_content = """
CREATE OR REPLACE FUNCTION public.validate_profile_institution()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- El FK ya garantiza que el ID existe; acá verificamos que esté activa
  IF NEW.institution_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.institutions
      WHERE id = NEW.institution_id AND is_active = true
    ) THEN
      RAISE EXCEPTION 'institution_inactive';
    END IF;
  END IF;

  -- Una vez asignada, institution_id no puede cambiarse desde el cliente
  IF TG_OP = 'UPDATE' THEN
    IF NEW.institution_id IS DISTINCT FROM OLD.institution_id AND auth.role() = 'authenticated' THEN
      -- Solo permitimos el cambio si es a través del sistema (ej. función admin) o al inicializar
      IF OLD.institution_id IS NOT NULL THEN
        RAISE EXCEPTION 'cannot_change_institution';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
"""

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    ssh.connect(host, username=user, password=password)
    stdin, stdout, stderr = ssh.exec_command('cat > /tmp/fix_trigger.sql')
    stdin.write(script_content)
    stdin.channel.shutdown_write()
    
    cmd = 'docker exec -i supabase-db psql -U postgres -d postgres < /tmp/fix_trigger.sql'
    stdin, stdout, stderr = ssh.exec_command(cmd)
    
    out = stdout.read().decode()
    err = stderr.read().decode()
    print("SQL Output:", out)
    print("SQL Error:", err)
        
finally:
    ssh.close()
