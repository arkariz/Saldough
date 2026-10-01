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
      // Amandemen ADR-016 28 Sep 2026: latar arang hangat, bukan hampir-hitam.
      expect(pixelDark.accent, const Color(0xFFF46B1C));
      expect(pixelDark.background, const Color(0xFF231F1B));
      expect(pixelDark.cardBackground, const Color(0xFF2D2823));
      expect(pixelDark.edge, const Color(0xFF8A7D6E));
      expect(pixelDark.textPrimary, const Color(0xFFF2ECE7));
      expect(pixelDark.textMuted, const Color(0xFFA8A29E));
    });

    test('overBudget sama persis dengan expense di kedua mode, disengaja (ADR-015)', () {
      expect(pixelLight.overBudget, pixelLight.expense);
      expect(pixelDark.overBudget, pixelDark.expense);
    });

    test('edge = textPrimary di mode terang; di mode gelap redup tapi >= 3:1 batas komponen (amandemen ADR-016)', () {
      expect(pixelLight.edge, pixelLight.textPrimary);
      expect(pixelDark.edge, isNot(pixelDark.textPrimary));
      expect(_contrastRatio(pixelDark.edge, pixelDark.background), greaterThanOrEqualTo(3.0));
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

  group('iconTile — garis ikon pixel tetap terbaca (NFR-UX-003, UX-19)', () {
    // Warna garis tepi seluruh ikon pixel di assets/icons.
    const iconOutline = Color(0xFF1E1B19);
    const minRatio = 3.0;

    for (final (name, colors) in [('terang', AppColorsExtension.pixelLight), ('gelap', AppColorsExtension.pixelDark)]) {
      final fills = {
        'netral': null,
        'income': colors.incomeFill,
        'expense': colors.expenseFill,
        'transfer': colors.transferFill,
        'pending': colors.pending,
      };
      for (final entry in fills.entries) {
        test('${entry.key} ($name) >= $minRatio:1 terhadap garis ikon', () {
          final ratio = _contrastRatio(iconOutline, colors.iconTile(entry.value));
          expect(ratio, greaterThanOrEqualTo(minRatio), reason: 'rasio ${ratio.toStringAsFixed(2)}');
        });
      }
    }
  });
}
