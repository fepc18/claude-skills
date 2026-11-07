#!/usr/bin/env python3
"""Check WCAG 2.2 contrast for design-token pairs, in every theme.

Usage:
  python3 check-contrast.py tokens.json

tokens.json format (hex colors per theme, plus the pairs to check):
{
  "themes": {
    "light": {"background": "#f6f7f5", "foreground": "#17201b", "primary": "#0b6652", ...},
    "dark":  {"background": "#0e1411", "foreground": "#e7eee9", "primary": "#5cc6a9", ...}
  },
  "pairs": [
    ["foreground", "background", 4.5],
    ["muted-foreground", "surface", 4.5],
    ["input", "surface", 3.0],
    ["ring", "background", 3.0]
  ],
  "distinct": [["success", "destructive"]]
}

"pairs" are [text-or-ui, background, minimum ratio]: 4.5 for body text, 3.0 for large
text and UI parts (borders of inputs, focus ring, icons). "distinct" lists colors that
mean different states; if they have similar luminance (ratio < 1.5) the script warns
that the states must never rely on color alone.
Exits with code 1 when any pair fails, so it can run in CI.
"""
import json
import sys


def luminance(hex_color):
    h = hex_color.lstrip('#')
    r, g, b = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    lin = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def ratio(a, b):
    hi, lo = sorted([luminance(a), luminance(b)], reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def main(path):
    spec = json.load(open(path))
    failed = False
    for theme, colors in spec['themes'].items():
        print(f'== {theme}')
        for fg, bg, minimum in spec['pairs']:
            if fg not in colors or bg not in colors:
                print(f'  ?    {fg} on {bg}: token missing in this theme')
                failed = True
                continue
            r = ratio(colors[fg], colors[bg])
            ok = r >= minimum
            failed |= not ok
            print(f"  {'ok  ' if ok else 'FAIL'} {fg} on {bg}: {r:.2f} (min {minimum})")
        for a, b in spec.get('distinct', []):
            if a in colors and b in colors and ratio(colors[a], colors[b]) < 1.5:
                print(f'  note {a} and {b} have similar luminance ({ratio(colors[a], colors[b]):.2f}): add text or an icon to every state')
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    main(sys.argv[1])
