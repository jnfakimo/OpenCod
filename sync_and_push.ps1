# Windows PowerShell Script to sync files from Codex to Git Repo
# Prevent encoding issues
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  北農人臉辨識系統 - word-cloud 同步工具  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. 偵測 Google Drive 磁碟代號 (G 或 H)
$drives = @("H", "G")
$selectedDrive = $null
foreach ($d in $drives) {
    $testPath = "$($d):\我的雲端硬碟"
    if (Test-Path $testPath) {
        $selectedDrive = $d
        break
    }
}

if ($null -eq $selectedDrive) {
    Write-Error "找不到掛載的 Google Drive 磁碟 (G 槽或 H 槽)。請檢查 Google Drive 是否正常啟動。"
    pause
    exit
}

$src = "$($selectedDrive):\我的雲端硬碟\AI\Codex\北農人臉辨識系統\word-cloud-site"
$dest = "$($selectedDrive):\我的雲端硬碟\AI\OpenCod"

Write-Host "[1] 偵測到磁碟代號: $($selectedDrive) 槽" -ForegroundColor Green
Write-Host "[2] 來源路徑: $src"
Write-Host "[3] 目的路徑: $dest"

if (-not (Test-Path $src)) {
    Write-Error "來源路徑不存在，請確認該路徑是否有檔案。"
    pause
    exit
}

# 2. 開始進行檔案同步 (複製 system/ 目錄與 assets/ 目錄的變更)
Write-Host "`n[4] 開始同步檔案中..." -ForegroundColor Yellow

# 同步 system 目錄下的網頁及資源
if (Test-Path "$src\system") {
    robocopy "$src\system" "$dest\system" /E /XO /NDL /NFL /NJH /NJS /XD plans
}
# 同步 assets 目錄下的圖示
if (Test-Path "$src\assets") {
    robocopy "$src\assets" "$dest\assets" /E /XO /NDL /NFL /NJH /NJS
}
# 同步根目錄的 index.html
if (Test-Path "$src\index.html") {
    Copy-Item "$src\index.html" "$dest\index.html" -Force
}

Write-Host "檔案複製同步完成！" -ForegroundColor Green

# 3. 執行 Git 提交與推送
Write-Host "`n[5] 檢查 Git 狀態並推送至 GitHub..." -ForegroundColor Yellow
Set-Location $dest

git status -s

Write-Host "`n是否要自動提交變更並 PUSH 到 GitHub？ (Y/N): " -NoNewline
$ans = Read-Host
if ($ans -eq "Y" -or $ans -eq "y" -or $ans -eq "") {
    git add -A
    $commitMsg = "update: 同步本地端最新版網頁變更 (" + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + ")"
    git commit -m $commitMsg
    
    Write-Host "正在推送到 GitHub (main)..." -ForegroundColor Cyan
    git pull wordcloud main --rebase
    git push wordcloud main
    git push origin main
    
    Write-Host "正在部署至 GitHub Pages (gh-pages)..." -ForegroundColor Cyan
    git checkout gh-pages
    git merge main -X theirs --no-edit
    git push wordcloud gh-pages
    git checkout main
    
    Write-Host "`n同步且推送部署完成！" -ForegroundColor Green
} else {
    Write-Host "已跳過 Git 推送步驟。" -ForegroundColor Yellow
}

Write-Host "`n工作完成，按任意鍵退出..."
pause
