import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/record/domain/budget_item_catalog.dart';
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
final fallbackTransaction = ExpenseTransaction(id: '_fallback', date: DateTime(2026), amount: 1, note: '', walletId: '_fallback');

/// [BudgetItemCatalog] palsu yang selalu mengembalikan [options] -- cukup
/// untuk seluruh uji yang tidak menguji pos anggaran (daftar kosong), dan
/// untuk uji T-4.4 yang memberi pilihan sendiri.
class FakeBudgetItemCatalog implements BudgetItemCatalog {
  /// Membuat [FakeBudgetItemCatalog].
  const FakeBudgetItemCatalog([this.options = const []]);

  /// Pilihan yang dikembalikan [listOptions].
  final List<BudgetItemOption> options;

  @override
  Future<Either<Failure, List<BudgetItemOption>>> listOptions() async => Right(options);
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
  plannedAmount: 0,
);
