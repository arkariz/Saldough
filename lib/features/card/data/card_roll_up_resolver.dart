import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';

/// Implementasi [RollUpResolver] (antarmuka milik fitur `cycle`) yang
/// menghitung baris `card` sungguhan dari siklus tagihan yang sedang
/// terbuka — menggantikan `UnavailableRollUpResolver` sesuai rencana
/// ROADMAP.md Fase 2. Baris `grocery` di luar cakupan resolver ini (dibangun
/// di branch terpisah — lihat catatan integrasi di root_module.dart).
final class CardRollUpResolver implements RollUpResolver {
  /// Membuat [CardRollUpResolver] di atas [_repository].
  CardRollUpResolver({required this._repository});

  final CardStatementRepository _repository;

  @override
  Future<RollUpResolution> resolve(RollUpSource source) async {
    if (source is! CardRollUpSource) return const RollUpResolution.unavailable();

    final result = await _repository.getOpenStatement(source.cardId);
    return switch (result) {
      Left() => const RollUpResolution.unavailable(),
      Right(value: null) => const RollUpResolution.unavailable(),
      Right(value: final statement?) => RollUpResolution(amount: statement.confirmedTotal, isAvailable: true),
    };
  }
}
