import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_save_button.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
  builder: (context, home) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: home!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('RecordSaveButton', () {
    testWidgets('animasi berhasil: centang dan "Tersimpan" dulu, lalu menyimpan sesudah jeda', (tester) async {
      var saved = 0;
      await tester.pumpWidget(_host(RecordSaveButton(label: 'Simpan Pengeluaran', onPressed: () => saved++)));
      expect(find.text('Simpan Pengeluaran'), findsOneWidget);
      await tester.tap(find.text('Simpan Pengeluaran'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(saved, 0, reason: 'belum menyimpan selama animasi');
      expect(find.text(t.record.savedLabel), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      // Ketukan kedua saat animasi diabaikan.
      await tester.tap(find.text(t.record.savedLabel));
      await tester.pump(RecordSaveButton.celebration);
      await tester.pump(const Duration(seconds: 2));
      expect(saved, 1);
    });

    testWidgets('gerak dikurangi: menyimpan langsung tanpa animasi', (tester) async {
      var saved = 0;
      await tester.pumpWidget(_host(RecordSaveButton(label: 'Simpan', onPressed: () => saved++), reduced: true));
      await tester.tap(find.text('Simpan'));
      expect(saved, 1);
      expect(find.text(t.record.savedLabel), findsNothing);
    });

    testWidgets('nonaktif: tidak bereaksi', (tester) async {
      await tester.pumpWidget(_host(const RecordSaveButton(label: 'Simpan', onPressed: null)));
      await tester.tap(find.text('Simpan'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(t.record.savedLabel), findsNothing);
    });

    testWidgets('ditutup sebelum jeda selesai: tidak menyimpan', (tester) async {
      var saved = 0;
      await tester.pumpWidget(_host(RecordSaveButton(label: 'Simpan', onPressed: () => saved++)));
      await tester.tap(find.text('Simpan'));
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pump(const Duration(seconds: 2));
      expect(saved, 0);
    });
  });

  group('Chip cepat nominal', () {
    testWidgets('+5k dan +100k menambah nominal dan memberi tahu', (tester) async {
      final controller = RecordAmountController();
      addTearDown(controller.dispose);
      var changed = 0;
      await tester.pumpWidget(
        _host(
          RecordAmountField(controller: controller, kind: TransactionKind.expense, onChanged: () => changed++),
          reduced: true,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('record-quick-5000')));
      await tester.pump();
      expect(controller.text, '5.000');
      await tester.tap(find.byKey(const ValueKey('record-quick-100000')));
      await tester.pump();
      expect(controller.text, '105.000');
      expect(changed, 2);
      expect(ActiveCurrency.value.fractionDigits, 0);
    });

    testWidgets('chip membuang ungkapan kalkulator', (tester) async {
      final controller = RecordAmountController()..applyKey('1');
      addTearDown(controller.dispose);
      controller
        ..applyKey(moneyKeyAdd)
        ..applyKey('2');
      expect(controller.expression, isNotEmpty);
      expect(controller.addSen(500000), isTrue);
      expect(controller.expression, isEmpty);
    });
  });

  group('DsKeypad dan DsSegmentedPill', () {
    testWidgets('keypad mengirim nilai tombol dan tekan lama hapus mengosongkan', (tester) async {
      final keys = <String>[];
      var cleared = 0;
      await tester.pumpWidget(
        _host(
          DsKeypad(
            rows: const [
              [DsKeypadKey(value: '1'), DsKeypadKey(value: 'back', icon: Icons.backspace_outlined)],
            ],
            clearValue: 'back',
            onKey: keys.add,
            onClear: () => cleared++,
          ),
          reduced: true,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('keypad-1')));
      await tester.longPress(find.byKey(const ValueKey('keypad-back')));
      expect(keys, contains('1'));
      expect(cleared, 1);
    });

    testWidgets('pil segmen berpindah dan melaporkan nilai', (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 320,
              child: DsSegmentedPill<int>(
                segments: const [
                  DsSegment(value: 0, label: 'Keluar'),
                  DsSegment(value: 1, label: 'Masuk'),
                  DsSegment(value: 2, label: 'Transfer'),
                ],
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
              ),
            ),
          ),
          reduced: true,
        ),
      );
      await tester.tap(find.text('Transfer'));
      await tester.pump();
      expect(selected, 2);
    });
  });
}
