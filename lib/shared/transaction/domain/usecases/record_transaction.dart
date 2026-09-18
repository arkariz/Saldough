import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/transaction_repository.dart';
import 'package:saldough/shared/transaction/domain/usecases/recompute_wallet_balances.dart';

/// Mencatat, menyunting, atau menghapus satu [Transaction], lalu menjaga
/// `Wallet.currentBalance` seluruh dompet yang terdampak tetap sesuai.
///
/// **Urutan penulisan mengikat** (lihat
/// [ADR-012](../../../../docs/02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md)):
/// dokumen transaksi ditulis lebih dulu, dokumen dompet menyusul.
/// `Transaction` adalah kebenaran; `Wallet.currentBalance` cuma cache-nya.
final class RecordTransaction {
  /// Membuat [RecordTransaction].
  const RecordTransaction({
    required this.transactionRepository,
    required this.recomputeWalletBalances,
  });

  /// Repository yang menyimpan buku besar.
  final TransactionRepository transactionRepository;

  /// Pemelihara `currentBalance`, dipanggil setelah [transactionRepository]
  /// berhasil ditulis.
  final RecomputeWalletBalances recomputeWalletBalances;

  /// Mencatat [transaction] baru, atau menyunting yang sudah ada.
  ///
  /// Beri [previousTransaction] saat menyunting — versi transaksi itu
  /// **sebelum** disunting. Dompet yang disentuh versi lama ikut dihitung
  /// ulang juga kalau berbeda dari versi baru, supaya tidak ada dompet yang
  /// saldonya jadi basi setelah, misalnya, dompet asal sebuah pengeluaran
  /// diganti. Biarkan `null` untuk transaksi baru.
  Future<Either<Failure, Unit>> call(Transaction transaction, {Transaction? previousTransaction}) async {
    final saveResult = await transactionRepository.saveTransaction(
      transaction,
      previousDate: previousTransaction?.date,
    );
    return switch (saveResult) {
      Left(value: final failure) => left(failure),
      Right() => recomputeWalletBalances.forWallets({
          ..._walletIdsOf(transaction),
          if (previousTransaction != null) ..._walletIdsOf(previousTransaction),
        }),
    };
  }

  /// Menghapus [transaction], lalu menghitung ulang dompet yang
  /// disentuhnya.
  Future<Either<Failure, Unit>> delete(Transaction transaction) async {
    final deleteResult = await transactionRepository.deleteTransaction(transaction.id, transaction.date);
    return switch (deleteResult) {
      Left(value: final failure) => left(failure),
      Right() => recomputeWalletBalances.forWallets(_walletIdsOf(transaction)),
    };
  }

  Set<String> _walletIdsOf(Transaction transaction) => switch (transaction) {
        IncomeTransaction(:final walletId) => {walletId},
        ExpenseTransaction(:final walletId) => {walletId},
        TransferTransaction(fromWalletId: final from, toWalletId: final to) => {from, to},
      };
}
