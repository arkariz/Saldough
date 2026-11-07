#!/usr/bin/env python3
"""Bangun aset listing Play Store: ikon 512 dan grafis fitur 1024x500.

    python3 scripts/launcher_icon/build_store_assets.py

Keluaran di `docs/03-release/store_assets/`:
- `app_icon_512.png`: ikon aplikasi (sama dengan `assets/icon/icon.png`,
  dirender langsung di 512 px; Play menambah sudut bulat sendiri).
- `feature_graphic_<bahasa>.jpg`: grafis fitur per bahasa listing, JPG tanpa
  transparansi sesuai syarat Play.

Rupa mengikuti design system v2: maskot clay + koin daun dari ikon peluncur,
ikon clay `assets/icons_clay/`, logo kata Space Mono Bold, teks Plus Jakarta
Sans, gradasi matcha. Teks diambil dari `PLAY_STORE_LISTING.md` §4 (judul
tangkapan layar pertama).
"""

import base64
import pathlib
import subprocess
import tempfile

import build_launcher_icon as icon
from render import crop_top, render_opaque

ROOT = icon.ROOT
OUT = ROOT / "docs/03-release/store_assets"
CLAY = ROOT / "assets/icons_clay"
FONTS = ROOT / "assets/fonts"

WIDTH, HEIGHT = 1024, 500

COPY = {
    "id": {"tagline": "Semua uangmu, satu buku", "chips": ["Catat", "Anggaran", "Freelance"]},
    "en": {"tagline": "All your money, one book", "chips": ["Record", "Budgets", "Freelance"]},
}

INK = "#1f4b2c"
INK_SOFT = "#2f5a3a"

# (aset clay, x, y, ukuran, putaran) mengelilingi maskot.
FLOATERS = [
    ("piggy_savings", 598, 70, 78, -12),
    ("cash_wallet", 892, 64, 72, 10),
    ("coin_paid", 914, 356, 70, -8),
    ("report_bars", 548, 336, 74, 8),
    ("leaf_send", 700, 30, 44, -18),
]


def _b64(path: pathlib.Path) -> str:
    return base64.b64encode(path.read_bytes()).decode()


def _fonts() -> str:
    return (
        "<style>"
        f"@font-face{{font-family:'TkMono';src:url(data:font/ttf;base64,{_b64(FONTS / 'SpaceMono-Bold.ttf')}) format('truetype');font-weight:700}}"
        f"@font-face{{font-family:'TkSans';src:url(data:font/ttf;base64,{_b64(FONTS / 'PlusJakartaSans-Variable.ttf')}) format('truetype');font-weight:200 800}}"
        "</style>"
    )


def _clay(name: str, x: float, y: float, size: float, turn: float) -> str:
    if size <= 0:
        return ""
    data = _b64(CLAY / f"{name}.svg")
    cx, cy = x + size / 2, y + size / 2
    return (
        f'<g transform="rotate({turn} {cx} {cy})" filter="url(#floatShadow)">'
        f'<image x="{x}" y="{y}" width="{size}" height="{size}" href="data:image/svg+xml;base64,{data}"/></g>'
    )


def _chips(labels: list[str], x: float, y: float) -> str:
    parts, cursor = [], x
    for label in labels:
        width = len(label) * 11.6 + 36
        parts.append(
            f'<rect x="{cursor}" y="{y}" width="{width}" height="40" rx="20" fill="#ffffff" fill-opacity="0.72" '
            f'stroke="#ffffff" stroke-opacity="0.9"/>'
            f'<text x="{cursor + width / 2}" y="{y + 26.5}" text-anchor="middle" font-family="TkSans" font-weight="700" '
            f'font-size="19" fill="{INK}">{label}</text>'
        )
        cursor += width + 12
    return "".join(parts)


def feature_graphic(lang: str) -> str:
    copy = COPY[lang]
    scale = 7.4
    mx, my = 770, 262
    mascot = (
        f'<g transform="translate({mx - icon.CENTER_X * scale:.2f} {my - icon.CENTER_Y * scale:.2f}) scale({scale})">'
        f'<g filter="url(#groundShadow)">{icon.MASCOT}{icon.COIN}</g></g>'
    )
    defs = (
        icon.DEFS
        + f'<linearGradient id="fgBg" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="{WIDTH}" y2="{HEIGHT}">'
        '<stop offset="0%" stop-color="#ecf9ee"/><stop offset="55%" stop-color="#c9eecf"/><stop offset="100%" stop-color="#9fd3a8"/></linearGradient>'
        '<radialGradient id="fgHalo" cx="0.5" cy="0.5" r="0.5"><stop offset="0%" stop-color="#ffffff" stop-opacity="0.75"/>'
        '<stop offset="70%" stop-color="#ffffff" stop-opacity="0.25"/><stop offset="100%" stop-color="#ffffff" stop-opacity="0"/></radialGradient>'
        '<filter id="floatShadow" x="-30%" y="-30%" width="160%" height="160%"><feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#1f4b2c" flood-opacity="0.22"/></filter>'
    )
    leaves = "".join(
        f'<g transform="translate({x} {y}) rotate({r}) scale({s})" opacity="{o}"><path d="M26 15C22 13 23 8 28 8C33 8 34 13 30 15C28.5 15.8 27.5 15.8 26 15Z" fill="url(#clayLeafPlump)"/></g>'
        for x, y, r, s, o in [(-40, 380, -30, 4.2, 0.18), (420, -40, 40, 3.2, 0.14), (520, 430, 15, 2.4, 0.16)]
    )
    body = (
        f'<rect width="{WIDTH}" height="{HEIGHT}" fill="url(#fgBg)"/>'
        f'<ellipse cx="{WIDTH / 2}" cy="-40" rx="620" ry="150" fill="url(#bgGloss)" opacity="0.7"/>'
        + leaves
        + f'<circle cx="{mx}" cy="{my}" r="215" fill="url(#fgHalo)"/>'
        + "".join(_clay(*f) for f in FLOATERS)
        + mascot
        + f'<text x="88" y="214" font-family="TkMono" font-weight="700" font-size="64" letter-spacing="2" fill="{INK}">tanukonomy</text>'
        + f'<text x="90" y="272" font-family="TkSans" font-weight="700" font-size="33" fill="{INK_SOFT}">{copy["tagline"]}</text>'
        + _chips(copy["chips"], 90, 304)
    )
    # QuickLook hanya merender kanvas persegi dengan tepat, jadi desain
    # ditaruh di bagian atas kanvas WIDTHxWIDTH lalu dipotong saat ekspor.
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{WIDTH}" viewBox="0 0 {WIDTH} {WIDTH}">'
        f'<defs>{defs}<clipPath id="fgClip"><rect width="{WIDTH}" height="{HEIGHT}"/></clipPath></defs>{_fonts()}'
        f'<g clip-path="url(#fgClip)">{body}</g></svg>\n'
    )


def _to_jpeg(png: pathlib.Path, jpg: pathlib.Path) -> None:
    """PNG ke JPG kualitas 92 (tanpa alfa)."""
    subprocess.run(
        ["sips", "-s", "format", "jpeg", "-s", "formatOptions", "92", str(png), "--out", str(jpg)],
        check=True,
        capture_output=True,
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icon_svg = icon.SOURCES["icon"].replace('width="1024" height="1024"', 'width="512" height="512"', 1)
    render_opaque(icon_svg, 512, OUT / "app_icon_512.png")
    with tempfile.TemporaryDirectory() as d:
        for lang in COPY:
            # SVG tidak disimpan: hurufnya disematkan (~400 KB per berkas).
            svg = feature_graphic(lang)
            png = pathlib.Path(d) / f"{lang}.png"
            render_opaque(svg, WIDTH, png)
            crop_top(png, HEIGHT)
            _to_jpeg(png, OUT / f"feature_graphic_{lang}.jpg")


if __name__ == "__main__":
    main()
