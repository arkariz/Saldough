import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/recurring/presentation/bloc/recurring_state.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'recurring_event.dart';

/// Bloc segmen Rutin dan rincian rutin (T-14.5, PLAN_TAB_LAYOUT §6).
///
/// Membaca rutin, dompet, dan dokumen bulan transaksi dari [_monthsBack]
/// bulan lalu sampai bulan berjalan (ADR-012): segmen cukup bulan
/// sebelumnya (ADR-034 §3.2), rincian membaca setahun untuk riwayat.
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
    this._monthsBack = 1,
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
    _subscriptions = [
      ledgerChanges.from(this).listen((_) => add(const RecurringRefreshed())),
      _recurringChanges.from(this).listen((_) => add(const RecurringRefreshed())),
    ];
  }

  final RecurringRuleRepository _rules;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final RecurringChanges _recurringChanges;
  final int _monthsBack;
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
    emit(
      state.copyWith(
        rules: rules.getOrElse((_) => const []),
        wallets: wallets.getOrElse((_) => const []),
        transactions: transactions,
        today: today,
        isLoading: false,
        loadFailed: false,
      ),
    );
  }

  Future<void> _onSkipped(RecurringOccurrenceSkipped event, Emitter<RecurringState> emit) async {
    final rule = state.ruleOf(event.ruleId);
    if (rule == null) return;
    await _write(
      rule.copyWith(skippedDates: {...rule.skippedDates, event.date}),
      emit,
      t.recurring.skippedMessage(date: CycleMonthFormatter.formatDayMonth(event.date)),
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

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
