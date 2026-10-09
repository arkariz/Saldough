import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';

/// Nominal Catat (T-14.5): `amount-display` di tengah, diisi papan angka.
void main() {
  testWidgets('menampilkan nominal berpemisah ribuan dengan simbol mata uang, 0 bila kosong', (tester) async {
    final controller = TextEditingController();
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
    final controller = TextEditingController(text: '25.000');
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
}
