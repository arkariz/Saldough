import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';

/// Cara tangkapan notifikasi disampaikan ke pengguna (ADR-032 §3.7).
enum NotificationDelivery {
  /// Hanya kotak masuk dan kartu Beranda.
  inboxOnly,

  /// Notifikasi Tanukonomy per tangkapan, plus kotak masuk.
  reminderAndInbox,
}

/// Seberapa berani tangkapan dicatat tanpa ditinjau (ADR-032 §3.4).
enum AutoRecordLevel {
  /// Tidak ada yang dicatat otomatis.
  reviewAll,

  /// Otomatis bila nominal, jenis, dompet, dan kategori terisi tanpa masalah.
  whenComplete,

  /// Otomatis bila nominal dan dompet yakin; kategori boleh kosong.
  whenAmountAndWallet,
}

/// Setelan Catat dari notifikasi.
final class NotificationCaptureSettings extends Equatable {
  /// Membuat [NotificationCaptureSettings].
  const NotificationCaptureSettings({
    this.enabled = false,
    this.delivery = NotificationDelivery.inboxOnly,
    this.autoRecordLevel = AutoRecordLevel.reviewAll,
    this.sources = const [],
    this.disabledBuiltInPatternIds = const {},
  });

  /// Pengguna menyalakan fitur ini (izin akses sistem dicek terpisah).
  final bool enabled;

  /// Mode penyampaian.
  final NotificationDelivery delivery;

  /// Tingkat otomatis.
  final AutoRecordLevel autoRecordLevel;

  /// Aplikasi yang didengarkan.
  final List<NotificationSource> sources;

  /// Pola bawaan yang dinonaktifkan pengguna.
  final Set<String> disabledBuiltInPatternIds;

  /// Sumber aktif untuk [packageName], atau `null`.
  NotificationSource? activeSource(String packageName) {
    for (final source in sources) {
      if (source.packageName == packageName && source.enabled) return source;
    }
    return null;
  }

  /// Salinan dengan field yang diganti.
  NotificationCaptureSettings copyWith({
    bool? enabled,
    NotificationDelivery? delivery,
    AutoRecordLevel? autoRecordLevel,
    List<NotificationSource>? sources,
    Set<String>? disabledBuiltInPatternIds,
  }) => NotificationCaptureSettings(
    enabled: enabled ?? this.enabled,
    delivery: delivery ?? this.delivery,
    autoRecordLevel: autoRecordLevel ?? this.autoRecordLevel,
    sources: sources ?? this.sources,
    disabledBuiltInPatternIds: disabledBuiltInPatternIds ?? this.disabledBuiltInPatternIds,
  );

  @override
  List<Object?> get props => [enabled, delivery, autoRecordLevel, sources, disabledBuiltInPatternIds];
}
