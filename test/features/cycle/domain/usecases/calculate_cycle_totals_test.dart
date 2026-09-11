import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line.dart';
import 'package:saldough/features/cycle/domain/entities/budget_line_kind.dart';
import 'package:saldough/features/cycle/domain/entities/income_line.dart';
import 'package:saldough/features/cycle/domain/entities/investment_plan.dart';
import 'package:saldough/features/cycle/domain/entities/monthly_cycle.dart';
import 'package:saldough/features/cycle/domain/usecases/calculate_cycle_totals.dart';

void main() {
  final calculate = CalculateCycleTotals();

  MonthlyCycle cycleWith({required int income, required int budget}) {
    return MonthlyCycle(
      id: '2026-09',
      incomeLines: [IncomeLine(id: 'i1', label: 'Pemasukan', amount: income)],
      budgetLines: [
        BudgetLine(
          id: 'b1',
          label: 'Anggaran',
          amount: budget,
          kind: BudgetLineKind.manual,
        ),
      ],
      investmentPlan: InvestmentPlan.empty(),
    );
  }

  group('CalculateCycleTotals', () {
    test('sisa positif: 15.839.563 - 13.382.490 = 2.457.073', () {
      final totals = calculate(
        cycleWith(income: 1583956300, budget: 1338249000),
      );

      expect(totals.totalIncome, 1583956300);
      expect(totals.totalBudget, 1338249000);
      expect(totals.remainder, 245707300);
      expect(totals.isOverBudget, isFalse);
    });

    test('sisa negatif: 8.900.000 - 10.237.042 = -1.337.042', () {
      final totals = calculate(
        cycleWith(income: 890000000, budget: 1023704200),
      );

      expect(totals.remainder, -133704200);
      expect(totals.isOverBudget, isTrue);
    });

    test('jumlah beberapa baris pemasukan dan anggaran', () {
      final cycle = MonthlyCycle(
        id: '2026-09',
        incomeLines: const [
          IncomeLine(id: 'i1', label: 'Gaji', amount: 300000000),
          IncomeLine(id: 'i2', label: 'Freelance', amount: 50000000),
        ],
        budgetLines: [
          BudgetLine(
            id: 'b1',
            label: 'Kos',
            amount: 150000000,
            kind: BudgetLineKind.manual,
          ),
          BudgetLine(
            id: 'b2',
            label: 'Listrik',
            amount: 20000000,
            kind: BudgetLineKind.manual,
          ),
        ],
        investmentPlan: InvestmentPlan.empty(),
      );

      final totals = calculate(cycle);

      expect(totals.totalIncome, 350000000);
      expect(totals.totalBudget, 170000000);
      expect(totals.remainder, 180000000);
    });
  });
}
