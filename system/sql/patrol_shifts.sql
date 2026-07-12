-- ============================================================
-- 駐衛警巡檢系統：班別排程
-- Version 1.0  |  Run ONCE in Supabase SQL Editor（idempotent）
-- ============================================================
-- patrol_shift_template：預設班別範本（只存一份，方便快速套用到新的一天）
-- patrol_shifts        ：實際生效的每日班別，逐日獨立可調整
-- 巡檢點沿用 plan_markers（kind='patrol'），簽到記錄沿用 checkin_logs，
-- 不需要新表。
-- ============================================================

create table if not exists patrol_shift_template (
  template_id uuid primary key default gen_random_uuid(),
  name        text not null,
  start_time  time not null,
  end_time    time not null,
  sort_order  int not null default 0
);

create table if not exists patrol_shifts (
  shift_id    uuid primary key default gen_random_uuid(),
  shift_date  date not null,
  name        text not null,
  start_time  time not null,
  end_time    time not null,
  sort_order  int not null default 0,
  created_at  timestamptz default now()
);
create unique index if not exists idx_patrol_shifts_date_name on patrol_shifts(shift_date, name);
create index if not exists idx_patrol_shifts_date on patrol_shifts(shift_date);

-- ── RLS ────────────────────────────────────────────────────
alter table patrol_shift_template enable row level security;
drop policy if exists "allow_all_for_now" on patrol_shift_template;
create policy "allow_all_for_now" on patrol_shift_template for all using (true);

alter table patrol_shifts enable row level security;
drop policy if exists "allow_all_for_now" on patrol_shifts;
create policy "allow_all_for_now" on patrol_shifts for all using (true);

-- ── 預設範本（可在後台自行調整）──────────────────────────────
insert into patrol_shift_template (name, start_time, end_time, sort_order)
select * from (values
  ('早班','08:00','12:00',1),
  ('午班','12:00','17:00',2),
  ('晚班','17:00','22:00',3),
  ('夜班','22:00','08:00',4)
) as v(name, start_time, end_time, sort_order)
where not exists (select 1 from patrol_shift_template);
