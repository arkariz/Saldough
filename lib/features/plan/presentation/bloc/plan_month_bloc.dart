import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/plan/domain/month_review.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Event [PlanMonthBloc].
sealed class PlanMonthEvent {
  /// Membuat [PlanMonthEvent].
  const PlanMonthEvent();
}

/// Memuat (dengan kerangka bila [showSkeleton]).
final class PlanMonthLoaded extends PlanMonthEvent {
  /// Membuat [PlanMonthLoaded].
  const PlanMonthLoaded({this.showSkeleton = true});

  /// Tampilkan kerangka.
  final bool showSkeleton;
}

/// Dompet kartu saldo dipilih; `null` = semua.
final class PlanMonthWalletChanged extends PlanMonthEvent {
  /// Membuat [PlanMonthWalletChanged].
  const PlanMonthWalletChanged(this.walletId);

  /// Dompetnya.
  final String? walletId;
}

/// Sakelar "Hitung jajan harian".
final class PlanMonthUnplannedToggled extends PlanMonthEvent {
  /// Membuat [PlanMonthUnplannedToggled].
  const PlanMonthUnplannedToggled({required this.enabled});

  /// Nyala atau mati.
  final bool enabled;
}

/// Centang satu langkah tinjau awal bulan (J4, ADR-036 §3.7).
final class PlanReviewStepDone extends PlanMonthEvent {
  /// Membuat [PlanReviewStepDone].
  const PlanReviewStepDone(this.step);

  /// Langkahnya.
  final MonthReviewStep step;
}

/// "Nanti": kartu tinjau dilipat (`true`) atau dibuka lagi (`false`).
final class PlanReviewDismissed extends PlanMonthEvent {
  /// Membuat [PlanReviewDismissed].
  const PlanReviewDismissed({this.dismissed = true});

  /// Dilipat atau dibuka.
  final bool dismissed;
}

/// Tinjau disimpan di tempat lain (bloc Beranda atau Bulan ini).
final class PlanReviewSynced extends PlanMonthEvent {
  /// Membuat [PlanReviewSynced].
  const PlanReviewSynced(this.review);

  /// Tinjau terbaru.
  final MonthReview review;
}

/// "Selesai meninjau".
final class PlanReviewCompleted extends PlanMonthEvent {
  /// Membuat [PlanReviewCompleted].
  const PlanReviewCompleted();
}

/// Pilih bulan di pemilih bulan (ADR-036 §3.5): 0 = bulan berjalan.
final class PlanMonthSelected extends PlanMonthEvent {
  /// Membuat [PlanMonthSelected].
  const PlanMonthSelected(this.index);

  /// Indeks bulan.
  final int index;
}

/// Bloc segmen **Bulan ini** dan baris perkiraan di Beranda (T-15.13).
/// Hanya membaca; tidak ada yang ditulis dari sini.
final class PlanMonthBloc extends Bloc<PlanMonthEvent, PlanMonthState> {
  /// Membuat [PlanMonthBloc]. [now] bisa diganti di uji.
  PlanMonthBloc({
    required this._wallets,
    required this._transactions,
    required this._rules,
    required this._budgets,
    required this._freelance,
    required LedgerChanges ledgerChanges,
    required RecurringChanges recurringChanges,
    this._reviews,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(PlanMonthState(today: DateTime.now(), range: financialMonthOf(DateTime.now(), 1))) {
    on<PlanMonthLoaded>(_onLoaded);
    on<PlanMonthWalletChanged>((event, emit) => emit(state.copyWith(walletId: () => event.walletId)));
    on<PlanMonthUnplannedToggled>((event, emit) => emit(state.copyWith(includeUnplanned: event.enabled)));
    on<PlanMonthSelected>((event, emit) {
      if (event.index != state.selected) AppAnalytics.log(PlanEvents.planViewed(event.index));
      emit(state.copyWith(selected: event.index));
    });
    on<PlanReviewStepDone>(
      (event, emit) => _saveReview(state.review.copyWith(doneSteps: {...state.review.doneSteps, event.step}), emit),
    );
    on<PlanReviewDismissed>((event, emit) => _saveReview(state.review.copyWith(dismissed: event.dismissed), emit));
    on<PlanReviewSynced>((event, emit) {
      if (event.review.monthStart == state.range.start && event.review != state.review) {
        emit(state.copyWith(review: event.review));
      }
    });
    on<PlanReviewCompleted>((event, emit) async {
      AppAnalytics.log(PlanEvents.monthReviewCompleted(state.reviewDoneCount));
      await _saveReview(state.review.copyWith(completed: true), emit);
      emit(
        state.copyWith(
          effect: ShowSnackBarEffect(
            message: t.plan.reviewDoneMessage(month: state.range.label),
            severity: .success,
          ),
        ),
      );
    });
    void refresh() => add(const PlanMonthLoaded(showSkeleton: false));
    _subscriptions = [
      ledgerChanges.changes.listen((_) => refresh()),
      recurringChanges.changes.listen((_) => refresh()),
      ?_reviews?.changes.listen((review) => add(PlanReviewSynced(review))),
    ];
    ActiveFinancialMonth.notifier.addListener(refresh);
    // Tanggal berganti saat aplikasi hidup di latar (T-15.17).
    ActiveDay.notifier.addListener(refresh);
    _removeMonthListener = () {
      ActiveFinancialMonth.notifier.removeListener(refresh);
      ActiveDay.notifier.removeListener(refresh);
    };
  }

  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final RecurringRuleRepository _rules;
  final PlanBudgetSource _budgets;
  final PlanFreelanceSource _freelance;

  /// Status tinjau awal bulan (ADR-036 §3.7); `null` = tanpa (sebagian uji).
  final MonthReviewRepository? _reviews;

  Future<void> _saveReview(MonthReview review, Emitter<PlanMonthState> emit) async {
    emit(state.copyWith(review: review));
    await _reviews?.save(review);
  }

  final DateTime Function() _now;
  late final List<StreamSubscription<void>> _subscriptions;
  late final void Function() _removeMonthListener;

  Future<void> _onLoaded(PlanMonthLoaded event, Emitter<PlanMonthState> emit) async {
    if (event.showSkeleton) emit(state.copyWith(isLoading: true));
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final range = financialMonthOf(today, ActiveFinancialMonth.startDay);
    Failure? failure;
    T? read<T>(Either<Failure, T> result) => result.fold((f) {
      failure ??= f;
      return null;
    }, (value) => value);

    final wallets = read(await _wallets.listWallets());
    final rules = read(await _rules.listRules());
    // Anggaran yang sudah ada + periode virtual anggaran rutin yang belum
    // lahir, untuk bulan berjalan dan dua bulan sesudahnya (ADR-036 §3.5).
    Future<List<PlanBudget>?> budgetsIn(FinancialMonthRange m) async {
      final existing = read(await _budgets.budgetsStartingIn(m.start, m.end));
      final scheduled = read(await _budgets.scheduledBudgetsStartingIn(m.start, m.end));
      return existing == null ? null : [...existing, ...?scheduled];
    }

    final budgets = await budgetsIn(range);
    // Bulan lalu untuk kilas balik (W10).
    final previousRange = financialMonthOf(
      DateTime(range.start.year, range.start.month - 1, range.start.day),
      range.start.day,
    );
    final previousBudgets = (await _budgets.budgetsStartingIn(previousRange.start, previousRange.end)).getOrElse(
      (_) => const [],
    );
    final stored = (await _reviews?.load())?.getOrElse((_) => null);
    final review = stored != null && stored.monthStart == range.start ? stored : MonthReview(monthStart: range.start);
    final later = <List<PlanBudget>>[];
    for (var k = 1; k <= PlanMonthState.horizon; k++) {
      final m = financialMonthOf(DateTime(range.start.year, range.start.month + k, range.start.day), range.start.day);
      later.add(await budgetsIn(m) ?? const []);
    }
    // Freelance adalah data sekunder: gagal dibaca berarti tanpa "belum pasti".
    final uncertain = (await _freelance.unpaid()).getOrElse((_) => const []);
    final months = read(await _transactions.listAvailableMonths()) ?? const <DateTime>[];
    final transactions = <Transaction>[];
    // Tiga bulan keuangan lalu (rata-rata di luar rencana) sampai akhir bulan ini.
    final from = DateTime(range.start.year, range.start.month - 3, range.start.day);
    for (var m = DateTime(from.year, from.month); m.isBefore(range.end); m = DateTime(m.year, m.month + 1)) {
      transactions.addAll(read(await _transactions.listTransactionsInMonth(m)) ?? const []);
    }
    if (failure != null) {
      emit(
        state.copyWith(
          isLoading: false,
          loadFailed: true,
          effect: ShowSnackBarEffect(message: failure!.userMessage ?? t.common.genericErrorMessage, severity: .error),
        ),
      );
      return;
    }
    final earliestMonth = months.isEmpty ? null : months.reduce((a, b) => a.isBefore(b) ? a : b);
    final earliestLoaded = transactions.isEmpty
        ? null
        : transactions.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final historyStart = earliestMonth == null
        ? null
        : (earliestLoaded != null &&
                  earliestLoaded.year == earliestMonth.year &&
                  earliestLoaded.month == earliestMonth.month
              ? earliestLoaded
              : earliestMonth);
    emit(
      state.copyWith(
        today: today,
        range: range,
        isLoading: false,
        loadFailed: false,
        wallets: [
          for (final w in wallets!)
            if (w.isActive) w,
        ],
        rules: rules,
        budgets: budgets,
        laterBudgets: later,
        previousBudgets: previousBudgets,
        review: review,
        uncertain: uncertain,
        transactions: transactions,
        historyStart: historyStart,
      ),
    );
    if (!_viewed) {
      _viewed = true;
      AppAnalytics.log(PlanEvents.planViewed(state.selected));
    }
    await _snapshot(emit);
  }

  /// `plan_viewed` dikirim sekali saat pertama dimuat, bukan tiap segar.
  bool _viewed = false;

  /// W9: simpan perkiraan akhir bulan ini sekali (semua dompet aktif), lalu
  /// baca snapshot bulan lalu.
  Future<void> _snapshot(Emitter<PlanMonthState> emit) async {
    final reviews = _reviews;
    if (reviews == null) return;
    final stored = (await reviews.loadSnapshots()).getOrElse((_) => const []);
    final current = ForecastSnapshot(
      monthStart: state.range.start,
      endBalance: state.copyWith(walletId: () => null).projectionFor(0).endBalance,
      takenOn: state.today,
    );
    final updated = withSnapshot(stored, current);
    if (!identical(updated, stored)) await reviews.saveSnapshots(updated);
    final previous = state.previousRange.start;
    emit(
      state.copyWith(
        previousForecast: () => updated
            .where((s) => s.monthStart == previous && s.isEarly(days: PlanMonthState.reviewDays))
            .firstOrNull
            ?.endBalance,
      ),
    );
  }

  @override
  Future<void> close() async {
    _removeMonthListener();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
