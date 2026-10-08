import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';

/// `PixelTheme` adalah tema global aplikasi (ADR-031), isinya ADR-034.
void main() {
  group('PixelTheme', () {
    test('terang membawa AppColors.light, gelap AppColors.dark, plus AppNumberStyles', () {
      expect(PixelTheme.light.brightness, Brightness.light);
      expect(
        PixelTheme.light.extension<AppColors>(),
        AppColors.light,
      );
      expect(PixelTheme.dark.brightness, Brightness.dark);
      expect(
        PixelTheme.dark.extension<AppColors>(),
        AppColors.dark,
      );
      expect(PixelTheme.light.extension<AppNumberStyles>(), isNotNull);
      expect(PixelTheme.dark.extension<AppNumberStyles>()!.amount.color, AppColors.dark.ink);
    });

    test('dialog, pemilih tanggal, dan sheet berlatar surface tanpa bingkai (ADR-034)', () {
      for (final (theme, colors) in [
        (PixelTheme.light, AppColors.light),
        (PixelTheme.dark, AppColors.dark),
      ]) {
        expect(theme.dialogTheme.backgroundColor, colors.surface);
        expect(theme.datePickerTheme.backgroundColor, colors.surface);
        expect(theme.bottomSheetTheme.backgroundColor, colors.surface);
        final shape = theme.dialogTheme.shape! as RoundedRectangleBorder;
        expect(shape.side, BorderSide.none);
        expect(theme.scaffoldBackgroundColor, colors.bg);
        expect(theme.colorScheme.primary, colors.brand);
        expect(theme.colorScheme.error, colors.danger);
        expect(theme.snackBarTheme.backgroundColor, colors.inverseSurface);
      }
    });

    test(
      'dipasang sebagai theme/darkTheme MaterialApp, bukan pembungkus per layar',
      () {
        final app = File('lib/app/app.dart').readAsStringSync();
        expect(app, contains('theme: PixelTheme.light'));
        expect(app, contains('darkTheme: PixelTheme.dark'));
      },
    );

    test(
      'tanpa unduhan huruf saat runtime: google_fonts tidak lagi jadi dependensi',
      () {
        expect(
          File('pubspec.yaml').readAsStringSync(),
          isNot(contains('google_fonts')),
        );
      },
    );

    test('satu huruf: semua slot textTheme dan skala Angka memakai Plus Jakarta Sans', () {
      final theme = PixelTheme.light;
      final t = theme.textTheme;
      for (final style in [
        t.displayLarge, t.headlineSmall, t.titleLarge, t.titleMedium, t.bodyLarge,
        t.bodyMedium, t.bodySmall, t.labelLarge, t.labelMedium, t.labelSmall,
      ]) {
        expect(style!.fontFamily, kAppFontFamily);
      }
      final numbers = theme.extension<AppNumberStyles>()!;
      for (final style in [numbers.amountDisplay, numbers.amountHero, numbers.amountLg, numbers.amount, numbers.amountSm]) {
        expect(style.fontFamily, kAppFontFamily);
        expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      }
    });

    test('skala Teks sesuai tokens.json dan tidak ada teks di bawah 12px', () {
      final t = PixelTheme.light.textTheme;
      expect(t.headlineSmall!.fontSize, 24);
      expect(t.titleLarge!.fontSize, 18);
      expect(t.titleMedium!.fontWeight, FontWeight.w600);
      expect(t.bodyLarge!.fontSize, 16);
      expect(t.bodyMedium!.fontSize, 14);
      expect(t.bodySmall!.fontSize, 12);
      for (final style in [t.labelMedium, t.labelSmall, t.bodySmall]) {
        expect(style!.fontSize, greaterThanOrEqualTo(kMinLabelSize));
      }
    });

    test('huruf lama tidak lagi dibundel', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('SpaceGrotesk')));
      expect(pubspec, isNot(contains('SpaceMono')));
      expect(pubspec, contains('PlusJakartaSans'));
    });

    testWidgets(
      'lembar modal berlatar surface dan memakai token tanpa pembungkus',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: PixelTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => SizedBox(
                      height: 100,
                      child: Text(context.appColors.positive.toString()),
                    ),
                  ),
                  child: const Text('buka'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('buka'));
        await tester.pumpAndSettle();

        final label = find.text(
          AppColors.light.positive.toString(),
        );
        expect(label, findsOneWidget);
        // `Material` terluar di dalam rute lembar bawah -- itu yang mewarnai
        // permukaan sheet, bukan `Material` lain di pohon (mis. milik tombol).
        final sheetMaterial = tester
            .widgetList<Material>(
              find.ancestor(of: label, matching: find.byType(Material)),
            )
            .last;
        expect(sheetMaterial.color, AppColors.light.surface);
      },
    );

    testWidgets('context.appColors tanpa tema terpasang jatuh ke AppColors.light', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Text(context.appColors.positive.toString()),
          ),
        ),
      );

      expect(
        find.text(AppColors.light.positive.toString()),
        findsOneWidget,
      );
    });
  });
}
