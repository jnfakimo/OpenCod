# -*- coding: utf-8 -*-
"""產生 EP03 教學檔案處理工具列表的一頁式 PDF。"""
from pathlib import Path
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import mm
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle

FONT = "NotoSansTC"
FONT_PATH = Path(r"C:\Windows\Fonts\NotoSansTC-VF.ttf")
if not FONT_PATH.exists():
    raise FileNotFoundError("Noto Sans TC font not found; install before rebuilding PDF.")
pdfmetrics.registerFont(TTFont(FONT, FONT_PATH))

styles = getSampleStyleSheet()
P = ParagraphStyle("body", parent=styles["Normal"], fontName=FONT, fontSize=7.2, leading=9.2)
PH = ParagraphStyle("cell", parent=P, fontSize=7, leading=8.8)
PHEAD = ParagraphStyle("head", parent=PH, textColor=colors.white)
TITLE = ParagraphStyle("title", parent=styles["Title"], fontName=FONT, fontSize=18, leading=21)
SUB = ParagraphStyle("sub", parent=styles["Normal"], fontName=FONT, fontSize=8, leading=11, textColor=colors.HexColor("#555555"))
CAT = ParagraphStyle("cat", parent=styles["Normal"], fontName=FONT, fontSize=10, leading=13, textColor=colors.white)

HEADBG = colors.HexColor("#0d1530")
CATBG = colors.HexColor("#1f6feb")
ZEBRA = colors.HexColor("#eef4ff")

def cell(t): return Paragraph(t, PH)

DATA = [
    ("Word", [
        ("套印獎狀/通知單/成績單", "手動換名換到崩潰", "python-docx + openpyxl", "讀名單套模板，每人產一份"),
        ("出考卷（學生/教師分開）", "出完題還要手動刪答案", "python-docx", "產出學生卷和教師卷兩份"),
        ("講義合併+批次轉PDF", "各課散落要合併", "選用: docxcompose", "合併後轉 PDF"),
    ]),
    ("Excel", [
        ("成績計算+排名+標紅", "每次段考重來", "openpyxl", "算總分排名，不及格標紅"),
        ("段考分析（答對率/圖）", "不會做統計圖", "matplotlib", "畫答對率條圖和分布圖"),
        ("總表拆成各班", "一張大表要分班", "openpyxl", "依班級欄拆成各班 Excel"),
        ("隨機座位表/分組", "每次手喬", "openpyxl", "隨機排 6×5 座位表"),
    ]),
    ("PowerPoint", [
        ("教材大綱→整份簡報", "一頁頁貼很花時間", "python-pptx", "每個重點做一頁投影片"),
        ("圖片→圖卡簡報", "一張張貼", "python-pptx + pillow", "每張圖片做一頁"),
        ("統一字型/加校徽", "字體亂要逐頁改", "python-pptx", "全部改標楷體加校徽"),
    ]),
    ("PDF", [
        ("考卷合併/拆分/重排", "散在幾十個 PDF", "pypdf + PyMuPDF", "合併並抽頁另存"),
        ("加浮水印（防外流）", "講義想加標示", "pypdf + reportlab", "每頁加浮水印"),
        ("掃描講義 OCR", "無法複製文字", "ocrmypdf+Tesseract", "OCR 成可複製 PDF"),
        ("抽課本某頁轉圖", "只要某張圖", "PyMuPDF", "轉圖片去白邊"),
    ]),
]

COLW = [40*mm, 52*mm, 42*mm, 132*mm]
HEAD = [Paragraph(f"<b>{h}</b>", PHEAD) for h in ("項目", "痛點", "套件", "一句話")]

def build():
    doc = SimpleDocTemplate("EP03_教學檔案處理_工具列表.pdf", pagesize=landscape(A4),
        leftMargin=10*mm, rightMargin=10*mm, topMargin=9*mm, bottomMargin=8*mm)
    flow = []
    flow.append(Paragraph("EP03 教學檔案處理工具列表｜老師的 Python 神器清單", TITLE))
    flow.append(Paragraph("三師爸 Sense Bar・AI Agent 基本功 EP03", SUB))
    flow.append(Spacer(1, 3*mm))
    rows = [HEAD]
    style = [
        ("FONTNAME", (0,0), (-1,-1), FONT),
        ("BACKGROUND", (0,0), (-1,0), HEADBG),
        ("TEXTCOLOR", (0,0), (-1,0), colors.white),
        ("GRID", (0,0), (-1,-1), 0.4, colors.HexColor("#cccccc")),
        ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ("TOPPADDING", (0,0), (-1,-1), 2.4),
        ("BOTTOMPADDING", (0,0), (-1,-1), 2.4),
    ]
    r = 1
    for catname, items in DATA:
        rows.append([Paragraph(f"<b>{catname}</b>", CAT), "", "", ""])
        style.append(("SPAN", (0,r), (-1,r)))
        style.append(("BACKGROUND", (0,r), (-1,r), CATBG))
        r += 1
        for item, pain, pkg, line in items:
            rows.append([cell(item), cell(pain), cell(f"<font color='#0d6efd'>{pkg}</font>"), cell(line)])
            if r % 2 == 0:
                style.append(("BACKGROUND", (0,r), (-1,r), ZEBRA))
            r += 1
    t = Table(rows, colWidths=COLW, repeatRows=1)
    t.setStyle(TableStyle(style))
    flow.append(t)
    doc.build(flow)
    print("PDF generated")

if __name__ == "__main__":
    build()
