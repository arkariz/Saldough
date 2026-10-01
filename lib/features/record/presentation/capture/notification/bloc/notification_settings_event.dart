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

/// Sumber ditambah atau diubah.
final class NotificationSourceSaved extends NotificationSettingsEvent {
  /// Membuat [NotificationSourceSaved].
  const NotificationSourceSaved(this.source);

  /// Sumber.
  final NotificationSource source;
}

/// Sumber dihapus (pola pengguna untuk paketnya ikut dihapus).
final class NotificationSourceRemoved extends NotificationSettingsEvent {
  /// Membuat [NotificationSourceRemoved].
  const NotificationSourceRemoved(this.packageName);

  /// Paket sumber.
  final String packageName;
}

/// Pola bawaan diaktifkan/dinonaktifkan.
final class BuiltInPatternToggled extends NotificationSettingsEvent {
  /// Membuat [BuiltInPatternToggled].
  const BuiltInPatternToggled({required this.patternId, required this.enabled});

  /// Id pola bawaan.
  final String patternId;

  /// Aktif.
  final bool enabled;
}

/// Pola pengguna disimpan.
final class NotificationPatternSaved extends NotificationSettingsEvent {
  /// Membuat [NotificationPatternSaved].
  const NotificationPatternSaved(this.pattern);

  /// Pola.
  final NotificationPattern pattern;
}

/// Pola pengguna dihapus.
final class NotificationPatternDeleted extends NotificationSettingsEvent {
  /// Membuat [NotificationPatternDeleted].
  const NotificationPatternDeleted(this.patternId);

  /// Id pola.
  final String patternId;
}

/// Muat ulang sampel debug.
final class DebugSamplesRequested extends NotificationSettingsEvent {
  /// Membuat [DebugSamplesRequested].
  const DebugSamplesRequested();
}
