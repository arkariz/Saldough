import 'dart:typed_data';

/// Hasil menyimpan atau membagikan berkas.
enum TransferOutcome {
  /// Berkas tersimpan atau dibagikan.
  done,

  /// Pengguna menutup lembar sistem tanpa menyimpan atau membagikan.
  cancelled,

  /// Dibagikan, tetapi penyedia tidak melapor apa yang dipilih pengguna
  /// (`ShareResultStatus.unavailable`). Jangan mengklaim tersimpan (ADR-040 §3.5).
  unconfirmed,
}

/// Menyimpan, membagikan, dan memilih berkas lewat lembar sistem (KT-E3, ADR-040
/// §3.8). Tidak butuh izin penyimpanan: Storage Access Framework (Android) dan
/// pemilih dokumen iOS. Berkas hanya meninggalkan perangkat lewat pilihan
/// pengguna di lembar itu.
abstract interface class FileTransfer {
  /// "Simpan ke…": pemilih lokasi sistem (termasuk Drive).
  Future<TransferOutcome> saveAs({required String fileName, required Uint8List bytes, required String mimeType});

  /// "Bagikan": lembar bagi sistem.
  Future<TransferOutcome> share({required String fileName, required Uint8List bytes, required String mimeType});

  /// Memilih satu berkas cadangan dan membaca isinya; `null` bila dibatalkan.
  Future<Uint8List?> pickBackup();
}
