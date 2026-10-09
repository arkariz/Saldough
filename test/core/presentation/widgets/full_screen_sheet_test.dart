import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Isi lembar tidak tertutup bilah navigasi sistem (edge-to-edge Android).
void main() {
  const navBar = 48.0;
  const height = 800.0;

  Future<void> open(WidgetTester tester, Future<void> Function(BuildContext context) show) async {
    tester.view
      ..physicalSize = const Size(360, height)
      ..devicePixelRatio = 1
      ..padding = const FakeViewPadding(top: 24, bottom: navBar);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => show(context), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  const bottomButton = Key('bottom');
  Widget content() => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('isi'),
      SizedBox(key: bottomButton, height: 48, width: double.infinity),
    ],
  );

  testWidgets('showAppSheet: tombol terbawah di atas navigasi sistem', (tester) async {
    await open(tester, (context) => showAppSheet<void>(context, builder: (_) => content()));
    expect(tester.getRect(find.byKey(bottomButton)).bottom, lessThanOrEqualTo(height - navBar));
  });

  testWidgets('showFullScreenSheet: isi setinggi layar berhenti di atas navigasi sistem', (tester) async {
    await open(
      tester,
      (context) => showFullScreenSheet<void>(
        context,
        builder: (_) => const SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(key: bottomButton, height: 48),
          ),
        ),
      ),
    );
    expect(tester.getRect(find.byKey(bottomButton)).bottom, height - navBar);
  });
}
