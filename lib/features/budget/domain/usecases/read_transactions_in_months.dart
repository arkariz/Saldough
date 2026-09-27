import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Membaca transaksi dari dokumen bulan [months] saja, bukan seluruh riwayat
/// (keputusan KT-1, NFR-PERF-002). Transaksi hanya terhitung ke anggaran yang
/// periodenya mencakup tanggalnya, jadi bulan-bulan `Budget.months` sudah
/// cukup untuk menghitung progresnya dengan tepat.
final class ReadTransactionsInMonths {
  /// Membuat [ReadTransactionsInMonths].
  const ReadTransactionsInMonths(this._repository);

  final TransactionRepository _repository;

  /// Gabungan transaksi seluruh [months]; hanya tahun dan bulannya yang
  /// dipakai. Gagal kalau satu bulan saja gagal dibaca.
  Future<Either<Failure, List<Transaction>>> call(Iterable<DateTime> months) async {
    final keys = {for (final month in months) DateTime(month.year, month.month)};
    final results = await [for (final month in keys) _repository.listTransactionsInMonth(month)].wait;
    final transactions = <Transaction>[];
    for (final result in results) {
      switch (result) {
        case Left(:final value):
          return Left(value);
        case Right(:final value):
          transactions.addAll(value);
      }
    }
    return Right(transactions);
  }
}
