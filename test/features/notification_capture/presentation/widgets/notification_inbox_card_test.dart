import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/discovery/discovery.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_module.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/notification_inbox_card.dart';
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

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: ListView(children: [NotificationInboxCard(container: container)]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final card = find.byKey(const ValueKey('notification-inbox-card'));
  final action = find.byKey(const ValueKey('inbox-card-action'));

  testWidgets('platform tanpa dukungan (iOS): tidak ada apa pun', (tester) async {
    await pumpCard(tester);

    expect(card, findsNothing);
  });

  testWidgets('belum disetel: judul Nyalakan, tombol utama, tanpa kaki; ketuk membuka Mulai cepat', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.unset);
    await pumpCard(tester);

    expect(find.text(t.discovery.notification.button), findsOneWidget);
    expect(find.text(t.notificationCapture.accountEntryBody), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-card-head')), findsNothing);

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text(t.discovery.quickStart.title), findsOneWidget);
  });

  testWidgets('izin hilang: Catat dari notifikasi + Izinkan; pengungkapan lalu setelan sistem', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(
      FeatureState.permissionNeeded,
      activeCount: 2,
    );
    await pumpCard(tester);

    expect(find.text(t.discovery.notification.manage), findsOneWidget);
    expect(find.text(t.discovery.status.permissionNeeded), findsOneWidget);
    expect(find.text(t.discovery.allowAccess), findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text(t.notificationCapture.disclosureTitle), findsOneWidget);
    await tester.tap(find.text(t.notificationCapture.disclosureAccept));
    await tester.pumpAndSettle();
    expect(gateway.accessSettingsOpened, 1);
  });

  testWidgets('sakelar mati: Nyalakan membuka setelan', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.off, activeCount: 2);
    await pumpCard(tester);

    expect(find.text(t.discovery.notification.button), findsOneWidget);
    expect(find.text(t.discovery.status.off), findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text(t.notificationCapture.settingsTitle), findsWidgets);
  });

  testWidgets('aktif tanpa yang menunggu: jumlah aplikasi, kepala kartu membuka setelan; tanpa Cek; latar tenang', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 2);
    await pumpCard(tester);

    expect(find.text(t.discovery.notification.inboxTitle), findsOneWidget);
    expect(find.text(t.discovery.notification.activeApps(n: 2)), findsOneWidget);
    expect(action, findsNothing);
    expect(find.byKey(const ValueKey('inbox-card-head')), findsOneWidget);
    final background = tester.widget<Material>(find.descendant(of: card, matching: find.byType(Material)).first).color;
    expect(background, isNot(PixelTheme.light.extension<AppColors>()!.warningSoft));

    await tester.tap(find.byKey(const ValueKey('inbox-card-head')));
    await tester.pumpAndSettle();
    expect(find.text(t.notificationCapture.settingsTitle), findsWidgets);
  });

  testWidgets('aktif dengan tangkapan: Cek, pratinjau paling banyak dua, nominal tak terbaca ada Ajari pola', (
    tester,
  ) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 2);
    await store.saveInbox([entry('a', note: 'QRIS Toko'), entry('b', amount: null), entry('c')]);
    await pumpCard(tester);

    expect(find.text(t.notificationCapture.banner(n: 3)), findsOneWidget);
    expect(find.text(t.discovery.notification.check), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-preview-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-preview-b')), findsOneWidget);
    expect(find.byKey(const ValueKey('inbox-preview-c')), findsNothing);
    expect(find.text(t.discovery.notification.teachPattern), findsOneWidget);
    // Pratinjau hanya membaca: tidak ada tombol Simpan / Catat di Beranda.
    expect(find.text(t.notificationCapture.recordAction), findsNothing);
    expect(find.text(t.discovery.notification.activeApps(n: 2)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('inbox-teach-b')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPatternPage), findsOneWidget);
  });

  testWidgets('Cek membuka kotak masuk', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 1);
    await store.saveInbox([entry('a')]);
    await pumpCard(tester);

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text(t.notificationCapture.inboxTitle), findsWidgets);
  });

  testWidgets('setelan berubah: kartu ikut berubah tanpa dimuat ulang', (tester) async {
    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.unset);
    await pumpCard(tester);
    expect(find.text(t.discovery.notification.button), findsOneWidget);

    statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 1);
    statuses.notify();
    await tester.pumpAndSettle();

    expect(find.text(t.discovery.notification.inboxTitle), findsOneWidget);
  });

  group('analitik (FEATURE_DISCOVERY §9)', () {
    late List<AnalyticsEvent> events;

    setUp(() {
      events = [];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
    });

    testWidgets('belum disetel: quick_start dari Beranda', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.unset);
      await pumpCard(tester);

      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(
        events.first,
        DiscoveryEvents.notificationRowTapped(state: 'unset', surface: 'home', action: 'quick_start'),
      );
    });

    testWidgets('izin hilang dan sakelar mati: manage dengan state-nya', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.permissionNeeded);
      await pumpCard(tester);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        events.single,
        DiscoveryEvents.notificationRowTapped(state: 'permission', surface: 'home', action: 'manage'),
      );
    });

    testWidgets('aktif: Kelola dan Ajari pola tercatat; Cek tidak', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 2);
      await store.saveInbox([entry('b', amount: null)]);
      await pumpCard(tester);

      await tester.tap(find.byKey(const ValueKey('inbox-teach-b')));
      await tester.pumpAndSettle();
      expect(
        events.single,
        DiscoveryEvents.notificationRowTapped(state: 'active', surface: 'home', action: 'teach_pattern'),
      );
    });

    testWidgets('parameter tanpa nama aplikasi atau isi notifikasi', (tester) async {
      statuses.status[DiscoveredFeature.notification] = const FeatureStatus(FeatureState.active, activeCount: 2);
      await store.saveInbox([entry('b', amount: null)]);
      await pumpCard(tester);
      await tester.tap(find.byKey(const ValueKey('inbox-teach-b')));
      await tester.pumpAndSettle();

      for (final event in events) {
        for (final value in event.parameters.values) {
          expect('$value', isNot(contains('BRImo')));
          expect('$value', isNot(contains('Teks b')));
          expect('$value', isNot(contains('brimo')));
        }
      }
    });
  });
}
