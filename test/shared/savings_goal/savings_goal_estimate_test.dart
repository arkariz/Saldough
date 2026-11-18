import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Perkiraan tanggal tercapai (ADR-048 §3.6, §3.7, T-30.7). Periode keuangan
/// mulai tanggal 1; hari ini 18 Nov 2026, jadi periode lengkap terakhir
/// Agu, Sep, Okt.
void main() {
  final schedule = FinancialMonthSchedule.initial;
  final today = DateTime(2026, 11, 18);
  const goalWallet = 'goal-1';

  SavingsGoal goal({DateTime? createdAt, DateTime? targetDate}) => SavingsGoal(
    id: '1',
    name: 'Dana darurat',
    targetAmount: 10000000,
    iconKey: 'goalShield',
    walletId: goalWallet,
    createdAt: createdAt ?? DateTime(2026, 7),
    targetDate: targetDate,
  );

  var seq = 0;
  Transaction into(DateTime date, int amount, {String from = 'bank', String to = goalWallet}) =>
      TransferTransaction(id: 't${seq++}', date: date, amount: amount, note: '', fromWalletId: from, toWalletId: to);

  SavingsGoalEstimate estimate(
    List<Transaction> txs, {
    SavingsGoal? g,
    int remaining = 1000000,
    int? idle,
  }) => SavingsGoalEstimate.of(
    goal: g ?? goal(),
    remaining: remaining,
    transactions: txs,
    schedule: schedule,
    today: today,
    idleAverage: idle,
  );

  test('tujuan yang belum melewati satu periode lengkap belum bisa diperkirakan', () {
    final e = estimate([into(DateTime(2026, 11, 6), 500000)], g: goal(createdAt: DateTime(2026, 11, 5)));
    expect(e.rate, isNull);
    expect(e.rateDate, isNull);
    expect(e.blocker, GoalEstimateBlocker.notEnoughHistory);
  });

  test('rata-rata 3 periode lengkap; tanggal = awal periode berjalan + ceil(sisa ÷ laju) periode', () {
    final e = estimate([
      into(DateTime(2026, 8, 3), 300000),
      into(DateTime(2026, 9, 3), 300000),
      into(DateTime(2026, 10, 3), 300000),
      // Periode berjalan tidak ikut rata-rata.
      into(DateTime(2026, 11, 3), 900000),
    ]);
    expect(e.rate, 300000);
    // ceil(1.000.000 ÷ 300.000) = 4 periode sesudah Nov → 1 Mar 2027.
    expect(e.rateDate, DateTime(2027, 3));
    expect(e.blocker, isNull);
  });

  test('transfer keluar mengurangi; penyesuaian saldo dan dompet lain diabaikan', () {
    final e = estimate([
      into(DateTime(2026, 10, 2), 600000),
      into(DateTime(2026, 10, 9), 300000, from: goalWallet, to: 'bank'),
      BalanceAdjustmentTransaction(
        id: 'adj',
        date: DateTime(2026, 10, 10),
        amount: 5000000,
        note: '',
        walletId: goalWallet,
        direction: AdjustmentDirection.increase,
      ),
      into(DateTime(2026, 10, 11), 700000, to: 'cash'),
    ]);
    expect(e.rate, 100000);
  });

  test('riwayat pendek dibagi periode yang sudah dijalani, bukan 3', () {
    final e = estimate([
      into(DateTime(2026, 9, 20), 200000),
      into(DateTime(2026, 10, 20), 200000),
    ], g: goal(createdAt: DateTime(2026, 9, 15)));
    expect(e.rate, 200000);
  });

  test('rata-rata ≤ 0: belum bisa; skenario uang nganggur tetap dihitung dari nol', () {
    final e = estimate([into(DateTime(2026, 10, 2), 100000, from: goalWallet, to: 'bank')], idle: 500000);
    expect(e.rate, isNull);
    expect(e.blocker, GoalEstimateBlocker.notSaving);
    expect(e.idleRate, 500000);
    expect(e.idleDate, DateTime(2027));
  });

  test('skenario uang nganggur ditambahkan ke laju; disembunyikan bila ≤ 0', () {
    final txs = [into(DateTime(2026, 10, 2), 300000)];
    final withIdle = estimate(txs, idle: 400000);
    expect(withIdle.idleRate, 100000 + 400000);
    expect(withIdle.idleDate, DateTime(2027));
    expect(estimate(txs, idle: 0).idleDate, isNull);
    expect(estimate(txs, idle: -50000).idleDate, isNull);
    expect(estimate(txs).idleDate, isNull);
  });

  test('melewati target tanggal hanya bila perkiraan laju sesudah target', () {
    final txs = [for (final m in [8, 9, 10]) into(DateTime(2026, m, 3), 300000)];
    expect(estimate(txs, g: goal(targetDate: DateTime(2026, 12, 31))).beyondTarget, isTrue);
    expect(estimate(txs, g: goal(targetDate: DateTime(2027, 12, 31))).beyondTarget, isFalse);
    expect(estimate(txs).beyondTarget, isFalse);
    // Tanpa perkiraan laju, tidak ada peringatan.
    expect(estimate(const [], g: goal(targetDate: DateTime(2026, 12))).beyondTarget, isFalse);
  });
}
