import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/plan/data/idle_money_average_impl.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

final class _NoBudgets implements PlanBudgetSource {
  @override
  Future<Either<Failure, List<PlanBudget>>> budgetsStartingIn(DateTime from, DateTime until) async => const Right([]);

  @override
  Future<Either<Failure, List<PlanBudget>>> scheduledBudgetsStartingIn(DateTime from, DateTime until) async =>
      const Right([]);
}

/// Rata-rata uang nganggur untuk skenario perkiraan tujuan (ADR-048 §3.6).
void main() {
  late TransactionRepositoryImpl transactions;
  late IdleMoneyAverageImpl idle;
  final today = DateTime(2026, 11, 18);

  setUp(() {
    transactions = TransactionRepositoryImpl(storage: InMemoryKeyValueStorage());
    idle = IdleMoneyAverageImpl(
      transactions: transactions,
      rules: RecurringRuleRepositoryImpl(storage: InMemoryKeyValueStorage()),
      budgets: _NoBudgets(),
      schedule: () => FinancialMonthSchedule.initial,
    );
  });

  test('tanpa catatan: null', () async {
    expect((await idle.averageBefore(today)).getOrElse((_) => -1), isNull);
  });

  test('rata-rata periode lengkap sejak catatan pertama; periode berjalan tidak ikut', () async {
    await transactions.saveTransaction(
      IncomeTransaction(id: 'i', date: DateTime(2026, 9, 2), amount: 1000000, note: '', walletId: 'bank'),
    );
    await transactions.saveTransaction(
      ExpenseTransaction(id: 'e', date: DateTime(2026, 10, 5), amount: 400000, note: '', walletId: 'bank'),
    );
    await transactions.saveTransaction(
      ExpenseTransaction(id: 'now', date: DateTime(2026, 11, 5), amount: 999999, note: '', walletId: 'bank'),
    );
    // Sep +1.000.000, Okt −400.000; Agu sebelum catatan pertama.
    expect((await idle.averageBefore(today)).getOrElse((_) => -1), 300000);
  });
}
