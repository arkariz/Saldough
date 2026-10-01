import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';

/// `PixelTheme` adalah tema global aplikasi (ADR-031).
void main() {
  group('PixelTheme', () {
    test('terang membawa pixelLight, gelap membawa pixelDark', () {
      expect(PixelTheme.light.brightness, Brightness.light);
      expect(
        PixelTheme.light.extension<AppColorsExtension>(),
        AppColorsExtension.pixelLight,
      );
      expect(PixelTheme.dark.brightness, Brightness.dark);
      expect(
        PixelTheme.dark.extension<AppColorsExtension>(),
        AppColorsExtension.pixelDark,
      );
    });

    test('dialog dan pemilih tanggal berlatar hangat, bersudut pixelSm (B-18)', () {
      for (final (theme, colors) in [
        (PixelTheme.light, AppColorsExtension.pixelLight),
        (PixelTheme.dark, AppColorsExtension.pixelDark),
      ]) {
        expect(theme.dialogTheme.backgroundColor, colors.background);
        expect(theme.datePickerTheme.backgroundColor, colors.background);
        final shape = theme.dialogTheme.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, AppRadius.pixelSmAll);
        expect(shape.side.color, colors.edge);
        expect(theme.datePickerTheme.shape, shape);
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

    testWidgets(
      'textTheme: Space Grotesk untuk judul, Plus Jakarta Sans untuk isi',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: PixelTheme.light,
            home: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    'judul',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('isi', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        );

        expect(
          tester.widget<Text>(find.text('judul')).style!.fontFamily,
          contains('SpaceGrotesk'),
        );
        expect(
          tester.widget<Text>(find.text('isi')).style!.fontFamily,
          contains('PlusJakartaSans'),
        );
      },
    );

    testWidgets(
      'lembar modal berlatar colors.background dan memakai palet pixel tanpa pembungkus',
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
                      child: Text(context.appColors.income.toString()),
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
          AppColorsExtension.pixelLight.income.toString(),
        );
        expect(label, findsOneWidget);
        // `Material` terluar di dalam rute lembar bawah -- itu yang mewarnai
        // permukaan sheet, bukan `Material` lain di pohon (mis. milik tombol).
        final sheetMaterial = tester
            .widgetList<Material>(
              find.ancestor(of: label, matching: find.byType(Material)),
            )
            .last;
        expect(sheetMaterial.color, AppColorsExtension.pixelLight.background);
      },
    );

    testWidgets('context.appColors tanpa tema terpasang jatuh ke pixelLight', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Text(context.appColors.income.toString()),
          ),
        ),
      );

      expect(
        find.text(AppColorsExtension.pixelLight.income.toString()),
        findsOneWidget,
      );
    });
  });
}
