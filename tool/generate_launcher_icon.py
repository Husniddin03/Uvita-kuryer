#!/usr/bin/env python3
"""Uvita launcher icon generator.

Uvita brend ikonasi: to'liq lime (#C5F255) fon + vektor forest (#0A2B1D) "U" harfi.
Font'siz chiziladi (ikki vertikal chiziq + pastki yoy) — shuning uchun har qanday
tizimda bir xil natija beradi.

Foydalanish:
    python3 tool/generate_launcher_icon.py

Barcha mipmap o'lchamlarini qayta yaratadi:
    mdpi 48 / hdpi 72 / xhdpi 96 / xxhdpi 144 / xxxhdpi 192

Eslatma: Android 8+ (API 26) uchun adaptive icon ham bor:
    res/mipmap-anydpi-v26/ic_launcher.xml (background = @color/ic_launcher_background,
    foreground = @drawable/ic_launcher_foreground). Ularni alohida tahrirlash kerak.
"""
from PIL import Image, ImageDraw

LEAF = (197, 242, 85)    # #C5F255
FOREST = (10, 43, 29)    # #0A2B1D
STROKE = 60              # master 1024px dagi chiziq qalinligi

BASE = "android/app/src/main/res"
SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def draw_master(size: int = 1024) -> Image.Image:
    S = size
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # To'liq lime kvadrat (Android launcher o'zi maskalaydi)
    d.rectangle([0, 0, S - 1, S - 1], fill=LEAF)

    # U harfi: chap/ong vertikal + pastki yoy (markazda)
    w_stroke = int(STROKE * (S / 1024) * 4)
    x1 = int(S * 0.30)
    x2 = int(S * 0.70)
    top = int(S * 0.22)
    bottom = int(S * 0.63)
    r = (x2 - x1) // 2

    d.line([(x1, top), (x1, bottom)], fill=FOREST, width=w_stroke)
    d.line([(x2, top), (x2, bottom)], fill=FOREST, width=w_stroke)
    d.arc([x1, bottom - r, x2, bottom + r], start=180, end=360, fill=FOREST, width=w_stroke)

    return img


def main() -> None:
    master = draw_master()
    for folder, px in SIZES.items():
        out = f"{BASE}/mipmap-{folder}/ic_launcher.png"
        master.resize((px, px), Image.LANCZOS).save(out)
        print(f"  {out}: {px}x{px} OK")


if __name__ == "__main__":
    main()
