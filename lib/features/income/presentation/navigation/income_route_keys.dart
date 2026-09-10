import 'package:navigation/navigation.dart';

/// Satu-satunya berkas yang boleh diimpor fitur lain dari `income`.
abstract final class IncomeRouteKeys {
  IncomeRouteKeys._();

  /// Daftar sumber pemasukan.
  static const list = RouteKey<EmptyInput>('income.list');
}
