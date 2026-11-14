import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/app/milestone/inbox_clear_tracker.dart';
import 'package:saldough/app/milestone/milestone_fact_rules.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// [MilestoneFactsSource] yang membaca dompet, transaksi, rutin, jadwal periode,
/// status cadangan, dan penanda kotak masuk (ADR-046 §3.1). Hanya membaca;
/// satu kegagalan membaca membuat seluruh evaluasi ditunda (G-5).
final class AppMilestoneFactsSource implements MilestoneFactsSource {
  /// Membuat [AppMilestoneFactsSource].
  const AppMilestoneFactsSource({
    required this._wallets,
    required this._transactions,
    required this._rules,
    required this._schedule,
    required this._backup,
    required this._inbox,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final RecurringRuleRepository _rules;
  final FinancialMonthPreferenceRepository _schedule;
  final BackupGateway _backup;
  final InboxClearTracker _inbox;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, Set<MilestoneFact>>> read() async {
    final wallets = await _wallets.listWallets();
    final transactions = await _transactions.listAllTransactions();
    final rules = await _rules.listRules();
    final schedule = await _schedule.load();
    final backupAt = await _backup.lastBackupAt();
    final inboxCleared = await _inbox.isCleared();

    return wallets.flatMap(
      (w) => transactions.flatMap(
        (t) => rules.flatMap(
          (r) => schedule.flatMap(
            (s) => backupAt.map(
              (at) => milestoneFactsFrom(
                wallets: w,
                transactions: t,
                rules: r,
                schedule: s,
                today: _now(),
                backupDone: at != null,
                inboxCleared: inboxCleared,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
