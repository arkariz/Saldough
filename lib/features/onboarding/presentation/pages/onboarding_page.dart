import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/motion/motion.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_currency_step.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_gate_steps.dart';
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

/// Langkah wajib mode pertama kali, urut tampil (FEATURE_DISCOVERY §4):
/// bahasa › layar geser › mata uang › awal periode › pengingat › penutup.
enum _Step { language, slides, currency, period, reminder, finale }

/// Onboarding: layar geser pengantar, empat langkah wajib, lalu penutup
/// (ONBOARDING_PLAN §3, ART_BRIEF §3, FEATURE_DISCOVERY §4), dengan adegan
/// bergerak ADR-021 §3.7.
///
/// Mode pertama kali dimulai dengan langkah pilih bahasa (ADR-028 §3.4):
/// bahasa saat ini terpilih, dan mengetuk pilihan lain langsung mengganti
/// teks lewat [OnboardingPage.onLanguageSelected].
///
/// Mode pertama kali: "Lewati" dan tombol Lanjut di layar geser terakhir
/// melompat ke langkah wajib pertama yang tersisa (mata uang), tidak keluar
/// dari onboarding. Mata uang (ADR-025 §3.7), awal periode keuangan, dan
/// pengingat rutin tidak punya tombol lewati dan tidak terpilih otomatis;
/// "wajib" berarti wajib dijawab, bukan wajib menyala (KT-D1). Tombol Kembali
/// di aplikasi maupun tombol sistem kembali ke langkah sebelumnya. Penutup
/// (ajakan dompet pertama, ringkasan jawaban, baris informasi Catat dari
/// notifikasi di Android) tampil paling akhir. Mode tinjau (dari Akun) hanya
/// menampilkan layar geser dan boleh ditutup kapan saja.
///
/// Halaman ini tidak menyimpan apa pun -- [onFinished] dan callback langkah
/// yang memutuskan (lihat `buildOnboardingRoute`).
class OnboardingPage extends StatefulWidget {
  /// Membuat [OnboardingPage].
  const OnboardingPage({
    required this.onFinished,
    this.mode = OnboardingMode.firstRun,
    this.onLanguageSelected,
    this.onPeriodConfirmed,
    this.onTurnOnReminders,
    this.onRemindersDeclined,
    this.skipPeriod = false,
    this.skipReminder = false,
    super.key,
  });

  /// Dipanggil saat pengguna meninggalkan onboarding. [currency] selalu
  /// terisi di mode pertama kali dan selalu `null` di mode tinjau.
  final Future<void> Function(OnboardingOutcome outcome, AppCurrency? currency) onFinished;

  /// Mode pembukaan.
  final OnboardingMode mode;

  /// Menerapkan dan menyimpan bahasa yang diketuk di langkah bahasa.
  final Future<void> Function(AppLocale locale)? onLanguageSelected;

  /// Menyimpan awal periode keuangan yang dipilih; `false` = gagal, langkah
  /// bertahan. `null` = langkah tidak ditanyakan.
  final Future<bool> Function(FinancialMonthStart start)? onPeriodConfirmed;

  /// Meminta izin notifikasi sistem lalu menyalakan pengingat rutin; `true`
  /// bila akhirnya menyala. `null` = langkah tidak ditanyakan.
  final Future<bool> Function()? onTurnOnReminders;

  /// Dipanggil saat pengguna memilih "Tidak sekarang" di langkah pengingat.
  final Future<void> Function()? onRemindersDeclined;

  /// Langkah awal periode sudah dijawab di sesi sebelumnya.
  final bool skipPeriod;

  /// Langkah pengingat sudah dijawab di sesi sebelumnya.
  final bool skipReminder;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _busy = false;

  late _Step _step = widget.mode == OnboardingMode.firstRun ? _Step.language : _Step.slides;

  /// Langkah yang sudah dilalui, untuk Kembali.
  final List<_Step> _trail = [];

  AppCurrency? _currency;
  late final AppCurrency? _suggested = AppCurrency.forCountry(
    WidgetsBinding.instance.platformDispatcher.locale.countryCode,
  );
  AppLocale _language = LocaleSettings.currentLocale;
  FinancialMonthStart _period = FinancialMonthStart.first;
  bool _periodConfirmed = false;
  OnboardingReminderChoice? _reminder;

  bool get _review => widget.mode == OnboardingMode.review;

  /// Layar geser: lima di mode tinjau; empat di mode pertama kali, karena
  /// layar kelimanya menjadi penutup sesudah langkah wajib.
  int get _count => _review ? onboardingSlideCount : onboardingSlideCount - 1;

  bool get _isLast => _page == _count - 1;

  bool get _asksPeriod => widget.onPeriodConfirmed != null && !widget.skipPeriod;

  bool get _asksReminder => widget.onTurnOnReminders != null && !widget.skipReminder;

  /// Langkah sesudah [from] di mode pertama kali, melewati yang tidak ditanya.
  _Step _after(_Step from) {
    final order = [
      _Step.language,
      _Step.slides,
      _Step.currency,
      if (_asksPeriod) _Step.period,
      if (_asksReminder) _Step.reminder,
      _Step.finale,
    ];
    return order[order.indexOf(from) + 1];
  }

  void _go(_Step step) => setState(() {
    _trail.add(_step);
    _step = step;
  });

  void _advance() => _go(_after(_step));

  void _back() {
    if (_trail.isEmpty || _busy) return;
    setState(() => _step = _trail.removeLast());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(AppLocale locale) async {
    setState(() => _language = locale);
    await widget.onLanguageSelected?.call(locale);
  }

  /// Lanjut dari langkah bahasa. Pilihan disimpan lagi di sini: pengguna yang
  /// langsung menekan lanjut tanpa mengetuk pilihan bawaan juga sudah memilih,
  /// jadi lembar bahasa ucapan (ADR-028 §3.8) tidak bertanya lagi (B-17).
  Future<void> _confirmLanguage() async {
    await widget.onLanguageSelected?.call(_language);
    if (mounted) _advance();
  }

  Future<void> _confirmPeriod() async {
    if (_busy) return;
    setState(() => _busy = true);
    final saved = await widget.onPeriodConfirmed!(_period);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) {
      _periodConfirmed = true;
      _advance();
    }
  }

  Future<void> _turnOnReminders() async {
    if (_busy) return;
    setState(() => _busy = true);
    final on = await widget.onTurnOnReminders!();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _reminder = on ? OnboardingReminderChoice.on : OnboardingReminderChoice.permissionDenied;
    });
  }

  Future<void> _declineReminders() async {
    await widget.onRemindersDeclined?.call();
    if (!mounted) return;
    setState(() => _reminder = OnboardingReminderChoice.off);
    _advance();
  }

  Future<void> _finish(OnboardingOutcome outcome, AppCurrency? currency) async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.onFinished(outcome, currency);
    if (mounted) setState(() => _busy = false);
  }

  /// "Lewati" / Lanjut di layar geser terakhir: mode tinjau selesai, mode
  /// pertama kali melompat ke langkah wajib berikutnya.
  void _leaveSlides() {
    if (_review) {
      unawaited(_finish(OnboardingOutcome.dismissed, null));
    } else {
      _advance();
    }
  }

  void _nextSlide() {
    final duration = MotionPolicy.duration(context, const Duration(milliseconds: 420));
    if (duration == Duration.zero) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(duration: duration, curve: Curves.easeInOut);
    }
  }

  /// Layar geser tampil (dan bisa dibalik) hanya di langkah `slides`.
  bool get _onSlides => _step == _Step.slides;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali sistem di langkah wajib kembali ke langkah sebelumnya,
      // bukan keluar dari onboarding.
      canPop: _trail.isEmpty || _review,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Builder(
        builder: (context) {
          final colors = context.appColors;
          final showBack = !_review && _trail.isNotEmpty && _step != _Step.slides && _step != _Step.language;
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
                                  t.app.title,
                                  style: labelSmStyle(context, color: colors.ink2),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showBack)
                                AppButton.text(
                                  key: const ValueKey('onboarding-back'),
                                  label: t.onboarding.backAction,
                                  onPressed: _busy ? null : _back,
                                )
                              else if (_onSlides && (!_isLast || _review))
                                AppButton.text(
                                  label: _review ? t.onboarding.closeAction : t.onboarding.skipAction,
                                  onPressed: _busy ? null : _leaveSlides,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            // Tetap terpasang di balik langkah lain, supaya
                            // "Kembali" mendarat di layar geser yang sama.
                            Offstage(
                              offstage: !_onSlides,
                              child: PageView.builder(
                                controller: _controller,
                                itemCount: _count,
                                onPageChanged: (page) => setState(() => _page = page),
                                itemBuilder: (context, index) => OnboardingSlide(
                                  index: index,
                                  active: index == _page && _onSlides,
                                  controller: _controller,
                                ),
                              ),
                            ),
                            if (_step == _Step.language)
                              OnboardingLanguageStep(selected: _language, onSelected: _selectLanguage),
                            if (_step == _Step.currency)
                              OnboardingCurrencyStep(
                                selected: _currency,
                                suggested: _suggested,
                                onSelected: (currency) => setState(() => _currency = currency),
                              ),
                            if (_step == _Step.period)
                              OnboardingPeriodStep(
                                selected: _period,
                                onSelected: (start) => setState(() => _period = start),
                              ),
                            if (_step == _Step.reminder) OnboardingReminderStep(choice: _reminder),
                            if (_step == _Step.finale)
                              OnboardingFinale(
                                period: _periodConfirmed ? _period : null,
                                reminder: _reminder,
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.space4,
                          AppSpacing.space2,
                          AppSpacing.space4,
                          AppSpacing.space4,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_onSlides) ...[
                              OnboardingPageIndicator(count: _count, current: _page),
                              const SizedBox(height: AppSpacing.space4),
                            ],
                            AnimatedSwitcher(
                              duration: MotionPolicy.duration(context, const Duration(milliseconds: 240)),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _actions(context),
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

  Widget _actions(BuildContext context) {
    switch (_step) {
      case _Step.language:
        return SizedBox(
          key: const ValueKey('language'),
          width: double.infinity,
          child: AppButton(
            key: const ValueKey('onboarding-language-confirm'),
            label: t.onboarding.languageConfirm,
            onPressed: _confirmLanguage,
          ),
        );
      case _Step.slides:
        if (!_isLast) {
          return SizedBox(
            key: const ValueKey('next'),
            width: double.infinity,
            child: AppButton(label: t.onboarding.nextAction, onPressed: _nextSlide),
          );
        }
        // Layar geser terakhir: mode tinjau menutup, mode pertama kali
        // melanjutkan ke langkah wajib.
        return SizedBox(
          key: const ValueKey('close'),
          width: double.infinity,
          child: AppButton(
            label: _review ? t.onboarding.closeAction : t.onboarding.nextAction,
            onPressed: _busy ? null : _leaveSlides,
          ),
        );
      case _Step.currency:
        final currency = _currency;
        return SizedBox(
          key: const ValueKey('currency'),
          width: double.infinity,
          child: AppButton(
            key: const ValueKey('onboarding-currency-confirm'),
            label: currency == null
                ? t.onboarding.currencyChooseFirst
                : t.onboarding.currencyConfirm(code: currency.code),
            onPressed: currency == null || _busy ? null : _advance,
          ),
        );
      case _Step.period:
        return SizedBox(
          key: const ValueKey('period'),
          width: double.infinity,
          child: AppButton(
            key: const ValueKey('onboarding-period-confirm'),
            label: switch (_period.day) {
              final day? => t.onboarding.periodConfirm(day: day),
              null => t.onboarding.periodConfirmLast,
            },
            loading: _busy,
            onPressed: _busy ? null : _confirmPeriod,
          ),
        );
      case _Step.reminder:
        if (_reminder != null && _reminder != OnboardingReminderChoice.off) {
          // Dijawab lewat Nyalakan (menyala atau izin ditolak): Lanjut.
          return SizedBox(
            key: const ValueKey('reminder-answered'),
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('onboarding-reminder-next'),
              label: t.onboarding.nextAction,
              onPressed: _advance,
            ),
          );
        }
        return Column(
          key: const ValueKey('reminder-ask'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              key: const ValueKey('onboarding-reminder-turn-on'),
              label: t.onboarding.turnOn,
              loading: _busy,
              onPressed: _busy ? null : _turnOnReminders,
            ),
            const SizedBox(height: AppSpacing.space2),
            // Selebar Nyalakan dan bergaya tombol, bukan teks, supaya tidak
            // terbaca sebagai Lewati.
            AppButton.secondary(
              key: const ValueKey('onboarding-reminder-not-now'),
              label: t.onboarding.notNow,
              onPressed: _busy ? null : () => unawaited(_declineReminders()),
            ),
          ],
        );
      case _Step.finale:
        return Column(
          key: const ValueKey('final'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Satu denyut saat layar akhir tiba (ADR-021 §3.7).
            AppFadeIn(
              delay: const Duration(milliseconds: 200),
              child: AppButton(
                label: t.onboarding.createWalletAction,
                onPressed: _busy ? null : () => _finish(OnboardingOutcome.createWallet, _currency),
              ),
            ),
            const SizedBox(height: AppSpacing.space1),
            Center(
              child: AppButton.text(
                label: t.onboarding.laterAction,
                onPressed: _busy ? null : () => _finish(OnboardingOutcome.dismissed, _currency),
              ),
            ),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppButton.text(
                  label: t.onboarding.signInAction,
                  onPressed: _busy ? null : () => _finish(OnboardingOutcome.signIn, _currency),
                ),
              ),
            ),
          ],
        );
    }
  }
}
