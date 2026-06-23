--
-- PostgreSQL database dump
--

-- Dumped from database version 15.8
-- Dumped by pg_dump version 15.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: day_of_week; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.day_of_week AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
);


ALTER TYPE public.day_of_week OWNER TO postgres;

--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_method AS ENUM (
    'mercadopago',
    'stripe',
    'manual'
);


ALTER TYPE public.payment_method OWNER TO postgres;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'refunded'
);


ALTER TYPE public.payment_status OWNER TO postgres;

--
-- Name: reservation_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.reservation_status AS ENUM (
    'confirmed',
    'cancelled',
    'attended',
    'no_show'
);


ALTER TYPE public.reservation_status OWNER TO postgres;

--
-- Name: session_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.session_status AS ENUM (
    'scheduled',
    'cancelled',
    'paused',
    'completed'
);


ALTER TYPE public.session_status OWNER TO postgres;

--
-- Name: subscription_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.subscription_status AS ENUM (
    'active',
    'expired',
    'cancelled',
    'pending'
);


ALTER TYPE public.subscription_status OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'client',
    'sudo'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: book_session_if_available(uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid) RETURNS json
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  v_caller       uuid := auth.uid();
  v_session_inst uuid;
  v_capacity     int;
  v_confirmed    int;
  v_session_date date;
  v_week_start   date;
  v_week_end     date;
  v_has_plan     int;
  v_max_per_week int;
  v_used_week    int;
begin
  select capacity, date, institution_id into v_capacity, v_session_date, v_session_inst
  from class_sessions where id = p_session_id and status = 'scheduled';
  if v_capacity is null then return json_build_object('ok', false, 'error', 'session_not_found'); end if;

  -- la sesion debe ser de la institucion del caller (no cross-tenant)
  if v_session_inst is distinct from kali_institution_id() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  -- reservas para uno mismo, o un admin/sudo reservando para un alumno (no IDOR)
  if p_user_id <> v_caller and not kali_is_admin() then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  -- el usuario destino debe pertenecer a la misma institucion
  if not exists (select 1 from profiles where id = p_user_id and institution_id = v_session_inst) then
    return json_build_object('ok', false, 'error', 'forbidden');
  end if;

  -- destino activo
  if not exists (select 1 from profiles where id = p_user_id and is_active) then
    return json_build_object('ok', false, 'error', 'inactive');
  end if;

  if exists (select 1 from reservations where session_id = p_session_id and user_id = p_user_id and status = 'confirmed') then
    return json_build_object('ok', false, 'error', 'already_booked');
  end if;

  select count(*) into v_confirmed from reservations where session_id = p_session_id and status = 'confirmed';
  if v_confirmed >= v_capacity then return json_build_object('ok', false, 'error', 'full'); end if;

  select count(*) into v_has_plan from subscriptions
  where user_id = p_user_id and status = 'active' and CURRENT_DATE between start_date and end_date;
  if v_has_plan = 0 then return json_build_object('ok', false, 'error', 'no_plan'); end if;

  select p.max_reservations_per_week into v_max_per_week
  from subscriptions s join plans p on p.id = s.plan_id
  where s.user_id = p_user_id and s.status = 'active' and CURRENT_DATE between s.start_date and s.end_date
  order by s.created_at desc limit 1;

  if v_max_per_week is not null then
    v_week_start := date_trunc('week', v_session_date)::date;
    v_week_end   := v_week_start + 6;
    select count(*) into v_used_week from reservations r
    join class_sessions cs on cs.id = r.session_id
    where r.user_id = p_user_id and r.status = 'confirmed' and cs.date between v_week_start and v_week_end;
    if v_used_week >= v_max_per_week then return json_build_object('ok', false, 'error', 'weekly_limit_exceeded'); end if;
  end if;

  insert into reservations (user_id, session_id, status, institution_id)
  values (p_user_id, p_session_id, 'confirmed', v_session_inst)
  on conflict (user_id, session_id) do update set status = 'confirmed', cancelled_at = null, cancelled_by = null;

  return json_build_object('ok', true);
end;
$$;


ALTER FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid) OWNER TO postgres;

--
-- Name: create_institution(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_institution(inst_name text, inst_slug text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  new_inst_id uuid;
BEGIN
  -- Insertar la nueva institución y obtener su ID
  INSERT INTO institutions (name, slug) 
  VALUES (inst_name, inst_slug) 
  RETURNING id INTO new_inst_id;
  
  -- Actualizar el perfil del usuario con la nueva institución y rol sudo
  UPDATE profiles 
  SET institution_id = new_inst_id, role = 'sudo' 
  WHERE id = auth.uid();
  
  RETURN new_inst_id;
END;
$$;


ALTER FUNCTION public.create_institution(inst_name text, inst_slug text) OWNER TO postgres;

--
-- Name: fill_profile_email(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fill_profile_email() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
begin
  if new.email is null or new.email = '' then
    select email into new.email from auth.users where id = new.id;
  end if;
  return new;
end;
$$;


ALTER FUNCTION public.fill_profile_email() OWNER TO postgres;

--
-- Name: generate_sessions_from_template(uuid, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_sessions_from_template(p_template_id uuid, p_weeks integer DEFAULT 4) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_template      schedule_templates%ROWTYPE;
    v_target_dow    INTEGER;
    v_current_dow   INTEGER;
    v_day_offset    INTEGER;
    v_date          DATE;
    i               INTEGER;
BEGIN
    SELECT * INTO v_template 
    FROM schedule_templates 
    WHERE id = p_template_id AND is_active = TRUE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Plantilla no encontrada o inactiva: %', p_template_id;
    END IF;

    -- Convertimos el enum day_of_week a número (0=domingo ... 6=sábado)
    -- usando la convención estándar de EXTRACT(DOW ...)
    v_target_dow := CASE v_template.day_of_week
        WHEN 'sunday'    THEN 0
        WHEN 'monday'    THEN 1
        WHEN 'tuesday'   THEN 2
        WHEN 'wednesday' THEN 3
        WHEN 'thursday'  THEN 4
        WHEN 'friday'    THEN 5
        WHEN 'saturday'  THEN 6
    END;

    v_current_dow := EXTRACT(DOW FROM CURRENT_DATE);
    v_day_offset  := v_target_dow - v_current_dow;

    -- Si el día ya pasó esta semana, empezamos desde la próxima
    IF v_day_offset < 0 THEN
        v_day_offset := v_day_offset + 7;
    END IF;

    FOR i IN 0..p_weeks - 1 LOOP
        v_date := CURRENT_DATE + (v_day_offset + i * 7) * INTERVAL '1 day';

        -- INSERT ... WHERE NOT EXISTS evita duplicados sin lanzar error
        INSERT INTO class_sessions (
            template_id, name, description,
            date, start_time, end_time,
            capacity, instructor_name
        )
        SELECT
            p_template_id,
            v_template.name,
            v_template.description,
            v_date,
            v_template.start_time,
            v_template.end_time,
            v_template.capacity,
            v_template.instructor_name
        WHERE NOT EXISTS (
            SELECT 1 FROM class_sessions
            WHERE template_id = p_template_id AND date = v_date
        );
    END LOOP;
END;
$$;


ALTER FUNCTION public.generate_sessions_from_template(p_template_id uuid, p_weeks integer) OWNER TO postgres;

--
-- Name: get_available_spots(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_available_spots(p_session_id uuid) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_capacity        INTEGER;
    v_confirmed_count INTEGER;
BEGIN
    SELECT capacity INTO v_capacity 
    FROM class_sessions 
    WHERE id = p_session_id;

    SELECT COUNT(*) INTO v_confirmed_count 
    FROM reservations 
    WHERE session_id = p_session_id 
    AND status = 'confirmed';

    RETURN v_capacity - v_confirmed_count;
END;
$$;


ALTER FUNCTION public.get_available_spots(p_session_id uuid) OWNER TO postgres;

--
-- Name: get_dates_with_available_sessions(date, date, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid DEFAULT NULL::uuid) RETURNS TABLE(date text)
    LANGUAGE sql STABLE
    AS $$
  SELECT DISTINCT cs.date::TEXT
  FROM class_sessions cs
  WHERE cs.date BETWEEN p_from AND p_to
    AND cs.status = 'scheduled'
    AND (p_institution_id IS NULL OR cs.institution_id = p_institution_id);
$$;


ALTER FUNCTION public.get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid) OWNER TO postgres;

--
-- Name: get_institution_mp_token(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_institution_mp_token(p_institution_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_secret_name text;
  v_token text;
BEGIN
  -- Solo service_role puede ejecutar esta función
  IF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT mp_token_secret_name
    INTO v_secret_name
    FROM institutions
   WHERE id = p_institution_id;

  IF v_secret_name IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT decrypted_secret
    INTO v_token
    FROM vault.decrypted_secrets
   WHERE name = v_secret_name;

  RETURN v_token;
END;
$$;


ALTER FUNCTION public.get_institution_mp_token(p_institution_id uuid) OWNER TO postgres;

--
-- Name: get_session_confirmed_counts(uuid[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_session_confirmed_counts(p_session_ids uuid[]) RETURNS TABLE(session_id uuid, confirmed_count integer)
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT session_id, COUNT(*)::INT
  FROM reservations
  WHERE session_id = ANY(p_session_ids)
    AND status = 'confirmed'
  GROUP BY session_id;
$$;


ALTER FUNCTION public.get_session_confirmed_counts(p_session_ids uuid[]) OWNER TO postgres;

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role, institution_id, is_active)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    COALESCE(new.email, ''),
    COALESCE((new.raw_user_meta_data->>'role')::user_role, 'client'::user_role),
    NULLIF(new.raw_user_meta_data->>'institution_id', '')::uuid,
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    full_name      = EXCLUDED.full_name,
    email          = EXCLUDED.email,
    role           = EXCLUDED.role,
    institution_id = EXCLUDED.institution_id;
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user error: %', SQLERRM;
  RETURN new;
END;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: kali_institution_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.kali_institution_id() RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select institution_id from profiles where id = auth.uid() and is_active
$$;


ALTER FUNCTION public.kali_institution_id() OWNER TO postgres;

--
-- Name: kali_is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.kali_is_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists(select 1 from profiles where id = auth.uid() and is_active and role in ('admin','sudo'))
$$;


ALTER FUNCTION public.kali_is_admin() OWNER TO postgres;

--
-- Name: kali_role(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.kali_role() RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  SELECT role::text FROM profiles WHERE id = auth.uid()
$$;


ALTER FUNCTION public.kali_role() OWNER TO postgres;

--
-- Name: profiles_guard_self(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profiles_guard_self() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public', 'auth'
    AS $$
declare
  meta_role text;
begin
  if auth.uid() is not null and new.id = auth.uid() and not public.kali_is_admin() then
    if tg_op = 'UPDATE' then
      new.role := old.role;
      new.is_active := old.is_active;
      if old.institution_id is not null then new.institution_id := old.institution_id; end if;
    elsif tg_op = 'INSERT' then
      -- Honrar el rol del metadata del signup (consistente con handle_new_user),
      -- en lugar de forzar siempre 'client'. Permite el auto-registro de un dueño (sudo).
      select raw_user_meta_data->>'role' into meta_role
        from auth.users where id = new.id;
      new.role := coalesce(meta_role::user_role, 'client'::user_role);
      new.is_active := true;
    end if;
  end if;
  return new;
end;
$$;


ALTER FUNCTION public.profiles_guard_self() OWNER TO postgres;

--
-- Name: promote_waitlist_on_cancellation(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.promote_waitlist_on_cancellation() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_session    class_sessions%rowtype;
  v_class_name text;
  v_confirmed  int;
  v_week_start date;
  v_week_end   date;
  v_waiter     record;
  v_limit      int;
  v_used       int;
begin
  if new.status <> 'cancelled' or old.status = 'cancelled' then
    return new;
  end if;

  select * into v_session from class_sessions where id = new.session_id;
  if not found or v_session.status <> 'scheduled' or v_session.date < current_date then
    return new;
  end if;

  select count(*) into v_confirmed
  from reservations where session_id = new.session_id and status = 'confirmed';
  if v_confirmed >= v_session.capacity then
    return new;
  end if;

  select coalesce(v_session.name, st.name, 'la clase') into v_class_name
  from (select 1) as one
  left join schedule_templates st on st.id = v_session.template_id;

  v_week_start := date_trunc('week', v_session.date)::date;
  v_week_end   := v_week_start + 6;

  for v_waiter in
    select w.id, w.user_id
    from waitlist w
    where w.session_id = new.session_id and w.status = 'waiting'
    order by w.created_at asc
    for update skip locked
  loop
    -- plan activo que cubra la fecha de la clase
    select p.max_reservations_per_week into v_limit
    from subscriptions s
    join plans p on p.id = s.plan_id
    where s.user_id = v_waiter.user_id and s.status = 'active'
      and s.start_date <= v_session.date and s.end_date >= v_session.date
    order by s.end_date desc
    limit 1;
    if not found then continue; end if;

    if v_limit is not null then
      select count(*) into v_used
      from reservations r
      join class_sessions cs on cs.id = r.session_id
      where r.user_id = v_waiter.user_id and r.status = 'confirmed'
        and cs.date between v_week_start and v_week_end;
      if v_used >= v_limit then continue; end if;
    end if;

    -- ya tiene reserva confirmada en esta sesión: limpiar la fila huérfana y seguir
    if exists (
      select 1 from reservations
      where user_id = v_waiter.user_id and session_id = new.session_id
        and status = 'confirmed'
    ) then
      delete from waitlist where id = v_waiter.id;
      continue;
    end if;

    -- revive la fila cancelada si existía (UNIQUE user_id, session_id)
    insert into reservations (user_id, session_id, status, institution_id)
    values (v_waiter.user_id, new.session_id, 'confirmed', v_session.institution_id)
    on conflict (user_id, session_id) do update
      set status = 'confirmed', cancelled_at = null, cancelled_by = null;

    delete from waitlist where id = v_waiter.id;

    insert into notifications (user_id, title, body, type)
    values (
      v_waiter.user_id,
      '¡Conseguiste un lugar!',
      'Se liberó un lugar en ' || v_class_name || ' del '
        || to_char(v_session.date, 'DD/MM')
        || '. Ya estás inscripto automáticamente.',
      'waitlist'
    );

    exit;
  end loop;

  return new;
exception when others then
  -- la promoción nunca debe impedir la cancelación original
  raise warning 'promote_waitlist_on_cancellation: %', sqlerrm;
  return new;
end;
$$;


ALTER FUNCTION public.promote_waitlist_on_cancellation() OWNER TO postgres;

--
-- Name: update_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at() OWNER TO postgres;

--
-- Name: validate_profile_institution(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.validate_profile_institution() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
  IF TG_OP = 'UPDATE'
     AND OLD.institution_id IS NOT NULL
     AND NEW.institution_id IS DISTINCT FROM OLD.institution_id THEN
    RAISE EXCEPTION 'institution_id_cannot_be_changed';
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.validate_profile_institution() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: class_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.class_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_id uuid,
    name text NOT NULL,
    description text,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    capacity integer NOT NULL,
    status public.session_status DEFAULT 'scheduled'::public.session_status NOT NULL,
    cancellation_reason text,
    instructor_name text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    institution_id uuid,
    CONSTRAINT end_after_start CHECK ((end_time > start_time)),
    CONSTRAINT valid_capacity CHECK ((capacity > 0))
);


ALTER TABLE public.class_sessions OWNER TO postgres;

--
-- Name: institutions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.institutions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    address text,
    phone text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    logo_url text,
    mp_token_secret_name text,
    payment_alias text
);


ALTER TABLE public.institutions OWNER TO postgres;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    body text NOT NULL,
    type text DEFAULT 'general'::text NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notifications OWNER TO postgres;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    subscription_id uuid,
    amount numeric(10,2) NOT NULL,
    currency text DEFAULT 'ARS'::text NOT NULL,
    method public.payment_method,
    status public.payment_status DEFAULT 'pending'::public.payment_status NOT NULL,
    notes text,
    processed_by uuid,
    payment_date timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    preference_id text,
    institution_id uuid
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    price numeric(10,2) NOT NULL,
    currency text DEFAULT 'ARS'::text NOT NULL,
    max_reservations_per_week integer,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    institution_id uuid
);


ALTER TABLE public.plans OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    full_name text,
    phone text,
    avatar_url text,
    role public.user_role DEFAULT 'client'::public.user_role NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    email text,
    patologias text[],
    institution_id uuid
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: push_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.push_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    endpoint text NOT NULL,
    p256dh text NOT NULL,
    auth_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.push_subscriptions OWNER TO postgres;

--
-- Name: reservations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    session_id uuid NOT NULL,
    status public.reservation_status DEFAULT 'confirmed'::public.reservation_status NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by uuid,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    institution_id uuid
);


ALTER TABLE public.reservations OWNER TO postgres;

--
-- Name: saas_plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.saas_plans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    price numeric NOT NULL,
    currency text DEFAULT 'ARS'::text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    mp_plan_id text
);


ALTER TABLE public.saas_plans OWNER TO postgres;

--
-- Name: schedule_templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schedule_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    day_of_week public.day_of_week NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    capacity integer DEFAULT 20 NOT NULL,
    instructor_name text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    institution_id uuid,
    CONSTRAINT end_after_start CHECK ((end_time > start_time)),
    CONSTRAINT valid_capacity CHECK ((capacity > 0))
);


ALTER TABLE public.schedule_templates OWNER TO postgres;

--
-- Name: sessions_with_availability; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.sessions_with_availability AS
SELECT
    NULL::uuid AS id,
    NULL::uuid AS template_id,
    NULL::text AS name,
    NULL::text AS description,
    NULL::date AS date,
    NULL::time without time zone AS start_time,
    NULL::time without time zone AS end_time,
    NULL::integer AS capacity,
    NULL::public.session_status AS status,
    NULL::text AS instructor_name,
    NULL::bigint AS confirmed_count,
    NULL::bigint AS available_spots,
    NULL::timestamp with time zone AS created_at,
    NULL::timestamp with time zone AS updated_at;


ALTER TABLE public.sessions_with_availability OWNER TO postgres;

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    plan_id uuid NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status public.subscription_status DEFAULT 'pending'::public.subscription_status NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    institution_id uuid,
    CONSTRAINT end_after_start CHECK ((end_date > start_date))
);


ALTER TABLE public.subscriptions OWNER TO postgres;

--
-- Name: tenant_subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tenant_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    institution_id uuid NOT NULL,
    saas_plan_id uuid NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    mp_preapproval_id text,
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tenant_subscriptions OWNER TO postgres;

--
-- Name: waitlist; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.waitlist (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    session_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    status text DEFAULT 'waiting'::text,
    CONSTRAINT waitlist_status_check CHECK ((status = ANY (ARRAY['waiting'::text, 'notified'::text, 'expired'::text])))
);


ALTER TABLE public.waitlist OWNER TO postgres;

--
-- Name: class_sessions class_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_user_id_key UNIQUE (user_id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: saas_plans saas_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.saas_plans
    ADD CONSTRAINT saas_plans_pkey PRIMARY KEY (id);


--
-- Name: schedule_templates schedule_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_templates
    ADD CONSTRAINT schedule_templates_pkey PRIMARY KEY (id);


--
-- Name: institutions studios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT studios_pkey PRIMARY KEY (id);


--
-- Name: institutions studios_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.institutions
    ADD CONSTRAINT studios_slug_key UNIQUE (slug);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tenant_subscriptions tenant_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_subscriptions
    ADD CONSTRAINT tenant_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: tenant_subscriptions unique_institution_subscription; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_subscriptions
    ADD CONSTRAINT unique_institution_subscription UNIQUE (institution_id);


--
-- Name: class_sessions unique_template_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT unique_template_date UNIQUE (template_id, date);


--
-- Name: reservations unique_user_session; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT unique_user_session UNIQUE (user_id, session_id);


--
-- Name: waitlist waitlist_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_pkey PRIMARY KEY (id);


--
-- Name: waitlist waitlist_user_id_session_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_user_id_session_id_key UNIQUE (user_id, session_id);


--
-- Name: idx_class_sessions_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_class_sessions_date ON public.class_sessions USING btree (date);


--
-- Name: idx_class_sessions_status_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_class_sessions_status_date ON public.class_sessions USING btree (status, date);


--
-- Name: idx_class_sessions_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_class_sessions_template_id ON public.class_sessions USING btree (template_id);


--
-- Name: idx_payments_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_payments_user_id ON public.payments USING btree (user_id);


--
-- Name: idx_reservations_session_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservations_session_id ON public.reservations USING btree (session_id);


--
-- Name: idx_reservations_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservations_user_id ON public.reservations USING btree (user_id);


--
-- Name: idx_subscriptions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_subscriptions_user_id ON public.subscriptions USING btree (user_id);


--
-- Name: notifications_user_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX notifications_user_created_idx ON public.notifications USING btree (user_id, created_at DESC);


--
-- Name: sessions_with_availability _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.sessions_with_availability AS
 SELECT cs.id,
    cs.template_id,
    cs.name,
    cs.description,
    cs.date,
    cs.start_time,
    cs.end_time,
    cs.capacity,
    cs.status,
    cs.instructor_name,
    count(r.id) FILTER (WHERE (r.status = 'confirmed'::public.reservation_status)) AS confirmed_count,
    (cs.capacity - count(r.id) FILTER (WHERE (r.status = 'confirmed'::public.reservation_status))) AS available_spots,
    cs.created_at,
    cs.updated_at
   FROM (public.class_sessions cs
     LEFT JOIN public.reservations r ON ((cs.id = r.session_id)))
  GROUP BY cs.id;


--
-- Name: reservations notify-waitlist; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "notify-waitlist" AFTER UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://tmfcnvtjzmtpqhzvfxos.supabase.co/functions/v1/dynamic-processor', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRtZmNudnRqem10cHFoenZmeG9zIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mzg2ODY2NiwiZXhwIjoyMDg5NDQ0NjY2fQ.ZJJXQ0Nd3UZoBQYovlXgAzUcaIa7eW5hTuA_hXiWcmA"}', '{}', '5000');


--
-- Name: profiles profiles_fill_email; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profiles_fill_email BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.fill_profile_email();


--
-- Name: profiles profiles_guard_self; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profiles_guard_self BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.profiles_guard_self();


--
-- Name: class_sessions trg_class_sessions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_class_sessions_updated_at BEFORE UPDATE ON public.class_sessions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: payments trg_payments_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: plans trg_plans_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_plans_updated_at BEFORE UPDATE ON public.plans FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: profiles trg_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: reservations trg_promote_waitlist; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_promote_waitlist AFTER UPDATE OF status ON public.reservations FOR EACH ROW WHEN (((new.status = 'cancelled'::public.reservation_status) AND (old.status <> 'cancelled'::public.reservation_status))) EXECUTE FUNCTION public.promote_waitlist_on_cancellation();


--
-- Name: reservations trg_reservations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_reservations_updated_at BEFORE UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: schedule_templates trg_schedule_templates_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_schedule_templates_updated_at BEFORE UPDATE ON public.schedule_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: subscriptions trg_subscriptions_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


--
-- Name: profiles trg_validate_profile_institution; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_validate_profile_institution BEFORE INSERT OR UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.validate_profile_institution();


--
-- Name: class_sessions class_sessions_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE CASCADE;


--
-- Name: class_sessions class_sessions_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.class_sessions
    ADD CONSTRAINT class_sessions_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.schedule_templates(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: payments payments_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE CASCADE;


--
-- Name: payments payments_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.profiles(id);


--
-- Name: payments payments_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- Name: payments payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: plans plans_studio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_studio_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_studio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_studio_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id);


--
-- Name: push_subscriptions push_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_cancelled_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES public.profiles(id);


--
-- Name: reservations reservations_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: schedule_templates schedule_templates_studio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schedule_templates
    ADD CONSTRAINT schedule_templates_studio_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id);


--
-- Name: subscriptions subscriptions_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: subscriptions subscriptions_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.plans(id);


--
-- Name: subscriptions subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


--
-- Name: tenant_subscriptions tenant_subscriptions_institution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_subscriptions
    ADD CONSTRAINT tenant_subscriptions_institution_id_fkey FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE CASCADE;


--
-- Name: tenant_subscriptions tenant_subscriptions_saas_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tenant_subscriptions
    ADD CONSTRAINT tenant_subscriptions_saas_plan_id_fkey FOREIGN KEY (saas_plan_id) REFERENCES public.saas_plans(id) ON DELETE RESTRICT;


--
-- Name: waitlist waitlist_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.class_sessions(id) ON DELETE CASCADE;


--
-- Name: waitlist waitlist_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.waitlist
    ADD CONSTRAINT waitlist_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: payments Admins can insert payments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can insert payments" ON public.payments FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'sudo'::public.user_role)))));


--
-- Name: reservations Admins can update reservations in their institution; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can update reservations in their institution" ON public.reservations FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.class_sessions cs ON ((cs.institution_id = p.institution_id)))
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['sudo'::public.user_role, 'admin'::public.user_role])) AND (cs.id = reservations.session_id)))));


--
-- Name: reservations Admins can view all reservations in their institution; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can view all reservations in their institution" ON public.reservations FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.profiles p
     JOIN public.class_sessions cs ON ((cs.institution_id = p.institution_id)))
  WHERE ((p.id = auth.uid()) AND (p.role = ANY (ARRAY['sudo'::public.user_role, 'admin'::public.user_role])) AND (cs.id = reservations.session_id)))));


--
-- Name: saas_plans Planes SaaS visibles para usuarios autenticados; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Planes SaaS visibles para usuarios autenticados" ON public.saas_plans FOR SELECT TO authenticated USING (true);


--
-- Name: push_subscriptions Users manage own subscriptions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users manage own subscriptions" ON public.push_subscriptions USING ((auth.uid() = user_id)) WITH CHECK ((auth.uid() = user_id));


--
-- Name: tenant_subscriptions Usuarios ven solo la suscripción de su institución; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Usuarios ven solo la suscripción de su institución" ON public.tenant_subscriptions FOR SELECT TO authenticated USING ((institution_id IN ( SELECT profiles.institution_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: class_sessions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.class_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: class_sessions class_sessions_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY class_sessions_delete ON public.class_sessions FOR DELETE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: class_sessions class_sessions_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY class_sessions_insert ON public.class_sessions FOR INSERT TO authenticated WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: class_sessions class_sessions_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY class_sessions_select ON public.class_sessions FOR SELECT TO authenticated USING ((institution_id = public.kali_institution_id()));


--
-- Name: class_sessions class_sessions_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY class_sessions_update ON public.class_sessions FOR UPDATE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin())) WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: institutions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications notifications_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_select ON public.notifications FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: notifications notifications_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY notifications_update ON public.notifications FOR UPDATE TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: plans; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

--
-- Name: plans plans_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY plans_delete ON public.plans FOR DELETE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: plans plans_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY plans_insert ON public.plans FOR INSERT TO authenticated WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: plans plans_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY plans_select ON public.plans FOR SELECT TO authenticated USING ((institution_id = public.kali_institution_id()));


--
-- Name: plans plans_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY plans_update ON public.plans FOR UPDATE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin())) WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_delete ON public.profiles FOR DELETE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: profiles profiles_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_insert ON public.profiles FOR INSERT TO authenticated WITH CHECK (((id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin())));


--
-- Name: profiles profiles_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated USING ((((id = auth.uid()) AND is_active) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin())));


--
-- Name: profiles profiles_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_update ON public.profiles FOR UPDATE TO authenticated USING (((id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin()))) WITH CHECK (((id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin())));


--
-- Name: push_subscriptions push_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY push_own ON public.push_subscriptions USING ((auth.uid() = user_id));


--
-- Name: push_subscriptions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.push_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: reservations; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: reservations reservations_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reservations_delete ON public.reservations FOR DELETE TO authenticated USING (((user_id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin())));


--
-- Name: reservations reservations_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reservations_insert ON public.reservations FOR INSERT TO authenticated WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: reservations reservations_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reservations_select ON public.reservations FOR SELECT TO authenticated USING (((institution_id = public.kali_institution_id()) OR (user_id = auth.uid())));


--
-- Name: reservations reservations_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY reservations_update ON public.reservations FOR UPDATE TO authenticated USING (((user_id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin()))) WITH CHECK (((user_id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin())));


--
-- Name: saas_plans; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.saas_plans ENABLE ROW LEVEL SECURITY;

--
-- Name: schedule_templates; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.schedule_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: schedule_templates schedule_templates_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY schedule_templates_delete ON public.schedule_templates FOR DELETE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: schedule_templates schedule_templates_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY schedule_templates_insert ON public.schedule_templates FOR INSERT TO authenticated WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: schedule_templates schedule_templates_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY schedule_templates_select ON public.schedule_templates FOR SELECT TO authenticated USING ((institution_id = public.kali_institution_id()));


--
-- Name: schedule_templates schedule_templates_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY schedule_templates_update ON public.schedule_templates FOR UPDATE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin())) WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: payments staff_read_institution_payments; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY staff_read_institution_payments ON public.payments FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.profiles staff
     JOIN public.profiles student ON ((student.id = payments.user_id)))
  WHERE ((staff.id = auth.uid()) AND (staff.role = ANY (ARRAY['sudo'::public.user_role, 'admin'::public.user_role])) AND (staff.institution_id = student.institution_id)))));


--
-- Name: institutions studios_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY studios_read ON public.institutions FOR SELECT TO authenticated USING (true);


--
-- Name: institutions studios_read_anon; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY studios_read_anon ON public.institutions FOR SELECT TO anon USING (true);


--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions subscriptions_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subscriptions_delete ON public.subscriptions FOR DELETE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: subscriptions subscriptions_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subscriptions_insert ON public.subscriptions FOR INSERT TO authenticated WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: subscriptions subscriptions_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subscriptions_select ON public.subscriptions FOR SELECT TO authenticated USING (((user_id = auth.uid()) OR ((institution_id = public.kali_institution_id()) AND public.kali_is_admin())));


--
-- Name: subscriptions subscriptions_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY subscriptions_update ON public.subscriptions FOR UPDATE TO authenticated USING (((institution_id = public.kali_institution_id()) AND public.kali_is_admin())) WITH CHECK (((institution_id = public.kali_institution_id()) AND public.kali_is_admin()));


--
-- Name: tenant_subscriptions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.tenant_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: waitlist users manage own waitlist; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "users manage own waitlist" ON public.waitlist TO authenticated USING ((user_id = auth.uid())) WITH CHECK ((user_id = auth.uid()));


--
-- Name: waitlist; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

--
-- Name: waitlist waitlist_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY waitlist_own ON public.waitlist USING ((auth.uid() = user_id));


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION book_session_if_available(p_session_id uuid, p_user_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.book_session_if_available(p_session_id uuid, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION create_institution(inst_name text, inst_slug text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_institution(inst_name text, inst_slug text) TO anon;
GRANT ALL ON FUNCTION public.create_institution(inst_name text, inst_slug text) TO authenticated;
GRANT ALL ON FUNCTION public.create_institution(inst_name text, inst_slug text) TO service_role;


--
-- Name: FUNCTION fill_profile_email(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.fill_profile_email() TO anon;
GRANT ALL ON FUNCTION public.fill_profile_email() TO authenticated;
GRANT ALL ON FUNCTION public.fill_profile_email() TO service_role;


--
-- Name: FUNCTION generate_sessions_from_template(p_template_id uuid, p_weeks integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generate_sessions_from_template(p_template_id uuid, p_weeks integer) TO anon;
GRANT ALL ON FUNCTION public.generate_sessions_from_template(p_template_id uuid, p_weeks integer) TO authenticated;
GRANT ALL ON FUNCTION public.generate_sessions_from_template(p_template_id uuid, p_weeks integer) TO service_role;


--
-- Name: FUNCTION get_available_spots(p_session_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_available_spots(p_session_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_available_spots(p_session_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_available_spots(p_session_id uuid) TO service_role;


--
-- Name: FUNCTION get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_dates_with_available_sessions(p_from date, p_to date, p_institution_id uuid) TO service_role;


--
-- Name: FUNCTION get_institution_mp_token(p_institution_id uuid); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION public.get_institution_mp_token(p_institution_id uuid) FROM PUBLIC;
GRANT ALL ON FUNCTION public.get_institution_mp_token(p_institution_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_institution_mp_token(p_institution_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_institution_mp_token(p_institution_id uuid) TO service_role;


--
-- Name: FUNCTION get_session_confirmed_counts(p_session_ids uuid[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.get_session_confirmed_counts(p_session_ids uuid[]) TO anon;
GRANT ALL ON FUNCTION public.get_session_confirmed_counts(p_session_ids uuid[]) TO authenticated;
GRANT ALL ON FUNCTION public.get_session_confirmed_counts(p_session_ids uuid[]) TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION kali_institution_id(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.kali_institution_id() TO anon;
GRANT ALL ON FUNCTION public.kali_institution_id() TO authenticated;
GRANT ALL ON FUNCTION public.kali_institution_id() TO service_role;


--
-- Name: FUNCTION kali_is_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.kali_is_admin() TO anon;
GRANT ALL ON FUNCTION public.kali_is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.kali_is_admin() TO service_role;


--
-- Name: FUNCTION kali_role(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.kali_role() TO anon;
GRANT ALL ON FUNCTION public.kali_role() TO authenticated;
GRANT ALL ON FUNCTION public.kali_role() TO service_role;


--
-- Name: FUNCTION profiles_guard_self(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.profiles_guard_self() TO anon;
GRANT ALL ON FUNCTION public.profiles_guard_self() TO authenticated;
GRANT ALL ON FUNCTION public.profiles_guard_self() TO service_role;


--
-- Name: FUNCTION promote_waitlist_on_cancellation(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.promote_waitlist_on_cancellation() TO anon;
GRANT ALL ON FUNCTION public.promote_waitlist_on_cancellation() TO authenticated;
GRANT ALL ON FUNCTION public.promote_waitlist_on_cancellation() TO service_role;


--
-- Name: FUNCTION update_updated_at(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at() TO service_role;


--
-- Name: FUNCTION validate_profile_institution(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.validate_profile_institution() TO anon;
GRANT ALL ON FUNCTION public.validate_profile_institution() TO authenticated;
GRANT ALL ON FUNCTION public.validate_profile_institution() TO service_role;


--
-- Name: TABLE class_sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.class_sessions TO anon;
GRANT ALL ON TABLE public.class_sessions TO authenticated;
GRANT ALL ON TABLE public.class_sessions TO service_role;


--
-- Name: TABLE institutions; Type: ACL; Schema: public; Owner: postgres
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.institutions TO anon;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.institutions TO authenticated;
GRANT ALL ON TABLE public.institutions TO service_role;


--
-- Name: TABLE notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.notifications TO anon;
GRANT ALL ON TABLE public.notifications TO authenticated;
GRANT ALL ON TABLE public.notifications TO service_role;


--
-- Name: TABLE payments; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.payments TO anon;
GRANT ALL ON TABLE public.payments TO authenticated;
GRANT ALL ON TABLE public.payments TO service_role;


--
-- Name: TABLE plans; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.plans TO anon;
GRANT ALL ON TABLE public.plans TO authenticated;
GRANT ALL ON TABLE public.plans TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE push_subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.push_subscriptions TO anon;
GRANT ALL ON TABLE public.push_subscriptions TO authenticated;
GRANT ALL ON TABLE public.push_subscriptions TO service_role;


--
-- Name: TABLE reservations; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.reservations TO anon;
GRANT ALL ON TABLE public.reservations TO authenticated;
GRANT ALL ON TABLE public.reservations TO service_role;


--
-- Name: TABLE saas_plans; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.saas_plans TO anon;
GRANT ALL ON TABLE public.saas_plans TO authenticated;
GRANT ALL ON TABLE public.saas_plans TO service_role;


--
-- Name: TABLE schedule_templates; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.schedule_templates TO anon;
GRANT ALL ON TABLE public.schedule_templates TO authenticated;
GRANT ALL ON TABLE public.schedule_templates TO service_role;


--
-- Name: TABLE sessions_with_availability; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sessions_with_availability TO anon;
GRANT ALL ON TABLE public.sessions_with_availability TO authenticated;
GRANT ALL ON TABLE public.sessions_with_availability TO service_role;


--
-- Name: TABLE subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.subscriptions TO anon;
GRANT ALL ON TABLE public.subscriptions TO authenticated;
GRANT ALL ON TABLE public.subscriptions TO service_role;


--
-- Name: TABLE tenant_subscriptions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.tenant_subscriptions TO anon;
GRANT ALL ON TABLE public.tenant_subscriptions TO authenticated;
GRANT ALL ON TABLE public.tenant_subscriptions TO service_role;


--
-- Name: TABLE waitlist; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.waitlist TO anon;
GRANT ALL ON TABLE public.waitlist TO authenticated;
GRANT ALL ON TABLE public.waitlist TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- PostgreSQL database dump complete
--

