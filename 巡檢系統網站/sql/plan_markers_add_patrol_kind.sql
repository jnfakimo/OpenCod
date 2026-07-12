-- ============================================================
-- 新增「巡邏點標示」標記類型 (patrol)
-- Run ONCE in Supabase SQL Editor（idempotent）
-- ============================================================
-- 原本 plan_markers.kind 只允許 equipment/space/repair/note，
-- 「空間」標記類型名稱已還原，另外新增獨立的「巡邏點標示」類型 (kind='patrol')。

alter table plan_markers drop constraint if exists plan_markers_kind_check;
alter table plan_markers add constraint plan_markers_kind_check
  check (kind in ('equipment','space','patrol','repair','note'));
