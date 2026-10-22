import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
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

  @override
  Future<Either<Failure, ExportData>> load() => guard(() async {
    final txs = await _ok(transactions.listAllTransactions());
    final wallet = await _ok(wallets.listWallets());
    final category = await _ok(categories.listCategories());
    final options = await _ok(budgets.listOptions());
    final rule = await _ok(rules.listRules());
    final projects = await _ok(freelance.listProjects());
    final payments = await _ok(freelance.listPayments());

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
    );
  });

  // `Failure` bukan Exception; `RepositoryGuard.guard` meneruskannya apa adanya.
  // ignore: only_throw_errors
  Future<T> _ok<T>(Future<Either<Failure, T>> result) async => (await result).getOrElse((f) => throw f);
}
