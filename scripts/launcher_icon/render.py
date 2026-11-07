"""Render SVG ke PNG lewat QuickLook macOS (`qlmanage`).

QuickLook selalu meratakan gambar ke latar putih, jadi PNG transparan dibuat
dengan matting selisih: SVG dirender di atas latar putih dan hitam, lalu
alfa = 1 - (putih - hitam) dan warna = hitam / alfa per piksel. Hasilnya
tepat untuk gradasi, keburaman, dan bayangan.
"""

from __future__ import annotations

import pathlib
import re
import shutil
import struct
import subprocess
import tempfile
import zlib


def _qlmanage(svg_text: str, size: int, tmp: pathlib.Path, name: str) -> pathlib.Path:
    src = tmp / f"{name}.svg"
    src.write_text(svg_text)
    subprocess.run(["qlmanage", "-t", "-s", str(size), "-o", str(tmp), str(src)], check=True, capture_output=True)
    return tmp / f"{name}.svg.png"


def _decode(path: pathlib.Path, max_rows: int | None = None) -> tuple[int, int, int, list[bytearray]]:
    data = path.read_bytes()
    i, idat = 8, b""
    width = height = color_type = 0
    while i < len(data):
        (length,) = struct.unpack(">I", data[i : i + 4])
        kind, chunk = data[i + 4 : i + 8], data[i + 8 : i + 8 + length]
        i += 12 + length
        if kind == b"IHDR":
            width, height, depth, color_type = struct.unpack(">IIBB", chunk[:10])
            assert depth == 8, depth
        elif kind == b"IDAT":
            idat += chunk
    bpp = {6: 4, 2: 3}[color_type]
    stride = width * bpp
    limit = height if max_rows is None else min(height, max_rows)
    if max_rows is None:
        raw = zlib.decompress(idat)
    else:
        raw = zlib.decompressobj().decompress(idat, (stride + 1) * limit)
    rows, prev, o = [], bytearray(stride), 0
    for _ in range(limit):
        f = raw[o]
        o += 1
        row = bytearray(raw[o : o + stride])
        o += stride
        if f == 1:
            for x in range(bpp, stride):
                row[x] = (row[x] + row[x - bpp]) & 255
        elif f == 2:
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 255
        elif f == 3:
            for x in range(stride):
                a = row[x - bpp] if x >= bpp else 0
                row[x] = (row[x] + (a + prev[x]) // 2) & 255
        elif f == 4:
            for x in range(stride):
                a = row[x - bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x - bpp] if x >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                row[x] = (row[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(row)
        prev = row
    return width, height, bpp, rows


def _encode(path: pathlib.Path, width: int, height: int, rows: list[bytes], rgb: bool = False) -> None:
    """Menulis PNG 8-bit; [rows] RGB bila [rgb] (tanpa alfa), selain itu RGBA."""
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(kind: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2 if rgb else 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def _with_backdrop(svg_text: str, color: str) -> str:
    backdrop = f'<rect x="-100000" y="-100000" width="200000" height="200000" fill="{color}"/>'
    return re.sub(r"(</defs>)", r"\1" + backdrop, svg_text, count=1)


def render_opaque(svg_text: str, size: int, out: pathlib.Path) -> None:
    """Render SVG yang menutupi seluruh kanvas (tanpa transparansi)."""
    with tempfile.TemporaryDirectory() as d:
        shutil.move(_qlmanage(svg_text, size, pathlib.Path(d), "o"), out)


def render_transparent(svg_text: str, size: int, out: pathlib.Path) -> None:
    """Render SVG berlatar transparan menjadi PNG RGBA."""
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d)
        white = _decode(_qlmanage(_with_backdrop(svg_text, "#ffffff"), size, tmp, "w"))
        black = _decode(_qlmanage(_with_backdrop(svg_text, "#000000"), size, tmp, "b"))
    width, height, bpp, wrows = white
    _, _, bpp_b, brows = black
    rows = []
    for y in range(height):
        wr, br = wrows[y], brows[y]
        out_row = bytearray(width * 4)
        for x in range(width):
            wi, bi, oi = x * bpp, x * bpp_b, x * 4
            rb, gb, bb = br[bi], br[bi + 1], br[bi + 2]
            diff = max(wr[wi] - rb, wr[wi + 1] - gb, wr[wi + 2] - bb, 0)
            alpha = 255 - diff
            if alpha > 0:
                out_row[oi] = min(255, rb * 255 // alpha)
                out_row[oi + 1] = min(255, gb * 255 // alpha)
                out_row[oi + 2] = min(255, bb * 255 // alpha)
                out_row[oi + 3] = alpha
        rows.append(bytes(out_row))
    _encode(out, width, height, rows)


def crop_top(png: pathlib.Path, height: int) -> None:
    """Memotong [png] menjadi [height] baris teratas (RGBA)."""
    width, _, bpp, rows = _decode(png)
    kept = []
    for row in rows[:height]:
        if bpp == 4:
            kept.append(bytes(row))
        else:
            out = bytearray(width * 4)
            for x in range(width):
                out[x * 4 : x * 4 + 3] = row[x * 3 : x * 3 + 3]
                out[x * 4 + 3] = 255
            kept.append(bytes(out))
    _encode(png, width, height, kept)
