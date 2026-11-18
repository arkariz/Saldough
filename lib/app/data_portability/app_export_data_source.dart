import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/investment/investment.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// [ExportDataSource] di akar komposisi (ADR-030): membaca repositori
/// transaksi, dompet, kategori, anggaran, rutin, dan freelance, yang tidak
/// boleh diimpor langsung oleh fitur `data_portability`.
final class AppExportDataSource with RepositoryGuard implements ExportDataSource {
  /// Membuat [AppExportDataSource].
  const AppExportDataSource({
    required this.transactions,
    required this.wallets,
    required this.categories,
    required this.budgets,
    required this.rules,
    required this.freelance,
    required this.goals,
    this.investments,
  });

  /// Buku besar.
  final TransactionRepository transactions;

  /// Dompet.
  final WalletRepository wallets;

  /// Kategori.
  final CategoryRepository categories;

  /// Katalog pos anggaran.
  final BudgetItemCatalog budgets;

  /// Rutin.
  final RecurringRuleRepository rules;

  /// Freelance.
  final FreelanceRepository freelance;

  /// Tujuan tabungan untuk lembar Tujuan (ADR-048 §3.4).
  final SavingsGoalRepository goals;

  /// Instrumen dan valuasi untuk lembar Investasi dan Valuasi (ADR-049 §3.9).
  final InvestmentRepository? investments;

  @override
  Future<Either<Failure, ExportData>> load() => guard(() async {
    final txs = await _ok(transactions.listAllTransactions());
    final wallet = await _ok(wallets.listWallets());
    final category = await _ok(categories.listCategories());
    final options = await _ok(budgets.listOptions());
    final rule = await _ok(rules.listRules());
    final projects = await _ok(freelance.listProjects());
    final payments = await _ok(freelance.listPayments());
    final goal = await _ok(goals.listGoals());
    final instruments = investments == null ? const <Instrument>[] : await _ok(investments!.listInstruments());
    final valuations = investments == null ? const <InstrumentValuation>[] : await _ok(investments!.listValuations());

    final projectNames = {for (final p in projects) p.id: p.name};
    return ExportData(
      transactions: txs,
      wallets: wallet,
      categoryNames: {for (final c in category) c.id: c.name},
      budgetLabels: {for (final o in options) o.itemId: '${o.budgetName} › ${o.itemName}'},
      ruleNames: {for (final r in rule) r.id: r.note},
      freelanceProjectByPaymentId: {for (final p in payments) p.id: ?projectNames[p.projectId]},
      schedule: ActiveFinancialMonth.schedule,
      currency: ActiveCurrency.value,
      goals: goal,
      instruments: instruments,
      valuations: valuations,
    );
  });

  // `Failure` bukan Exception; `RepositoryGuard.guard` meneruskannya apa adanya.
  // ignore: only_throw_errors
  Future<T> _ok<T>(Future<Either<Failure, T>> result) async => (await result).getOrElse((f) => throw f);
}
