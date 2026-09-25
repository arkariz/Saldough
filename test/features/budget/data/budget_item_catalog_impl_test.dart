import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';

void main() {
  test('BudgetItemCatalogImpl memetakan tiap pos, dengan isActive dari status anggaran', () async {
    final repository = BudgetRepositoryImpl(storage: InMemoryKeyValueStorage());
    await repository.saveBudget(
      Budget(
        id: 'b1',
        name: 'Rumah tangga',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 9),
        plannedAmount: 100,
        items: const [
          BudgetItem(id: 'beras', name: 'Beras', enteredAmount: 50),
          BudgetItem(id: 'susu', name: 'Susu', enteredAmount: 50),
        ],
      ),
    );
    await repository.saveBudget(
      Budget(
        id: 'b2',
        name: 'Agustus',
        walletId: 'bca',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026, 8),
        plannedAmount: 100,
        items: const [BudgetItem(id: 'listrik', name: 'Listrik', enteredAmount: 100)],
      ),
    );

    final catalog = BudgetItemCatalogImpl(repository: repository, now: () => DateTime(2026, 9, 15));
    final options = (await catalog.listOptions()).getOrElse((_) => throw StateError('expected Right'));

    expect(options.map((o) => o.itemId), ['beras', 'susu', 'listrik']);
    expect(options.first.budgetName, 'Rumah tangga');
    expect(options.first.walletId, 'bca');
    expect(options.map((o) => o.isActive), [true, true, false]);
  });
}
