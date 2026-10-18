import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/analysis/domain/summarize_period.dart';
import 'package:saldough/features/budget/data/adapters/plan_budget_source_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_kind.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// B-15 end-to-end (revisi 18 Okt 2026, QA T-19.7 A9): Analisis dan Rencana
/// memakai sumber anggaran yang sebenarnya (`PlanBudgetSourceImpl`), dengan
/// transfer Tabungan Rp1.000.000 tertaut **pos transfer**. Tidak ada selisih
/// yang sah: transfer tidak dihitung di kedua sisi (aturan 7, KT-R14).
void main() {
  int rp(int rupiah) => rupiah * 100;

  test(
    'transfer tertaut pos transfer: pos tidak masuk baris Anggaran Rencana dan total Analisis = Nyata Rencana',
    () async {
      final storage = InMemoryKeyValueStorage();
      final budgets = BudgetRepositoryImpl(storage: storage);
      final transactions = TransactionRepositoryImpl(storage: storage);
      await budgets.saveBudget(
        Budget(
          id: 'sep',
          name: 'September',
          walletId: 'bca',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9),
          items: [
            BudgetItem(id: 'belanja', name: 'Belanja', enteredAmount: rp(3068500)),
            BudgetItem(
              id: 'tabungan',
              name: 'Tabungan',
              enteredAmount: rp(1000000),
              kind: BudgetItemKind.transfer,
              targetWalletId: 'tabungan',
            ),
          ],
        ),
      );
      final sep = <Transaction>[
        ExpenseTransaction(
          id: 'e1',
          date: DateTime(2026, 9, 3, 9),
          amount: rp(3068500),
          note: '',
          walletId: 'bca',
          categoryId: 'belanja',
          budgetItemId: 'belanja',
        ),
        ExpenseTransaction(id: 'e2', date: DateTime(2026, 9, 20, 9), amount: rp(1245000), note: '', walletId: 'bca'),
        ExpenseTransaction(id: 'e3', date: DateTime(2026, 9, 15, 9), amount: rp(120000), note: '', walletId: 'bca'),
        TransferTransaction(
          id: 't1',
          date: DateTime(2026, 9, 26, 9),
          amount: rp(1000000),
          note: '',
          fromWalletId: 'bca',
          toWalletId: 'tabungan',
          budgetItemId: 'tabungan',
        ),
      ];
      for (final t in sep) {
        await transactions.saveTransaction(t);
      }

      final source = PlanBudgetSourceImpl(budgetRepository: budgets, transactionRepository: transactions);
      final planned = (await source.budgetsStartingIn(
        DateTime(2026, 9),
        DateTime(2026, 10),
      )).getOrElse((_) => const []);
      final lines = [for (final b in planned) ...b.lines];
      expect(lines.map((l) => l.itemId), ['belanja'], reason: 'pos transfer tidak diteruskan ke Rencana');

      final plan = monthPlan(
        const [],
        from: DateTime(2026, 9),
        until: DateTime(2026, 10),
        today: DateTime(2026, 9, 30),
        transactions: sep,
        budgetLines: lines,
      );
      final analysis = summarizePeriod(
        sep,
        from: DateTime(2026, 9),
        until: DateTime(2026, 10),
        kind: CategoryKind.expense,
        categoryOf: (_) => null,
      );

      expect(plan.budgetSpent, rp(3068500), reason: 'baris Anggaran kilas balik tidak memuat transfer');
      expect(plan.recordedRecurringOut + plan.budgetSpent + plan.unplannedOut, analysis.total);
      expect(analysis.total, rp(3068500 + 1245000 + 120000));
      expect(analysis.transfers.total, rp(1000000), reason: 'transfer tampil hanya sebagai keterangan');
    },
  );
}
