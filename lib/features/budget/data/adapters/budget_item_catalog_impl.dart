import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';

/// Implementasi port [BudgetItemCatalog] milik `record` dari data anggaran
/// (ADR-0009: port milik konsumen, implementasi di fitur penyedia, dikawat di
/// `RootModule`).
final class BudgetItemCatalogImpl implements BudgetItemCatalog {
  /// Membuat [BudgetItemCatalogImpl].
  const BudgetItemCatalogImpl({required this._repository});

  final BudgetRepository _repository;

  @override
  Future<Either<Failure, List<BudgetItemOption>>> listOptions() async {
    return (await _repository.listBudgets()).map(
      (budgets) => [
        for (final budget in budgets)
          for (final item in budget.items)
            BudgetItemOption(
              budgetId: budget.id,
              budgetName: budget.name,
              itemId: item.id,
              itemName: item.name,
              walletId: budget.walletId,
              startDate: budget.startDate,
              endDate: budget.endDate,
              isArchived: budget.isArchived,
              transferToWalletId: item.targetWalletId,
            ),
      ],
    );
  }
}
