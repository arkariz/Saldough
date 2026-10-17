import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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
              title: Text(
                state.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
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
      return AppErrorState(
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
          AppSpacing.space4,
          AppSpacing.space1,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: [
          _SummaryCard(state: state, detail: detail),
          if (detail.trend.length >= 2) ...[
            const SizedBox(height: AppSpacing.space4),
            AppSectionHeader(t.analysis.trend.title),
            _TrendCard(state: state, detail: detail, input: input),
          ],
          const SizedBox(height: AppSpacing.space4),
          AppSectionHeader(
            t.analysis.category.transactions,
            hint: state.hasMore ? t.analysis.category.moreHint : null,
          ),
          if (state.groups.isEmpty)
            Padding(
              key: const ValueKey('category-empty'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Text(
                t.transaction.filteredEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: context.appColors.ink2),
              ),
            )
          else
            for (final (i, group) in state.groups.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.space4),
              TransactionDateGroupCard(
                group: group,
                walletsById: state.walletsById,
                onTransactionTap: (transaction) => context.pushRoute(
                  TransactionRouteKeys.detail,
                  TransactionDetailInput(transaction),
                ),
              ),
            ],
          const SizedBox(height: AppSpacing.space3),
          AppButton.secondary(
            key: const ValueKey('category-see-all'),
            label: t.analysis.category.seeAll,
            onPressed: () => unawaited(
              context.pushRoute(
                TransactionRouteKeys.filtered,
                TransactionFilterInput(
                  title: state.name,
                  subtitle: state.period.label,
                  filter: bloc.periodFilter(state.period),
                ),
              ),
            ),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
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

    return AppCard(
      key: const ValueKey('category-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.space1,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.period.label,
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                ),
              ),
              if (state.isArchived)
                AppBadge(
                  t.analysis.archived,
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
              color: income ? colors.positive : null,
            ),
          ),
          Text(
            t.analysis.shareOf(percent: share, kind: kindName),
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
          if (isNew)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space1),
                child: AppBadge(
                  t.analysis.compare.newThisMonth,
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
          Divider(height: AppSpacing.space4, color: colors.line),
          Row(
            key: const ValueKey('category-frequency'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AppIcon(
                  IconKey.transactions,
                  size: 18,
                  color: colors.ink2,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
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
                      style: textTheme.bodyLarge,
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
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.ink2,
                        ),
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
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
    return AppCard(
      key: const ValueKey('category-trend'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.space3,
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
            color: colors.surface2,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.space1,
              children: [
                Text(title, style: textTheme.labelLarge),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: AppMoneyFormatter.format(point.amount),
                        style: context.numberStyles.amountSm.copyWith(
                          color: colors.ink,
                        ),
                      ),
                      if (comparable && diff != 0)
                        TextSpan(
                          text:
                              ' · ${diff > 0 ? t.analysis.category.aboveAvg(amount: AppMoneyFormatter.format(diff)) : t.analysis.category.belowAvg(amount: AppMoneyFormatter.format(-diff))}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.ink2,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isViewed)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      key: const ValueKey('category-trend-jump'),
                      onPressed: () => unawaited(
                        context.pushRoute(
                          AnalysisRouteKeys.open,
                          AnalysisInput(
                            source: AnalysisSource.history,
                            periodStart: point.period.start,
                          ),
                        ),
                      ),
                      child: Text(
                        t.analysis.trend.seePeriod(period: point.period.name),
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
