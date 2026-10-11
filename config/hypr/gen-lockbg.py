#!/usr/bin/env python3
# gen-lockbg.py — Generates a sepia background with a pixel wave texture
# Usage: python3 gen-lockbg.py /chemin/output.png

import math
import random
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    # Fallback without PIL: create a minimal solid PNG
    sys.exit(0)

out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/lockbg.png"

W, H = 1920, 1080
CELL = 7
GAP = 1
STEP = CELL + GAP
cols = W // STEP
rows = H // STEP

img = Image.new("RGB", (W, H), (11, 9, 6))
draw = ImageDraw.Draw(img)

random.seed(42)  # fixed seed for visual consistency

# Simulate the final wave state (everything revealed)
# from the center, each pixel has uniform random brightness
cx, cy = cols / 2, rows / 2

for r in range(rows):
    for c in range(cols):
        # Brightness: uniform 78%..92% with jitter
        lum = 0.78 + random.random() * 0.14
        # Slight variation with distance from the center (center pixels slightly brighter)
        dist = math.sqrt((c - cx) ** 2 + (r - cy) ** 2) / math.sqrt(cx**2 + cy**2)
        lum = lum * (1 - dist * 0.08)

        rr = min(255, int(lum * 230))
        gg = min(255, int(lum * 215))
        bb = min(255, int(lum * 180))

        x = c * STEP
        y = r * STEP
        draw.rectangle([x, y, x + CELL - 1, y + CELL - 1], fill=(rr, gg, bb))

img.save(out, "PNG", optimize=False, compress_level=1)
print(f"Generated {out}")
