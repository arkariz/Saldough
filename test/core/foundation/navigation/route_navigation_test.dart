import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';

/// `pushRoute` (ADR-030 §3.3): kunci bertipe → rute Flutter dari
/// `RouteNode` yang sama dengan `go_router`.
final class _NameInput extends RouteInput {
  const _NameInput(this.name);
  final String name;
}

abstract final class _Keys {
  static const page = RouteKey<_NameInput>('test.page');
  static const sheet = RouteKey<_NameInput>('test.sheet');
  static const flow = RouteKey<EmptyInput>('test.flow');
  static const missing = RouteKey<EmptyInput>('test.missing');
}

final class _Module extends FeatureRouteModule {
  const _Module();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<_NameInput>(key: _Keys.page, builder: (_, input) => Scaffold(body: Text('halaman ${input.name}'))),
    RouteNode.typed<_NameInput>(
      key: _Keys.sheet,
      transition: RouteTransition.slideFromBottom,
      builder: (context, input) => Text('lembar ${input.name}', style: TextStyle(color: Theme.of(context).primaryColor)),
    ),
    RouteNode.typed<EmptyInput>(
      key: _Keys.flow,
      transition: RouteTransition.none,
      builder: (context, _) => TextButton(onPressed: () => Navigator.of(context).pop('selesai'), child: const Text('alur')),
    ),
  ];
}

void main() {
  late BuildContext caller;

  Future<void> pump(WidgetTester tester) async {
    final container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(RouteRegistry.fromModules(const [_Module()]));
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          home: Theme(
            data: ThemeData(primaryColor: const Color(0xFF3B3A8F)),
            child: Builder(
              builder: (context) {
                caller = context;
                return const Scaffold(body: Text('pemanggil'));
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('kunci halaman membuka halaman dengan input bertipe', (tester) async {
    await pump(tester);
    unawaited(caller.pushRoute(_Keys.page, const _NameInput('dompet')));
    await tester.pumpAndSettle();

    expect(find.text('halaman dompet'), findsOneWidget);
    expect(find.text('pemanggil'), findsNothing);
  });

  testWidgets('slideFromBottom = lembar modal yang memakai tema pemanggil', (tester) async {
    await pump(tester);
    unawaited(caller.pushRoute(_Keys.sheet, const _NameInput('catat')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.widget<Text>(find.text('lembar catat')).style?.color, const Color(0xFF3B3A8F));
  });

  testWidgets('none = alur transparan: pemanggil tetap tampil, hasil pop diteruskan', (tester) async {
    await pump(tester);
    final result = caller.pushRoute<EmptyInput, String>(_Keys.flow, const EmptyInput());
    await tester.pumpAndSettle();

    expect(find.text('pemanggil'), findsOneWidget);
    await tester.tap(find.text('alur'));
    await tester.pumpAndSettle();
    expect(await result, 'selesai');
  });

  testWidgets('kunci yang belum didaftarkan melempar StateError yang jelas', (tester) async {
    await pump(tester);
    expect(() => caller.pushRoute(_Keys.missing, const EmptyInput()), throwsStateError);
  });
}
