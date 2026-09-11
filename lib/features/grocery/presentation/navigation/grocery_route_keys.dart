import 'package:navigation/navigation.dart';

/// Satu-satunya berkas yang boleh diimpor fitur lain dari `grocery`.
abstract final class GroceryRouteKeys {
  GroceryRouteKeys._();

  /// Layar rencana belanja.
  static const page = RouteKey<EmptyInput>('grocery.page');
}
