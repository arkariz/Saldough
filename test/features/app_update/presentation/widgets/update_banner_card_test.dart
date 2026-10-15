import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/app_update/presentation/widgets/update_banner_card.dart';

double _luminance(Color color) {
  double linearize(double channel) =>
      channel <= 0.04045 ? channel / 12.92 : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(color.r) + 0.7152 * linearize(color.g) + 0.0722 * linearize(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

/// Kartu banner pembaruan rupa v3 (APP_UPDATE §7): tata letak dan kontras.
void main() {
  setUpAll(() async {
    await (FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'))).load();
  });

  Future<void> pump(WidgetTester tester, Widget card, {ThemeData? theme, double width = 360}) async {
    tester.view
      ..physicalSize = Size(width, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? PixelTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(alignment: Alignment.topCenter, child: card),
          ),
        ),
      ),
    );
  }

  const full = UpdateBannerCard(
    title: 'Versi baru tersedia.',
    icon: IconKey.systemUpdate,
    versionChip: 'v0.7.0',
    actionLabel: 'Perbarui',
    dismissLabel: 'Nanti',
  );

  testWidgets('judul dan chip sebaris bila muat; × di pojok kanan atas, tombol di baris sendiri di bawah', (
    tester,
  ) async {
    await pump(tester, full, width: 480);
    final title = tester.getRect(find.text('Versi baru tersedia.'));
    final chip = tester.getRect(find.byKey(const ValueKey('app-update-version-chip')));
    final close = tester.getRect(find.byKey(const ValueKey('app-update-dismiss')));
    final action = tester.getRect(find.byKey(const ValueKey('app-update-action')));
    final card = tester.getRect(find.byType(UpdateBannerCard));

    expect((chip.center.dy - title.center.dy).abs(), lessThan(8), reason: 'sebaris');
    expect(close.top - card.top, lessThan(16));
    expect(card.right - close.right, lessThan(16), reason: 'pojok kanan');
    expect(close.width, greaterThanOrEqualTo(48));
    expect(action.top, greaterThanOrEqualTo(title.bottom), reason: 'tombol di baris sendiri');
    expect(card.right - action.right, lessThanOrEqualTo(16), reason: 'tombol rata kanan');
    expect(action.width, lessThan(card.width / 2), reason: 'selebar teksnya, bukan sebaris penuh');
  });

  testWidgets('di 360dp judul memakai lebar penuh dan chip turun ke bawahnya', (tester) async {
    await pump(
      tester,
      const UpdateBannerCard(
        title: 'Mengunduh versi baru. Kamu tetap bisa mencatat.',
        icon: IconKey.progressActivity,
        spin: true,
        versionChip: 'v0.7.0',
        actionLabel: 'Perbarui',
        dismissLabel: 'Nanti',
      ),
    );
    final title = tester.getRect(find.textContaining('Mengunduh'));
    final chip = tester.getRect(find.byKey(const ValueKey('app-update-version-chip')));
    expect(chip.top, greaterThanOrEqualTo(title.bottom - 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tanpa chip, tanpa ×, tanpa tombol: hanya ikon dan judul', (tester) async {
    await pump(tester, const UpdateBannerCard(title: 'Mengunduh versi baru.', icon: IconKey.systemUpdate));
    expect(find.byKey(const ValueKey('app-update-version-chip')), findsNothing);
    expect(find.byKey(const ValueKey('app-update-dismiss')), findsNothing);
    expect(find.byKey(const ValueKey('app-update-action')), findsNothing);
  });

  testWidgets('× dan tombol memanggil callback masing-masing; × punya label aksesibilitas', (tester) async {
    var dismissed = 0;
    var acted = 0;
    await pump(
      tester,
      UpdateBannerCard(
        title: 'Versi baru tersedia.',
        icon: IconKey.systemUpdate,
        actionLabel: 'Perbarui',
        onAction: () => acted++,
        dismissLabel: 'Nanti',
        onDismiss: () => dismissed++,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('app-update-dismiss')));
    await tester.tap(find.byKey(const ValueKey('app-update-action')));
    expect((dismissed, acted), (1, 1));
    expect(find.bySemanticsLabel('Nanti'), findsOneWidget);
  });

  for (final (name, theme) in [('terang', PixelTheme.light), ('gelap', PixelTheme.dark)]) {
    testWidgets('kontras 4,5:1 di mode $name: teks di brand, tombol, dan chip', (tester) async {
      await pump(tester, full, theme: theme);
      final c = theme.extension<AppColors>()!;
      expect(_contrast(c.onBrand, c.brand), greaterThanOrEqualTo(4.5), reason: 'judul di latar brand');
      expect(_contrast(c.brandInk, c.surface), greaterThanOrEqualTo(4.5), reason: 'teks tombol');
      expect(
        _contrast(theme.brightness == Brightness.dark ? c.onBrand : c.ink, c.straw),
        greaterThanOrEqualTo(4.5),
        reason: 'teks chip di atas straw',
      );
      expect(_contrast(c.brand, c.surface), greaterThanOrEqualTo(3), reason: 'ikon di tile');
    });
  }
}
