import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/features/recurring/domain/sync_recurring_reminders.dart';

/// Menyalakan pengingat rutin dari tombol permanen (FEATURE_DISCOVERY P-1):
/// meminta izin notifikasi sistem, menyalakan sakelar global, lalu menyusun
/// ulang jadwal. Alur yang sama dengan sakelar di Akun. Ditolak = sakelar
/// tidak berubah.
final class EnableReminders {
  /// Membuat [EnableReminders].
  const EnableReminders({required this.scheduler, required this.settings, required this.sync});

  /// Penjadwal (izin).
  final ReminderScheduler scheduler;

  /// Sakelar global.
  final ReminderSettingsRepository settings;

  /// Penyusun jadwal.
  final SyncRecurringReminders sync;

  /// `true` bila izin diberikan dan sakelar menyala.
  Future<bool> call() async {
    if (!await scheduler.requestPermission()) return false;
    if ((await settings.setEnabled(enabled: true)).isLeft()) return false;
    await sync();
    return true;
  }
}
