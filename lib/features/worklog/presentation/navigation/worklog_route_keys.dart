import 'package:navigation/navigation.dart';

/// Satu-satunya berkas yang boleh diimpor fitur lain dari `worklog`.
abstract final class WorklogRouteKeys {
  WorklogRouteKeys._();

  /// Layar catatan jam kerja dan buku jam.
  static const page = RouteKey<EmptyInput>('worklog.page');
}
