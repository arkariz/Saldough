// Port satu anggota (pola port kecil ADR-0009).
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/savings_goal/domain/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Banyaknya periode keuangan lengkap terakhir yang dirata-rata (ADR-048 §3.6).
const goalEstimatePeriods = 3;

/// Rata-rata uang nganggur (`MonthPlan.remaining`) pada periode keuangan
/// lengkap terakhir, untuk baris skenario perkiraan tujuan (ADR-048 §3.6
/// butir 2). Dihitung `features/plan`, dipasang akar komposisi (ADR-030).
abstract interface class IdleMoneyAverage {
  /// Rata-rata sen per periode atas paling banyak [goalEstimatePeriods]
  /// periode lengkap sebelum periode [today]; periode sebelum catatan pertama
  /// tidak dihitung. `null` bila belum ada periode lengkap yang tercatat.
  Future<Either<Failure, int?>> averageBefore(DateTime today);
}

/// Mengapa baris "Dengan laju sekarang" belum bisa diperkirakan.
enum GoalEstimateBlocker {
  /// Tujuan belum melewati satu periode keuangan lengkap.
  notEnoughHistory,

  /// Rata-rata uang masuk ke dompet tujuan ≤ 0.
  notSaving,
}

/// Perkiraan tanggal tercapai satu tujuan (ADR-048 §3.6, §3.7). Semua nominal
/// dalam sen per periode keuangan; tanggal = awal periode saat tujuan
/// diperkirakan tercapai. Perkiraan, bukan janji.
final class SavingsGoalEstimate extends Equatable {
  /// Membuat [SavingsGoalEstimate].
  const SavingsGoalEstimate({
    this.rate,
    this.rateDate,
    this.blocker,
    this.idleRate,
    this.idleDate,
    this.beyondTarget = false,
  });

  /// Menghitung perkiraan [goal] yang masih kurang [remaining] sen, dari
  /// [transactions] (semua catatan; yang tidak menyentuh dompet tujuan
  /// diabaikan) pada periode [schedule] sebelum periode [today].
  /// [idleAverage] = rata-rata uang nganggur dari [IdleMoneyAverage].
  factory SavingsGoalEstimate.of({
    required SavingsGoal goal,
    required int remaining,
    required Iterable<Transaction> transactions,
    required FinancialMonthSchedule schedule,
    required DateTime today,
    int? idleAverage,
  }) {
    final current = schedule.periodOf(today);
    // Periode lengkap terakhir yang sudah dijalani tujuan (berakhir sesudah
    // tujuan dibuat). Tujuan baru tidak dibagi 3 periode kosong.
    final periods = <FinancialPeriod>[];
    var period = current;
    for (var back = 0; back < goalEstimatePeriods; back++) {
      period = schedule.previousOf(period);
      if (!period.end.isAfter(goal.createdAt)) break;
      periods.add(period);
    }

    int? rate;
    GoalEstimateBlocker? blocker;
    if (periods.isEmpty) {
      blocker = GoalEstimateBlocker.notEnoughHistory;
    } else {
      var net = 0;
      for (final tx in transactions) {
        final date = periodDateOf(tx);
        if (!periods.any((p) => p.contains(date))) continue;
        net += netOfGoalWallet(tx, goal.walletId);
      }
      final average = net ~/ periods.length;
      if (average <= 0) {
        blocker = GoalEstimateBlocker.notSaving;
      } else {
        rate = average;
      }
    }

    DateTime? reachDate(int perPeriod) {
      var target = current;
      for (var k = 0; k < (remaining + perPeriod - 1) ~/ perPeriod; k++) {
        target = schedule.nextOf(target);
      }
      return target.start;
    }

    final rateDate = rate == null ? null : reachDate(rate);
    // Skenario: uang nganggur ditambahkan ke laju nyata (yang tidak pernah
    // dianggap negatif); disembunyikan bila uang nganggur ≤ 0.
    final idleRate = idleAverage != null && idleAverage > 0 ? (rate ?? 0) + idleAverage : null;
    final targetDate = goal.targetDate;
    return SavingsGoalEstimate(
      rate: rate,
      rateDate: rateDate,
      blocker: blocker,
      idleRate: idleRate,
      idleDate: idleRate == null ? null : reachDate(idleRate),
      beyondTarget: targetDate != null && rateDate != null && rateDate.isAfter(targetDate),
    );
  }

  /// Rata-rata uang masuk bersih ke dompet tujuan per periode, atau `null`.
  final int? rate;

  /// Awal periode saat tujuan diperkirakan tercapai dengan [rate].
  final DateTime? rateDate;

  /// Alasan [rate] kosong.
  final GoalEstimateBlocker? blocker;

  /// [rate] ditambah rata-rata uang nganggur, atau `null` bila uang nganggur
  /// ≤ 0 atau belum diketahui.
  final int? idleRate;

  /// Awal periode saat tujuan diperkirakan tercapai dengan [idleRate].
  final DateTime? idleDate;

  /// Perkiraan dengan laju sekarang melewati target tanggal tujuan (§3.7).
  final bool beyondTarget;

  @override
  List<Object?> get props => [rate, rateDate, blocker, idleRate, idleDate, beyondTarget];
}

/// Uang bersih yang masuk ke dompet [walletId] lewat [tx]: pemasukan dan
/// transfer masuk menambah, pengeluaran dan transfer keluar mengurangi.
/// Penyesuaian saldo tidak dihitung: koreksi bukan laju menabung (§3.6).
int netOfGoalWallet(Transaction tx, String walletId) => switch (tx) {
  IncomeTransaction(walletId: final w) => w == walletId ? tx.amount : 0,
  ExpenseTransaction(walletId: final w) => w == walletId ? -tx.amount : 0,
  TransferTransaction(:final fromWalletId, :final toWalletId) =>
    (toWalletId == walletId ? tx.amount : 0) - (fromWalletId == walletId ? tx.amount : 0),
  BalanceAdjustmentTransaction() || InvestmentTransaction() => 0,
};
