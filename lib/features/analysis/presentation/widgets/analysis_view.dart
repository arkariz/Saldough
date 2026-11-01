import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/domain/analysis_access.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/presentation/analysis_colors.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_trend.dart';
import 'package:saldough/features/analysis/presentation/widgets/compare_line.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

/// Isi layar Analisis satu periode (Riwayat › Analisis, A2): pemilih periode,
/// donat porsi kategori dengan legenda, dan kaki kartu transfer. Dipakai
/// segmen di Riwayat dan halaman rute penuh.
class AnalysisView extends StatelessWidget {
  /// Membuat [AnalysisView].
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    // Paket berubah: periode lama terkunci atau terbuka (ADR-041 §3.8).
    return ValueListenableBuilder<PlanState>(
      valueListenable: ActivePlan.notifier,
      builder: (context, _, _) => _view(context),
    );
  }

  Widget _view(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, state) {
        final bloc = context.read<AnalysisBloc>();
        // Tur (ADR-021): hanya saat termuat dan ada transaksi di periode.
        return TourTrigger(
          tour: TourId.analysis,
          ready: !state.isLoading && !state.loadFailed && state.summary != null && !state.summary!.isEmpty,
          child: RefreshIndicator(
            onRefresh: () async {
              bloc.add(const AnalysisRefreshed());
              await bloc.stream.firstWhere((s) => !s.isLoading);
            },
            child: ListView(
              key: const ValueKey('analysis-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space4,
                AppSpacing.space2,
                AppSpacing.space4,
                AppSpacing.space8,
              ),
              children: _children(context, state, bloc),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _children(
    BuildContext context,
    AnalysisState state,
    AnalysisBloc bloc,
  ) {
    if (state.isLoading) return const [_Loading()];
    if (state.loadFailed) return [const _LoadError()];
    if (!state.hasAnyTransactions) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space8),
          child: DsCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
                const SizedBox(height: 12),
                Text(t.analysis.empty.title, textAlign: TextAlign.center, style: context.ds.typography.titleMd),
                const SizedBox(height: 4),
                Text(
                  t.analysis.empty.body,
                  textAlign: TextAlign.center,
                  style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textMuted),
                ),
                const SizedBox(height: 16),
                DsButton(
                  label: t.analysis.empty.cta,
                  icon: Icons.add,
                  onPressed: () => context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput()),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    final period = state.period;
    final summary = state.summary;
    final stepper = DsPeriodStepper(
      title: period.label,
      tag: period.isTransition ? t.plan.transitionLabel(days: period.days) : null,
      previousLabel: t.analysis.previousPeriod,
      nextLabel: t.analysis.nextPeriod,
      onPrevious: state.canGoBack ? () => bloc.add(const AnalysisPeriodStepped(forward: false)) : null,
      onNext: state.isCurrent ? null : () => bloc.add(const AnalysisPeriodStepped(forward: true)),
    );
    // Gratis: periode lebih tua dari batas terkunci; pemilih periode tetap
    // berfungsi supaya pengguna bisa kembali (ADR-041 §3.8).
    final freePeriods = ActivePlan.limits.value.freeAnalysisPeriods;
    if (!ActivePlan.isPlus &&
        isAnalysisPeriodLocked(
          period: period,
          now: bloc.today,
          schedule: ActiveFinancialMonth.schedule,
          freePeriods: freePeriods,
        )) {
      return [stepper, const SizedBox(height: AppSpacing.space4), _LockedPeriod(
          freePeriods: freePeriods,
          onBack: () => bloc.add(AnalysisPeriodJumped(bloc.today)),
        )];
    }
    return [
      stepper,
      const SizedBox(height: AppSpacing.space3),
      _Controls(state: state),
      const SizedBox(height: AppSpacing.space4),
      if (summary == null || summary.isEmpty)
        DsCard(
          key: const ValueKey('analysis-none'),
          child: Text(
            state.kind == CategoryKind.income
                ? t.analysis.emptyMonthIncome(period: period.name)
                : t.analysis.emptyMonth(period: period.name),
            style: context.ds.typography.bodyMd.copyWith(color: context.ds.colors.textSecondary),
          ),
        )
      else
        _AnalysisCard(state: state, summary: summary),
      // Transfer tetap informasi walau jenis ini kosong (B-4, F7): mis. dompet
      // Tabungan yang hanya menerima transfer.
      if (summary != null && summary.isEmpty && summary.transfers.hasAny)
        DsCard(
          key: const ValueKey('analysis-transfers-only'),
          padding: EdgeInsets.zero,
          child: _TransferFoot(info: summary.transfers),
        ),
      AnalysisTrendSection(state: state),
    ];
  }
}

/// Periode di luar batas Analisis Gratis: data diburamkan dengan kartu Plus di
/// atasnya (komponen PlusLocked). Isi di belakangnya hanya kerangka, karena
/// periode terkunci tidak dimuat. Pesan sama dengan paywall `analysisHistory`.
class _LockedPeriod extends StatelessWidget {
  const _LockedPeriod({required this.freePeriods, required this.onBack});

  final int freePeriods;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium.paywall.messages.analysis;
    final colors = context.appColors;
    return PlusLocked(
      key: const ValueKey('analysis-locked'),
      minHeight: 400,
      title: texts.title(n: freePeriods),
      text: texts.body,
      freeLabel: t.premium.backToLatest,
      onFree: onBack,
      onSee: () => unawaited(
        context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.analysisHistory)),
      ),
      preview: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.space3,
          children: [
            for (final width in const [0.9, 0.62, 0.78, 0.45, 0.7, 0.55])
              FractionallySizedBox(
                widthFactor: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: colors.brandSoft, borderRadius: BorderRadius.circular(4)),
                  child: const SizedBox(height: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan jenis (Pengeluaran | Pemasukan) dan penyaring dompet (F2, F3).
/// Penyaring dompet hanya tampil bila ada lebih dari satu dompet.
class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final AnalysisState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AnalysisBloc>();
    final wallets = state.wallets;
    final selected = wallets.where((w) => w.id == state.walletId).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.space2,
      children: [
        Semantics(
          container: true,
          label: t.analysis.kindLabel,
          child: DsSegmentedPill<CategoryKind>(
            key: const ValueKey('analysis-kind'),
            segments: [
              DsSegment(value: CategoryKind.expense, label: t.analysis.kind.expense),
              DsSegment(value: CategoryKind.income, label: t.analysis.kind.income),
            ],
            selected: state.kind,
            onChanged: (kind) => bloc.add(AnalysisKindChanged(kind)),
          ),
        ),
        if (wallets.length > 1)
          DsFieldGroup(
            children: [
              DsSelectRow<String>(
                key: const ValueKey('analysis-wallet'),
                icon: Icons.account_balance_wallet_outlined,
                leading: selected == null
                    ? null
                    : DsIconTile.asset(
                        asset: ClayIcons.forIcon(walletIconKey(selected.iconKey)) ?? ClayIcons.walletNav,
                        size: DsIconTileSize.sm,
                      ),
                label: t.transaction.walletFilterLabel,
                title: selected?.name ?? t.analysis.allWallets,
                allLabel: t.analysis.allWallets,
                options: [
                  for (final wallet in wallets)
                    DsMenuOption(
                      value: wallet.id,
                      label: wallet.name,
                      leading: SvgPicture.asset(
                        ClayIcons.forIcon(walletIconKey(wallet.iconKey)) ?? ClayIcons.walletNav,
                      ),
                    ),
                ],
                onSelected: (id) => bloc.add(AnalysisWalletChanged(id)),
              ),
            ],
          ),
      ],
    );
  }
}

/// Membuka Rincian kategori [group] untuk periode, jenis, dan dompet yang
/// dilihat; [from] `link` (Lihat rincian) atau `highlight` (baris sorotan).
void _openDetail(
  BuildContext context,
  AnalysisState state,
  AnalysisGroup group, {
  required String from,
}) {
  AppAnalytics.log(AnalysisEvents.categoryOpened(category: _analyticsCategory(group), from: from));
  unawaited(
    context.pushRoute(
      AnalysisRouteKeys.category,
      CategoryDetailInput(
        categoryId: group.category?.id,
        kind: state.kind,
        periodStart: state.period.start,
        walletId: state.walletId,
      ),
    ),
  );
}

/// Nilai parameter `category` peristiwa analitik: kunci bawaan, `custom`
/// (tanpa nama buatan pengguna), `none`, `freelance`, atau `others`.
String _analyticsCategory(AnalysisGroup group) => switch (group.kind) {
  AnalysisGroupKind.category => group.category!.builtInKey ?? 'custom',
  AnalysisGroupKind.freelance => 'freelance',
  AnalysisGroupKind.uncategorized => 'none',
  AnalysisGroupKind.others => 'others',
};

String _shareText(AnalysisShare share) => share.belowOne ? '<1%' : '${share.percent}%';

String _groupName(AnalysisGroup group) => switch (group.kind) {
  AnalysisGroupKind.category => group.category!.name,
  AnalysisGroupKind.freelance => t.analysis.freelanceGroup,
  AnalysisGroupKind.uncategorized => t.analysis.uncategorized,
  AnalysisGroupKind.others => t.analysis.others(n: group.children.length),
};

String _kindName(CategoryKind kind) => kind == CategoryKind.expense ? t.analysis.kind.expense : t.analysis.kind.income;

/// Kartu donat: lingkar, legenda, dan kaki transfer di satu `AppCard`.
/// Mengetuk irisan atau baris memilih kategori (F1): irisan lain meredup dan
/// tengah donat berganti ke kategori itu; mengetuk lagi membatalkan.
class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.state, required this.summary});

  final AnalysisState state;
  final PeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bloc = context.read<AnalysisBloc>();
    final groups = summary.groups;
    final kind = _kindName(summary.kind);
    final amountColor = summary.kind == CategoryKind.income ? colors.positive : null;
    final selected = state.selected;
    final selectedSlice = state.selectedKey == null ? null : summary.sliceOf(state.selectedKey!);
    void select(String key) => bloc.add(AnalysisGroupSelected(key));
    var divider = false;
    var firstRow = true;
    Widget row(
      AnalysisGroup group, {
      bool child = false,
      Color? swatch,
      bool? expanded,
    }) {
      final name = _groupName(group);
      final percent = _shareText(group.share);
      final widget = AppLegendRow(
        key: ValueKey('analysis-row-${child ? 'child-' : ''}$name'),
        name: name,
        percent: percent,
        sen: group.amount,
        semanticsLabel: t.analysis.rowSemantics(
          name: name,
          percent: percent,
          amount: AppMoneyFormatter.format(group.amount),
        ),
        swatch: swatch,
        child: child,
        expanded: expanded,
        selected: group.key == state.selectedKey,
        showDivider: divider,
        amountColor: amountColor,
        onTap: () => select(group.key),
      );
      divider = true;
      // Tur: baris kategori pertama dan baris Tanpa kategori (hanya saat tampil).
      final tourKey = group.kind == AnalysisGroupKind.uncategorized
          ? SpotlightKey.analysisUncategorized
          : (!child && firstRow ? SpotlightKey.analysisCategories : null);
      firstRow = false;
      return SpotlightTarget(spotlightKey: tourKey, child: widget);
    }

    return DsCard(
      key: const ValueKey('analysis-card'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space4),
          Center(
            child: AppDonutChart(
              rounded: true,
              trackColor: context.ds.colors.surfaceContainerHigh,
              slices: [
                for (final g in groups)
                  DonutSlice(
                    value: g.amount,
                    color: analysisColorOf(colors, g),
                  ),
              ],
              selected: selectedSlice,
              onSelect: (index) => select(groups[index].key),
              semanticsLabel: t.analysis.donutSemantics(
                kind: kind,
                period: state.period.name,
                parts: groups.map((g) => '${_groupName(g)} ${_shareText(g.share)}').join(', '),
              ),
              center: _DonutCenter(
                kindName: kind,
                total: summary.total,
                color: amountColor,
                selected: selected,
                lowerKind: kind.toLowerCase(),
              ),
            ),
          ),
          // Pembanding: total jenis saat tak ada pilihan, kategori saat dipilih (B-6).
          if (state.comparison case final comparison?)
            CompareLine(
              label: compareLabel(comparison),
              result: selected == null ? comparison.ofTotal(summary.total) : comparison.ofGroup(selected),
              isGroup: selected != null,
              isUncategorized: selected?.kind == AnalysisGroupKind.uncategorized,
            ),
          // "Lihat rincian {kategori}" untuk kategori dan Freelance (F4);
          // "Beri kategori" saat Tanpa kategori dipilih (F5).
          if (selected != null &&
              (selected.kind == AnalysisGroupKind.category || selected.kind == AnalysisGroupKind.freelance)) ...[
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: DsButton.secondary(
                key: const ValueKey('analysis-detail'),
                label: t.analysis.category.seeCategory(
                  category: _groupName(selected),
                ),
                onPressed: () => _openDetail(context, state, selected, from: 'link'),
              ),
            ),
          ],
          if (selected?.kind == AnalysisGroupKind.uncategorized) ...[
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: DsButton.secondary(
                key: const ValueKey('analysis-fix'),
                label: t.analysis.fix,
                onPressed: () {
                  AppAnalytics.log(AnalysisEvents.uncategorizedFixOpened);
                  unawaited(
                    context.pushRoute(
                      TransactionRouteKeys.filtered,
                      TransactionFilterInput(
                        title: t.analysis.uncategorized,
                        subtitle: state.period.label,
                        filter: PeriodTransactionFilter(
                          from: state.period.start,
                          until: state.period.end,
                          type: summary.kind == CategoryKind.expense
                              ? TransactionTypeFilter.expense
                              : TransactionTypeFilter.income,
                          uncategorized: true,
                          walletId: state.walletId,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (state.comparison case final comparison?)
            _Highlights(
              comparison: comparison,
              highlights: state.highlights,
              onOpen: (group) => _openDetail(context, state, group, from: 'highlight'),
            ),
          const SizedBox(height: AppSpacing.space2),
          for (final group in groups) ...[
            row(
              group,
              swatch: analysisColorOf(colors, group),
              expanded: group.kind == AnalysisGroupKind.others ? state.othersOpen : null,
            ),
            if (group.kind == AnalysisGroupKind.others && state.othersOpen)
              for (final member in group.children) row(member, child: true),
          ],
          if (summary.transfers.hasAny) _TransferFoot(info: summary.transfers),
        ],
      ),
    );
  }
}

/// Sorotan perubahan (B-7), 0–3 baris di atas daftar, kalimat netral tanpa
/// nilai. Membuka Rincian kategori menyusul di irisan 6.
class _Highlights extends StatelessWidget {
  const _Highlights({
    required this.comparison,
    required this.highlights,
    required this.onOpen,
  });

  final PeriodComparison comparison;
  final List<Highlight> highlights;

  /// Membuka Rincian kategori sorotan itu.
  final ValueChanged<AnalysisGroup> onOpen;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();
    final ds = context.ds;
    final c = ds.colors;
    final label = compareLabel(comparison);
    return Container(
      key: const ValueKey('analysis-highlights'),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.outlineSubtle)),
      ),
      child: Column(
        children: [
          for (final highlight in highlights)
            InkWell(
              key: ValueKey('analysis-highlight-${highlight.group.key}'),
              onTap: () => onOpen(highlight.group),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _highlightIcon(highlight.group),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _highlightText(highlight, label),
                          style: ds.typography.bodyMd.copyWith(color: c.textPrimary),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: c.textMuted),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Ikon clay kategori sorotan; ikon piksel lama di tile datar bila belum digambar.
  Widget _highlightIcon(AnalysisGroup group) {
    final key = group.category == null ? IconKey.freelance : categoryIcon(group.category!);
    final clay = ClayIcons.forIcon(key);
    return clay != null ? DsIconTile.asset(asset: clay) : AppIconTile(key);
  }

  /// "Makan Rp295.000 lebih tinggi dari rata-rata 3 bulan". Saat nominal
  /// disembunyikan, nominalnya dilepas dari kalimat.
  String _highlightText(Highlight highlight, String label) {
    final name = _groupName(highlight.group);
    final subject = AmountVisibility.hidden
        ? name
        : '$name ${AppMoneyFormatter.format(highlight.comparison.difference)}';
    return highlight.comparison.isHigher
        ? t.analysis.highlight.higher(subject: subject, compare: label)
        : t.analysis.highlight.lower(subject: subject, compare: label);
  }
}

/// Isi lubang donat: jenis dan total; bila ada pilihan, namanya, nominalnya,
/// dan "{persen} dari pengeluaran" (`tk-donut__center`).
class _DonutCenter extends StatelessWidget {
  const _DonutCenter({
    required this.kindName,
    required this.total,
    required this.color,
    required this.selected,
    required this.lowerKind,
  });

  final String kindName;
  final int total;
  final Color? color;
  final AnalysisGroup? selected;
  final String lowerKind;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final muted = ds.typography.bodySm.copyWith(color: ds.colors.textSecondary);
    final group = selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group == null ? kindName : _groupName(group),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: muted,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AppMoneyText(group?.amount ?? total, size: MoneySize.large, color: color),
        ),
        if (group != null)
          Text(
            t.analysis.shareOf(percent: _shareText(group.share), kind: lowerKind),
            textAlign: TextAlign.center,
            style: muted,
          ),
      ],
    );
  }
}

/// Kaki kartu: transfer periode itu sebagai informasi, tanpa penanda warna,
/// persen, atau irisan (B-4).
class _TransferFoot extends StatelessWidget {
  const _TransferFoot({required this.info});

  final TransferInfo info;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget line({required String title, required int sen, String? sub}) => Row(
      children: [
        DsIconTile.asset(asset: ClayIcons.transfer, size: DsIconTileSize.sm),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: ds.typography.titleMd.copyWith(fontSize: 14))),
                  const SizedBox(width: 8),
                  AppMoneyText(sen, size: MoneySize.small, color: c.textSecondary),
                ],
              ),
              if (sub != null) Text(sub, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('analysis-transfers'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
      child: Column(
        spacing: 12,
        children: [
          if (info.perWallet) ...[
            line(title: t.analysis.transferIn, sen: info.incoming),
            line(title: t.analysis.transferOut, sen: info.outgoing),
          ] else
            line(title: t.analysis.transferTitle, sen: info.total, sub: t.analysis.transferSub),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(
        key: ValueKey('analysis-loading'),
        spacing: 16,
        children: [
          DsSkeleton(height: 52, radius: DsRadius.fullAll),
          DsSkeleton(height: 44, radius: DsRadius.fullAll),
          DsSkeleton(height: 272, radius: DsRadius.lgAll),
          DsSkeleton(height: 116, radius: DsRadius.lgAll),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Padding(
      key: const ValueKey('analysis-error'),
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 32, color: ds.colors.textSecondary),
          const SizedBox(height: 8),
          Text(
            t.analysis.error,
            textAlign: TextAlign.center,
            style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
