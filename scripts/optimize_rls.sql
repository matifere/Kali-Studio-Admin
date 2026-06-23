-- 1. Create the sync function
CREATE OR REPLACE FUNCTION public.sync_profiles_to_app_metadata()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  -- Update auth.users with the role, institution_id, and is_active from profiles
  UPDATE auth.users
  SET raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || 
      jsonb_build_object(
        'role', NEW.role,
        'institution_id', NEW.institution_id,
        'is_active', NEW.is_active
      )
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

-- 2. Create the trigger on profiles
DROP TRIGGER IF EXISTS trg_sync_profiles_to_app_metadata ON public.profiles;
CREATE TRIGGER trg_sync_profiles_to_app_metadata
AFTER INSERT OR UPDATE OF role, institution_id, is_active
ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.sync_profiles_to_app_metadata();

-- 3. Backfill existing profiles to auth.users
UPDATE auth.users u
SET raw_app_meta_data = coalesce(u.raw_app_meta_data, '{}'::jsonb) || 
    jsonb_build_object(
      'role', p.role,
      'institution_id', p.institution_id,
      'is_active', p.is_active
    )
FROM public.profiles p
WHERE u.id = p.id;

-- 4. Update kali_is_admin to check JWT first
CREATE OR REPLACE FUNCTION public.kali_is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT coalesce(
    CASE 
      WHEN (auth.jwt() -> 'app_metadata' ->> 'role') IS NOT NULL THEN
        coalesce((auth.jwt() -> 'app_metadata' ->> 'is_active')::boolean, true) = true 
        AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin', 'sudo')
      ELSE NULL
    END,
    exists(select 1 from profiles where id = auth.uid() and is_active and role in ('admin','sudo'))
  )
$function$;

-- 5. Update kali_institution_id to check JWT first
CREATE OR REPLACE FUNCTION public.kali_institution_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT coalesce(
    CASE 
      WHEN (auth.jwt() -> 'app_metadata' ->> 'role') IS NOT NULL THEN
        CASE 
          WHEN coalesce((auth.jwt() -> 'app_metadata' ->> 'is_active')::boolean, true) = true THEN
            (auth.jwt() -> 'app_metadata' ->> 'institution_id')::uuid
          ELSE NULL
        END
      ELSE NULL
    END,
    (select institution_id from profiles where id = auth.uid() and is_active)
  )
$function$;
