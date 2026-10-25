import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';
import 'package:saldough/features/premium/presentation/bloc/paywall_bloc.dart';
import 'package:saldough/features/premium/presentation/bloc/paywall_state.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/pages/paywall_message.dart';
import 'package:saldough/features/premium/presentation/widgets/plan_card.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_subscription.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_tile.dart';
import 'package:state_management/state_management.dart';

/// Paywall Tanukonomy Plus (T-24.17a, design "Paywall Plus"): satu layar untuk
/// semua pemicu, hanya judul dan satu kalimatnya yang berganti ([PaywallMessage]).
/// Tidak pernah mengubah data dan tidak menghalangi pencatatan; "Nanti saja"
/// sama besar dengan tombol beli.
///
/// Sebelum Plus dijual ([PaywallPhase.notSelling]) layar hanya mengajak masuk
/// akun, karena hak pra-peluncuran dan uji coba memerlukan akun (ADR-041
/// §3.4, §3.13); desain belum punya keadaan ini.
///
/// Mencatat `paywall_viewed` saat dibuka dan `paywall_dismissed` saat ditutup.
class PaywallPage extends StatefulWidget {
  /// Membuat [PaywallPage].
  const PaywallPage({
    required this.trigger,
    required this.signedIn,
    required this.onSignIn,
    this.launch = launchPlaySubscriptions,
    super.key,
  });

  /// Membuka alamat di luar aplikasi ("Kelola di Play Store"); untuk uji.
  final Future<bool> Function(Uri uri) launch;

  /// Pemicu paywall, untuk pesan dan analitik.
  final PaywallTrigger trigger;

  /// Pengguna sudah masuk akun.
  final bool signedIn;

  /// Membuka layar Akun untuk masuk.
  final VoidCallback onSignIn;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.log(
      PremiumEvents.paywallViewed(trigger: widget.trigger.analyticsName),
    );
  }

  @override
  void dispose() {
    AppAnalytics.log(
      PremiumEvents.paywallDismissed(trigger: widget.trigger.analyticsName),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlanState>(
      valueListenable: ActivePlan.notifier,
      builder: (context, plan, _) => _paywall(context, plan),
    );
  }

  Widget _paywall(BuildContext context, PlanState plan) {
    final texts = t.premium.paywall;
    return BlocBuilder<PaywallBloc, PaywallState>(
      builder: (context, state) {
        if (state.phase == PaywallPhase.done) {
          return _DonePage(kind: state.selected);
        }
        // Sudah berlangganan: tanpa pilihan paket dan tombol beli.
        if (isSubscribed(plan)) {
          return _SubscribedPage(until: (plan as PlusPlan).until, launch: widget.launch);
        }
        final bloc = context.read<PaywallBloc>();
        return Scaffold(
          appBar: AppBar(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space4,
              0,
              AppSpacing.space4,
              AppSpacing.space4,
            ),
            children: [
              _Header(message: PaywallMessage.of(widget.trigger)),
              if (state.phase == PaywallPhase.pending ||
                  state.phase == PaywallPhase.failed) ...[
                const SizedBox(height: AppSpacing.space4),
                AppBanner(
                  message: state.phase == PaywallPhase.failed
                      ? texts.failed
                      : texts.pending,
                  tone: state.phase == PaywallPhase.failed
                      ? AppTone.danger
                      : AppTone.info,
                  icon: state.phase == PaywallPhase.failed
                      ? IconKey.error
                      : IconKey.info,
                ),
              ],
              if (!widget.signedIn && state.phase != PaywallPhase.notSelling) ...[
                const SizedBox(height: AppSpacing.space4),
                AppBanner(
                  message: texts.signInForTrial,
                  tone: AppTone.info,
                  actionLabel: t.premium.signInAction,
                  onAction: widget.onSignIn,
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              const _Benefits(),
              Align(
                child: AppButton.text(
                  label: t.premium.features.seeAll,
                  icon: IconKey.chevronRight,
                  small: true,
                  onPressed: () => unawaited(
                    context.pushRoute(PremiumRouteKeys.features, const PlusFeaturesInput(fromPaywall: true)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              switch (state.phase) {
                PaywallPhase.notSelling => _NotSelling(
                  signedIn: widget.signedIn,
                ),
                PaywallPhase.offline => _Offline(
                  onRetry: () => bloc.add(const PaywallStarted()),
                ),
                _ => _Plans(
                  state: state,
                  onSelect: (kind) => bloc.add(PaywallPlanSelected(kind)),
                ),
              },
            ],
          ),
          bottomNavigationBar: AppStickyBar(
            child: _Actions(
              state: state,
              signedIn: widget.signedIn,
              onSignIn: widget.onSignIn,
              onBuy: () => bloc.add(const PaywallBuyRequested()),
              onLater: () => Navigator.of(context).maybePop(),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.message});

  final PaywallMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return Column(
      children: [
        const PlusTile(IconKey.plus),
        const SizedBox(height: AppSpacing.space1),
        if (message.hasKicker)
          AppBadge(t.premium.paywall.kicker, tone: AppTone.brand),
        const SizedBox(height: AppSpacing.space1),
        Text(
          message.title,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          message.body,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
        ),
      ],
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall.benefits;
    Widget row(IconKey icon, String title) => AppListRow(
      compact: true,
      wrapTitle: true,
      leading: PlusTile(icon, size: 32),
      title: title,
    );
    return AppListCard(
      dividerIndent: 60,
      children: [
        row(IconKey.photoCamera, texts.photo),
        row(IconKey.notificationsActive, texts.warn),
        row(IconKey.chatBubble, texts.ask),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  const _Plans({required this.state, required this.onSelect});

  final PaywallState state;
  final ValueChanged<PlusPlanKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall;
    if (state.phase == PaywallPhase.loading) {
      return Column(
        children: [
          PlanCard(
            name: texts.yearly,
            subtitle: texts.cancelAnytime,
            selected: true,
            onTap: null,
          ),
          const SizedBox(height: AppSpacing.space2),
          PlanCard(
            name: texts.monthly,
            subtitle: texts.cancelAnytime,
            selected: false,
            onTap: null,
          ),
        ],
      );
    }
    return Column(
      children: [
        for (final option in state.plans) ...[
          _card(option, state),
          if (option != state.plans.last)
            const SizedBox(height: AppSpacing.space2),
        ],
      ],
    );
  }

  Widget _card(PlanOption option, PaywallState state) {
    final texts = t.premium.paywall;
    final monthly = option.kind == PlusPlanKind.monthly;
    final (tag, subtitle) = switch (option.kind) {
      PlusPlanKind.yearlyFounder => (
        texts.founderName,
        state.deadline == null
            ? texts.cancelAnytime
            : texts.founderSub(
                date: CycleMonthFormatter.formatDateShort(state.deadline!),
              ),
      ),
      PlusPlanKind.yearlyIntro => (
        texts.introName,
        texts.introSub(
          price: option.regularPriceText ?? option.priceText,
          until: state.deadline == null ? '' : _until(state.deadline!),
        ),
      ),
      PlusPlanKind.yearly => (
        null,
        option.perMonthText == null
            ? texts.cancelAnytime
            : texts.yearlyEquiv(price: option.perMonthText!),
      ),
      PlusPlanKind.monthly => (null, texts.cancelAnytime),
    };
    return PlanCard(
      name: monthly ? texts.monthly : texts.yearly,
      subtitle: subtitle,
      tag: tag,
      priceText: option.priceText,
      regularPriceText: option.regularPriceText,
      unit: monthly ? texts.perMonth : texts.perYear,
      selected: state.selected == option.kind,
      onTap: state.locked ? null : () => onSelect(option.kind),
    );
  }

  /// "26 Nov, 21.00" (id) atau "26 Nov, 9:00 pm" (en).
  static String _until(DateTime d) {
    final minute = d.minute.toString().padLeft(2, '0');
    final clock = LocaleSettings.currentLocale == AppLocale.en
        ? '${d.hour % 12 == 0 ? 12 : d.hour % 12}:$minute ${d.hour < 12 ? 'am' : 'pm'}'
        : '${d.hour.toString().padLeft(2, '0')}.$minute';
    return '${CycleMonthFormatter.formatDayMonth(d)}, $clock';
  }
}

class _Offline extends StatelessWidget {
  const _Offline({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return AppCard(
      child: Column(
        children: [
          AppIcon(IconKey.wifiOff, color: colors.ink2),
          const SizedBox(height: AppSpacing.space2),
          Text(
            texts.offlineTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            texts.offlineBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: AppSpacing.space2),
          AppButton.secondary(
            label: texts.retry,
            small: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _NotSelling extends StatelessWidget {
  const _NotSelling({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            signedIn ? texts.paywall.notSellingTitle : texts.signInTitle,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            signedIn ? texts.paywall.notSellingBody : texts.signInBody,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.signedIn,
    required this.onSignIn,
    required this.onBuy,
    required this.onLater,
  });

  final PaywallState state;
  final bool signedIn;
  final VoidCallback onSignIn;
  final VoidCallback onBuy;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall;
    final selling = state.phase != PaywallPhase.notSelling;
    final option = state.selectedOption;
    final label = switch (state.phase) {
      PaywallPhase.buying => texts.processing,
      PaywallPhase.pending => texts.waiting,
      PaywallPhase.failed => texts.retry,
      PaywallPhase.ready =>
        option?.kind == PlusPlanKind.monthly
            ? texts.buyMonthly
            : texts.buyYearly,
      _ => texts.subscribe,
    };
    final canBuy =
        state.phase == PaywallPhase.ready || state.phase == PaywallPhase.failed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selling)
          AppButton(
            label: label,
            expand: true,
            loading: state.phase == PaywallPhase.buying,
            onPressed: canBuy ? onBuy : null,
          )
        else if (!signedIn)
          AppButton(
            label: t.premium.signInAction,
            expand: true,
            onPressed: onSignIn,
          ),
        if (selling || !signedIn) const SizedBox(height: AppSpacing.space2),
        AppButton.secondary(
          label: texts.later,
          expand: true,
          onPressed: onLater,
        ),
        if (option != null &&
            selling &&
            state.phase != PaywallPhase.loading) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            _fine(option),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.appColors.ink2),
          ),
        ],
      ],
    );
  }

  static String _fine(PlanOption option) {
    final texts = t.premium.paywall;
    return switch (option.kind) {
      PlusPlanKind.monthly => texts.fineMonthly(price: option.priceText),
      PlusPlanKind.yearlyIntro => texts.fineIntro(
        price: option.priceText,
        regular: option.regularPriceText ?? option.priceText,
      ),
      _ => texts.fineYearly(price: option.priceText),
    };
  }
}

/// Layar sesudah Plus aktif ("Plus aktif"): satu tombol Selesai. Tanggal
/// perpanjangan dibaca dari hak yang berlaku bila sudah tersalin.
class _DonePage extends StatelessWidget {
  const _DonePage({required this.kind});

  /// Paket yang dibeli.
  final PlusPlanKind? kind;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall;
    final textTheme = Theme.of(context).textTheme;
    final until = ActivePlan.state.isPlus ? _untilOf() : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PlusTile(IconKey.plus, size: 64),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  texts.doneTitle,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  until == null
                      ? texts.doneBody
                      : texts.doneBodyPlan(
                          plan: kind == PlusPlanKind.monthly
                              ? texts.monthly
                              : texts.yearly,
                          date: CycleMonthFormatter.formatDateShort(until),
                        ),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.appColors.ink2,
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
                AppButton(
                  label: texts.done,
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static DateTime? _untilOf() {
    final plan = ActivePlan.state;
    return plan is PlusPlan ? plan.until : null;
  }
}

/// Paywall untuk yang sudah berlangganan: menyatakan Plus aktif dan menawarkan
/// "Kelola di Play Store" (batalkan atau ganti paket di sana), bukan membeli lagi.
class _SubscribedPage extends StatelessWidget {
  const _SubscribedPage({required this.until, required this.launch});

  final DateTime? until;
  final Future<bool> Function(Uri uri) launch;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PlusTile(IconKey.plus, size: 64),
                const SizedBox(height: AppSpacing.space4),
                Text(texts.subscribedTitle, textAlign: TextAlign.center, style: textTheme.titleLarge),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  until == null
                      ? texts.subscribedOpen
                      : texts.subscribedBody(date: CycleMonthFormatter.formatDateShort(until!)),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: context.appColors.ink2),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppStickyBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: t.premium.account.manage,
              expand: true,
              onPressed: () => unawaited(launch(playSubscriptionsUri)),
            ),
            const SizedBox(height: AppSpacing.space2),
            AppButton.secondary(label: texts.close, expand: true, onPressed: () => Navigator.of(context).maybePop()),
          ],
        ),
      ),
    );
  }
}
