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
/// Ambang 3:1 untuk garis yang wajib terlihat dan aksen ikon di kartu hero.
/// `textTertiary` (hanya placeholder dan nonaktif), `outlineSubtle`, dan
/// `outlineStrong` (KT-DS1: ikut spek) sengaja tidak diuji. `textMuted`
/// hanya diuji di kartu dan kanvas (KT-DS2).
final _pairs = <(String, String, double)>[
  ('textPrimary', 'surfaceCanvas', 4.5),
  ('textPrimary', 'surfaceCard', 4.5),
  ('textPrimary', 'surfaceOverlay', 4.5),
  ('textPrimary', 'surfaceHover', 4.5),
  ('textPrimary', 'surfaceSunken', 4.5),
  ('textSecondary', 'surfaceCanvas', 4.5),
  ('textSecondary', 'surfaceCard', 4.5),
  ('textSecondary', 'surfaceSunken', 4.5),
  ('textMuted', 'surfaceCanvas', 4.5),
  ('textMuted', 'surfaceCard', 4.5),
  ('onSurface', 'surface', 4.5),
  ('onSurfaceVariant', 'surface', 4.5),
  ('primary', 'surfaceCard', 4.5),
  ('onPrimary', 'primary', 4.5),
  ('onPrimaryContainer', 'primaryContainer', 4.5),
  ('onSecondary', 'secondary', 4.5),
  ('onSecondaryContainer', 'secondaryContainer', 4.5),
  ('onTertiary', 'tertiary', 4.5),
  ('onTertiaryContainer', 'tertiaryContainer', 4.5),
  ('onError', 'error', 4.5),
  ('onErrorContainer', 'errorContainer', 4.5),
  ('error', 'surfaceCard', 4.5),
  ('actionPrimary', 'surfaceCard', 4.5),
  ('actionPrimary', 'surfaceCanvas', 4.5),
  ('onActionPrimary', 'actionPrimary', 4.5),
  ('onActionPrimary', 'actionPrimaryPressed', 4.5),
  ('onActionSecondary', 'actionSecondary', 4.5),
  ('onActionSecondary', 'actionSecondaryPressed', 4.5),
  ('actionGhost', 'surfaceCard', 4.5),
  ('actionGhost', 'actionGhostPressed', 4.5),
  ('inverseOnSurface', 'inverseSurface', 4.5),
  ('inversePrimary', 'inverseSurface', 4.5),
  ('onHero', 'heroSurface', 4.5),
  ('onHeroMuted', 'heroSurface', 4.5),
  ('heroAccent', 'heroSurface', 3),
  ('primaryContainer', 'onHero', 4.5),
  ('onHero', 'heroActionSecondary', 4.5),
  ('onToneWarmContainer', 'toneWarmContainer', 4.5),
  ('income', 'surfaceCanvas', 4.5),
  ('income', 'surfaceCard', 4.5),
  ('onIncomeContainer', 'incomeContainer', 4.5),
  ('warning', 'surfaceCard', 4.5),
  ('onWarningContainer', 'warningContainer', 4.5),
  ('info', 'surfaceCard', 4.5),
  ('onInfoContainer', 'infoContainer', 4.5),
  ('outline', 'surfaceCard', 3),
  ('outlineFocus', 'surfaceCard', 3),
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
    expect(DsThemePresets.byId('matcha'), matcha);
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
            if (const {'heroTile', 'scrim'}.contains(entry.key)) continue;
            expect(entry.value.a, 1, reason: entry.key);
          }
        });
      });
    }
  }
}
