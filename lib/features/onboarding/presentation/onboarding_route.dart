import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart';

/// Membangun rute `/onboarding` (ADR-021 §3.2).
///
/// Mode pertama kali: menyimpan mata uang pilihan (ADR-025 §3.7), menandai
/// onboarding selesai, lalu `go('/home')` dengan [OnboardingOutcome] sebagai
/// `extra` (kecuali `dismissed`); akar komposisi menerjemahkannya menjadi
/// aksi awal shell, jadi fitur ini tidak mengenal shell (ADR-030 §3.1).
/// Mode tinjau (`extra: OnboardingMode.review`, dari menu info): cukup
/// kembali, progres tidak disentuh.
///
/// [enableReminders] menyalakan pengingat rutin (izin notifikasi lalu
/// sakelar) dan disambungkan akar komposisi supaya fitur ini tidak mengimpor
/// `recurring` (ADR-030); `null` = langkah pengingat tidak ditanyakan.
/// Awal periode keuangan disimpan sebagai satu entri sejak awal
/// (`FinancialMonthSchedule.single`), jadi menetapkannya sebelum ada data
/// tidak membuat periode peralihan (FINANCIAL_PERIOD). Tiap jawaban dicatat
/// per langkah, jadi bila onboarding terputus langkah itu tidak ditanya lagi.
Widget buildOnboardingRoute(
  BuildContext context,
  GoRouterState state, {
  Future<bool> Function()? enableReminders,
}) {
  final mode = state.extra is OnboardingMode ? state.extra! as OnboardingMode : OnboardingMode.firstRun;
  return _OnboardingLoader(mode: mode, enableReminders: enableReminders);
}

/// Memuat progres langkah wajib sebelum menampilkan [OnboardingPage].
class _OnboardingLoader extends StatefulWidget {
  const _OnboardingLoader({required this.mode, required this.enableReminders});

  final OnboardingMode mode;
  final Future<bool> Function()? enableReminders;

  @override
  State<_OnboardingLoader> createState() => _OnboardingLoaderState();
}

class _OnboardingLoaderState extends State<_OnboardingLoader> {
  TutorialProgress? _progress;

  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) return;
    _loading = true;
    unawaited(_load(ScopeProvider.of(context)));
  }

  Future<void> _load(GetIt container) async {
    final progress = widget.mode == OnboardingMode.review
        ? TutorialProgress.empty
        : (await container<TutorialProgressRepository>().load()).getOrElse((_) => TutorialProgress.empty);
    if (mounted) setState(() => _progress = progress);
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    if (progress == null) return const ColoredBox(color: Color(0x00000000));
    return _page(context, progress);
  }

  Widget _page(BuildContext context, TutorialProgress progress) {
    final mode = widget.mode;
    final container = ScopeProvider.of(context);
    final enableReminders = widget.enableReminders;
    Future<void> answered(OnboardingStep step) async {
      await container<TutorialProgressRepository>().markOnboardingStepAnswered(step);
    }

    return OnboardingPage(
      mode: mode,
      skipPeriod: !progress.isStepPending(OnboardingStep.period),
      skipReminder: !progress.isStepPending(OnboardingStep.reminder),
      onPeriodConfirmed: mode == OnboardingMode.review
          ? null
          : (start) async {
              final saved = await container<FinancialMonthPreferenceRepository>().save(
                FinancialMonthSchedule.single(start),
              );
              if (saved.isLeft()) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
                }
                return false;
              }
              ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.single(start);
              await answered(OnboardingStep.period);
              AppAnalytics.log(DiscoveryEvents.stepAnswered(step: 'period', choice: 'confirmed'));
              return true;
            },
      onTurnOnReminders: mode == OnboardingMode.review || enableReminders == null
          ? null
          : () async {
              final on = await enableReminders();
              await answered(OnboardingStep.reminder);
              AppAnalytics.log(DiscoveryEvents.stepAnswered(step: 'reminder', choice: 'turned_on'));
              if (on) AppAnalytics.log(DiscoveryEvents.featureEnabled(feature: 'reminder', via: 'onboarding'));
              return on;
            },
      onRemindersDeclined: () async {
        await answered(OnboardingStep.reminder);
        AppAnalytics.log(DiscoveryEvents.stepAnswered(step: 'reminder', choice: 'not_now'));
      },
      // ADR-028 §3.4: bahasa langsung diterapkan dan disimpan saat diketuk.
      onLanguageSelected: (locale) async {
        final changed = await container<ChangeAppLanguage>()(locale);
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
        // Mata uang wajib tersimpan sebelum onboarding ditandai selesai:
        // kalau penyimpanan gagal, pengguna tetap di penutup dan bisa mencoba
        // lagi, bukan diam-diam jatuh ke IDR saat dibuka ulang.
        if ((await container<CurrencyPreferenceRepository>().save(chosen)).isLeft()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.common.genericErrorMessage)));
          }
          return;
        }
        ActiveCurrency.notifier.value = chosen;
        await container<TutorialProgressRepository>().markOnboardingDone();
        if (!context.mounted) return;
        context.go(AppRouteRegistry.homePath, extra: outcome == OnboardingOutcome.dismissed ? null : outcome);
      },
    );
  }
}
