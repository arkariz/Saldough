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
  ///
  /// Ditolak dengan [ValidationFailure] ber-`code` [occurrenceTakenCode]
  /// kalau `transaction.recurrence` menunjuk kemunculan yang sudah dicatat
  /// transaksi lain (invarian 15, ADR-034 §3.2).
  Future<Either<Failure, Unit>> call(Transaction transaction, {Transaction? previousTransaction, Object? source}) async {
    if (transaction.recurrence case final link?) {
      final taken = await _occurrenceTaken(transaction, link);
      if (taken case Left(value: final failure)) return left(failure);
      if (taken case Right(value: true)) {
        return left(
          const ValidationFailure(code: occurrenceTakenCode, message: 'Kemunculan rutin ini sudah tercatat.'),
        );
      }
    }
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

  /// Kode [ValidationFailure] saat kemunculan rutin sudah dicatat transaksi
  /// lain.
  static const occurrenceTakenCode = FailureCode('RECURRENCE_OCCURRENCE_TAKEN');

  /// Apakah transaksi lain (id berbeda) sudah menautkan kemunculan [link].
  ///
  /// Membaca dokumen bulan kemunculan beserta bulan sebelum dan sesudahnya,
  /// ditambah bulan transaksinya (ADR-012): transaksi yang mencatat
  /// kemunculan selalu bertanggal dekat kemunculannya.
  Future<Either<Failure, bool>> _occurrenceTaken(Transaction transaction, RecurrenceLink link) async {
    final day = link.occurrenceDate;
    final months = {
      for (final offset in const [-1, 0, 1]) DateTime(day.year, day.month + offset),
      DateTime(transaction.date.year, transaction.date.month),
    };
    for (final month in months) {
      final result = await transactionRepository.listTransactionsInMonth(month);
      switch (result) {
        case Left(value: final failure):
          return left(failure);
        case Right(value: final transactions):
          final clash = transactions.any(
            (t) => t.id != transaction.id && (t.recurrence?.sameOccurrence(link) ?? false),
          );
          if (clash) return right(true);
      }
    }
    return right(false);
  }

  Either<Failure, Unit> _announced(Either<Failure, Unit> result, Object? source) {
    if (result.isRight()) ledgerChanges.notifyChanged(source: source);
    return result;
  }
}
