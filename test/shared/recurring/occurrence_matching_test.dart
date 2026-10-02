import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kasus wajib pencocokan RECURRING_AND_FORECAST §7.7 (ADR-034 §3.4).
void main() {
  RecurringRule netflix({RecurringAmountMode mode = RecurringAmountMode.fixed, String id = 'netflix'}) => RecurringRule(
    id: id,
    kind: RecurringKind.expense,
    amount: 6500000,
    amountMode: mode,
    walletId: 'bca',
    note: 'Netflix',
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9)),
  );

  ExpenseTransaction tx(int amount, DateTime date, {String wallet = 'bca'}) =>
      ExpenseTransaction(id: 't', date: date, amount: amount, note: '', walletId: wallet);

  test('rutin tetap 65.000 tgl 1; notifikasi 65.000 tgl 3, dompet sama: cocok persis', () {
    final match = matchOccurrences(tx(6500000, DateTime(2026, 10, 3, 9)), rules: [netflix()], transactions: const []);
    expect(match?.date, DateTime(2026, 10));
    expect(match?.exact, isTrue);
  });

  test('ditolak: nominal 79.000, dompet beda, lebih dari 3 hari, atau sudah tercatat', () {
    expect(matchOccurrences(tx(7900000, DateTime(2026, 10, 3)), rules: [netflix()], transactions: const []), isNull);
    expect(
      matchOccurrences(
        tx(6500000, DateTime(2026, 10, 3), wallet: 'jago'),
        rules: [netflix()],
        transactions: const [],
      ),
      isNull,
    );
    expect(matchOccurrences(tx(6500000, DateTime(2026, 10, 5)), rules: [netflix()], transactions: const []), isNull);
    final recorded = ExpenseTransaction(
      id: 'r',
      date: DateTime(2026, 10),
      amount: 6500000,
      note: '',
      walletId: 'bca',
      recurrence: RecurrenceLink(ruleId: 'netflix', occurrenceDate: DateTime(2026, 10)),
    );
    expect(matchOccurrences(tx(6500000, DateTime(2026, 10, 2)), rules: [netflix()], transactions: [recorded]), isNull);
  });

  test('dua kandidat (dua rutin sama): tidak ditebak', () {
    expect(
      matchOccurrences(
        tx(6500000, DateTime(2026, 10, 2)),
        rules: [
          netflix(),
          netflix(id: 'lain'),
        ],
        transactions: const [],
      ),
      isNull,
    );
  });

  test('rutin kira-kira ±10%: cocok tetapi bukan persis (hanya saran)', () {
    final match = matchOccurrences(
      tx(7000000, DateTime(2026, 10, 2)),
      rules: [netflix(mode: RecurringAmountMode.estimated)],
      transactions: const [],
    );
    expect(match?.exact, isFalse);
    expect(
      matchOccurrences(
        tx(7200000, DateTime(2026, 10, 2)),
        rules: [netflix(mode: RecurringAmountMode.estimated)],
        transactions: const [],
      ),
      isNull,
    );
  });
}
