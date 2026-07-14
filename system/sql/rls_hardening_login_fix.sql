-- ============================================================
-- HOTFIX for rls_hardening.sql — restores login
-- ============================================================
--
-- PROBLEM:
-- login.html resolves the typed 帳號 (username) to an email
-- BEFORE calling auth.signInWithPassword() — at that point the
-- browser has no session yet, so auth.uid() is null. The
-- "users_select" policy from rls_hardening.sql requires
-- auth.uid() is not null, so that pre-login lookup now returns
-- zero rows and every login fails with "找不到帳號".
--
-- FIX:
-- Add a SECURITY DEFINER function that looks up only the email
-- for a given active username. It runs with elevated privilege
-- (bypasses RLS internally) but only ever returns a single email
-- string for an active account — it does not expose the rest of
-- the users table to anonymous callers, so this does not reopen
-- the original "anyone can read the whole users table" hole.
--
-- Run this in the Supabase SQL Editor now — idempotent, safe to
-- re-run. Then also deploy the updated system/login.html (already
-- pushed to GitHub / GitHub Pages) that calls this function
-- instead of querying the users table directly.
-- ============================================================

create or replace function login_lookup_email(p_username text)
returns text
language sql
security definer
set search_path = public
stable
as $$
  select email from users
  where username = p_username and status = 'active'
  limit 1;
$$;

revoke all on function login_lookup_email(text) from public;
grant execute on function login_lookup_email(text) to anon, authenticated;
