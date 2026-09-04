#!/bin/bash
# generate.sh — 用 Chrome headless 将 HTML 打印为 A4 竖版 PDF（新能源纯电报告）
# 用法: bash generate.sh <input.html> <output.pdf>
# 依赖: /Applications/Google Chrome.app
set -e
INPUT="${1:?用法: generate.sh <input.html> <output.pdf>}"
OUTPUT="${2:?缺少输出路径}"
mkdir -p "$(dirname "$OUTPUT")"

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$OUTPUT" \
  --print-to-pdf-no-header "$INPUT" 2>/dev/null || true

if [ ! -f "$OUTPUT" ]; then echo "ERROR: PDF 未生成"; exit 1; fi
SIZE=$(stat -f%z "$OUTPUT" 2>/dev/null || stat -c%s "$OUTPUT")
echo "OK: $OUTPUT ($SIZE bytes)"
