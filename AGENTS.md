# AGENTS.md — 臺北農產 巡檢/報修/派工系統

> Instructions for AI coding agents (OpenCode, etc.) working in this repo.
> Human setup lives in `README.md`; deeper context in `PROJECT_CONTEXT.md`.

## What this is
A web-based **equipment inspection / repair / dispatch / maintenance** system for
臺北農產運銷股份有限公司 第一果菜市場, plus floor-plan (2D) and stacked-floor (3D)
viewers with a marker layer. **No build step** — every page is a standalone
static HTML file that loads libraries from CDNs and talks directly to Supabase.

## Tech stack
- **Frontend**: plain multi-page HTML/CSS/JS (no framework, no bundler). Each
  `system/*.html` is self-contained.
- **Backend**: Supabase (PostgreSQL + PostgREST REST + Auth + Storage), accessed
  from the browser with the **anon key** (already embedded in each HTML file).
  Project ref: `qztffronusdhgxhjjubt`.
- **Libraries via CDN**: `@supabase/supabase-js@2`, OpenSeadragon 4.1 (2D deep-zoom),
  Three.js r128 (3D), SheetJS `xlsx@0.18.5` (XLSX/CSV), Chart.js, qrcodejs.
- **Hosting**: GitHub Pages, auto-deployed from the `main` branch.
  Base URL: `https://jnfakimo.github.io/word-cloud/system/<page>.html`

## Repo layout
```
index.html              # root: redirects to system/index.html
PROJECT_CONTEXT.md      # full architecture / onboarding notes
system/*.html           # the actual application pages (see table below)
system/sql/*.sql        # Supabase schema — idempotent, run in SQL Editor
system/plans/*          # LIVE floor-plan assets (DZI tiles + textures) — do NOT delete
supabase/functions/     # edge function (LINE notify)
```

### Key pages (`system/`)
`index.html` portal · `login.html` · `app.html` inspection · `admin.html` back-office
· `dashboard.html` · `workorder.html` repair/dispatch · `materials.html` Material
Master · `arealist.html` floor-space table · `b1_integrated_marker_system.html`
marker editor · `b1plan.html` 2D plan · `floor3d.html` 3D floors · `modeler.html`
DXF→plan/3D · `handover.html` shift handover · `analytics.html` · `rbac.html`.

## How to run / verify
- **Run**: it's static. Open any `system/*.html` in a browser, or serve the repo
  root (`python3 -m http.server`) and browse to `/system/...`. No install/build.
- **Verify JS**: this repo has no test suite. Sanity-check a page's inline script
  with Node before committing:
  ```
  node -e "const fs=require('fs');const h=fs.readFileSync('system/PAGE.html','utf8');const p=h.split('<script>');require('vm').compileFunction(p[p.length-1].split('</script>')[0])"
  ```
- **Deploy check**: pushing to `main` triggers the `pages build and deployment`
  workflow. The live site is CDN-cached — append `?v=<n>` to a URL to bypass cache.

## Database
All schema is in `system/sql/` and is **idempotent** (`create table if not exists`,
`add column if not exists`, `drop policy if exists` before create). To provision a
fresh Supabase project, run in the SQL Editor in this order:
`schema.sql` → `locations_schema.sql` → `work_order_schema.sql` → `floor_models.sql`
→ `handover_schema.sql` → `floor_spaces.sql` → `plan_markers.sql` → `material_master.sql`
→ `equipment_lifecycle.sql` → `patrol_shifts.sql` → `checkin_logs.sql` → `rls_hardening.sql`
→ `rls_hardening_login_fix.sql` → `permanent_data_protection.sql`.
`permanent_data_protection.sql` must be applied last. Production data is append/update/
deactivate only: never reset the database, truncate tables, or physically delete personnel.
RLS is currently open (`allow_all_for_now`) for development. Storage buckets:
`floorplans`, `repair-files`.

## Conventions (follow these)
- **Match the surrounding style**: cyberpunk dark theme. Core vars: `--bg:#020b18`,
  `--cyan:#00d4ff`, `--green:#00ff9d`, `--amber:#ffb300`, `--red:#ff3b3b`; fonts
  Noto Sans TC + Rajdhani. UI text is Traditional Chinese.
- **Dates**: unified format is 西元 `YYYY-MM-DD` (datetime `YYYY-MM-DD HH:mm`);
  date inputs use a calendar picker; forms show a 填表日期 (today). Use the local
  `fmtDate()`/`todayISO()` helpers.
- **Floor naming differs between systems**: area/material data may use `B1F`,
  while plan/3D use `B1`. Reconcile with a `canonicalFloor()` (B1≈B1F, 1F≈1, RF≈頂樓).
- **New/changed DB columns**: `create table if not exists` won't alter an existing
  table — always add a matching `alter table … add column if not exists`.
- **Adding a page**: give it the shared navbar/topbar, the Supabase init block, and
  cross-links consistent with sibling pages.

## Do NOT
- Do **not** delete `system/plans/*` — those textures/DZI tiles are used live by
  `floor3d.html` and `b1plan.html`.
- Do **not** drop or truncate DB tables casually — `equipment`, `locations`,
  `floor_spaces`, inspection data are shared across dashboard/repair/materials.
- Do **not** delete rows from `users` or other protected master/history tables. Set
  `status='inactive'`; the permanent-data trigger intentionally rejects DELETE/TRUNCATE.
- Do **not** disable TLS or hardcode secrets beyond the already-public anon key.

## Git workflow
- Default branch `main` is what GitHub Pages deploys. Commit/push only what you
  intend to ship.
- Multiple agents may push concurrently; if a push is rejected, do
  `git fetch origin main && git rebase origin/main` then push again.
- Don't open a PR unless asked.
