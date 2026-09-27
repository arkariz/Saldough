import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Implementasi port [BudgetOverviewSource] milik `home` dari data anggaran
/// (ADR-0009). Angkanya dihitung [CalculateBudgetProgress] yang sama dengan
/// layar Anggaran, jadi Beranda dan ringkasan di puncak layar Anggaran tidak
/// pernah berbeda.
///
/// ⚠ Seperti `BudgetBloc`, terpakai dihitung dari
/// [TransactionRepository.listAllTransactions] — tautan pos yang menentukan,
/// bukan bulan transaksinya.
final class BudgetOverviewSourceImpl implements BudgetOverviewSource {
  /// Membuat [BudgetOverviewSourceImpl]. [now] bisa diganti di uji.
  BudgetOverviewSourceImpl({
    required this._budgetRepository,
    required this._transactionRepository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;
  final DateTime Function() _now;

  @override
  Future<Either<Failure, BudgetOverview>> activeBudgetOverview() async {
    final now = _now();
    final List<Budget> budgets;
    switch (await _budgetRepository.listBudgets()) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        budgets = value.where((b) => b.statusAt(now) == BudgetStatus.active).toList();
    }
    if (budgets.isEmpty) return const Right(BudgetOverview(activeCount: 0, plannedAmount: 0, spent: 0));

    final List<Transaction> transactions;
    switch (await _transactionRepository.listAllTransactions()) {
      case Left(:final value):
        return Left(value);
      case Right(:final value):
        transactions = value;
    }
    const calculate = CalculateBudgetProgress();
    var planned = 0;
    var spent = 0;
    for (final budget in budgets) {
      final progress = calculate(budget, transactions, now: now);
      planned += progress.plannedAmount;
      spent += progress.spent;
    }
    return Right(BudgetOverview(activeCount: budgets.length, plannedAmount: planned, spent: spent));
  }
}
