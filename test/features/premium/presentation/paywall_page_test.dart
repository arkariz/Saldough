import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_module.dart';
import 'package:saldough/features/premium/presentation/pages/paywall_page.dart';

/// Paywall sementara (T-23.8) sampai rupa final (T-23.17).
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool signedIn,
    VoidCallback? onSignIn,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: PaywallPage(trigger: PaywallTrigger.account, signedIn: signedIn, onSignIn: onSignIn ?? () {}),
      ),
    );
    await tester.pump();
  }

  testWidgets('tanpa akun: ajakan masuk; tombol membuka Akun', (tester) async {
    var opened = 0;
    await pump(tester, signedIn: false, onSignIn: () => opened++);
    expect(find.text(t.premium.signInTitle), findsOneWidget);
    expect(find.text(t.premium.signInBody), findsOneWidget);
    await tester.tap(find.text(t.premium.signInAction));
    expect(opened, 1);
  });

  testWidgets(
    'sudah masuk tetapi bukan Plus: Plus belum dijual, tanpa tombol',
    (tester) async {
      await pump(tester, signedIn: true);
      expect(find.text(t.premium.plusOnlyTitle), findsOneWidget);
      expect(find.text(t.premium.plusOnlyBody), findsOneWidget);
      expect(find.text(t.premium.signInAction), findsNothing);
    },
  );

  testWidgets('muat di 360dp dengan teks 200% tanpa overflow', (tester) async {
    await pump(tester, signedIn: false, scale: 2);
    expect(tester.takeException(), isNull);
  });

  test('modul rute: satu rute paywall dan satu entri menu pengembang', () {
    const module = PremiumRouteModule();
    expect(module.routes, hasLength(1));
    expect(module.devEntries, hasLength(1));
  });

  test('nama pemicu untuk analitik unik dan P1–P10 berurutan', () {
    final names = PaywallTrigger.values.map((t) => t.analyticsName).toList();
    expect(names.toSet(), hasLength(names.length));
    expect(names.take(10), [for (var i = 1; i <= 10; i++) 'P$i']);
  });
}
