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
  group('AppColorsExtension varian on-light (ADR-0006, UX-22)', () {
    // Ambang WCAG untuk teks normal. Dipakai juga untuk ikon kecil (bukan
    // ambang teks besar 3:1 yang lebih longgar) supaya marginnya aman untuk
    // kasus terkecil (ikon 14-18px seperti badge "perlu ditinjau").
    const minRatio = 4.5;
    const light = AppColorsExtension.light;
    const dark = AppColorsExtension.dark;

    final lightVariants = <String, Color>{
      'incomeOnLight': light.incomeOnLight,
      'expenseOnLight': light.expenseOnLight,
      'overBudgetOnLight': light.overBudgetOnLight,
      'investmentOnLight': light.investmentOnLight,
      'rollUpOnLight': light.rollUpOnLight,
      'needsReviewOnLight': light.needsReviewOnLight,
    };

    for (final entry in lightVariants.entries) {
      test('${entry.key} lolos >= $minRatio:1 terhadap cardBackground terang', () {
        final ratio = _contrastRatio(entry.value, light.cardBackground);
        expect(
          ratio,
          greaterThanOrEqualTo(minRatio),
          reason: '${entry.key} hanya ${ratio.toStringAsFixed(2)}:1 terhadap kartu '
              'putih — di bawah ambang keterbacaan.',
        );
      });

      test('${entry.key} lolos >= $minRatio:1 terhadap background terang (dasar krem)', () {
        final ratio = _contrastRatio(entry.value, light.background);
        expect(
          ratio,
          greaterThanOrEqualTo(minRatio),
          reason: '${entry.key} hanya ${ratio.toStringAsFixed(2)}:1 terhadap dasar '
              'krem — di bawah ambang keterbacaan.',
        );
      });
    }

    test('mode gelap tidak butuh varian terpisah — nilainya sama dengan slot aslinya', () {
      expect(dark.incomeOnLight, dark.income);
      expect(dark.expenseOnLight, dark.expense);
      expect(dark.overBudgetOnLight, dark.overBudget);
      expect(dark.investmentOnLight, dark.investment);
      expect(dark.rollUpOnLight, dark.rollUp);
      expect(dark.needsReviewOnLight, dark.needsReview);
    });

    test('slot asli (isian) TIDAK ikut berubah oleh penambahan varian on-light', () {
      // Regresi ADR-0006: isian (chip terpilih, badge, tombol) tetap
      // memakai hex aslinya — hanya teks/ikon yang pindah ke varian.
      expect(light.income, const Color(0xFF1E9E46));
      expect(light.expense, const Color(0xFFE13553));
      expect(light.overBudget, const Color(0xFFF07B12));
      expect(light.investment, const Color(0xFFD99B00));
      expect(light.rollUp, const Color(0xFF2D6FE0));
      expect(light.needsReview, const Color(0xFFFFD400));
    });

    test('copyWith mempertahankan seluruh varian on-light kalau tidak diisi', () {
      final copy = light.copyWith(textPrimary: Colors.black);
      expect(copy.incomeOnLight, light.incomeOnLight);
      expect(copy.needsReviewOnLight, light.needsReviewOnLight);
    });

    test('lerp(t: 0) mengembalikan warna awal untuk varian on-light', () {
      final lerped = light.lerp(dark, 0);
      expect(lerped.incomeOnLight, light.incomeOnLight);
    });

    test('lerp(t: 1) mengembalikan warna akhir untuk varian on-light', () {
      final lerped = light.lerp(dark, 1);
      expect(lerped.incomeOnLight, dark.incomeOnLight);
    });
  });
}
