import paramiko

host = '192.168.0.41'
user = 'mati'
password = '2102'

sql_content = """
-- 1. Añadir group_id
ALTER TABLE public.class_sessions ADD COLUMN group_id uuid;

-- 2. Migrar datos de schedule_templates a class_sessions
UPDATE public.class_sessions cs
SET 
  name = COALESCE(cs.name, st.name, 'Clase General'),
  description = COALESCE(cs.description, st.description),
  start_time = COALESCE(cs.start_time, st.start_time, '00:00'),
  end_time = COALESCE(cs.end_time, st.end_time, '00:00'),
  capacity = COALESCE(cs.capacity, st.capacity, 1),
  instructor_name = COALESCE(cs.instructor_name, st.instructor_name)
FROM public.schedule_templates st
WHERE cs.template_id = st.id;

-- Para los que no tengan template_id pero tengan nulos (por las dudas)
UPDATE public.class_sessions 
SET 
  name = COALESCE(name, 'Clase General'),
  start_time = COALESCE(start_time, '00:00'),
  end_time = COALESCE(end_time, '00:00'),
  capacity = COALESCE(capacity, 1)
WHERE name IS NULL OR start_time IS NULL OR end_time IS NULL OR capacity IS NULL;

-- 3. Hacer los campos NOT NULL
ALTER TABLE public.class_sessions ALTER COLUMN name SET NOT NULL;
ALTER TABLE public.class_sessions ALTER COLUMN start_time SET NOT NULL;
ALTER TABLE public.class_sessions ALTER COLUMN end_time SET NOT NULL;
ALTER TABLE public.class_sessions ALTER COLUMN capacity SET NOT NULL;

-- 4. Actualizar promote_waitlist_on_cancellation (quitar join con schedule_templates)
CREATE OR REPLACE FUNCTION public.promote_waitlist_on_cancellation()
 RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session    class_sessions%rowtype;
  v_class_name text;
  v_confirmed  int;
  v_month_start date;
  v_waiter     record;
  v_limit      int;
  v_used       int;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then return new; end if;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < current_date then return new; end if;

  select count(*) into v_confirmed from reservations where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then return new; end if;

  v_class_name := v_session.name;
  v_month_start := date_trunc('month', v_session.date)::date;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    select p.max_reservations_per_month into v_limit
    from subscriptions s join plans p on p.id = s.plan_id
    where s.user_id = v_waiter.user_id and s.status = 'active'
      and s.start_date <= v_session.date and s.end_date >= v_session.date
    order by s.end_date desc limit 1;
    
    if not found then continue; end if;

    if v_limit is not null then
      select count(*) into v_used
      from reservations r join class_sessions cs on cs.id = r.session_id
      where r.user_id = v_waiter.user_id and r.status = 'confirmed'
        and cs.date >= v_month_start and cs.date < v_month_start + interval '1 month';
      if v_used >= v_limit then continue; end if;
    end if;

    if exists (select 1 from reservations where user_id = v_waiter.user_id and session_id = new.session_id and status = 'confirmed') then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    insert into reservations (user_id, session_id, status, institution_id)
    values (v_waiter.user_id, new.session_id, 'confirmed', v_session.institution_id)
    on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (v_waiter.user_id, '¡Conseguiste un lugar!', 'Se liberó un lugar en ' || v_class_name || ' del ' || to_char(v_session.date, 'DD/MM') || ' y ya tenés la reserva confirmada.', 'booking');
  end loop;

  return new;
end;
$function$;

-- Nota: book_session_if_available no necesita cambios porque solo leía capacity, date y institution_id de class_sessions directamente (que ya existían).
-- El único otro lugar es admin_assign_student o similares, pero asumo que tampoco usaban schedule_templates porque class_sessions tiene todo ahora.

-- 5. Eliminar generar_sessions_from_template (ya no existe template)
DROP FUNCTION IF EXISTS public.generate_sessions_from_template(uuid, integer);

-- 6. Eliminar FK y columna template_id
DROP VIEW IF EXISTS public.sessions_with_availability CASCADE;
ALTER TABLE public.class_sessions DROP COLUMN template_id CASCADE;

-- 7. Eliminar schedule_templates
DROP TABLE public.schedule_templates CASCADE;

NOTIFY pgrst, 'reload schema';
"""

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    ssh.connect(host, username=user, password=password)
    stdin, stdout, stderr = ssh.exec_command('cat > /tmp/drop_templates.sql')
    stdin.write(sql_content)
    stdin.channel.shutdown_write()
    
    cmd = 'docker exec -i supabase-db psql -U postgres -d postgres < /tmp/drop_templates.sql'
    stdin, stdout, stderr = ssh.exec_command(cmd)
    
    out = stdout.read().decode()
    err = stderr.read().decode()
    print("SQL Output:", out)
    print("SQL Error:", err)
        
finally:
    ssh.close()
