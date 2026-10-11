#!/usr/bin/env python3
"""Generates the mcse app icon: a dark rounded tile with a grass-block
band and a terminal prompt glyph. Writes assets/icon.png, the macOS
AppIcon set, the Windows .ico, and packaging PNGs."""

import os
from PIL import Image, ImageDraw

S = 1024
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# Background tile with a subtle vertical gradient.
for y in range(S):
    t = y / S
    d.line([(0, y), (S, y)],
           fill=(int(16 + 16 * t), int(23 + 20 * t), int(18 + 16 * t), 255))

# Grass band across the top with pixel notches.
GRASS = (84, 176, 73, 255)
GRASS_DARK = (62, 140, 55, 255)
band_top, band_h, px = 100, 150, 48
d.rectangle((0, band_top, S, band_top + 14), fill=(112, 206, 96, 255))
d.rectangle((0, band_top + 14, S, band_top + band_h), fill=GRASS)
for n in [(40, band_top + band_h, 40 + 3 * px, band_top + band_h + px),
          (S - 40 - 4 * px, band_top + band_h, S - 40 - 2 * px,
           band_top + band_h + px),
          (S // 2 - px, band_top + band_h, S // 2 + px,
           band_top + band_h + px)]:
    d.rectangle(n, fill=GRASS_DARK)

# Terminal prompt ">_" centered in the lower area.
GREEN = (126, 231, 135, 255)
cx, cy = S // 2, S // 2 + 120
w = 56
x0, y0, drop = cx - 210, cy - 150, 150
d.line([(x0, y0), (x0 + 190, y0 + drop), (x0, y0 + 2 * drop)],
       fill=GREEN, width=w, joint="curve")
for pt in [(x0, y0), (x0 + 190, y0 + drop), (x0, y0 + 2 * drop)]:
    d.ellipse((pt[0] - w // 2, pt[1] - w // 2,
               pt[0] + w // 2, pt[1] + w // 2), fill=GREEN)
ux, uy = cx + 60, cy + 150
d.line([(ux, uy), (ux + 230, uy)], fill=GREEN, width=w)
for pt in [(ux, uy), (ux + 230, uy)]:
    d.ellipse((pt[0] - w // 2, pt[1] - w // 2,
               pt[0] + w // 2, pt[1] + w // 2), fill=GREEN)

# Round the tile.
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle((24, 24, S - 24, S - 24),
                                       radius=190, fill=255)
final = Image.new("RGBA", (S, S), (0, 0, 0, 0))
final.paste(img, (0, 0), mask)
img = final

out = os.path.join(ROOT, "assets")
os.makedirs(out, exist_ok=True)
img.save(os.path.join(out, "icon.png"))

pack = os.path.join(ROOT, "packaging", "icons")
os.makedirs(pack, exist_ok=True)
for size in (16, 32, 48, 64, 128, 256, 512):
    img.resize((size, size), Image.LANCZOS).save(
        os.path.join(pack, f"mcse-{size}.png"))

mac = os.path.join(ROOT, "macos", "Runner", "Assets.xcassets",
                   "AppIcon.appiconset")
for size in (16, 32, 64, 128, 256, 512, 1024):
    img.resize((size, size), Image.LANCZOS).save(
        os.path.join(mac, f"app_icon_{size}.png"))

ico_path = os.path.join(ROOT, "windows", "runner", "resources",
                        "app_icon.ico")
img.resize((256, 256), Image.LANCZOS).save(
    ico_path, format="ICO",
    sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128),
           (256, 256)])

print("icon written")
