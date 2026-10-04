import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Sakelar Catat otomatis di "Atur lebih lanjut" (T-17.4, ADR-037 §3.2).
void main() {
  testWidgets('nominal tetap: sakelar tampil dan menyalakan autoRecord; kira-kira menyembunyikan dan mematikannya', (
    tester,
  ) async {
    late RecurringPattern? latest;
    RecurringPattern? value = const RecurringPattern();
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => RecordRepeatField(
                value: value,
                date: DateTime(2026, 10, 5),
                kind: TransactionKind.expense,
                onChanged: (next) => setState(() => value = latest = next),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(t.record.repeat.moreAction));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('repeat-auto-record'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(latest?.autoRecord, isTrue);

    await tester.ensureVisible(find.text(t.record.repeat.amountEstimated));
    await tester.tap(find.text(t.record.repeat.amountEstimated));
    await tester.pumpAndSettle();
    expect(latest?.autoRecord, isFalse);
    expect(toggle, findsNothing);
  });

  test('toRule: catat otomatis hanya untuk nominal tetap; of() membawanya', () {
    RecurringRule build(RecurringPattern p) => p.toRule(
      id: 'r',
      kind: RecurringKind.expense,
      amount: 100,
      walletId: 'bca',
      note: 'Kos',
      anchorDate: DateTime(2026, 10),
    );
    final fixed = build(const RecurringPattern(autoRecord: true));
    expect(fixed.autoRecord, isTrue);
    expect(RecurringPattern.of(fixed).autoRecord, isTrue);
    expect(
      build(const RecurringPattern(autoRecord: true, amountMode: RecurringAmountMode.estimated)).autoRecord,
      isFalse,
    );
  });
}
