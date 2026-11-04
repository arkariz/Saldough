import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_module.dart';
import 'package:saldough/shared/auth/auth.dart';
import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_plus_purchasing.dart';

final class _StubAccountModule extends FeatureRouteModule {
  @override
  List<RouteNode> get routes => [
    RouteNode.typed<EmptyInput>(
      key: AccountRouteKeys.page,
      defaultInput: () => const EmptyInput(),
      builder: (context, _) => const Scaffold(body: Text('layar-akun')),
    ),
  ];
}

/// Tombol Masuk di paywall harus membawa pengguna ke tempat masuk, bukan hanya
/// menutup paywall lalu mengembalikannya ke layar asal (mis. Mulai cepat).
void main() {
  late GetIt container;

  setUp(() {
    container = GetIt.asNewInstance()
      ..registerSingleton<RouteRegistry>(RouteRegistry.fromModules([const PremiumRouteModule(), _StubAccountModule()]))
      ..registerSingleton<PlusPurchasing>(FakePlusPurchasing(selling: false))
      ..registerSingleton<AuthRepository>(FakeAuthRepository());
  });

  Future<void> openPaywall(WidgetTester tester, PaywallTrigger trigger) async {
    await tester.pumpWidget(
      ScopeProvider(
        container: container,
        child: MaterialApp(
          theme: PixelTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('layar-asal'),
                  TextButton(
                    onPressed: () => context.pushRoute(PremiumRouteKeys.paywall, PaywallInput(trigger)),
                    child: const Text('buka'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('dari batas sumber notifikasi: Masuk membuka Akun', (tester) async {
    await openPaywall(tester, PaywallTrigger.notificationSource);
    await tester.tap(find.text(t.premium.signInAction));
    await tester.pumpAndSettle();
    expect(find.text('layar-akun'), findsOneWidget);
  });

  testWidgets('dari Akun: Masuk hanya menutup paywall (Akun sudah di bawahnya)', (tester) async {
    await openPaywall(tester, PaywallTrigger.account);
    await tester.tap(find.text(t.premium.signInAction));
    await tester.pumpAndSettle();
    expect(find.text('layar-akun'), findsNothing);
    expect(find.text('layar-asal'), findsOneWidget);
  });
}
