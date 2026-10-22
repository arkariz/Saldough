import 'dart:ui' as ui;

import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/di/notification_capture_module.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_capture_settings.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_gateway.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/presentation/navigation/notification_capture_route_keys.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../../../helpers/fake_notification_capture_gateway.dart';
import '../../../../helpers/routes.dart';

void main() {
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
      ..registerSingleton<CategoryRepository>(CategoryRepositoryImpl(storage: storage));
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

    testWidgets('hanya aplikasi dengan pola bawaan, semuanya tercentang', (tester) async {
      gateway.apps = const [gopay, calculator, bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      expect(find.text('BRImo'), findsOneWidget);
      expect(find.text('GoPay'), findsOneWidget);
      expect(find.text('Kalkulator'), findsNothing);
      final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(boxes, hasLength(2));
      expect(boxes.every((box) => box.value ?? false), isTrue);
    });

    testWidgets('akses sudah ada: Nyalakan menyimpan sumber, menyalakan fitur, dan menutup layar', (tester) async {
      gateway
        ..apps = const [gopay, bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      final saved = await settings();
      expect(saved.enabled, isTrue);
      expect(saved.sources.map((s) => s.packageName), ['id.co.bri.brimo', 'com.gojek.gopay']);
      expect(gateway.configuredSources, hasLength(2));
      expect(find.text(t.discovery.quickStart.turnOn), findsNothing);
      expect(find.text('buka'), findsOneWidget);
    });

    testWidgets('analitik: selesai mencatat jumlah aplikasi dan via quick_start, tanpa nama aplikasi', (tester) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      gateway
        ..apps = const [gopay, bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);

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

    testWidgets('aplikasi yang dicentang dihapus tidak ikut disimpan', (tester) async {
      gateway
        ..apps = const [gopay, bri]
        ..accessGranted = true;
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      await tester.tap(find.byKey(const ValueKey('quick-start-com.gojek.gopay')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();

      expect((await settings()).sources.map((s) => s.packageName), ['id.co.bri.brimo']);
    });

    testWidgets('tanpa centang dan tanpa sumber, Nyalakan nonaktif', (tester) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      await tester.tap(find.byKey(const ValueKey('quick-start-id.co.bri.brimo')));
      await tester.pumpAndSettle();

      final button = tester.widget<AppButton>(find.byKey(const ValueKey('quick-start-turn-on')));
      expect(button.onPressed, isNull);
    });

    testWidgets('akses belum ada: pengungkapan dulu, lalu setelan sistem; kembali dengan akses menutup layar', (
      tester,
    ) async {
      gateway.apps = const [bri];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

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

      await tester.tap(find.text(t.discovery.quickStart.turnOn));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(gateway.accessSettingsOpened, 0);
      expect(find.text(t.discovery.allowAccess), findsOneWidget);
    });

    testWidgets('tanpa aplikasi bawaan terpasang: pemilih aplikasi langsung terbuka', (tester) async {
      gateway.apps = const [calculator];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      expect(find.text(t.notificationCapture.pickAppTitle), findsOneWidget);
    });

    testWidgets('Aplikasi lain membuka pemilih yang sudah ada', (tester) async {
      gateway.apps = const [bri, calculator];
      await open(tester, NotificationCaptureRouteKeys.quickStart);

      await tester.tap(find.byKey(const ValueKey('quick-start-other')));
      await tester.pumpAndSettle();

      expect(find.text(t.notificationCapture.pickAppTitle), findsOneWidget);
      expect(find.text('Kalkulator'), findsOneWidget);
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
      await store.saveSettings(const NotificationCaptureSettings(enabled: true));
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
}
