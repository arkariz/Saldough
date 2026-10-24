part of 'export_bloc.dart';

/// Peristiwa lembar ekspor.
sealed class ExportEvent {
  /// Membuat [ExportEvent].
  const ExportEvent();
}

/// Lembar dibuka: hitung ringkasan.
final class ExportStarted extends ExportEvent {
  /// Membuat [ExportStarted].
  const ExportStarted();
}

/// Pengguna memilih format.
final class ExportFormatChanged extends ExportEvent {
  /// Membuat [ExportFormatChanged].
  const ExportFormatChanged(this.format);

  /// Format terpilih.
  final ExportFormat format;
}

/// Tombol Ekspor.
final class ExportRequested extends ExportEvent {
  /// Membuat [ExportRequested].
  const ExportRequested();
}

/// Tombol Batal saat berkas disiapkan.
final class ExportCancelRequested extends ExportEvent {
  /// Membuat [ExportCancelRequested].
  const ExportCancelRequested();
}

/// Tombol "Simpan ke…".
final class ExportSaveRequested extends ExportEvent {
  /// Membuat [ExportSaveRequested].
  const ExportSaveRequested();
}

/// Tombol "Bagikan".
final class ExportShareRequested extends ExportEvent {
  /// Membuat [ExportShareRequested].
  const ExportShareRequested();
}
