import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/grocery/data/models/grocery_plan_model.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';

StorageKey _planKey(String id) => StorageKey(namespace: 'grocery', name: id);

/// Implementasi [GroceryPlanRepository] di atas [KeyValueStorage], satu
/// dokumen per `id` (bulan) — pola yang sama seperti `CycleRepositoryImpl`,
/// bukan lagi dokumen singleton seperti `CycleTemplateRepositoryImpl`.
final class GroceryPlanRepositoryImpl with RepositoryGuard implements GroceryPlanRepository {
  /// Membuat [GroceryPlanRepositoryImpl] di atas [_storage].
  const GroceryPlanRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<GroceryPlanModel> _store(String id) => StoredValue<GroceryPlanModel>.json(
        key: _planKey(id),
        fromJson: GroceryPlanModel.fromJson,
        toJson: (m) => m.toJson(),
        storage: _storage,
      );

  @override
  Future<Either<Failure, GroceryPlan>> getPlan(String id) => guard(() async {
        final model = await _store(id).read();
        if (model != null) return model.toEntity();
        // Belum pernah disunting untuk bulan ini -- salin daftar item bulan
        // SEBELUMNYA (kalau ada) supaya pemilik tidak mengetik ulang daftar
        // belanja tiap bulan (keputusan pemilik). Sengaja TIDAK ditulis ke
        // [id] di sini -- baru tersimpan sungguhan saat `savePlan` pertama
        // dipanggil, sama seperti siklus baru yang masih kosong di memori
        // sampai baris pertamanya disimpan (`CycleBloc._loadCycle`).
        final previous = await _store(_previousMonthId(id)).read();
        if (previous == null) return .empty(id);
        return GroceryPlan(
          id: id,
          weeklyItems: previous.toEntity().weeklyItems,
          monthlyItems: previous.toEntity().monthlyItems,
          weeksPerMonth: previous.weeksPerMonth,
        );
      });

  @override
  Future<Either<Failure, Unit>> savePlan(GroceryPlan plan) => guardVoid(() async {
        await _store(plan.id).write(GroceryPlanModel.fromEntity(plan));
      });

  /// Kebalikan `RollOverCycle._nextCycleId` (fitur `cycle`) — duplikasi kecil
  /// yang sudah jadi pola di proyek ini untuk aritmetika `YYYY-MM` (lihat
  /// juga `_currentCycleId` yang berulang di beberapa berkas), bukan hal
  /// yang perlu disatukan lewat util bersama untuk dua baris logika.
  static String _previousMonthId(String cycleId) {
    final parts = cycleId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final previousMonth = month == 1 ? 12 : month - 1;
    final previousYear = month == 1 ? year - 1 : year;
    return '$previousYear-${previousMonth.toString().padLeft(2, '0')}';
  }
}
