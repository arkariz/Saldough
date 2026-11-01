import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/domain/category_detail.dart';
import 'package:saldough/features/analysis/presentation/bloc/category_detail_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/category_detail_state.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_trend.dart';
import 'package:saldough/features/analysis/presentation/widgets/compare_line.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Rincian satu kategori di satu periode (A5, FR-ANL-004): total, persen,
/// pembanding, frekuensi, tren enam periode dengan garis rata-rata, dan
/// transaksinya. Hanya membaca; sunting lewat CATAT dari rincian transaksi,
/// dan sekembalinya angka sudah segar.
class CategoryDetailPage extends StatelessWidget {
  /// Membuat [CategoryDetailPage].
  const CategoryDetailPage({required this.input, super.key});

  /// Kategori dan periode yang dirinci.
  final CategoryDetailInput input;

  @override
  Widget build(BuildContext context) {
    final container = ScopeProvider.of(context);
    return BlocProvider<CategoryDetailBloc>(
      create: (_) => CategoryDetailBloc(
        transactionRepository: container<TransactionRepository>(),
        walletRepository: container<WalletRepository>(),
        ledgerChanges: container<LedgerChanges>(),
        input: input,
      )..add(const CategoryDetailStarted()),
      child: EffectListener<CategoryDetailBloc, CategoryDetailState>(
        child: BlocBuilder<CategoryDetailBloc, CategoryDetailState>(
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: Text(state.name, style: context.ds.typography.headlineMd),
              centerTitle: false,
            ),
            body: SafeArea(
              child: _Body(state: state, input: input),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.input});

  final CategoryDetailState state;
  final CategoryDetailInput input;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CategoryDetailBloc>();
    if (state.isLoading) return const AppSkeletonPage();
    final detail = state.detail;
    if (state.loadFailed || detail == null) {
      return DsErrorState(
        title: t.transaction.loadErrorTitle,
        retryLabel: t.common.retry,
        onRetry: () => bloc.add(const CategoryDetailStarted()),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const CategoryDetailRefreshed());
        await bloc.stream.firstWhere((s) => !s.isLoading);
      },
      child: ListView(
        key: const ValueKey('category-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          32,
        ),
        children: [
          _SummaryCard(state: state, detail: detail),
          if (detail.trend.length >= 2) ...[
            const SizedBox(height: 16),
            DsSectionHeader(title: t.analysis.trend.title),
            const SizedBox(height: 8),
            _TrendCard(state: state, detail: detail, input: input),
          ],
          const SizedBox(height: 16),
          DsSectionHeader(title: t.analysis.category.transactions),
          if (state.hasMore)
            Text(
              t.analysis.category.moreHint,
              style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
            ),
          const SizedBox(height: 8),
          if (state.groups.isEmpty)
            DsCard(
              key: const ValueKey('category-empty'),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
                  const SizedBox(height: 10),
                  Text(
                    t.transaction.filteredEmpty,
                    textAlign: TextAlign.center,
                    style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
                  ),
                ],
              ),
            )
          else
            for (final (i, group) in state.groups.indexed) ...[
              if (i > 0) const SizedBox(height: 16),
              TransactionDateGroupCard(
                group: group,
                walletsById: state.walletsById,
                onTransactionTap: (transaction) => context.pushRoute(
                  TransactionRouteKeys.detail,
                  TransactionDetailInput(transaction),
                ),
              ),
            ],
          const SizedBox(height: 12),
          DsButton.secondary(
            key: const ValueKey('category-see-all'),
            expand: true,
            label: t.analysis.category.seeAll,
            onPressed: () {
              AppAnalytics.log(AnalysisEvents.seeAllOpened);
              unawaited(
                context.pushRoute(
                  TransactionRouteKeys.filtered,
                  TransactionFilterInput(
                    title: state.name,
                    subtitle: state.period.label,
                    filter: bloc.periodFilter(state.period),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Kartu atas: periode, total, persen, pembanding, dan frekuensi (B-17).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state, required this.detail});

  final CategoryDetailState state;
  final CategoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final income = state.kind == CategoryKind.income;
    final kindName = (income ? t.analysis.kind.income : t.analysis.kind.expense).toLowerCase();
    final share = detail.share.belowOne ? '<1%' : '${detail.share.percent}%';
    final comparison = detail.comparison;
    final frequency = detail.frequency;
    final isNew = comparison != null && comparison.isNew;
    String decimal(int tenths) {
      final text = tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10}.${tenths % 10}';
      return LocaleSettings.currentLocale == AppLocale.en ? text : text.replaceAll('.', ',');
    }

    return DsCard(
      key: const ValueKey('category-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.period.label,
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
              if (state.isArchived)
                DsBadge(
                  label: t.analysis.archived,
                  tone: DsBadgeTone.neutral,
                  key: const ValueKey('category-archived'),
                ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AppMoneyText(
              detail.amount,
              size: MoneySize.hero,
              color: income ? c.income : null,
            ),
          ),
          Text(
            t.analysis.shareOf(percent: share, kind: kindName),
            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
          ),
          if (isNew)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: DsBadge(
                  label: t.analysis.compare.newThisMonth,
                  tone: DsBadgeTone.neutral,
                  key: const ValueKey('analysis-new'),
                ),
              ),
            )
          else if (comparison != null && comparison.hasBaseline)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CompareLine(
                label: compareLabelOf(
                  months: comparison.months,
                  toDay: detail.compareToDay,
                ),
                result: comparison,
                isGroup: true,
                isUncategorized: false,
                alignStart: true,
              ),
            ),
          Divider(height: 16, color: c.outlineSubtle),
          Row(
            key: const ValueKey('category-frequency'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.receipt_long_outlined, size: 18, color: c.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frequency.count == 1
                          ? t.analysis.category.frequencyOne(
                              count: 1,
                              amount: AppMoneyFormatter.format(
                                frequency.average,
                              ),
                            )
                          : t.analysis.category.frequency(
                              count: frequency.count,
                              amount: AppMoneyFormatter.format(
                                frequency.average,
                              ),
                            ),
                      style: ds.typography.bodyMd.copyWith(color: c.textPrimary),
                    ),
                    if (frequency.usualCountTenths != null && frequency.usualAverage != null)
                      Text(
                        t.analysis.category.frequencyUsual(
                          count: decimal(frequency.usualCountTenths!),
                          amount: AppMoneyFormatter.format(
                            frequency.usualAverage!,
                          ),
                        ),
                        key: const ValueKey('category-usual'),
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tren satu kategori: batang per periode, garis rata-rata, dan panel angka
/// kolom terpilih (B-17).
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.state,
    required this.detail,
    required this.input,
  });

  final CategoryDetailState state;
  final CategoryDetail detail;
  final CategoryDetailInput input;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final bloc = context.read<CategoryDetailBloc>();
    final trend = detail.trend;
    final selected = state.trendIndex;
    final point = trend[selected];
    final isViewed = selected == trend.length - 1;
    final average = detail.average;
    final months = detail.comparison?.months ?? 0;
    final comparable = average != null && !point.isRunning && !point.period.isTransition;
    final diff = comparable ? point.amount - average : 0;

    TrendColumn column(CategoryTrendPoint p) {
      final caption = p.isRunning
          ? t.analysis.trend.toDate(
              date: CycleMonthFormatter.formatDayMonth(p.asOf!),
            )
          : p.period.isTransition
          ? t.analysis.trend.days(n: p.period.days)
          : null;
      return TrendColumn(
        label: CycleMonthFormatter.formatMonthShort(p.period.lastDay),
        income: 0,
        expense: p.amount,
        caption: caption,
        semanticsLabel:
            '${caption == null ? p.period.label : '${p.period.label} ($caption)'}, '
            '${state.name} ${AppMoneyFormatter.format(p.amount)}',
      );
    }

    final title = point.isRunning
        ? '${point.period.label} · ${t.analysis.trend.toDate(date: CycleMonthFormatter.formatDayMonth(point.asOf!))}'
        : point.period.label;
    return DsCard(
      key: const ValueKey('category-trend'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          AppTrendChart(
            columns: [for (final p in trend) column(p)],
            selected: selected,
            single: true,
            average: average,
            averageLabel: average == null ? null : t.analysis.category.avgLine(n: months),
            onSelect: (index) => bloc.add(CategoryDetailTrendSelected(index)),
            axisLabel: compactAmount,
          ),
          Container(
            key: const ValueKey('category-readout'),
            decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Text(title, style: ds.typography.labelMd.copyWith(color: c.textPrimary)),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: AppMoneyFormatter.format(point.amount),
                        style: ds.typography.amountSm.copyWith(color: c.textPrimary),
                      ),
                      if (comparable && diff != 0)
                        TextSpan(
                          text:
                              ' · ${diff > 0 ? t.analysis.category.aboveAvg(amount: AppMoneyFormatter.format(diff)) : t.analysis.category.belowAvg(amount: AppMoneyFormatter.format(-diff))}',
                          style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                        ),
                    ],
                  ),
                ),
                if (!isViewed)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DsButton.ghost(
                      key: const ValueKey('category-trend-jump'),
                      label: t.analysis.trend.seePeriod(period: point.period.name),
                      onPressed: () => unawaited(
                        context.pushRoute(
                          AnalysisRouteKeys.open,
                          AnalysisInput(
                            source: AnalysisSource.history,
                            periodStart: point.period.start,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
