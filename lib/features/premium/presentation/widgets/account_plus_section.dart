import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/premium/domain/plus_purchasing.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/premium/presentation/widgets/plus_subscription.dart';

/// Bagian Plus di layar Akun (design `AkunPlus`): satu baris status paket
/// ("Gratis", uji coba, aktif, tenggang, ditahan, penguji), "Kelola di Play
/// Store" bila ada langganan, dan "Pulihkan pembelian" yang selalu ada.
///
/// Dibaca dari [ActivePlan], jadi berubah sendiri saat paket berubah. Paket
/// (Tahunan/Bulanan) dan status "tidak diperpanjang" belum disimpan di cache
/// hak, jadi keterangan aktif hanya menyebut tanggal akhir periode.
class AccountPlusSection extends StatelessWidget {
  /// Membuat [AccountPlusSection]; [launch] untuk uji.
  const AccountPlusSection({required this.purchasing, this.launch = launchPlaySubscriptions, super.key});

  /// Pembelian, untuk memulihkan.
  final PlusPurchasing purchasing;

  /// Membuka alamat di luar aplikasi.
  final Future<bool> Function(Uri uri) launch;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSectionHeader(title: texts.section),
        const SizedBox(height: 8),
        ValueListenableBuilder<PlanState>(
          valueListenable: ActivePlan.notifier,
          builder: (context, plan, _) {
            final (sub, badge, warn, manage, features) = _describe(plan);
            void open() => unawaited(
              features
                  ? context.pushRoute(PremiumRouteKeys.features, const PlusFeaturesInput())
                  : context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.account)),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlusCard(
                  key: const ValueKey('account-plus-row'),
                  title: texts.rowTitle,
                  subtitle: sub,
                  badge: badge,
                  warn: warn,
                  cta: features ? null : t.premium.seePlus,
                  onTap: open,
                ),
                const SizedBox(height: 8),
                DsListCard(
                  children: [
                    if (manage)
                      DsSettingRow(
                        key: const ValueKey('account-plus-manage'),
                        leading: const SettingIconTile(IconKey.openInNew),
                        title: texts.manage,
                        onTap: () => unawaited(launch(playSubscriptionsUri)),
                      ),
                    DsSettingRow(
                      key: const ValueKey('account-plus-restore'),
                      leading: const SettingIconTile(IconKey.restorePurchases),
                      title: texts.restore,
                      onTap: () => unawaited(_restore(context)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await purchasing.restore();
    messenger.showAppSnackBar(SnackBar(content: Text(t.premium.account.restoreDone)));
  }

  /// `(keterangan, lencana, lencana peringatan, tampilkan "Kelola", buka daftar fitur)`.
  (String, String?, bool, bool, bool) _describe(PlanState plan) {
    final texts = t.premium.account;
    String date(DateTime d) => CycleMonthFormatter.formatDateShort(d);
    return switch (plan) {
      FreePlan() => (texts.subFree, null, false, false, false),
      // Langganan ditahan tertutup uji coba (KT-P19): ajak memperbaiki pembayaran.
      TrialPlan(:final endsOn, :final onHoldSince) when onHoldSince != null => (
        texts.subTrialOnHold(date: date(endsOn)),
        texts.badgeCheck,
        true,
        true,
        false,
      ),
      TrialPlan(:final endsOn) => (texts.subTrial(date: date(endsOn)), texts.badgeTrial, false, false, false),
      OnHoldPlan() => (texts.subOnHold, texts.badgeCheck, true, true, false),
      PlusPlan(:final inGrace, :final until) when inGrace => (
        until == null ? texts.subOnHold : texts.subGrace(date: date(until)),
        texts.badgeCheck,
        true,
        true,
        false,
      ),
      PlusPlan(:final source, :final until) when source != PlanSource.purchase => (
        until == null ? texts.subTesterOpen : texts.subTester(date: date(until)),
        t.premium.plusBadge,
        false,
        false,
        true,
      ),
      PlusPlan(:final until) => (
        until == null ? texts.subActiveOpen : texts.subActive(date: date(until)),
        t.premium.plusBadge,
        false,
        true,
        true,
      ),
    };
  }
}

/// Kartu Plus (acuan Profil): latar gradasi hero, ubin koin clay, judul dan
/// keterangan status, lencana status, dan -- untuk paket Gratis -- tombol
/// "Lihat Plus". Seluruh kartu bisa diketuk. Tanpa harga: harga hanya tampil
/// di paywall dan selalu dari toko.
class _PlusCard extends StatelessWidget {
  const _PlusCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.warn,
    required this.cta,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final bool warn;
  final String? cta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final base = c.heroSurface;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.lerp(base, Colors.white, 0.08)!, Color.lerp(base, Colors.black, 0.35)!],
    );
    return DsPressable(
      onPressed: onTap,
      pressedScale: 0.99,
      dimWhenDisabled: false,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: DsRadius.xlAll,
          border: Border.all(color: c.heroBorder),
          boxShadow: [BoxShadow(color: c.heroGlow.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DsIconTile.asset(asset: ClayIcons.tierCoin, tone: DsIconTileTone.heroIncome, size: DsIconTileSize.lg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ds.typography.titleMd.copyWith(fontSize: 17, color: c.onHero)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: ds.typography.bodySm.copyWith(color: c.onHeroMuted)),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: warn ? c.warningContainer : c.onHero.withValues(alpha: 0.16),
                        borderRadius: DsRadius.fullAll,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        child: Text(
                          badge!,
                          style: ds.typography.labelMd.copyWith(color: warn ? c.onWarningContainer : c.onHero),
                        ),
                      ),
                    ),
                  ],
                  if (cta == null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 20, color: c.onHeroMuted),
                  ],
                ],
              ),
              if (cta != null) ...[
                const SizedBox(height: 14),
                DsButton.onHero(label: cta!, icon: Icons.arrow_forward, onPressed: onTap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
