import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/wallet/domain/wallet.dart';

/// Menghitung saldo turunan sebuah [Wallet] dari `initialBalance` ditambah
/// seluruh transaksi yang menyentuhnya. Dart murni, tanpa I/O — lihat
/// DOMAIN_MODEL.md bagian "Dompet" untuk rumusnya.
///
/// Ini rumus yang sama dipakai `RecomputeWalletBalances` untuk membuktikan
/// `Wallet.currentBalance` tersimpan tidak melenceng (ADR-012).
final class CalculateWalletBalance {
  /// Membuat [CalculateWalletBalance].
  const CalculateWalletBalance();

  /// Menghitung saldo [wallet] dari `initialBalance` ditambah seluruh
  /// [transactions] yang menyentuhnya.
  ///
  /// [transactions] boleh berisi transaksi milik dompet lain — yang tidak
  /// menyentuh [wallet] diabaikan, supaya pemanggil bisa memberikan seluruh
  /// riwayat tanpa menyaring dulu.
  int call(Wallet wallet, List<Transaction> transactions) {
    var balance = wallet.initialBalance;
    for (final transaction in transactions) {
      switch (transaction) {
        case IncomeTransaction(:final walletId, :final amount):
          if (walletId == wallet.id) balance += amount;
        case ExpenseTransaction(:final walletId, :final amount):
          if (walletId == wallet.id) balance -= amount;
        case TransferTransaction(fromWalletId: final from, toWalletId: final to, amount: final amount):
          if (to == wallet.id) balance += amount;
          if (from == wallet.id) balance -= amount;
      }
    }
    return balance;
  }
}
