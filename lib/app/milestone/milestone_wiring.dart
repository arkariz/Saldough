import 'dart:async';
import 'dart:developer' as developer;

import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:saldough/app/milestone/app_milestone_facts_source.dart';
import 'package:saldough/app/milestone/backup_recorded_gateway.dart';
import 'package:saldough/app/milestone/inbox_clear_tracker.dart';
import 'package:saldough/app/milestone/milestone_coordinator.dart';
import 'package:saldough/app/milestone/stamp_remote_switch.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/data_portability/domain/backup_gateway.dart';
import 'package:saldough/features/milestone/data/milestone_store_impl.dart';
import 'package:saldough/features/milestone/domain/repositories/milestone_ports.dart';
import 'package:saldough/features/milestone/domain/usecases/evaluate_milestones.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Mendaftarkan mesin tonggak di akar (ADR-046 §3.1). Dipanggil sesudah
/// repositori bersama, fitur kotak masuk, dan cadangan terdaftar. Pelacak
/// kotak masuk hanya dibuat bila fitur catat dari notifikasi terdaftar
/// (Android); tanpa itu fakta kotak masuk selalu salah.
void registerMilestone(GetIt container) {
  final captureStore = container.isRegistered<NotificationCaptureStore>()
      ? container<NotificationCaptureStore>()
      : null;
  final captureChanges = container.isRegistered<CaptureInboxChanges>()
      ? container<CaptureInboxChanges>()
      : null;
  final inbox = InboxClearTracker(
    storage: container<KeyValueStorage>(),
    store: captureStore,
    changes: captureChanges,
  );
  container
    ..registerSingleton<InboxClearTracker>(inbox)
    ..registerLazySingleton<MilestoneStore>(
      () => MilestoneStoreImpl(storage: container<KeyValueStorage>()),
    )
    ..registerLazySingleton<MilestoneFactsSource>(
      () => AppMilestoneFactsSource(
        wallets: container<WalletRepository>(),
        transactions: container<TransactionRepository>(),
        rules: container<RecurringRuleRepository>(),
        schedule: container<FinancialMonthPreferenceRepository>(),
        backup: container<BackupGateway>(),
        inbox: inbox,
      ),
    )
    ..registerLazySingleton<EvaluateMilestones>(
      () => EvaluateMilestones(
        store: container<MilestoneStore>(),
        facts: container<MilestoneFactsSource>(),
      ),
    )
    ..registerLazySingleton<MilestoneBookAccess>(() => container<MilestoneCoordinator>())
    ..registerLazySingleton<MilestoneCoordinator>(
      () => MilestoneCoordinator(
        evaluate: container<EvaluateMilestones>(),
        store: container<MilestoneStore>(),
        signals: _signals(container, captureChanges),
        disabledIds: firebaseStampDisabledIds,
      ),
    );
}

/// Gabungan sinyal yang berarti "fakta mungkin berubah": transaksi, rutin,
/// dan kotak masuk.
Stream<void> _signals(GetIt container, CaptureInboxChanges? captureChanges) {
  final controller = StreamController<void>.broadcast();
  container<LedgerChanges>().changes.listen((_) => controller.add(null));
  container<RecurringChanges>().changes.listen((_) => controller.add(null));
  captureChanges?.stream.listen((_) => controller.add(null));
  container<BackupRecorded>().stream.listen((_) => controller.add(null));
  return controller.stream;
}

/// Memulai pelacak kotak masuk dan koordinator evaluasi sesudah aplikasi
/// siap. Tidak menunda pembukaan layar pertama dan tidak melempar (G-5).
Future<void> startMilestones(GetIt container) async {
  if (!container.isRegistered<MilestoneCoordinator>()) return;
  try {
    await container<InboxClearTracker>().start();
    await container<MilestoneCoordinator>().start();
  } on Object catch (e, st) {
    developer.log(
      'Mesin tonggak gagal dimulai, dicoba lagi pada pembukaan berikutnya',
      error: e,
      stackTrace: st,
      name: 'Milestone',
    );
  }
}
