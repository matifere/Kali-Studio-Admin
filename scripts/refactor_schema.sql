-- 1. Make columns nullable in class_sessions
ALTER TABLE public.class_sessions
  ALTER COLUMN name DROP NOT NULL,
  ALTER COLUMN start_time DROP NOT NULL,
  ALTER COLUMN end_time DROP NOT NULL,
  ALTER COLUMN capacity DROP NOT NULL,
  ALTER COLUMN instructor_name DROP NOT NULL;

-- 2. Drop institution_id from reservations and subscriptions
ALTER TABLE public.reservations DROP COLUMN IF EXISTS institution_id;
ALTER TABLE public.subscriptions DROP COLUMN IF EXISTS institution_id;

-- 3. Update RLS policies for reservations
DROP POLICY IF EXISTS reservations_delete ON public.reservations;
CREATE POLICY reservations_delete ON public.reservations FOR DELETE TO authenticated USING (
  (user_id = auth.uid()) OR (
    EXISTS (
      SELECT 1 FROM public.class_sessions cs
      WHERE cs.id = reservations.session_id AND cs.institution_id = public.kali_institution_id()
    ) AND public.kali_is_admin()
  )
);

DROP POLICY IF EXISTS reservations_insert ON public.reservations;
CREATE POLICY reservations_insert ON public.reservations FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.class_sessions cs
    WHERE cs.id = session_id AND cs.institution_id = public.kali_institution_id()
  ) AND public.kali_is_admin()
);

DROP POLICY IF EXISTS reservations_select ON public.reservations;
CREATE POLICY reservations_select ON public.reservations FOR SELECT TO authenticated USING (
  (user_id = auth.uid()) OR (
    EXISTS (
      SELECT 1 FROM public.class_sessions cs
      WHERE cs.id = reservations.session_id AND cs.institution_id = public.kali_institution_id()
    )
  )
);

DROP POLICY IF EXISTS reservations_update ON public.reservations;
CREATE POLICY reservations_update ON public.reservations FOR UPDATE TO authenticated USING (
  (user_id = auth.uid()) OR (
    EXISTS (
      SELECT 1 FROM public.class_sessions cs
      WHERE cs.id = reservations.session_id AND cs.institution_id = public.kali_institution_id()
    ) AND public.kali_is_admin()
  )
) WITH CHECK (
  (user_id = auth.uid()) OR (
    EXISTS (
      SELECT 1 FROM public.class_sessions cs
      WHERE cs.id = session_id AND cs.institution_id = public.kali_institution_id()
    ) AND public.kali_is_admin()
  )
);

-- 4. Update RLS policies for subscriptions
DROP POLICY IF EXISTS subscriptions_delete ON public.subscriptions;
CREATE POLICY subscriptions_delete ON public.subscriptions FOR DELETE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM public.plans p
    WHERE p.id = subscriptions.plan_id AND p.institution_id = public.kali_institution_id()
  ) AND public.kali_is_admin()
);

DROP POLICY IF EXISTS subscriptions_insert ON public.subscriptions;
CREATE POLICY subscriptions_insert ON public.subscriptions FOR INSERT TO authenticated WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.plans p
    WHERE p.id = plan_id AND p.institution_id = public.kali_institution_id()
  ) AND public.kali_is_admin()
);

DROP POLICY IF EXISTS subscriptions_select ON public.subscriptions;
CREATE POLICY subscriptions_select ON public.subscriptions FOR SELECT TO authenticated USING (
  (user_id = auth.uid()) OR (
    EXISTS (
      SELECT 1 FROM public.plans p
      WHERE p.id = subscriptions.plan_id AND p.institution_id = public.kali_institution_id()
    ) AND public.kali_is_admin()
  )
);

DROP POLICY IF EXISTS subscriptions_update ON public.subscriptions;
CREATE POLICY subscriptions_update ON public.subscriptions FOR UPDATE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM public.plans p
    WHERE p.id = subscriptions.plan_id AND p.institution_id = public.kali_institution_id()
  ) AND public.kali_is_admin()
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.plans p
    WHERE p.id = plan_id AND p.institution_id = public.kali_institution_id()
  ) AND public.kali_is_admin()
);

-- 5. Update generate_sessions_from_template
CREATE OR REPLACE FUNCTION public.generate_sessions_from_template(p_template_id uuid, p_weeks integer DEFAULT 4)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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

    IF v_day_offset < 0 THEN
        v_day_offset := v_day_offset + 7;
    END IF;

    FOR i IN 0..p_weeks - 1 LOOP
        v_date := CURRENT_DATE + (v_day_offset + i * 7) * INTERVAL '1 day';

        INSERT INTO class_sessions (
            template_id, 
            date, 
            institution_id
        )
        SELECT
            p_template_id,
            v_date,
            v_template.institution_id
        WHERE NOT EXISTS (
            SELECT 1 FROM class_sessions
            WHERE template_id = p_template_id AND date = v_date
        );
    END LOOP;
END;
$function$;
