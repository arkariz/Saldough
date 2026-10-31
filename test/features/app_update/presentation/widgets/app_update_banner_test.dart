import 'package:dependencies/dependencies.dart';
import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/domain/entities/update_snapshot.dart';
import 'package:saldough/features/app_update/domain/repositories/app_update_memory_repository.dart';
import 'package:saldough/features/app_update/domain/repositories/update_sources.dart';
import 'package:saldough/features/app_update/domain/usecases/read_update_snapshot.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/widgets/app_update_banner.dart';
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

/// Slide pembaruan di carousel status Beranda (APP_UPDATE §7, B-2, B-3, B-7;
/// ADR-043 §3.6), dengan bloc sungguhan di atas sumber palsu.
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
  late DsStatusBoard board;
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
    board = DsStatusBoard();
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
    board.dispose();
    await created?.close();
    await container.reset();
    LocaleSettings.setLocaleSync(AppLocale.id);
  });

  /// Pelapor + carousel status yang membaca papan yang sama.
  Widget host() => Column(
    children: [
      AppUpdateBanner(container: container, board: board),
      DsStatusCarousel(board: board, previousLabel: 'prev', nextLabel: 'next', dotLabel: (i) => 'dot $i'),
    ],
  );

  Future<void> pump(WidgetTester tester, {Widget? child}) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        // Ikon "mengunduh" berputar tanpa henti; uji tidak menunggunya.
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child ?? host(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final slideFinder = find.byKey(const ValueKey('status-slide-app_update'));
  final dismissFinder = find.byKey(const ValueKey('status-slide-dismiss'));

  const available = StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 7);

  testWidgets('tanpa pengumuman: tidak ada slide', (tester) async {
    await pump(tester);
    expect(slideFinder, findsNothing);
    expect(board.slides, isEmpty);
    verify(() => store.check()).called(1);
  });

  testWidgets('bloc tidak terdaftar: kosong, tanpa galat', (tester) async {
    await pump(
      tester,
      child: AppUpdateBanner(container: GetIt.asNewInstance(), board: board),
    );
    expect(board.slides, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slide berlatar perhatian dan paling depan, dengan chip versi di keterangan (B-14)', (tester) async {
    fakeNotes.entries = {
      (build: 8, patch: 0): const ReleaseNote(build: 8, patch: 0, version: '0.7.0', groups: []),
    };
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    await pump(tester);
    expect(find.text('v0.7.0'), findsOneWidget);
    expect(board.slides.single.attention, isTrue);
    expect(board.slides.single.order, lessThan(0));
  });

  testWidgets('tanpa catatan build itu: slide tampil tanpa keterangan versi', (tester) async {
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.available, availableBuild: 8));
    await pump(tester);
    expect(find.text(t.appUpdate.banner.storeAvailable), findsOneWidget);
    expect(board.slides.single.subtitle, isEmpty);
  });

  testWidgets('analitik: pengumuman yang tampil dicatat sekali walau layar dibangun ulang', (tester) async {
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
    await tester.tap(find.text(t.appUpdate.banner.storeAvailable));
    await tester.pumpAndSettle();
    verify(() => store.startDownload()).called(1);
  });

  testWidgets('tersedia: × menunda pengumuman dan menyimpannya', (tester) async {
    source(play: available);
    await pump(tester);
    expect(find.bySemanticsLabel(t.appUpdate.action.later), findsOneWidget);
    await tester.tap(dismissFinder);
    await tester.pumpAndSettle();
    expect(slideFinder, findsNothing);
    verifyNever(() => store.startDownload());
    verify(() => memory.save(any())).called(1);
  });

  testWidgets('mengunduh: ikon berputar, tanpa aksi dan tanpa ×', (tester) async {
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloading, availableBuild: 7));
    await pump(tester);
    expect(find.text(t.appUpdate.banner.storeDownloading), findsOneWidget);
    expect(find.text(t.appUpdate.banner.storeDownloadingNote), findsOneWidget);
    expect(board.slides.single.busy, isTrue);
    expect(board.slides.single.onAction, isNull);
    expect(find.text(t.appUpdate.action.update.toUpperCase()), findsNothing);
    expect(dismissFinder, findsNothing);
  });

  testWidgets('sudah diunduh: tanpa ×; Pasang sekarang hanya jalan saat diketuk (B-7)', (tester) async {
    source(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 7));
    await pump(tester);
    expect(dismissFinder, findsNothing);
    verifyNever(() => store.completeInstall());
    await tester.tap(find.text(t.appUpdate.banner.storeDownloaded));
    await tester.pumpAndSettle();
    verify(() => store.completeInstall()).called(1);
  });

  testWidgets('pembaruan kecil siap: Oke menutupnya dan mengingatnya (B-8)', (tester) async {
    source(patchState: const PatchState(next: 1));
    await pump(tester);
    expect(find.text(t.appUpdate.banner.patchReady), findsOneWidget);
    expect(find.text(t.appUpdate.banner.patchReadyNote), findsOneWidget);
    await tester.tap(find.text(t.appUpdate.banner.patchReady));
    await tester.pumpAndSettle();
    expect(slideFinder, findsNothing);
    verify(() => memory.save(any())).called(1);
  });

  testWidgets('B-4 (S4): versi baru dan pembaruan kecil sekaligus, hanya versi baru', (tester) async {
    source(play: available, patchState: const PatchState(next: 1));
    await pump(tester);
    expect(board.slides, hasLength(1));
    expect(find.text(t.appUpdate.banner.storeAvailable), findsOneWidget);
  });

  testWidgets('pengumuman jadi slide pertama di depan slide lain', (tester) async {
    source(play: available);
    board.report(
      'recurring',
      const DsStatusSlideData(id: 'recurring', icon: Icons.event_note, title: 'Menunggu', subtitle: 'x', attention: true),
    );
    await pump(tester);
    expect(board.slides.first.id, 'app_update');
    expect(board.slides, hasLength(2));
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
      testWidgets('360dp ${locale.languageCode} $name: tanpa overflow, tombol di dalam slide', (tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        source(play: setup.play, patchState: setup.patch);
        await pump(tester);
        expect(tester.takeException(), isNull);
        final slide = tester.getRect(slideFinder);
        expect(slide.width, 328);
        for (final element in dismissFinder.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.right, lessThanOrEqualTo(slide.right));
        }
      });
    }
  }

  group('kotak masuk dan pembaruan (B-2 diubah 15 Okt 2026: slot sendiri-sendiri)', () {
    late _MockCaptureStore captureStore;

    setUp(() {
      captureStore = _MockCaptureStore();
      container
        ..registerSingleton<NotificationCaptureStore>(captureStore)
        ..registerSingleton<CaptureInboxChanges>(CaptureInboxChanges());
      source(play: const StoreUpdateInfo(stage: StoreUpdateStage.downloaded, availableBuild: 7));
    });

    final entry = CaptureInboxEntry(
      id: 'a',
      packageName: 'id.co.bri.brimo',
      appLabel: 'BRImo',
      text: 'Transaksi Rp50.000 berhasil',
      capturedAt: DateTime(2026, 10, 1, 14),
      draft: const RecordDraft(kind: DraftKind.expense, amountSen: 5000000),
    );

    Widget both() => Column(
      children: [
        host(),
        CaptureInboxBanner(container: container),
      ],
    );

    testWidgets('kotak masuk berisi: slide pembaruan dan banner kotak masuk tampil bersama', (tester) async {
      when(() => captureStore.loadInbox()).thenAnswer((_) async => right([entry]));
      await pump(tester, child: both());
      expect(slideFinder, findsOneWidget);
      expect(find.byKey(const ValueKey('capture-inbox-banner')), findsOneWidget);
    });

    testWidgets('kotak masuk kosong: hanya slide pembaruan', (tester) async {
      when(() => captureStore.loadInbox()).thenAnswer((_) async => right(<CaptureInboxEntry>[]));
      await pump(tester, child: both());
      expect(slideFinder, findsOneWidget);
      expect(find.byKey(const ValueKey('capture-inbox-banner')), findsNothing);
    });
  });
}
