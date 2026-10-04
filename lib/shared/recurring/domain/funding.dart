import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/cashflow_projection.dart';
import 'package:saldough/shared/recurring/domain/occurrence_status.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Peringatan **siapkan dana** (W1, E3; ADR-036 §3.6): perkiraan saldo dompet
/// pada awal hari kemunculan autodebet kurang dari nominalnya. Kalimatnya
/// menyarankan tindakan di luar aplikasi, tidak pernah "transfer sekarang".
final class FundingWarning extends Equatable {
  /// Membuat [FundingWarning].
  const FundingWarning({
    required this.rule,
    required this.date,
    required this.walletId,
    required this.walletName,
    required this.balance,
  });

  /// Rutin autodebetnya.
  final RecurringRule rule;

  /// Tanggal kemunculan.
  final DateTime date;

  /// Dompet yang didebet.
  final String walletId;

  /// Nama dompet, untuk kalimat dan notifikasi.
  final String walletName;

  /// Perkiraan saldo dompet pada awal hari itu.
  final int balance;

  /// Kekurangan: nominal − perkiraan saldo, selalu positif.
  int get shortfall => rule.amount - balance;

  @override
  List<Object?> get props => [rule.id, date, walletId, walletName, balance];
}

/// Hari terjauh sebelum kemunculan autodebet yang diperingatkan (H−3).
const fundingLookaheadDays = 3;

/// Peringatan siapkan dana per [today] (ADR-036 §3.6): kemunculan rutin
/// **autodebet** pengeluaran atau transfer yang belum tercatat atau dilewati
/// pada H−3 sampai H0, bila [projectionOf] dompetnya memperkirakan saldo awal
/// hari itu kurang dari nominalnya. Urut tanggal.
List<FundingWarning> fundingWarnings(
  Iterable<RecurringRule> rules, {
  required DateTime today,
  required Iterable<Transaction> transactions,
  required CashflowProjection Function(String walletId) projectionOf,
  required String Function(String walletId) walletName,
}) {
  final start = DateTime(today.year, today.month, today.day);
  final until = DateTime(start.year, start.month, start.day + fundingLookaheadDays + 1);
  final projections = <String, CashflowProjection>{};
  final warnings = <FundingWarning>[];
  for (final rule in rules) {
    if (rule.isPaused || rule.kind == RecurringKind.income) continue;
    if (rule.effectivePaymentMode != RecurringPaymentMode.autoDebit) continue;
    for (final o in occurrenceStatusesOf(rule, from: start, until: until, today: start, transactions: transactions)) {
      if (o.status != OccurrenceStatus.pending && o.status != OccurrenceStatus.upcoming) continue;
      final projection = projections[rule.walletId] ??= projectionOf(rule.walletId);
      final previous = DateTime(o.date.year, o.date.month, o.date.day - 1);
      final balance = o.date.isAfter(start)
          ? projection.days.where((d) => d.date == previous).firstOrNull?.balance ?? projection.startBalance
          : projection.startBalance;
      if (balance >= rule.amount) continue;
      warnings.add(
        FundingWarning(
          rule: rule,
          date: o.date,
          walletId: rule.walletId,
          walletName: walletName(rule.walletId),
          balance: balance,
        ),
      );
    }
  }
  return warnings..sort((a, b) => a.date.compareTo(b.date));
}
