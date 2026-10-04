import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Contoh RECURRING_AND_FORECAST §7.6 dan §7.2a (hari ini 2 Okt 2026),
/// nominal dalam sen.
void main() {
  final today = DateTime(2026, 10, 2, 9);
  final from = DateTime(2026, 10);
  final until = DateTime(2026, 11);

  RecurringRule rule(
    String id,
    int amount,
    int day, {
    RecurringKind kind = RecurringKind.expense,
    RecurringAmountMode mode = RecurringAmountMode.fixed,
    String? budgetItemKey,
  }) => RecurringRule(
    id: id,
    kind: kind,
    amount: amount,
    amountMode: mode,
    walletId: 'bca',
    toWalletId: kind == RecurringKind.transfer ? 'tabungan' : null,
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, day)),
    budgetItemKey: budgetItemKey,
  );

  final rules = [
    rule('Kos', 190000000, 1),
    rule('Netflix', 6500000, 1),
    rule('Listrik', 20000000, 5, mode: RecurringAmountMode.estimated),
    rule('Cicilan', 291400000, 10),
    rule('Gaji', 1200000000, 25, kind: RecurringKind.income),
    rule('Tabungan', 100000000, 26, kind: RecurringKind.transfer),
    rule('Sabil', 80000000, 28),
  ];

  ExpenseTransaction kos(int amount) => ExpenseTransaction(
    id: 'kos',
    date: DateTime(2026, 10, 1, 8),
    amount: amount,
    note: 'Kos',
    walletId: 'bca',
    recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10)),
  );

  final belanja = ExpenseTransaction(
    id: 'belanja',
    date: DateTime(2026, 10, 1, 19),
    amount: 36850000,
    note: 'Belanja',
    walletId: 'bca',
    budgetItemId: 'bulanan',
  );
  final jajan = ExpenseTransaction(
    id: 'jajan',
    date: DateTime(2026, 10, 2, 8),
    amount: 5700000,
    note: '',
    walletId: 'bca',
  );
  const budget = (itemId: 'bulanan', planned: 306850000, spent: 36850000);

  MonthPlan plan(
    List<Transaction> transactions, {
    List<RecurringRule>? with_,
    List<BudgetPlanLine> lines = const [budget],
  }) => monthPlan(
    with_ ?? rules,
    from: from,
    until: until,
    today: today,
    transactions: transactions,
    budgetLines: lines,
  );

  test('§7.6: uang nganggur rencana 3.052.500; §7.2a: sisa 2.995.500 sesudah Rp57.000 di luar rencana', () {
    final result = plan([kos(190000000), belanja, jajan]);
    expect(result.plannedIncome, 1200000000);
    expect(result.plannedRecurringOut, 587900000);
    expect(result.recordedRecurringOut, 190000000);
    expect(result.budgetPlanned, 306850000);
    expect(result.planned, 305250000);
    expect(result.unplannedOut, 5700000);
    expect(result.remaining, 299550000);
    expect(result.moved, 100000000);
    expect(result.hasEstimate, isTrue);
  });

  test('transfer rutin ke Tabungan tidak mengurangi uang nganggur (KT-R14)', () {
    final without = plan(
      const [],
      with_: [
        for (final r in rules)
          if (r.kind != RecurringKind.transfer) r,
      ],
    );
    expect(plan(const []).planned, without.planned);
  });

  test('rutin tertaut pos anggaran tidak dihitung dua kali (invarian 17)', () {
    final withKos = [...rules.where((r) => r.id != 'Kos'), rule('Kos', 190000000, 1, budgetItemKey: 'kos')];
    final result = plan(const [], with_: withKos, lines: [budget, (itemId: 'kos', planned: 200000000, spent: 0)]);
    expect(result.plannedRecurringOut, 587900000 - 190000000);
    expect(result.budgetPlanned, 306850000 + 200000000);
  });

  test('selisih rutin, kelebihan pos, dan pemasukan di luar rencana ikut ke sisa', () {
    final bonus = IncomeTransaction(
      id: 'bonus',
      date: DateTime(2026, 10, 2),
      amount: 50000000,
      note: '',
      walletId: 'bca',
    );
    final result = plan(
      [kos(195000000), bonus],
      lines: [(itemId: 'bulanan', planned: 306850000, spent: 316850000)],
    );
    expect(result.recurringDifference, -5000000);
    expect(result.budgetOverrun, 10000000);
    expect(result.unplannedIn, 50000000);
    expect(result.remaining, 305250000 - 5000000 - 10000000 + 50000000);
  });

  test('transaksi yang rutinnya dihapus dihitung di luar rencana (T-15.18)', () {
    final result = plan([kos(190000000)], with_: [...rules.where((r) => r.id != 'Kos')]);
    expect(result.plannedRecurringOut, 587900000 - 190000000);
    expect(result.unplannedOut, 190000000);
  });
}
