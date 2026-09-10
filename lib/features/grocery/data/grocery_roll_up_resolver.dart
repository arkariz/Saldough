import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';
import 'package:saldough/features/grocery/domain/usecases/calculate_grocery_roll_up.dart';

/// Implementasi [RollUpResolver] (antarmuka milik fitur `cycle`) yang
/// menghitung baris `grocery` sungguhan dari [GroceryPlanRepository] —
/// menggantikan `UnavailableRollUpResolver` sesuai rencana ROADMAP.md
/// Fase 2. Baris `card` tetap `unavailable()` sampai Fase 4 bagian kartu
/// kredit selesai (di luar cakupan ronde ini).
final class GroceryRollUpResolver implements RollUpResolver {
  /// Membuat [GroceryRollUpResolver] di atas [_repository].
  GroceryRollUpResolver({required this._repository}) : _calculate = CalculateGroceryRollUp();

  final GroceryPlanRepository _repository;
  final CalculateGroceryRollUp _calculate;

  @override
  Future<RollUpResolution> resolve(RollUpSource source) async {
    if (source is! GroceryRollUpSource) return const RollUpResolution.unavailable();

    final result = await _repository.getPlan();
    return switch (result) {
      Left() => const RollUpResolution.unavailable(),
      Right(value: final plan) => RollUpResolution(amount: _calculate(plan), isAvailable: true),
    };
  }
}
