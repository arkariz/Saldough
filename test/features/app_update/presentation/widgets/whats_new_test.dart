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
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/app_update/domain/entities/app_update_memory.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';
import 'package:saldough/features/app_update/presentation/bloc/app_update_bloc.dart';
import 'package:saldough/features/app_update/presentation/widgets/release_notes_view.dart';
import 'package:saldough/features/app_update/presentation/widgets/whats_new_host.dart';
import 'package:saldough/features/app_update/presentation/widgets/whats_new_sheet.dart';

import '../../../../helpers/update_harness.dart';

ReleaseNote _note(int build, int patch, String version, List<NoteGroup> groups) =>
    ReleaseNote(build: build, patch: patch, version: version, groups: groups);

const _fresh = NoteGroup(
  category: NoteCategory.newFeature,
  notes: [
    LocalizedNote(id: 'Hitung langsung di Catat.', en: 'Calculate right in Record.'),
    LocalizedNote(id: 'Urutan dompet bisa diatur.', en: 'Wallet order can be arranged.'),
  ],
);
const _fixed = NoteGroup(
  category: NoteCategory.fixed,
  notes: [LocalizedNote(id: 'Kembali ke Beranda dulu.', en: 'Back goes to Home first.')],
);

/// Lembar Apa yang baru (APP_UPDATE F3, B-10–B-12) dan pemicunya di Beranda.
void main() {
  setUpAll(() async {
    await (FontLoader('PlusJakartaSans')..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'))).load();
    registerFallbackValue(AppUpdateMemory.empty);
  });

  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));

  group('WhatsNewSheet', () {
    Future<void> pump(WidgetTester tester, List<ReleaseNote> notes, {VoidCallback? onClose}) async {
      tester.view
        ..physicalSize = const Size(360, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: PixelTheme.light,
          home: Scaffold(
            body: WhatsNewSheet(notes: notes, onClose: onClose ?? () {}),
          ),
        ),
      );
    }

    testWidgets('satu versi: judul bernomor versi, kelompok per kategori dengan label sekali', (tester) async {
      await pump(tester, [
        _note(7, 0, '0.6.0', [_fresh, _fixed]),
      ]);
      expect(find.text('Apa yang baru di versi 0.6.0'), findsOneWidget);
      expect(find.text('0.6.0 (7)'), findsOneWidget);
      expect(find.text(t.appUpdate.category.kNew), findsOneWidget, reason: 'label sekali walau dua butir');
      expect(find.text(t.appUpdate.category.fixed), findsOneWidget);
      expect(find.text('Hitung langsung di Catat.'), findsOneWidget);
      expect(find.text('Urutan dompet bisa diatur.'), findsOneWidget);
      expect(find.text('✨'), findsOneWidget);
      expect(find.text('🛠️'), findsOneWidget);
    });

    testWidgets('pembaruan kecil: judul tanpa nomor, baris versi memuat "pembaruan"', (tester) async {
      await pump(tester, [
        _note(7, 1, '0.6.0', [_fixed]),
      ]);
      expect(find.text('Apa yang baru'), findsOneWidget);
      expect(find.text('0.6.0 (7), pembaruan 1'), findsOneWidget);
    });

    testWidgets('gabungan: judul versi terbaru dan kepala per versi', (tester) async {
      await pump(tester, [
        _note(9, 0, '0.7.0', [_fresh]),
        _note(7, 0, '0.6.0', [_fixed]),
      ]);
      expect(find.text('Apa yang baru di versi 0.7.0'), findsOneWidget);
      expect(find.text('0.7.0 (9)'), findsNWidgets(2), reason: 'baris versi di kepala dan kepala kelompok');
      expect(find.text('0.6.0 (7)'), findsOneWidget);
    });

    testWidgets('kategori tak dikenal: butir tampil tanpa label dan emoji', (tester) async {
      await pump(tester, [
        _note(7, 0, '0.6.0', [
          const NoteGroup(
            category: null,
            notes: [LocalizedNote(id: 'Butir baru.', en: 'New item.')],
          ),
        ]),
      ]);
      expect(find.text('Butir baru.'), findsOneWidget);
      expect(find.text('✨'), findsNothing);
    });

    testWidgets('Oke memanggil penutup; tidak ada tombol tutup bergambar maupun penutup maskot', (tester) async {
      var closed = 0;
      await pump(
        tester,
        [
          _note(7, 0, '0.6.0', [_fresh]),
        ],
        onClose: () => closed++,
      );
      await tester.tap(find.byKey(const ValueKey('whats-new-ok')));
      expect(closed, 1);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('Terima kasih'), findsNothing);
    });

    for (final locale in [AppLocale.id, AppLocale.en]) {
      testWidgets('360dp ${locale.languageCode}: enam butir bergulir tanpa overflow', (tester) async {
        await tester.runAsync(() => LocaleSettings.setLocale(locale));
        await pump(tester, [
          _note(9, 0, '0.7.0', [_fresh, _fixed]),
          _note(7, 0, '0.6.0', [_fresh, _fixed]),
        ]);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(SingleChildScrollView)).height, lessThanOrEqualTo(330));
        expect(tester.getRect(find.byKey(const ValueKey('whats-new-ok'))).bottom, lessThanOrEqualTo(900));
      });
    }

    testWidgets('judul dan kategori mengikuti bahasa aktif', (tester) async {
      await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en));
      await pump(tester, [
        _note(7, 0, '0.6.0', [_fresh]),
      ]);
      expect(find.text("What's new in version 0.6.0"), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Calculate right in Record.'), findsOneWidget);
      expect(categoryLabel(NoteCategory.security), 'Security');
      expect(categoryLabel(null), isNull);
    });
  });

  group('WhatsNewHost', () {
    late UpdateHarness harness;
    late GetIt container;
    late bool active;

    setUp(() {
      harness = UpdateHarness();
      when(harness.memory.load).thenAnswer((_) async => right(AppUpdateMemory.empty.see(6, 0)));
      harness.notes.entries = {
        (build: 7, patch: 0): _note(7, 0, '0.6.0', [_fresh]),
      };
      container = GetIt.asNewInstance();
      harness.register(container);
      active = true;
    });

    tearDown(() async => harness.dispose());

    Widget app({Widget? child}) => MaterialApp(
      theme: PixelTheme.light,
      builder: (context, child) => SpotlightHost(
        repository: TutorialProgressRepositoryImpl(storage: InMemoryKeyValueStorage()),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            const SpotlightTarget(spotlightKey: SpotlightKey.homeBalance, child: SizedBox(width: 100, height: 40)),
            WhatsNewHost(container: container, active: active),
            ?child,
          ],
        ),
      ),
    );

    Future<void> checkNow(WidgetTester tester) async {
      container<AppUpdateBloc>().add(const AppUpdateChecked());
      await tester.pumpAndSettle();
    }

    testWidgets('tampil sekali; Oke menutup dan menyimpan versi terakhir dilihat', (tester) async {
      await tester.pumpWidget(app());
      await checkNow(tester);
      expect(find.text('Apa yang baru di versi 0.6.0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('whats-new-ok')));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsNothing);
      verify(
        () => harness.memory.save(any(that: isA<AppUpdateMemory>().having((m) => m.lastSeenBuild, 'build', 7))),
      ).called(1);

      container<AppUpdateBloc>().add(const AppUpdateChecked(force: true));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsNothing, reason: 'tidak tampil ulang');
    });

    testWidgets('analitik: whats_new_viewed otomatis dicatat saat lembar dibuka', (tester) async {
      final events = <AnalyticsEvent>[];
      AppAnalytics.debugSink = events.add;
      addTearDown(() => AppAnalytics.debugSink = null);
      await tester.pumpWidget(app());
      await checkNow(tester);
      final viewed = events.where((e) => e.name == 'whats_new_viewed').toList();
      expect(viewed, hasLength(1));
      expect(viewed.single.parameters, {'build': 7, 'patch': 0, 'source': 'auto'});
    });

    testWidgets('menutup lewat scrim juga berarti sudah dilihat', (tester) async {
      await tester.pumpWidget(app());
      await checkNow(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsNothing);
      verify(() => harness.memory.save(any())).called(1);
    });

    testWidgets('Beranda bukan tab aktif: menunggu; begitu aktif, tampil', (tester) async {
      active = false;
      await tester.pumpWidget(app());
      await checkNow(tester);
      expect(find.byType(WhatsNewSheet), findsNothing);

      active = true;
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsOneWidget);
    });

    testWidgets('selama tur spotlight tampil: menunggu; tur selesai, lembar tampil', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      final controller = SpotlightHost.maybeOf(tester.element(find.byType(WhatsNewHost)), listen: false)!;
      await controller.maybeStart(TourId.home);
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.isActive, isTrue);

      container<AppUpdateBloc>().add(const AppUpdateChecked());
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WhatsNewSheet), findsNothing);

      await controller.finish();
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsOneWidget);
    });

    testWidgets('tanpa catatan yang menunggu: tidak ada lembar dan tidak ada galat', (tester) async {
      harness.notes.entries = {};
      await tester.pumpWidget(app());
      await checkNow(tester);
      expect(find.byType(WhatsNewSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bloc tidak terdaftar: kosong', (tester) async {
      container = GetIt.asNewInstance();
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.byType(WhatsNewSheet), findsNothing);
    });
  });
}
