import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';

/// Luminansi relatif WCAG (rekomendasi ITU-R BT.709). Dihitung langsung dari
/// channel [Color] (0.0–1.0 sejak API `Color` versi baru).
double _relativeLuminance(Color color) {
  double linearize(double channel) =>
      channel <= 0.04045 ? channel / 12.92 : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(color.r) + 0.7152 * linearize(color.g) + 0.0722 * linearize(color.b);
}

/// Rasio kontras WCAG antara dua warna — selalu >=1, simetris.
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Kontras token warna ADR-034 (design system bagian Aksesibilitas): teks
/// 4,5:1 di permukaannya, ikon bermakna dan isi progress bar 3:1, di kedua
/// tema.
void main() {
  const textRatio = 4.5;
  const graphicRatio = 3.0;

  for (final (mode, c) in [
    ('terang', AppColors.light),
    ('gelap', AppColors.dark),
  ]) {
    group('AppColors ($mode)', () {
      final textPairs = <String, (Color, Color)>{
        'ink di bg': (c.ink, c.bg),
        'ink di surface': (c.ink, c.surface),
        'ink di surface2': (c.ink, c.surface2),
        'ink2 di bg': (c.ink2, c.bg),
        'ink2 di surface': (c.ink2, c.surface),
        'ink2 di surface2': (c.ink2, c.surface2),
        'ink3 di bg': (c.ink3, c.bg),
        'ink3 di surface': (c.ink3, c.surface),
        'ink3 di surface2': (c.ink3, c.surface2),
        'onBrand di brand': (c.onBrand, c.brand),
        'brand (tautan) di surface': (c.brand, c.surface),
        'brand (tautan) di bg': (c.brand, c.bg),
        'brandInk di brandSoft': (c.brandInk, c.brandSoft),
        'positive di surface': (c.positive, c.surface),
        'positive di positiveSoft': (c.positive, c.positiveSoft),
        'danger di surface': (c.danger, c.surface),
        'danger di dangerSoft': (c.danger, c.dangerSoft),
        'warning di surface': (c.warning, c.surface),
        'warning di warningSoft': (c.warning, c.warningSoft),
        'info di infoSoft': (c.info, c.infoSoft),
        'onInverse di inverseSurface': (c.onInverse, c.inverseSurface),
        'inverseBrand di inverseSurface': (c.inverseBrand, c.inverseSurface),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in textPairs.entries) {
        test('teks $name >= $textRatio:1', () {
          final ratio = _contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(textRatio),
            reason: 'rasio ${ratio.toStringAsFixed(2)}',
          );
        });
      }

      final graphicPairs = <String, (Color, Color)>{
        'catOrange di catOrangeBg': (c.catOrange, c.catOrangeBg),
        'catGreen di catGreenBg': (c.catGreen, c.catGreenBg),
        'catBlue di catBlueBg': (c.catBlue, c.catBlueBg),
        'catPurple di catPurpleBg': (c.catPurple, c.catPurpleBg),
        'catTeal di catTealBg': (c.catTeal, c.catTealBg),
        'catRose di catRoseBg': (c.catRose, c.catRoseBg),
        'catAmber di catAmberBg': (c.catAmber, c.catAmberBg),
        'catIndigo di catIndigoBg': (c.catIndigo, c.catIndigoBg),
        'catBrown di catBrownBg': (c.catBrown, c.catBrownBg),
        'catSlate di catSlateBg': (c.catSlate, c.catSlateBg),
        'ink (isi bar) di track': (c.ink, c.track),
        'warningFill (isi bar) di track': (c.warningFill, c.track),
        'danger (isi bar) di track': (c.danger, c.track),
        'lineStrong (tepi input) di surface': (c.lineStrong, c.surface),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in graphicPairs.entries) {
        test('grafis $name >= $graphicRatio:1', () {
          final ratio = _contrastRatio(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(graphicRatio),
            reason: 'rasio ${ratio.toStringAsFixed(2)}',
          );
        });
      }
    });
  }

  test('copyWith dan lerp mengikutsertakan token', () {
    final copy = AppColors.light.copyWith(brand: Colors.black);
    expect(copy.brand, Colors.black);
    expect(copy.ink2, AppColors.light.ink2);
    expect(
      AppColors.light.lerp(AppColors.dark, 0).catTeal,
      AppColors.light.catTeal,
    );
    expect(
      AppColors.light.lerp(AppColors.dark, 1).catTeal,
      AppColors.dark.catTeal,
    );
  });

  test(
    'ikon piksel (garis tepi gelap) terbaca di tile surface2 mode terang',
    () {
      // Warna garis tepi seluruh ikon piksel di assets/icons. Mode gelap belum
      // punya varian bertepi terang: B-23 (ADR-034 §4), bukan diuji di sini.
      const iconOutline = Color(0xFF1E1B19);
      expect(
        _contrastRatio(iconOutline, AppColors.light.surface2),
        greaterThanOrEqualTo(graphicRatio),
      );
    },
  );
}
