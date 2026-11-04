import 'dart:ui' as ui;

import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_module.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/negative_shapes.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_auth_repository.dart';
import '../../../../helpers/fake_notification_capture_gateway.dart';
import '../../../../helpers/fake_plus_purchasing.dart';
import '../../../../helpers/routes.dart';

void main() {
  // Gerbang Plus (ADR-041 §3.8): uji ini menguji perilaku Plus.
  setUp(() => ActivePlan.notifier.value = const PlusPlan(source: PlanSource.prelaunch));
  tearDown(ActivePlan.reset);

  late GetIt container;
  late FakeNotificationCaptureGateway gateway;
  late NotificationCaptureStore store;
  late TransactionRepository ledger;
  late WalletRepository wallets;

  setUpAll(registerEffectHandlers);

  setUp(() async {
    final storage = InMemoryKeyValueStorage();
    gateway = FakeNotificationCaptureGateway();
    wallets = WalletRepositoryImpl(storage: storage);
    ledger = TransactionRepositoryImpl(storage: storage);
    container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(appRouteRegistry())
      ..registerSingleton<KeyValueStorage>(storage)
      ..registerSingleton<WalletRepository>(wallets)
      ..registerSingleton<TransactionRepository>(ledger)
      ..registerSingleton<LedgerChanges>(LedgerChanges())
      ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(storage: storage))
      ..registerSingleton<PlusPurchasing>(FakePlusPurchasing(selling: false))
      ..registerSingleton<AuthRepository>(FakeAuthRepository());
    NotificationCaptureModule.register(container, gateway: gateway);
    store = container<NotificationCaptureStore>();
    await wallets.saveWallet(
      const Wallet(id: 'bri', name: 'BRI', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
  });

  Future<void> open(WidgetTester tester, RouteKey<EmptyInput> key) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => context.pushRoute(key, const EmptyInput()),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  group('Mulai cepat (FEATURE_DISCOVERY §5.1)', () {
    const bri = InstalledApp(packageName: 'id.co.bri.brimo', label: 'BRImo');
    const gopay = InstalledApp(packageName: 'com.gojek.gopay', label: 'GoPay');
    const calculator = InstalledApp(packageName: 'com.android.calculator2', label: 'Kalkulator');

    Future<NotificationCaptureSettings> settings() async =>
        (await store.loadSettings()).getOrElse((_) => throw StateError(''));

    Future<void> resumeApp(WidgetTester tester) async {
      const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ].forEach(tester.binding.handleAppLifecycleStateChanged);
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, List<InstalledApp> apps) async {
      for (final app in apps) {
        final row = find.byKey(ValueKey('quick-start-${app.packageName}'));
        // Baris bawah bisa tertutup bilah Nyalakan: gulir dulu.
        await tester.ensureVisible(row);
        await tester.pumpAndSettle();
        await tester.tap(row);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('semua aplikasi terpasang ditawarkan, tidak ada yang tercentang bawaan (ADR-044 §3.4)', (
      tester,
    ) async {
      gateway.apps = const [gopay, calculator, bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      expect(find.text('BRImo'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      expect(find.text('Kalkulator'), findsOneWidget);
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(boxes, hasLength(3));
      expect(boxes.every((box) => !(box.value ?? true)), isTrue);
      // Tombol mati dengan alasan yang terbaca.
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on'))).onPressed, isNull);
      expect(find.text(t.discovery.quickStart.pickHint), findsOneWidget);
    });

    testWidgets('pencarian menyaring daftar tanpa membuang pilihan', (tester) async {
      gateway.apps = const [gopay, calculator, bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.enterText(find.byKey(const ValueKey('quick-start-search')), 'kalku');
      await tester.pumpAndSettle();
      expect(find.text('Kalkulator'), findsOneWidget);
      expect(find.text('BRImo'), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('quick-start-search')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.appsEmpty), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('quick-start-search')), '');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: find.byKey(const ValueKey('quick-start-id.co.bri.brimo')),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('Gratis melihat catatan batas satu aplikasi', (tester) async {
      gateway.apps = const [bri];
      ActivePlan.notifier.value = const FreePlan();
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      expect(find.text(t.discovery.quickStart.freeLimit), findsOneWidget);
    });

    testWidgets('Plus tidak melihat catatan batas', (tester) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      expect(find.text(t.discovery.quickStart.freeLimit), findsNothing);
    });

    testWidgets('akses sudah ada: Nyalakan menyimpan sumber, menyalakan fitur, dan menutup layar', (tester) async {
      gateway
        ..apps = const [gopay, bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri, gopay]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      final saved = await settings();
      expect(saved.enabled, isTrue);
      expect(saved.sources.map((s) => s.packageName), ['id.co.bri.brimo', 'com.gojek.gopay']);
      expect(gateway.configuredSources, hasLength(2));
      expect(find.text(t.discovery.quickStart.turnOn), findsNothing);
      expect(find.text('buka'), findsOneWidget);
    });

    testWidgets('satu dompet: dompetnya dipakai otomatis, tanpa pertanyaan (ADR-044 §3.4)', (tester) async {
      gateway
        ..apps = const [bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      expect(find.byKey(const ValueKey('quick-start-wallet-id.co.bri.brimo')), findsNothing);
      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect((await settings()).sources.single.walletId, 'bri');
    });

    testWidgets('beberapa dompet: tiap aplikasi ditanya dompetnya, tidak ditebak', (tester) async {
      await wallets.saveWallet(
        const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
      );
      gateway
        ..apps = const [bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      // Belum dipilih: Nyalakan mati dengan alasan.
      final picker = find.byKey(const ValueKey('quick-start-wallet-id.co.bri.brimo'));
      expect(picker, findsOneWidget);
      expect(find.text(t.discovery.quickStart.walletHint), findsOneWidget);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on'))).onPressed, isNull);

      await tester.ensureVisible(picker);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('BCA').last);
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on'))).onPressed, isNotNull);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect((await settings()).sources.single.walletId, 'bca');
    });

    testWidgets('gagal menyimpan: pesan galat terlihat dan layar bertahan', (tester) async {
      container
        ..unregister<NotificationCaptureStore>()
        ..registerSingleton<NotificationCaptureStore>(_SettingsFailingStore(store));
      gateway
        ..apps = const [bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect(find.text(t.common.genericErrorMessage), findsOneWidget);
      expect(find.text(t.discovery.quickStart.turnOn), findsOneWidget);
    });

    testWidgets('Plus: izin memunculkan notifikasi diminta sebelum ke setelan akses (notifikasi bertindak bawaan)', (
      tester,
    ) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect(gateway.reminderPermissionRequests, 1);
    });

    testWidgets('Gratis: izin notifikasi tidak diminta (notifikasi bukan bawaan bagi Gratis)', (tester) async {
      ActivePlan.notifier.value = const FreePlan();
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect(gateway.reminderPermissionRequests, 0);
    });

    testWidgets('aplikasi mana pun bisa dipilih, bukan hanya bank yang dikenal', (tester) async {
      gateway
        ..apps = const [calculator]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [calculator]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect((await settings()).sources.map((s) => s.packageName), ['com.android.calculator2']);
    });

    testWidgets('analitik: selesai mencatat jumlah aplikasi dan via quick_start, tanpa nama aplikasi', (tester) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      gateway
        ..apps = const [gopay, bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri, gopay]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect(events, [
        DiscoveryEvents.quickStartCompleted(appsCount: 2),
        DiscoveryEvents.featureEnabled(feature: 'notification', via: 'quick_start'),
      ]);
      expect(events.first.parameters, {'apps_count': 2});
    });

    testWidgets('analitik: akses diberikan sesudah kembali dari setelan sistem juga selesai satu kali', (tester) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);
      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.notificationCapture.disclosureAccept));
      await tester.pumpAndSettle();
      expect(events, isEmpty);

      gateway.accessGranted = true;
      await resumeApp(tester);

      expect(events.map((e) => e.name), ['quick_start_completed', 'feature_enabled']);
      expect(events.first.parameters, {'apps_count': 1});
    });

    testWidgets('aplikasi yang dicentang lalu dihapus tidak ikut disimpan', (tester) async {
      gateway
        ..apps = const [gopay, bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri, gopay]);

      await tester.tap(find.byKey(const ValueKey('quick-start-com.gojek.gopay')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect((await settings()).sources.map((s) => s.packageName), ['id.co.bri.brimo']);
    });

    testWidgets('tanpa centang dan tanpa sumber, Nyalakan nonaktif', (tester) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on'))).onPressed, isNull);

      await pick(tester, const [bri]);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on'))).onPressed, isNotNull);
      expect(find.text(t.discovery.quickStart.pickedCount(n: 1)), findsOneWidget);

      await pick(tester, const [bri]);
      expect(tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on'))).onPressed, isNull);
    });

    testWidgets('akses belum ada: pengungkapan dulu, lalu setelan sistem; kembali dengan akses menutup layar', (
      tester,
    ) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.disclosureTitle), findsOneWidget);
      expect(gateway.accessSettingsOpened, 0);
      // Sumber sudah tersimpan sebelum keluar ke setelan sistem.
      expect((await settings()).sources, hasLength(1));

      await tester.tap(find.text(t.notificationCapture.disclosureAccept));
      await tester.pumpAndSettle();
      expect(gateway.accessSettingsOpened, 1);
      expect(find.text(t.discovery.allowAccess), findsOneWidget);

      gateway.accessGranted = true;
      await resumeApp(tester);

      expect(find.text(t.discovery.allowAccess), findsNothing);
      expect(find.text('buka'), findsOneWidget);
    });

    testWidgets('kembali tanpa akses: layar bertahan dan tombol menjadi Izinkan', (tester) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.notificationCapture.disclosureAccept));
      await tester.pumpAndSettle();
      await resumeApp(tester);

      expect(find.text(t.discovery.allowAccess), findsOneWidget);
      expect(find.text('BRImo'), findsOneWidget);

      // Izinkan memakai ulang sumber yang tersimpan, tanpa menyimpan lagi.
      await tester.tap(find.text(t.discovery.allowAccess));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.disclosureTitle), findsOneWidget);
    });

    testWidgets('pengungkapan dibatalkan: tidak membuka setelan sistem, layar tetap', (tester) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);
      await pick(tester, const [bri]);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(gateway.accessSettingsOpened, 0);
      expect(find.text(t.discovery.allowAccess), findsOneWidget);
    });
  });

  group('setelan', () {
    testWidgets('menyalakan fitur menampilkan akses; pengungkapan jelas sebelum setelan sistem', (tester) async {
      await open(tester, NotificationCaptureRouteKeys.settings);
      expect(find.text(t.notificationCapture.accessMissingTitle), findsNothing);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect((await store.loadSettings()).getOrElse((_) => throw StateError('')).enabled, isTrue);
      expect(find.text(t.notificationCapture.accessMissingTitle), findsOneWidget);

      await tester.tap(find.text(t.notificationCapture.accessAction));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.disclosureTitle), findsOneWidget);
      expect(gateway.accessSettingsOpened, 0);
      await tester.tap(find.text(t.notificationCapture.disclosureAccept));
      await tester.pumpAndSettle();
      expect(gateway.accessSettingsOpened, 1);
    });

    testWidgets('analitik: menyalakan sakelar di setelan = feature_enabled via account', (tester) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      await open(tester, NotificationCaptureRouteKeys.settings);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(events, [DiscoveryEvents.featureEnabled(feature: 'notification', via: 'account')]);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(events, hasLength(1));
    });

    testWidgets('mode pengingat ditolak izinnya tetap kotak masuk saja', (tester) async {
      await store.saveSettings(
        const NotificationCaptureSettings(enabled: true, delivery: NotificationDelivery.inboxOnly),
      );
      await open(tester, NotificationCaptureRouteKeys.settings);

      final reminder = find.descendant(
        of: find.byKey(const ValueKey('notification-reminder')),
        matching: find.byType(Switch),
      );
      await tester.scrollUntilVisible(reminder, 200);
      await tester.ensureVisible(reminder);
      await tester.pumpAndSettle();
      await tester.tap(reminder);
      await tester.pumpAndSettle();
      expect(gateway.reminderPermissionRequests, 1);
      final settings = (await store.loadSettings()).getOrElse((_) => throw StateError(''));
      expect(settings.delivery, NotificationDelivery.inboxOnly);
    });

    group('notifikasi saat aplikasi tertutup (ADR-044 §3.5)', () {
      Finder reminderSwitch() =>
          find.descendant(of: find.byKey(const ValueKey('notification-reminder')), matching: find.byType(Switch));

      Future<bool> reminderOn(WidgetTester tester) async {
        await tester.scrollUntilVisible(reminderSwitch(), 200);
        return tester.widget<Switch>(reminderSwitch()).value;
      }

      testWidgets('Plus, bawaan: sakelar sudah menyala tanpa disentuh', (tester) async {
        await store.saveSettings(const NotificationCaptureSettings(enabled: true));
        await open(tester, NotificationCaptureRouteKeys.settings);

        expect(await reminderOn(tester), isTrue);
      });

      testWidgets('Gratis, bawaan: sakelar mati', (tester) async {
        ActivePlan.notifier.value = const FreePlan();
        await store.saveSettings(const NotificationCaptureSettings(enabled: true));
        await open(tester, NotificationCaptureRouteKeys.settings);

        expect(await reminderOn(tester), isFalse);
      });

      testWidgets('Plus mematikan: tersimpan sebagai mati (bukan kembali ke bawaan)', (tester) async {
        await store.saveSettings(const NotificationCaptureSettings(enabled: true));
        await open(tester, NotificationCaptureRouteKeys.settings);
        await reminderOn(tester);
        await tester.ensureVisible(reminderSwitch());
        await tester.pumpAndSettle();

        await tester.tap(reminderSwitch());
        await tester.pumpAndSettle();

        final settings = (await store.loadSettings()).getOrElse((_) => throw StateError(''));
        expect(settings.delivery, NotificationDelivery.inboxOnly);
        expect(settings.remindsWhenClosed(isPlus: true), isFalse);
        expect(gateway.configuredRemind, isFalse);
        expect(gateway.configuredAutoNotify, isFalse);
      });

      testWidgets('bawaan dikirim ke native sebagai otomatis, dengan teks notifikasi bertindak', (tester) async {
        await store.saveSettings(const NotificationCaptureSettings(enabled: true));
        await open(tester, NotificationCaptureRouteKeys.settings);
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();

        expect(gateway.configuredAutoNotify, isTrue);
        expect(gateway.configuredRemind, isFalse);
        final texts = gateway.configuredTexts!;
        expect(texts.actionRecord, t.notificationCapture.recordAction);
        expect(texts.actionDismiss, t.notificationCapture.dismissAction);
        expect(texts.actionUndo, t.notificationCapture.undoAction);
        expect(texts.recordedTitle, t.notificationCapture.actionableRecordedTitle);
        expect(texts.groupSummary, contains('{count}'));
        expect(texts.recordedMany, contains('{count}'));
      });
    });

    testWidgets('tingkat otomatis tersimpan dan sumber baru dikirim ke native', (tester) async {
      await store.saveSettings(const NotificationCaptureSettings(enabled: true));
      gateway.apps = const [InstalledApp(packageName: 'id.co.bri.brimo', label: 'BRImo')];
      await open(tester, NotificationCaptureRouteKeys.settings);

      final autoRecord = find.descendant(
        of: find.byKey(const ValueKey('notification-auto-record')),
        matching: find.byType(Switch),
      );
      await tester.scrollUntilVisible(autoRecord, 200);
      await tester.ensureVisible(autoRecord);
      await tester.pumpAndSettle();
      await tester.tap(autoRecord);
      await tester.pumpAndSettle();
      // Sub-sakelar tingkat 3 baru muncul sesudah Catat otomatis nyala.
      expect(find.byKey(const ValueKey('notification-auto-record-any-category')), findsOneWidget);
      await tester.scrollUntilVisible(find.text(t.notificationCapture.addSource), 200);
      await tester.tap(find.text(t.notificationCapture.addSource));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BRImo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.notificationCapture.save));
      await tester.pumpAndSettle();

      final settings = (await store.loadSettings()).getOrElse((_) => throw StateError(''));
      expect(settings.autoRecordLevel, AutoRecordLevel.whenComplete);
      expect(settings.sources.single.packageName, 'id.co.bri.brimo');
      expect(settings.sources.single.keywords, defaultNotificationKeywords);
      expect(gateway.configuredSources?.single.packageName, 'id.co.bri.brimo');
    });
  });

  group('sakelar setelan (QA PR #43 F15, F20)', () {
    testWidgets('tiap sakelar berlabel, bisa diketuk utuh, dan membawa status', (tester) async {
      await store.saveSettings(
        const NotificationCaptureSettings(enabled: true, autoRecordLevel: AutoRecordLevel.whenAmountAndWallet),
      );
      final handle = tester.ensureSemantics();
      await open(tester, NotificationCaptureRouteKeys.settings);
      for (final label in [
        t.notificationCapture.autoRecordLabel,
        t.notificationCapture.autoRecordAnyCategoryLabel,
        t.notificationCapture.reminderLabel,
      ]) {
        final node = find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));
        await tester.scrollUntilVisible(node, 200);
        final data = tester.getSemantics(node).getSemanticsData();
        expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
        expect(data.flagsCollection.isToggled, isNot(ui.Tristate.none), reason: label);
      }
      handle.dispose();
    });

    testWidgets('mematikan lalu menyalakan Catat otomatis memulihkan "walau kategori belum jelas"', (tester) async {
      await store.saveSettings(
        const NotificationCaptureSettings(enabled: true, autoRecordLevel: AutoRecordLevel.whenAmountAndWallet),
      );
      await open(tester, NotificationCaptureRouteKeys.settings);
      final autoRecord = find.byKey(const ValueKey('notification-auto-record'));
      await tester.scrollUntilVisible(autoRecord, 200);
      await tester.pumpAndSettle();
      Future<AutoRecordLevel> level() async =>
          (await store.loadSettings()).getOrElse((_) => throw StateError('')).autoRecordLevel;

      await tester.tap(autoRecord);
      await tester.pumpAndSettle();
      expect(await level(), AutoRecordLevel.reviewAll);
      await tester.tap(autoRecord);
      await tester.pumpAndSettle();
      expect(await level(), AutoRecordLevel.whenAmountAndWallet);
    });
  });

  group('segmen kotak masuk di 360dp (QA PR #43 F19)', () {
    setUpAll(() async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
      await loader.load();
    });

    for (final locale in [AppLocale.id, AppLocale.en]) {
      testWidgets('${locale.languageCode}: label segmen dan hitungannya sebaris', (tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
        tester.view
          ..physicalSize = const Size(360, 720)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await open(tester, NotificationCaptureRouteKeys.inbox);
        for (final label in [t.notificationCapture.inboxPendingTitle, t.notificationCapture.inboxAutoTitle]) {
          final text = find.textContaining(label, findRichText: true);
          final paragraph = tester.renderObject<RenderParagraph>(text.first);
          expect(
            paragraph.getMaxIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(paragraph.size.width + 0.5),
            reason: '"$label" terbungkus',
          );
        }
      });
    }
  });

  group('kotak masuk', () {
    final at = DateTime(2026, 10, 1, 14);

    CaptureInboxEntry unreadable() => CaptureInboxEntry(
      id: 'u',
      packageName: 'id.co.bri.brimo',
      appLabel: 'BRImo',
      text: 'Transfer masuk dari ANDI',
      capturedAt: at,
      draft: const RecordDraft(kind: DraftKind.income),
    );

    testWidgets('tautan Kelola aplikasi & pola ada juga saat kosong dan membuka setelan', (tester) async {
      await open(tester, NotificationCaptureRouteKeys.inbox);

      await tester.tap(find.byKey(const ValueKey('inbox-manage-sources')));
      await tester.pumpAndSettle();

      expect(find.text(t.notificationCapture.settingsTitle), findsWidgets);
    });

    testWidgets('nominal tak terbaca: Ajari pola membuka pembuat pola; yang terbaca tanpa tombol itu', (tester) async {
      await store.saveInbox([
        unreadable(),
        CaptureInboxEntry(
          id: 'ok',
          packageName: 'id.co.bri.brimo',
          appLabel: 'BRImo',
          text: 'Bayar',
          capturedAt: at,
          draft: const RecordDraft(kind: DraftKind.expense, amountSen: 10000),
        ),
      ]);
      await open(tester, NotificationCaptureRouteKeys.inbox);

      expect(find.byKey(const ValueKey('inbox-teach-u')), findsOneWidget);
      expect(find.byKey(const ValueKey('inbox-teach-ok')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('inbox-teach-u')));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPatternPage), findsOneWidget);
    });

    testWidgets('rute teachPattern langsung membuka pembuat pola untuk tangkapan itu', (tester) async {
      await store.saveInbox([unreadable()]);
      await tester.pumpWidget(
        ScopeProvider(
          container: container,
          child: MaterialApp(
            theme: PixelTheme.light,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => context.pushRoute(
                  NotificationCaptureRouteKeys.teachPattern,
                  const TeachPatternInput(entryId: 'u'),
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationPatternPage), findsOneWidget);
    });

    testWidgets('Abaikan menghapus tangkapan beserta teksnya', (tester) async {
      await store.saveInbox([
        CaptureInboxEntry(
          id: 'a',
          packageName: 'id.co.bri.brimo',
          appLabel: 'BRImo',
          text: 'Transaksi Rp50.000 berhasil',
          capturedAt: at,
          draft: const RecordDraft(kind: DraftKind.expense, amountSen: 5000000, issues: {DraftIssue.kindUnclear}),
          reviewReason: CaptureReviewReason.kindUnclear,
        ),
      ]);
      await open(tester, NotificationCaptureRouteKeys.inbox);
      expect(find.text('Transaksi Rp50.000 berhasil'), findsOneWidget);

      // Alasan perlu dicek tersimpan dan tampil sebagai badge (QA PR #43 F16).
      expect(find.text(t.notificationCapture.reviewReason.kindUnclear), findsOneWidget);

      await tester.tap(find.text(t.notificationCapture.dismissAction));
      await tester.pumpAndSettle();
      expect((await store.loadInbox()).getOrElse((_) => throw StateError('')), isEmpty);
      expect(find.text(t.notificationCapture.inboxEmpty), findsOneWidget);

      // Urungkan mengembalikannya ke Perlu dicek (QA PR #43 F18).
      await tester.tap(find.byKey(const ValueKey('inbox-dismiss-undo')));
      await tester.pumpAndSettle();
      expect((await store.loadInbox()).getOrElse((_) => throw StateError('')).single.id, 'a');
      expect(find.text('Transaksi Rp50.000 berhasil'), findsOneWidget);
    });

    testWidgets('Bukan transaksi: kartu perlu diisi ditutup, bentuknya dipelajari, Urungkan memulihkan', (
      tester,
    ) async {
      await store.saveInbox([
        CaptureInboxEntry(
          id: 'a',
          packageName: 'id.co.bri.brimo',
          appLabel: 'BRImo',
          text: 'Diskon Rp50.000 untuk kamu',
          capturedAt: at,
          draft: const RecordDraft(kind: DraftKind.expense, amountSen: 5000000, issues: {DraftIssue.kindUnclear}),
          reviewReason: CaptureReviewReason.kindUnclear,
        ),
      ]);
      await open(tester, NotificationCaptureRouteKeys.inbox);

      await tester.tap(find.byKey(const ValueKey('inbox-not-transaction-a')));
      await tester.pumpAndSettle();
      expect((await store.loadInbox()).getOrElse((_) => throw StateError('')), isEmpty);
      expect(find.text(t.notificationCapture.notTransactionDone), findsOneWidget);
      final shapes = container<NegativeShapeStore>();
      expect((await shapes.load()).getOrElse((_) => const []).single.template, 'Diskon {amount} untuk kamu');

      await tester.tap(find.byKey(const ValueKey('inbox-not-transaction-undo')));
      await tester.pumpAndSettle();
      expect((await store.loadInbox()).getOrElse((_) => throw StateError('')).single.id, 'a');
      expect((await shapes.load()).getOrElse((_) => const []), isEmpty);
    });

    group('satu ketuk (ADR-044 §3.6)', () {
      CaptureInboxEntry known(
        String id, {
        int amount = 5000000,
        String? category = 'builtin.food',
        Duration ago = Duration.zero,
        CaptureReviewReason reason = CaptureReviewReason.autoRecordOff,
      }) => CaptureInboxEntry(
        id: id,
        packageName: 'id.co.bri.brimo',
        appLabel: 'BRImo',
        text: 'Pembayaran ke KOPI $id berhasil',
        capturedAt: at.subtract(ago),
        draft: RecordDraft(
          kind: DraftKind.expense,
          amountSen: amount,
          walletId: 'bri',
          categoryId: category,
          note: 'KOPI $id',
          date: at.subtract(ago),
        ),
        reviewReason: reason,
      );

      Future<List<Transaction>> recorded() async =>
          (await ledger.listTransactionsInMonth(at)).getOrElse((_) => throw StateError(''));

      testWidgets('Plus, kartu dikenali: Catat langsung mencatat tanpa formulir; Ubah dulu tetap ada', (tester) async {
        await store.saveInbox([known('a')]);
        await open(tester, NotificationCaptureRouteKeys.inbox);
        expect(find.byKey(const ValueKey('inbox-edit-first-a')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('inbox-confirm-a')));
        await tester.pumpAndSettle();

        final tx = (await recorded()).single;
        expect(tx.amount, 5000000);
        expect(tx.note, 'KOPI a');
        expect((await store.loadInbox()).getOrElse((_) => throw StateError('')), isEmpty);
        expect(find.text(t.notificationCapture.inboxEmpty), findsOneWidget);
        expect(find.text(t.notificationCapture.oneTapRecorded(amount: 'Rp50.000', app: 'BRImo')), findsOneWidget);
      });

      group('peristiwa analitik (ukuran keberhasilan, NOTIFICATION_CAPTURE_V2 §12)', () {
        late List<AnalyticsEvent> events;

        setUp(() {
          events = [];
          AppAnalytics.debugSink = events.add;
          addTearDown(() => AppAnalytics.debugSink = null);
        });

        List<AnalyticsEvent> only(String name) => events.where((e) => e.name == name).toList();

        testWidgets('membuka kotak masuk mencatat jumlah kartu per kelas', (tester) async {
          await store.saveInbox([known('a'), known('b', category: null)]);
          await open(tester, NotificationCaptureRouteKeys.inbox);

          expect(
            only('capture_inbox_opened').single,
            CaptureEvents.inboxOpened(planned: 0, recognized: 1, needsInput: 1),
          );
        });

        testWidgets('satu ketuk mencatat one_tap dengan kelas kartu', (tester) async {
          await store.saveInbox([known('a')]);
          await open(tester, NotificationCaptureRouteKeys.inbox);

          await tester.tap(find.byKey(const ValueKey('inbox-confirm-a')));
          await tester.pumpAndSettle();

          expect(
            only('capture_card_action').single,
            CaptureEvents.cardAction(action: 'one_tap', cardClass: 'recognized'),
          );
        });

        testWidgets('Catat semua mencatat confirm_all untuk tiap kartu', (tester) async {
          await store.saveInbox([known('a'), known('b', amount: 1200000, ago: const Duration(minutes: 5))]);
          await open(tester, NotificationCaptureRouteKeys.inbox);

          await tester.tap(find.byKey(const ValueKey('inbox-confirm-all')));
          await tester.pumpAndSettle();

          expect(only('capture_card_action').map((e) => e.parameters['action']), ['confirm_all', 'confirm_all']);
        });

        testWidgets('Abaikan mencatat dismiss; tanpa nominal, nama aplikasi, atau teks notifikasi', (tester) async {
          await store.saveInbox([known('a', category: null)]);
          await open(tester, NotificationCaptureRouteKeys.inbox);

          await tester.tap(find.text(t.notificationCapture.dismissAction));
          await tester.pumpAndSettle();

          expect(
            only('capture_card_action').single,
            CaptureEvents.cardAction(action: 'dismiss', cardClass: 'needs_input'),
          );
          for (final event in events) {
            for (final value in event.parameters.values) {
              expect('$value', isNot(contains('BRImo')));
              expect('$value', isNot(contains('KOPI')));
              expect('$value', isNot(contains('50000')));
            }
          }
        });

        testWidgets('Sudah, tutup pada duplikat mencatat close_duplicate', (tester) async {
          await ledger.saveTransaction(
            ExpenseTransaction(id: 'manual', date: at, amount: 5000000, note: 'Kopi', walletId: 'bri'),
          );
          await store.saveInbox([known('a')]);
          await open(tester, NotificationCaptureRouteKeys.inbox);

          await tester.tap(find.byKey(const ValueKey('inbox-close-duplicate')));
          await tester.pumpAndSettle();

          expect(
            only('capture_card_action').single,
            CaptureEvents.cardAction(action: 'close_duplicate', cardClass: 'needs_input'),
          );
        });
      });

      testWidgets('Batalkan sesudah satu ketuk: transaksi dihapus dan kartu kembali', (tester) async {
        await store.saveInbox([known('a')]);
        await open(tester, NotificationCaptureRouteKeys.inbox);
        await tester.tap(find.byKey(const ValueKey('inbox-confirm-a')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('inbox-confirm-undo')));
        await tester.pumpAndSettle();

        expect(await recorded(), isEmpty);
        expect((await store.loadInbox()).getOrElse((_) => throw StateError('')).single.id, 'a');
        expect(find.text('Pembayaran ke KOPI a berhasil'), findsOneWidget);
      });

      testWidgets('kartu perlu diisi (tanpa kategori): tidak ada Ubah dulu, Catat membuka CATAT', (tester) async {
        await store.saveInbox([known('a', category: null)]);
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-edit-first-a')), findsNothing);
        expect(find.byKey(const ValueKey('inbox-confirm-all')), findsNothing);
      });

      testWidgets('Gratis, kartu dikenali: satu ketuk tidak ditawarkan', (tester) async {
        ActivePlan.notifier.value = const FreePlan();
        await store.saveInbox([known('a')]);
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-edit-first-a')), findsNothing);
      });

      testWidgets('Plus, dua kartu atau lebih: Catat semua yang cocok mencatat semuanya', (tester) async {
        await store.saveInbox([
          known('a'),
          known('b', amount: 1200000, ago: const Duration(minutes: 5)),
          known('c', category: null),
        ]);
        await open(tester, NotificationCaptureRouteKeys.inbox);
        expect(find.text(t.notificationCapture.confirmAllAction(n: 2)), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('inbox-confirm-all')));
        await tester.pumpAndSettle();

        expect((await recorded()).map((tx) => tx.amount).toSet(), {5000000, 1200000});
        // Yang perlu diisi tetap menunggu.
        expect((await store.loadInbox()).getOrElse((_) => throw StateError('')).map((e) => e.id), ['c']);
        expect(find.text(t.notificationCapture.oneTapRecordedMany(n: 2)), findsOneWidget);
      });

      testWidgets('Catat semua tidak muncul untuk satu kartu, atau untuk Gratis', (tester) async {
        await store.saveInbox([known('a')]);
        await open(tester, NotificationCaptureRouteKeys.inbox);
        expect(find.byKey(const ValueKey('inbox-confirm-all')), findsNothing);
      });

      testWidgets('alasan "Catat otomatis mati" tidak ditempel di kartu; alasan sungguhan tetap', (tester) async {
        await store.saveInbox([
          known('a'),
          known('b', category: null, reason: CaptureReviewReason.categoryUnclear),
        ]);
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.text(t.notificationCapture.reviewReason.autoRecordOff), findsNothing);
        expect(find.text(t.notificationCapture.reviewReason.categoryUnclear), findsOneWidget);
      });
    });

    group('izin dicabut (ADR-044, temuan review UX)', () {
      testWidgets('fitur menyala tetapi izin tidak ada: banner dengan Izinkan, bukan kotak masuk yang tampak kosong', (
        tester,
      ) async {
        await store.saveSettings(const NotificationCaptureSettings(enabled: true));
        gateway.accessGranted = false;
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-access-banner')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('inbox-access-grant')));
        await tester.pumpAndSettle();
        expect(find.text(t.notificationCapture.disclosureTitle), findsOneWidget);
        await tester.tap(find.text(t.notificationCapture.disclosureAccept));
        await tester.pumpAndSettle();
        expect(gateway.accessSettingsOpened, 1);
      });

      testWidgets('izin ada: tanpa banner', (tester) async {
        await store.saveSettings(const NotificationCaptureSettings(enabled: true));
        gateway.accessGranted = true;
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-access-banner')), findsNothing);
      });

      testWidgets('fitur mati: tanpa banner', (tester) async {
        gateway.accessGranted = false;
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-access-banner')), findsNothing);
      });

      testWidgets('dialog izin menjelaskan langkah sesudah Lanjut', (tester) async {
        expect(t.notificationCapture.disclosureBody, contains('Pilih Tanukonomy'));
      });
    });

    group('duplikat dua arah (ADR-044 §3.3)', () {
      CaptureInboxEntry card({String id = 'a'}) => CaptureInboxEntry(
        id: id,
        packageName: 'id.co.bri.brimo',
        appLabel: 'BRImo',
        text: 'Pembayaran Rp50.000 ke KOPI berhasil',
        capturedAt: at,
        draft: RecordDraft(kind: DraftKind.expense, amountSen: 5000000, walletId: 'bri', date: at),
        reviewReason: CaptureReviewReason.autoRecordOff,
      );

      testWidgets('tanpa catatan yang sama: aksi biasa, tanpa keterangan duplikat', (tester) async {
        await store.saveInbox([card()]);
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-duplicate-of')), findsNothing);
        expect(find.text(t.notificationCapture.recordAction), findsOneWidget);
        expect(find.text(t.notificationCapture.closeDuplicateAction), findsNothing);
      });

      testWidgets('catatan manual yang sama sudah ada: kartu menawarkan Sudah, tutup dan Tetap catat', (tester) async {
        await ledger.saveTransaction(
          ExpenseTransaction(id: 'manual', date: at, amount: 5000000, note: 'Kopi pagi', walletId: 'bri'),
        );
        await store.saveInbox([card()]);
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.text(t.notificationCapture.possibleDuplicate), findsOneWidget);
        expect(find.text(t.notificationCapture.duplicateOf(label: 'Kopi pagi')), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-record-anyway')), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-close-duplicate')), findsOneWidget);
        // Tanpa rutin yang cocok, tidak ada Tautkan.
        expect(find.byKey(const ValueKey('inbox-link-existing')), findsNothing);

        await tester.tap(find.byKey(const ValueKey('inbox-close-duplicate')));
        await tester.pumpAndSettle();
        expect((await store.loadInbox()).getOrElse((_) => throw StateError('')), isEmpty);
        // Transaksi yang sudah ada tidak disentuh.
        expect((await ledger.listTransactionsInMonth(at)).getOrElse((_) => []), hasLength(1));
      });

      testWidgets('dicatat manual sesudah kartu tampil: kartu berubah, tidak hilang sendiri', (tester) async {
        await store.saveInbox([card()]);
        await open(tester, NotificationCaptureRouteKeys.inbox);
        expect(find.byKey(const ValueKey('inbox-duplicate-of')), findsNothing);

        await ledger.saveTransaction(
          ExpenseTransaction(id: 'manual', date: at, amount: 5000000, note: 'Kopi', walletId: 'bri'),
        );
        container<LedgerChanges>().notifyChanged();
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('inbox-duplicate-of')), findsOneWidget);
        // Kartu tetap ada: dua pembelian yang sama bisa sungguhan.
        expect(find.text('Pembayaran Rp50.000 ke KOPI berhasil'), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-record-anyway')), findsOneWidget);
      });

      testWidgets('satu catatan hanya dicocokkan ke satu kartu (yang tertua)', (tester) async {
        await ledger.saveTransaction(
          ExpenseTransaction(id: 'manual', date: at, amount: 5000000, note: 'Kopi', walletId: 'bri'),
        );
        final older = card(id: 'old');
        final newer = CaptureInboxEntry(
          id: 'new',
          packageName: older.packageName,
          appLabel: older.appLabel,
          text: 'Pembayaran Rp50.000 ke KOPI berhasil (kedua)',
          capturedAt: at.add(const Duration(minutes: 30)),
          draft: older.draft,
          reviewReason: CaptureReviewReason.autoRecordOff,
        );
        await store.saveInbox([newer, older]);
        await open(tester, NotificationCaptureRouteKeys.inbox);

        expect(find.byKey(const ValueKey('inbox-duplicate-of')), findsOneWidget);
        expect(find.byKey(const ValueKey('inbox-record-anyway')), findsOneWidget);
        expect(find.text(t.notificationCapture.recordAction), findsOneWidget);
      });
    });

    testWidgets('tanpa yang menunggu, kotak masuk terbuka di segmen Otomatis (QA PR #43 F17)', (tester) async {
      await store.saveAutoRecorded([
        AutoRecordedEntry(
          captureId: 'a',
          transactionId: 't1',
          transactionDate: at,
          kind: DraftKind.expense,
          amountSen: 4250000,
          appLabel: 'BRImo',
          recordedAt: at,
          note: 'INDOMARET',
        ),
      ]);
      await open(tester, NotificationCaptureRouteKeys.inbox);
      expect(find.text(t.notificationCapture.inboxEmpty), findsNothing);
      expect(find.text('INDOMARET'), findsOneWidget);
    });

    testWidgets('Batalkan transaksi otomatis menghapusnya dari buku besar', (tester) async {
      final tx = ExpenseTransaction(id: 't1', date: at, amount: 2500000, note: 'KOPI', walletId: 'bri');
      await ledger.saveTransaction(tx);
      await store.saveAutoRecorded([
        AutoRecordedEntry(
          captureId: 'a',
          transactionId: 't1',
          transactionDate: at,
          kind: DraftKind.expense,
          amountSen: 2500000,
          appLabel: 'BRImo',
          recordedAt: at,
          note: 'KOPI',
        ),
      ]);
      await open(tester, NotificationCaptureRouteKeys.inbox);

      // Yang tercatat otomatis ada di segmen kedua.
      await tester.tap(find.textContaining(t.notificationCapture.inboxAutoTitle, findRichText: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.notificationCapture.undoAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.notificationCapture.undoAction).last);
      await tester.pumpAndSettle();

      expect((await ledger.listTransactionsInMonth(at)).getOrElse((_) => throw StateError('')), isEmpty);
      expect((await store.loadAutoRecorded()).getOrElse((_) => throw StateError('')), isEmpty);
    });
  });

  testWidgets('pembuat pola: tandai nominal dan catatan → templat yang cocok dengan contohnya', (tester) async {
    NotificationPattern? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await openNotificationPatternPage(
              context,
              packageName: 'id.co.bri.brimo',
              wallets: const [],
              sample: 'QRIS Rp18.500 di WARUNG BU TINI sukses',
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    // Penanda awal Nominal: kata bukan nominal ditolak dengan pesan.
    await tester.tap(find.text('WARUNG'));
    await tester.pump();
    expect(find.text(t.notificationCapture.patternNotAmount(word: 'WARUNG')), findsOneWidget);

    await tester.tap(find.text('Rp18.500'));
    await tester.pump();
    // Sesudah nominal, penanda pindah sendiri ke Catatan.
    for (final word in ['WARUNG', 'BU', 'TINI']) {
      await tester.tap(find.text(word));
      await tester.pump();
    }
    expect(find.byKey(const ValueKey('pattern-preview')), findsOneWidget);
    expect(find.textContaining('WARUNG BU TINI'), findsWidgets);
    await tester.tap(find.text(t.notificationCapture.save));
    await tester.pumpAndSettle();

    expect(result?.template, 'QRIS {amount} di {note} sukses');
    expect(result?.kind, NotificationPatternKind.expense);
  });

  group('pembuat pola: petunjuk langkah demi langkah', () {
    Future<void> openBuilder(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => openNotificationPatternPage(
                context,
                packageName: 'id.co.bri.brimo',
                wallets: const [],
                sample: 'QRIS Rp18.500 di WARUNG BU TINI sukses',
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
    }

    final save = find.widgetWithText(AppButton, t.notificationCapture.save);

    testWidgets('judul, pengantar satu kalimat, dan langkah bernomor', (tester) async {
      await openBuilder(tester);

      expect(find.text(t.notificationCapture.patternTitle), findsOneWidget);
      expect(find.byKey(const ValueKey('pattern-intro')), findsOneWidget);
      expect(find.text(t.notificationCapture.patternIntro), findsOneWidget);
      expect(find.text(t.notificationCapture.patternSampleLabel), findsOneWidget);
      expect(find.text(t.notificationCapture.patternMarkLabel), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(t.notificationCapture.patternKindLabel),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(t.notificationCapture.patternKindLabel), findsOneWidget);
    });

    testWidgets('petunjuk mengikuti kemajuan: nominal dulu, lalu catatan yang boleh dilewati', (tester) async {
      await openBuilder(tester);
      expect(find.text(t.notificationCapture.patternHintAmount), findsOneWidget);
      expect(find.text(t.notificationCapture.patternHintNote), findsNothing);

      await tester.tap(find.text('Rp18.500'));
      await tester.pump();

      expect(find.text(t.notificationCapture.patternHintAmount), findsNothing);
      expect(find.text(t.notificationCapture.patternHintNote), findsOneWidget);
    });

    testWidgets('arti penanda terpilih ditulis di bawah pilihannya', (tester) async {
      await openBuilder(tester);
      expect(find.text(t.notificationCapture.roleAmountHelp), findsOneWidget);

      await tester.tap(find.text(t.notificationCapture.roleNote));
      await tester.pump();
      expect(find.text(t.notificationCapture.roleNoteHelp), findsOneWidget);

      await tester.tap(find.text(t.notificationCapture.roleIgnore));
      await tester.pump();
      expect(find.text(t.notificationCapture.roleIgnoreHelp), findsOneWidget);
    });

    testWidgets('Simpan nonaktif disertai alasannya sampai nominal ditandai', (tester) async {
      await openBuilder(tester);
      expect(find.byKey(const ValueKey('pattern-need-amount')), findsOneWidget);
      expect(tester.widget<AppButton>(save).onPressed, isNull);

      await tester.tap(find.text('Rp18.500'));
      await tester.pump();

      expect(find.byKey(const ValueKey('pattern-need-amount')), findsNothing);
      expect(tester.widget<AppButton>(save).onPressed, isNotNull);
    });

    testWidgets('templat mentah tidak disebut Pola dan tersembunyi di balik tautan', (tester) async {
      await openBuilder(tester);
      expect(find.byKey(const ValueKey('pattern-template')), findsNothing);

      await tester.scrollUntilVisible(
        find.text(t.notificationCapture.patternTemplateToggle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(t.notificationCapture.patternTemplateToggle));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pattern-template')), findsOneWidget);
      expect(find.text(t.notificationCapture.patternTemplateLabel), findsOneWidget);
    });
  });

  group('Gratis (ADR-041 §3.8)', () {
    setUp(() => ActivePlan.notifier.value = const FreePlan());

    testWidgets('sakelar Catat otomatis membuka paywall dan setelannya tidak berubah', (tester) async {
      await store.saveSettings(const NotificationCaptureSettings(enabled: true));
      await open(tester, NotificationCaptureRouteKeys.settings);

      final autoRecord = find.descendant(
        of: find.byKey(const ValueKey('notification-auto-record')),
        matching: find.byType(Switch),
      );
      await tester.scrollUntilVisible(autoRecord, 200);
      await tester.tap(autoRecord);
      await tester.pumpAndSettle();

      expect(find.text(t.premium.signInTitle), findsOneWidget);
      final saved = (await store.loadSettings()).getOrElse((_) => throw StateError(''));
      expect(saved.autoRecordLevel, AutoRecordLevel.reviewAll);
    });

    testWidgets('menambah sumber kedua membuka paywall; sumber pertama tetap boleh', (tester) async {
      gateway.apps = const [
        InstalledApp(packageName: 'id.co.bri.brimo', label: 'BRImo'),
        InstalledApp(packageName: 'com.gojek.gopay', label: 'GoPay'),
      ];
      await store.saveSettings(const NotificationCaptureSettings(enabled: true));
      await open(tester, NotificationCaptureRouteKeys.settings);
      await tester.scrollUntilVisible(find.text(t.notificationCapture.addSource), 200);
      await tester.tap(find.text(t.notificationCapture.addSource));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BRImo'));
      await tester.pumpAndSettle();
      expect(find.text(t.notificationCapture.save), findsOneWidget, reason: 'sumber pertama membuka halaman sumber');
      await tester.tap(find.text(t.notificationCapture.save));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text(t.notificationCapture.addSource), 200);
      await tester.tap(find.text(t.notificationCapture.addSource));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GoPay'));
      await tester.pumpAndSettle();
      expect(find.text(t.premium.signInTitle), findsOneWidget);
      final saved = (await store.loadSettings()).getOrElse((_) => throw StateError(''));
      expect(saved.sources.map((e) => e.packageName), ['id.co.bri.brimo']);
    });

    testWidgets('Ajari pola membuka paywall, bukan pembuat pola', (tester) async {
      await store.saveInbox([
        CaptureInboxEntry(
          id: 'u',
          packageName: 'id.co.bri.brimo',
          appLabel: 'BRImo',
          text: 'Transfer masuk dari ANDI',
          capturedAt: DateTime(2026, 10, 1, 14),
          draft: const RecordDraft(kind: DraftKind.income),
        ),
      ]);
      await open(tester, NotificationCaptureRouteKeys.inbox);
      await tester.tap(find.byKey(const ValueKey('inbox-teach-u')));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationPatternPage), findsNothing);
      expect(find.text(t.premium.signInTitle), findsOneWidget);
    });
  });
}

/// Penyimpanan yang gagal menyimpan setelan (Mulai cepat: galat harus terlihat).
final class _SettingsFailingStore implements NotificationCaptureStore {
  _SettingsFailingStore(this._inner);

  final NotificationCaptureStore _inner;

  @override
  Future<Either<Failure, Unit>> saveSettings(NotificationCaptureSettings settings) async =>
      const Left(SystemFailure(code: FailureCode.unknown, message: 'disk penuh'));

  @override
  Future<Either<Failure, NotificationCaptureSettings>> loadSettings() => _inner.loadSettings();

  @override
  Future<Either<Failure, List<NotificationPattern>>> loadPatterns() => _inner.loadPatterns();

  @override
  Future<Either<Failure, Unit>> savePatterns(List<NotificationPattern> patterns) => _inner.savePatterns(patterns);

  @override
  Future<Either<Failure, List<CaptureInboxEntry>>> loadInbox() => _inner.loadInbox();

  @override
  Future<Either<Failure, Unit>> saveInbox(List<CaptureInboxEntry> entries) => _inner.saveInbox(entries);

  @override
  Future<Either<Failure, List<AutoRecordedEntry>>> loadAutoRecorded() => _inner.loadAutoRecorded();

  @override
  Future<Either<Failure, Unit>> saveAutoRecorded(List<AutoRecordedEntry> entries) => _inner.saveAutoRecorded(entries);

  @override
  Future<Either<Failure, Map<String, DateTime>>> loadProcessedIds() => _inner.loadProcessedIds();

  @override
  Future<Either<Failure, Unit>> saveProcessedIds(Map<String, DateTime> ids) => _inner.saveProcessedIds(ids);
}
