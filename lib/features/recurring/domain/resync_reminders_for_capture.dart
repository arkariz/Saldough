import 'package:saldough/features/recurring/domain/reminder_plan.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/reminder_settings.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Menyesuaikan pengingat rutin dengan keputusan Catat lewat notifikasi
/// bertindak yang belum diterapkan ke buku besar (ADR-044 §3.5, T-26.12).
///
/// Dijalankan mesin tanpa layar (aplikasi tertutup) setiap keputusan Catat,
/// Batalkan, atau Catat semua. Tanpa ini pengingat "jatuh tempo hari ini"
/// tetap berbunyi untuk kemunculan yang sudah dicatat lewat tombol. Berbeda
/// dengan [SyncRecurringReminders] (menggantikan seluruh jadwal), ini hanya:
///
/// - membatalkan pengingat yang tidak lagi berlaku (kemunculan tercatat),
///   termasuk "siapkan dana" kemunculan itu;
/// - menjadwalkan ulang yang masih berlaku, supaya pengingat harian yang
///   isinya berkurang (atau pulih karena Batalkan) tampil dengan isi benar.
///
/// Pengingat siapkan dana tidak dibentuk ulang di sini (butuh perkiraan fitur
/// Rencana); aplikasi menyusunnya lagi saat dibuka.
final class ResyncRemindersForCapture {
  /// Membuat [ResyncRemindersForCapture].
  const ResyncRemindersForCapture({
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

  /// Buku besar.
  final TransactionRepository transactions;

  /// Jam.
  final DateTime Function() clock;

  /// [recorded]: kemunculan yang diputuskan Catat di jurnal (`ruleId`, tanggal
  /// kemunculan). Mengembalikan `false` bila tidak ada yang diubah (sakelar
  /// mati, atau pembacaan gagal).
  Future<bool> call(Iterable<({String ruleId, DateTime date})> recorded) async {
    final enabled = (await settings.isEnabled()).fold((_) => null, (value) => value);
    if (enabled != true) return false;
    final allRules = (await rules.listRules()).fold((_) => null, (value) => value);
    if (allRules == null) return false;
    final now = clock();
    final ledger = <Transaction>[];
    for (final offset in const [0, 1, 2]) {
      final month = (await transactions.listTransactionsInMonth(
        DateTime(now.year, now.month + offset),
      )).fold((_) => null, (value) => value);
      if (month == null) return false;
      ledger.addAll(month);
    }
    final keys = {for (final r in recorded) reminderPayload(r.ruleId, r.date)};
    final before = planReminders(allRules, now: now, transactions: ledger);
    final after = planReminders(allRules, now: now, transactions: ledger, recordedExternally: keys);
    final stillValid = {for (final r in after) r.id};
    await scheduler.cancel([
      for (final r in before)
        if (!stillValid.contains(r.id)) r.id,
      // Siapkan dana kemunculan yang sudah tercatat tidak perlu lagi.
      for (final key in keys) reminderId('fund|$key'),
    ]);
    await scheduler.schedule(after);
    return true;
  }
}
