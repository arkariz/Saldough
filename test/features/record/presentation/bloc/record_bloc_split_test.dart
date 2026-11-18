import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/mocks.dart';

/// Menabung ke beberapa tujuan sekaligus lewat CATAT (ADR-048 §9), dengan
/// penyimpanan sungguhan di memori.
void main() {
  late InMemoryKeyValueStorage storage;
  late WalletRepositoryImpl wallets;
  late TransactionRepositoryImpl transactions;
  late SavingsGoalRepositoryImpl goals;
  late GoalSplitMemory memory;

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    wallets = WalletRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    goals = SavingsGoalRepositoryImpl(storage: storage);
    memory = GoalSplitMemory(storage: storage);
    for (final w in const [
      Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 100000000, currentBalance: 100000000),
      Wallet(id: 'wa', name: 'Darurat', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
      Wallet(id: 'wb', name: 'Liburan', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
      Wallet(id: 'wc', name: 'Rumah', iconKey: 'walletSavings', initialBalance: 0, currentBalance: 0),
    ]) {
      await wallets.saveWallet(w);
    }
    final created = DateTime(2026, 11);
    await goals.saveGoals([
      SavingsGoal(id: 'a', name: 'Darurat', targetAmount: 1000000000, iconKey: 'walletSavings', walletId: 'wa', createdAt: created),
      SavingsGoal(id: 'b', name: 'Liburan', targetAmount: 1000000000, iconKey: 'walletSavings', walletId: 'wb', createdAt: created),
      SavingsGoal(
        id: 'c',
        name: 'Rumah',
        targetAmount: 1000000000,
        iconKey: 'walletSavings',
        walletId: 'wc',
        createdAt: created,
        status: SavingsGoalStatus.archived,
      ),
    ]);
  });

  RecordBloc buildBloc() => RecordBloc(
    budgetItemCatalog: stubBudgetItemCatalog(),
    createCategory: CreateCategory(repository: CategoryRepositoryImpl(storage: InMemoryKeyValueStorage())),
    recurringRepository: RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
    recurringChanges: RecurringChanges(),
    walletRepository: wallets,
    transactionRepository: transactions,
    savingsGoals: goals,
    splitMemory: memory,
    recordTransaction: RecordTransaction(
      ledgerChanges: LedgerChanges(),
      transactionRepository: transactions,
      recomputeWalletBalances: RecomputeWalletBalances(walletRepository: wallets, transactionRepository: transactions),
    ),
  );

  Future<int> balanceOf(String id) async =>
      (await wallets.listWallets()).getOrElse((_) => []).firstWhere((w) => w.id == id).currentBalance;

  test('memuat hanya tujuan Active dan persen terakhir', () async {
    await memory.save({'a': 70, 'b': 30});
    final bloc = buildBloc()..add(const RecordWalletsLoaded());
    await bloc.stream.firstWhere((s) => !s.isLoading);

    expect(bloc.state.activeGoals.map((g) => g.id), ['a', 'b']);
    expect(bloc.state.rememberedSplit, {'a': 70, 'b': 30});
    await bloc.close();
  });

  test('satu transfer per tujuan, jumlahnya tepat total, persen diingat', () async {
    final bloc = buildBloc()..add(const RecordWalletsLoaded());
    await bloc.stream.firstWhere((s) => !s.isLoading);

    bloc.add(
      SplitTransferRecorded(
        fromWalletId: 'bca',
        amount: 10000001,
        percents: const {'a': 60, 'b': 40},
        date: DateTime(2026, 11, 18),
        note: 'gajian',
      ),
    );
    await bloc.stream.firstWhere((s) => s.saveCount == 1);

    final recorded = (await transactions.listTransactionsInMonth(DateTime(2026, 11))).getOrElse((_) => []);
    expect(recorded, hasLength(2));
    expect(recorded.every((t) => t is TransferTransaction && t.fromWalletId == 'bca' && t.note == 'gajian'), isTrue);
    expect(await balanceOf('wa'), 6000001);
    expect(await balanceOf('wb'), 4000000);
    expect(await balanceOf('bca'), 100000000 - 10000001);
    expect((await memory.read()).getOrElse((_) => {}), {'a': 60, 'b': 40});
    await bloc.close();
  });
}
