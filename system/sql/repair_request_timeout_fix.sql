-- ============================================================
-- 報修單送出 timeout 修復
-- 適用狀況：
-- 1. 新增報修出現 "canceling statement due to statement timeout"
-- 2. repair_requests 尚未有 mobile / fault_location 欄位
-- 3. 新版表單已移除「設備」欄位，但資料庫仍強制 equipment_id 不可空
--
-- 請在 Supabase SQL Editor 執行一次。可重複執行。
-- ============================================================

-- 新版新增報修表單需要的欄位
alter table public.repair_requests add column if not exists mobile text;
alter table public.repair_requests add column if not exists fault_location text;
alter table public.repair_requests add column if not exists equipment_category text;
alter table public.repair_requests add column if not exists location_id uuid references public.locations(location_id);
alter table public.repair_requests add column if not exists impact_level text;
alter table public.repair_requests add column if not exists urgency text default 'normal';
alter table public.repair_requests add column if not exists affects_operation boolean default false;
alter table public.repair_requests add column if not exists desired_finish timestamptz;
alter table public.repair_requests add column if not exists hidden boolean default false;
alter table public.repair_requests add column if not exists updated_at timestamptz default now();

-- 前端已移除設備欄位，直接報修可先不綁設備，避免 equipment_id 外鍵檢查 timeout。
alter table public.repair_requests alter column equipment_id drop not null;

-- 確認狀態值涵蓋新版流程
alter table public.repair_requests drop constraint if exists repair_requests_status_check;
alter table public.repair_requests add constraint repair_requests_status_check
  check (status in (
    'pending','transferred','assigned','accepted','in_progress','waiting_parts',
    'waiting_vendor','pending_review','completed','closed','returned','rejected',
    'cancelled','overdue'
  ));

-- 確認 RLS 寫入政策含 with check，避免 insert 被舊政策卡住。
alter table public.repair_requests enable row level security;
drop policy if exists "allow_all_for_now" on public.repair_requests;
create policy "allow_all_for_now" on public.repair_requests
  for all using (true) with check (true);

-- 讓 PostgREST/Supabase 立即刷新欄位快取。
notify pgrst, 'reload schema';
