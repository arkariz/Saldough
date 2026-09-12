import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

/// Kontrak akses data [GroceryPlan]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class GroceryPlanRepository {
  /// Membaca rencana belanja ber-`id` [id] (format `YYYY-MM`). `Right`
  /// selalu terisi, tidak pernah `null`:
  ///
  /// - Kalau [id] sudah pernah disimpan, dokumen itu yang dikembalikan.
  /// - Kalau belum, daftar item disalin dari bulan SEBELUMNYA (kalau ada) —
  ///   bukan dikosongkan — supaya pemilik tidak perlu mengetik ulang daftar
  ///   belanja tiap bulan. Salinan ini TIDAK otomatis tersimpan; baru
  ///   tertulis ke [id] ini saat [savePlan] pertama dipanggil untuknya.
  /// - Kalau bulan sebelumnya juga belum ada, [GroceryPlan.empty].
  Future<Either<Failure, GroceryPlan>> getPlan(String id);

  /// Menyimpan [plan] (di bawah `plan.id`), menimpa yang ada.
  Future<Either<Failure, Unit>> savePlan(GroceryPlan plan);
}
