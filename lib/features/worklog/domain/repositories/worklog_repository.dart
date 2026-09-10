import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';

/// Kontrak akses data buku jam. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class WorklogRepository {
  /// Seluruh buku (terbuka dan tertutup) milik sumber ber-`id` [sourceId],
  /// terurut dari yang terlama.
  Future<Either<Failure, List<BillingBook>>> listBooks(String sourceId);

  /// Menambah [entry] untuk sumber ber-`id` [sourceId]: menyambung ke buku
  /// terbuka kalau ada dan `entry.startsNewBook` false, atau memulai buku
  /// baru kalau `entry.startsNewBook` true atau belum ada buku terbuka
  /// (FR-TIME-001, FR-TIME-002). Mengembalikan buku yang menerima entri ini.
  Future<Either<Failure, BillingBook>> addEntry({required String sourceId, required WorkLogEntry entry});

  /// Menyimpan [book] apa adanya — dipakai use case penutupan buku dan
  /// penandaan penyuntikan, yang sudah menyiapkan salinan `close()`/
  /// `markInjected()`-nya sendiri.
  Future<Either<Failure, Unit>> saveBook(BillingBook book);
}
