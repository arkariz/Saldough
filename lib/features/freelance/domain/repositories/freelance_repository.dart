import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';

/// Kontrak akses data freelance: proyek, worklog, dan pembayaran. Lihat
/// ADR-0005 — selalu `Either<Failure, T>`, tidak pernah `throw Failure`.
///
/// ⚠ Tidak satu pun operasi di sini menyentuh saldo dompet. Satu-satunya
/// jalan freelance ke saldo adalah `ReceiveFreelancePayment`, yang menulis
/// transaksi lewat `RecordTransaction`.
abstract interface class FreelanceRepository {
  /// Seluruh proyek.
  Future<Either<Failure, List<FreelanceProject>>> listProjects();

  /// Menyimpan [project] — menambah kalau `id` baru, menimpa kalau ada.
  Future<Either<Failure, Unit>> saveProject(FreelanceProject project);

  /// Menghapus proyek ber-`id` [id]. Pemanggil yang memastikan proyek itu
  /// belum punya entri (ADR-019).
  Future<Either<Failure, Unit>> deleteProject(String id);

  /// Seluruh entri worklog.
  Future<Either<Failure, List<WorklogEntry>>> listEntries();

  /// Menyimpan [entries] sekaligus dalam satu penulisan — menambah yang
  /// `id`-nya baru, menimpa yang sudah ada.
  Future<Either<Failure, Unit>> saveEntries(List<WorklogEntry> entries);

  /// Menghapus entri ber-`id` [id].
  Future<Either<Failure, Unit>> deleteEntry(String id);

  /// Seluruh pembayaran.
  Future<Either<Failure, List<FreelancePayment>>> listPayments();

  /// Menyimpan [payment] — menambah kalau `id` baru, menimpa kalau ada.
  Future<Either<Failure, Unit>> savePayment(FreelancePayment payment);

  /// Menghapus pembayaran ber-`id` [id].
  Future<Either<Failure, Unit>> deletePayment(String id);
}
