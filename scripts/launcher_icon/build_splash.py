#!/usr/bin/env python3
"""Bangun aset splash v2: gambar splash native dan lapisan maskot intro.

Splash native menampilkan tanuki clay **tanpa daun dan koin**; intro Flutter
(`lib/app/startup/startup_intro.dart`) menggambar tubuh yang sama di posisi
dan ukuran yang sama, lalu menjatuhkan daun dan meletupkan koin. Karena itu
ukuran kotak maskot di sini (`BOX_DP`) harus sama dengan
`StartupIntro.mascotBoxSize`.

    python3 scripts/launcher_icon/build_splash.py
    dart run flutter_native_splash:create

Bayangan (`filter`) dibuang di semua keluaran: `flutter_svg` tidak mendukung
`feDropShadow`, jadi gambar native dan Flutter harus sama-sama tanpa bayangan
supaya peralihannya tidak terlihat.
"""

import re

import build_launcher_icon as icon
from render import render_transparent

ROOT = icon.ROOT
ILLUSTRATION = ROOT / "assets/illustration"

# Kotak viewBox maskot (54 satuan) di layar, dalam dp.
BOX_DP = 180
# Gambar splash pra-Android 12 dianggap xxxhdpi (4x) oleh flutter_native_splash.
PRE12_PX = BOX_DP * 4
# Ikon splash Android 12+: kanvas 288 dp (1152 px di 4x), isi wajib di dalam
# lingkaran 192 dp.
A12_CANVAS_PX = 288 * 4

_GRADIENT_IDS = ("clayTanukiBody", "clayMuzzle", "clayLeafPlump", "claySoftHighlight")


def _mascot_defs() -> str:
    found = []
    for gid in _GRADIENT_IDS:
        match = re.search(rf'<linearGradient[^>]*id="{gid}".*?</linearGradient>', icon.DEFS, re.S)
        assert match, gid
        found.append(match.group(0))
    return "".join(found)


def _split_mascot() -> tuple[str, str]:
    plain = re.sub(r'\s*filter="url\(#[^)]+\)"', "", icon.MASCOT)
    marker = '<path d="M26 15C22'
    index = plain.index(marker)
    return plain[:index], plain[index:]


BODY, LEAF = _split_mascot()
MASCOT_DEFS = _mascot_defs()


def _svg(size: int, view_box: str, content: str) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="{view_box}" fill="none"><defs>{MASCOT_DEFS}</defs>{content}</svg>\n'
    )


def main() -> None:
    icon.SRC.mkdir(parents=True, exist_ok=True)
    # Lapisan intro Flutter, viewBox 54 yang sama dengan maskot.
    (ILLUSTRATION / "splash_tanuki_body.svg").write_text(_svg(54, "0 0 54 54", BODY))
    (ILLUSTRATION / "splash_tanuki_leaf.svg").write_text(_svg(54, "0 0 54 54", LEAF))

    offset = (A12_CANVAS_PX - PRE12_PX) / 2 / PRE12_PX * 54
    canvas_units = A12_CANVAS_PX / PRE12_PX * 54
    outputs = {
        "splash": (_svg(PRE12_PX, "0 0 54 54", BODY), PRE12_PX),
        "splash_android12": (
            _svg(A12_CANVAS_PX, f"{-offset} {-offset} {canvas_units} {canvas_units}", BODY),
            A12_CANVAS_PX,
        ),
    }
    for name, (text, size) in outputs.items():
        (icon.SRC / f"{name}.svg").write_text(text)
        render_transparent(text, size, icon.OUT / f"{name}.png")


if __name__ == "__main__":
    main()
