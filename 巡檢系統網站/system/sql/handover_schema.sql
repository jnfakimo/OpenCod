-- ============================================================
-- 電子交接簿 — 臺北農產 設備巡檢維修系統
-- Version 1.0  |  Run ONCE in Supabase SQL Editor
-- ============================================================

create table if not exists handover_records (
  record_id    uuid        primary key default gen_random_uuid(),
  shift_date   date        not null default current_date,
  shift_type   text        not null default 'morning'
                             check (shift_type in ('morning','afternoon','night')),
  dept_id      uuid        references departments(dept_id),
  location_id  uuid        references locations(location_id),
  handover_by  uuid        references users(user_id),
  takeover_by  uuid        references users(user_id),
  eq_normal    int         not null default 0,
  eq_abnormal  int         not null default 0,
  issues       text        not null default '',   -- newline-separated
  pending      text        not null default '',   -- newline-separated
  notes        text        not null default '',
  status       text        not null default 'draft'
                             check (status in ('draft','confirmed')),
  created_by   uuid        references users(user_id),
  created_at   timestamptz default now(),
  confirmed_at timestamptz,
  confirmed_by uuid        references users(user_id)
);

-- 雙層交接稽核：
-- draft = 草稿；confirmed 且 confirmed_by/confirmed_at 尚空白 = 已送出、待指定接班人接收；
-- confirmed_by 必須等於 takeover_by 且 confirmed_at 有值，前端才判定為交接完成。
comment on column handover_records.confirmed_by is '實際點選接收的接班人；必須與 takeover_by 相同才算交接完成';
comment on column handover_records.confirmed_at is '指定接班人點選接收的時間；空白表示尚未完成交接';

create index if not exists idx_ho_date on handover_records(shift_date desc);
create index if not exists idx_ho_dept on handover_records(dept_id);

alter table handover_records enable row level security;
create policy "allow_all_for_now" on handover_records for all using (true);
