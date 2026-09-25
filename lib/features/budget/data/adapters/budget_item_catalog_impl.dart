import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';

/// Implementasi port [BudgetItemCatalog] milik `record` dari data anggaran
/// (ADR-0009: port milik konsumen, implementasi di fitur penyedia, dikawat di
/// `RootModule`).
final class BudgetItemCatalogImpl implements BudgetItemCatalog {
  /// Membuat [BudgetItemCatalogImpl]. [now] bisa diganti di uji.
  BudgetItemCatalogImpl({required this._repository, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final BudgetRepository _repository;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, List<BudgetItemOption>>> listOptions() async {
    final now = _now();
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
              isActive: budget.statusAt(now) == BudgetStatus.active,
            ),
      ],
    );
  }
}
