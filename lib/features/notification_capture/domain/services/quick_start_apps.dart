import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/services/built_in_notification_patterns.dart';

/// Aplikasi terpasang yang punya pola bawaan, urut nama, untuk daftar pendek
/// Mulai cepat (FEATURE_DISCOVERY §5.1). Pola bawaan berlaku per aplikasi
/// tanpa pola buatan pengguna, jadi aplikasi ini tidak butuh pembuat pola.
List<InstalledApp> quickStartApps(Iterable<InstalledApp> installed) =>
    [
      for (final app in installed)
        if (builtInNotificationApps.containsKey(app.packageName)) app,
    ]..sort((a, b) {
      final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      return byLabel != 0 ? byLabel : a.packageName.compareTo(b.packageName);
    });

/// Sumber baru untuk [app] dengan filter bawaan (ADR-032 §3.1).
NotificationSource quickStartSource(InstalledApp app) =>
    NotificationSource(packageName: app.packageName, appLabel: app.label, keywords: defaultNotificationKeywords);

/// Menggabungkan [picked] ke [existing]: sumber yang sudah ada dipertahankan
/// (filter dan dompetnya) dan dinyalakan; yang baru ditambahkan di akhir.
List<NotificationSource> mergeQuickStartSources(
  List<NotificationSource> existing,
  Iterable<NotificationSource> picked,
) {
  final result = [...existing];
  for (final source in picked) {
    final index = result.indexWhere((s) => s.packageName == source.packageName);
    if (index < 0) {
      result.add(source);
    } else if (!result[index].enabled) {
      final old = result[index];
      result[index] = NotificationSource(
        packageName: old.packageName,
        appLabel: old.appLabel,
        keywords: old.keywords,
        walletId: old.walletId,
        walletRules: old.walletRules,
      );
    }
  }
  return result;
}
