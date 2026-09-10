import 'package:navigation/navigation.dart';

/// Satu-satunya berkas yang boleh diimpor fitur lain dari `example_note`.
abstract final class ExampleNoteRouteKeys {
  ExampleNoteRouteKeys._();

  /// Daftar catatan contoh.
  static const list = RouteKey<EmptyInput>('example_note.list');
}
