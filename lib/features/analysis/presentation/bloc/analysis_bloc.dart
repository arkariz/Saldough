import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

part 'analysis_effect.dart';
part 'analysis_event.dart';

/// Bloc Analisis (FR-ANL-001): ringkasan pengeluaran per kategori untuk satu
/// periode keuangan. Hanya membaca: tidak menulis entitas apa pun dan tidak
/// memancarkan `LedgerChanges` (B-13), hanya mendengarkannya supaya segar
/// begitu transaksi, kategori, awal bulan keuangan, atau tanggal berubah.
///
/// ⚠ Membaca dokumen bulan yang disentuh periode ± batas atribusi 7 hari
/// ([ListPeriodTransactions]), bukan seluruh riwayat (NFR-PERF-002).
final class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  /// Membuat [AnalysisBloc]. [categoryOf] dan [now] bisa diganti di uji.
  AnalysisBloc({
    required TransactionRepository transactionRepository,
    required LedgerChanges ledgerChanges,
    Category? Function(String id)? categoryOf,
    DateTime Function()? now,
  }) : _repository = transactionRepository,
       _categoryOf = categoryOf ?? ActiveCategories.byId,
       _now = now ?? DateTime.now,
       super(AnalysisState.initial(ActiveFinancialMonth.periodOf((now ?? DateTime.now)()))) {
    on<AnalysisStarted>(_onStarted);
    on<AnalysisRefreshed>(_onRefreshed);
    on<AnalysisPeriodStepped>(_onStepped);
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => _refresh());
    ActiveFinancialMonth.notifier.addListener(_refresh);
    ActiveDay.notifier.addListener(_refresh);
    ActiveCategories.notifier.addListener(_refresh);
  }

  void _refresh() => add(const AnalysisRefreshed());

  late final StreamSubscription<void> _ledgerSubscription;
  final TransactionRepository _repository;
  final Category? Function(String id) _categoryOf;
  final DateTime Function() _now;

  /// Tanggal di dalam periode yang dilihat; `null` = ikut periode berjalan.
  DateTime? _anchor;

  Future<void> _onStarted(AnalysisStarted event, Emitter<AnalysisState> emit) async {
    _anchor = event.periodStart;
    emit(state.copyWith(isLoading: true, loadFailed: false));
    await _load(emit, firstLoad: true);
  }

  Future<void> _onRefreshed(AnalysisRefreshed event, Emitter<AnalysisState> emit) =>
      _load(emit, firstLoad: false);

  Future<void> _onStepped(AnalysisPeriodStepped event, Emitter<AnalysisState> emit) async {
    final schedule = ActiveFinancialMonth.schedule;
    final shown = state.period;
    if (event.forward) {
      if (state.isCurrent) return;
      _anchor = schedule.nextOf(shown).start;
    } else {
      if (!state.canGoBack) return;
      _anchor = schedule.previousOf(shown).start;
    }
    await _load(emit, firstLoad: false);
  }

  Future<void> _load(Emitter<AnalysisState> emit, {required bool firstLoad}) async {
    final schedule = ActiveFinancialMonth.schedule;
    final current = schedule.periodOf(_now());
    var period = _anchor == null ? current : schedule.periodOf(_anchor!);
    // Analisis tidak melihat ke depan: awal bulan yang diubah atau tanggal
    // yang berganti tidak boleh meninggalkan periode di masa depan.
    if (period.start.isAfter(current.start)) period = current;
    if (!period.start.isBefore(current.start)) _anchor = null;

    final months = await _repository.listAvailableMonths();
    switch (months) {
      case Left(:final value):
        _emitFailure(emit, value, firstLoad: firstLoad);
        return;
      case Right(value: final months) when months.isEmpty:
        emit(
          AnalysisState(
            period: period,
            summary: null,
            isCurrent: true,
            canGoBack: false,
            hasAnyTransactions: false,
            isLoading: false,
          ),
        );
        return;
      case Right(value: final months):
        final first = months.reduce((a, b) => a.isBefore(b) ? a : b);
        final earliest = schedule.periodOf(DateTime(first.year, first.month));
        switch (await ListPeriodTransactions(_repository)(from: period.start, until: period.end)) {
          case Left(:final value):
            _emitFailure(emit, value, firstLoad: firstLoad);
          case Right(:final value):
            emit(
              AnalysisState(
                period: period,
                summary: summarizePeriod(
                  value,
                  from: period.start,
                  until: period.end,
                  kind: CategoryKind.expense,
                  categoryOf: _categoryOf,
                ),
                isCurrent: period.start == current.start,
                canGoBack: period.start.isAfter(earliest.start),
                hasAnyTransactions: true,
                isLoading: false,
              ),
            );
        }
    }
  }

  /// Pemuatan pertama yang gagal menampilkan galat layar; gagal menyegarkan
  /// mempertahankan angka lama dan cukup memberi tahu.
  void _emitFailure(Emitter<AnalysisState> emit, Failure failure, {required bool firstLoad}) => emit(
    firstLoad
        ? state.copyWith(isLoading: false, loadFailed: true, effect: _effectError(failure))
        : state.copyWith(effect: _effectError(failure)),
  );

  @override
  Future<void> close() async {
    ActiveFinancialMonth.notifier.removeListener(_refresh);
    ActiveDay.notifier.removeListener(_refresh);
    ActiveCategories.notifier.removeListener(_refresh);
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
