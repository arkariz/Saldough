part of 'notification_settings_bloc.dart';

/// Event [NotificationSettingsBloc].
sealed class NotificationSettingsEvent {
  /// Membuat [NotificationSettingsEvent].
  const NotificationSettingsEvent();
}

/// Layar dibuka.
final class NotificationSettingsStarted extends NotificationSettingsEvent {
  /// Membuat [NotificationSettingsStarted].
  const NotificationSettingsStarted();
}

/// Kembali dari setelan sistem: cek ulang akses dan izin.
final class NotificationSettingsResumed extends NotificationSettingsEvent {
  /// Membuat [NotificationSettingsResumed].
  const NotificationSettingsResumed();
}

/// Fitur dinyalakan/dimatikan.
final class NotificationCaptureToggled extends NotificationSettingsEvent {
  /// Membuat [NotificationCaptureToggled].
  const NotificationCaptureToggled({required this.enabled});

  /// Nyala.
  final bool enabled;
}

/// Mode penyampaian diganti.
final class NotificationDeliveryChanged extends NotificationSettingsEvent {
  /// Membuat [NotificationDeliveryChanged].
  const NotificationDeliveryChanged(this.delivery);

  /// Mode baru.
  final NotificationDelivery delivery;
}

/// Tingkat otomatis diganti.
final class AutoRecordLevelChanged extends NotificationSettingsEvent {
  /// Membuat [AutoRecordLevelChanged].
  const AutoRecordLevelChanged(this.level);

  /// Tingkat baru.
  final AutoRecordLevel level;
}

/// Sakelar Catat otomatis diganti: mati = tinjau semua; nyala = tingkat
/// otomatis terakhir sebelum dimatikan (selama bloc ini hidup), bawaan
/// [AutoRecordLevel.whenComplete] (QA PR #43 F20).
final class AutoRecordToggled extends NotificationSettingsEvent {
  /// Membuat [AutoRecordToggled].
  const AutoRecordToggled({required this.on});

  /// Nyala atau mati.
  final bool on;
}

/// Sumber ditambah atau diubah.
final class NotificationSourceSaved extends NotificationSettingsEvent {
  /// Membuat [NotificationSourceSaved].
  const NotificationSourceSaved(this.source);

  /// Sumber.
  final NotificationSource source;
}

/// Sumber dihapus.
final class NotificationSourceRemoved extends NotificationSettingsEvent {
  /// Membuat [NotificationSourceRemoved].
  const NotificationSourceRemoved(this.packageName);

  /// Paket sumber.
  final String packageName;
}

/// Sampel debug diminta ulang (ADR-032 §3.6).
final class DebugSamplesRequested extends NotificationSettingsEvent {
  /// Membuat [DebugSamplesRequested].
  const DebugSamplesRequested();
}

/// Penyimpanan contoh notifikasi dinyalakan atau dimatikan (ADR-042 §3.2).
final class NotificationSamplesToggled extends NotificationSettingsEvent {
  /// Membuat [NotificationSamplesToggled].
  const NotificationSamplesToggled({required this.on});

  /// Nyala.
  final bool on;
}

/// Muat contoh notifikasi aplikasi [packageName].
final class NotificationSamplesRequested extends NotificationSettingsEvent {
  /// Membuat [NotificationSamplesRequested].
  const NotificationSamplesRequested(this.packageName);

  /// Paket aplikasi.
  final String packageName;
}
