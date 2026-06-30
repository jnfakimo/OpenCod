-- ============================================================
-- 3D 模型建模系統 — 樓層模型資料表 + 儲存桶
-- 在 Supabase SQL Editor 執行一次
-- ============================================================

-- 1) 樓層模型記錄表
create table if not exists floor_models (
  floor_id   text primary key,          -- 例：B1 / 1F / 2F / 3F
  name       text,
  image_path text,                       -- 儲存桶內路徑，例：1F.png
  bbox       jsonb,                       -- DXF 範圍（mm）
  level      int default 0,
  updated_at timestamptz default now()
);

alter table floor_models enable row level security;
drop policy if exists "allow_all_for_now" on floor_models;
create policy "allow_all_for_now" on floor_models for all using (true) with check (true);

-- 2) 建立公開儲存桶 floorplans（存放各樓層 PNG）
insert into storage.buckets (id, name, public)
values ('floorplans','floorplans', true)
on conflict (id) do update set public = true;

-- 3) 允許讀寫該儲存桶（前端以 anon 金鑰上傳）
drop policy if exists "floorplans_read"   on storage.objects;
drop policy if exists "floorplans_write"  on storage.objects;
drop policy if exists "floorplans_update" on storage.objects;
drop policy if exists "floorplans_delete" on storage.objects;
create policy "floorplans_read"   on storage.objects for select using (bucket_id = 'floorplans');
create policy "floorplans_write"  on storage.objects for insert with check (bucket_id = 'floorplans');
create policy "floorplans_update" on storage.objects for update using (bucket_id = 'floorplans');
create policy "floorplans_delete" on storage.objects for delete using (bucket_id = 'floorplans');
