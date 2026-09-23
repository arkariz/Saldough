import 'package:mocktail/mocktail.dart';
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
