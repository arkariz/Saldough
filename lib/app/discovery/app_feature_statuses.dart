import 'dart:async';

import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';

/// [FeatureStatuses] di akar komposisi (ADR-030): membaca setelan dan izin
/// tiap fitur lewat port masing-masing, supaya Beranda, Rutin, dan Akun tidak
/// saling mengimpor fitur (FEATURE_DISCOVERY P-2).
final class AppFeatureStatuses implements FeatureStatuses {
  /// Membuat [AppFeatureStatuses].
  const AppFeatureStatuses({
    required this.captureGateway,
    required this.captureStore,
    required this.reminderSettings,
    required this.reminderScheduler,
    required this.changesSource,
  });

  /// Layanan notifikasi platform (dukungan dan akses notifikasi).
  final NotificationCaptureGateway captureGateway;

  /// Setelan Catat dari notifikasi.
  final NotificationCaptureStore captureStore;

  /// Sakelar global pengingat rutin.
  final ReminderSettingsRepository reminderSettings;

  /// Penjadwal pengingat (izin notifikasi).
  final ReminderScheduler reminderScheduler;

  /// Pemancar perubahan setelan.
  final FeatureStatusChanges changesSource;

  @override
  Stream<void> get changes => changesSource.stream;

  @override
  Future<FeatureStatus> read(DiscoveredFeature feature) => switch (feature) {
    DiscoveredFeature.notification => _notification(),
    DiscoveredFeature.reminder => _reminder(),
  };

  // Urutan: tanpa aplikasi sumber aktif = belum disetel (juga saat semua
  // sumber dihapus, §5.1); sakelar mati; akses dicabut; baru aktif.
  Future<FeatureStatus> _notification() async {
    if (!captureGateway.isSupported) return FeatureStatus.unsupported;
    final settings = (await captureStore.loadSettings()).fold((_) => null, (value) => value);
    final active = settings?.sources.where((source) => source.enabled).length ?? 0;
    if (settings == null || active == 0) return const FeatureStatus(FeatureState.unset);
    if (!settings.enabled) return FeatureStatus(FeatureState.off, activeCount: active);
    if (!await captureGateway.isAccessGranted()) {
      return FeatureStatus(FeatureState.permissionNeeded, activeCount: active);
    }
    return FeatureStatus(FeatureState.active, activeCount: active);
  }

  Future<FeatureStatus> _reminder() async {
    final enabled = (await reminderSettings.isEnabled()).fold((_) => false, (value) => value);
    if (!enabled) return const FeatureStatus(FeatureState.off);
    if (!await reminderScheduler.hasPermission()) return const FeatureStatus(FeatureState.permissionNeeded);
    return const FeatureStatus(FeatureState.active);
  }
}
