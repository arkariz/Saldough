import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/pages/paywall_page.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Modul rute fitur `premium` (ADR-030 §3.3, ADR-041 §3.1).
final class PremiumRouteModule extends FeatureRouteModule {
  /// Membuat [PremiumRouteModule].
  const PremiumRouteModule();

  @override
  List<RouteNode> get routes => [
    RouteNode.typed<PaywallInput>(
      key: PremiumRouteKeys.paywall,
      builder: (context, input) {
        final container = ScopeProvider.of(context);
        return PaywallPage(
          signedIn: container<AuthRepository>().currentUser != null,
          onSignIn: () =>
              context.pushRoute(AccountRouteKeys.page, const EmptyInput()),
        );
      },
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    DevEntry.typed<PaywallInput>(
      label: 'Paywall sementara',
      category: 'premium',
      key: PremiumRouteKeys.paywall,
      inputFactory: () => const PaywallInput(PaywallTrigger.account),
    ),
  ];
}
