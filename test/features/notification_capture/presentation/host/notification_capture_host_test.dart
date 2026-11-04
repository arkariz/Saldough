import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_module.dart';
import 'package:saldough/features/notification_capture/presentation/host/notification_capture_host.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_notification_capture_gateway.dart';

void main() {
  late FakeNotificationCaptureGateway gateway;
  late GetIt container;

  setUp(() {
    ActivePlan.reset();
    final storage = InMemoryKeyValueStorage();
    gateway = FakeNotificationCaptureGateway();
    container = GetIt.asNewInstance()
      ..registerSingleton<KeyValueStorage>(storage)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges())
      ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(storage: storage));
    NotificationCaptureModule.register(container, gateway: gateway);
    addTearDown(ActivePlan.reset);
  });

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationCaptureHost(container: container, child: const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('status Plus disalin ke native saat mulai (untuk mesin tanpa layar), Gratis tanpa batas', (tester) async {
    await pumpHost(tester);

    expect(gateway.syncedPlan, (false, null));
  });

  testWidgets('hak berubah: salinan ikut berubah; uji coba berlaku sampai awal hari sesudah hari terakhir', (
    tester,
  ) async {
    await pumpHost(tester);

    ActivePlan.notifier.value = TrialPlan(endsOn: DateTime(2026, 11, 10));
    await tester.pump();
    expect(gateway.syncedPlan, (true, DateTime(2026, 11, 11)));

    final until = DateTime(2027);
    ActivePlan.notifier.value = PlusPlan(source: PlanSource.prelaunch, until: until);
    await tester.pump();
    expect(gateway.syncedPlan, (true, until));

    ActivePlan.notifier.value = const FreePlan();
    await tester.pump();
    expect(gateway.syncedPlan, (false, null));
  });

  testWidgets('pendengar dilepas saat host dibuang', (tester) async {
    await pumpHost(tester);
    await tester.pumpWidget(const SizedBox());
    gateway.syncedPlan = null;

    ActivePlan.notifier.value = TrialPlan(endsOn: DateTime(2026, 11, 10));
    await tester.pump();

    expect(gateway.syncedPlan, isNull);
  });
}
