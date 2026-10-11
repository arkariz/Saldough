import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/mocks.dart';

/// Kartu Arus Beranda memakai periode keuangan berjalan dan tanggal periode
/// (T-18.4, FR-HOME-001, FINANCIAL_PERIOD P-4 dan P-11).
void main() {
  late TransactionRepositoryImpl transactions;
  late MockBudgetOverviewSource budgets;
  late MockFreelanceOverviewSource freelance;
  final now = DateTime(2026, 10, 26, 9);
  final occurrence = DateTime(2026, 10, 25);

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    transactions = TransactionRepositoryImpl(storage: storage);
    budgets = MockBudgetOverviewSource();
    freelance = MockFreelanceOverviewSource();
    when(() => budgets.activeBudgetOverview()).thenAnswer(
      (_) async => right(const BudgetOverview(activeCount: 0, plannedAmount: 0, spent: 0)),
    );
    when(() => freelance.freelanceOverview()).thenAnswer((_) async => right(null));
    for (final t in <Transaction>[
      // Gaji kemunculan 25 Okt cair Jumat 23 Okt (contoh D).
      IncomeTransaction(
        id: 'gaji',
        date: DateTime(2026, 10, 23, 9),
        amount: 1200000000,
        note: 'Gaji',
        walletId: 'bca',
        recurrence: RecurrenceLink(ruleId: 'gaji', occurrenceDate: occurrence),
      ),
      ExpenseTransaction(id: 'sebelum', date: DateTime(2026, 10, 24, 19), amount: 5000000, note: '', walletId: 'bca'),
      ExpenseTransaction(id: 'makan', date: DateTime(2026, 10, 25, 12), amount: 7500000, note: '', walletId: 'bca'),
      ExpenseTransaction(id: 'nov', date: DateTime(2026, 11, 3, 12), amount: 2500000, note: '', walletId: 'bca'),
      TransferTransaction(
        id: 'tabung',
        date: DateTime(2026, 10, 26),
        amount: 100000000,
        note: '',
        fromWalletId: 'bca',
        toWalletId: 'jago',
      ),
      ExpenseTransaction(id: 'akhir', date: DateTime(2026, 11, 25, 8), amount: 1000000, note: '', walletId: 'bca'),
    ]) {
      await transactions.saveTransaction(t);
    }
  });

  tearDown(() => ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial);

  Future<HomeBloc> load() async {
    final bloc = HomeBloc(
      walletRepository: WalletRepositoryImpl(storage: InMemoryKeyValueStorage()),
      transactionRepository: transactions,
      budgetOverviewSource: budgets,
      freelanceOverviewSource: freelance,
      ledgerChanges: LedgerChanges(),
      now: () => now,
    )..add(const HomeStarted());
    await bloc.stream.firstWhere((s) => !s.isLoading);
    addTearDown(bloc.close);
    return bloc;
  }

  test('awal bulan 25: periode 25 Okt – 24 Nov, gaji 23 Okt ikut, transfer tidak', () async {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    final state = (await load()).state;
    expect(state.period, FinancialPeriod(start: DateTime(2026, 10, 25), end: DateTime(2026, 11, 25)));
    expect(state.period.name, '25 Okt – 24 Nov');
    expect(state.cashFlow, const CashFlow(income: 1200000000, expense: 10000000));
  });

  test('awal bulan 1: bulan kalender, bertajuk nama bulan', () async {
    final state = (await load()).state;
    expect(state.period, FinancialPeriod(start: DateTime(2026, 10), end: DateTime(2026, 11)));
    expect(state.period.name, 'Oktober');
    expect(state.cashFlow, const CashFlow(income: 1200000000, expense: 12500000));
  });

  test('periode peralihan bertajuk rentang walau awal barunya tanggal 1', () async {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(
      const FinancialMonthStart.day(25),
    ).changedOn(DateTime(2026, 10, 10), FinancialMonthStart.first);
    final state = (await load()).state;
    expect(state.period, FinancialPeriod(start: DateTime(2026, 9, 25), end: DateTime(2026, 11), isTransition: true));
    expect(state.period.name, '25 Sep – 31 Okt');
    expect(state.cashFlow, const CashFlow(income: 1200000000, expense: 12500000));
  });

  test('mengubah awal bulan menyegarkan Beranda', () async {
    final bloc = await load();
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    final state = await bloc.stream.firstWhere((s) => s.period.start == DateTime(2026, 10, 25));
    expect(state.cashFlow.expense, 10000000);
  });
}
