import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/domain/period_trend.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
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
    required WalletRepository walletRepository,
    required LedgerChanges ledgerChanges,
    Category? Function(String id)? categoryOf,
    DateTime Function()? now,
    bool sharesHistoryPeriod = false,
  }) : _repository = transactionRepository,
       _sharesHistory = sharesHistoryPeriod,
       _wallets = walletRepository,
       _categoryOf = categoryOf ?? ActiveCategories.byId,
       _now = now ?? DateTime.now,
       super(
         AnalysisState.initial(
           ActiveFinancialMonth.periodOf((now ?? DateTime.now)()),
         ),
       ) {
    on<AnalysisStarted>(_onStarted);
    on<AnalysisHistorySynced>((event, emit) async {
      // Segmen Daftar memindah periode bersama (`HistoryPeriod`).
      _anchor = HistoryPeriod.anchor;
      await _load(emit, firstLoad: false, keepSelection: false);
    });
    on<AnalysisRefreshed>(_onRefreshed);
    on<AnalysisPeriodStepped>(_onStepped);
    on<AnalysisGroupSelected>(_onSelected);
    on<AnalysisTrendSelected>((event, emit) {
      if (event.index >= 0 && event.index < state.trend.length) emit(state.withTrendSelected(event.index));
    });
    on<AnalysisPeriodJumped>((event, emit) async {
      _anchor = event.date;
      await _load(emit, firstLoad: false, keepSelection: false);
    });
    on<AnalysisKindChanged>(
      (event, emit) => _onControls(emit, kind: event.kind, walletId: state.walletId),
    );
    on<AnalysisWalletChanged>(
      (event, emit) => _onControls(emit, kind: state.kind, walletId: event.walletId),
    );
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => _refresh());
    ActiveFinancialMonth.notifier.addListener(_refresh);
    ActiveDay.notifier.addListener(_refresh);
    ActiveCategories.notifier.addListener(_refresh);
    ActiveCurrency.notifier.addListener(_refresh);
    if (_sharesHistory) HistoryPeriod.notifier.addListener(_syncHistory);
  }

  /// Periode dibagi dengan segmen Daftar di Riwayat (T-19.10).
  final bool _sharesHistory;

  void _syncHistory() {
    if (HistoryPeriod.anchor != _anchor) add(const AnalysisHistorySynced());
  }

  void _refresh() => add(const AnalysisRefreshed());

  late final StreamSubscription<void> _ledgerSubscription;
  final TransactionRepository _repository;
  final WalletRepository _wallets;
  final Category? Function(String id) _categoryOf;
  final DateTime Function() _now;

  /// Tanggal di dalam periode yang dilihat; `null` = ikut periode berjalan.
  DateTime? _anchor;

  /// Transaksi periode yang dilihat dan bulan pembandingnya; jenis dan dompet
  /// berganti tanpa membaca ulang.
  List<Transaction> _transactions = const [];

  /// Bulan pembanding periode yang dilihat (B-6) dan hari ini bila periode berjalan.
  List<FinancialPeriod> _comparisonPeriods = const [];
  DateTime? _comparisonToday;

  /// Periode tren enam kolom berakhir di periode yang dilihat (F6).
  List<FinancialPeriod> _trendPeriods = const [];

  List<TrendPoint> _trendFor(String? walletId) => buildTrend(
    transactions: _transactions,
    periods: _trendPeriods,
    today: _now(),
    categoryOf: _categoryOf,
    walletId: walletId,
  );

  PeriodComparison? _compare(
    AnalysisState from,
    CategoryKind kind,
    String? walletId,
  ) => comparePeriod(
    transactions: _transactions,
    period: from.period,
    periods: _comparisonPeriods,
    kind: kind,
    categoryOf: _categoryOf,
    today: _comparisonToday,
    walletId: walletId,
    minSen: highlightMinSenOf(ActiveCurrency.value),
  );

  Future<void> _onStarted(
    AnalysisStarted event,
    Emitter<AnalysisState> emit,
  ) async {
    _anchor = event.periodStart ?? (_sharesHistory ? HistoryPeriod.anchor : null);
    emit(state.copyWith(isLoading: true, loadFailed: false));
    await _load(emit, firstLoad: true);
  }

  Future<void> _onRefreshed(
    AnalysisRefreshed event,
    Emitter<AnalysisState> emit,
  ) => _load(emit, firstLoad: false);

  void _onSelected(AnalysisGroupSelected event, Emitter<AnalysisState> emit) {
    final summary = state.summary;
    if (summary == null || summary.groupOf(event.key) == null) return;
    final selected = state.selectedKey == event.key;
    if (event.key == 'others') {
      // Lainnya memilih sekaligus membuka anggotanya; mengetuk lagi menutup keduanya.
      emit(
        state.withSelection(selected ? null : event.key, othersOpen: !selected),
      );
    } else {
      emit(
        state.withSelection(
          selected ? null : event.key,
          othersOpen: state.othersOpen,
        ),
      );
    }
  }

  PeriodSummary _summarize(
    AnalysisState from,
    CategoryKind kind,
    String? walletId,
  ) => summarizePeriod(
    _transactions,
    from: from.period.start,
    until: from.period.end,
    kind: kind,
    categoryOf: _categoryOf,
    walletId: walletId,
  );

  /// Jenis atau dompet berganti: ringkasan dihitung ulang dari transaksi yang
  /// sudah dibaca dan pilihan baris dikosongkan (barisnya berganti).
  void _onControls(
    Emitter<AnalysisState> emit, {
    required CategoryKind kind,
    required String? walletId,
  }) {
    if (state.summary == null || (kind == state.kind && walletId == state.walletId)) return;
    emit(
      state.withControls(
        kind: kind,
        walletId: walletId,
        summary: _summarize(state, kind, walletId),
        comparison: _compare(state, kind, walletId),
        trend: _trendFor(walletId),
      ),
    );
  }

  Future<void> _onStepped(
    AnalysisPeriodStepped event,
    Emitter<AnalysisState> emit,
  ) async {
    final schedule = ActiveFinancialMonth.schedule;
    final shown = state.period;
    if (event.forward) {
      if (state.isCurrent) return;
      _anchor = schedule.nextOf(shown).start;
    } else {
      if (!state.canGoBack) return;
      _anchor = schedule.previousOf(shown).start;
    }
    // Pindah periode mengosongkan pilihan (F1).
    await _load(emit, firstLoad: false, keepSelection: false);
  }

  Future<void> _load(
    Emitter<AnalysisState> emit, {
    required bool firstLoad,
    bool keepSelection = true,
  }) async {
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
            kind: state.kind,
          ),
        );
        return;
      case Right(value: final months):
        final wallets = switch (await _wallets.listWallets()) {
          Right(:final value) => value,
          Left() => state.wallets,
        };
        final first = months.reduce((a, b) => a.isBefore(b) ? a : b);
        final earliest = schedule.periodOf(DateTime(first.year, first.month));
        _comparisonPeriods = comparisonPeriods(
          period: period,
          schedule: schedule,
          earliestStart: earliest.start,
        );
        _comparisonToday = period.start == current.start ? _now() : null;
        _trendPeriods = trendPeriods(
          period: period,
          schedule: schedule,
          earliestStart: earliest.start,
        );
        final readFrom = _trendPeriods.first.start;
        switch (await ListPeriodTransactions(_repository)(
          from: readFrom,
          until: period.end,
        )) {
          case Left(:final value):
            _emitFailure(emit, value, firstLoad: firstLoad);
          case Right(:final value):
            _transactions = value;
            // Dompet yang tak dikenal lagi dilepas dari penyaring.
            final walletId = wallets.any((w) => w.id == state.walletId) ? state.walletId : null;
            final summary = summarizePeriod(
              value,
              from: period.start,
              until: period.end,
              kind: state.kind,
              categoryOf: _categoryOf,
              walletId: walletId,
            );
            // Pilihan bertahan lewat penyegaran selama barisnya masih ada.
            final key = keepSelection && summary.groupOf(state.selectedKey ?? '') != null ? state.selectedKey : null;
            emit(
              AnalysisState(
                period: period,
                summary: summary,
                isCurrent: period.start == current.start,
                canGoBack: period.start.isAfter(earliest.start),
                hasAnyTransactions: true,
                isLoading: false,
                selectedKey: key,
                othersOpen: keepSelection && state.othersOpen && summary.groupOf('others') != null,
                kind: state.kind,
                walletId: walletId,
                wallets: wallets,
                comparison: comparePeriod(
                  transactions: value,
                  period: period,
                  periods: _comparisonPeriods,
                  kind: state.kind,
                  categoryOf: _categoryOf,
                  today: _comparisonToday,
                  walletId: walletId,
                  minSen: highlightMinSenOf(ActiveCurrency.value),
                ),
                trend: _trendFor(walletId),
                trendSelected: keepSelection ? state.trendSelected : null,
              ),
            );
            if (_sharesHistory) HistoryPeriod.select(period, current);
        }
    }
  }

  /// Pemuatan pertama yang gagal menampilkan galat layar; gagal menyegarkan
  /// mempertahankan angka lama dan cukup memberi tahu.
  void _emitFailure(
    Emitter<AnalysisState> emit,
    Failure failure, {
    required bool firstLoad,
  }) => emit(
    firstLoad
        ? state.copyWith(
            isLoading: false,
            loadFailed: true,
            effect: _effectError(failure),
          )
        : state.copyWith(effect: _effectError(failure)),
  );

  @override
  Future<void> close() async {
    ActiveFinancialMonth.notifier.removeListener(_refresh);
    ActiveDay.notifier.removeListener(_refresh);
    ActiveCategories.notifier.removeListener(_refresh);
    ActiveCurrency.notifier.removeListener(_refresh);
    HistoryPeriod.notifier.removeListener(_syncHistory);
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
