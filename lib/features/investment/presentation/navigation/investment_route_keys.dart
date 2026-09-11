import 'package:navigation/navigation.dart';

/// Satu-satunya berkas yang boleh diimpor fitur lain dari `investment`.
abstract final class InvestmentRouteKeys {
  InvestmentRouteKeys._();

  /// Layar investasi.
  static const page = RouteKey<EmptyInput>('investment.page');
}
