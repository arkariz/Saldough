import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_cycle_gateway.dart';

/// Implementasi [GroceryCycleGateway] (port milik fitur `grocery`) di atas
/// [CycleRepository] fitur ini sendiri — pola yang sama seperti
/// `CycleInvestmentGatewayImpl`, delegasi murni karena satu-satunya yang
/// dibutuhkan `grocery` adalah daftar `id` siklus (ADR-0009).
final class GroceryCycleGatewayImpl implements GroceryCycleGateway {
  /// Membuat [GroceryCycleGatewayImpl] di atas [_cycleRepository].
  const GroceryCycleGatewayImpl({required this._cycleRepository});

  final CycleRepository _cycleRepository;

  @override
  Future<Either<Failure, List<String>>> listCycleIds() =>
      _cycleRepository.listCycleIds();
}
