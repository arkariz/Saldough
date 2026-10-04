import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
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

  Future<void> pump(WidgetTester tester, {double width = 400}) async {
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
      now: () => DateTime(2026, 10, 2, 9),
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

  test('nominal ringkas chip bulan', () {
    expect(compactApprox(1092100000), '≈10,9 jt');
    expect(compactApprox(1100000000), '≈11 jt');
    expect(compactApprox(85000000), '≈850 rb');
    expect(compactApprox(-171400000), '≈−1,7 jt');
  });
}
