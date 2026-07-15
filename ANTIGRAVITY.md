# 第一果菜市場 設備巡檢/報修系統 (v2.0) - ANTIGRAVITY.md

## 專案目標
優化第一果菜市場的中央設備巡檢與報修系統，強化首頁安全門戶、改進系統導航流暢度、修正歷史遺留之 JavaScript 腳本錯誤，並確保跨子系統的穩定性。

## 技術棧
* **前端**：原生 HTML5、CSS3（含亮暗主題動態切換）、純 JavaScript (ES6+)
* **後端與資料庫**：Supabase (Database, Auth, Storage)
* **硬體與行動端整合**：HTML5 QR-Code 掃描、3D 建模與雲台整合

## 注意事項與工作規範
* **安全防護**：
  * 禁止將 Supabase Admin 憑證、資料庫連接字串或敏感私密金鑰 (如 API keys, tokens) 提交至 GitHub 倉庫。
  * Supabase 初始化與網路要求皆須使用 `try-catch` 包裹進行優雅降級。
* **開發與驗證流程**：
  * 修改任何網頁後，須執行 Node.js 腳本編譯檢查（使用 `vm.compileFunction` 或 `node --check`），確保無任何語法錯誤。
  * 不使用全域 `git add .`，僅針對有實質改動的檔案進行 Staging、Commit 與 Push。
* **連結與導航**：
  * 保持「系統入口 ⌂」之統一入口頁面跳轉邏輯。
  * 區分手機端掃描 (`app.html`) 與桌面端稽核面板 (`guardpatrol.html`) 的跳轉目標。
