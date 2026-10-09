import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Ulangi di Catat (QA PR #43 F11): tetap baris form, pilihan di sheet.
void main() {
  final date = DateTime(2026, 10, 9);

  Future<ValueNotifier<RecurringPattern?>> pump(
    WidgetTester tester, {
    RecurringPattern? initial,
    bool locked = false,
  }) async {
    final value = ValueNotifier<RecurringPattern?>(initial);
    addTearDown(value.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: ValueListenableBuilder<RecurringPattern?>(
            valueListenable: value,
            builder: (context, current, _) => RecordRepeatField(
              value: current,
              date: date,
              kind: TransactionKind.expense,
              locked: locked,
              onChanged: (next) => value.value = next,
            ),
          ),
        ),
      ),
    );
    return value;
  }

  testWidgets('baris "Ulangi · Tidak"; memilih Tiap bulan di sheet menyetel nilai dan meringkas baris', (tester) async {
    final value = await pump(tester);
    final row = find.byKey(const ValueKey('record-repeat'));
    expect(find.descendant(of: row, matching: find.text(t.record.repeat.label)), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text(t.record.repeat.off)), findsOneWidget);
    final rowHeight = tester.getSize(row).height;

    await tester.tap(row);
    await tester.pumpAndSettle();
    // Bentuk baris tidak berubah: pilihannya di sheet, bukan chip di form.
    expect(tester.getSize(row).height, rowHeight);
    expect(find.byType(AppChip), findsNothing);

    await tester.tap(find.byKey(const ValueKey('repeat-option-monthly')));
    await tester.pumpAndSettle();
    expect(value.value?.frequency, RecurringFrequency.monthly);

    await tester.tap(find.byKey(const ValueKey('repeat-done')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: row, matching: find.text(t.record.repeat.everyMonthDay(day: 9))),
      findsOneWidget,
    );
    expect(tester.getSize(row).height, rowHeight);

    // Kembali ke Tidak lewat sheet yang sama.
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('repeat-option-off')));
    await tester.pumpAndSettle();
    expect(value.value, isNull);
  });

  testWidgets('terkunci (Jadikan Rutin): sheet tanpa "Tidak", baris meringkas pola', (tester) async {
    await pump(tester, initial: const RecurringPattern(), locked: true);
    final row = find.byKey(const ValueKey('record-repeat'));
    expect(find.descendant(of: row, matching: find.text(t.record.repeat.everyMonthDay(day: 9))), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('repeat-option-off')), findsNothing);
    expect(find.byKey(const ValueKey('repeat-option-weekly')), findsOneWidget);
  });
}
