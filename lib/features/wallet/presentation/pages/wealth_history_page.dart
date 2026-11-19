import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_state.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_empty_states.dart';
import 'package:saldough/features/wallet/presentation/widgets/wealth_history_chart.dart';
import 'package:saldough/shared/wealth/wealth.dart';
import 'package:state_management/state_management.dart';

/// Riwayat kekayaan (B-100, ADR-050 §3.6): Total aset di akhir tiap periode
/// keuangan, dengan pecahan perubahan periode terpilih. Gratis melihat
/// `freeAnalysisPeriods` periode terakhir; Plus seluruhnya.
class WealthHistoryPage extends StatelessWidget {
  /// Membuat [WealthHistoryPage].
  const WealthHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.assets.wealth.title)),
      body: SafeArea(
        child: BlocBuilder<WealthHistoryBloc, WealthHistoryState>(
          builder: (context, state) {
            if (state.isLoading) return const AppSkeletonPage();
            if (state.failed) {
              return WalletLoadErrorState(onRetry: () => context.read<WealthHistoryBloc>().add(const WealthHistoryStarted()));
            }
            if (!state.hasChart) return _Empty(locked: state.hasLockedOlder);
            return _Body(state: state);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final WealthHistoryState state;

  @override
  Widget build(BuildContext context) {
    final current = state.current!;
    final isLatest = state.selected == state.points.length - 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.sm, DsSpacing.md, DsSpacing.xl),
      children: [
        DsReveal(
          child: DsCard(
            key: const ValueKey('wealth-chart-card'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLatest ? t.assets.wealth.periodTotalNow : t.assets.wealth.periodTotal(period: current.period.name),
                  style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
                ),
                const SizedBox(height: 4),
                AppMoneyText(current.point.total, size: MoneySize.large),
                const SizedBox(height: 4),
                _DeltaLine(change: current.change),
                const SizedBox(height: 16),
                WealthHistoryChart(
                  points: state.points,
                  selected: state.selected,
                  onSelected: (i) => context.read<WealthHistoryBloc>().add(WealthHistoryPointSelected(i)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _AxisLabel(state.points.first.period.shortName),
                    _AxisLabel(state.points.last.period.shortName),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: DsMotion.standard,
          child: _ChangeCard(key: ValueKey('change-${state.selected}'), selected: current),
        ),
        if (current.point.hasStale) ...[
          const SizedBox(height: 12),
          DsInlineBanner(
            key: const ValueKey('wealth-stale'),
            icon: Symbols.schedule_rounded,
            maxLines: 3,
            message: t.assets.wealth.stale,
          ),
        ],
        if (state.hasLockedOlder) ...[const SizedBox(height: 12), const _LockedCard()],
      ],
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.ds.typography.labelSm.copyWith(color: context.ds.colors.textSecondary));
}

class _DeltaLine extends StatelessWidget {
  const _DeltaLine({required this.change});

  final WealthChange? change;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final change = this.change;
    if (change == null) {
      return Text(t.assets.wealth.firstPeriod, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary));
    }
    final total = change.total;
    final (icon, color, text) = switch (total) {
      > 0 => (Symbols.trending_up_rounded, ds.colors.income, t.assets.wealth.changeUp(amount: AppMoneyFormatter.format(total))),
      < 0 => (Symbols.trending_down_rounded, ds.colors.error, t.assets.wealth.changeDown(amount: AppMoneyFormatter.format(-total))),
      _ => (Symbols.trending_flat_rounded, ds.colors.textSecondary, t.assets.wealth.changeFlat),
    };
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: ds.typography.bodySm.copyWith(color: color, fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({required this.selected, super.key});

  final WealthPeriodPoint selected;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final change = selected.change;
    final w = t.assets.wealth;
    return DsCard(
      key: const ValueKey('wealth-change-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(w.changeHeading(period: selected.period.name), style: ds.typography.titleMd),
          const SizedBox(height: 12),
          if (change == null)
            Text(w.noChange, style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary))
          else ...[
            _ChangeRow(icon: Symbols.swap_vert_rounded, label: w.flow, hint: w.flowHint, amount: change.flow),
            _ChangeRow(
              icon: Symbols.show_chart_rounded,
              label: w.investmentValue,
              hint: w.investmentValueHint,
              amount: change.investmentValue,
            ),
            _ChangeRow(icon: Symbols.tune_rounded, label: w.adjustment, hint: w.adjustmentHint, amount: change.adjustment),
            _ChangeRow(icon: Symbols.flag_rounded, label: w.opening, hint: w.openingHint, amount: change.opening),
            Divider(height: 24, color: ds.colors.outlineSubtle),
            Row(
              children: [
                Expanded(child: Text(w.changeTotal, style: ds.typography.titleMd)),
                _Signed(change.total, size: MoneySize.regular),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.icon, required this.label, required this.hint, required this.amount});

  final IconData icon;
  final String label;
  final String hint;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final muted = amount == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DsIconTile(icon: icon, size: DsIconTileSize.sm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(hint, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Opacity(opacity: muted ? 0.5 : 1, child: _Signed(amount)),
        ],
      ),
    );
  }
}

/// Nominal bertanda: pemasukan `positive`, pengeluaran `ink`, nol tanpa tanda.
class _Signed extends StatelessWidget {
  const _Signed(this.sen, {this.size = MoneySize.small});

  final int sen;
  final MoneySize size;

  @override
  Widget build(BuildContext context) => AppMoneyText(
    sen.abs(),
    kind: sen > 0 ? MoneyKind.income : (sen < 0 ? MoneyKind.expense : MoneyKind.balance),
    size: size,
  );
}

class _LockedCard extends StatelessWidget {
  const _LockedCard();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final w = t.assets.wealth;
    final free = ActivePlan.limits.value.freeAnalysisPeriods;
    return DsCard(
      key: const ValueKey('wealth-locked'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.lock_rounded, size: 20, color: ds.colors.actionPrimary),
              const SizedBox(width: 8),
              Expanded(child: Text(w.lockedTitle, style: ds.typography.titleMd)),
            ],
          ),
          const SizedBox(height: 6),
          Text(w.lockedBody(n: free), style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary)),
          const SizedBox(height: 12),
          DsButton(
            label: t.premium.seePlus,
            onPressed: () => unawaited(
              context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.analysisHistory)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.show_chart_rounded, size: 40, color: ds.colors.textSecondary),
            const SizedBox(height: 12),
            Text(t.assets.wealth.emptyTitle, style: ds.typography.titleMd, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              t.assets.wealth.emptyBody,
              style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
