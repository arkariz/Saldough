import 'dart:async';

import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// **Catat otomatis** rutin bernominal tetap (ADR-037 §3.2): berjalan saat
/// aplikasi dibuka dan saat tanggal berganti, bukan di latar. Mencatat lewat
/// `RecordTransaction` (satu jalur tulis), menulis log, lalu menawarkan
/// **Batalkan** di snackbar. Kemunculan yang dibatalkan tidak dicatat lagi.
class AutoRecordHost extends StatefulWidget {
  /// Membuat [AutoRecordHost].
  const AutoRecordHost({required this.container, required this.child, super.key});

  /// Kontainer akar.
  final GetIt container;

  /// Isi shell.
  final Widget child;

  @override
  State<AutoRecordHost> createState() => _AutoRecordHostState();
}

class _AutoRecordHostState extends State<AutoRecordHost> {
  AutoRecordLogRepository? _log;
  late final RecurringRuleRepository _rules;
  late final TransactionRepository _transactions;
  late final RecordTransaction _record;
  var _running = false;
  var _sequence = 0;

  @override
  void initState() {
    super.initState();
    final c = widget.container;
    // Kontainer tanpa log (sebagian uji shell): tidak ada yang dicatat.
    if (!c.isRegistered<AutoRecordLogRepository>()) return;
    _log = c<AutoRecordLogRepository>();
    _rules = c<RecurringRuleRepository>();
    _transactions = c<TransactionRepository>();
    _record = RecordTransaction(
      ledgerChanges: c<LedgerChanges>(),
      transactionRepository: _transactions,
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: c<WalletRepository>(),
        transactionRepository: _transactions,
      ),
    );
    ActiveDay.notifier.addListener(_run);
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _run() => unawaited(_recordDue());

  Future<void> _recordDue() async {
    final log = _log;
    if (_running || log == null) return;
    _running = true;
    try {
      final now = DateTime.now();
      final windowStart = DateTime(now.year, now.month - 1);
      final rules = switch (await _rules.listRules()) {
        Right(:final value) => value,
        Left() => null,
      };
      final entries = switch (await log.list(now)) {
        Right(:final value) => value,
        Left() => null,
      };
      if (rules == null || entries == null || !rules.any((r) => r.autoRecord)) return;
      final transactions = <Transaction>[];
      for (final month in [windowStart, DateTime(now.year, now.month)]) {
        switch (await _transactions.listTransactionsInMonth(month)) {
          case Right(:final value):
            transactions.addAll(value);
          case Left():
            return;
        }
      }
      final due = dueAutoRecords(
        rules,
        windowStart: windowStart,
        today: now,
        transactions: transactions,
        logged: {for (final e in entries) (e.ruleId, e.occurrenceDate)},
      );
      final recorded = <(AutoRecordEntry, Transaction)>[];
      for (final (rule, date) in due) {
        final transaction = transactionForOccurrence(
          rule,
          date,
          id: 'auto-${now.microsecondsSinceEpoch}-${_sequence++}',
          now: now,
        );
        if ((await _record(transaction, source: this)).isLeft()) break;
        recorded.add((
          AutoRecordEntry(
            transactionId: transaction.id,
            ruleId: rule.id,
            ruleName: rule.note,
            occurrenceDate: date,
            recordedAt: now,
          ),
          transaction,
        ));
      }
      if (recorded.isEmpty) return;
      await log.add([for (final (entry, _) in recorded) entry]);
      AppAnalytics.log(PlanEvents.autoRecorded(recorded.length));
      if (mounted) _announce(recorded);
    } finally {
      _running = false;
    }
  }

  void _announce(List<(AutoRecordEntry, Transaction)> recorded) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final message = recorded.length == 1
        ? t.recurring.autoRecordedOne(name: recorded.single.$1.ruleName)
        : t.recurring.autoRecordedMany(n: recorded.length);
    messenger.showSnackBar(
      actionSnackBar(
        context,
        content: Text(message),
        action: SnackBarAction(
          label: t.recurring.undoAction,
          onPressed: () => unawaited(_undo(recorded)),
        ),
      ),
    );
  }

  Future<void> _undo(List<(AutoRecordEntry, Transaction)> recorded) async {
    for (final (entry, transaction) in recorded) {
      if ((await _record.delete(transaction, source: this)).isLeft()) return;
      await _log?.markUndone(entry.transactionId);
    }
    AppAnalytics.log(PlanEvents.autoRecordUndone);
  }

  @override
  void dispose() {
    if (_log != null) ActiveDay.notifier.removeListener(_run);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
