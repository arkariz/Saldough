import 'package:navigation/navigation.dart';

/// Input rute layar catatan jam kerja — satu-satunya berkas yang boleh
/// diimpor fitur lain dari `worklog`.
final class WorklogSourceInput extends RouteInput {
  /// Membuat [WorklogSourceInput], langsung memilih sumber ber-`id`
  /// [sourceId] kalau diisi.
  const WorklogSourceInput({this.sourceId});

  /// Sumber freelance yang langsung dipilih saat layar dibuka -- `null`
  /// jatuh balik ke sumber freelance pertama (perilaku lama, dipakai titik
  /// masuk generik di app bar `IncomeSourceListPage`). Diisi saat dicapai
  /// dari tombol milik satu sumber tertentu (laporan pemilik: sebelumnya
  /// selalu lompat ke sumber freelance PERTAMA walau pemilik menekan
  /// tombol milik sumber lain).
  final String? sourceId;
}

/// Kunci rute fitur `worklog`.
abstract final class WorklogRouteKeys {
  WorklogRouteKeys._();

  /// Layar catatan jam kerja dan buku jam.
  static const page = RouteKey<WorklogSourceInput>('worklog.page');
}
