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

/// Pola diikat ke rutin [ruleId] (ADR-042 §3.4); [ruleId] `null` melepas
/// ikatan pola ini.
final class NotificationPatternBound extends NotificationSettingsEvent {
  /// Membuat [NotificationPatternBound].
  const NotificationPatternBound({
    required this.packageName,
    required this.patternId,
    required this.patternLabel,
    required this.ruleId,
  });

  /// Paket aplikasi pola.
  final String packageName;

  /// Id pola (bawaan atau pengguna).
  final String patternId;

  /// Nama pola, disimpan di ikatan untuk ditampilkan.
  final String patternLabel;

  /// Rutin tujuan, atau `null`.
  final String? ruleId;
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
