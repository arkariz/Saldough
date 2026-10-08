import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_currency_step.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_language_step.dart';
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
/// Mode pertama kali dimulai dengan langkah pilih bahasa (ADR-028 §3.4):
/// bahasa saat ini terpilih, dan mengetuk pilihan lain langsung mengganti
/// teks lewat [OnboardingPage.onLanguageSelected].
///
/// Mode pertama kali: setiap jalan keluar ("Lewati", ajakan layar akhir)
/// lebih dulu melewati langkah pilih mata uang yang tidak bisa dilewati
/// (ADR-025 §3.7) — tanpa tombol lewati, tanpa pilihan otomatis, dan tombol
/// lanjutnya menyebut mata uang yang dipilih.
///
/// Halaman ini tidak menyimpan apa pun — [onFinished] yang memutuskan
/// (lihat `buildOnboardingRoute`).
class OnboardingPage extends StatefulWidget {
  /// Membuat [OnboardingPage].
  const OnboardingPage({
    required this.onFinished,
    this.mode = OnboardingMode.firstRun,
    this.onLanguageSelected,
    super.key,
  });

  /// Dipanggil saat pengguna meninggalkan onboarding. [currency] selalu
  /// terisi di mode pertama kali dan selalu `null` di mode tinjau.
  final Future<void> Function(OnboardingOutcome outcome, AppCurrency? currency) onFinished;

  /// Mode pembukaan.
  final OnboardingMode mode;

  /// Menerapkan dan menyimpan bahasa yang diketuk di langkah bahasa.
  final Future<void> Function(AppLocale locale)? onLanguageSelected;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  /// Jalan keluar yang sedang menunggu pilihan mata uang; terisi berarti
  /// langkah mata uang sedang tampil.
  OnboardingOutcome? _pendingOutcome;
  AppCurrency? _currency;
  late final AppCurrency? _suggested = AppCurrency.forCountry(
    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );

  bool get _choosingCurrency => _pendingOutcome != null;

  /// Langkah bahasa sedang tampil (hanya mode pertama kali, di awal).
  late bool _choosingLanguage = widget.mode == OnboardingMode.firstRun;
  AppLocale _language = LocaleSettings.currentLocale;

  bool get _onStep => _choosingCurrency || _choosingLanguage;

  Future<void> _selectLanguage(AppLocale locale) async {
    setState(() => _language = locale);
    await widget.onLanguageSelected?.call(locale);
  }

  /// Lanjut dari langkah bahasa. Pilihan disimpan lagi di sini: pengguna yang
  /// langsung menekan lanjut tanpa mengetuk pilihan bawaan juga sudah memilih,
  /// jadi lembar bahasa ucapan (ADR-028 §3.8) tidak bertanya lagi (B-17).
  Future<void> _confirmLanguage() async {
    await widget.onLanguageSelected?.call(_language);
    if (mounted) setState(() => _choosingLanguage = false);
  }

  static const int _count = onboardingSlideCount;

  bool get _isLast => _page == _count - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Jalan keluar dari layar geser: mode tinjau langsung selesai, mode
  /// pertama kali menuju langkah mata uang.
  Future<void> _leave(OnboardingOutcome outcome) async {
    if (widget.mode == OnboardingMode.review) return _finish(outcome, null);
    setState(() => _pendingOutcome = outcome);
  }

  void _backToSlides() => setState(() => _pendingOutcome = null);

  Future<void> _finish(OnboardingOutcome outcome, AppCurrency? currency) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await widget.onFinished(outcome, currency);
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
    return PopScope(
      // Tombol kembali sistem di langkah mata uang kembali ke layar geser,
      // bukan keluar dari onboarding.
      canPop: !_choosingCurrency,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToSlides();
      },
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
                        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space2, 0),
                        child: SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.app.title.toUpperCase(),
                                  style: transactionLabelStyle(context, color: colors.ink2),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_choosingCurrency)
                                AppButton.text(
                                  key: const ValueKey('onboarding-back'),
                                  label: t.onboarding.backAction,
                                  onPressed: _finishing ? null : _backToSlides,
                                )
                              else if (_choosingLanguage)
                                const SizedBox.shrink()
                              else if (!_isLast || review)
                                AppButton.text(
                                  label: review ? t.onboarding.closeAction : t.onboarding.skipAction,
                                  onPressed: _finishing ? null : () => _leave(OnboardingOutcome.dismissed),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // Tetap terpasang saat langkah mata uang tampil,
                            // supaya "Kembali" mendarat di layar yang sama.
                            Offstage(
                              offstage: _onStep,
                              child: PageView.builder(
                                controller: _controller,
                                itemCount: _count,
                                onPageChanged: (page) => setState(() => _page = page),
                                itemBuilder: (context, index) => OnboardingSlide(
                                  index: index,
                                  active: index == _page && !_onStep,
                                  controller: _controller,
                                ),
                              ),
                            ),
                            if (_choosingLanguage)
                              OnboardingLanguageStep(selected: _language, onSelected: _selectLanguage),
                            if (_choosingCurrency)
                              OnboardingCurrencyStep(
                                selected: _currency,
                                suggested: _suggested,
                                onSelected: (currency) => setState(() => _currency = currency),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_onStep) ...[
                              OnboardingPageIndicator(count: _count, current: _page),
                              const SizedBox(height: AppSpacing.space4),
                            ],
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
    if (_choosingLanguage) {
      return SizedBox(
        key: const ValueKey('language'),
        width: double.infinity,
        child: AppButton(
          key: const ValueKey('onboarding-language-confirm'),
          label: t.onboarding.languageConfirm,
          onPressed: _confirmLanguage,
        ),
      );
    }
    final pending = _pendingOutcome;
    if (pending != null) {
      final currency = _currency;
      return SizedBox(
        key: const ValueKey('currency'),
        width: double.infinity,
        child: AppButton(
          key: const ValueKey('onboarding-currency-confirm'),
          label: currency == null ? t.onboarding.currencyChooseFirst : t.onboarding.currencyConfirm(code: currency.code),
          onPressed: currency == null || _finishing ? null : () => _finish(pending, currency),
        ),
      );
    }
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
          onPressed: _finishing ? null : () => _finish(OnboardingOutcome.dismissed, null),
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
            onPressed: _finishing ? null : () => _leave(OnboardingOutcome.createWallet),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Center(
          child: AppButton.text(
            label: t.onboarding.laterAction,
            onPressed: _finishing ? null : () => _leave(OnboardingOutcome.dismissed),
          ),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AppButton.text(
              label: t.onboarding.signInAction,
              onPressed: _finishing ? null : () => _leave(OnboardingOutcome.signIn),
            ),
          ),
        ),
      ],
    );
  }
}
