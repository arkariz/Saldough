import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Contoh RECURRING_AND_FORECAST §7.6 dan kasus wajib §7.7 (sen).
void main() {
  final today = DateTime(2026, 10, 2, 9);
  final from = DateTime(2026, 10);
  final until = DateTime(2026, 11);

  RecurringRule rule(String id, int amount, int day, {RecurringKind kind = RecurringKind.expense}) => RecurringRule(
    id: id,
    kind: kind,
    amount: amount,
    amountMode: id == 'Listrik' ? RecurringAmountMode.estimated : RecurringAmountMode.fixed,
    walletId: 'bca',
    toWalletId: kind == RecurringKind.transfer ? 'tabungan' : null,
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, day)),
  );

  final rules = [
    rule('Kos', 190000000, 1),
    rule('Netflix', 6500000, 1),
    rule('Listrik', 20000000, 5),
    rule('Cicilan', 291400000, 10),
    rule('Gaji', 1200000000, 25, kind: RecurringKind.income),
    rule('Tabungan', 100000000, 26, kind: RecurringKind.transfer),
    rule('Sabil', 80000000, 28),
  ];
  final kosRecorded = ExpenseTransaction(
    id: 'kos',
    date: DateTime(2026, 10, 1, 8),
    amount: 190000000,
    note: 'Kos',
    walletId: 'bca',
    recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10)),
  );

  CashflowProjection project({String? walletId, int start = 650000000}) => projectCashflow(
    rules,
    startBalance: start,
    today: today,
    until: until,
    pendingFrom: from,
    transactions: [kosRecorded],
    budgets: [(walletId: 'bca', key: null, remaining: 270000000, periodEnd: until)],
    unplannedPerDay: walletId == null ? 3000000 : null,
    walletId: walletId,
  );

  test('§7.6: titik terendah Rp561.000 pada 24 Okt; akhir Okt Rp10.921.000', () {
    final result = project();
    expect(result.days.first.date, DateTime(2026, 10, 2));
    expect(result.days, hasLength(30));
    expect(result.lowest, (date: DateTime(2026, 10, 24), balance: 56100000));
    expect(result.endBalance, 1092100000);
    final b = result.breakdown;
    expect(b, (
      income: 1200000000,
      recurringOut: 397900000,
      budget: 270000000,
      unplanned: 90000000,
      uncertain: 0,
      transfers: 0,
    ));
    expect(
      result.startBalance + b.income - b.recurringOut - b.budget - b.unplanned + b.uncertain + b.transfers,
      result.endBalance,
    );
  });

  test('§7.2a: akhir bulan = saldo awal bulan + sisa uang nganggur − di luar rencana sisa bulan', () {
    // Saldo awal Okt 8.825.500 (sebelum Kos, belanja, dan Rp57.000 di luar rencana).
    const startOfMonth = 882550000;
    const remaining = 299550000;
    expect(project().endBalance, startOfMonth + remaining - 30 * 3000000);
  });

  test('transfer rutin tidak mengubah total; per dompet BCA turun, Tabungan naik (invarian 16)', () {
    final withoutTransfer = projectCashflow(
      [
        for (final r in rules)
          if (r.kind != RecurringKind.transfer) r,
      ],
      startBalance: 650000000,
      today: today,
      until: until,
      pendingFrom: from,
      transactions: [kosRecorded],
    );
    final total = projectCashflow(
      rules,
      startBalance: 650000000,
      today: today,
      until: until,
      pendingFrom: from,
      transactions: [kosRecorded],
    );
    expect(total.days, withoutTransfer.days);

    final savings = projectCashflow(
      rules,
      startBalance: 0,
      today: today,
      until: until,
      pendingFrom: from,
      transactions: [kosRecorded],
      walletId: 'tabungan',
    );
    expect(savings.days.firstWhere((d) => d.date == DateTime(2026, 10, 26)).balance, 100000000);
    expect(savings.days.firstWhere((d) => d.date == DateTime(2026, 10, 25)).balance, 0);
  });

  test('pembagian harian persis: 100.000.001 sen ÷ 3 hari (§7.7)', () {
    expect(dailyPortions(100000001, 3), [33333333, 33333333, 33333335]);
    final result = projectCashflow(
      const [],
      startBalance: 100000001,
      today: DateTime(2026, 10, 29),
      until: until,
      pendingFrom: from,
      transactions: const [],
      budgets: [(walletId: 'bca', key: null, remaining: 100000001, periodEnd: until)],
    );
    expect(result.days.map((d) => d.balance), [66666668, 33333335, 0]);
  });

  test('pemasukan belum pasti dihitung dan ditandai (KT-R6)', () {
    final result = projectCashflow(
      const [],
      startBalance: 0,
      today: today,
      until: until,
      pendingFrom: from,
      transactions: const [],
      uncertainIncome: [(walletId: 'bca', amount: 250000000, date: DateTime(2026, 10, 15))],
    );
    expect(result.uncertain, 250000000);
    expect(result.endBalance, 250000000);
  });

  test('di luar rencana: rata-rata bulan penuh, tanpa rutin dan pos; null bila belum sebulan penuh', () {
    final history = [
      ExpenseTransaction(id: 'a', date: DateTime(2026, 9, 3), amount: 60000000, note: '', walletId: 'bca'),
      ExpenseTransaction(id: 'b', date: DateTime(2026, 8, 20), amount: 33000000, note: '', walletId: 'bca'),
      ExpenseTransaction(
        id: 'pos',
        date: DateTime(2026, 9, 4),
        amount: 1,
        note: '',
        walletId: 'bca',
        budgetItemId: 'x',
      ),
      kosRecorded,
      ExpenseTransaction(
        id: 'kos-sep',
        date: DateTime(2026, 9, 1, 8),
        amount: 190000000,
        note: 'Kos',
        walletId: 'bca',
        recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 9)),
      ),
    ];
    final months = [
      (start: DateTime(2026, 9), end: DateTime(2026, 10)),
      (start: DateTime(2026, 8), end: DateTime(2026, 9)),
      (start: DateTime(2026, 7), end: DateTime(2026, 8)),
    ];
    // Riwayat mulai 1 Agu: Agu dan Sep penuh, Jul tidak (61 hari).
    expect(
      unplannedDailyAverage(history, months: months, historyStart: DateTime(2026, 8), ruleIds: {'Kos'}),
      (60000000 + 33000000) ~/ 61,
    );
    expect(
      unplannedDailyAverage(history, months: months, historyStart: DateTime(2026, 9, 3), ruleIds: {'Kos'}),
      isNull,
    );
    // Rutin Kos dihapus: transaksinya kini di luar rencana (T-15.18).
    expect(
      unplannedDailyAverage(history, months: months, historyStart: DateTime(2026, 8), ruleIds: const {}),
      (60000000 + 33000000 + 190000000) ~/ 61,
    );
  });

  test('§7.4: pos Kos sisa 2.000.000 dengan rutin tertaut 1.900.000 → keluar 2.000.000, bukan 3.900.000 (T-16.5)', () {
    RecurringRule kos({String? key}) => RecurringRule(
      id: 'kos-rutin',
      kind: RecurringKind.expense,
      amount: 190000000,
      walletId: 'bca',
      note: 'Kos',
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, 15)),
      budgetItemKey: key,
    );
    CashflowProjection run(String? key) => projectCashflow(
      [kos(key: key)],
      startBalance: 0,
      today: today,
      until: until,
      pendingFrom: from,
      transactions: const [],
      budgets: [(walletId: 'bca', key: 'kos', remaining: 200000000, periodEnd: until)],
    );
    expect(run('kos').endBalance, -200000000);
    expect(run('kos').days.firstWhere((d) => d.date == DateTime(2026, 10, 15)).balance, lessThan(-190000000));
    expect(run(null).endBalance, -390000000);
  });

  test('bulan depan berantai: saldo awal Nov = perkiraan akhir Okt, persis dalam sen (invarian 20)', () {
    final october = project();
    final november = projectCashflow(
      rules,
      startBalance: 650000000,
      today: today,
      until: DateTime(2026, 12),
      pendingFrom: from,
      transactions: [kosRecorded],
      budgets: [(walletId: 'bca', key: null, remaining: 270000000, periodEnd: until)],
      unplannedPerDay: 3000000,
      reportFrom: DateTime(2026, 11),
    );
    expect(november.startBalance, october.endBalance);
    expect(november.days.first.date, DateTime(2026, 11));
    expect(november.days, hasLength(30));
    final b = november.breakdown;
    expect(
      november.startBalance + b.income - b.recurringOut - b.budget - b.unplanned + b.uncertain + b.transfers,
      november.endBalance,
    );
  });
}
