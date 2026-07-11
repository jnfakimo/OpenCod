# EP03 ・ Python 能力：教學現場老師的「檔案處理」工具地圖

> 圖例：🟢＝核心包自動安裝　🟡＝按需求選裝

## 一、套件總覽

| 類別 | 代表套件 | 能做什麼 |
|------|----------|----------|
| 📄 Word | 🟢 `python-docx`；🟡 `docxcompose` | 生成/讀寫；選用合併 Word |
| 📊 Excel | 🟢 `openpyxl`；🟡 `pandas`、`xlsxwriter` | 一般讀寫；選用進階分析/輸出 |
| 📑 PPT | 🟢 `python-pptx` | 生成/改寫 PowerPoint |
| 📕 PDF | 🟢 `PyMuPDF`、`pypdf`、`reportlab`；其餘選用 | 合併/拆分/抽文字/轉圖/浮水印/生成 |
| 🔄 轉檔 | 🟢 `markitdown[pdf,docx,pptx,xlsx]` | 常用文件轉 Markdown |
| 🖼️ 圖像/圖表 | 🟢 `pillow`、`matplotlib`、`qrcode[pil]` | 圖片處理、數據圖、QR Code |
| 🎙️ 語音影音 | 🟡 `edge-tts`、`yt-dlp`、`youtube-transcript-api` | 只在旁白、下載、字幕任務選裝 |

## 二、教學檔案處理

### Word 篇
- **W1. 套印個人化通知單／獎狀／成績單** 🟢 `python-docx` + `openpyxl`
- **W2. 出考卷／學習單，題目卷與答案卷分開** 🟢 `python-docx`
- **W3. 多份講義合併成一份、批次轉 PDF** 🟡 `docxcompose` + `pywin32`

### Excel 篇
- **E1. 成績計算 + 排名 + 及格標示** 🟢 `openpyxl`
- **E2. 段考成績分析（答對率、落點圖）** 🟢 `matplotlib` + 🟡 `pandas`
- **E3. 總成績單拆成各班** 🟢 `openpyxl`
- **E4. 自動產生座位表／隨機分組** 🟢 `openpyxl`

### PPT 篇
- **P1. 教材大綱→自動生成上課簡報** 🟢 `python-pptx`
- **P2. 圖片→圖卡簡報** 🟢 `python-pptx` + `pillow`
- **P3. 統一字型／加校徽** 🟢 `python-pptx`

### PDF 篇
- **D1. 考卷合併/拆分/重新排序** 🟢 `pypdf` + `PyMuPDF`
- **D2. PDF 加浮水印** 🟢 `pypdf` + `reportlab`
- **D3. 掃描講義 OCR** 🟡 `ocrmypdf` + Tesseract
- **D4. 抽課本某幾頁/PDF 轉圖** 🟢 `PyMuPDF`

## 三、安裝核心工具
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install_windows.ps1"
```
