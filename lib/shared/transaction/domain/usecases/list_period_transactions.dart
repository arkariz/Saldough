import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/transaction/domain/period_date.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';
import 'package:saldough/shared/transaction/domain/transaction_repository.dart';

/// Membaca transaksi yang mungkin menjadi anggota periode `from <= d < until`
/// (ADR-038 §3.5): dokumen bulan yang disentuh rentang itu ditambah
/// [periodAttributionDays] hari di kedua sisi, karena transaksi tertaut rutin
/// ikut tanggal kemunculannya (P-4). Hasilnya boleh memuat transaksi di luar
/// periode; penyaringnya `periodDateOf`.
///
/// Biayanya mengikuti lebar rentang (satu dokumen per bulan), bukan panjang
/// riwayat (NFR-PERF-002).
final class ListPeriodTransactions {
  /// Membuat [ListPeriodTransactions].
  const ListPeriodTransactions(this._repository);

  final TransactionRepository _repository;

  /// Transaksi dokumen bulan yang disentuh `[from, until)` ± batas atribusi.
  Future<Either<Failure, List<Transaction>>> call({required DateTime from, required DateTime until}) async {
    final first = DateTime(from.year, from.month, from.day - periodAttributionDays);
    final last = DateTime(until.year, until.month, until.day + periodAttributionDays);
    final all = <Transaction>[];
    for (var m = DateTime(first.year, first.month); m.isBefore(last); m = DateTime(m.year, m.month + 1)) {
      switch (await _repository.listTransactionsInMonth(m)) {
        case Left(:final value):
          return left(value);
        case Right(:final value):
          all.addAll(value);
      }
    }
    return right(all);
  }
}
