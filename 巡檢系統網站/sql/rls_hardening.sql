-- ============================================================
-- RLS Hardening — close the "anyone with the anon key" hole
-- ============================================================
--
-- PROBLEM:
-- Every table currently uses a policy like:
--   create policy "allow_all_for_now" on <table> for all using (true);
-- The Supabase anon key is also hardcoded in every system/*.html
-- page (by design — this is a no-build static-HTML app). Combined,
-- this means ANYONE who views page source and copies the anon key
-- can read/write every table directly via the PostgREST API,
-- with zero login — including the `users` table (role escalation)
-- and `system_settings` (holds the LINE channel token).
--
-- FIX:
-- Require a logged-in Supabase Auth session (auth.uid() is not
-- null) for all API access. This does NOT change what a logged-in
-- staff member can do — every page already authenticates via
-- login.html / db.auth.getSession() — it only blocks requests that
-- carry the anon key but no session, which today is anyone.
--
-- ⚠ BEFORE RUNNING THIS IN PRODUCTION:
--   1. Confirm every page you actually use requires login first
--      (open each system/*.html in a private/incognito window
--      with no prior session and check it doesn't silently work
--      via the anon key alone — most pages already tolerate a
--      null session in JS without hard-redirecting to login.html,
--      so double-check nothing currently depends on anonymous
--      read/write access before flipping this on).
--   2. If you have a Supabase branch/staging project, run it
--      there first and click through the whole app logged in.
--   3. This migration is idempotent — safe to re-run.
-- ============================================================

-- ---- helper: is the logged-in user an admin? ----
create or replace function is_admin() returns boolean
language sql security definer stable as $$
  select exists (
    select 1 from users
    where auth_id = auth.uid()
      and (role = 'admin' or rbac_role = 'admin')
      and status = 'active'
  );
$$;

-- ---- generic tables: swap allow_all_for_now -> must be logged in ----
do $$
declare t text;
begin
  foreach t in array array[
    'equipment','inspection_records','repair_requests','maintenance_orders',
    'cost_records','audit_logs','inspection_cycles',
    'markets','locations','departments',
    'case_status_log','repair_attachments','roles','role_permissions','notifications',
    'floor_models','handover_records','floor_spaces','plan_markers',
    'material_categories','materials'
  ] loop
    execute format('drop policy if exists "allow_all_for_now" on %I', t);
    execute format('drop policy if exists "authenticated_only" on %I', t);
    execute format('create policy "authenticated_only" on %I for all using (auth.uid() is not null) with check (auth.uid() is not null)', t);
  end loop;
end $$;

-- handover_cases.* were created with different policy names (all_access_*)
do $$
declare t text;
begin
  foreach t in array array['handover_cases','handover_case_logs','handover_case_attachments'] loop
    execute format('drop policy if exists "all_access_cases" on %I', t);
    execute format('drop policy if exists "all_access_case_logs" on %I', t);
    execute format('drop policy if exists "all_access_attachments" on %I', t);
    execute format('drop policy if exists "authenticated_only" on %I', t);
    execute format('create policy "authenticated_only" on %I for all using (auth.uid() is not null) with check (auth.uid() is not null)', t);
  end loop;
end $$;

-- ---- users: any logged-in user may read (needed for name/dept
--      dropdowns everywhere); only admins may insert/update/delete,
--      so a regular staff member cannot PATCH their own row to
--      grant themselves role='admin' / rbac_role='admin'. ----
drop policy if exists "allow_all_for_now" on users;
drop policy if exists "authenticated_only" on users;
drop policy if exists "users_select" on users;
drop policy if exists "users_admin_insert" on users;
drop policy if exists "users_admin_update" on users;
drop policy if exists "users_admin_delete" on users;
create policy "users_select"       on users for select using (auth.uid() is not null);
create policy "users_admin_insert" on users for insert with check (is_admin());
create policy "users_admin_update" on users for update using (is_admin()) with check (is_admin());
create policy "users_admin_delete" on users for delete using (is_admin());

-- ---- system_settings: hide line_channel_token (LINE bot secret)
--      from every client; everything else (org name, feature
--      toggles) stays readable by logged-in staff; only admins
--      may write. ----
drop policy if exists "allow_all_for_now" on system_settings;
drop policy if exists "settings_select" on system_settings;
drop policy if exists "settings_admin_insert" on system_settings;
drop policy if exists "settings_admin_update" on system_settings;
drop policy if exists "settings_admin_delete" on system_settings;
create policy "settings_select" on system_settings for select
  using (auth.uid() is not null and key <> 'line_channel_token');
create policy "settings_admin_insert" on system_settings for insert with check (is_admin());
create policy "settings_admin_update" on system_settings for update using (is_admin()) with check (is_admin());
create policy "settings_admin_delete" on system_settings for delete using (is_admin());

-- ---- Storage: require login to upload/replace/delete files.
--      Reads stay public (floor-plan images and repair-file links
--      are rendered as plain <img>/<a> without auth headers). ----
drop policy if exists "floorplans_write"  on storage.objects;
drop policy if exists "floorplans_update" on storage.objects;
drop policy if exists "floorplans_delete" on storage.objects;
create policy "floorplans_write"  on storage.objects for insert with check (bucket_id = 'floorplans' and auth.uid() is not null);
create policy "floorplans_update" on storage.objects for update using (bucket_id = 'floorplans' and auth.uid() is not null);
create policy "floorplans_delete" on storage.objects for delete using (bucket_id = 'floorplans' and auth.uid() is not null);

drop policy if exists "repairfiles_write"  on storage.objects;
drop policy if exists "repairfiles_update" on storage.objects;
drop policy if exists "repairfiles_delete" on storage.objects;
create policy "repairfiles_write"  on storage.objects for insert with check (bucket_id = 'repair-files' and auth.uid() is not null);
create policy "repairfiles_update" on storage.objects for update using (bucket_id = 'repair-files' and auth.uid() is not null);
create policy "repairfiles_delete" on storage.objects for delete using (bucket_id = 'repair-files' and auth.uid() is not null);

-- NOTE: the `handover-attachments` bucket was created manually via
-- the Supabase dashboard (see handover_cases.sql comment) and isn't
-- scripted here — check its Storage policies by hand if it also
-- allows anonymous writes.
