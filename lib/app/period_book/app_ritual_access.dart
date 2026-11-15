import 'package:flutter/widgets.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/app/shell/shell_requests.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/features/period_book/domain/entities/ritual_info.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_source.dart';
import 'package:saldough/features/period_book/domain/services/period_book_access.dart';
import 'package:saldough/features/period_book/domain/services/ritual_progress.dart';
import 'package:saldough/features/period_book/presentation/period_book_ritual_access.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// [PeriodBookRitualAccess] di akar komposisi (ADR-045, ADR-030): gerbang Plus
/// dicek **di sini**, bukan hanya di UI (BP-10); penyunting transaksi dibuka
/// lewat kunci rute CATAT; pindah ke Rutin lewat [ShellRequests].
final class AppRitualAccess implements PeriodBookRitualAccess {
  /// Membuat [AppRitualAccess].
  const AppRitualAccess({
    required this._gate,
    required this._source,
    required this._transactions,
    required this._wallets,
    required this._shell,
  });

  final PeriodBookGate _gate;
  final PeriodBookSource _source;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final ShellRequests _shell;

  @override
  Future<RitualLoad> load(String periodId) async {
    final closed = (await _gate.closedPeriods()).where((c) => c.id == periodId).firstOrNull;
    if (closed == null) return const RitualFailed();
    if (await _gate.accessOf(periodId) == BookAccess.locked) return const RitualLocked();
    final info = await _source.ritualFor(closed);
    final memory = await _gate.memory();
    return info.fold(
      (_) => const RitualFailed(),
      (value) => RitualReady(info: value, resume: ritualResumeStep(memory, periodId)),
    );
  }

  @override
  Future<void> markStepDone(String periodId, RitualStep step) async {
    await _gate.markStepDone(periodId, step.index);
  }

  @override
  Future<void> finish(String periodId) async {
    // Gerbang dicek lagi: jangan menandai dibuka bila terkunci (BP-10).
    if (await _gate.accessOf(periodId) == BookAccess.open) await _gate.markOpened(periodId);
  }

  @override
  Future<void> categorize(BuildContext context, String transactionId) async {
    final all = (await _transactions.listAllTransactions()).getOrElse((_) => const []);
    final transaction = all.where((t) => t.id == transactionId).firstOrNull;
    if (transaction == null || !context.mounted) return;
    final wallets = (await _wallets.listWallets()).getOrElse((_) => const []);
    if (!context.mounted) return;
    await context.pushRoute(RecordRouteKeys.edit, RecordEditInput(transaction: transaction, wallets: wallets));
  }

  @override
  void showRecurring(BuildContext context) {
    Navigator.of(context).pop(false);
    _shell.send(ShellRequest.showPlanRecurring);
  }
}
