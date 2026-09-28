import 'package:di/di.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart';

/// Membangun rute `/onboarding` (ADR-021 §3.2).
///
/// Mode pertama kali: menandai onboarding selesai lalu `go('/home')`, dengan
/// [ShellStartAction.createWallet] kalau pengguna memilih "Buat Dompet
/// Pertama". Mode tinjau (`extra: OnboardingMode.review`, dari menu info):
/// cukup kembali, progres tidak disentuh.
Widget buildOnboardingRoute(BuildContext context, GoRouterState state) {
  final mode = state.extra is OnboardingMode ? state.extra! as OnboardingMode : OnboardingMode.firstRun;
  return OnboardingPage(
    mode: mode,
    onFinished: (outcome) async {
      if (mode == OnboardingMode.review) {
        context.pop();
        return;
      }
      await ScopeProvider.of(context)<TutorialProgressRepository>().markOnboardingDone();
      if (!context.mounted) return;
      context.go(
        AppRouteRegistry.homePath,
        extra: outcome == OnboardingOutcome.createWallet ? ShellStartAction.createWallet : null,
      );
    },
  );
}
