#!/usr/bin/env python3
"""Bangun sumber ikon peluncur v2 (ADR-043) dari maskot clay.

Menulis SVG sumber ke `assets/icon/src/` lalu merendernya ke PNG 1024 px di
`assets/icon/` lewat QuickLook macOS (`render.py`), yang mendukung gradasi dan
`feDropShadow`. Sesudahnya jalankan:

    python3 scripts/launcher_icon/build_launcher_icon.py
    dart run flutter_launcher_icons

Maskot dan koin disalin dari `assets/icons_clay/tanuki_mascot.svg` (versi
acuan dengan bayangan) dan `tier_coin.svg`; latar memakai nada matcha
`primaryFixed`/`primaryFixedDim` di `docs/03-design/design-system-v2/tokens.json`.
"""

import pathlib

from render import render_opaque, render_transparent

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "assets/icon/src"
OUT = ROOT / "assets/icon"
SIZE = 1024

# Titik tengah gabungan maskot + koin dalam satuan viewBox maskot (54).
CENTER_X, CENTER_Y = 28.5, 26.5

DEFS = """
<linearGradient id="bg" gradientUnits="userSpaceOnUse" x1="170" y1="170" x2="854" y2="854">
  <stop offset="0%" stop-color="#d9f5dd"/>
  <stop offset="50%" stop-color="#bdefc4"/>
  <stop offset="100%" stop-color="#94c99e"/>
</linearGradient>
<radialGradient id="bgGlow" cx="50%" cy="46%" r="34%">
  <stop offset="0%" stop-color="#ffffff" stop-opacity="0.22"/>
  <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
<linearGradient id="bgGloss" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0%" stop-color="#ffffff" stop-opacity="0.6"/>
  <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
</linearGradient>
<linearGradient gradientUnits="userSpaceOnUse" id="clayTanukiBody" x1="27" x2="27" y1="12" y2="46"><stop offset="0%" stop-color="#8b6f57"/><stop offset="50%" stop-color="#6c523e"/><stop offset="100%" stop-color="#4d3727"/></linearGradient>
<linearGradient gradientUnits="userSpaceOnUse" id="clayMuzzle" x1="27" x2="27" y1="28" y2="42"><stop offset="0%" stop-color="#ffffff"/><stop offset="100%" stop-color="#f5ebd9"/></linearGradient>
<linearGradient gradientUnits="userSpaceOnUse" id="clayLeafPlump" x1="20" x2="32" y1="5" y2="17"><stop offset="0%" stop-color="#86efac"/><stop offset="40%" stop-color="#22c55e"/><stop offset="100%" stop-color="#15803d"/></linearGradient>
<linearGradient id="claySoftHighlight" x1="0%" x2="0%" y1="0%" y2="100%"><stop offset="0%" stop-color="#ffffff" stop-opacity="0.75"/><stop offset="100%" stop-color="#ffffff" stop-opacity="0"/></linearGradient>
<filter height="130%" id="clayShadowFilter" width="130%" x="-10%" y="-10%"><feDropShadow dx="0" dy="2" flood-color="#2d1e15" flood-opacity="0.35" stdDeviation="1.5"/></filter>
<filter height="140%" id="groundShadow" width="140%" x="-20%" y="-20%"><feDropShadow dx="0" dy="1.6" flood-color="#1f4b2c" flood-opacity="0.35" stdDeviation="1.6"/></filter>
<linearGradient id="clayCoin" x1="0%" x2="100%" y1="0%" y2="100%"><stop offset="0%" stop-color="#fde047"/><stop offset="60%" stop-color="#f59e0b"/><stop offset="100%" stop-color="#d97706"/></linearGradient>
<linearGradient id="clayCoinHighlight" x1="30%" x2="70%" y1="0%" y2="100%"><stop offset="0%" stop-color="#ffffff" stop-opacity="0.8"/><stop offset="100%" stop-color="#ffffff" stop-opacity="0"/></linearGradient>
"""

MASCOT = """
<rect fill="#4d3727" height="10" rx="4.5" width="10" x="11" y="8"/><rect fill="#4d3727" height="10" rx="4.5" width="10" x="33" y="8"/>
<rect fill="#f5ebd9" height="6" rx="2.5" width="6" x="13" y="10"/><rect fill="#f5ebd9" height="6" rx="2.5" width="6" x="35" y="10"/>
<rect fill="url(#clayTanukiBody)" filter="url(#clayShadowFilter)" height="30" rx="14" width="38" x="8" y="14"/>
<ellipse cx="27" cy="17" fill="url(#claySoftHighlight)" rx="14" ry="4"/>
<rect fill="#22472d" height="14" rx="5.5" width="13" x="11" y="20"/><rect fill="#22472d" height="14" rx="5.5" width="13" x="30" y="20"/>
<circle cx="17.5" cy="26.5" fill="#ffffff" r="3.8"/><circle cx="18" cy="26.5" fill="#1a1a1a" r="2.2"/><circle cx="19" cy="25" fill="#ffffff" r="1"/>
<circle cx="36.5" cy="26.5" fill="#ffffff" r="3.8"/><circle cx="36" cy="26.5" fill="#1a1a1a" r="2.2"/><circle cx="37" cy="25" fill="#ffffff" r="1"/>
<ellipse cx="27" cy="35" fill="url(#clayMuzzle)" rx="8" ry="6"/><ellipse cx="27" cy="33" fill="url(#claySoftHighlight)" rx="6" ry="2"/>
<ellipse cx="27" cy="32" fill="#2d1e15" rx="2.8" ry="2"/>
<path d="M25 36.5C26 37.8 28 37.8 29 36.5" stroke="#6c523e" stroke-linecap="round" stroke-width="1.4" fill="none"/>
<ellipse cx="12" cy="33" fill="#f87171" opacity="0.6" rx="2.2" ry="1.4"/><ellipse cx="42" cy="33" fill="#f87171" opacity="0.6" rx="2.2" ry="1.4"/>
<path d="M26 15C22 13 23 8 28 8C33 8 34 13 30 15C28.5 15.8 27.5 15.8 26 15Z" fill="url(#clayLeafPlump)" filter="url(#clayShadowFilter)"/>
<ellipse cx="26.5" cy="9.5" fill="#ffffff" opacity="0.8" rx="2.5" ry="1.2"/>
"""

# Koin daun (tier_coin.svg, viewBox 24) di sudut kanan bawah maskot.
COIN = """
<g transform="translate(37 33) scale(0.5)" filter="url(#clayShadowFilter)">
<circle cx="12" cy="12" fill="url(#clayCoin)" r="10"/><circle cx="12" cy="12" fill="#d97706" opacity="0.2" r="8"/>
<path d="M12 7C9.5 7 8 9.5 8 11.5C8 14 10.5 15.5 12 16.5C13.5 15.5 16 14 16 11.5C16 9.5 14.5 7 12 7Z" fill="#15803d" opacity="0.9"/>
<path d="M12 7C11.5 9 10.5 12 8.5 13" stroke="#86efac" stroke-linecap="round" stroke-width="0.8" fill="none"/>
<ellipse cx="9" cy="7.5" fill="url(#clayCoinHighlight)" rx="4.5" ry="2.2" transform="rotate(-25 9 7.5)"/>
</g>
"""

# Siluet untuk ikon bertema Android 13+ (hanya alfa yang dipakai).
MONO = """
<mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="54" height="54">
<rect fill="#fff" height="10" rx="4.5" width="10" x="11" y="8"/><rect fill="#fff" height="10" rx="4.5" width="10" x="33" y="8"/>
<rect fill="#fff" height="30" rx="14" width="38" x="8" y="14"/>
<rect fill="#000" height="5" rx="2" width="5" x="13.5" y="10.5"/><rect fill="#000" height="5" rx="2" width="5" x="35.5" y="10.5"/>
<rect fill="#000" height="14" rx="5.5" width="13" x="11" y="20"/><rect fill="#000" height="14" rx="5.5" width="13" x="30" y="20"/>
<circle cx="18" cy="26.5" fill="#fff" r="2.4"/><circle cx="36" cy="26.5" fill="#fff" r="2.4"/>
<ellipse cx="27" cy="35" fill="#000" rx="8" ry="6"/><ellipse cx="27" cy="32.4" fill="#fff" rx="2.8" ry="2"/>
<path d="M24.4 15.8C20.2 13.2 21.8 6.4 28 6.4C34.2 6.4 35.8 13.2 31.6 15.8Z" fill="#000"/>
<path d="M26 15C22 13 23 8 28 8C33 8 34 13 30 15C28.5 15.8 27.5 15.8 26 15Z" fill="#fff"/>
<circle cx="43" cy="39" fill="#000" r="6.2"/><circle cx="43" cy="39" fill="#fff" r="5"/>
</mask>
<rect width="54" height="54" fill="#fff" mask="url(#m)"/>
"""


def subject(scale: float, body: str, dy: float = 0) -> str:
    tx = SIZE / 2 - CENTER_X * scale
    ty = SIZE / 2 - CENTER_Y * scale + dy
    return f'<g transform="translate({tx:.2f} {ty:.2f}) scale({scale})">{body}</g>'


def background() -> str:
    return (
        f'<rect width="{SIZE}" height="{SIZE}" fill="url(#bg)"/>'
        f'<rect width="{SIZE}" height="{SIZE}" fill="url(#bgGlow)"/>'
        f'<ellipse cx="{SIZE / 2}" cy="0" rx="{SIZE * 0.62}" ry="{SIZE * 0.28}" fill="url(#bgGloss)"/>'
    )


def svg(content: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
        f'viewBox="0 0 {SIZE} {SIZE}"><defs>{DEFS}</defs>{content}</svg>\n'
    )


def mascot_with_coin(scale: float) -> str:
    return subject(scale, f'<g filter="url(#groundShadow)">{MASCOT}{COIN}</g>', dy=8)


SOURCES = {
    # Latar ikon adaptif Android.
    "background": svg(background()),
    # Latar depan ikon adaptif: isi di dalam lingkaran aman 66/108 dp.
    "foreground": svg(mascot_with_coin(12)),
    # Ikon bertema (monokrom) Android 13+.
    "monochrome": svg(subject(12, MONO, dy=8)),
    # Ikon utuh: Android lawas dan iOS (alfa dibuang).
    "icon": svg(background() + mascot_with_coin(16.5)),
}


# Berkas berlatar transparan; sisanya menutupi seluruh kanvas.
TRANSPARENT = {"foreground", "monochrome"}


def main() -> None:
    SRC.mkdir(parents=True, exist_ok=True)
    for name, text in SOURCES.items():
        (SRC / f"{name}.svg").write_text(text)
        out = OUT / f"{name}.png"
        if name in TRANSPARENT:
            render_transparent(text, SIZE, out)
        else:
            render_opaque(text, SIZE, out)
    # Ikon 512 untuk listing Play dibuat build_store_assets.py.

if __name__ == "__main__":
    main()
