import 'package:di/di.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/domain/trial_gift.dart';
import 'package:saldough/features/premium/presentation/bloc/paywall_bloc.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/pages/paywall_page.dart';
import 'package:saldough/features/premium/presentation/pages/plus_features_page.dart';
import 'package:saldough/features/premium/presentation/pages/trial_gift_page.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

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
        return BlocProvider(
          create: (_) =>
              PaywallBloc(purchasing: container<PlusPurchasing>())
                ..add(const PaywallStarted()),
          child: PaywallPage(
            trigger: input.trigger,
            signedIn: container<AuthRepository>().currentUser != null,
            onSignIn: () =>
                context.pushRoute(AccountRouteKeys.page, const EmptyInput()),
          ),
        );
      },
    ),
    RouteNode.typed<PlusFeaturesInput>(
      key: PremiumRouteKeys.features,
      defaultInput: () => const PlusFeaturesInput(),
      builder: (context, input) => PlusFeaturesPage(fromPaywall: input.fromPaywall),
    ),
    RouteNode.typed<TrialGiftInput>(
      key: PremiumRouteKeys.trialGift,
      builder: (context, input) =>
          TrialGiftPage(info: input.info, gift: ScopeProvider.of(context)<TrialGift>()),
    ),
  ];

  @override
  List<DevEntry> get devEntries => [
    DevEntry.typed<PaywallInput>(
      label: 'Paywall',
      category: 'premium',
      key: PremiumRouteKeys.paywall,
      inputFactory: () => const PaywallInput(PaywallTrigger.account),
    ),
  ];
}
