part of 'restore_bloc.dart';

/// Peristiwa alur pulihkan.
sealed class RestoreEvent {
  /// Membuat [RestoreEvent].
  const RestoreEvent();
}

/// Halaman dibuka: periksa berkas (atau cadangan pengaman).
final class RestoreStarted extends RestoreEvent {
  /// Membuat [RestoreStarted].
  const RestoreStarted({required this.bytes, required this.source});

  /// Isi berkas, `null` untuk `undo`.
  final Uint8List? bytes;

  /// Asal alur.
  final RestoreKind source;
}

/// "Pilih berkas lain" dari halaman galat.
final class RestoreOtherFileRequested extends RestoreEvent {
  /// Membuat [RestoreOtherFileRequested].
  const RestoreOtherFileRequested();
}

/// Pengguna menyetujui penggantian (tombol Ganti data di dialog).
final class RestoreConfirmed extends RestoreEvent {
  /// Membuat [RestoreConfirmed].
  const RestoreConfirmed();
}
