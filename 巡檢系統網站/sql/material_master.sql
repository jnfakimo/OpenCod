-- ============================================================
-- 材料基本資料 Material Master — 設備 / 材料 / 備品主檔
-- 臺北農產運銷股份有限公司 第一果菜市場
-- Version 1.0 | Run ONCE in Supabase SQL Editor（idempotent，可重複執行）
-- 用途：設備維護、巡檢、保養、報修、庫存管理共用主檔
-- ============================================================

-- ── 1. 材料分類（獨立管理）────────────────────────────────
create table if not exists material_categories (
  category_id uuid primary key default gen_random_uuid(),
  code        text unique not null,          -- 分類代碼（用於材料編號前綴）
  name        text not null,                 -- 分類名稱
  sort_order  int  not null default 0,
  status      text not null default 'active' check (status in ('active','inactive'))
);

insert into material_categories (code,name,sort_order) values
  ('ELE','電氣材料',10),('MEC','機械材料',20),('FIR','消防設備',30),
  ('HVA','空調設備',40),('WAT','給排水材料',50),('PIP','管材',60),
  ('VAL','閥件',70),('BEA','軸承',80),('MOT','馬達',90),
  ('SEN','感測器',100),('PLC','PLC控制元件',110),('CAB','電纜線材',120),
  ('LIG','照明設備',130),('HAR','五金零件',140),('LUB','潤滑油品',150),
  ('CLN','清潔耗材',160),('SAF','安全防護用品',170),('TOL','工具',180),
  ('SPR','備品零件',190),('OTH','其他',200)
on conflict (code) do nothing;

-- ── 2. 材料基本資料 Material Master ───────────────────────
create table if not exists materials (
  material_id        uuid primary key default gen_random_uuid(),
  -- 一、基本識別
  material_code      text unique,                 -- 材料編號（邏輯編碼：分類-樓層-流水號）
  material_name      text not null,               -- 材料名稱
  material_alias     text,                         -- 材料別名
  category_id        uuid references material_categories(category_id),
  sub_category       text,                         -- 材料子分類
  material_type      text,                         -- 材料類型（設備/備品/耗材…）
  status             text not null default 'active' check (status in ('active','inactive')),
  -- 位置（第一欄樓層 + 區域位置表 / 既有設備連結）
  floor              text,                         -- 樓層（B1/1F/2F/3F…）— 清單第一欄
  space_id           uuid references floor_spaces(space_id),   -- 平面空間（區域位置表）
  equipment_id       uuid references equipment(equipment_id),  -- 連結既有設備
  location_id        uuid references locations(location_id),
  -- 二、規格屬性
  brand              text, manufacturer text, model text, specification text,
  size               text, color text, material_txt text, unit text,
  weight             text, capacity text, voltage text, current_a text, power text,
  frequency          text, pressure text, temperature_range text,
  waterproof_level   text, ip_rating text,
  -- 三、採購資訊
  supplier           text, supplier_code text, original_manufacturer text, country text,
  purchase_price     numeric(14,2), currency text default 'TWD',
  warranty           text, lead_time int,
  -- 四、庫存資訊
  safety_stock       numeric(14,2), current_stock numeric(14,2),
  maximum_stock      numeric(14,2), minimum_stock numeric(14,2),
  storage_location   text, shelf text, batch_number text, expiry_date date,
  -- 五、管理資訊
  qr_code            text,          -- QR 內容（掃描導向設備連結檔 / 明細）
  barcode            text, rfid text, asset_tag text,
  -- 六、附件資訊（檔案連結）
  product_image      text, datasheet_url text, manual_url text, sds_url text,
  certificate_url    text, cad_file_url text, bim_file_url text,
  -- 七、巡檢相關
  inspection_required boolean default false,
  inspection_cycle   text, maintenance_cycle text, replacement_cycle text,
  critical_level     text, risk_level text,
  -- 八、備註
  description        text, remark text,
  -- 稽核
  created_at         timestamptz default now(),
  updated_at         timestamptz default now(),
  created_by         uuid references users(user_id),
  updated_by         uuid references users(user_id)
);

create index if not exists idx_materials_floor    on materials(floor);
create index if not exists idx_materials_category on materials(category_id);
create index if not exists idx_materials_code      on materials(material_code);

-- ── 3. RLS ────────────────────────────────────────────────
alter table material_categories enable row level security;
alter table materials           enable row level security;
drop policy if exists "allow_all_for_now" on material_categories;
drop policy if exists "allow_all_for_now" on materials;
create policy "allow_all_for_now" on material_categories for all using (true);
create policy "allow_all_for_now" on materials           for all using (true);

-- ── 4. updated_at 觸發器 ──────────────────────────────────
create or replace function set_materials_updated_at()
returns trigger as $$
begin new.updated_at := now(); return new; end;
$$ language plpgsql;
drop trigger if exists trg_materials_updated_at on materials;
create trigger trg_materials_updated_at
  before update on materials for each row execute function set_materials_updated_at();

-- ── 5. 材料編號邏輯：分類代碼-樓層-流水號（例 ELE-B1-0001）──
-- 前端 materials.html 會自動產生；此函式供 SQL 端手動補號使用
create or replace function gen_material_code(p_cat text, p_floor text)
returns text as $$
declare pre text; n int;
begin
  pre := coalesce(nullif(upper(p_cat),''),'OTH') || '-' || coalesce(nullif(upper(p_floor),''),'NA') || '-';
  select coalesce(max((regexp_replace(material_code, '^.*-', ''))::int),0)+1
    into n from materials where material_code like pre || '%';
  return pre || lpad(n::text, 4, '0');
end;
$$ language plpgsql;
