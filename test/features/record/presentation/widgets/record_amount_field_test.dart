import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';

void main() {
  group('RecordAmountField -- formatter pemisah ribuan', () {
    testWidgets('digit yang diketik dirender berpemisah titik ribuan', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordAmountField(controller: controller, label: 'Nominal', kind: TransactionKind.income),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '5000000');
      await tester.pump();

      expect(controller.text, '5.000.000');
      expect(parseMoneyInput(controller.text), 500000000);
    });

    testWidgets('chip pilihan cepat menambah ke nilai yang sudah terurai, lalu memformat ulang', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordAmountField(
              controller: controller,
              label: 'Nominal',
              kind: TransactionKind.expense,
              quickAmounts: const [1000000, 5000000],
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '20000');
      await tester.pump();
      expect(controller.text, '20.000');

      await tester.tap(find.text('+10rb'));
      await tester.pump();

      expect(controller.text, '30.000');
      expect(parseMoneyInput(controller.text), 3000000);
    });
  });

  testWidgets('chip pilihan cepat berjajar sebaris, tidak bertumpuk vertikal', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordAmountField(
            controller: controller,
            label: 'Nominal',
            kind: TransactionKind.expense,
            quickAmounts: const [1000000, 5000000, 10000000],
          ),
        ),
      ),
    );

    final ys = ['+10rb', '+50rb', '+100rb'].map((l) => tester.getTopLeft(find.text(l)).dy).toSet();
    expect(ys, hasLength(1), reason: 'Container(alignment) di dalam Wrap membuat chip melebar penuh dan bertumpuk');
  });

  testWidgets('label chip pilihan cepat mengikuti bahasa (Inggris: k, bukan rb)', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordAmountField(
            controller: TextEditingController(),
            label: 'Amount',
            kind: TransactionKind.expense,
            quickAmounts: const [1000000, 5000000, 10000000],
          ),
        ),
      ),
    );

    for (final label in ['+10k', '+50k', '+100k']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.textContaining('rb'), findsNothing);
  });

  testWidgets('menutup dialog sesudah mengetuk di luar kolom tidak mengembalikan fokus ke nominal', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                RecordAmountField(controller: controller, label: 'Nominal', kind: TransactionKind.expense, autofocus: true),
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => TextButton(onPressed: () => Navigator.pop(context), child: const Text('tutup')),
                  ),
                  child: const Text('pilih tanggal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);

    await tester.tap(find.text('pilih tanggal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tutup'));
    await tester.pumpAndSettle();

    expect(field.focusNode.hasFocus, isFalse);
  });
}
