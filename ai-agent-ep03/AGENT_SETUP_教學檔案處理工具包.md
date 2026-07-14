# 🤖 Agent 安裝指南：教學檔案處理「核心工具包」

> **這份檔案是寫給 AI Agent 讀的。**
> 適用於 Windows 上的 Claude Code、ChatGPT 的 Codex App、Google Antigravity、OpenCode。

## 🎯 給 Agent 的必要規則
1. **只在本 repo 內工作**
2. **只執行核心安裝**：不要安裝「選用工具」與「系統工具」
3. **不要使用全域 `pip install`**
4. **不要逐項上網研究**
5. **最多重試一次**
6. **不自動切換執行環境**

## 🚀 Windows 核心安裝
```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install_windows.ps1"
```

## ✅ 核心必裝套件
| 套件 | 用途 |
|------|------|
| `python-docx` | 生成／讀寫 Word |
| `openpyxl` | 讀寫與格式化 Excel |
| `python-pptx` | 生成／改寫 PowerPoint |
| `pypdf` | PDF 合併、拆分、浮水印 |
| `PyMuPDF` | PDF 抽文字、抽頁、轉圖片 |
| `reportlab` | 生成 PDF 與浮水印圖層 |
| `pillow` | 圖片裁切、去白邊、合成 |
| `matplotlib` | 產生統計圖表 |
| `qrcode[pil]` | 產生 QR Code |
| `markitdown[pdf,docx,pptx,xlsx]` | 文件轉 Markdown |

## 🟡 非必要套件（不要裝）
`docxcompose`, `xlsxwriter`, `pandas`, `pdfplumber`, `pdf2image`, `fpdf2`, `ocrmypdf`, `docx2pdf`, `pywin32`, `edge-tts`, `yt-dlp`, `youtube-transcript-api`

## ✅ 最終回報格式
```text
核心安裝完成回報：
✅ uv：已存在／已安裝
✅ Python：3.12.x
✅ 環境：<本 repo>\.venv
✅ 核心套件：10/10 匯入成功
🟡 選用套件：未安裝（正確）
```
