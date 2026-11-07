#!/usr/bin/env python3
"""Bangun tangkapan layar listing Play (1080x1920) dari tangkapan aplikasi.

    python3 scripts/launcher_icon/build_store_screenshots.py

Masukan: tangkapan mentah 1080x2400 di `build/store_screenshots/raw/`
(`<bahasa>_<layar>.png`, diambil dari emulator berisi cadangan demo
`tool/store_screenshots/demo_backup_test.dart`; caranya di
`PLAY_STORE_LISTING.md` §4.1). Keluaran: `docs/03-release/store_assets/
screenshots/<bahasa>/NN_<nama>.jpg`, JPG tanpa alfa (syarat Play: JPG atau
PNG 24-bit; JPG ~4x lebih kecil di repo).

Tata letak tiap slide: pil kategori, judul dua baris (baris kedua warna
aksen), subjudul, gelombang bergaris putus-putus, lalu satu atau dua ponsel
berbingkai dan kartu potongan layar yang "keluar" dari ponsel. Rupa design
system v2: huruf Plus Jakarta Sans, maskot tanuki clay, palet matcha/pink.
Status bar asli ditimpa status bar 9.41 supaya rapi dan seragam.
"""

from __future__ import annotations

import base64
import pathlib
import tempfile
from dataclasses import dataclass, field

import build_launcher_icon as icon
from build_store_assets import _fonts, _to_jpeg
from render import _decode, _encode, render_opaque

ROOT = icon.ROOT
RAW = ROOT / "build/store_screenshots/raw"
OUT = ROOT / "docs/03-release/store_assets/screenshots"

W, H = 1080, 1920
SHOT_W, SHOT_H = 1080, 2400
STATUS_H = 56  # baris status bar asli (ikon di baris 14-49)


@dataclass
class Theme:
    bg_top: str
    bg_bottom: str
    ink: str
    accent: str
    sub: str
    pill_bg: str
    pill_ink: str
    dot: str
    band: str
    dash: str


THEMES = {
    "matcha_dark": Theme("#163d27", "#0d1f15", "#ffffff", "#bdefc4", "#d3e6d7", "#ffffff22", "#ffffff", "#f5c542", "#ffffff14", "#bdefc466"),
    "mint": Theme("#effaf0", "#c9ecce", "#0f2a19", "#1f7a45", "#35513f", "#1f4b2c14", "#1f4b2c", "#1f9a55", "#ffffff8c", "#1f4b2c40"),
    "honey": Theme("#fff8e8", "#fde3a7", "#2b1d05", "#b86b00", "#5b4a2c", "#b86b0018", "#7a4700", "#e0a100", "#ffffff8c", "#b86b0045"),
    "pink": Theme("#fff1f6", "#f8c9dc", "#2a0f1b", "#be185d", "#5c3644", "#be185d14", "#8a1245", "#e11d74", "#ffffff8c", "#be185d40"),
    "lavender": Theme("#f4f1ff", "#d8cffa", "#1b1438", "#5b43c9", "#433b66", "#5b43c914", "#3d2c96", "#7b61ff", "#ffffff8c", "#5b43c940"),
    "night": Theme("#1d3326", "#0e1210", "#ffffff", "#a2d2a9", "#cfd9d2", "#ffffff1f", "#ffffff", "#a2d2a9", "#ffffff10", "#a2d2a955"),
}


@dataclass
class Phone:
    shot: str  # nama layar tanpa awalan bahasa
    x: float
    y: float
    width: float
    tilt: float = 0


@dataclass
class Card:
    """Potongan layar [shot] (kotak dalam piksel tangkapan) yang melayang."""

    shot: str
    box: tuple[int, int, int, int]  # x, y, lebar, tinggi
    x: float
    y: float
    width: float
    tilt: float = 0
    radius: float = 26


@dataclass
class Slide:
    name: str
    theme: str
    pill: dict[str, str]
    title: dict[str, tuple[str, str]]
    sub: dict[str, tuple[str, str]]
    phones: list[Phone]
    cards: list[Card] = field(default_factory=list)
    badge: dict[str, str] | None = None
    badge_left: bool = False
    mascot: bool = False


TWO = [Phone("a", 30, 700, 500, -2), Phone("b", 550, 790, 500, 2)]


def two(a: str, b: str) -> list[Phone]:
    return [Phone(a, TWO[0].x, TWO[0].y, TWO[0].width, TWO[0].tilt), Phone(b, TWO[1].x, TWO[1].y, TWO[1].width, TWO[1].tilt)]


SLIDES = [
    Slide(
        "01_beranda",
        "matcha_dark",
        {"id": "Beranda", "en": "Home"},
        {"id": ("Semua uangmu,", "satu buku."), "en": ("All your money,", "one book.")},
        {
            "id": ("Saldo semua dompet, arus bulan ini, dan", "perkiraan akhir bulan di satu layar."),
            "en": ("Every wallet's balance, this month's flow,", "and a month-end forecast on one screen."),
        },
        [Phone("home", 190, 640, 700)],
        cards=[Card("dompet", (42, 756, 996, 370), 520, 1500, 520, 3)],
        mascot=True,
    ),
    Slide(
        "02_catat",
        "mint",
        {"id": "Catat", "en": "Record"},
        {"id": ("Catat dalam", "hitungan detik."), "en": ("Record it", "in seconds.")},
        {
            "id": ("Ketik nominal, pilih kategori, selesai.", "Bisa juga lewat suara."),
            "en": ("Type the amount, pick a category, done.", "Or just say it out loud."),
        },
        two("catat", "riwayat"),
    ),
    Slide(
        "03_rutin",
        "honey",
        {"id": "Rutin", "en": "Recurring"},
        {"id": ("Tagihan rutin,", "sudah terjadwal."), "en": ("Recurring bills,", "already scheduled.")},
        {
            "id": ("Gaji, internet, langganan, dan nabung.", "Kelihatan yang jatuh tempo minggu ini."),
            "en": ("Salary, internet, subscriptions, savings.", "See what's due this week."),
        },
        two("rutin", "rutin2"),
    ),
    Slide(
        "04_anggaran",
        "pink",
        {"id": "Anggaran", "en": "Budgets"},
        {"id": ("Anggaran sebagai", "rencana."), "en": ("Budgets,", "as a plan.")},
        {
            "id": ("Bagi rencana belanja jadi pos. Saldo tidak", "terpotong, sisanya tetap kelihatan."),
            "en": ("Split your spending plan into items. Your", "balance stays put; you see what's left."),
        },
        two("budget_pink", "anggaran"),
        badge={"id": "Warna pink", "en": "Pink theme"},
    ),
    Slide(
        "05_freelance",
        "lavender",
        {"id": "Freelance", "en": "Freelance"},
        {"id": ("Jam kerja", "jadi pendapatan."), "en": ("Hours become", "income.")},
        {
            "id": ("Catat jam kerja per proyek, kumpulkan jadi", "tagihan, tandai saat sudah dibayar."),
            "en": ("Log hours per project, bundle them into", "invoices, and mark them when paid."),
        },
        two("project", "freelance"),
    ),
    Slide(
        "06_analisis",
        "night",
        {"id": "Analisis", "en": "Analysis"},
        {"id": ("Tahu ke mana", "uangmu pergi."), "en": ("See where", "your money goes.")},
        {
            "id": ("Pengeluaran per kategori, dibanding", "biasanya, dan enam bulan terakhir."),
            "en": ("Spending by category, compared with", "usual, and the last six months."),
        },
        [Phone("analisis", 190, 640, 700)],
        cards=[Card("analisis2", (30, 1250, 1020, 900), 480, 1520, 560, -3)],
        badge={"id": "Mode gelap", "en": "Dark mode"},
        badge_left=True,
    ),
]


def _png_b64(path: pathlib.Path) -> str:
    return base64.b64encode(path.read_bytes()).decode()


def _pixel(path: pathlib.Path, x: int, y: int) -> tuple[int, int, int]:
    """Warna piksel (x, y) tangkapan; hanya baris sampai y yang diurai."""
    _, _, bpp, rows = _decode(path, max_rows=y + 1)
    row = rows[y]
    return (row[x * bpp], row[x * bpp + 1], row[x * bpp + 2])


def _status_color(path: pathlib.Path) -> tuple[int, int, int]:
    return _pixel(path, 4, 4)


def _status_bar(color: tuple[int, int, int]) -> str:
    r, g, b = color
    ink = "#111111" if (0.299 * r + 0.587 * g + 0.114 * b) > 140 else "#ffffff"
    y = 36
    return (
        f'<rect width="{SHOT_W}" height="{STATUS_H}" fill="rgb({r},{g},{b})"/>'
        f'<text x="64" y="{y + 4}" font-family="TkSans" font-weight="700" font-size="30" fill="{ink}">9:41</text>'
        # Sinyal, wifi, baterai.
        f'<path d="M846 {y + 4} L874 {y + 4} L874 {y - 22} Z" fill="{ink}"/>'
        f'<path d="M892 {y - 14} a24 24 0 0 1 32 0 l-16 18 z" fill="{ink}"/>'
        f'<rect x="944" y="{y - 18}" width="44" height="22" rx="6" fill="none" stroke="{ink}" stroke-width="3"/>'
        f'<rect x="948" y="{y - 14}" width="32" height="14" rx="3" fill="{ink}"/>'
        f'<rect x="990" y="{y - 11}" width="4" height="8" rx="2" fill="{ink}"/>'
    )


def _phone(lang: str, phone: Phone, uid: str) -> str:
    path = RAW / f"{lang}_{phone.shot}.png"
    bezel = phone.width * 0.026
    screen_w = phone.width - 2 * bezel
    scale = screen_w / SHOT_W
    screen_h = SHOT_H * scale
    height = screen_h + 2 * bezel
    radius = phone.width * 0.12
    cx, cy = phone.x + phone.width / 2, phone.y + height / 2
    inner = (
        f'<g transform="translate({bezel} {bezel}) scale({scale})" clip-path="url(#scr{uid})">'
        f'<image width="{SHOT_W}" height="{SHOT_H}" href="data:image/png;base64,{_png_b64(path)}"/>'
        f"{_status_bar(_status_color(path))}"
        f'<circle cx="{SHOT_W / 2}" cy="30" r="15" fill="#0b0c0d"/></g>'
    )
    return (
        f'<clipPath id="scr{uid}"><rect width="{SHOT_W}" height="{SHOT_H}" rx="{(radius - bezel) / scale}"/></clipPath>'
        f'<g transform="rotate({phone.tilt} {cx} {cy}) translate({phone.x} {phone.y})" filter="url(#phoneShadow)">'
        f'<rect width="{phone.width}" height="{height}" rx="{radius}" fill="#16191b"/>'
        f'<rect x="1.5" y="1.5" width="{phone.width - 3}" height="{height - 3}" rx="{radius - 1.5}" fill="none" stroke="#3a3f43" stroke-width="3"/>'
        f"{inner}</g>"
    )


def _card(lang: str, card: Card, uid: str) -> str:
    path = RAW / f"{lang}_{card.shot}.png"
    bx, by, bw, bh = card.box
    scale = card.width / bw
    height = bh * scale
    cx, cy = card.x + card.width / 2, card.y + height / 2
    r, g, b = _pixel(path, bx + 4, by + 4)
    return (
        f'<clipPath id="card{uid}"><rect width="{bw}" height="{bh}" rx="{card.radius / scale}"/></clipPath>'
        f'<g transform="rotate({card.tilt} {cx} {cy}) translate({card.x} {card.y})" filter="url(#cardShadow)">'
        f'<rect width="{card.width}" height="{height}" rx="{card.radius}" fill="rgb({r},{g},{b})"/>'
        f'<g transform="scale({scale})" clip-path="url(#card{uid})">'
        f'<image x="{-bx}" y="{-by}" width="{SHOT_W}" height="{SHOT_H}" href="data:image/png;base64,{_png_b64(path)}"/></g>'
        f"</g>"
    )


def _mascot(x: float, y: float, size: float) -> str:
    """Maskot + koin (lebar ~41 satuan) berpusat di (x, y)."""
    scale = size / 41
    return (
        f'<g transform="translate({x - icon.CENTER_X * scale:.1f} {y - icon.CENTER_Y * scale:.1f}) scale({scale:.3f})">'
        f'<g filter="url(#groundShadow)">{icon.MASCOT}{icon.COIN}</g></g>'
    )


def _pill(text: str, theme: Theme) -> str:
    width = len(text) * 18.6 + 88
    return (
        f'<rect x="80" y="84" width="{width}" height="68" rx="34" fill="{theme.pill_bg}"/>'
        f'<circle cx="114" cy="118" r="10" fill="{theme.dot}"/>'
        f'<text x="138" y="130" font-family="TkSans" font-weight="600" font-size="34" fill="{theme.pill_ink}">{text}</text>'
    )


def _wave(theme: Theme) -> str:
    return (
        f'<path d="M0 560 C 260 500, 520 640, 1080 540 L1080 700 C 700 760, 300 640, 0 700 Z" fill="{theme.band}"/>'
        f'<path d="M0 588 C 300 560, 560 690, 1080 586" fill="none" stroke="{theme.dash}" stroke-width="6" '
        f'stroke-dasharray="34 26" stroke-linecap="round"/>'
    )


def _badge(text: str, theme: Theme, left: bool = False) -> str:
    width = len(text) * 19 + 104
    x = 60 if left else W - width - 60
    y = H - 150
    return (
        f'<g filter="url(#cardShadow)"><rect x="{x}" y="{y}" width="{width}" height="84" rx="42" fill="#ffffff"/></g>'
        f'<circle cx="{x + 46}" cy="{y + 42}" r="13" fill="{theme.accent}"/>'
        f'<text x="{x + 72}" y="{y + 54}" font-family="TkSans" font-weight="800" font-size="36" fill="{theme.accent}">{text}</text>'
    )


def slide_svg(slide: Slide, lang: str) -> str:
    theme = THEMES[slide.theme]
    line1, line2 = slide.title[lang]
    sub1, sub2 = slide.sub[lang]
    defs = (
        icon.DEFS
        + f'<linearGradient id="sbg" x1="0" y1="0" x2="0.35" y2="1"><stop offset="0%" stop-color="{theme.bg_top}"/>'
        f'<stop offset="100%" stop-color="{theme.bg_bottom}"/></linearGradient>'
        '<filter id="phoneShadow" x="-30%" y="-20%" width="160%" height="140%"><feDropShadow dx="0" dy="24" stdDeviation="26" flood-color="#000000" flood-opacity="0.28"/></filter>'
        '<filter id="cardShadow" x="-30%" y="-40%" width="160%" height="180%"><feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="#000000" flood-opacity="0.22"/></filter>'
    )
    parts = [f'<rect width="{W}" height="{H}" fill="url(#sbg)"/>', _wave(theme), _pill(slide.pill[lang], theme)]
    parts.append(
        f'<text font-family="TkSans" font-weight="800" font-size="104" letter-spacing="-3">'
        f'<tspan x="76" y="272" fill="{theme.ink}">{line1}</tspan>'
        f'<tspan x="76" y="384" fill="{theme.accent}">{line2}</tspan></text>'
    )
    parts.append(
        f'<text font-family="TkSans" font-weight="500" font-size="40" fill="{theme.sub}">'
        f'<tspan x="82" y="468">{sub1}</tspan><tspan x="82" y="522">{sub2}</tspan></text>'
    )
    if slide.mascot:
        parts.append(_mascot(950, 128, 150))
    for i, phone in enumerate(slide.phones):
        parts.append(_phone(lang, phone, f"{i}"))
    for i, card in enumerate(slide.cards):
        parts.append(_card(lang, card, f"{i}"))
    if slide.badge:
        parts.append(_badge(slide.badge[lang], theme, slide.badge_left))
    # QuickLook hanya merender kanvas persegi dengan tepat (lihat build_store_assets).
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{H}" height="{H}" viewBox="0 0 {H} {H}">'
        f'<defs>{defs}<clipPath id="slide"><rect width="{W}" height="{H}"/></clipPath></defs>{_fonts()}'
        f'<g clip-path="url(#slide)">{"".join(parts)}</g></svg>\n'
    )


def _crop_rgb(png: pathlib.Path, out: pathlib.Path) -> None:
    width, _, bpp, rows = _decode(png)
    kept = []
    for row in rows[:H]:
        if bpp == 3:
            kept.append(bytes(row[: W * 3]))
        else:
            line = bytearray(W * 3)
            line[0::3] = row[0 : W * 4 : 4]
            line[1::3] = row[1 : W * 4 : 4]
            line[2::3] = row[2 : W * 4 : 4]
            kept.append(bytes(line))
    _encode(out, W, H, kept, rgb=True)


def main(only: set[str] | None = None) -> None:
    for lang in ("id", "en"):
        folder = OUT / lang
        folder.mkdir(parents=True, exist_ok=True)
        for slide in SLIDES:
            if only and slide.name not in only:
                continue
            with tempfile.TemporaryDirectory() as d:
                png = pathlib.Path(d) / "slide.png"
                render_opaque(slide_svg(slide, lang), H, png)
                _crop_rgb(png, png)
                _to_jpeg(png, folder / f"{slide.name}.jpg")
            print(lang, slide.name)


if __name__ == "__main__":
    import sys

    main(set(sys.argv[1:]) or None)
