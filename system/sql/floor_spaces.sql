-- ============================================================
-- 區域位置表 — 各樓層平面空間名稱
-- 臺北農產運銷股份有限公司 第一果菜市場
-- Version 1.0  |  Run ONCE in Supabase SQL Editor（可重複執行，idempotent）
-- ============================================================
-- 用途：以「樓層」為區隔，維護每一層的「平面空間名稱」。
--       支援整筆匯入 / 整筆匯出（XLSX / CSV）。
-- ============================================================

create table if not exists floor_spaces (
  space_id    uuid primary key default gen_random_uuid(),
  market_id   text not null default 'market1' references markets(market_id),
  floor       text not null,                       -- 樓層（區隔用），例：B1 / 1F / 2F / 3F
  floor_order int  not null default 0,             -- 樓層排序
  space_name  text not null,                       -- 平面空間名稱
  sort_order  int  not null default 0,             -- 同層內排序
  note        text,                                -- 備註（選填）
  status      text not null default 'active' check (status in ('active','inactive')),
  created_at  timestamptz default now(),
  updated_at  timestamptz default now(),
  created_by  uuid references users(user_id),
  constraint uq_floor_space unique (market_id, floor, space_name)
);

create index if not exists idx_floor_spaces_mf on floor_spaces(market_id, floor);

-- ── RLS ────────────────────────────────────────────────────
alter table floor_spaces enable row level security;
drop policy if exists "allow_all_for_now" on floor_spaces;
create policy "allow_all_for_now" on floor_spaces for all using (true);

-- ── updated_at 觸發器 ──────────────────────────────────────
create or replace function set_floor_spaces_updated_at()
returns trigger as $$
begin
  new.updated_at := now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_floor_spaces_updated_at on floor_spaces;
create trigger trg_floor_spaces_updated_at
  before update on floor_spaces
  for each row execute function set_floor_spaces_updated_at();

-- ── 樓層排序輔助（前端亦會套用，此處僅作預設）─────────────
-- B1=10, 1F=20, 2F=30, 3F=40, 4F=50, RF=90
