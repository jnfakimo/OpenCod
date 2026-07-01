-- ============================================================
-- 平面圖整合標記 — B1 整合標記系統
-- 臺北農產運銷股份有限公司 第一果菜市場
-- Version 1.0  |  Run ONCE in Supabase SQL Editor（idempotent）
-- ============================================================
-- 用途：在各樓層平面圖上放置標記點（設備 / 空間 / 報修 / 一般），
--       座標以 OpenSeadragon viewport 正規化座標儲存，隨平面圖同步縮放/旋轉。
-- ============================================================

create table if not exists plan_markers (
  marker_id    uuid primary key default gen_random_uuid(),
  floor_id     text not null,                          -- B1 / 1F / 2F / 3F
  x            double precision not null,              -- OSD viewport x
  y            double precision not null,              -- OSD viewport y
  kind         text not null default 'note'
               check (kind in ('equipment','space','repair','note')),
  label        text not null,                          -- 標記名稱（顯示文字）
  equipment_id uuid references equipment(equipment_id) on delete set null,
  space_id     uuid references floor_spaces(space_id)  on delete set null,
  color        text,                                   -- 選填自訂色，null 則依 kind
  note         text,
  status       text not null default 'active' check (status in ('active','inactive')),
  created_at   timestamptz default now(),
  updated_at   timestamptz default now(),
  created_by   uuid references users(user_id)
);

create index if not exists idx_plan_markers_floor on plan_markers(floor_id);

-- ── RLS ────────────────────────────────────────────────────
alter table plan_markers enable row level security;
drop policy if exists "allow_all_for_now" on plan_markers;
create policy "allow_all_for_now" on plan_markers for all using (true);

-- ── updated_at 觸發器 ──────────────────────────────────────
create or replace function set_plan_markers_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_plan_markers_updated_at on plan_markers;
create trigger trg_plan_markers_updated_at
  before update on plan_markers
  for each row execute function set_plan_markers_updated_at();
