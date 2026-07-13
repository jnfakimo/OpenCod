# PROJECT_CONTEXT — 臺北農產 第一果菜市場 設備巡檢 / 報修派工系統

> 給後續開發者 / AI 代理的專案脈絡文件。每次接手前請先讀本檔，避免重複踩雷。

---

## 1. 專案概述

- **業主**：臺北農產運銷股份有限公司 — 第一果菜市場
- **性質**：純前端（多頁 HTML）＋ Supabase 後端的設備**巡檢 / 報修 / 派工 / 維修**管理系統，含樓層平面圖與 3D 立體模型。
- **UI 風格**：Cyberpunk 深色霓虹主題。核心色票：
  - `--bg:#020b18`、`--panel:#041428`／`#05101e`、`--border:#0c2840`／`#0a3a5a`
  - `--cyan:#00d4ff`（主色，發光）、`--green:#00ff9d`、`--amber:#ffb300`、`--red:#ff3b3b`／`#ff5470`
  - 字型：`Noto Sans TC` + `Rajdhani`（標題）
- **語言**：介面全繁體中文。

---

## 2. 部署 / 環境

- **前端**：GitHub Pages，**從 `main` 分支自動部署**（workflow：`pages build and deployment`）。
  - 網址基底：`https://jnfakimo.github.io/word-cloud/system/<page>.html`
  - 倉庫：`jnfakimo/word-cloud`
- **後端**：Supabase（PostgreSQL + PostgREST + Auth + Storage）
  - Project ref：`qztffronusdhgxhjjubt`
  - URL：`https://qztffronusdhgxhjjubt.supabase.co`
  - 前端用 **anon key** 直連（各 HTML 內硬編 `SUPA_URL` / `SUPA_KEY`）。
  - RLS 目前多為 `allow_all_for_now`（開發階段全開）。
- **Storage buckets**：`floorplans`（樓層平面圖 PNG）、`repair-files`（報修附件）。
- **Edge Function**：`supabase/functions/line-notify/`（LINE 通知）。
- **驗證限制**：本開發環境的外連 proxy 會擋 CDN / github.io 的直接 curl（回 000/403）。
  **無法用 curl 驗證線上頁面**，改用：`node --check` 語法檢查 ＋ GitHub Actions 部署狀態（`mcp__github__actions_list`）。

---

## 3. 技術棧（全部走 CDN，無建置步驟）

| 用途 | 函式庫 |
|---|---|
| 後端 SDK | `@supabase/supabase-js@2` |
| 2D 平面圖深縮放 | OpenSeadragon 4.1.0（DZI 磚圖 / Storage image） |
| 3D 立體樓層 | Three.js r128 |
| XLSX / CSV 匯入匯出 | SheetJS `xlsx@0.18.5`（`aoa_to_sheet` / `sheet_to_json` / `writeFile`） |
| 圖表 | Chart.js |
| QR Code | qrcodejs |
| 平面圖產製（離線） | Python：ezdxf（解析 DXF）、matplotlib（渲染）、PIL（bloom/tiling） |

---

## 4. 頁面清單（`system/*.html`）

> 根目錄另有 `index.html`／`admin.html`／`app.html`／`maintenance.html` 為舊入口，實際系統在 `system/`。

**入口 / 核心**
- `index.html` — 系統入口　`login.html` — 登入　`setup.html` — 系統初始化
- `app.html` — 巡檢系統　`admin.html` — 後台管理（左側選單為各子系統樞紐）

**報修派工管理系統（P1–P6，企業級 14 模組規劃的已完成部分）**
- `workorder.html` — 報修系統（新增報修、派工、案件流程）
- `dashboard.html` — 戰情儀表板　`analytics.html` — 統計分析
- `equipment.html` — 設備履歷　`rbac.html` — 權限管理 RBAC
- `notices.html` — 通知中心　`api.html` — 整合 API 文件
- `maintenance.html` — 舊維修管理（已被 `workorder.html` 取代，導覽一律指向報修系統）

**場域 / 樓層 / 3D**
- `locations.html` — 場域位置管理（市場→樓層→區域→細節階層樹，可收合）
- `arealist.html` — **區域位置表**（各樓層平面空間名稱；兩欄「樓層／空間名稱」；XLSX/CSV 整筆匯入匯出）
- `b1plan.html` — 樓層平面圖（B1/1F/2F/3F，OpenSeadragon 自由平移縮放旋轉）
- `b1_integrated_marker_system.html` — **整合標記系統**（在平面圖上放置設備/空間/報修點/一般標記，隨圖縮放旋轉）
- `floor3d.html` — 3D 立體樓層模型　`inspection3d.html` — 3D 巡檢地圖
- `modeler.html` — 3D 模型建模系統（上傳 DXF → 產生平面圖 + 3D）
- `handover.html` — 電子交接簿

---

## 5. 資料庫 SQL（`system/sql/`）— 執行順序

所有 SQL 皆設計為 **idempotent（可重複執行）**：用 `create table if not exists`、`add column if not exists`、`drop policy if exists` 後再 create。

於 Supabase SQL Editor 依序執行：

1. `schema.sql` — 核心表（equipment / inspection_records / repair_requests / maintenance_orders …）
2. `locations_schema.sql` — markets / locations / departments（自動 seed 第一、第二市場）
3. `work_order_schema.sql` — 報修派工擴充（req_no/wo_no 自動編號、case_status_log、roles、role_permissions、notifications、repair-files bucket）
4. `floor_models.sql` — 樓層平面圖模型表（供 b1plan / floor3d / marker 讀底圖）
5. `handover_schema.sql` / `handover_cases.sql` — 電子交接簿
6. `floor_spaces.sql` — **區域位置表**（各樓層平面空間名稱）
7. `plan_markers.sql` — **整合標記**（外鍵參照 equipment / floor_spaces / repair_requests，故須在 6 之後）
8. `material_master.sql` — 材料與備品主檔
9. `patrol_shifts.sql` / `checkin_logs.sql` — 駐衛警班別與簽到紀錄
10. `rls_hardening.sql` / `rls_hardening_login_fix.sql` — 正式環境權限
11. `permanent_data_protection.sql` — **最後執行**；禁止實體刪除/清空並建立人員異動快照

輔助 / 修補：`dept_rebuild.sql`、`org_update.sql`、`repair_request_timeout_fix.sql`。
`dept_rebuild.sql` 現為安全增量同步，不會清空人員部門或刪除既有部門。

**永久保存原則**：正式資料只能新增、修改或設為 `inactive`，不可重建資料庫、
`TRUNCATE` 或實體 `DELETE` 人員與業務歷程。所有人員異動會寫入 `users_history`。

**⚠️ 新增/改欄位時**：若表已存在，`create table if not exists` 不會補欄位 → 必須另外寫 `alter table ... add column if not exists`（見 `plan_markers.sql` 的 `repair_id` 範例）。

---

## 6. 關鍵慣例 / 已知雷點

- **樓層命名不一致**：區域位置表匯入資料常見「B1F/1F」，平面圖系統用「B1/1F/2F/3F」。
  跨系統比對樓層時請用正規化：`B1≈B1F`、`1F≈1`、`RF≈頂樓`
  （參考 `b1_integrated_marker_system.html` 的 `canonicalFloor()`）。
- **市場**：主要使用 `market1`（第一市場）、`market2`（第二市場）；其他舊市場只停用、不刪除。
- **標記座標**：`plan_markers` 存 OpenSeadragon viewport 正規化座標（x,y），才能隨圖縮放/旋轉對位。
- **平面圖對位**：B1/1F/2F/3F 用同一 world frame 與像素網格疊放，故可上下層對齊。
- **報修表單**（workorder 新增報修）現況：聯絡人/單位/電話自帳號自動帶入、手機必填、無「設備」欄、故障位置為自由文字、故障位置照片必填、希望完成日期為「點選年月日」。

---

## 7. 開發 / Git 流程（多代理並行）

- **本專案常有多個 AI 代理同時對 `main` 推送** → 直接 push 易被 non-fast-forward 打回。
- 標準流程：
  1. `git fetch origin main && git reset --hard origin/main`（或 rebase）取最新
  2. 編輯 → `node --check`（或 vm.compileFunction 驗證內嵌 JS）
  3. `git commit` → `git rebase origin/main` → `git push origin main`
  4. 同步指定開發分支：`git branch -f <branch> HEAD && git push origin <branch> --force-with-lease`
- 指定開發分支：`claude/system-implementation-gjoi5k`
- **勿在未經允許下開 PR。**

### 業主的長期指示（standing instructions）
- **「有關連一併修正」**：改動某系統時，所有相關系統要一起更新（例：改導覽名稱、共用資料表、樓層對應）。
- **一次只用一個 AI**（避免並行衝突）。

---

## 8. 快速接手檢查清單

- [ ] `git fetch origin main && git reset --hard origin/main`
- [ ] 需要新表/欄位？在 `system/sql/` 寫 idempotent SQL，並提醒業主到 Supabase 執行
- [ ] 改完頁面用 `node --check` 驗證內嵌 JS
- [ ] 部署後用 `mcp__github__actions_list` 確認 `pages build and deployment` 為 success（無法 curl 線上頁）
- [ ] 有跨系統關聯時，落實「有關連一併修正」
