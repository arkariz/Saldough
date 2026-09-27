import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/budget/data/adapters/budget_overview_source_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../../../helpers/mocks.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late BudgetRepositoryImpl budgets;
  late TransactionRepositoryImpl transactions;
  late BudgetOverviewSourceImpl source;
  final now = DateTime(2026, 9, 26);

  Budget budget(String id, {required DateTime start, bool archived = false, int amount = 100000000}) => Budget(
    id: id,
    name: id,
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: start,
    isArchived: archived,
    items: [BudgetItem(id: '$id-pos', name: 'Pos', enteredAmount: amount)],
  );

  ExpenseTransaction spend(String id, String itemId, int amount) => ExpenseTransaction(
    id: id,
    date: DateTime(2026, 9, 20),
    amount: amount,
    note: '',
    walletId: 'bca',
    budgetItemId: itemId,
  );

  BudgetOverview read(Either<Failure, BudgetOverview> result) =>
      result.getOrElse((_) => throw StateError('expected Right'));

  setUp(() {
    storage = InMemoryKeyValueStorage();
    budgets = BudgetRepositoryImpl(storage: storage);
    transactions = TransactionRepositoryImpl(storage: storage);
    source = BudgetOverviewSourceImpl(budgetRepository: budgets, transactionRepository: transactions, now: () => now);
  });

  test('tanpa anggaran aktif, seluruh angka nol', () async {
    expect(read(await source.activeBudgetOverview()), const BudgetOverview(activeCount: 0, plannedAmount: 0, spent: 0));
  });

  test('hanya anggaran aktif yang dijumlahkan; yang selesai dan diarsipkan diabaikan', () async {
    await budgets.saveBudget(budget('aktif', start: DateTime(2026, 9), amount: 306850000));
    await budgets.saveBudget(budget('aktif-2', start: DateTime(2026, 9, 15), amount: 50000000));
    await budgets.saveBudget(budget('selesai', start: DateTime(2026, 8)));
    await budgets.saveBudget(budget('arsip', start: DateTime(2026, 9), archived: true));
    await transactions.saveTransaction(spend('t1', 'aktif-pos', 57660000));
    await transactions.saveTransaction(spend('t2', 'aktif-2-pos', 60000000));
    await transactions.saveTransaction(spend('t3', 'selesai-pos', 99));
    await transactions.saveTransaction(spend('t4', 'arsip-pos', 99));

    final overview = read(await source.activeBudgetOverview());
    expect(overview.activeCount, 2);
    expect(overview.plannedAmount, 356850000);
    expect(overview.spent, 117660000);
    expect(overview.remaining, 239190000);
  });

  test('pemakaian melewati rencana membuat sisa negatif, tidak dipotong ke nol', () async {
    await budgets.saveBudget(budget('aktif', start: DateTime(2026, 9), amount: 100));
    await transactions.saveTransaction(spend('t1', 'aktif-pos', 150));

    expect(read(await source.activeBudgetOverview()).remaining, -50);
  });

  test('kegagalan membaca anggaran diteruskan sebagai Left, tidak dilempar', () async {
    final failing = MockBudgetRepository();
    when(failing.listBudgets).thenAnswer(
      (_) async => left(const SystemFailure(code: FailureCode.unknown, message: 'disk penuh')),
    );
    final result = await BudgetOverviewSourceImpl(
      budgetRepository: failing,
      transactionRepository: transactions,
      now: () => now,
    ).activeBudgetOverview();

    expect(result.isLeft(), isTrue);
  });
}
