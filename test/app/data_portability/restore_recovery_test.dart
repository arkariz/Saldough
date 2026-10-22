import 'package:di/di.dart' show GetIt;
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/app/data_portability/app_backup_registry.dart';
import 'package:saldough/app/data_portability/restore_recovery.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/data_portability/data/restore_engine.dart';
import 'package:saldough/features/data_portability/domain/restore_models.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Penuntasan pemulihan di akar komposisi (ADR-040 §3.4 langkah 6).
void main() {
  late InMemoryKeyValueStorage live;
  late GetIt container;
  late RestoreEngine engine;

  Future<void> restore(RestoreKind kind) async {
    await engine.stage(incoming: <String, String>{}, kind: kind, backupCreatedAt: DateTime(2026, 10, 12));
    final outcome = await recoverRestoreJournal(engine);
    container.registerSingleton<RestoreRecoveryOutcome>(RestoreRecoveryOutcome(outcome));
    await markOnboardingDoneIfRestoring(container);
    await finishRestoreIfNeeded(container);
  }

  Future<bool> isOnboardingDone() async =>
      (await container<TutorialProgressRepository>().load()).getOrElse((_) => TutorialProgress.empty).onboardingDone;

  setUp(() {
    live = InMemoryKeyValueStorage();
    engine = RestoreEngine(
      live: live,
      staging: InMemoryKeyValueStorage(),
      registry: appBackupRegistry,
      now: () => DateTime(2026, 10, 22, 9),
    );
    container = GetIt.asNewInstance()
      ..registerSingleton<RestoreEngine>(engine)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: live))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: live))
      ..registerSingleton<TutorialProgressRepository>(TutorialProgressRepositoryImpl(storage: live));
  });

  test('pemulihan dari onboarding menandai onboarding selesai (progres tutorial tidak ikut cadangan)', () async {
    expect(await isOnboardingDone(), isFalse);
    await restore(RestoreKind.onboarding);
    expect(await isOnboardingDone(), isTrue);
  });

  test('pemulihan dari Akun tidak menyentuh progres onboarding', () async {
    await restore(RestoreKind.account);
    expect(await isOnboardingDone(), isFalse);
  });
}
