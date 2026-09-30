import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Mock [WalletRepository] (ADR-0010) -- dipakai lintas uji bloc `record`,
/// `transaction`, dan `wallet`.
class MockWalletRepository extends Mock implements WalletRepository {}

/// Mock [TransactionRepository] (ADR-0010) -- dipakai lintas uji bloc
/// `record`, `transaction`, dan `wallet`.
class MockTransactionRepository extends Mock implements TransactionRepository {}

/// Dompet netral untuk [registerFallbackValue] -- nilai isinya tidak
/// penting, hanya bentuknya yang dibutuhkan `mocktail` sebagai placeholder
/// untuk matcher `any()` pada argumen `Wallet`.
const fallbackWallet = Wallet(
  id: '_fallback',
  name: '_fallback',
  iconKey: 'walletCash',
  initialBalance: 0,
  currentBalance: 0,
);

/// Transaksi netral untuk [registerFallbackValue] -- placeholder `any()`
/// pada argumen bertipe `Transaction` (mis. `saveTransaction`).
final fallbackTransaction = ExpenseTransaction(
  id: '_fallback',
  date: DateTime(2026),
  amount: 1,
  note: '',
  walletId: '_fallback',
);

/// Mock [BudgetItemCatalog] (ADR-0010).
class MockBudgetItemCatalog extends Mock implements BudgetItemCatalog {}

/// [BudgetItemCatalog] yang selalu mengembalikan [options] -- cukup untuk
/// uji yang tidak menguji pos anggaran (daftar kosong), dan untuk uji T-4.4
/// yang memberi pilihan sendiri.
MockBudgetItemCatalog stubBudgetItemCatalog([List<BudgetItemOption> options = const []]) {
  final catalog = MockBudgetItemCatalog();
  when(catalog.listOptions).thenAnswer((_) async => Right(options));
  return catalog;
}

/// Mock [BudgetRepository] (ADR-0010) -- uji bloc `budget`.
class MockBudgetRepository extends Mock implements BudgetRepository {}

/// Anggaran netral untuk [registerFallbackValue] -- placeholder `any()` pada
/// argumen bertipe `Budget` (mis. `saveBudget`).
final fallbackBudget = Budget(
  id: '_fallback',
  name: '_fallback',
  walletId: '_fallback',
  period: BudgetPeriod.monthly,
  startDate: DateTime(2026),
);

/// Mock [BudgetOverviewSource] (ADR-0010).
class MockBudgetOverviewSource extends Mock implements BudgetOverviewSource {}

/// [BudgetOverviewSource] untuk uji yang membuka shell tanpa menguji
/// Beranda: [overview] tetap, bawaannya tanpa anggaran aktif.
MockBudgetOverviewSource stubBudgetOverviewSource([
  BudgetOverview overview = const BudgetOverview(activeCount: 0, plannedAmount: 0, spent: 0),
]) {
  final source = MockBudgetOverviewSource();
  when(source.activeBudgetOverview).thenAnswer((_) async => Right(overview));
  return source;
}

/// Mock [FreelanceOverviewSource] (ADR-0010).
class MockFreelanceOverviewSource extends Mock implements FreelanceOverviewSource {}

/// [FreelanceOverviewSource] dengan [overview] tetap, bawaannya `null`
/// (tanpa pembayaran tertunda).
MockFreelanceOverviewSource stubFreelanceOverviewSource([FreelanceOverview? overview]) {
  final source = MockFreelanceOverviewSource();
  when(source.freelanceOverview).thenAnswer((_) async => Right(overview));
  return source;
}

/// [WalletRepository] yang `listWallets()`-nya SELALU gagal -- pembacaan
/// yang gagal, bukan daftar yang memang kosong.
MockWalletRepository failingWalletRepository() {
  final repository = MockWalletRepository();
  when(repository.listWallets).thenAnswer(
    (_) async => const Left(
      SystemFailure(code: FailureCode('TEST_FORCED_FAILURE'), message: 'dipaksa gagal untuk uji'),
    ),
  );
  return repository;
}
