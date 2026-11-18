import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/investment/investment_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

part 'investment_event.dart';
part 'investment_state.dart';

/// Instrumen, valuasi, dan catatan beli/jual untuk layar Investasi
/// (ADR-049). Semua tulis lewat use case `shared/investment`; perubahan
/// diumumkan lewat [LedgerChanges] supaya tab Dompet dan Beranda segar.
final class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  /// Membuat [InvestmentBloc].
  InvestmentBloc({
    required this._investments,
    required this._transactions,
    required this._wallets,
    required this._ledgerChanges,
  }) : super(InvestmentState.initial()) {
    on<InvestmentStarted>(_onStarted);
    on<InstrumentSaved>(_onSaved);
    on<InstrumentDeleted>(_onDeleted);
    on<ValuationsSaved>(_onValuationsSaved);
    on<ValuationDeleted>(_onValuationDeleted);
    _ledgerSubscription = _ledgerChanges.from(this).listen((_) => add(const InvestmentStarted()));
  }

  final InvestmentRepository _investments;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final LedgerChanges _ledgerChanges;
  late final StreamSubscription<void> _ledgerSubscription;

  LoadInstrumentSummaries get _summaries =>
      LoadInstrumentSummaries(investments: _investments, transactions: _transactions);

  Future<void> _onStarted(InvestmentStarted event, Emitter<InvestmentState> emit) => _load(emit);

  Future<void> _load(Emitter<InvestmentState> emit, {UiEffect? effect, bool saved = false}) async {
    final summaries = await _summaries();
    final valuations = await _investments.listValuations();
    final ledger = await _transactions.listAllTransactions();
    final wallets = await _wallets.listWallets();
    switch ((summaries, valuations, ledger, wallets)) {
      case (Right(value: final s), Right(value: final v), Right(value: final l), Right(value: final w)):
        emit(
          state.copyWith(
            summaries: s,
            valuations: v,
            trades: [for (final t in l) if (t is InvestmentTransaction) t],
            wallets: w,
            isLoading: false,
            loadFailed: false,
            saveCount: saved ? state.saveCount + 1 : null,
            effect: effect,
          ),
        );
      case (Left(value: final f), _, _, _) ||
          (_, Left(value: final f), _, _) ||
          (_, _, Left(value: final f), _) ||
          (_, _, _, Left(value: final f)):
        emit(state.copyWith(isLoading: false, loadFailed: true, effect: _error(f)));
    }
  }

  Future<void> _onSaved(InstrumentSaved event, Emitter<InvestmentState> emit) async {
    final isNew = state.summaryOf(event.instrument.id) == null;
    final result = isNew
        ? await CreateInstrument(investments: _investments, summaries: _summaries)(
            event.instrument,
            activeLimit: event.activeLimit,
          )
        : await UpdateInstrument(investments: _investments, transactions: _transactions)(event.instrument);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure), lastFailure: () => failure.code));
      case Right():
        if (isNew) AppAnalytics.log(WealthEvents.instrumentAdded(event.instrument.type.name, 'existing'));
        _ledgerChanges.notifyChanged(source: this);
        await _load(emit, effect: _success(t.assets.invest.saved), saved: true);
    }
  }

  Future<void> _onDeleted(InstrumentDeleted event, Emitter<InvestmentState> emit) async {
    switch (await DeleteInstrument(investments: _investments, transactions: _transactions)(event.instrumentId)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        _ledgerChanges.notifyChanged(source: this);
        await _load(emit, effect: _success(t.assets.invest.deleted), saved: true);
    }
  }

  Future<void> _onValuationsSaved(ValuationsSaved event, Emitter<InvestmentState> emit) async {
    switch (await SaveValuations(investments: _investments)(event.valuations)) {
      case Left():
        emit(state.copyWith(effect: _error(null, t.assets.invest.bulk.saveError)));
      case Right() when event.restore:
        _ledgerChanges.notifyChanged(source: this);
        await _load(emit);
      case Right():
        final n = event.valuations.length;
        AppAnalytics.log(WealthEvents.valuationUpdated(n, event.single ? 'single' : 'bulk'));
        _ledgerChanges.notifyChanged(source: this);
        await _load(
          emit,
          effect: _success(n == 1 ? t.assets.invest.bulk.savedOne : t.assets.invest.bulk.saved(n: n)),
          saved: true,
        );
    }
  }

  Future<void> _onValuationDeleted(ValuationDeleted event, Emitter<InvestmentState> emit) async {
    final v = event.valuation;
    switch (await _investments.deleteValuation(v.instrumentId, v.date)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        _ledgerChanges.notifyChanged(source: this);
        await _load(emit);
    }
  }

  UiEffect _success(String message) => ShowSnackBarEffect(message: message, severity: .success);

  UiEffect _error(Failure? failure, [String? message]) => ShowSnackBarEffect(
    message:
        message ??
        failure?.userMessage ??
        (failure == null ? null : investmentFailureMessage(failure)) ??
        t.common.genericErrorMessage,
    severity: .error,
  );

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
