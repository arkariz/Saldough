import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  final typography = DsTypography.from(autumnKyoto.light);

  test('rem dan em spek dikonversi ke px', () {
    final headline = typography.headlineMd;
    expect(headline.fontFamily, DsFonts.heading);
    expect(headline.fontSize, 24);
    expect(headline.fontSize! * headline.height!, closeTo(32, 0.001));
    expect(headline.letterSpacing, closeTo(-0.36, 0.0001));
    expect(headline.fontWeight, FontWeight.w600);
    expect(headline.fontVariations, [const FontVariation.weight(600)]);

    expect(typography.labelSm.fontSize, 11);
    expect(typography.labelSm.letterSpacing, closeTo(0.44, 0.0001));
    expect(typography.bodyMd.letterSpacing, isNull);
  });

  test('keluarga huruf per peran', () {
    for (final name in ['displayLg', 'displayLgMobile', 'headlineLg', 'headlineLgMobile', 'headlineMd', 'headlineSm']) {
      expect(typography.toMap()[name]!.fontFamily, DsFonts.heading, reason: name);
    }
    for (final name in ['bodyLg', 'bodyMd', 'bodySm']) {
      expect(typography.toMap()[name]!.fontFamily, DsFonts.body, reason: name);
    }
    for (final name in ['labelLg', 'labelMd', 'labelSm', 'amountLg', 'amountMd', 'amountSm']) {
      expect(typography.toMap()[name]!.fontFamily, DsFonts.mono, reason: name);
    }
  });

  test('nominal memakai angka tabular, warna bawaan textPrimary', () {
    expect(typography.amountMd.fontFeatures, [const FontFeature.tabularFigures()]);
    expect(typography.bodyMd.color, autumnKyoto.light.textPrimary);
  });

  test('lerp di ujung sama dengan masing-masing skala', () {
    final dark = DsTypography.from(autumnKyoto.dark);
    expect(typography.lerp(dark, 1).bodyMd.color, dark.bodyMd.color);
    expect(typography.lerp(null, 0.5), same(typography));
  });
}
