import 'dart:async';

import 'package:dependencies/dependencies.dart' show Left, Right;
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/domain/reminder_plan.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/features/recurring/domain/sync_recurring_reminders.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pengingat rutin di shell (ADR-035 §3.8, T-15.8): menyusun ulang jadwal
/// saat aplikasi dibuka, kembali ke depan, dan tiap rutin atau buku besar
/// berubah; menangani ketukan notifikasi.
///
/// Aksi **Catat** membuka aplikasi lalu mencatat satu ketuk lewat
/// `RecordTransaction` dengan Batalkan (rutin bernominal tetap), atau
/// membuka CATAT untuk nominal kira-kira. Tidak ada pencatatan di latar.
/// Kemunculan yang sudah tercatat ditolak invarian 15, jadi ketukan ganda
/// tidak menggandakan transaksi.
class RecurringReminderHost extends StatefulWidget {
  /// Membuat [RecurringReminderHost].
  const RecurringReminderHost({
    required this.container,
    required this.onShowRecurring,
    required this.child,
    super.key,
  });

  /// Kontainer akar.
  final GetIt container;

  /// Membuka tab Rencana › Rutin.
  final VoidCallback onShowRecurring;

  /// Isi shell.
  final Widget child;

  @override
  State<RecurringReminderHost> createState() => _RecurringReminderHostState();
}

class _RecurringReminderHostState extends State<RecurringReminderHost> with WidgetsBindingObserver {
  ReminderScheduler? _scheduler;
  late SyncRecurringReminders _sync;
  late RecordTransaction _record;
  late RecurringRuleRepository _rules;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduler != null) return;
    final c = widget.container;
    if (!c.isRegistered<ReminderScheduler>() || !c.isRegistered<ReminderSettingsRepository>()) return;
    final scheduler = _scheduler = c<ReminderScheduler>();
    _rules = c<RecurringRuleRepository>();
    _sync = SyncRecurringReminders(
      scheduler: scheduler,
      settings: c<ReminderSettingsRepository>(),
      rules: _rules,
      transactions: c<TransactionRepository>(),
    );
    _record = RecordTransaction(
      ledgerChanges: c<LedgerChanges>(),
      transactionRepository: c<TransactionRepository>(),
      recomputeWalletBalances: RecomputeWalletBalances(
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
      ),
    );
    _subscriptions
      ..add(scheduler.responses.listen((response) => unawaited(_handle(response))))
      ..add(c<RecurringChanges>().changes.listen((_) => _scheduleSync()))
      ..add(c<LedgerChanges>().changes.listen((_) => _scheduleSync()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  Future<void> _start() async {
    final launch = await _scheduler!.initialize();
    await _sync();
    if (launch != null) await _handle(launch);
  }

  /// Perubahan beruntun (catat semua, sunting) cukup disusun sekali.
  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => unawaited(_sync()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _scheduler != null) unawaited(_sync());
  }

  Future<void> _handle(ReminderResponse response) async {
    if (!mounted) return;
    widget.onShowRecurring();
    final target = parseReminderPayload(response.payload);
    if (!response.recordAction || target == null) return;
    final rules = (await _rules.listRules()).getOrElse((_) => const []);
    final rule = rules.where((r) => r.id == target.ruleId).firstOrNull;
    if (rule == null || !mounted) return;
    if (rule.amountMode == RecurringAmountMode.estimated) {
      await context.pushRoute(
        RecordRouteKeys.sheet,
        RecordSheetInput(occurrenceRule: rule, occurrenceDate: target.date),
      );
      return;
    }
    final c = widget.container;
    final options = c.isRegistered<BudgetItemCatalog>()
        ? (await c<BudgetItemCatalog>().listOptions()).getOrElse((_) => const [])
        : const <BudgetItemOption>[];
    if (!mounted) return;
    final transaction = transactionForOccurrence(
      rule,
      target.date,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      now: DateTime.now(),
      budgetItemId: budgetItemForOccurrence(rule, target.date, options),
    );
    final result = await _record(transaction);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final record = _record;
    messenger.showSnackBar(
      switch (result) {
        Left() => SnackBar(content: Text(t.recurring.alreadyRecordedMessage(name: rule.note))),
        Right() => actionSnackBar(
          context,
          content: Text(t.recurring.recordedMessage(name: rule.note)),
          action: SnackBarAction(
            label: t.recurring.undoAction,
            onPressed: () => unawaited(record.delete(transaction)),
          ),
        ),
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
