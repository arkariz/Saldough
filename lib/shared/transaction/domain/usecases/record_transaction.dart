import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/domain/ledger_changes.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/transaction_query.dart';
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
    required this.ledgerChanges,
  });

  /// Repository yang menyimpan buku besar.
  final TransactionRepository transactionRepository;

  /// Pemelihara `currentBalance`, dipanggil setelah [transactionRepository]
  /// berhasil ditulis.
  final RecomputeWalletBalances recomputeWalletBalances;

  /// Diberi tahu sekali sesudah transaksi DAN saldo dompetnya tertulis
  /// (ADR-030 §3.4) -- tidak saat gagal. `source` di [call]/[delete]
  /// diteruskan ke sinyal, supaya bloc penulis mengabaikan kejadiannya
  /// sendiri.
  final LedgerChanges ledgerChanges;

  /// Mencatat [transaction] baru, atau menyunting yang sudah ada.
  ///
  /// Beri [previousTransaction] saat menyunting — versi transaksi itu
  /// **sebelum** disunting. Dompet yang disentuh versi lama ikut dihitung
  /// ulang juga kalau berbeda dari versi baru, supaya tidak ada dompet yang
  /// saldonya jadi basi setelah, misalnya, dompet asal sebuah pengeluaran
  /// diganti. Biarkan `null` untuk transaksi baru.
  Future<Either<Failure, Unit>> call(Transaction transaction, {Transaction? previousTransaction, Object? source}) async {
    final saveResult = await transactionRepository.saveTransaction(
      transaction,
      previousDate: previousTransaction?.date,
    );
    return _announced(switch (saveResult) {
      Left(value: final failure) => left<Failure, Unit>(failure),
      Right() => await recomputeWalletBalances.forWallets({
          ...walletIdsOf(transaction),
          if (previousTransaction != null) ...walletIdsOf(previousTransaction),
        }),
    }, source);
  }

  /// Menghapus [transaction], lalu menghitung ulang dompet yang
  /// disentuhnya.
  Future<Either<Failure, Unit>> delete(Transaction transaction, {Object? source}) async {
    final deleteResult = await transactionRepository.deleteTransaction(transaction.id, transaction.date);
    return _announced(switch (deleteResult) {
      Left(value: final failure) => left<Failure, Unit>(failure),
      Right() => await recomputeWalletBalances.forWallets(walletIdsOf(transaction)),
    }, source);
  }

  Either<Failure, Unit> _announced(Either<Failure, Unit> result, Object? source) {
    if (result.isRight()) ledgerChanges.notifyChanged(source: source);
    return result;
  }
}
