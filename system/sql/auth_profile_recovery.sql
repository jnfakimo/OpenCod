-- ============================================================
-- Supabase Auth / public.users 帳戶同步修復（可重複執行）
--
-- 用途：Auth 已有 Email，但 public.users 沒有對應帳戶時，允許已登入的
-- 系統管理員補建或重新連結帳戶清單。只新增或更新，不刪除任何資料。
-- ============================================================

alter table public.users
  add column if not exists permissions jsonb default '{}'::jsonb;

create or replace function public.recover_auth_user_profile(
  p_email text,
  p_name text,
  p_username text,
  p_phone text default null,
  p_dept_id uuid default null,
  p_role text default 'inspector',
  p_rbac_role text default 'reporter',
  p_permissions jsonb default '{}'::jsonb
)
returns table(user_id uuid, auth_id uuid, repaired boolean)
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_auth_id uuid;
  v_user_id uuid;
  v_profile_auth_id uuid;
  v_creator_id uuid;
begin
  if auth.uid() is null or not exists (
    select 1
    from public.users u
    where u.auth_id = auth.uid()
      and u.status = 'active'
      and (u.role = 'admin' or u.rbac_role in ('admin', 'sysadmin'))
  ) then
    raise exception '僅限已登入的系統管理員修復帳戶資料'
      using errcode = '42501';
  end if;

  if nullif(btrim(p_email), '') is null
     or nullif(btrim(p_name), '') is null
     or nullif(btrim(p_username), '') is null then
    raise exception 'Email、姓名與登入帳號為必填'
      using errcode = '22023';
  end if;

  if p_role not in ('admin', 'inspector', 'maintenance', 'supervisor') then
    raise exception '不支援的帳戶角色：%', p_role
      using errcode = '22023';
  end if;

  if p_rbac_role not in (
    'reporter', 'duty', 'dispatcher', 'technician',
    'unit_supervisor', 'mgmt_supervisor', 'sysadmin', 'admin'
  ) then
    raise exception '不支援的 RBAC 角色：%', p_rbac_role
      using errcode = '22023';
  end if;

  select au.id
    into v_auth_id
  from auth.users au
  where lower(au.email) = lower(btrim(p_email))
  order by au.created_at
  limit 1;

  if v_auth_id is null then
    raise exception '找不到此 Email 的 Supabase Auth 帳號'
      using errcode = 'P0002';
  end if;

  select u.user_id
    into v_creator_id
  from public.users u
  where u.auth_id = auth.uid()
  limit 1;

  select u.user_id, u.auth_id
    into v_user_id, v_profile_auth_id
  from public.users u
  where u.auth_id = v_auth_id
     or lower(u.email) = lower(btrim(p_email))
  order by (u.auth_id = v_auth_id) desc, u.created_at
  limit 1;

  if exists (
    select 1
    from public.users u
    where lower(u.username) = lower(btrim(p_username))
      and (v_user_id is null or u.user_id <> v_user_id)
  ) then
    raise exception '此登入帳號已存在'
      using errcode = '23505';
  end if;

  if v_user_id is not null then
    if v_profile_auth_id is not null and v_profile_auth_id <> v_auth_id then
      raise exception '帳戶清單中的 Email 已連結其他 Auth 身分'
        using errcode = '23505';
    end if;

    update public.users
    set auth_id = v_auth_id,
        name = p_name,
        username = p_username,
        email = lower(btrim(p_email)),
        phone = nullif(btrim(p_phone), ''),
        dept_id = p_dept_id,
        role = p_role,
        rbac_role = p_rbac_role,
        permissions = coalesce(p_permissions, '{}'::jsonb),
        status = 'active'
    where public.users.user_id = v_user_id;

    return query select v_user_id, v_auth_id, true;
    return;
  end if;

  insert into public.users (
    auth_id, name, username, email, phone, dept_id,
    role, rbac_role, permissions, status, created_by
  ) values (
    v_auth_id, p_name, p_username, lower(btrim(p_email)),
    nullif(btrim(p_phone), ''), p_dept_id,
    p_role, p_rbac_role, coalesce(p_permissions, '{}'::jsonb),
    'active', v_creator_id
  )
  returning public.users.user_id into v_user_id;

  return query select v_user_id, v_auth_id, true;
end;
$$;

revoke all on function public.recover_auth_user_profile(
  text, text, text, text, uuid, text, text, jsonb
) from public;

grant execute on function public.recover_auth_user_profile(
  text, text, text, text, uuid, text, text, jsonb
) to authenticated;
