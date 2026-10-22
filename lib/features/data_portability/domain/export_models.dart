import 'dart:typed_data';

/// Format berkas ekspor (KT-E1).
enum ExportFormat {
  /// Excel; xlsx dua lembar.
  xlsx('xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),

  /// CSV transaksi saja.
  csv('csv', 'text/csv');

  const ExportFormat(this.extension, this.mimeType);

  /// Ekstensi berkas.
  final String extension;

  /// Tipe MIME untuk lembar simpan dan bagi.
  final String mimeType;
}

/// Ringkasan sebelum ekspor: "142 transaksi, 3 Jun – 22 Okt 2026".
final class ExportPreview {
  /// Membuat [ExportPreview].
  const ExportPreview({required this.count, required this.firstDate, required this.lastDate});

  /// Jumlah transaksi.
  final int count;

  /// Tanggal transaksi paling awal, `null` bila kosong.
  final DateTime? firstDate;

  /// Tanggal transaksi paling akhir, `null` bila kosong.
  final DateTime? lastDate;
}

/// Berkas ekspor yang siap disimpan atau dibagikan.
final class ExportFile {
  /// Membuat [ExportFile].
  const ExportFile({required this.name, required this.bytes, required this.format, required this.rowCount});

  /// Nama berkas, mis. `tanukonomy-ekspor-2026-10-22.xlsx`.
  final String name;

  /// Isi berkas.
  final Uint8List bytes;

  /// Format.
  final ExportFormat format;

  /// Jumlah transaksi di dalamnya.
  final int rowCount;
}

/// Penanda pembatalan kooperatif: dicek di antara tahap (baca → bangun →
/// simpan). Hasil yang selesai sesudah batal dibuang (ADR-040 §3.6).
final class ExportCancel {
  bool _cancelled = false;

  /// Apakah pengguna sudah membatalkan.
  bool get isCancelled => _cancelled;

  /// Membatalkan.
  void cancel() => _cancelled = true;
}
