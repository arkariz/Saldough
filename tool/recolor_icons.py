"""Selaraskan warna tertanam ikon pixel-art ke keluarga hue sistem warna ADR-016.

Hanya menyentuh assets/icons/*.svg (salinan aplikasi); docs/ tidak disentuh.
Kuning/emas/coklat/oranye (bahan dompet, koin, atap) SENGAJA dibiarkan:
keluarga hangat itu sudah selaras dengan terracotta + krem.
"""
import glob
import os
import re
import sys

MAP = {
    # garis luar -> warna edge/textPrimary layar baru
    "1E1E1E": "1E1B19",
    # slate abu-kebiruan -> stone abu hangat (selaras textMuted #57534E)
    "F8FAFC": "FFFFFF",
    "CBD5E1": "D6D3D1",
    "94A3B8": "A8A29E",
    "64748B": "78716C",
    "475569": "57534E",
    "334155": "44403C",
    # emerald -> hijau uang masuk (rampa dari token income #16A34A/#15803D)
    "34D399": "4ADE80",
    "10B981": "22C55E",
    "059669": "16A34A",
    "047857": "15803D",
    "064E3B": "14532D",
    # merah
    "EF4444": "DC2626",
    # sky + teal -> satu rampa biru mutasi (token transfer #2563EB/#1D4ED8)
    "BAE6FD": "BFDBFE",
    "38BDF8": "60A5FA",
    "0284C7": "2563EB",
    "CCFBF1": "DBEAFE",
    "14B8A6": "3B82F6",
    "0F766E": "1D4ED8",
    # sisa teal/mint/abu-biru terang -> keluarga biru, hijau, dan stone hangat
    "2DD4BF": "93C5FD",
    "115E59": "1E40AF",
    "134E4A": "1E3A8A",
    "A7F3D0": "BBF7D0",
    "065F46": "14532D",
    "E2E8F0": "E7E5E4",
    "F1F5F9": "F5F5F4",
    "E0F2FE": "DBEAFE",
    # pink gelap celengan -> terracotta gelap
    "BE185D": "9A3412",
    "9D174D": "7C2D12",
    "831843": "5C1F0A",
    # pink celengan -> terracotta (keluarga aksen)
    "FBCFE8": "FED7AA",
    "F472B6": "FB923C",
    "DB2777": "C2410C",
}

pat = re.compile(r'fill="#([0-9A-Fa-f]{6})"')


def recolor(svg):
    def sub(m):
        key = m.group(1).upper()
        return 'fill="#%s"' % MAP.get(key, key)

    return pat.sub(sub, svg)


def main(src_dir, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    changed = 0
    for f in sorted(glob.glob(os.path.join(src_dir, "*.svg"))):
        svg = open(f, encoding="utf-8").read()
        new = recolor(svg)
        if new != svg:
            changed += 1
        open(os.path.join(out_dir, os.path.basename(f)), "w", encoding="utf-8", newline="\n").write(new)
    print("recolored", changed, "files ->", out_dir)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
