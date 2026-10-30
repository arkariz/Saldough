import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/theme/theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  for (final preset in DsThemePresets.all) {
    for (final brightness in Brightness.values) {
      group('${preset.id} ${brightness.name}', () {
        final theme = AppThemeBridge.build(preset, brightness);
        final scheme = brightness == Brightness.light ? preset.light : preset.dark;
        final legacy = theme.extension<AppColors>()!;

        test('memasang ekstensi lama dan Ds sekaligus', () {
          expect(theme.extension<AppNumberStyles>(), isNotNull);
          expect(theme.extension<DsColorScheme>(), same(scheme));
          expect(theme.extension<DsTypography>(), isNotNull);
          expect(theme.extension<DsElevation>(), isNotNull);
          expect(theme.brightness, brightness);
          expect(theme.scaffoldBackgroundColor, scheme.surfaceCanvas);
        });

        test('token lama diturunkan dari peran Ds', () {
          expect(legacy.bg, scheme.surfaceCanvas);
          expect(legacy.brand, scheme.actionPrimary);
          expect(legacy.positive, scheme.income);
          expect(legacy.catBlue, scheme.categories.blue.color);
          expect(legacy.catBlueBg, scheme.categories.blue.container);
        });

        test('pasangan teks utama layar lama lolos 4,5:1', () {
          for (final bg in [legacy.bg, legacy.surface, legacy.surface2]) {
            expect(_contrast(legacy.ink, bg), greaterThanOrEqualTo(4.5));
            expect(_contrast(legacy.ink2, bg), greaterThanOrEqualTo(4.5));
            expect(_contrast(legacy.brand, bg), greaterThanOrEqualTo(4.5), reason: 'brand di $bg');
          }
          expect(_contrast(legacy.onBrand, legacy.brand), greaterThanOrEqualTo(4.5));
          expect(_contrast(legacy.brandInk, legacy.brandSoft), greaterThanOrEqualTo(4.5));
          expect(_contrast(legacy.positive, legacy.surface), greaterThanOrEqualTo(4.5));
          expect(_contrast(legacy.danger, legacy.surface), greaterThanOrEqualTo(4.5));
        });

        test('garis kolom isian lama ≥ 3:1 di permukaan kartu', () {
          expect(_contrast(legacy.lineStrong, legacy.surface), greaterThanOrEqualTo(3));
        });
      });
    }
  }

  test('tema di-cache per preset dan kecerahan', () {
    expect(
      AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
      same(AppThemeBridge.build(DsThemePresets.fallback, Brightness.light)),
    );
  });

  testWidgets('context.appColors di mode gelap tidak jatuh ke token terang', (tester) async {
    late AppColors seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.dark),
        home: Builder(
          builder: (context) {
            seen = context.appColors;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(seen.bg, DsThemePresets.fallback.dark.surfaceCanvas);
    expect(seen.bg, isNot(AppColors.light.bg));
  });
}
