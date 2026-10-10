#!/usr/bin/env python3
"""Terapkan palet tema berserk ke seluruh config Unit-3.

Usage: retheme.py [ink|blood|paper]   (default: ink)

Routing file:
  config/kitty/kitty.conf                        -> section [KITTY]
  config/quickshell/pixel_wave.py,
  config/quickshell/pixel-wave-close-video.py    -> section [PIXEL]
  semua file lain di config/                     -> [GLOBAL] + [QML] + [CSS]
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
VARIANT = sys.argv[1] if len(sys.argv) > 1 else "ink"
REPO = os.path.dirname(os.path.dirname(HERE))
CONFIG = os.path.join(REPO, "config")

KITTY_FILES = {"config/kitty/kitty.conf"}
PIXEL_FILES = {
    "config/quickshell/pixel_wave.py",
    "config/quickshell/pixel-wave-close-video.py",
}


def load_palette(path):
    sections, cur = {}, None
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            s = line.strip()
            if not s or s.startswith(";"):
                continue
            if s.startswith("[") and s.endswith("]"):
                cur = s[1:-1].strip()
                sections[cur] = []
                continue
            if cur is None:
                continue
            old, tab, new = line.partition("\t")
            if not tab:
                parts = line.split()
                if len(parts) < 2:
                    continue
                old, new = parts[0], parts[1]
            old, new = old.strip(), new.strip()
            if old and new:
                sections[cur].append((old, new))
    return sections


def apply_rules(text, pairs):
    total = 0
    for old, new in pairs:
        text, n = re.compile(old, re.IGNORECASE).subn(new, text)
        total += n
    return text, total


def main():
    palette = os.path.join(HERE, VARIANT + ".palette")
    if not os.path.isfile(palette):
        print("Palet tidak ditemukan: %s" % palette)
        return 1
    sections = load_palette(palette)
    for need in ("GLOBAL", "QML", "CSS", "KITTY", "PIXEL"):
        if need not in sections:
            print("Section [%s] hilang di %s" % (need, palette))
            return 1

    changed, files = 0, 0
    for root, _dirs, names in os.walk(CONFIG):
        for name in sorted(names):
            full = os.path.join(root, name)
            rel = os.path.relpath(full, REPO)
            if rel in KITTY_FILES:
                rules = sections["KITTY"]
            elif rel in PIXEL_FILES:
                rules = sections["PIXEL"]
            else:
                rules = sections["GLOBAL"] + sections["QML"] + sections["CSS"]
            try:
                with open(full, encoding="utf-8") as fh:
                    text = fh.read()
            except (UnicodeDecodeError, OSError):
                continue  # binary / tidak terbaca -> lewati
            new_text, n = apply_rules(text, rules)
            if n:
                with open(full, "w", encoding="utf-8") as fh:
                    fh.write(new_text)
                files += 1
                changed += n
    print("Varian '%s' diterapkan: %d substitusi di %d file." % (VARIANT, changed, files))
    return 0


if __name__ == "__main__":
    sys.exit(main())
