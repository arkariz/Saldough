import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';

/// Nominal Catat (T-14.5): `amount-display` di tengah, diisi papan angka.
void main() {
  testWidgets('menampilkan nominal berpemisah ribuan dengan simbol mata uang, 0 bila kosong', (tester) async {
    final controller = RecordAmountController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(body: RecordAmountField(controller: controller, kind: TransactionKind.expense)),
      ),
    );
    expect(find.text('Rp0'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    controller.text = '45.000';
    await tester.pump();
    expect(find.text('Rp45.000'), findsOneWidget);
    final rich = tester.widget<RichText>(find.descendant(of: find.byKey(const ValueKey('record-amount')), matching: find.byType(RichText)));
    expect(rich.text.style!.fontSize, 40);
  });

  testWidgets('label semantik menyebut angka yang diketik walau nominal disembunyikan (QA F4)', (tester) async {
    AmountVisibility.notifier.value = true;
    addTearDown(() => AmountVisibility.notifier.value = false);
    final handle = tester.ensureSemantics();
    final controller = RecordAmountController(text: '25.000');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(body: RecordAmountField(controller: controller, kind: TransactionKind.expense)),
      ),
    );
    expect(find.bySemanticsLabel(RegExp(r'Rp25\.000')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(AmountVisibility.mask)), findsNothing);
    handle.dispose();
  });

  group('kalkulator (T-8.18)', () {
    RecordAmountController typed(List<String> keys, {String text = ''}) {
      final controller = RecordAmountController(text: text);
      keys.forEach(controller.applyKey);
      return controller;
    }

    test('teks berisi hasil, ungkapan terpisah', () {
      final controller = typed(['1', '0', '000', moneyKeyAdd, '5', '000']);
      addTearDown(controller.dispose);
      expect(controller.expression, '10.000 + 5.000');
      expect(controller.text, '15.000');
      expect(parseMoneyInput(controller.text), 1500000);
    });

    test('tanpa operator teks sama dengan papan angka biasa', () {
      final controller = typed(['4', '5', '000']);
      addTearDown(controller.dispose);
      expect(controller.expression, isEmpty);
      expect(controller.text, '45.000');
    });

    test('melanjutkan nominal yang sudah ada, mis. pra-isi', () {
      final controller = typed([moneyKeyMultiply, '2'], text: '25.000');
      addTearDown(controller.dispose);
      expect(controller.expression, '25.000 × 2');
      expect(controller.text, '50.000');
    });

    test('hasil tidak sah mengosongkan teks dan memberi alasan', () {
      final controller = typed(['5', moneyKeySubtract, '5']);
      addTearDown(controller.dispose);
      expect(controller.text, isEmpty);
      expect(controller.error, MoneyExpressionError.notPositive);
    });

    test('operator di akhir tetap memberi tahu pendengar walau hasil sama', () {
      final controller = typed(['5']);
      addTearDown(controller.dispose);
      var notified = 0;
      controller.addListener(() => notified++);
      expect(controller.applyKey(moneyKeyAdd), isTrue);
      expect(controller.text, '5');
      expect(notified, 1);
      expect(controller.applyKey(moneyKeyAdd), isFalse);
    });

    test('menulis teks atau clear dari luar membuang ungkapan', () {
      final controller = typed(['5', moneyKeyAdd, '5']);
      addTearDown(controller.dispose);
      controller.text = '75.000';
      expect(controller.expression, isEmpty);

      final errored = typed(['5', moneyKeySubtract, '5']);
      addTearDown(errored.dispose);
      var notified = 0;
      errored
        ..addListener(() => notified++)
        ..clear();
      expect(errored.expression, isEmpty);
      expect(errored.error, isNull);
      expect(notified, 1);
    });

    testWidgets('ungkapan dan keterangan galat tampil di atas nominal', (tester) async {
      final controller = RecordAmountController();
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(body: RecordAmountField(controller: controller, kind: TransactionKind.expense)),
        ),
      );
      expect(find.byKey(const ValueKey('record-amount-expression')), findsNothing);

      ['8', moneyKeyDivide, '2'].forEach(controller.applyKey);
      await tester.pump();
      expect(find.text('8 ÷ 2'), findsOneWidget);
      expect(find.text('Rp4', findRichText: true), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('8 ÷ 2.*Rp4')), findsOneWidget);
      expect(find.byKey(const ValueKey('record-amount-error')), findsNothing);

      controller
        ..applyKey(moneyKeySubtract)
        ..applyKey('4');
      await tester.pump();
      expect(find.text(t.record.calc.notPositive), findsOneWidget);
      handle.dispose();
    });
  });
}
