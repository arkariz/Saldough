/// Port notifikasi lokal pengingat rutin (ADR-035 §3.8). Implementasinya di
/// atas `flutter_local_notifications`; uji memakai tiruan.
library;

import 'package:saldough/features/recurring/domain/reminder_plan.dart';

/// Ketukan pada notifikasi pengingat: [payload] dari `PlannedReminder`, dan
/// [recordAction] bila yang diketuk aksi **Catat**.
typedef ReminderResponse = ({String? payload, bool recordAction});

/// Penjadwal pengingat.
abstract interface class ReminderScheduler {
  /// Menyiapkan plugin; ketukan yang membuka aplikasi dikembalikan sekali.
  Future<ReminderResponse?> initialize();

  /// Ketukan selama aplikasi hidup.
  Stream<ReminderResponse> get responses;

  /// Meminta izin notifikasi (Android 13+, iOS). `true` bila diizinkan.
  Future<bool> requestPermission();

  /// Mengganti seluruh pengingat terjadwal dengan [reminders]. Daftar
  /// kosong membatalkan semuanya.
  Future<void> replaceAll(List<PlannedReminder> reminders);
}
