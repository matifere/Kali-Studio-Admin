import paramiko

host = '192.168.0.41'
user = 'mati'
password = '2102'

script_content = """
-- 1. Rename column in plans
ALTER TABLE public.plans RENAME COLUMN max_reservations_per_week TO max_reservations_per_month;

-- 2. Update book_session_if_available
CREATE OR REPLACE FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql SECURITY DEFINER
AS $function$
declare
  v_caller       uuid := auth.uid();
  v_session_inst uuid;
  v_capacity     int;
  v_confirmed    int;
  v_session_date date;
  v_month_start  date;
  v_has_plan     int;
  v_max_per_month int;
  v_used_month   int;
begin
  select capacity, date, institution_id into v_capacity, v_session_date, v_session_inst
  from class_sessions where id = p_session_id and status = 'scheduled';
  if v_capacity is null then return json_build_object('ok', false, 'error', 'session_not_found'); end if;

  if v_session_inst is distinct from kali_institution_id() then return json_build_object('ok', false, 'error', 'forbidden'); end if;
  if p_user_id <> v_caller and not kali_is_admin() then return json_build_object('ok', false, 'error', 'forbidden'); end if;
  if not exists (select 1 from profiles where id = p_user_id and institution_id = v_session_inst) then return json_build_object('ok', false, 'error', 'forbidden'); end if;
  if not exists (select 1 from profiles where id = p_user_id and is_active) then return json_build_object('ok', false, 'error', 'inactive'); end if;

  if exists (select 1 from reservations where session_id = p_session_id and user_id = p_user_id and status = 'confirmed') then return json_build_object('ok', false, 'error', 'already_booked'); end if;

  select count(*) into v_confirmed from reservations where session_id = p_session_id and status = 'confirmed';
  if v_confirmed >= v_capacity then return json_build_object('ok', false, 'error', 'full'); end if;

  select count(*) into v_has_plan from subscriptions
  where user_id = p_user_id and status = 'active' and CURRENT_DATE between start_date and end_date;
  if v_has_plan = 0 then return json_build_object('ok', false, 'error', 'no_plan'); end if;

  select p.max_reservations_per_month into v_max_per_month
  from subscriptions s join plans p on p.id = s.plan_id
  where s.user_id = p_user_id and s.status = 'active' and CURRENT_DATE between s.start_date and s.end_date
  order by s.created_at desc limit 1;

  if v_max_per_month is not null then
    v_month_start := date_trunc('month', v_session_date)::date;
    select count(*) into v_used_month from reservations r
    join class_sessions cs on cs.id = r.session_id
    where r.user_id = p_user_id and r.status = 'confirmed' 
      and cs.date >= v_month_start and cs.date < v_month_start + interval '1 month';
      
    if v_used_month >= v_max_per_month then return json_build_object('ok', false, 'error', 'monthly_limit_exceeded'); end if;
  end if;

  insert into reservations (user_id, session_id, status, institution_id)
  values (p_user_id, p_session_id, 'confirmed', v_session_inst)
  on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

  return json_build_object('ok', true);
end;
$function$;

-- 3. Update promote_waitlist_on_cancellation
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

  select coalesce(v_session.name, st.name, 'la clase') into v_class_name
  from (select 1) as one left join schedule_templates st on st.id = v_session.template_id;

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

-- 4. Notify PostgREST cache reload
NOTIFY pgrst, 'reload schema';
"""

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    ssh.connect(host, username=user, password=password)
    stdin, stdout, stderr = ssh.exec_command('cat > /tmp/fix_month.sql')
    stdin.write(script_content)
    stdin.channel.shutdown_write()
    
    cmd = 'docker exec -i supabase-db psql -U postgres -d postgres < /tmp/fix_month.sql'
    stdin, stdout, stderr = ssh.exec_command(cmd)
    
    out = stdout.read().decode()
    err = stderr.read().decode()
    print("SQL Output:", out)
    print("SQL Error:", err)
        
finally:
    ssh.close()
