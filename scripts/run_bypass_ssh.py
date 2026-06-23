import paramiko

host = '192.168.0.41'
user = 'mati'
password = '2102'

script_content = """
CREATE OR REPLACE FUNCTION public.bypass_saas_subscription(p_plan_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_institution_id uuid;
BEGIN
  v_institution_id := public.kali_institution_id();
  
  INSERT INTO public.tenant_subscriptions (
    institution_id,
    saas_plan_id,
    status,
    current_period_start,
    current_period_end
  ) VALUES (
    v_institution_id,
    p_plan_id,
    'active',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + interval '1 month'
  )
  ON CONFLICT ON CONSTRAINT unique_institution_subscription
  DO UPDATE SET
    saas_plan_id = EXCLUDED.saas_plan_id,
    status = 'active',
    current_period_start = EXCLUDED.current_period_start,
    current_period_end = EXCLUDED.current_period_end,
    mp_preapproval_id = NULL;
END;
$function$;
"""

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    ssh.connect(host, username=user, password=password)
    stdin, stdout, stderr = ssh.exec_command('cat > /tmp/bypass_mp.sql')
    stdin.write(script_content)
    stdin.channel.shutdown_write()
    
    cmd = 'docker exec -i supabase-db psql -U postgres -d postgres < /tmp/bypass_mp.sql'
    stdin, stdout, stderr = ssh.exec_command(cmd)
    
    out = stdout.read().decode()
    err = stderr.read().decode()
    print("SQL Output:", out)
    print("SQL Error:", err)
        
finally:
    ssh.close()
