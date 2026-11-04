import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';

/// Aplikasi terpasang untuk daftar Mulai cepat (FEATURE_DISCOVERY §5.1),
/// urut nama. Tanpa daftar bank tertanam (ADR-044 §3.4): pengguna memilih
/// sendiri aplikasi yang notifikasinya mau dibaca, dibantu pencarian. Aplikasi
/// ini sendiri disisihkan.
List<InstalledApp> quickStartApps(Iterable<InstalledApp> installed, {String? ownPackage}) =>
    [
      for (final app in installed)
        if (app.packageName != ownPackage) app,
    ]..sort((a, b) {
      final byLabel = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      return byLabel != 0 ? byLabel : a.packageName.compareTo(b.packageName);
    });

/// Sumber baru untuk [app] dengan filter bawaan (ADR-032 §3.1) dan, bila
/// diketahui, [walletId] dompet bawaannya.
NotificationSource quickStartSource(InstalledApp app, {String? walletId}) => NotificationSource(
  packageName: app.packageName,
  appLabel: app.label,
  keywords: defaultNotificationKeywords,
  walletId: walletId,
);

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
