import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/domain/period_summary.dart';
import 'package:saldough/features/analysis/presentation/analysis_colors.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
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
        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const AnalysisRefreshed());
            await bloc.stream.firstWhere((s) => !s.isLoading);
          },
          child: ListView(
            key: const ValueKey('analysis-scroll'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space8),
            children: _children(context, state, bloc),
          ),
        );
      },
    );
  }

  List<Widget> _children(BuildContext context, AnalysisState state, AnalysisBloc bloc) {
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
            onAction: () => context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput()),
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
      const SizedBox(height: AppSpacing.space4),
      if (summary == null || summary.isEmpty)
        AppCard(
          key: const ValueKey('analysis-none'),
          child: Text(
            t.analysis.emptyMonth(period: period.name),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.appColors.ink2),
          ),
        )
      else
        _AnalysisCard(summary: summary, periodName: period.name),
    ];
  }
}

String _shareText(AnalysisShare share) => share.belowOne ? '<1%' : '${share.percent}%';

String _groupName(AnalysisGroup group) => switch (group.kind) {
  AnalysisGroupKind.category => group.category!.name,
  AnalysisGroupKind.freelance => t.analysis.freelanceGroup,
  AnalysisGroupKind.uncategorized => t.analysis.uncategorized,
  AnalysisGroupKind.others => t.analysis.others(n: group.children.length),
};

String _kindName(CategoryKind kind) => kind == CategoryKind.expense ? t.analysis.kind.expense : t.analysis.kind.income;

/// Kartu donat: lingkar, legenda, dan kaki transfer di satu `AppCard`.
class _AnalysisCard extends StatefulWidget {
  const _AnalysisCard({required this.summary, required this.periodName});

  final PeriodSummary summary;
  final String periodName;

  @override
  State<_AnalysisCard> createState() => _AnalysisCardState();
}

class _AnalysisCardState extends State<_AnalysisCard> {
  /// Anggota Lainnya sedang dibuka.
  bool _othersOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final summary = widget.summary;
    final groups = summary.groups;
    final kind = _kindName(summary.kind);
    final amountColor = summary.kind == CategoryKind.income ? colors.positive : null;
    var divider = false;
    Widget row(AnalysisGroup group, {bool child = false, Color? swatch, bool? expanded, VoidCallback? onTap}) {
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
        showDivider: divider,
        amountColor: amountColor,
        onTap: onTap,
      );
      divider = true;
      return widget;
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
              slices: [for (final g in groups) DonutSlice(value: g.amount, color: analysisColorOf(colors, g))],
              semanticsLabel: t.analysis.donutSemantics(
                kind: kind,
                period: widget.periodName,
                parts: groups.map((g) => '${_groupName(g)} ${_shareText(g.share)}').join(', '),
              ),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(kind, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppMoneyText(summary.total, size: MoneySize.large, color: amountColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          for (final group in groups) ...[
            row(
              group,
              swatch: analysisColorOf(colors, group),
              expanded: group.kind == AnalysisGroupKind.others ? _othersOpen : null,
              onTap: group.kind == AnalysisGroupKind.others ? () => setState(() => _othersOpen = !_othersOpen) : null,
            ),
            if (group.kind == AnalysisGroupKind.others && _othersOpen)
              for (final member in group.children) row(member, child: true),
          ],
          if (summary.transfers.hasAny) _TransferFoot(info: summary.transfers),
        ],
      ),
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
              if (sub != null) Text(sub, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
            ],
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('analysis-transfers'),
      color: colors.surface2,
      margin: const EdgeInsets.only(top: AppSpacing.space2),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
      child: Column(
        spacing: AppSpacing.space3,
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}
