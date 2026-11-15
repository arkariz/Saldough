import 'package:flutter/widgets.dart';
import 'package:saldough/app/period_book/period_book_gate.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/features/period_book/domain/repositories/period_book_source.dart';
import 'package:saldough/features/period_book/domain/services/period_book_access.dart';
import 'package:saldough/features/period_book/domain/services/period_stamps.dart';
import 'package:saldough/features/period_book/presentation/period_book_read_access.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// [PeriodBookReadAccess] di akar komposisi (ADR-045, ADR-030). Membuka buku =
/// gerbang dicek **di sini** (BP-10), buku ditandai dibuka, stempel periode
/// tercetak permanen ke sampul, dan perayaan stempel terpisah dilipat ke sampul
/// ([absorbStamps], BP-13).
final class AppBookAccess implements PeriodBookReadAccess {
  /// Membuat [AppBookAccess].
  const AppBookAccess({
    required this._gate,
    required this._source,
    required this._transactions,
    required this._wallets,
    required this._absorbStamps,
  });

  final PeriodBookGate _gate;
  final PeriodBookSource _source;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final void Function(Set<String> ids) _absorbStamps;

  static const List<String> _stampOrder = [periodStampTidy, periodStampRecurringClear];

  @override
  Future<BookLoad> open(String periodId) async {
    final closed = (await _gate.closedPeriods()).where((c) => c.id == periodId).firstOrNull;
    if (closed == null) return const BookFailed();
    if (await _gate.accessOf(periodId) == BookAccess.locked) return const BookLocked();
    final content = (await _source.contentFor(closed)).fold((_) => null, (value) => value);
    if (content == null) return const BookFailed();
    final printed = {...periodStampsOf(content), ...(await _gate.memory()).stampsOf(periodId)};
    await _gate.printStamps(periodId, printed);
    await _gate.markOpened(periodId);
    _absorbStamps(printed);
    return BookReady(content: content, stamps: [for (final id in _stampOrder) if (printed.contains(id)) id]);
  }

  @override
  Future<void> categorizeFirstUntagged(BuildContext context, String periodId) async {
    final closed = (await _gate.closedPeriods()).where((c) => c.id == periodId).firstOrNull;
    if (closed == null) return;
    final info = (await _source.ritualFor(closed)).fold((_) => null, (value) => value);
    final first = info?.untagged.firstOrNull;
    if (first == null || !context.mounted) return;
    final all = (await _transactions.listAllTransactions()).getOrElse((_) => const []);
    final transaction = all.where((t) => t.id == first.transactionId).firstOrNull;
    if (transaction == null || !context.mounted) return;
    final wallets = (await _wallets.listWallets()).getOrElse((_) => const []);
    if (!context.mounted) return;
    await context.pushRoute(RecordRouteKeys.edit, RecordEditInput(transaction: transaction, wallets: wallets));
  }
}
