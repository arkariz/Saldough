import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  final typography = DsTypography.from(matcha.light);

  test('ukuran dan em spek dikonversi ke px', () {
    final headline = typography.headlineMd;
    expect(headline.fontFamily, DsFonts.sans);
    expect(headline.fontSize, 24);
    expect(headline.fontSize! * headline.height!, closeTo(32, 0.001));
    expect(headline.letterSpacing, closeTo(-0.48, 0.0001));
    expect(headline.fontWeight, FontWeight.w600);
    expect(headline.fontVariations, [const FontVariation.weight(600)]);

    expect(typography.labelSm.fontSize, 11);
    expect(typography.labelSm.letterSpacing, closeTo(0.66, 0.0001));
    expect(typography.bodyMd.letterSpacing, isNull);
  });

  test('keluarga huruf per peran', () {
    for (final entry in typography.toMap().entries) {
      final expected = entry.key.startsWith('pixel') ? DsFonts.pixel : DsFonts.sans;
      expect(entry.value.fontFamily, expected, reason: entry.key);
    }
  });

  test('nominal memakai angka tabular, warna bawaan textPrimary', () {
    expect(typography.amount.fontFeatures, contains(const FontFeature.tabularFigures()));
    expect(typography.pixelAmount.fontFeatures, isNull);
    expect(typography.bodyMd.color, matcha.light.textPrimary);
  });

  test('lerp di ujung sama dengan masing-masing skala', () {
    final dark = DsTypography.from(matcha.dark);
    expect(typography.lerp(dark, 1).bodyMd.color, dark.bodyMd.color);
    expect(typography.lerp(null, 0.5), same(typography));
  });
}
