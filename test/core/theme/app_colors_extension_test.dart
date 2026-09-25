import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';

/// Luminansi relatif WCAG (rekomendasi ITU-R BT.709). Dihitung langsung dari
/// channel [Color] (0.0–1.0 sejak API `Color` versi baru) — rumus murni,
/// tidak butuh dependensi tambahan hanya untuk dipakai sekali per tes.
double _relativeLuminance(Color color) {
  double linearize(double channel) =>
      channel <= 0.04045 ? channel / 12.92 : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Rasio kontras WCAG antara dua warna — selalu >=1, simetris terhadap
/// urutan argumen.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppColorsExtension slot ADR-015 (accent/onAccent/transfer/pending, NFR-UX-003)', () {
    const minRatio = 4.5;
    const light = AppColorsExtension.light;
    const dark = AppColorsExtension.dark;

    test('nilai hex sesuai ADR-015, bukan hasil karangan', () {
      expect(light.accent, const Color(0xFFA73A00));
      expect(light.transfer, const Color(0xFF3D4A42));
      expect(light.pending, const Color(0xFF8D4B00));
      expect(dark.accent, const Color(0xFFE95100));
      expect(dark.transfer, const Color(0xFF708A7A));
      expect(dark.pending, const Color(0xFFCA6C00));
    });

    test('overBudget dan transfer berbagi hex dengan expense/textMuted ADR-015 secara sengaja', () {
      // `overBudget` di kelas ini masih nilai ADR-0006 lama (belum diganti
      // di T-2.2 ini — lihat catatan TASK_LIST T-2.2), jadi yang diverifikasi
      // di sini murni bahwa `transfer` ADR-015 (0x3D4A42/0x708A7A) BUKAN
      // salah salin: nilainya memang identik dengan `textMuted` versi
      // ADR-015 (bukan `textMuted` lama di kelas ini, yang nilainya beda).
      const adr015TextMutedLight = Color(0xFF3D4A42);
      const adr015TextMutedDark = Color(0xFF708A7A);
      expect(light.transfer, adr015TextMutedLight);
      expect(dark.transfer, adr015TextMutedDark);
    });

    for (final entry in {'accent': light.accent, 'transfer': light.transfer, 'pending': light.pending}.entries) {
      test('${entry.key} (terang) lolos >= $minRatio:1 terhadap cardBackground terang', () {
        final ratio = _contrastRatio(entry.value, light.cardBackground);
        expect(ratio, greaterThanOrEqualTo(minRatio));
      });

      test('${entry.key} (terang) lolos >= $minRatio:1 terhadap background terang', () {
        final ratio = _contrastRatio(entry.value, light.background);
        expect(ratio, greaterThanOrEqualTo(minRatio));
      });
    }

    for (final entry in {'accent': dark.accent, 'transfer': dark.transfer, 'pending': dark.pending}.entries) {
      test('${entry.key} (gelap) lolos >= $minRatio:1 terhadap cardBackground gelap', () {
        final ratio = _contrastRatio(entry.value, dark.cardBackground);
        expect(ratio, greaterThanOrEqualTo(minRatio));
      });

      test('${entry.key} (gelap) lolos >= $minRatio:1 terhadap background gelap', () {
        final ratio = _contrastRatio(entry.value, dark.background);
        expect(ratio, greaterThanOrEqualTo(minRatio));
      });
    }

    test('onAccent (terang) lolos >= $minRatio:1 di atas isian accent', () {
      final ratio = _contrastRatio(light.onAccent, light.accent);
      expect(ratio, greaterThanOrEqualTo(minRatio));
    });

    test('onAccent (gelap) lolos >= $minRatio:1 di atas isian accent — celah ADR-015 diisi manual', () {
      // ADR-015 hanya menyatakan kontras teks putih di atas `accent` mode
      // terang (6,46:1). Putih di atas `accent` gelap cuma 3,72:1 — gagal.
      // Nilai onAccent gelap di sini BUKAN dari ADR-015; lihat dokumentasi
      // field `onAccent`.
      final ratio = _contrastRatio(dark.onAccent, dark.accent);
      expect(ratio, greaterThanOrEqualTo(minRatio));
    });

    test('copyWith mempertahankan slot ADR-015 kalau tidak diisi', () {
      final copy = light.copyWith(textPrimary: Colors.black);
      expect(copy.accent, light.accent);
      expect(copy.onAccent, light.onAccent);
      expect(copy.transfer, light.transfer);
      expect(copy.pending, light.pending);
    });

    test('lerp(t: 0/1) pada slot ADR-015 mengembalikan warna awal/akhir', () {
      expect(light.lerp(dark, 0).accent, light.accent);
      expect(light.lerp(dark, 1).accent, dark.accent);
    });
  });

  group('AppColorsExtension.pixelLight/pixelDark (palet ADR-015 direvisi ADR-016)', () {
    const textRatio = 4.5;
    // WCAG 1.4.11: komponen non-teks (garis aksen, kotak ikon, bilah).
    const graphicRatio = 3.0;
    // ADR-016: tiga warna jenis transaksi harus berjarak hue selebar ini.
    const minHueGap = 60.0;
    const pixelLight = AppColorsExtension.pixelLight;
    const pixelDark = AppColorsExtension.pixelDark;

    double hueGap(Color a, Color b) {
      final diff = (HSLColor.fromColor(a).hue - HSLColor.fromColor(b).hue).abs();
      return diff > 180 ? 360 - diff : diff;
    }

    test('nilai hex sesuai tabel ADR-016, bukan hasil karangan', () {
      expect(pixelLight.income, const Color(0xFF15803D));
      expect(pixelLight.incomeFill, const Color(0xFF16A34A));
      expect(pixelLight.expense, const Color(0xFFB91C1C));
      expect(pixelLight.expenseFill, const Color(0xFFDC2626));
      expect(pixelLight.transfer, const Color(0xFF1D4ED8));
      expect(pixelLight.transferFill, const Color(0xFF2563EB));
      expect(pixelLight.pending, const Color(0xFFA16207));
      expect(pixelLight.accent, const Color(0xFFC2410C));
      expect(pixelLight.background, const Color(0xFFFFF8F5));
      expect(pixelLight.cardBackground, const Color(0xFFFFFFFF));
      expect(pixelLight.textPrimary, const Color(0xFF1E1B19));
      expect(pixelLight.textMuted, const Color(0xFF57534E));

      expect(pixelDark.income, const Color(0xFF22C55E));
      expect(pixelDark.expense, const Color(0xFFF87171));
      expect(pixelDark.transfer, const Color(0xFF60A5FA));
      expect(pixelDark.pending, const Color(0xFFF59E0B));
      expect(pixelDark.accent, const Color(0xFFE95100));
      expect(pixelDark.background, const Color(0xFF14120F));
      expect(pixelDark.cardBackground, const Color(0xFF1F1C18));
      expect(pixelDark.textPrimary, const Color(0xFFF2ECE7));
      expect(pixelDark.textMuted, const Color(0xFFA8A29E));
    });

    test('overBudget sama persis dengan expense di kedua mode, disengaja (ADR-015)', () {
      expect(pixelLight.overBudget, pixelLight.expense);
      expect(pixelDark.overBudget, pixelDark.expense);
    });

    test('edge memakai textPrimary, sesuai ADR-015 ("garis tepi struktural")', () {
      expect(pixelLight.edge, pixelLight.textPrimary);
      expect(pixelDark.edge, pixelDark.textPrimary);
    });

    test('accent/transfer/pending sengaja berbeda dari palet lama (revisi ADR-016)', () {
      expect(pixelLight.accent, isNot(AppColorsExtension.light.accent));
      expect(pixelLight.transfer, isNot(AppColorsExtension.light.transfer));
      expect(pixelLight.pending, isNot(AppColorsExtension.light.pending));
    });

    for (final mode in {'pixelLight': pixelLight, 'pixelDark': pixelDark}.entries) {
      final palette = mode.value;
      for (final entry in {
        'income': palette.income,
        'expense': palette.expense,
        'overBudget': palette.overBudget,
        'transfer': palette.transfer,
        'pending': palette.pending,
        'accent': palette.accent,
        'textPrimary': palette.textPrimary,
        'textMuted': palette.textMuted,
      }.entries) {
        test('${entry.key} (${mode.key}) lolos >= $textRatio:1 sebagai teks di kartu dan latar', () {
          expect(_contrastRatio(entry.value, palette.cardBackground), greaterThanOrEqualTo(textRatio));
          expect(_contrastRatio(entry.value, palette.background), greaterThanOrEqualTo(textRatio));
        });
      }

      for (final entry in {
        'incomeFill': palette.incomeFill,
        'expenseFill': palette.expenseFill,
        'transferFill': palette.transferFill,
      }.entries) {
        test('${entry.key} (${mode.key}) lolos >= $graphicRatio:1 sebagai bidang di kartu dan latar', () {
          expect(_contrastRatio(entry.value, palette.cardBackground), greaterThanOrEqualTo(graphicRatio));
          expect(_contrastRatio(entry.value, palette.background), greaterThanOrEqualTo(graphicRatio));
        });
      }

      test('tiga warna jenis transaksi (${mode.key}) berjarak hue >= $minHueGap derajat', () {
        final fills = [palette.incomeFill, palette.expenseFill, palette.transferFill];
        for (var i = 0; i < fills.length; i++) {
          for (var j = i + 1; j < fills.length; j++) {
            expect(hueGap(fills[i], fills[j]), greaterThanOrEqualTo(minHueGap));
          }
        }
      });
    }

    test('onAccent (terang) lolos >= $textRatio:1 di atas isian accent palet pixel', () {
      expect(_contrastRatio(pixelLight.onAccent, pixelLight.accent), greaterThanOrEqualTo(textRatio));
    });

    test('onAccent (gelap) lolos >= $textRatio:1 di atas isian accent palet pixel', () {
      expect(_contrastRatio(pixelDark.onAccent, pixelDark.accent), greaterThanOrEqualTo(textRatio));
    });

    test('copyWith dan lerp mengikutsertakan slot Fill', () {
      final copy = pixelLight.copyWith(incomeFill: Colors.black);
      expect(copy.incomeFill, Colors.black);
      expect(copy.expenseFill, pixelLight.expenseFill);
      expect(pixelLight.lerp(pixelDark, 0).transferFill, pixelLight.transferFill);
      expect(pixelLight.lerp(pixelDark, 1).transferFill, pixelDark.transferFill);
    });
  });
}
