part of 'backup_bloc.dart';

/// Peristiwa lembar cadangkan.
sealed class BackupEvent {
  /// Membuat [BackupEvent].
  const BackupEvent();
}

/// Lembar dibuka: hitung ringkasan.
final class BackupStarted extends BackupEvent {
  /// Membuat [BackupStarted].
  const BackupStarted();
}

/// Tombol Cadangkan.
final class BackupRequested extends BackupEvent {
  /// Membuat [BackupRequested].
  const BackupRequested();
}

/// Tombol Batal saat cadangan dibuat.
final class BackupCancelRequested extends BackupEvent {
  /// Membuat [BackupCancelRequested].
  const BackupCancelRequested();
}

/// Tombol "Simpan ke…".
final class BackupSaveRequested extends BackupEvent {
  /// Membuat [BackupSaveRequested].
  const BackupSaveRequested();
}

/// Tombol "Bagikan".
final class BackupShareRequested extends BackupEvent {
  /// Membuat [BackupShareRequested].
  const BackupShareRequested();
}
