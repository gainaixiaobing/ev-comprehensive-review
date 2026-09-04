#!/bin/bash
# qa.sh — EV Review PDF 机械质检：页数 / 全页渲染 / contact sheet
# 用法: bash qa.sh <report.pdf> [outdir]
# 依赖: pymupdf + pillow（自动装到 /tmp/evqa venv）
PDF="${1:?用法: qa.sh <report.pdf> [outdir]}"
OUT="${2:-/tmp/ev-pdf-qa}"
mkdir -p "$OUT"

# 准备 Python 环境（pymupdf 渲染 + PIL 拼 contact sheet）
if ! /tmp/evqa/bin/python3 -c "import fitz, PIL" 2>/dev/null; then
  python3 -m venv /tmp/evqa
  /tmp/evqa/bin/pip -q install pymupdf pillow
fi

echo "=== 1. 页数 + 全页渲染 ==="
/tmp/evqa/bin/python3 - "$PDF" "$OUT" <<'PY'
import sys, fitz
pdf, out = sys.argv[1], sys.argv[2]
doc = fitz.open(pdf)
print(f"页数: {doc.page_count}")
for i, page in enumerate(doc):
    pix = page.get_pixmap(dpi=100)
    pix.save(f"{out}/p{i+1:02d}.png")
print(f"渲染完成: {out}/p*.png")
PY

echo "=== 2. contact sheet ==="
/tmp/evqa/bin/python3 - "$OUT" <<'PY'
import sys, glob
from PIL import Image, ImageDraw
out = sys.argv[1]
files = sorted(glob.glob(f"{out}/p*.png"))
if not files:
    print("未找到渲染页"); sys.exit(0)
thumb_w = 420
thumbs = []
for f in files:
    im = Image.open(f)
    h = int(im.height * thumb_w / im.width)
    thumbs.append(im.resize((thumb_w, h)))
cols = 4
gap = 12
label_h = 26
rows = (len(thumbs) + cols - 1) // cols
sheet = Image.new("RGB", (cols * (thumb_w + gap) + gap, rows * (thumbs[0].height + label_h + gap) + gap), "white")
draw = ImageDraw.Draw(sheet)
for i, t in enumerate(thumbs):
    r, c = divmod(i, cols)
    x = gap + c * (thumb_w + gap)
    y = gap + r * (t.height + label_h + gap)
    sheet.paste(t, (x, y))
    draw.text((x + 2, y + t.height + 4), f"P{i+1}", fill="black")
sheet.save(f"{out}/contact_sheet.png")
print(f"OK: {out}/contact_sheet.png")
PY

echo "=== 3. 文件大小 ==="
ls -la "$PDF" | awk '{print "size:", $5, "bytes"}'

echo "=== 4. 后续步骤 ==="
cat <<EOF
a) 打开 contact_sheet.png 全局检查：节奏/拥挤/空洞/布局重复/颜色统一
b) vision_analyze 逐页（p*.png）检查：溢出/重叠/截断/孤立标题/乱码
c) 数据 QA：正文数字 = 图表 = 表格（跨页一致性）；估算数据有 Estimated 标记；P1 无车型名/参数/结论
EOF
