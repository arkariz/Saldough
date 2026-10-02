import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/domain/recurring_starters.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_starter_chips.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/recurring/recurring.dart';

void main() {
  final today = DateTime(2026, 10, 2, 9);

  test('tanggal bawaan: kemunculan berikutnya yang belum lewat; tanpa tanggal lazim = hari ini', () {
    expect(RecurringStarter.salary.dateFrom(today), DateTime(2026, 10, 25));
    expect(RecurringStarter.rent.dateFrom(today), DateTime(2026, 11));
    expect(RecurringStarter.bpjs.dateFrom(today), DateTime(2026, 10, 10));
    expect(RecurringStarter.internet.dateFrom(today), today);
    expect(RecurringStarter.rent.dateFrom(DateTime(2026, 10)), DateTime(2026, 10));
  });

  test('chip membuka CATAT mode jadwal dengan jenis, kategori, catatan, dan pola terisi (J1)', () {
    final input = RecurringStarterChips.inputFor(RecurringStarter.installment, today);
    expect(input.initialChoice, RecordChoice.expense);
    expect(input.draft?.kind, DraftKind.expense);
    expect(input.draft?.categoryId, 'builtin.bills');
    expect(input.draft?.note, 'Cicilan');
    expect(input.draft?.issues, isEmpty);
    expect(input.repeat?.end, const RecurringEndsAfter(12));

    final savings = RecurringStarterChips.inputFor(RecurringStarter.savings, today);
    expect(savings.initialChoice, RecordChoice.transfer);
    expect(savings.draft?.categoryId, isNull);
    expect(
      RecurringStarterChips.inputFor(RecurringStarter.electricity, today).repeat?.amountMode,
      RecurringAmountMode.estimated,
    );
  });
}
