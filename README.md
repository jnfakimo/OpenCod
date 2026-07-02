# 臺北農產 第一果菜市場 — 設備巡檢 / 報修 / 派工系統

A web-based equipment **inspection · repair · dispatch · maintenance** system for
臺北農產運銷股份有限公司 第一果菜市場, with 2D floor-plan and 3D stacked-floor
viewers, an integrated marker layer, a Material Master, and a shift handover log.

- **Live**: https://jnfakimo.github.io/word-cloud/ → forwards to `system/index.html`
- **Stack**: static multi-page HTML/JS (no build) + Supabase (PostgreSQL/Auth/Storage),
  hosted on GitHub Pages. Libraries load from CDNs.
- **Agent notes**: see [`AGENTS.md`](AGENTS.md). Full architecture: [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md).

## Run locally
No install or build — the pages are static and talk to the hosted Supabase directly.
```bash
python3 -m http.server 8080      # then open http://localhost:8080/system/index.html
```
Or just open any `system/*.html` in a browser.

## Project structure
```
index.html            # redirects to system/index.html
system/*.html         # application pages
system/sql/*.sql      # Supabase schema (idempotent)
system/plans/*        # live floor-plan tiles/textures (2D & 3D) — keep
supabase/functions/   # LINE-notify edge function
```

### Main pages (under `system/`)
| Page | 用途 |
|---|---|
| `index.html` / `login.html` | 入口 / 登入 |
| `app.html` | 巡檢 App |
| `admin.html` | 後台管理 |
| `dashboard.html` | 戰情儀表板 |
| `workorder.html` | 報修 / 派工 |
| `materials.html` | 設備材料管理（Material Master） |
| `arealist.html` | 區域位置表（樓層空間） |
| `b1_integrated_marker_system.html` | 整合標記編輯 |
| `b1plan.html` / `floor3d.html` | 2D 平面圖 / 3D 立體樓層 |
| `modeler.html` | 3D 建模（DXF→平面/3D） |
| `handover.html` | 電子交接簿 |
| `analytics.html` / `rbac.html` | 統計分析 / 權限管理 |

## Backend setup (Supabase)
1. Create a Supabase project (or use the configured one, ref `qztffronusdhgxhjjubt`).
2. In the SQL Editor, run the scripts in `system/sql/` in this order:
   `schema.sql` → `locations_schema.sql` → `work_order_schema.sql` → `floor_models.sql`
   → `handover_schema.sql` → `floor_spaces.sql` → `plan_markers.sql` → `material_master.sql`
3. Create Storage buckets `floorplans` and `repair-files`.
4. Each page embeds the Supabase URL + **anon** key (public by design); update them
   in the `<script>` init block if you point at a different project.

> Row-Level Security is currently open (`allow_all_for_now`) for development —
> tighten before production.

## Deploy
Push to `main`; GitHub Pages builds and publishes automatically. The site is
CDN-cached — append `?v=<n>` to a URL to force a fresh copy after a deploy.

## Conventions
- Dark cyberpunk theme (`--bg:#020b18`, `--cyan:#00d4ff`); UI in Traditional Chinese.
- Dates standardised to **`YYYY-MM-DD`**; forms carry a 填表日期 (today).
- SQL is idempotent; add `alter table … add column if not exists` when adding columns.
