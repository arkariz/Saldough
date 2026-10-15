import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/widgets/app_update_banner.dart';
import 'package:saldough/features/app_update/presentation/widgets/update_banner_card.dart';
import 'package:saldough/features/notification_capture/domain/entities/capture_inbox_entry.dart';
import 'package:saldough/features/notification_capture/domain/repositories/notification_capture_store.dart';
import 'package:saldough/features/notification_capture/domain/services/capture_inbox_changes.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/capture_inbox_banner.dart';
import 'package:saldough/shared/capture/capture.dart';

import '../../../../helpers/update_harness.dart';

class _MockInstalled extends Mock implements InstalledVersionSource {}

class _MockStore extends Mock implements StoreUpdateSource {}

class _MockPatch extends Mock implements PatchSource {}

class _MockMemory extends Mock implements AppUpdateMemoryRepository {}

class _MockCaptureStore extends Mock implements NotificationCaptureStore {}

Stream<StoreUpdateStage> _noStages(Invocation _) => const Stream<StoreUpdateStage>.empty();

/// Banner pembaruan di slot Beranda (APP_UPDATE §7, B-2, B-3, B-7), dengan
/// bloc sungguhan di atas sumber palsu.
void main() {
  setUpAll(() async {
    final loader = FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    await loader.load();
    registerFallbackValue(AppUpdateMemory.empty);
  });

  late _MockStore store;
  late _MockPatch patch;
  late _MockMemory memory;
  late GetIt container;
  late FakeReleaseNotes fakeNotes;
  AppUpdateBloc? created;

  void source({StoreUpdateInfo? play, PatchState patchState = PatchState.none}) {
    when(
      () => store.check(),
    ).thenAnswer((_) async => right(play ?? const StoreUpdateInfo(stage: StoreUpdateStage.none)));
    when(() => patch.read()).thenAnswer((_) async => right(patchState));
  }

  setUp(() {
    final installed = _MockInstalled();
    store = _MockStore();
    patch = _MockPatch();
    memory = _MockMemory();
    fakeNotes = FakeReleaseNotes();
    when(installed.read).thenAnswer((_) async => right((name: '0.5.0', build: 6)));
    when(() => store.watch()).thenAnswer(_noStages);
    when(() => store.startDownload()).thenAnswer((_) async => right(true));
    when(() => store.completeInstall()).thenAnswer((_) async => right(unit));
    when(() => memory.load()).thenAnswer((_) async => right(AppUpdateMemory.empty.see(6, 0)));
    when(() => memory.save(any())).thenAnswer((_) async => right(unit));
    source();
    // Bloc dibuat malas, di dalam zona uji widget (bukan di setUp).
    created = null;
    container = GetIt.asNewInstance()
      ..registerLazySingleton<AppUpdateBloc>(
        () => created = AppUpdateBloc(
          read: ReadUpdateSnapshot(installed: installed, store: store, patch: patch),
          store: store,
          memory: memory,
          notes: fakeNotes,
        ),
      );
  });

  tearDown(() async {
    await created?.close();
    await container.reset();
    LocaleSettings.setLocaleSync(AppLocale.id);
  });

  Future<void> pump(WidgetTester tester, {Widget? child}) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        // Ikon "mengunduh" berputar tanpa henti; uji tidak menunggunya.
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child ?? AppUpdateBanner(container: container),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selama tur spotlight tampil, banner menyingkir; sesudahnya kembali (B-10)', (tester) async {
    source(patchState: const PatchState(next: 1));
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = TutorialProgressRepositoryImpl(storage: InMemoryKeyValueStorage());
    late BuildContext inner;
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        // Seperti `SaldoughApp`: host tur di atas Navigator.
        builder: (context, child) => SpotlightHost(repository: repository, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              inner = context;
              return Column(
                children: [
                  const SpotlightTarget(
                    spotlightKey: SpotlightKey.homeBalance,
                    child: SizedBox(width: 100, height: 40),
                  ),
                  AppUpdateBanner(container: container),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-update-patch-ready')), findsOneWidget);

    final controller = SpotlightHost.maybeOf(inner, listen: false)!;
    await controller.maybeStart(TourId.home);
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.isActive, isTrue);
    expect(find.byKey(const ValueKey('app-update-patch-ready')), findsNothing);

    await controller.finish();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('app-update-patch-ready')), findsOneWidget);
  });

  const available = StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 7);

  testWidgets('tanpa pengumuman: tidak ada banner', (tester) async {
    await pump(tester);
    expect(find.byType(UpdateBannerCard), findsNothing);
    verify(() => store.check()).called(1);
  });

  testWidgets('bloc tidak terdaftar: kosong, tanpa galat', (tester) async {
    await pump(tester, child: AppUpdateBanner(container: GetIt.asNewInstance()));
    expect(find.byType(UpdateBannerCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chip versi tampil bila catatan build yang ditawarkan Play sudah ada (B-14)', (tester) async {
    fakeNotes.entries = {
      (build: 8, patch: 0): const ReleaseNote(build: 8, patch: 0, version: '0.7.0', groups: []),
    };
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    await pump(tester);
    expect(find.text('v0.7.0'), findsOneWidget);
  });

  testWidgets('tanpa catatan build itu: banner tampil tanpa chip', (tester) async {
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    await pump(tester);
    expect(find.text(t.appUpdate.banner.storeAvailable), findsOneWidget);
    expect(find.byKey(const ValueKey('app-update-version-chip')), findsNothing);
  });

  testWidgets('analitik: banner yang tampil dicatat sekali walau layar dibangun ulang', (tester) async {
    final events = <AnalyticsEvent>[];
    AppAnalytics.debugSink = events.add;
    addTearDown(() => AppAnalytics.debugSink = null);
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    await pump(tester);
    await pump(tester);
    final shown = events.where((e) => e.name == 'update_banner_shown').toList();
    expect(shown, hasLength(1));
    expect(shown.single.parameters['stage'], 'available');
  });

  testWidgets('tersedia: Perbarui memulai unduhan', (tester) async {
    source(play: available);
    await pump(tester);
    expect(find.text(t.appUpdate.banner.storeAvailable), findsOneWidget);
    await tester.tap(find.text(t.appUpdate.action.update));
    await tester.pumpAndSettle();
    verify(() => store.startDownload()).called(1);
  });

  testWidgets('tersedia: Nanti menyembunyikan banner dan menyimpannya', (tester) async {
    source(play: available);
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('app-update-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateBannerCard), findsNothing);
    verify(() => memory.save(any())).called(1);
  });

  testWidgets('mengunduh: tanpa aksi apa pun', (tester) async {
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloading, availableBuild: 7));
    await pump(tester);
    expect(find.text(t.appUpdate.banner.storeDownloading), findsOneWidget);
    expect(find.text(t.appUpdate.action.update), findsNothing);
    expect(find.byKey(const ValueKey('app-update-dismiss')), findsNothing);
  });

  testWidgets('sudah diunduh: tanpa Nanti; Pasang sekarang hanya jalan saat diketuk (B-7)', (tester) async {
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 7));
    await pump(tester);
    expect(find.byKey(const ValueKey('app-update-dismiss')), findsNothing);
    verifyNever(() => store.completeInstall());
    await tester.tap(find.text(t.appUpdate.action.install));
    await tester.pumpAndSettle();
    verify(() => store.completeInstall()).called(1);
  });

  testWidgets('pembaruan kecil siap: Oke menutupnya dan mengingatnya (B-8)', (tester) async {
    source(patchState: const PatchState(next: 1));
    await pump(tester);
    expect(find.text(t.appUpdate.banner.patchReady), findsOneWidget);
    await tester.tap(find.text(t.appUpdate.action.ok));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateBannerCard), findsNothing);
    verify(() => memory.save(any())).called(1);
  });

  testWidgets('B-4 (S4): versi baru dan pembaruan kecil sekaligus, hanya versi baru', (tester) async {
    source(play: available, patchState: const PatchState(next: 1));
    await pump(tester);
    expect(find.byType(UpdateBannerCard), findsOneWidget);
    expect(find.text(t.appUpdate.banner.storeAvailable), findsOneWidget);
  });

  final cases = <String, ({StoreUpdateInfo? play, PatchState patch})>{
    'tersedia': (play: available, patch: PatchState.none),
    'mengunduh': (
      play: const StoreUpdateInfo(stage: StoreUpdateStage.downloading, availableBuild: 7),
      patch: PatchState.none,
    ),
    'sudah diunduh': (
      play: const StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 7),
      patch: PatchState.none,
    ),
    'pembaruan kecil': (play: null, patch: const PatchState(next: 1)),
  };
  for (final locale in [AppLocale.id, AppLocale.en]) {
    for (final MapEntry(key: name, value: setup) in cases.entries) {
      testWidgets('360dp ${locale.languageCode} $name: tanpa overflow, tindakan di dalam banner', (tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        source(play: setup.play, patchState: setup.patch);
        await pump(tester);
        expect(tester.takeException(), isNull);
        final banner = tester.getRect(find.byType(UpdateBannerCard));
        expect(banner.width, 328);
        for (final label in [
          t.appUpdate.action.update,
          t.appUpdate.action.install,
          t.appUpdate.action.ok,
        ]) {
          for (final element in find.text(label).evaluate()) {
            final rect = tester.getRect(find.byWidget(element.widget));
            expect(rect.left, greaterThanOrEqualTo(banner.left), reason: label);
            expect(rect.right, lessThanOrEqualTo(banner.right), reason: label);
          }
        }
        for (final element in find.byKey(const ValueKey('app-update-dismiss')).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.right, lessThanOrEqualTo(banner.right));
          expect(rect.top, greaterThanOrEqualTo(banner.top), reason: '× di pojok atas');
        }
      });
    }
  }

  group('slot kotak masuk (B-2, B-3)', () {
    late _MockCaptureStore captureStore;

    setUp(() {
      captureStore = _MockCaptureStore();
      container
        ..registerSingleton<NotificationCaptureStore>(captureStore)
        ..registerSingleton<CaptureInboxChanges>(CaptureInboxChanges());
      source(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 7));
    });

    Widget slot() => CaptureInboxBanner(
      container: container,
      fallback: AppUpdateBanner(container: container),
    );

    final entry = CaptureInboxEntry(
      id: 'a',
      packageName: 'id.co.bri.brimo',
      appLabel: 'BRImo',
      text: 'Transaksi Rp50.000 berhasil',
      capturedAt: DateTime(2026, 10, 1, 14),
      draft: const RecordDraft(kind: DraftKind.expense, amountSen: 5000000),
    );

    testWidgets('kotak masuk kosong: banner pembaruan tampil', (tester) async {
      when(() => captureStore.loadInbox()).thenAnswer((_) async => right(<CaptureInboxEntry>[]));
      await pump(tester, child: slot());
      expect(find.byKey(const ValueKey('app-update-store-downloaded')), findsOneWidget);
      expect(find.byKey(const ValueKey('capture-inbox-banner')), findsNothing);
    });

    testWidgets('kotak masuk berisi: hanya banner kotak masuk', (tester) async {
      when(() => captureStore.loadInbox()).thenAnswer((_) async => right([entry]));
      await pump(tester, child: slot());
      expect(find.byKey(const ValueKey('capture-inbox-banner')), findsOneWidget);
      expect(find.byKey(const ValueKey('app-update-store-downloaded')), findsNothing);
      expect(find.byType(UpdateBannerCard), findsNothing);
      expect(find.byType(AppBanner), findsOneWidget);
    });
  });
}
