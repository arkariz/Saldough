import 'dart:ui' as ui;

import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/effect_handler/app_effect_registry.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
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
}
