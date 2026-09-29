import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_scene.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Cara pengguna meninggalkan onboarding.
enum OnboardingOutcome {
  /// Lewati, "Nanti saja", atau "Tutup".
  dismissed,

  /// "Buat Dompet Pertama" (KO-6).
  createWallet,

  /// "Sudah punya akun? Masuk" (ADR-024 §3.1).
  signIn,
}

/// Onboarding empat layar geser + satu layar akhir (ONBOARDING_PLAN §3,
/// ART_BRIEF §3), dengan adegan bergerak ADR-021 §3.7.
///
/// Berada di luar `AppShellPage`, jadi memasang [PixelTheme] sendiri.
/// Halaman ini tidak menyimpan apa pun — [onFinished] yang memutuskan
/// (lihat `buildOnboardingRoute`).
class OnboardingPage extends StatefulWidget {
  /// Membuat [OnboardingPage].
  const OnboardingPage({required this.onFinished, this.mode = OnboardingMode.firstRun, super.key});

  /// Dipanggil sekali saat pengguna meninggalkan onboarding.
  final Future<void> Function(OnboardingOutcome outcome) onFinished;

  /// Mode pembukaan.
  final OnboardingMode mode;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const int _count = onboardingSlideCount;

  bool get _isLast => _page == _count - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(OnboardingOutcome outcome) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished(outcome);
    if (mounted) setState(() => _finishing = false);
  }

  void _next() {
    final duration = MotionPolicy.duration(context, const Duration(milliseconds: 420));
    if (duration == Duration.zero) {
      _controller.jumpToPage(_page + 1);
    } else {
      unawaited(
        _controller.nextPage(
          duration: duration,
          curve: const SteppedCurve(8, curve: Curves.easeInOut),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PixelTheme(
      child: Builder(
        builder: (context) {
          final colors = context.appColors;
          final review = widget.mode == OnboardingMode.review;
          return Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: OnboardingBackdrop(controller: _controller)),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, 0),
                        child: SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.app.title.toUpperCase(),
                                  style: transactionLabelStyle(context, color: colors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!_isLast || review)
                                AppButton.tertiary(
                                  label: review ? t.onboarding.closeAction : t.onboarding.skipAction,
                                  onPressed: _finishing ? null : () => _finish(OnboardingOutcome.dismissed),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: _count,
                          onPageChanged: (page) => setState(() => _page = page),
                          itemBuilder: (context, index) => OnboardingSlide(
                            index: index,
                            active: index == _page,
                            controller: _controller,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OnboardingPageIndicator(count: _count, current: _page),
                            const SizedBox(height: AppSpacing.md),
                            AnimatedSwitcher(
                              duration: MotionPolicy.duration(context, const Duration(milliseconds: 240)),
                              switchInCurve: const SteppedCurve(4),
                              switchOutCurve: const SteppedCurve(4),
                              child: _actions(context, review),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actions(BuildContext context, bool review) {
    if (!_isLast) {
      return SizedBox(
        key: const ValueKey('next'),
        width: double.infinity,
        child: AppButton(label: t.onboarding.nextAction, onPressed: _next),
      );
    }
    if (review) {
      return SizedBox(
        key: const ValueKey('close'),
        width: double.infinity,
        child: AppButton(
          label: t.onboarding.closeAction,
          onPressed: _finishing ? null : () => _finish(OnboardingOutcome.dismissed),
        ),
      );
    }
    return Column(
      key: const ValueKey('final'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Satu denyut saat layar akhir tiba (ADR-021 §3.7).
        PixelPop(
          delay: const Duration(milliseconds: 200),
          child: AppButton(
            label: t.onboarding.createWalletAction,
            onPressed: _finishing ? null : () => _finish(OnboardingOutcome.createWallet),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: AppButton.tertiary(
            label: t.onboarding.laterAction,
            onPressed: _finishing ? null : () => _finish(OnboardingOutcome.dismissed),
          ),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AppButton.tertiary(
              label: t.onboarding.signInAction,
              onPressed: _finishing ? null : () => _finish(OnboardingOutcome.signIn),
            ),
          ),
        ),
      ],
    );
  }
}
