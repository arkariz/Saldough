import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/plan/data/month_review_repository_impl.dart';
import 'package:saldough/features/plan/domain/month_review.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/features/plan/presentation/pages/plan_month_page.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Anggaran hanya untuk rentang pertama yang diminta (bulan berjalan).
final class _Budgets implements PlanBudgetSource {
  _Budgets(this.budgets);
  final List<PlanBudget> budgets;
  DateTime? _first;

  @override
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until) async {
    _first ??= from;
    return right(from == _first ? budgets : const []);
  }

  @override
  Future<Either<Failure, List<PlanBudget>>> scheduledBudgetsStartingIn(DateTime from, DateTime until) async =>
      right(const []);
}

final class _NoFreelance implements PlanFreelanceSource {
  const _NoFreelance();

  @override
  Future<Either<Failure, List<UncertainIncome>>> unpaid() async => right(const []);
}

/// Segmen Bulan ini dengan contoh RECURRING_AND_FORECAST §7.6/§7.2a (hari
/// ini 2 Okt 2026).
void main() {
  late InMemoryKeyValueStorage storage;
  late RecurringRuleRepositoryImpl rules;
  late TransactionRepositoryImpl transactions;
  late WalletRepositoryImpl wallets;

  RecurringRule rule(String id, int amount, int day, {RecurringKind kind = RecurringKind.expense}) => RecurringRule(
    id: id,
    kind: kind,
    amount: amount,
    amountMode: id == 'Listrik' ? RecurringAmountMode.estimated : RecurringAmountMode.fixed,
    walletId: 'bca',
    toWalletId: kind == RecurringKind.transfer ? 'tabungan' : null,
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, day)),
  );

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    rules = RecurringRuleRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    wallets = WalletRepositoryImpl(storage: storage);
    for (final r in [
      rule('Kos', 190000000, 1),
      rule('Netflix', 6500000, 1),
      rule('Listrik', 20000000, 5),
      rule('Cicilan', 291400000, 10),
      rule('Gaji', 1200000000, 25, kind: RecurringKind.income),
      rule('Tabungan', 100000000, 26, kind: RecurringKind.transfer),
      rule('Sabil', 80000000, 28),
    ]) {
      await rules.saveRule(r);
    }
    // Saldo nyata disimpan langsung (tanpa hitung ulang): Rp6.500.000.
    await wallets.saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 650000000),
    );
    for (final t in <Transaction>[
      // Riwayat sejak 1 Jul: rata-rata di luar rencana Jul–Sep (92 hari) = Rp30.000/hari.
      ExpenseTransaction(id: 'jul', date: DateTime(2026, 7), amount: 276000000, note: '', walletId: 'bca'),
      ExpenseTransaction(
        id: 'kos',
        date: DateTime(2026, 10, 1, 8),
        amount: 190000000,
        note: 'Kos',
        walletId: 'bca',
        recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10)),
      ),
      ExpenseTransaction(id: 'jajan', date: DateTime(2026, 10, 2, 8), amount: 5700000, note: '', walletId: 'bca'),
    ]) {
      await transactions.saveTransaction(t);
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    double width = 400,
    MonthReviewRepository? reviews,
    DateTime? today,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final bloc = PlanMonthBloc(
      wallets: wallets,
      transactions: transactions,
      rules: rules,
      budgets: _Budgets([
        PlanBudget(
          walletId: 'bca',
          periodEnd: DateTime(2026, 11),
          lines: const [(key: null, itemId: 'bulanan', planned: 306850000, spent: 36850000)],
        ),
      ]),
      freelance: const _NoFreelance(),
      ledgerChanges: LedgerChanges(),
      recurringChanges: RecurringChanges(),
      reviews: reviews,
      now: () => today ?? DateTime(2026, 10, 2, 9),
    )..add(const PlanMonthLoaded());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: PlanMonthView(onShowRecurring: () {}, onShowBudget: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Uang nganggur Rp2.995.500 = jumlah baris di bawahnya (§4.9)', (tester) async {
    await pump(tester);
    expect(find.text(t.plan.unplannedTitle(month: 'Okt').toUpperCase()), findsOneWidget);
    expect(find.text('Rp2.995.500'), findsOneWidget);
    // Juga baris Gaji 25 Okt di Berikutnya.
    expect(find.text('+Rp12.000.000'), findsNWidgets(2));
    expect(find.text('−Rp5.879.000'), findsOneWidget);
    expect(find.text('−Rp3.068.500'), findsOneWidget);
    expect(find.text('−Rp57.000'), findsOneWidget);
    expect(12000000 - 5879000 - 3068500 - 57000, 2995500);
  });

  testWidgets('Saldo dompet ≈: akhir Okt ≈Rp10.921.000, paling tipis ≈Rp561.000 pada 24 Okt, grafik bersemantik', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(find.text('≈Rp10.921.000'), findsOneWidget);
    expect(find.text('≈Rp561.000'), findsOneWidget);
    expect(find.text(t.plan.lowestOn(date: '24 Okt')), findsOneWidget);
    expect(
      find.bySemanticsLabel(t.plan.chartSemantics(low: 'Rp561.000', date: '24 Okt', end: 'Rp10.921.000')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('360dp tanpa luapan; tiga berikutnya urut tanggal', (tester) async {
    await pump(tester, width: 360);
    expect(tester.takeException(), isNull);
    expect(find.text(t.plan.nextTitle.toUpperCase()), findsOneWidget);
    expect(find.text('5 Okt'), findsOneWidget);
    expect(find.text('10 Okt'), findsOneWidget);
    expect(find.text('25 Okt'), findsOneWidget);
  });

  testWidgets('pemilih bulan: Nov berawal dari akhir Okt dan berlencana PERKIRAAN (T-16.6, invarian 20)', (
    tester,
  ) async {
    await pump(tester, width: 360);
    expect(find.text('Okt ≈10,9 jt'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plan-month-1')));
    await tester.pumpAndSettle();
    expect(find.textContaining(t.plan.forecastBadge), findsOneWidget);
    expect(find.text(t.plan.startOf(date: '1 Nov')), findsOneWidget);
    expect(find.text('≈Rp10.921.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W8: 75% pemasukan Okt terikat, bulan sebelumnya 49% (T-16.10)', (tester) async {
    await pump(tester);
    expect(
      find.text(t.plan.committedShareVs(percent: 75, month: 'Okt', previous: 49)),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('plan-installment-free')), findsNothing);
  });

  testWidgets(
    'analitik R2 tanpa nominal: plan_viewed sekali saat dimuat dan per bulan, month_review_completed (T-16.11)',
    (
      tester,
    ) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      await pump(tester, width: 360);
      expect(events, [PlanEvents.planViewed(0)]);
      await tester.tap(find.byKey(const ValueKey('plan-month-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('plan-month-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.plan.reviewOk));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.plan.reviewDone));
      await tester.pumpAndSettle();
      expect(events, [
        PlanEvents.planViewed(0),
        PlanEvents.planViewed(1),
        PlanEvents.planViewed(0),
        PlanEvents.monthReviewCompleted(1),
      ]);
      expect(events.last.parameters, {'steps_done': 1});
    },
  );

  test('nama dan parameter peristiwa R2 (ADR-036 §3.8)', () {
    expect(PlanEvents.budgetRepeatToggled(on: true), const AnalyticsEvent('budget_repeat_toggled', {'on': 'true'}));
    expect(PlanEvents.budgetPeriodBorn(count: 2), const AnalyticsEvent('budget_period_born', {'count': 2}));
    expect(
      PlanEvents.budgetEditScope('thisAndNext'),
      const AnalyticsEvent('budget_edit_scope', {'scope': 'thisAndNext'}),
    );
    expect(
      PlanEvents.recurringBudgetLinked('suggestion'),
      const AnalyticsEvent('recurring_budget_linked', {'source': 'suggestion'}),
    );
    expect(PlanEvents.planViewed(2), const AnalyticsEvent('plan_viewed', {'month_offset': 2}));
    expect(PlanEvents.fundingWarningShown, const AnalyticsEvent('funding_warning_shown'));
  });

  group('tinjau awal bulan (T-16.8, J4)', () {
    late MonthReviewRepositoryImpl reviews;
    setUp(() => reviews = MonthReviewRepositoryImpl(storage: storage));

    Finder card() => find.byKey(const ValueKey('month-review-card'));

    testWidgets('langkah perkiraan + kilas balik; Sesuai mencentang dan tersimpan', (tester) async {
      await pump(tester, width: 360, reviews: reviews);
      expect(card(), findsOneWidget);
      expect(find.text('0/2'), findsOneWidget);
      expect(find.text(t.plan.reviewEstimate(name: 'Listrik', amount: 'Rp200.000')), findsOneWidget);
      await tester.tap(find.text(t.plan.reviewOk));
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
      final stored = (await reviews.load()).getOrElse((_) => null)!;
      expect(stored.monthStart, DateTime(2026, 10));
      expect(stored.doneSteps, {MonthReviewStep.estimates});
      expect(tester.takeException(), isNull);
    });

    testWidgets('Nanti melipat jadi satu baris; Selesai meninjau menyembunyikan kartu', (tester) async {
      await pump(tester, reviews: reviews);
      await tester.tap(find.text(t.plan.reviewLater));
      await tester.pumpAndSettle();
      expect(card(), findsNothing);
      expect(find.byKey(const ValueKey('month-review-collapsed')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('month-review-collapsed')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.plan.reviewDone));
      await tester.pumpAndSettle();
      expect(card(), findsNothing);
      expect(find.byKey(const ValueKey('month-review-collapsed')), findsNothing);
      expect((await reviews.load()).getOrElse((_) => null)!.completed, isTrue);
    });

    testWidgets('tinjau yang diselesaikan di bloc lain (Beranda) ikut tertutup di sini (T-16.14)', (tester) async {
      await pump(tester, reviews: reviews);
      expect(card(), findsOneWidget);
      await tester.runAsync(() => reviews.save(MonthReview(monthStart: DateTime(2026, 10), completed: true)));
      await tester.pumpAndSettle();
      expect(card(), findsNothing);
    });

    testWidgets('status bulan lalu tidak terbawa ke bulan baru', (tester) async {
      await reviews.save(MonthReview(monthStart: DateTime(2026, 9), completed: true));
      await pump(tester, reviews: reviews);
      expect(card(), findsOneWidget);
    });

    testWidgets('lewat hari ke-7 kartu tidak tampil', (tester) async {
      await pump(tester, reviews: reviews, today: DateTime(2026, 10, 8, 9));
      expect(card(), findsNothing);
    });

    testWidgets('W9: snapshot bulan ini sekali; selisih perkiraan bulan lalu vs saldo nyata', (tester) async {
      // Saldo nyata akhir Sep = Rp6.500.000 + Kos Rp1.900.000 + jajan Rp57.000.
      await reviews.saveSnapshots([
        ForecastSnapshot(monthStart: DateTime(2026, 9), endBalance: 845700000 + 31200000),
        ForecastSnapshot(monthStart: DateTime(2026, 10), endBalance: 1),
      ]);
      await pump(tester, reviews: reviews);
      expect(find.textContaining('Rp312.000'), findsOneWidget);
      // Snapshot Okt yang sudah ada tidak ditimpa.
      final stored = (await reviews.loadSnapshots()).getOrElse((_) => const []);
      expect(stored.last, ForecastSnapshot(monthStart: DateTime(2026, 10), endBalance: 1));
    });

    testWidgets('tanpa snapshot bulan lalu: W9 tidak tampil, snapshot Okt dibuat', (tester) async {
      await pump(tester, reviews: reviews);
      expect(find.textContaining(t.plan.reviewLookback(month: '').trim()), findsOneWidget);
      expect(find.textContaining('Rp312.000'), findsNothing);
      final stored = (await reviews.loadSnapshots()).getOrElse((_) => const []);
      expect(stored.single.monthStart, DateTime(2026, 10));
    });

    test('withSnapshot: yang pertama menang, hanya tiga bulan terakhir', () {
      ForecastSnapshot s(int month, [int end = 0]) =>
          ForecastSnapshot(monthStart: DateTime(2026, month), endBalance: end);
      final list = [s(7), s(8), s(9)];
      expect(withSnapshot(list, s(9, 5)), same(list));
      expect(withSnapshot(list, s(10)), [s(8), s(9), s(10)]);
    });

    test('balanceBefore: transfer antardompet tidak mengubah jumlah', () {
      final txs = <Transaction>[
        IncomeTransaction(id: 'a', date: DateTime(2026, 10, 3), amount: 100, note: '', walletId: 'x'),
        ExpenseTransaction(id: 'b', date: DateTime(2026, 10, 4), amount: 30, note: '', walletId: 'y'),
        TransferTransaction(
          id: 'c',
          date: DateTime(2026, 10, 5),
          amount: 50,
          note: '',
          fromWalletId: 'x',
          toWalletId: 'y',
        ),
        TransferTransaction(
          id: 'd',
          date: DateTime(2026, 10, 5),
          amount: 20,
          note: '',
          fromWalletId: 'x',
          toWalletId: 'z',
        ),
        ExpenseTransaction(id: 'e', date: DateTime(2026, 9, 30), amount: 999, note: '', walletId: 'x'),
      ];
      expect(balanceBefore(DateTime(2026, 10), currentBalance: 1000, transactions: txs, walletIds: {'x', 'y'}), 950);
    });

    test('repositori menyimpan dan memuat ulang', () async {
      final review = MonthReview(
        monthStart: DateTime(2026, 10),
        doneSteps: const {MonthReviewStep.budgets, MonthReviewStep.lookback},
        dismissed: true,
      );
      await reviews.save(review);
      expect((await MonthReviewRepositoryImpl(storage: storage).load()).getOrElse((_) => null), review);
    });
  });

  test('nominal ringkas chip bulan', () {
    expect(compactApprox(1092100000), '≈10,9 jt');
    expect(compactApprox(1100000000), '≈11 jt');
    expect(compactApprox(85000000), '≈850 rb');
    expect(compactApprox(-171400000), '≈−1,7 jt');
  });
}
