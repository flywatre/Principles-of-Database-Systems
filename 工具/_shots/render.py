# -*- coding: utf-8 -*-
"""把带 ANSI 颜色的终端输出渲染成 PNG（模拟终端窗口）。"""
import os
import re
import sys
import unicodedata

from PIL import Image, ImageDraw, ImageFont

SHOTS = r"D:\code\database system principle\工具\_shots"
OUTDIR = r"D:\code\database system principle\experiment 1\截图"

BG = (30, 30, 30)
BAR = (45, 45, 48)
FG = (212, 212, 212)
FONT_PATH = r"C:\Windows\Fonts\simsun.ttc"
FONT_INDEX = 1
FONT_SIZE = 16

PALETTE = {
    30: (60, 60, 60), 31: (244, 135, 113), 32: (106, 190, 106),
    33: (220, 190, 100), 34: (86, 156, 214), 35: (197, 134, 192),
    36: (78, 201, 176), 37: (212, 212, 212),
    90: (128, 128, 128), 91: (244, 135, 113), 92: (106, 190, 106),
    93: (220, 190, 100), 94: (86, 156, 214), 95: (197, 134, 192),
    96: (78, 201, 176), 97: (255, 255, 255),
}

ANSI_RE = re.compile(r"\x1b\[([0-9;]*)m")


def cells(s):
    n = 0
    for ch in s:
        n += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
    return n


def parse(line, default_fg):
    """返回 [(text, color, bold), ...]"""
    out = []
    color, bold = default_fg, False
    pos = 0
    for m in ANSI_RE.finditer(line):
        if m.start() > pos:
            out.append((line[pos:m.start()], color, bold))
        codes = [int(c) for c in m.group(1).split(";") if c != ""] or [0]
        for c in codes:
            if c == 0:
                color, bold = default_fg, False
            elif c == 1:
                bold = True
            elif c == 22:
                bold = False
            elif c in PALETTE:
                color = PALETTE[c]
        pos = m.end()
    if pos < len(line):
        out.append((line[pos:], color, bold))
    return out


def render(src, title, dst_name, max_cells=96):
    lines = []
    with open(os.path.join(SHOTS, src), encoding="utf-8", errors="replace") as f:
        for raw in f.read().split("\n"):
            raw = raw.rstrip("\r")
            raw = ANSI_RE.sub(lambda m: m.group(0), raw)
            plain = ANSI_RE.sub("", raw)
            if cells(plain) > max_cells:
                # 按显示宽度截断
                acc, cut = 0, 0
                for i, ch in enumerate(plain):
                    acc += 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1
                    if acc > max_cells - 3:
                        cut = i
                        break
                raw, plain = plain[:cut] + "...", plain[:cut] + "..."
            lines.append((raw, plain))

    font = ImageFont.truetype(FONT_PATH, FONT_SIZE, index=FONT_INDEX)
    bold_font = ImageFont.truetype(FONT_PATH, FONT_SIZE, index=FONT_INDEX)
    cw = font.getlength("M")
    lh = int(FONT_SIZE * 1.55)
    pad = 26
    bar_h = 42

    wmax = max(cells(p) for _, p in lines) if lines else 60
    width = int(pad * 2 + cw * wmax)
    height = int(bar_h + pad * 2 + lh * len(lines))

    img = Image.new("RGB", (width, height), BG)
    d = ImageDraw.Draw(img)

    # 标题栏
    d.rectangle([0, 0, width, bar_h], fill=BAR)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        cx = 20 + i * 22
        d.ellipse([cx, bar_h // 2 - 6, cx + 12, bar_h // 2 + 6], fill=c)
    d.text((width // 2, bar_h // 2), title, font=font, fill=(190, 190, 190), anchor="mm")

    y = bar_h + pad
    for raw, _ in lines:
        x = pad
        for text, color, bold in parse(raw, FG):
            d.text((x, y), text, font=bold_font if bold else font, fill=color)
            x += font.getlength(text)
        y += lh

    os.makedirs(OUTDIR, exist_ok=True)
    path = os.path.join(OUTDIR, dst_name)
    img.save(path, "PNG")
    print(f"  {dst_name}  {width}x{height}  ({os.path.getsize(path)//1024} KB)")


if __name__ == "__main__":
    render("01-run.txt", "BusTub P1 — 一键编译并运行测试", "01-一键运行结果.png")
    render("02-test.txt", "make + 单元测试输出", "02-编译与单元测试.png")
    render("03-gdb.txt", "gdb 断点调试会话", "03-gdb调试会话.png", max_cells=124)
