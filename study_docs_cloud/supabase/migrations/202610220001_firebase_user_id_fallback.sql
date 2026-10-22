-- Firebase Authentication supplies the verified user's email and subject
-- (`sub`) in the JWT used by Supabase. Seeded accounts resolve through email
-- to their canonical public.users ID; newly registered Firebase accounts
-- fall back to their Firebase UID if the profile lookup is unavailable.
CREATE OR REPLACE FUNCTION public.current_app_user_id()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (
      SELECT u.id::text
      FROM public.users u
      WHERE lower(u.email) = lower(auth.jwt() ->> 'email')
      LIMIT 1
    ),
    auth.jwt() ->> 'sub'
  )
$$;

GRANT EXECUTE ON FUNCTION public.current_app_user_id() TO anon, authenticated;
