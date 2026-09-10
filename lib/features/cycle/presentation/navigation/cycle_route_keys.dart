import 'package:navigation/navigation.dart';

/// Input rute layar siklus — satu-satunya berkas yang boleh diimpor fitur
/// lain dari `cycle`.
final class CycleDetailInput extends RouteInput {
  /// Membuat [CycleDetailInput] untuk siklus ber-`id` [cycleId].
  const CycleDetailInput({required this.cycleId});

  /// Identitas siklus, format `YYYY-MM`.
  final String cycleId;
}

/// Kunci rute fitur `cycle`.
abstract final class CycleRouteKeys {
  CycleRouteKeys._();

  /// Layar siklus bulanan.
  static const detail = RouteKey<CycleDetailInput>('cycle.detail');
}
