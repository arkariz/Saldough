import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'recurring_event.dart';

/// Bloc segmen Rutin dan rincian rutin (T-15.5, PLAN_TAB_LAYOUT §6).
///
/// Membaca rutin, dompet, dan dokumen bulan transaksi dari [_monthsBack]
/// bulan lalu sampai bulan berjalan (ADR-012): segmen cukup bulan
/// sebelumnya (ADR-035 §3.2), rincian membaca setahun untuk riwayat.
///
/// ⚠ Tidak pernah menulis transaksi atau saldo: rutin adalah rencana
/// (invarian 14). Lewati, jeda, akhiri, ubah nominal, dan hapus hanya
/// menulis dokumen rutin.
final class RecurringBloc extends Bloc<RecurringEvent, RecurringState> {
  /// Membuat [RecurringBloc]. [now] bisa diganti di uji.
  RecurringBloc({
    required this._rules,
    required this._transactions,
    required this._wallets,
    required LedgerChanges ledgerChanges,
    required this._recurringChanges,
    required this._recordTransaction,
    this._monthsBack = 1,
    this._budgetItemCatalog,
    this._suggestionDismissals,
    this._autoRecordLog,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(RecurringState.initial(DateTime.now())) {
    on<RecurringStarted>((event, emit) => _load(emit, showSkeleton: true));
    on<RecurringRefreshed>((event, emit) => _load(emit, showSkeleton: false));
    on<RecurringKindFilterChanged>((event, emit) => emit(state.copyWith(kindFilter: () => event.kind)));
    on<RecurringOccurrenceSkipped>(_onSkipped);
    on<RecurringOccurrenceUnskipped>(_onUnskipped);
    on<RecurringPauseToggled>(_onPauseToggled);
    on<RecurringEnded>(_onEnded);
    on<RecurringAmountUpdated>(_onAmountUpdated);
    on<RecurringDeleted>(_onDeleted);
    on<RecurringOccurrenceRecorded>(_onRecorded);
    on<RecurringPendingRecordedAll>(_onRecordedAll);
    on<RecurringOccurrenceLinked>(_onLinked);
    on<RecurringBudgetLinkChanged>((event, emit) async {
      final rule = state.ruleOf(event.ruleId);
      if (rule == null) return;
      final linked = rule.withBudgetItemKey(event.key);
      final item = linkedBudgetItem(linked, state.budgetOptions);
      if (item != null) AppAnalytics.log(PlanEvents.recurringBudgetLinked('detail'));
      await _write(
        linked,
        emit,
        item == null
            ? t.recurring.budgetUnlinkedMessage(name: rule.note)
            : t.recurring.budgetLinkedMessage(name: rule.note, item: item.itemName),
      );
      if (item != null) await _chargeRecorded(linked);
    });
    on<RecurringAutoRecordUndone>((event, emit) async {
      final transaction = state.transactions.where((t) => t.id == event.entry.transactionId).firstOrNull;
      if (transaction != null) {
        if (await _recordTransaction.delete(transaction, source: this) case Left(value: final failure)) {
          emit(state.copyWith(effect: _effectError(failure)));
          return;
        }
      }
      await _autoRecordLog?.markUndone(event.entry.transactionId);
      AppAnalytics.log(PlanEvents.autoRecordUndone);
      await _load(emit, showSkeleton: false);
    });
    on<RecurringSuggestionDismissed>((event, emit) async {
      emit(state.copyWith(dismissedSuggestions: {...state.dismissedSuggestions, event.key}));
      await _suggestionDismissals?.add(event.key);
    });
    on<RecurringIdleDismissed>((event, emit) async {
      final rule = state.ruleOf(event.ruleId);
      if (rule == null) return;
      final today = state.today;
      await _write(
        rule.copyWith(idleDismissedAt: DateTime(today.year, today.month, today.day)),
        emit,
        null,
      );
    });
    on<RecurringOccurrenceSnoozed>((event, emit) async {
      final rule = state.ruleOf(event.ruleId);
      if (rule == null) return;
      final today = state.today;
      AppAnalytics.log(RecurringEvents.unseenNotYet);
      await _write(
        rule.copyWith(snoozedUntil: DateTime(today.year, today.month, today.day + unseenAfterDays)),
        emit,
        t.recurring.snoozedMessage(name: rule.note),
      );
    });
    on<RecurringAutoRecordToggled>((event, emit) async {
      final rule = state.ruleOf(event.ruleId);
      if (rule == null || rule.amountMode != RecurringAmountMode.fixed) return;
      AppAnalytics.log(RecurringEvents.autoRecordToggled(on: event.enabled, where: 'detail'));
      await _write(rule.copyWith(autoRecord: event.enabled), emit, null);
    });
    on<RecurringRemindersToggled>((event, emit) async {
      final rule = state.ruleOf(event.ruleId);
      if (rule != null) await _write(rule.copyWith(reminders: event.enabled), emit, null);
    });
    _subscriptions = [
      ledgerChanges.from(this).listen((_) => add(const RecurringRefreshed())),
      _recurringChanges.from(this).listen((_) => add(const RecurringRefreshed())),
    ];
    // Tanggal berganti saat aplikasi hidup di latar (T-15.17).
    ActiveDay.notifier.addListener(_onDayChanged);
  }

  final RecurringRuleRepository _rules;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final RecurringChanges _recurringChanges;
  final RecordTransaction _recordTransaction;
  final int _monthsBack;

  /// Pos anggaran untuk tautan rutin ke pos (ADR-036 §3.4); `null` = tanpa.
  final BudgetItemCatalog? _budgetItemCatalog;

  /// Saran "Sepertinya rutin" yang ditolak; `null` = tanpa (sebagian uji).
  final RecurringSuggestionDismissals? _suggestionDismissals;

  /// Log catat otomatis (ADR-037 §3.2); `null` = tanpa daftar.
  final AutoRecordLogRepository? _autoRecordLog;
  final DateTime Function() _now;
  late final List<StreamSubscription<void>> _subscriptions;

  DateTime get _today {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _load(Emitter<RecurringState> emit, {required bool showSkeleton}) async {
    if (showSkeleton) emit(state.copyWith(isLoading: true));
    final today = _today;
    final rules = await _rules.listRules();
    final wallets = await _wallets.listWallets();
    final transactions = <Transaction>[];
    var failure = switch ((rules, wallets)) {
      (Left(value: final f), _) || (_, Left(value: final f)) => f,
      _ => null,
    };
    for (var back = _monthsBack; back >= 0 && failure == null; back--) {
      switch (await _transactions.listTransactionsInMonth(DateTime(today.year, today.month - back))) {
        case Left(value: final f):
          failure = f;
        case Right(value: final month):
          transactions.addAll(month);
      }
    }
    if (failure != null) {
      emit(state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure)));
      return;
    }
    final options = await _budgetItemCatalog?.listOptions();
    final dismissed = await _suggestionDismissals?.load();
    final logged = await _autoRecordLog?.list(_now());
    emit(
      state.copyWith(
        rules: rules.getOrElse((_) => const []),
        wallets: wallets.getOrElse((_) => const []),
        budgetOptions: options?.getOrElse((_) => const []) ?? const [],
        dismissedSuggestions: dismissed?.getOrElse((_) => const {}) ?? const {},
        autoRecorded: [
          for (final e in logged?.getOrElse((_) => const []) ?? const <AutoRecordEntry>[])
            if (!e.undone && _now().difference(e.recordedAt) < const Duration(days: 7)) e,
        ],
        transactions: transactions,
        today: today,
        isLoading: false,
        loadFailed: false,
      ),
    );
  }

  /// Kemunculan [rule] yang sudah tercatat tanpa pos (mis. sebelum
  /// ditautkan) dibebankan ke pos periodenya, supaya rincian anggaran sama
  /// dengan Rencana (T-16.16 K4). Saldo tidak berubah.
  Future<void> _chargeRecorded(RecurringRule rule) async {
    for (final t in state.transactions) {
      if (t case ExpenseTransaction(budgetItemId: null, recurrence: final link?) when link.ruleId == rule.id) {
        final itemId = budgetItemForOccurrence(rule, link.occurrenceDate, state.budgetOptions);
        if (itemId == null) continue;
        await _recordTransaction(
          t.copyWith(budgetItemId: itemId),
          previousTransaction: t,
          source: this,
        );
      }
    }
  }

  Future<void> _onSkipped(RecurringOccurrenceSkipped event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null) return;
    final skipped = rule.copyWith(skippedDates: {...rule.skippedDates, event.date});
    AppAnalytics.log(RecurringEvents.occurrenceSkipped);
    final day = DateTime(event.date.year, event.date.month, event.date.day);
    await _write(skipped, emit, null);
    if (state.ruleOf(rule.id) != skipped) return;
    final repository = _rules;
    final changes = _recurringChanges;
    emit(
      state.copyWith(
        effect: _effectWithUndo(t.recurring.skippedMessage(date: CycleMonthFormatter.formatDayMonth(day)), () async {
          final current = (await repository.listRules()).getOrElse((_) => const []);
          for (final r in current) {
            if (r.id != rule.id) continue;
            final result = await repository.saveRule(r.copyWith(skippedDates: {...r.skippedDates}..remove(day)));
            if (result.isRight()) changes.notifyChanged();
            return result;
          }
          return right(unit);
        }),
      ),
    );
  }

  Future<void> _onUnskipped(RecurringOccurrenceUnskipped event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null) return;
    final day = DateTime(event.date.year, event.date.month, event.date.day);
    await _write(rule.copyWith(skippedDates: {...rule.skippedDates}..remove(day)), emit, null);
  }

  Future<void> _onPauseToggled(RecurringPauseToggled event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null) return;
    final paused = !rule.isPaused;
    await _write(
      rule.copyWith(isPaused: paused),
      emit,
      paused ? t.recurring.pausedMessage(name: rule.note) : t.recurring.resumedMessage(name: rule.note),
    );
  }

  /// Akhiri: kemunculan sesudah hari ini hilang; yang sudah tiba tetap.
  Future<void> _onEnded(RecurringEnded event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null) return;
    await _write(rule.copyWith(end: RecurringEndsOn(_today)), emit, t.recurring.endedMessage(name: rule.note));
  }

  /// W3 "Perbarui rutin": berlaku ke depan; transaksi lama tidak berubah.
  Future<void> _onAmountUpdated(RecurringAmountUpdated event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null || event.amount <= 0) return;
    await _write(rule.copyWith(amount: event.amount), emit, t.record.repeat.updatedMessage(name: rule.note));
  }

  Future<void> _onDeleted(RecurringDeleted event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null) return;
    switch (await _rules.deleteRule(rule.id)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        _recurringChanges.notifyChanged(source: this);
        emit(
          state.copyWith(
            rules: [
              for (final r in state.rules)
                if (r.id != rule.id) r,
            ],
            effect: _effectDone(t.recurring.deletedMessage(name: rule.note)),
          ),
        );
    }
  }

  /// Kemunculan menunggu [ruleId] pada [date] dicatat satu ketuk (ADR-035
  /// §3.3, pengecualian kedua aturan 8): hanya rutin bernominal tetap; yang
  /// kira-kira selalu lewat CATAT. Bila ada transaksi mirip yang belum
  /// tertaut (E4), aplikasi bertanya dulu, kecuali [event.force].
  Future<void> _onRecorded(RecurringOccurrenceRecorded event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null || rule.amountMode != RecurringAmountMode.fixed) return;
    if (!event.force) {
      final similar = matchCandidates(rule, event.date, state.transactions);
      if (similar.isNotEmpty) {
        emit(state.copyWith(effect: _effectAskSimilar(rule, event.date, similar.first)));
        return;
      }
    }
    final transaction = transactionForOccurrence(
      rule,
      event.date,
      id: _newId(),
      now: _now(),
      budgetItemId: budgetItemForOccurrence(rule, event.date, state.budgetOptions),
    );
    switch (await _recordTransaction(transaction, source: this)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        AppAnalytics.log(RecurringEvents.occurrenceRecorded('one_tap'));
        emit(
          state.copyWith(
            transactions: [...state.transactions, transaction],
            effect: _effectRecordedWithUndo(t.recurring.recordedMessage(name: rule.note), [transaction]),
          ),
        );
    }
  }

  /// Catat semua: setiap kemunculan menunggu atau terlewat dari rutin
  /// bernominal tetap yang tidak punya transaksi mirip. Sisanya tetap
  /// menunggu untuk ditinjau satu per satu.
  Future<void> _onRecordedAll(RecurringPendingRecordedAll event, Emitter<RecurringState> emit) async {
    final today = state.today;
    final recorded = <Transaction>[];
    for (final rule in state.rules) {
      if (rule.isPaused || rule.amountMode != RecurringAmountMode.fixed) continue;
      final waiting = occurrenceStatusesOf(
        rule,
        from: DateTime(today.year, today.month - 1),
        until: DateTime(today.year, today.month, today.day + 1),
        today: today,
        transactions: [...state.transactions, ...recorded],
      ).where((o) => o.status == OccurrenceStatus.pending || o.status == OccurrenceStatus.missed);
      for (final o in waiting) {
        if (matchCandidates(rule, o.date, [...state.transactions, ...recorded]).isNotEmpty) continue;
        final transaction = transactionForOccurrence(
          rule,
          o.date,
          id: _newId(),
          now: _now(),
          budgetItemId: budgetItemForOccurrence(rule, o.date, state.budgetOptions),
        );
        switch (await _recordTransaction(transaction, source: this)) {
          case Left(value: final failure):
            emit(
              state.copyWith(
                transactions: [...state.transactions, ...recorded],
                effect: _effectError(failure),
              ),
            );
            return;
          case Right():
            recorded.add(transaction);
        }
      }
    }
    if (recorded.isEmpty) return;
    AppAnalytics.log(RecurringEvents.occurrenceRecorded('record_all', count: recorded.length));
    emit(
      state.copyWith(
        transactions: [...state.transactions, ...recorded],
        effect: _effectRecordedWithUndo(t.recurring.recordedAllMessage(n: recorded.length), recorded),
      ),
    );
  }

  /// "Sudah tercatat? Tautkan" (E4): menulis tautan ke transaksi yang sudah
  /// ada. Saldo tidak berubah.
  Future<void> _onLinked(RecurringOccurrenceLinked event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    final existing = [
      for (final t in state.transactions)
        if (t.id == event.transactionId) t,
    ];
    if (rule == null || existing.isEmpty) return;
    final source = existing.single;
    final linked = source.withRecurrence(RecurrenceLink(ruleId: rule.id, occurrenceDate: event.date));
    switch (await _recordTransaction(linked, previousTransaction: source, source: this)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        AppAnalytics.log(RecurringEvents.occurrenceLinked);
        emit(
          state.copyWith(
            transactions: [for (final t in state.transactions) t.id == source.id ? linked : t],
            effect: _effectDone(t.recurring.linkedMessage(name: rule.note)),
          ),
        );
    }
  }

  String _newId() => _now().microsecondsSinceEpoch.toString() + (_idSalt++).toString();
  int _idSalt = 0;

  /// Bertanya saat ada transaksi mirip (E4): tautkan yang sudah ada, catat
  /// baru, atau batal.
  UiEffect _effectAskSimilar(RecurringRule rule, DateTime date, Transaction similar) => CallbackEffect(
    callback: (context) async {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.recurring.similarTitle),
          content: Text(
            t.recurring.similarBody(
              name: similar.note.isEmpty ? rule.note : similar.note,
              amount: AppMoneyFormatter.format(similar.amount),
              date: CycleMonthFormatter.formatDayMonth(similar.date),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(t.common.cancel)),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.recurring.recordNewAction),
            ),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(t.recurring.linkAction)),
          ],
        ),
      );
      if (choice == null || isClosed) return;
      add(
        choice
            ? RecurringOccurrenceLinked(ruleId: rule.id, date: date, transactionId: similar.id)
            : RecurringOccurrenceRecorded(ruleId: rule.id, date: date, force: true),
      );
    },
  );

  /// Tercatat + **Batalkan** yang menghapus [recorded] lagi lewat
  /// `RecordTransaction.delete` (langsung, karena kartu bisa sudah hilang).
  UiEffect _effectRecordedWithUndo(String message, List<Transaction> recorded) {
    final record = _recordTransaction;
    return _effectWithUndo(message, () async {
      for (final transaction in recorded) {
        final result = await record.delete(transaction);
        if (result.isLeft()) return result;
      }
      return right(unit);
    });
  }

  UiEffect _effectWithUndo(String message, Future<Either<Failure, Unit>> Function() undo) => CallbackEffect(
    callback: (context) {
      final colors = context.appColors;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        actionSnackBar(
          context,
          content: Text(message, style: TextStyle(color: colors.bg)),
          backgroundColor: colors.ink,
          action: SnackBarAction(
            label: t.recurring.undoAction,
            textColor: colors.brand,
            onPressed: () async {
              final result = await undo();
              if (result case Left(value: final failure)) {
                messenger.showSnackBar(
                  feedbackSnackBar(
                    colors,
                    ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error),
                  ),
                );
              }
            },
          ),
        ),
      );
    },
  );

  Future<void> _write(RecurringRule rule, Emitter<RecurringState> emit, String? message) async {
    switch (await _rules.saveRule(rule)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        _recurringChanges.notifyChanged(source: this);
        emit(
          state.copyWith(
            rules: [for (final r in state.rules) r.id == rule.id ? rule : r],
            effect: message == null ? null : _effectDone(message),
          ),
        );
    }
  }

  UiEffect _effectError(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  UiEffect _effectDone(String message) => ShowSnackBarEffect(message: message, severity: .success);

  void _onDayChanged() => add(const RecurringRefreshed());

  @override
  Future<void> close() async {
    ActiveDay.notifier.removeListener(_onDayChanged);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
