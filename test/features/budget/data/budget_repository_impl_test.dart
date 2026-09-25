import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late BudgetRepositoryImpl repository;

  final budget = Budget(
    id: 'b1',
    name: 'Rumah tangga',
    walletId: 'bca',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 9),
    items: const [
      BudgetItem(id: 'mingguan', name: 'Belanja mingguan', quantity: 4, unitPrice: 57660000),
      BudgetItem(id: 'bulanan', name: 'Belanja bulanan', enteredAmount: 76210000),
    ],
  );

  List<Budget> read(Either<Failure, List<Budget>> result) =>
      result.getOrElse((_) => throw StateError('expected Right'));

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = BudgetRepositoryImpl(storage: storage);
  });

  group('BudgetRepositoryImpl', () {
    test('daftar anggaran kosong sebelum ada yang disimpan', () async {
      expect(read(await repository.listBudgets()), isEmpty);
    });

    test('menyimpan lalu membaca mengembalikan nilai yang sama, termasuk pos yang dirinci', () async {
      await repository.saveBudget(budget);
      final budgets = read(await repository.listBudgets());
      expect(budgets.single, budget);
      expect(budgets.single.items.first.plannedAmount, 230640000);
    });

    test('menyimpan ulang id sama menimpa di posisi semula, bukan menambah', () async {
      await repository.saveBudget(budget);
      await repository.saveBudget(
        Budget(
          id: 'b2',
          name: 'Belanja',
          walletId: 'gopay',
          period: BudgetPeriod.weekly,
          startDate: DateTime(2026, 9, 7),
        ),
      );
      await repository.saveBudget(budget.copyWith(isArchived: true));

      final budgets = read(await repository.listBudgets());
      expect(budgets.map((b) => b.id), ['b1', 'b2']);
      expect(budgets.first.isArchived, isTrue);
    });

    test('menghapus anggaran', () async {
      await repository.saveBudget(budget);
      await repository.deleteBudget('b1');
      expect(read(await repository.listBudgets()), isEmpty);
    });

    test('membuat dan mengarsipkan anggaran tidak mengubah saldo dompet mana pun', () async {
      final wallets = WalletRepositoryImpl(storage: storage);
      const bca = Wallet(
        id: 'bca',
        name: 'BCA',
        iconKey: 'walletBank',
        initialBalance: 500000000,
        currentBalance: 500000000,
      );
      await wallets.saveWallet(bca);

      await repository.saveBudget(budget);
      await repository.saveBudget(budget.copyWith(isArchived: true));

      final after = (await wallets.listWallets()).getOrElse((_) => throw StateError('expected Right'));
      expect(after.single, bca);
    });
  });
}
