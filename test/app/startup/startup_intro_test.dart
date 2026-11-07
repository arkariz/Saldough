import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/startup/startup_intro.dart';

final Finder _overlay = find.byWidgetPredicate(
  (w) => w is ColoredBox && (w.color == StartupIntro.lightBackground || w.color == StartupIntro.darkBackground),
);

class _Probe extends StatefulWidget {
  const _Probe();

  static int mounts = 0;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.mounts++;
  }

  @override
  Widget build(BuildContext context) => const Text('aplikasi');
}

Widget _app({bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: const StartupIntro(child: _Probe()),
  ),
);

Future<void> _preload(WidgetTester tester) => tester.runAsync(StartupIntro.preload);

void main() {
  setUp(() => _Probe.mounts = 0);

  testWidgets('tanpa preload, aplikasi tampil tanpa intro', (tester) async {
    await tester.pumpWidget(_app());

    expect(_overlay, findsNothing);
    expect(find.text('aplikasi'), findsOneWidget);
  });

  testWidgets('intro diputar sekali lalu dilepas tanpa memasang ulang aplikasi', (tester) async {
    await _preload(tester);
    expect(StartupIntro.isPending, isTrue);

    await tester.pumpWidget(_app());
    expect(_overlay, findsOneWidget);
    expect(find.text('aplikasi'), findsOneWidget, reason: 'aplikasi sudah dibangun di bawah intro');
    expect(StartupIntro.isPending, isFalse);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(_overlay, findsOneWidget);

    await tester.pump(StartupIntro.duration);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(_overlay, findsNothing);
    expect(_Probe.mounts, 1);

    // State baru (mis. boot ulang) tidak memutar lagi.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app());
    expect(_overlay, findsNothing);
  });

  testWidgets('ketuk melompat ke akhir', (tester) async {
    await _preload(tester);
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(_overlay);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(_overlay, findsNothing);
  });

  testWidgets('gerak dikurangi melewati intro', (tester) async {
    await _preload(tester);
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.pump();

    expect(_overlay, findsNothing);
    expect(find.text('aplikasi'), findsOneWidget);
    expect(StartupIntro.isPending, isFalse);
  });
}
