import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: DsTheme.light,
  builder: (context, home) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: home!,
  ),
  home: Scaffold(body: Stack(children: [child])),
);

void main() {
  test('dsKeyframes menginterpolasi dan memotong di ujung', () {
    final keys = [(0.0, 0.0), (0.5, 10.0), (1.0, 0.0)];
    expect(dsKeyframes(-1, keys), 0);
    expect(dsKeyframes(0.25, keys), 5);
    expect(dsKeyframes(0.75, keys), 5);
    expect(dsKeyframes(2, keys), 0);
  });

  test('kemajuan app bar menyusut 110–240px', () {
    expect(DsCollapsingTopBar.progressFor(0), 0);
    expect(DsCollapsingTopBar.progressFor(110), 0);
    expect(DsCollapsingTopBar.progressFor(175), closeTo(0.5, 0.001));
    expect(DsCollapsingTopBar.progressFor(240), 1);
    expect(DsCollapsingTopBar.progressFor(999), 1);
  });

  group('DsCountUp', () {
    testWidgets('berhitung dari 0 ke nilai akhir', (tester) async {
      await tester.pumpWidget(_host(DsCountUp(value: 1000, builder: (_, v) => Text('$v'))));
      expect(find.text('0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      final mid = int.parse(tester.widget<Text>(find.byType(Text)).data!);
      expect(mid, inExclusiveRange(0, 1000));
      await tester.pumpAndSettle();
      expect(find.text('1000'), findsOneWidget);
    });

    testWidgets('gerak dikurangi: langsung nilai akhir', (tester) async {
      await tester.pumpWidget(_host(DsCountUp(value: 1000, builder: (_, v) => Text('$v')), reduced: true));
      expect(find.text('1000'), findsOneWidget);
    });
  });

  testWidgets('DsFlipSwitcher mengganti isi dan menyisakan satu anak', (tester) async {
    Widget build({required bool hidden}) => _host(
      DsFlipSwitcher(child: Text(hidden ? '••••' : '123', key: ValueKey(hidden))),
    );
    await tester.pumpWidget(build(hidden: false));
    await tester.pumpWidget(build(hidden: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('123'), findsOneWidget);
    expect(find.text('••••'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('123'), findsNothing);
    expect(find.text('••••'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DsCollapsingTopBar menampilkan judul susut setelah digulir', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: DsTheme.light,
        home: Scaffold(
          appBar: DsCollapsingTopBar(
            controller: controller,
            wordmark: 'tanukonomy',
            collapsedTitle: const Text('Rp 14.850.000'),
          ),
          body: ListView(controller: controller, children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('$i'))]),
        ),
      ),
    );
    double opacityOf(String text) =>
        tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;
    expect(opacityOf('Rp 14.850.000'), 0);
    expect(opacityOf('tanukonomy'), 1);
    controller.jumpTo(300);
    await tester.pump();
    expect(opacityOf('Rp 14.850.000'), 1);
    expect(opacityOf('tanukonomy'), 0);
  });

  testWidgets('DsCarousel: panah dan titik berpindah halaman', (tester) async {
    final pages = <int>[];
    await tester.pumpWidget(
      _host(
        Align(
          alignment: Alignment.topCenter,
          child: DsCarousel(
            title: 'WAWASAN',
            previousLabel: 'Sebelumnya',
            nextLabel: 'Berikutnya',
            dotLabel: (i) => 'Slide ${i + 1}',
            onPageChanged: pages.add,
            children: const [Center(child: Text('A')), Center(child: Text('B')), Center(child: Text('C'))],
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Berikutnya'));
    await tester.pumpAndSettle();
    expect(pages, [1]);
    await tester.tap(find.bySemanticsLabel('Slide 3'));
    await tester.pumpAndSettle();
    expect(pages, [1, 2]);
    final widths = tester
        .widgetList<AnimatedContainer>(find.descendant(of: find.byType(DsCarouselDots), matching: find.byType(AnimatedContainer)))
        .map((a) => a.constraints!.maxWidth)
        .toList();
    expect(widths, [8, 8, 24]);
  });

  group('DsSegmentMeter breathing', () {
    testWidgets('berjalan tanpa galat dan berhenti saat gerak dikurangi', (tester) async {
      Widget meter({required bool reduced}) => _host(
        const SizedBox(width: 200, child: DsSegmentMeter(value: 0.7, semanticLabel: '70%', breathing: true)),
        reduced: reduced,
      );
      await tester.pumpWidget(meter(reduced: false));
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
      expect(find.byType(ClipRRect), findsNWidgets(7));
      await tester.pumpWidget(meter(reduced: true));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(ClipRRect), findsNothing);
    });
  });

  testWidgets('DsPulse dan DsIdleMotion berulang lalu diam saat gerak dikurangi', (tester) async {
    await tester.pumpWidget(
      _host(const Column(children: [DsPulse(child: DsBadge(label: '3 HARI LAGI')), DsIdleMotion(child: Text('🍃'))])),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(DecoratedBox), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      _host(const Column(children: [DsPulse(child: DsBadge(label: '3 HARI LAGI')), DsIdleMotion(child: Text('🍃'))]), reduced: true),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('DsAmbientLayer', () {
    testWidgets('menggambar 12 partikel, tanpa sentuhan dan semantik', (tester) async {
      await tester.pumpWidget(_host(const SizedBox.expand(child: DsAmbientLayer())));
      await tester.pump(const Duration(seconds: 1));
      for (final p in DsAmbientParticle.defaults) {
        expect(find.text(p.glyph), findsWidgets);
      }
      expect(find.descendant(of: find.byType(DsAmbientLayer), matching: find.byType(Positioned)), findsNWidgets(12));
      expect(find.descendant(of: find.byType(DsAmbientLayer), matching: find.byType(IgnorePointer)), findsWidgets);
    });

    testWidgets('tidak tampil saat gerak dikurangi', (tester) async {
      await tester.pumpWidget(_host(const SizedBox.expand(child: DsAmbientLayer()), reduced: true));
      expect(find.text('🍃'), findsNothing);
    });

    testWidgets('DsAmbientBackdrop menaruh lapisan di belakang konten', (tester) async {
      await tester.pumpWidget(
        _host(const SizedBox.expand(child: DsAmbientBackdrop(child: Text('KONTEN')))),
      );
      final stack = tester.widget<Stack>(find.ancestor(of: find.text('KONTEN'), matching: find.byType(Stack)).first);
      expect(stack.children.first, isA<Positioned>());
      expect((stack.children.last as Text).data, 'KONTEN');
    });

    test('partikel bawaan: 12, setengah daun setengah kilau', () {
      expect(DsAmbientParticle.defaults, hasLength(12));
      expect(DsAmbientParticle.defaults.where((p) => p.kind == DsAmbientKind.leaf), hasLength(6));
    });
  });

  group('DsCelebration', () {
    testWidgets('memasang overlay lalu melepasnya sendiri', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(Builder(builder: (context) {
          ctx = context;
          return const SizedBox();
        })),
      );
      DsCelebration.burst(ctx, origin: const Offset(100, 200), label: '+50 XP', random: math.Random(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('+50 XP'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('+50 XP'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tidak memasang apa pun saat gerak dikurangi', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _host(Builder(builder: (context) {
          ctx = context;
          return const SizedBox();
        }), reduced: true),
      );
      DsCelebration.burst(ctx, origin: Offset.zero, label: '+50 XP');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('+50 XP'), findsNothing);
    });
  });

  testWidgets('DsJiggle berputar saat trigger naik dan kembali ke skala 1', (tester) async {
    Widget build(int trigger) => _host(DsJiggle(trigger: trigger, child: const Text('LVL 12')));
    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(1));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = tester.widget<Transform>(find.ancestor(of: find.text('LVL 12'), matching: find.byType(Transform)).first);
    expect(mid.transform.storage[0], isNot(1.0));
    await tester.pumpAndSettle();
    final end = tester.widget<Transform>(find.ancestor(of: find.text('LVL 12'), matching: find.byType(Transform)).first);
    expect(end.transform.getMaxScaleOnAxis(), closeTo(1, 0.0001));
  });

  testWidgets('DsTapTip muncul saat diketuk dan hilang setelah 2,4 dtk', (tester) async {
    await tester.pumpWidget(
      _host(const Padding(padding: EdgeInsets.only(top: 80), child: DsTapTip(message: 'Aman', child: SizedBox(width: 100, height: 40, child: Text('kartu'))))),
    );
    double opacity() => tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    expect(opacity(), 0);
    await tester.tap(find.text('kartu'));
    await tester.pump();
    expect(opacity(), 1);
    await tester.pump(DsMotion.tip + const Duration(milliseconds: 50));
    expect(opacity(), 0);
    await tester.pumpAndSettle();
  });

  group('DsHeroBalanceCard', () {
    Widget hero({bool hidden = false, VoidCallback? onToggle, bool withStats = true}) => SizedBox(
      width: 340,
      child: DsHeroBalanceCard(
        label: 'TOTAL SALDO',
        currencySymbol: 'Rp',
        amount: '14.850.000',
        semanticAmount: 'Rp14.850.000',
        hidden: hidden,
        toggleLabel: 'Sembunyikan saldo',
        onToggleHidden: onToggle,
        caption: 'Di 5 dompet',
        mascot: const SizedBox(key: Key('mascot')),
        coin: const SizedBox(key: Key('coin'), width: 24, height: 24),
        stats: withStats
            ? const [
                DsHeroStatTile(icon: Icons.arrow_circle_up, label: 'MASUK', value: '+Rp8.500.000'),
                DsHeroStatTile(icon: Icons.arrow_circle_down, label: 'KELUAR', value: '-Rp3.650.000', income: false),
              ]
            : const [],
      ),
    );

    testWidgets('daun, kilau, dan aura bergerak seiring waktu', (tester) async {
      await tester.pumpWidget(_host(hero()));
      Opacity aura() => tester.widget<Opacity>(find.byType(Opacity).first);
      final before = aura().opacity;
      await tester.pump(const Duration(milliseconds: 1500));
      expect(aura().opacity, isNot(before));
      expect(find.byKey(const Key('mascot')), findsOneWidget);
      expect(find.byKey(const Key('coin')), findsOneWidget);
    });

    testWidgets('gerak dikurangi: aura diam dan tak ada animasi tertunda', (tester) async {
      await tester.pumpWidget(_host(hero(), reduced: true));
      final before = tester.widget<Opacity>(find.byType(Opacity).first).opacity;
      await tester.pump(const Duration(seconds: 2));
      expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, before);
      await tester.pumpAndSettle();
    });

    testWidgets('menyembunyikan saldo mengaburkan angka dan tombol mata memantul', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(hero(onToggle: () => taps++)));
      expect(find.text('14.850.000'), findsOneWidget);
      await tester.pumpWidget(_host(hero(hidden: true, onToggle: () => taps++)));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(ImageFiltered), findsWidgets);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('14.850.000'), findsNothing);
      expect(find.text('••••••••'), findsOneWidget);
      await tester.tap(find.byTooltip('Sembunyikan saldo'));
      expect(taps, 1);
    });

    testWidgets('pembaca layar mendapat saldo akhir, bukan angka antara', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(hero()));
      expect(find.bySemanticsLabel('Rp14.850.000'), findsOneWidget);
      await tester.pumpWidget(_host(hero(hidden: true)));
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2)).catchError((_) => 0);
      expect(find.bySemanticsLabel('••••••••'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('kartu miring mengikuti jari lalu kembali saat dilepas', (tester) async {
      await tester.pumpWidget(_host(hero()));
      final card = find.byType(DsHeroBalanceCard);
      final topRight = tester.getTopRight(card) + const Offset(-10, 10);
      final gesture = await tester.startGesture(topRight);
      await tester.pump(const Duration(milliseconds: 300));
      final tilted = tester.widget<AnimatedContainer>(find.descendant(of: card, matching: find.byType(AnimatedContainer)).first);
      expect(tilted.transform!.storage[1], isNot(0.0));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 600));
      final flat = tester.widget<AnimatedContainer>(find.descendant(of: card, matching: find.byType(AnimatedContainer)).first);
      expect(flat.transform!.storage[1].abs(), lessThan(0.001));
    });

    testWidgets('gerak dikurangi: kartu tidak miring', (tester) async {
      await tester.pumpWidget(_host(hero(), reduced: true));
      final gesture = await tester.startGesture(tester.getTopRight(find.byType(DsHeroBalanceCard)) + const Offset(-10, 10));
      await tester.pump();
      final box = tester.widget<AnimatedContainer>(find.descendant(of: find.byType(DsHeroBalanceCard), matching: find.byType(AnimatedContainer)).first);
      expect(box.transform!.isIdentity(), isTrue);
      await gesture.up();
    });

    testWidgets('tanpa overflow di 320dp dengan teks 2x', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DsTheme.light,
          builder: (context, home) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2), disableAnimations: true),
            child: home!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(child: SizedBox(width: 320, child: hero())),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
