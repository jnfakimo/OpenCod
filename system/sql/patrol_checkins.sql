-- ============================================================
-- 巡邏點簽到記錄
-- Version 1.0  |  Run ONCE in Supabase SQL Editor（idempotent）
-- ============================================================
-- 用途：掃描巡邏點 QR code 後，記錄「誰、什麼時候、掃了哪個巡邏點」。
-- ============================================================

create table if not exists patrol_checkins (
  checkin_id  uuid primary key default gen_random_uuid(),
  marker_id   uuid references plan_markers(marker_id) on delete cascade,
  floor_id    text,
  label       text,                                 -- 簽到當下的巡邏點名稱快照
  user_id     uuid references users(user_id),
  user_name   text,                                 -- 簽到當下的人員姓名快照
  checkin_at  timestamptz not null default now()
);

create index if not exists idx_patrol_checkins_marker on patrol_checkins(marker_id);
create index if not exists idx_patrol_checkins_time   on patrol_checkins(checkin_at desc);

-- ── RLS ────────────────────────────────────────────────────
alter table patrol_checkins enable row level security;
drop policy if exists "allow_all_for_now" on patrol_checkins;
create policy "allow_all_for_now" on patrol_checkins for all using (true);
