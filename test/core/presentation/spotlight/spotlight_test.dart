import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/tutorial/tutorial.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late TutorialProgressRepositoryImpl repository;
  late int addTaps;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = TutorialProgressRepositoryImpl(storage: storage);
    addTaps = 0;
  });

  /// Layar uji bertiga target tur Dompet. [withCard] false menghilangkan
  /// target kedua (langkah bersyarat). [addAtBottom] memindah tombol tambah
  /// ke dasar layar.
  Widget screen({bool withCard = true, bool visible = true, bool ready = true, bool addAtBottom = false}) {
    return TourVisibility(
      visible: visible,
      child: TourTrigger(
        tour: TourId.wallet,
        ready: ready,
        child: Scaffold(
          body: Column(
            children: [
              const SpotlightTarget(
                spotlightKey: SpotlightKey.walletSummary,
                child: SizedBox(height: 120, child: Placeholder()),
              ),
              if (withCard)
                const SpotlightTarget(
                  spotlightKey: SpotlightKey.walletCard,
                  child: SizedBox(height: 60, child: Text('kartu')),
                ),
              if (addAtBottom) const Spacer(),
              SpotlightTarget(
                spotlightKey: SpotlightKey.walletAdd,
                child: TextButton(onPressed: () => addTaps++, child: const Text('tambah')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, Widget home, {bool animate = false, bool withHost = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: !animate),
          child: withHost ? SpotlightHost(repository: repository, child: child!) : child!,
        ),
        home: home,
      ),
    );
    if (animate) {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await tester.pumpAndSettle();
    }
  }

  Future<TutorialProgress> progress() async => (await repository.load()).getOrElse((_) => TutorialProgress.empty);

  Finder bubbleWithLabel(int current, int total, String title, String body) =>
      find.bySemanticsLabel(t.tour.stepSemantics(current: current, total: total, title: title, body: body));

  testWidgets('tur tampil sekali, berjalan per langkah, lalu tercatat selesai', (tester) async {
    await pump(tester, screen());

    expect(bubbleWithLabel(1, 3, t.tour.walletSummaryTitle, t.tour.walletSummaryBody), findsOneWidget);
    await tester.tap(find.text(t.tour.nextAction));
    await tester.pumpAndSettle();
    expect(find.text(t.tour.walletCardTitle), findsOneWidget);
    await tester.tap(find.text(t.tour.nextAction));
    await tester.pumpAndSettle();
    expect(find.text(t.tour.walletAddTitle), findsOneWidget);
    await tester.tap(find.text(t.tour.doneAction));
    await tester.pumpAndSettle();

    expect(find.text(t.tour.walletAddTitle), findsNothing);
    expect((await progress()).completedTours, {TourId.wallet});

    // Host baru di atas penyimpanan yang sama: tur tidak tampil lagi.
    await tester.pumpWidget(const SizedBox());
    await pump(tester, screen());
    expect(find.text(t.tour.walletSummaryTitle), findsNothing);
  });

  testWidgets('Lewati tur menutup dan menandai selesai', (tester) async {
    await pump(tester, screen());

    await tester.tap(find.text(t.tour.skipAction));
    await tester.pumpAndSettle();

    expect(find.text(t.tour.walletSummaryTitle), findsNothing);
    expect((await progress()).hasCompleted(TourId.wallet), isTrue);
  });

  testWidgets('tombol kembali sistem menutup tur, bukan layarnya', (tester) async {
    await pump(tester, screen());

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text(t.tour.walletSummaryTitle), findsNothing);
    expect(find.text('tambah'), findsOneWidget);
    expect((await progress()).hasCompleted(TourId.wallet), isTrue);
  });

  testWidgets('langkah yang targetnya tidak ada dilewati diam-diam', (tester) async {
    await pump(tester, screen(withCard: false));

    expect(bubbleWithLabel(1, 2, t.tour.walletSummaryTitle, t.tour.walletSummaryBody), findsOneWidget);
    await tester.tap(find.text(t.tour.nextAction));
    await tester.pumpAndSettle();
    expect(find.text(t.tour.walletAddTitle), findsOneWidget);
    expect(find.text(t.tour.walletCardTitle), findsNothing);
  });

  testWidgets('ketukan pada target diserap selama tur', (tester) async {
    await pump(tester, screen(addAtBottom: true));

    await tester.tap(find.text('tambah'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(addTaps, 0);
    expect(find.text(t.tour.walletSummaryTitle), findsOneWidget);
  });

  testWidgets('gelembung di bawah target atas, di atas target bawah', (tester) async {
    await pump(tester, screen(withCard: false, addAtBottom: true));

    final summary = tester.getRect(find.byType(Placeholder));
    final bubbleTop = tester.getRect(find.text(t.tour.walletSummaryTitle));
    expect(bubbleTop.top, greaterThan(summary.bottom));

    await tester.tap(find.text(t.tour.nextAction));
    await tester.pumpAndSettle();
    final add = tester.getRect(find.text('tambah'));
    final bubbleBottom = tester.getRect(find.text(t.tour.doneAction));
    expect(bubbleBottom.bottom, lessThan(add.top));
  });

  testWidgets('tidak mulai selama tab tersembunyi atau belum siap', (tester) async {
    await pump(tester, screen(visible: false));
    expect(find.text(t.tour.walletSummaryTitle), findsNothing);

    await pump(tester, screen(ready: false));
    expect(find.text(t.tour.walletSummaryTitle), findsNothing);

    await pump(tester, screen());
    expect(find.text(t.tour.walletSummaryTitle), findsOneWidget);
  });

  testWidgets('tanpa SpotlightHost, target dan pemicu tidak melakukan apa pun', (tester) async {
    await pump(tester, screen(), withHost: false);

    expect(find.text('tambah'), findsOneWidget);
    expect(find.text(t.tour.walletSummaryTitle), findsNothing);
  });

  testWidgets('dengan gerak aktif: lubang berpindah, centang penutup, tanpa galat', (tester) async {
    await pump(tester, screen(withCard: false), animate: true);

    expect(find.text(t.tour.walletSummaryTitle), findsOneWidget);
    await tester.tap(find.text(t.tour.nextAction));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text(t.tour.doneAction));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
    expect(find.text(t.tour.walletAddTitle), findsNothing);
    expect((await progress()).hasCompleted(TourId.wallet), isTrue);
  });
}
