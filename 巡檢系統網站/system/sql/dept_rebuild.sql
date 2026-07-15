-- ============================================================
-- 部門結構安全同步（永久資料版）
-- 只新增或更新部門，不清空 users.dept_id、不刪除任何既有部門。
-- 可安全重複執行；未知或自訂部門會原樣保留。
-- ============================================================

begin;

create temporary table if not exists desired_departments (
  name text not null,
  code text primary key,
  parent_code text,
  level int not null,
  sort_order int not null
) on commit drop;

truncate desired_departments;

insert into desired_departments (name,code,parent_code,level,sort_order) values
  ('董事長室','BOARD',null,1,10),
  ('總經理室','GM',null,1,20),
  ('副總經理室','VGM',null,1,30),
  ('秘書室','SECRE',null,1,40),
  ('稽核室','AUDIT',null,1,50),
  ('勞工安全衛生室','LABOR-SAFE',null,1,60),
  ('管理部','MGMT',null,1,70),
  ('業務部','BIZ',null,1,80),
  ('資訊部','IT',null,1,90),
  ('企劃部','PLAN',null,1,100),
  ('財務部','FIN',null,1,110),
  ('第二市場','MKT2',null,1,120),
  ('第一市場','MKT1',null,1,130),
  ('改建辦公室','RENO',null,1,140),
  ('總務課','MGMT-GEN','MGMT',2,1),
  ('人事課','MGMT-HR','MGMT',2,2),
  ('出納課','MGMT-FIN','MGMT',2,3),
  ('機電課','MGMT-MECH','MGMT',2,4),
  ('蔬菜課','BIZ-VEG','BIZ',2,1),
  ('貿易課','BIZ-TRADE','BIZ',2,2),
  ('營業管理課','BIZ-SALES','BIZ',2,3),
  ('有機蔬果課','BIZ-ORG','BIZ',2,4),
  ('蔬菜採購課','BIZ-VEG-BUY','BIZ',2,5),
  ('水果採購課','BIZ-FRUIT-BUY','BIZ',2,6),
  ('物流運輸課','BIZ-LOGI','BIZ',2,7),
  ('電商行銷課','BIZ-ECOM','BIZ',2,8),
  ('系統管理課','IT-SYS','IT',2,1),
  ('資訊管理課','IT-MGMT','IT',2,2),
  ('企劃推廣課','PLAN-PROMO','PLAN',2,1),
  ('研究發展課','PLAN-RD','PLAN',2,2),
  ('財務一課','FIN-1','FIN',2,1),
  ('財務二課','FIN-2','FIN',2,2),
  ('蔬菜組','MKT2-VEG','MKT2',2,1),
  ('水果組','MKT2-FRUIT','MKT2',2,2),
  ('業管組','MKT2-ADMIN','MKT2',2,3),
  ('駐衛隊','MKT2-GUARD','MKT2',2,4),
  ('水果組','MKT1-FRUIT','MKT1',2,1),
  ('蔬菜組','MKT1-VEG','MKT1',2,2),
  ('業管組','MKT1-ADMIN','MKT1',2,3),
  ('駐衛隊','MKT1-GUARD','MKT1',2,4);

-- 先同步第一層，保留原 dept_id，避免人員外鍵失效。
insert into departments (name,code,parent_id,level,sort_order,status)
select name,code,null,level,sort_order,'active'
from desired_departments where parent_code is null
on conflict (code) do update set
  name=excluded.name,
  level=excluded.level,
  sort_order=excluded.sort_order,
  status='active';

-- 再同步第二層並連結已存在的父部門，同樣保留原 dept_id。
insert into departments (name,code,parent_id,level,sort_order,status)
select d.name,d.code,p.dept_id,d.level,d.sort_order,'active'
from desired_departments d
join departments p on p.code=d.parent_code
where d.parent_code is not null
on conflict (code) do update set
  name=excluded.name,
  parent_id=excluded.parent_id,
  level=excluded.level,
  sort_order=excluded.sort_order,
  status='active';

commit;
