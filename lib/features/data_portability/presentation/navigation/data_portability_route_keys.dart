import 'dart:typed_data';

import 'package:navigation/navigation.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';

// Satu-satunya berkas fitur `data_portability` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input alur pulihkan: isi berkas yang sudah dipilih, atau kosong untuk
/// "Kembalikan data sebelum pemulihan" ([source] `undo`).
final class RestoreInput extends RouteInput {
  /// Membuat [RestoreInput].
  const RestoreInput({this.bytes, this.source = RestoreKind.account});

  /// Isi berkas cadangan; `null` untuk `undo`.
  final Uint8List? bytes;

  /// Asal alur.
  final RestoreKind source;
}

/// Input halaman "Data dipulihkan".
final class RestoreDoneInput extends RouteInput {
  /// Membuat [RestoreDoneInput].
  const RestoreDoneInput(this.report);

  /// Keterangan pemulihan yang baru selesai.
  final RestoreReport report;
}

/// Kunci rute fitur `data_portability`.
abstract final class DataPortabilityRouteKeys {
  /// Pulihkan dari cadangan: pratinjau, penggantian, proses (`Pulihkan.dc.html`).
  static const restore = RouteKey<RestoreInput>('dataPortability.restore');

  /// Halaman "Data dipulihkan" sesudah aplikasi dimulai ulang.
  static const restoreDone = RouteKey<RestoreDoneInput>('dataPortability.restoreDone');
}
