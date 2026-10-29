import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  final light = matcha.light;
  final dark = matcha.dark;

  test('nilai terang Matcha sesuai spek', () {
    expect(light.surfaceCanvas, const Color(0xFFFAFAF9));
    expect(light.surfaceCard, const Color(0xFFFFFFFF));
    expect(light.primaryContainer, const Color(0xFF1F4B2C));
    expect(light.actionPrimary, const Color(0xFF1F4B2C));
    expect(light.textPrimary, const Color(0xFF111827));
    expect(light.outlineSubtle, const Color(0xFFEAECEF));
    expect(light.incomeContainer, const Color(0xFFD8E6DC));
  });

  test('copyWith hanya mengganti yang diberikan', () {
    final changed = light.copyWith(primary: Colors.black);
    expect(changed.primary, Colors.black);
    expect(changed.surface, light.surface);
    expect(changed.categories, light.categories);
  });

  test('lerp di ujung sama dengan masing-masing skema', () {
    expect(light.lerp(dark, 0).toMap(), light.toMap());
    expect(light.lerp(dark, 1).toMap(), dark.toMap());
    expect(light.lerp(dark, 1).categories.all, dark.categories.all);
    expect(light.lerp(null, 0.5), same(light));
  });

  test('toMaterial memakai peran yang sama namanya', () {
    final scheme = light.toMaterial(Brightness.light);
    expect(scheme.brightness, Brightness.light);
    expect(scheme.primary, light.primary);
    expect(scheme.surfaceContainer, light.surfaceContainer);
    expect(scheme.onInverseSurface, light.inverseOnSurface);
    expect(scheme.outlineVariant, light.outlineVariant);
  });
}
