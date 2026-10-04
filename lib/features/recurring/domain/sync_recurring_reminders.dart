import 'package:saldough/features/recurring/domain/reminder_plan.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Menyusun ulang seluruh pengingat rutin (ADR-035 §3.8): saat aplikasi
/// dibuka atau kembali ke depan, dan tiap rutin atau buku besar berubah.
/// Sakelar global mati → semua pengingat dibatalkan.
///
/// Gagal membaca data tidak pernah membatalkan jadwal yang ada; jadwal
/// lama dibiarkan sampai penyusunan berikutnya berhasil.
final class SyncRecurringReminders {
  /// Membuat [SyncRecurringReminders].
  const SyncRecurringReminders({
    required this.scheduler,
    required this.settings,
    required this.rules,
    required this.transactions,
    this.clock = DateTime.now,
  });

  /// Penjadwal notifikasi.
  final ReminderScheduler scheduler;

  /// Sakelar global.
  final ReminderSettingsRepository settings;

  /// Rutin.
  final RecurringRuleRepository rules;

  /// Buku besar, untuk kemunculan yang sudah tercatat.
  final TransactionRepository transactions;

  /// Jam.
  final DateTime Function() clock;

  /// Menyusun ulang. Mengembalikan jumlah pengingat terjadwal, atau `null`
  /// bila tidak ada yang diubah karena pembacaan gagal.
  Future<int?> call() async {
    final enabled = (await settings.isEnabled()).fold((_) => null, (value) => value);
    if (enabled == null) return null;
    if (!enabled) {
      await scheduler.replaceAll(const []);
      return 0;
    }
    final now = clock();
    final allRules = (await rules.listRules()).fold((_) => null, (value) => value);
    if (allRules == null) return null;
    final ledger = <Transaction>[];
    for (final offset in const [0, 1, 2]) {
      final month = (await transactions.listTransactionsInMonth(
        DateTime(now.year, now.month + offset),
      )).fold((_) => null, (value) => value);
      if (month == null) return null;
      ledger.addAll(month);
    }
    final planned = planReminders(allRules, now: now, transactions: ledger);
    await scheduler.replaceAll(planned);
    return planned.length;
  }
}
