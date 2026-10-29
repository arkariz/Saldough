import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

double _luminance(Color c) => c.computeLuminance();

/// Rasio kontras WCAG 2.1 antara dua warna buram.
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Pasangan (teks, latar, ambang) yang wajib dipenuhi setiap preset.
///
/// `onActionSecondary` di atas `actionSecondary` memakai 3:1 karena nilai
/// spek Kyoto (#ffffff di #b87352) hanya 3,74:1; dicatat sebagai keputusan
/// terbuka di README design system baru.
final _pairs = <(String, String, double)>[
  ('textPrimary', 'surfaceCanvas', 4.5),
  ('textPrimary', 'surfaceContainer', 4.5),
  ('textPrimary', 'surfaceContainerLow', 4.5),
  ('textPrimary', 'surfaceContainerHigh', 4.5),
  ('textPrimary', 'surfaceFloating', 4.5),
  ('textSecondary', 'surfaceCanvas', 4.5),
  ('textSecondary', 'surfaceContainer', 4.5),
  ('textSecondary', 'surfaceContainerLow', 4.5),
  ('onSurface', 'surface', 4.5),
  ('onSurfaceVariant', 'surface', 4.5),
  ('primary', 'surfaceCanvas', 4.5),
  ('primary', 'surfaceContainer', 4.5),
  ('onPrimary', 'primary', 4.5),
  ('onPrimaryContainer', 'primaryContainer', 4.5),
  ('onSecondary', 'secondary', 4.5),
  ('onSecondaryContainer', 'secondaryContainer', 4.5),
  ('onTertiary', 'tertiary', 4.5),
  ('onTertiaryContainer', 'tertiaryContainer', 4.5),
  ('onError', 'error', 4.5),
  ('onErrorContainer', 'errorContainer', 4.5),
  ('error', 'surfaceContainer', 4.5),
  ('onActionPrimary', 'actionPrimary', 4.5),
  ('onActionPrimary', 'actionPrimaryPressed', 4.5),
  ('onActionSecondary', 'actionSecondary', 3),
  ('onActionSecondary', 'actionSecondaryPressed', 3),
  ('inverseOnSurface', 'inverseSurface', 4.5),
  ('inversePrimary', 'inverseSurface', 4.5),
  ('income', 'surfaceCanvas', 4.5),
  ('income', 'surfaceContainer', 4.5),
  ('onIncomeContainer', 'incomeContainer', 4.5),
  ('warning', 'surfaceCanvas', 4.5),
  ('warning', 'surfaceContainer', 4.5),
  ('onWarningContainer', 'warningContainer', 4.5),
  ('info', 'surfaceCanvas', 4.5),
  ('info', 'surfaceContainer', 4.5),
  ('onInfoContainer', 'infoContainer', 4.5),
  ('outlineStrong', 'surfaceCanvas', 3),
  ('outlineStrong', 'surfaceContainer', 3),
];

void main() {
  test('id preset unik, snake_case, dan fallback terdaftar', () {
    final ids = DsThemePresets.all.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id), isTrue, reason: id);
    }
    expect(DsThemePresets.all, contains(DsThemePresets.fallback));
  });

  test('byId jatuh ke fallback untuk id tak dikenal atau null', () {
    expect(DsThemePresets.byId('autumn_kyoto'), autumnKyoto);
    expect(DsThemePresets.byId('tidak_ada'), DsThemePresets.fallback);
    expect(DsThemePresets.byId(null), DsThemePresets.fallback);
  });

  for (final preset in DsThemePresets.all) {
    for (final (mode, scheme) in [('terang', preset.light), ('gelap', preset.dark)]) {
      group('${preset.id} $mode', () {
        final colors = scheme.toMap();

        test('teks dan latar pasangannya lolos ambang kontras', () {
          final failures = <String>[];
          for (final (fg, bg, min) in _pairs) {
            final ratio = _contrast(colors[fg]!, colors[bg]!);
            if (ratio < min) failures.add('$fg di $bg: ${ratio.toStringAsFixed(2)} < $min');
          }
          expect(failures, isEmpty);
        });

        test('warna kategori di wadahnya lolos 4,5:1', () {
          for (final pair in scheme.categories.all) {
            expect(_contrast(pair.color, pair.container), greaterThanOrEqualTo(4.5));
          }
        });

        test('warna yang ditempatkan sebagai latar buram', () {
          for (final entry in colors.entries) {
            if (const {'focusRing', 'scrim'}.contains(entry.key)) continue;
            expect(entry.value.a, 1, reason: entry.key);
          }
        });
      });
    }
  }
}
