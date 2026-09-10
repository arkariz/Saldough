import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

/// Kontrak akses data [GroceryPlan]. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class GroceryPlanRepository {
  /// Membaca rencana belanja. `Right` selalu terisi — [GroceryPlan.empty]
  /// kalau belum pernah disimpan (pola sama seperti `CycleTemplateRepository`).
  Future<Either<Failure, GroceryPlan>> getPlan();

  /// Menyimpan [plan], menimpa yang ada.
  Future<Either<Failure, Unit>> savePlan(GroceryPlan plan);
}
