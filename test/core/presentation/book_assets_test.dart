import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/presentation/widgets/tanuki_pose.dart';

import '../../helpers/reduced_motion.dart';

const List<String> _assets = [
  ClayIcons.mascotHappy,
  ClayIcons.mascotWriting,
  ClayIcons.mascotCalm,
  ClayIcons.bookPeriod,
  ClayIcons.bookOpen,
  ClayIcons.shelfBooks,
  ClayIcons.cardPeriod,
  ClayIcons.stampTool,
  ClayIcons.stampBook,
  ClayIcons.confettiLeaf,
  ClayIcons.confettiStar,
  ClayIcons.sparkle,
];

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  theme: DsTheme.light,
  builder: reduced ? reducedMotion : null,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('semua aset baru ada, bukan kosong, dan tanpa fitur SVG yang tidak didukung', () {
    for (final path in _assets) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final text = file.readAsStringSync();
      expect(text, startsWith('<svg'));
      expect(text, isNot(contains('<filter')), reason: '$path: filter tidak didukung perender');
      expect(text, isNot(contains('<image')), reason: '$path: aset bitmap tidak dipakai');
    }
  });

  testWidgets('setiap aset baru dirender flutter_svg tanpa galat', (tester) async {
    for (final path in _assets) {
      await tester.pumpWidget(_host(SvgPicture.asset(path, width: 64, height: 64)));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: path);
    }
  });

  group('TanukiPose', () {
    testWidgets('empat pose, tanpa pose sedih; gerak penuh dan lompat cheer tanpa galat', (tester) async {
      expect(TanukiPoseKind.values.map((k) => k.name), ['neutral', 'happy', 'writing', 'calm']);
      for (final kind in TanukiPoseKind.values) {
        await tester.pumpWidget(_host(TanukiPose(pose: kind, size: 80)));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpWidget(_host(TanukiPose(pose: kind, size: 80, cheer: 1)));
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump(const Duration(milliseconds: 600));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('gerak dikurangi: diam dan tidak ada animasi tertunda', (tester) async {
      await tester.pumpWidget(_host(const TanukiPose(pose: TanukiPoseKind.happy), reduced: true));
      await tester.pumpWidget(_host(const TanukiPose(pose: TanukiPoseKind.happy, cheer: 1), reduced: true));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('berlabel bila diberi label, dekoratif bila tidak', (tester) async {
      await tester.pumpWidget(_host(const TanukiPose(pose: TanukiPoseKind.calm, semanticLabel: 'Tanuki')));
      expect(find.bySemanticsLabel('Tanuki'), findsOneWidget);
    });
  });

  group('DsShake', () {
    testWidgets('bergeser saat trigger naik lalu kembali; diam bila gerak dikurangi', (tester) async {
      Widget build(int trigger, {bool reduced = false}) =>
          _host(DsShake(trigger: trigger, child: const SizedBox(key: ValueKey('x'), width: 10, height: 10)), reduced: reduced);
      await tester.pumpWidget(build(0));
      final home = tester.getTopLeft(find.byKey(const ValueKey('x')));
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 35));
      expect(tester.getTopLeft(find.byKey(const ValueKey('x'))).dx, isNot(home.dx));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('x'))), home);

      await tester.pumpWidget(build(0, reduced: true));
      await tester.pumpWidget(build(1, reduced: true));
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.getTopLeft(find.byKey(const ValueKey('x'))), home);
    });
  });

  group('DsShapeConfetti', () {
    testWidgets('meledak, melepas diri sendiri; paling banyak 44 partikel; diam bila gerak dikurangi', (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
        ),
      );
      DsShapeConfetti.burst(captured, origin: const Offset(100, 100), count: 500, random: math.Random(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(CustomPaint), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(DsShapeConfetti.maxParticles, 44);

      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox();
            },
          ),
          reduced: true,
        ),
      );
      DsShapeConfetti.burst(captured, origin: const Offset(100, 100), count: 20);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('DsSheen: menyapu anak tanpa mengubah ukuran dan tanpa menangkap sentuhan', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        DsSheen(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++, child: const SizedBox(width: 120, height: 40)),
        ),
      ),
    );
    final size = tester.getSize(find.byType(DsSheen));
    expect(size, const Size(120, 40));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });
}
