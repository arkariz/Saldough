import 'package:navigation/navigation.dart';

/// Satu-satunya berkas yang boleh diimpor fitur lain dari `card`.
abstract final class CardRouteKeys {
  CardRouteKeys._();

  /// Layar kartu kredit.
  static const page = RouteKey<EmptyInput>('card.page');
}
