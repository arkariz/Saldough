import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';

/// Papan angka (T-14.5) dan kolom operator kalkulator (T-8.18).
void main() {
  Future<List<String>> pump(WidgetTester tester, {required bool operators}) async {
    final pressed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: AppKeypad(onKey: pressed.add, onClear: () {}, operators: operators),
        ),
      ),
    );
    return pressed;
  }

  testWidgets('tanpa operators: tiga kolom, tanpa tombol operator', (tester) async {
    await pump(tester, operators: false);
    for (final key in moneyOperatorSymbols.keys) {
      expect(find.byKey(ValueKey('keypad-$key')), findsNothing);
    }
  });

  testWidgets('operators: kolom keempat ÷ × − + sejajar baris angka', (tester) async {
    final pressed = await pump(tester, operators: true);
    final rowsTop = [
      for (final digit in ['1', '4', '7', '0']) tester.getTopLeft(find.byKey(ValueKey('keypad-$digit'))).dy,
    ];
    for (final (i, key) in moneyOperatorSymbols.keys.indexed) {
      final finder = find.byKey(ValueKey('keypad-$key'));
      expect(tester.getTopLeft(finder).dy, rowsTop[i]);
      await tester.tap(finder);
    }
    expect(pressed, [moneyKeyDivide, moneyKeyMultiply, moneyKeySubtract, moneyKeyAdd]);
    expect(find.text('÷'), findsOneWidget);
  });

  testWidgets('tombol operator punya label semantik', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, operators: true);
    for (final label in [t.common.keypadAdd, t.common.keypadSubtract, t.common.keypadMultiply, t.common.keypadDivide]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    handle.dispose();
  });
}
