import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/premium/domain/plus_moments.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// [PlusUsage] dari data fitur lain. Fitur `premium` tidak boleh mengimpor
/// `notification_capture`, jadi akar komposisi yang menyambungkannya
/// (ADR-030). Bacaan yang gagal dihitung nol, tidak pernah melempar.
final class AppPlusUsage implements PlusUsage {
  /// Membuat [AppPlusUsage].
  const AppPlusUsage({required this.notifications, required this.rules});

  /// Penyimpanan Catat dari notifikasi.
  final NotificationCaptureStore notifications;

  /// Rutin.
  final RecurringRuleRepository rules;

  @override
  Future<int> notificationSources() async {
    return (await notifications.loadSettings()).fold((_) => 0, (settings) => settings.sources.length);
  }

  @override
  Future<int> autoRecordRules() async {
    return (await rules.listRules()).fold((_) => 0, (all) => all.where((r) => r.autoRecord).length);
  }

  @override
  Future<int> autoRecordedSince(DateTime since) async {
    return (await notifications.loadAutoRecorded()).fold(
      (_) => 0,
      (entries) => entries.where((e) => !e.recordedAt.isBefore(since)).length,
    );
  }
}
