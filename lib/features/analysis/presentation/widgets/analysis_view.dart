import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/domain/period_comparison.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/presentation/analysis_colors.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_trend.dart';
import 'package:saldough/features/analysis/presentation/widgets/compare_line.dart';
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
          child: AppEmptyState(
            art: EmptyArt.history,
            title: t.analysis.empty.title,
            body: t.analysis.empty.body,
            actionLabel: t.analysis.empty.cta,
            onAction: () => context.pushRoute(
              RecordRouteKeys.sheet,
              const RecordSheetInput(),
            ),
          ),
        ),
      ];
    }
    final period = state.period;
    final summary = state.summary;
    return [
      AppPeriodStepper(
        title: period.label,
        transitionDays: period.isTransition ? period.days : null,
        onPrevious: state.canGoBack ? () => bloc.add(const AnalysisPeriodStepped(forward: false)) : null,
        onNext: state.isCurrent ? null : () => bloc.add(const AnalysisPeriodStepped(forward: true)),
      ),
      const SizedBox(height: AppSpacing.space3),
      _Controls(state: state),
      const SizedBox(height: AppSpacing.space4),
      if (summary == null || summary.isEmpty)
        AppCard(
          key: const ValueKey('analysis-none'),
          child: Text(
            state.kind == CategoryKind.income
                ? t.analysis.emptyMonthIncome(period: period.name)
                : t.analysis.emptyMonth(period: period.name),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: context.appColors.ink2),
          ),
        )
      else
        _AnalysisCard(state: state, summary: summary),
      // Transfer tetap informasi walau jenis ini kosong (B-4, F7): mis. dompet
      // Tabungan yang hanya menerima transfer.
      if (summary != null && summary.isEmpty && summary.transfers.hasAny)
        AppCard(
          key: const ValueKey('analysis-transfers-only'),
          padding: EdgeInsets.zero,
          child: _TransferFoot(info: summary.transfers),
        ),
      AnalysisTrendSection(state: state),
    ];
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
          child: AppSegmentedControl<CategoryKind>(
            key: const ValueKey('analysis-kind'),
            options: [
              (CategoryKind.expense, t.analysis.kind.expense),
              (CategoryKind.income, t.analysis.kind.income),
            ],
            selected: state.kind,
            onChanged: (kind) => bloc.add(AnalysisKindChanged(kind)),
          ),
        ),
        if (wallets.length > 1)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: AppMenuSelectButton<String>(
                key: const ValueKey('analysis-wallet'),
                icon: selected == null ? IconKey.wallets : walletIconKey(selected.iconKey),
                label: selected?.name ?? t.analysis.allWallets,
                options: [
                  for (final wallet in wallets)
                    (
                      value: wallet.id,
                      label: wallet.name,
                      icon: walletIconKey(wallet.iconKey),
                    ),
                ],
                allLabel: t.analysis.allWallets,
                allIcon: IconKey.wallets,
                onSelected: (id) => bloc.add(AnalysisWalletChanged(id)),
              ),
            ),
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

    return AppCard(
      key: const ValueKey('analysis-card'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space4),
          Center(
            child: AppDonutChart(
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
              child: AppButton.secondary(
                key: const ValueKey('analysis-detail'),
                label: t.analysis.category.seeCategory(
                  category: _groupName(selected),
                ),
                small: true,
                onPressed: () => _openDetail(context, state, selected, from: 'link'),
              ),
            ),
          ],
          if (selected?.kind == AnalysisGroupKind.uncategorized) ...[
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: AppButton.secondary(
                key: const ValueKey('analysis-fix'),
                label: t.analysis.fix,
                small: true,
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final label = compareLabel(comparison);
    return Container(
      key: const ValueKey('analysis-highlights'),
      margin: const EdgeInsets.only(top: AppSpacing.space2),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Column(
        children: [
          for (final highlight in highlights)
            InkWell(
              key: ValueKey('analysis-highlight-${highlight.group.key}'),
              onTap: () => onOpen(highlight.group),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space2,
                ),
                child: Row(
                  children: [
                    AppIconTile(
                      highlight.group.category == null ? IconKey.freelance : categoryIcon(highlight.group.category!),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Expanded(
                      child: Text(
                        _highlightText(highlight, label),
                        style: textTheme.bodyLarge,
                      ),
                    ),
                    AppIcon(IconKey.chevronRight, color: colors.ink3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final group = selected;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          group == null ? kindName : _groupName(group),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: AppMoneyText(
            group?.amount ?? total,
            size: MoneySize.large,
            color: color,
          ),
        ),
        if (group != null)
          Text(
            t.analysis.shareOf(
              percent: _shareText(group.share),
              kind: lowerKind,
            ),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    Widget line({required String title, required int sen, String? sub}) => Row(
      children: [
        AppIconTile(IconKey.transfer, background: colors.surface),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(child: Text(title, style: textTheme.titleSmall)),
                  const SizedBox(width: AppSpacing.space2),
                  AppMoneyText(sen, size: MoneySize.small, color: colors.ink2),
                ],
              ),
              if (sub != null)
                Text(
                  sub,
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                ),
            ],
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('analysis-transfers'),
      color: colors.surface2,
      margin: const EdgeInsets.only(top: AppSpacing.space2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space3,
      ),
      child: Column(
        spacing: AppSpacing.space3,
        children: [
          if (info.perWallet) ...[
            line(title: t.analysis.transferIn, sen: info.incoming),
            line(title: t.analysis.transferOut, sen: info.outgoing),
          ] else
            line(
              title: t.analysis.transferTitle,
              sen: info.total,
              sub: t.analysis.transferSub,
            ),
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
      padding: EdgeInsets.only(top: AppSpacing.space2),
      child: Column(
        key: ValueKey('analysis-loading'),
        spacing: AppSpacing.space4,
        children: [
          AppSkeleton(height: 28, width: 160),
          AppSkeleton(height: 48),
          AppSkeleton(height: 36, width: 140),
          AppSkeleton(height: 116),
          AppSkeleton(height: 272),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      key: const ValueKey('analysis-error'),
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          AppIcon(IconKey.error, size: 32, color: colors.ink2),
          const SizedBox(height: AppSpacing.space2),
          Text(
            t.analysis.error,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}
