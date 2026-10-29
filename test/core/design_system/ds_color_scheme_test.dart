import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

void main() {
  final light = autumnKyoto.light;
  final dark = autumnKyoto.dark;

  test('nilai terang Kyoto sesuai spek', () {
    expect(light.surfaceCanvas, const Color(0xFFFBF9F4));
    expect(light.primaryContainer, const Color(0xFFB45309));
    expect(light.textPrimary, const Color(0xFF2A2421));
    expect(light.outlineSubtle, const Color(0xFFDED5C6));
    expect(light.actionSecondary, const Color(0xFFB87352));
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
