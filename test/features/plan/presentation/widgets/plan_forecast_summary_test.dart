import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_forecast_row.dart';

/// Perkiraan saldo di kartu bulan Beranda (QA PR #43 F13): pola label–nilai,
/// "Terendah" hanya bila lebih rendah dari akhir bulan.
void main() {
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    await loader.load();
  });

  final end = DateTime(2026, 10, 31);

  Future<void> pump(WidgetTester tester, {required int endBalance, required int lowBalance, DateTime? lowDate}) {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: Padding(
            // Kartu bulan Beranda: tepi layar 16 + isi kartu 16.
            padding: const EdgeInsets.all(32),
            child: PlanForecastSummary(
              endDate: end,
              endBalance: endBalance,
              lowDate: lowDate ?? end,
              lowBalance: lowBalance,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('terendah = akhir bulan: satu baris label dan nilai, tanpa "Terendah"', (tester) async {
    await pump(tester, endBalance: 861500000, lowBalance: 861500000);
    expect(find.text(t.plan.forecastEndLabel(date: '31 Okt')), findsOneWidget);
    expect(find.text('≈Rp8.615.000'), findsOneWidget);
    expect(find.byKey(const ValueKey('forecast-lowest')), findsNothing);
    expect(find.textContaining('≈'), findsOneWidget, reason: 'satu tanda ≈ per nilai');
  });

  testWidgets('terendah < akhir: baris kedua dengan tanggal; di bawah nol bernada bahaya', (tester) async {
    await pump(tester, endBalance: 861500000, lowBalance: -5000000, lowDate: DateTime(2026, 10, 24));
    final low = find.byKey(const ValueKey('forecast-lowest'));
    expect(tester.widget<Text>(low).data, t.plan.forecastLowest(amount: '≈−Rp50.000', date: '24 Okt'));
    expect(tester.widget<Text>(low).style?.color, AppColors.light.danger);
    expect(find.textContaining('('), findsNothing);
  });

  testWidgets('sembunyikan nominal menyamarkan kedua nilai', (tester) async {
    AmountVisibility.notifier.value = true;
    addTearDown(() => AmountVisibility.notifier.value = false);
    await pump(tester, endBalance: 861500000, lowBalance: 100000000, lowDate: DateTime(2026, 10, 24));
    expect(find.textContaining('8.615'), findsNothing);
    expect(find.textContaining('1.000.000'), findsNothing);
    expect(find.textContaining(AmountVisibility.mask), findsNWidgets(2));
  });

  for (final locale in [AppLocale.id, AppLocale.en]) {
    testWidgets('360dp ${locale.languageCode}: label dan baris terendah sebaris', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
      await pump(tester, endBalance: 861500000, lowBalance: 100000000, lowDate: DateTime(2026, 10, 24));
      expect(tester.takeException(), isNull);
      for (final text in [
        find.text(t.plan.forecastEndLabel(date: '31 ${locale == AppLocale.id ? 'Okt' : 'Oct'}')),
        find.byKey(const ValueKey('forecast-lowest')),
      ]) {
        final paragraph = tester.renderObject<RenderParagraph>(text);
        expect(paragraph.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(paragraph.size.width + 0.5));
      }
    });
  }
}
