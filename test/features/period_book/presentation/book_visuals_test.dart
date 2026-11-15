import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/features/period_book/presentation/category_clay.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_visuals.dart';

import '../../../helpers/reduced_motion.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: DsTheme.light,
  builder: reduced ? reducedMotion : null,
  home: Scaffold(body: SingleChildScrollView(child: Center(child: child))),
);

void main() {
  for (final reduced in [false, true]) {
    testWidgets('komponen kaya dirender tanpa galat (gerak ${reduced ? 'dikurangi' : 'penuh'})', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              SizedBox(height: 200, width: 320, child: BookScene(child: SizedBox.expand())),
              DonutChart(
                fractions: [0.5, 0.3, 0.1],
                colors: [Colors.green, Colors.amber, Colors.blue],
                center: Text('Rp1'),
              ),
              PairBars(labelA: 'A', valueA: 100, textA: 'Rp100', labelB: 'B', valueB: 40, textB: 'Rp40'),
              PairBars(onDark: true, labelA: 'A', valueA: 0, textA: 'Rp0', labelB: 'B', valueB: 0, textB: 'Rp0'),
              BookChip(asset: 'assets/icons_clay/calendar_date.svg', label: '31 hari'),
              BookHero(child: Text('hero')),
            ],
          ),
          reduced: reduced,
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Rp1'), findsOneWidget);
    });
  }

  test('palet donat cukup untuk delapan irisan dan ikon kategori semuanya ada di disk', () {
    for (final key in [null, 'food', 'groceries', 'transport', 'bills', 'internet', 'health', 'entertainment', 'shopping', 'education', 'family', 'donation', 'expenseOther', 'incomeOther', 'salary', 'freelance', 'bonus', 'gift']) {
      expect(File(categoryClayAsset(key)).existsSync(), isTrue, reason: '$key');
    }
    for (final asset in const [
      'assets/icons_clay/income_arrow.svg',
      'assets/icons_clay/expense_arrow.svg',
      'assets/icons_clay/chart_investment.svg',
      'assets/icons_clay/hourglass_pending.svg',
      'assets/icons_clay/coins_currency.svg',
      'assets/icons_clay/calendar_date.svg',
      'assets/icons_clay/repeat_loop.svg',
      'assets/icons_clay/check_completed.svg',
      'assets/icons_clay/report_bars.svg',
      'assets/icons_clay/tag_category.svg',
    ]) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });
}
