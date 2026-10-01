import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/built_in_notification_patterns.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pola yang dicoba untuk satu tangkapan (ADR-032 §3.3): pola pengguna, lalu
/// pola bawaan yang tidak dimatikan di [settings]. Pola pengguna yang gagal
/// dibaca = hanya pola bawaan.
Future<List<NotificationPattern>> loadActivePatterns(
  NotificationCaptureStore store,
  NotificationCaptureSettings settings,
) async => [
  ...(await store.loadPatterns()).getOrElse((_) => const []),
  for (final p in builtInNotificationPatterns)
    if (!settings.disabledBuiltInPatternIds.contains(p.id)) p,
];

/// Dompet aktif yang boleh mengisi draf. Gagal dibaca = tanpa dompet (draf
/// tetap tersusun, dompetnya kosong).
Future<List<Wallet>> loadActiveWallets(WalletRepository repository) async =>
    (await repository.listWallets()).getOrElse((_) => const []).where((w) => w.isActive).toList();
