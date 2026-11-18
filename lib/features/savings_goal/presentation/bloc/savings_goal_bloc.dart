import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'savings_goal_event.dart';
part 'savings_goal_state.dart';

/// Tujuan tabungan, dompet, dan transaksinya untuk layar rincian dan formulir
/// (ADR-048). Semua tulis lewat use case `shared/savings_goal`; tidak ada yang
/// menyentuh saldo (aturan 5).
final class SavingsGoalBloc extends Bloc<SavingsGoalEvent, SavingsGoalState> {
  /// Membuat [SavingsGoalBloc].
  SavingsGoalBloc({
    required this._goals,
    required this._wallets,
    required this._transactions,
    required this._ledgerChanges,
    required this._recordTransaction,
    this._idleMoney,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(SavingsGoalState.initial()) {
    on<SavingsGoalStarted>(_onStarted);
    on<SavingsGoalSaved>(_onSaved);
    on<SavingsGoalArchived>(_onArchived);
    on<SavingsGoalReactivated>(_onReactivated);
    on<SavingsGoalDeleted>(_onDeleted);
    _ledgerSubscription = _ledgerChanges.from(this).listen((_) => add(const SavingsGoalStarted()));
  }

  final SavingsGoalRepository _goals;
  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final LedgerChanges _ledgerChanges;

  /// Menghapus transaksi dompet tujuan saat tujuan dihapus (ADR-048 §8.2).
  final RecordTransaction _recordTransaction;
  late final StreamSubscription<void> _ledgerSubscription;

  /// Uang nganggur untuk baris skenario perkiraan (ADR-048 §3.6); `null` =
  /// tanpa skenario.
  final IdleMoneyAverage? _idleMoney;
  final DateTime Function() _now;

  ChangeSavingsGoalStatus get _change => ChangeSavingsGoalStatus(goalRepository: _goals, walletRepository: _wallets);

  Future<void> _onStarted(SavingsGoalStarted event, Emitter<SavingsGoalState> emit) async {
    await SyncSavingsGoalStatus(goalRepository: _goals, walletRepository: _wallets)();
    final goals = await _goals.listGoals();
    final wallets = await _wallets.listWallets();
    final transactions = await _transactions.listAllTransactions();
    switch ((goals, wallets, transactions)) {
      case (Right(value: final g), Right(value: final w), Right(value: final tx)):
        // Data sekunder: gagal dibaca berarti tanpa baris skenario.
        final idle = (await _idleMoney?.averageBefore(_now()))?.getOrElse((_) => null);
        emit(
          state.copyWith(
            goals: g,
            wallets: w,
            transactions: tx,
            idleAverage: () => idle,
            isLoading: false,
            loadFailed: false,
          ),
        );
      case (Left(value: final f), _, _) || (_, Left(value: final f), _) || (_, _, Left(value: final f)):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _error(f)));
    }
  }

  Future<void> _onSaved(SavingsGoalSaved event, Emitter<SavingsGoalState> emit) async {
    final isNew = state.goals.every((g) => g.id != event.goal.id);
    final result = isNew
        ? await CreateSavingsGoal(goalRepository: _goals, walletRepository: _wallets)(
            event.goal,
            initialAmount: event.initialAmount,
            activeLimit: event.activeLimit,
          )
        : await UpdateSavingsGoal(goalRepository: _goals, walletRepository: _wallets)(event.goal);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        if (isNew) AppAnalytics.log(WealthEvents.goalCreated(event.initialAmount > 0 ? 'initial' : 'empty'));
        // Dompet baru atau nama dompet berubah: layar lain ikut segar.
        _ledgerChanges.notifyChanged(source: this);
        await _reload(emit, t.assets.goal.savedMessage, saved: true);
    }
  }

  Future<void> _onArchived(SavingsGoalArchived event, Emitter<SavingsGoalState> emit) async {
    await _afterChange(await _change.archive(event.goalId), emit, t.assets.goal.archivedMessage);
  }

  Future<void> _onReactivated(SavingsGoalReactivated event, Emitter<SavingsGoalState> emit) async {
    await _afterChange(
      await _change.reactivate(event.goalId, activeLimit: event.activeLimit),
      emit,
      t.assets.goal.reactivatedMessage,
    );
  }

  Future<void> _onDeleted(SavingsGoalDeleted event, Emitter<SavingsGoalState> emit) async {
    final delete = DeleteSavingsGoal(
      goalRepository: _goals,
      walletRepository: _wallets,
      transactionRepository: _transactions,
      recordTransaction: _recordTransaction,
    );
    switch (await delete(event.goalId, source: this)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        await _reload(emit, t.assets.goal.deletedMessage, saved: true);
    }
  }

  Future<void> _afterChange(Either<Failure, SavingsGoal> result, Emitter<SavingsGoalState> emit, String message) async {
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        await _reload(emit, message);
    }
  }

  Future<void> _reload(Emitter<SavingsGoalState> emit, String message, {bool saved = false}) async {
    switch (await _goals.listGoals()) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right(value: final goals):
        emit(
          state.copyWith(
            goals: goals,
            saveCount: saved ? state.saveCount + 1 : null,
            effect: ShowSnackBarEffect(message: message, severity: .success),
          ),
        );
    }
  }

  UiEffect _error(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
