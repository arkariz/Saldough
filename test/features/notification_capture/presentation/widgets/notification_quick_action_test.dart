import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_module.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/notification_quick_action.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import '../../../../helpers/fake_feature_statuses.dart';
import '../../../../helpers/fake_notification_capture_gateway.dart';
import '../../../../helpers/routes.dart';

void main() {
  // Gerbang Plus (ADR-041 §3.8): uji ini menguji perilaku Plus.
  setUp(() => ActivePlan.notifier.value = const PlusPlan(source: PlanSource.prelaunch));
  tearDown(ActivePlan.reset);

  late GetIt container;
  late FakeNotificationCaptureGateway gateway;
  late NotificationCaptureStore store;
  late FakeFeatureStatuses statuses;

  setUpAll(registerEffectHandlers);

  setUp(() {
    final storage = InMemoryKeyValueStorage();
    gateway = FakeNotificationCaptureGateway();
    statuses = FakeFeatureStatuses();
    container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<KeyValueStorage>(storage)
      ..registerSingleton<WalletRepository>(WalletRepositoryImpl(storage: storage))
      ..registerSingleton<TransactionRepository>(TransactionRepositoryImpl(storage: storage))
      ..registerSingleton<LedgerChanges>(LedgerChanges())
      ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(storage: storage))
      ..registerSingleton<FeatureStatuses>(statuses);
    NotificationCaptureModule.register(container, gateway: gateway);
    store = container<NotificationCaptureStore>();
  });

  CaptureInboxEntry entry(String id, {int? amount = 5000000, String note = ''}) => CaptureInboxEntry(
    id: id,
    packageName: 'id.co.bri.brimo',
    appLabel: 'BRImo',
    text: 'Teks $id',
    capturedAt: DateTime(2026, 10, 19, 10, 30),
    draft: RecordDraft(kind: DraftKind.expense, amountSen: amount, note: note),
  );

  Future<void> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: Row(
              children: [Expanded(child: NotificationQuickAction(container: container))],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('tile aksi cepat Notifikasi', () {
    testWidgets('belum disetel: ketuk membuka Mulai cepat; tanpa lencana', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.unset);
      await pumpTile(tester);

      expect(find.text(t.home.actionNotification), findsOneWidget);
      expect(find.byType(DsBadge), findsNothing);
      await tester.tap(find.byKey(const ValueKey('home-action-notification')));
      await tester.pumpAndSettle();
      expect(find.text(t.discovery.quickStart.title), findsOneWidget);
    });

    testWidgets('aktif dengan tangkapan: lencana jumlah; ketuk membuka kotak masuk, tidak mencatat', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 1);
      await store.saveInbox([entry('a'), entry('b')]);
      await pumpTile(tester);

      expect(find.widgetWithText(DsBadge, '2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('home-action-notification')));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.inboxTitle), findsWidgets);
      expect(
        (await container<TransactionRepository>().listTransactionsInMonth(DateTime.now())).getOrElse((_) => []),
        isEmpty,
      );
    });

    testWidgets('aktif tanpa tangkapan: tanpa lencana, tetap ke kotak masuk', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 1);
      await pumpTile(tester);

      expect(find.byType(DsBadge), findsNothing);
      await tester.tap(find.byKey(const ValueKey('home-action-notification')));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.inboxTitle), findsWidgets);
    });

    testWidgets('sakelar mati: ketuk membuka setelan', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.off, activeCount: 1);
      await pumpTile(tester);

      await tester.tap(find.byKey(const ValueKey('home-action-notification')));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.settingsTitle), findsOneWidget);
    });
  });
}
