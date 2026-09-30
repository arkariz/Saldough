import 'package:di/di.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart';

/// Membangun rute `/onboarding` (ADR-021 §3.2).
///
/// Mode pertama kali: menyimpan mata uang pilihan (ADR-025 §3.7), menandai
/// onboarding selesai, lalu `go('/home')`, dengan
/// [ShellStartAction.createWallet] kalau pengguna memilih "Buat Dompet
/// Pertama". Mode tinjau (`extra: OnboardingMode.review`, dari menu info):
/// cukup kembali, progres tidak disentuh.
Widget buildOnboardingRoute(BuildContext context, GoRouterState state) {
  final mode = state.extra is OnboardingMode ? state.extra! as OnboardingMode : OnboardingMode.firstRun;
  return OnboardingPage(
    mode: mode,
    // ADR-028 §3.4: bahasa langsung diterapkan dan disimpan saat diketuk.
    onLanguageSelected: (locale) async {
      final changed = await ScopeProvider.of(context)<ChangeAppLanguage>()(locale);
      if (changed.isLeft() && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
      }
    },
    onFinished: (outcome, currency) async {
      if (mode == OnboardingMode.review) {
        context.pop();
        return;
      }
      // `OnboardingPage` selalu mengirim mata uang di mode pertama kali.
      final chosen = currency!;
      final container = ScopeProvider.of(context);
      // Mata uang wajib tersimpan sebelum onboarding ditandai selesai:
      // kalau penyimpanan gagal, pengguna tetap di langkah mata uang dan
      // bisa mencoba lagi, bukan diam-diam jatuh ke IDR saat dibuka ulang.
      if ((await container<CurrencyPreferenceRepository>().save(chosen)).isLeft()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
        }
        return;
      }
      ActiveCurrency.notifier.value = chosen;
      await container<TutorialProgressRepository>().markOnboardingDone();
      if (!context.mounted) return;
      context.go(
        AppRouteRegistry.homePath,
        extra: switch (outcome) {
          OnboardingOutcome.createWallet => ShellStartAction.createWallet,
          OnboardingOutcome.signIn => ShellStartAction.openAccount,
          OnboardingOutcome.dismissed => null,
        },
      );
    },
  );
}
