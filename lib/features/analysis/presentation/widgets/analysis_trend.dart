import 'package:flutter/material.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/domain/period_trend.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/analysis_state.dart';
import 'package:state_management/state_management.dart';

/// Nominal ringkas untuk sumbu dan selisih kolom (hanya di grafik): "15 jt",
/// "630 rb" (id) atau "15M", "630K" (en). Satu angka desimal bila perlu.
String compactAmount(int sen) {
  final amount = sen.abs() / 100;
  final english = LocaleSettings.currentLocale == AppLocale.en;
  String one(double value) {
    final rounded = (value * 10).round() / 10;
    final text = rounded == rounded.roundToDouble() ? '${rounded.round()}' : rounded.toStringAsFixed(1);
    return english ? text : text.replaceAll('.', ',');
  }

  if (amount >= 1e9) return english ? '${one(amount / 1e9)}B' : '${one(amount / 1e9)} M';
  if (amount >= 1e6) return english ? '${one(amount / 1e6)}M' : '${one(amount / 1e6)} jt';
  if (amount >= 1e3) return english ? '${(amount / 1e3).round()}K' : '${(amount / 1e3).round()} rb';
  return '${amount.round()}';
}

String _sign(int sen) => AmountVisibility.hidden || sen == 0 ? '' : (sen < 0 ? '−' : '+');

/// Bagian Tren (A4, F6): enam periode berakhir di periode yang dilihat, panel
/// angka kolom terpilih, dan tautan ke periode itu. Tidak tampil dengan satu
/// periode saja.
class AnalysisTrendSection extends StatelessWidget {
  /// Membuat [AnalysisTrendSection].
  const AnalysisTrendSection({required this.state, super.key});

  /// Keadaan Analisis.
  final AnalysisState state;

  @override
  Widget build(BuildContext context) {
    final trend = state.trend;
    if (trend.length < 2) return const SizedBox.shrink();
    final ds = context.ds;
    final c = ds.colors;
    final bloc = context.read<AnalysisBloc>();
    final selected = state.trendIndex;
    final point = trend[selected];
    final isViewed = selected == trend.length - 1;

    TrendColumn column(TrendPoint p) {
      final net = p.isRunning ? compactAmount(p.net) : '${_sign(p.net)}${compactAmount(p.net)}';
      final caption = p.isRunning
          ? t.analysis.trend.toDate(
              date: CycleMonthFormatter.formatDayMonth(p.asOf!),
            )
          : p.period.isTransition
          ? t.analysis.trend.days(n: p.period.days)
          : null;
      final period = caption == null ? p.period.label : '${p.period.label} ($caption)';
      return TrendColumn(
        // Periode yang tidak mulai di tanggal 1 diberi nama bulan tempat ia berakhir.
        label: CycleMonthFormatter.formatMonthShort(p.period.lastDay),
        income: p.income,
        expense: p.expense,
        netText: AmountVisibility.hidden ? '•••' : net,
        caption: caption,
        semanticsLabel: t.analysis.trend.column(
          period: period,
          income: AppMoneyFormatter.format(p.income),
          expense: AppMoneyFormatter.format(p.expense),
          net: '${_sign(p.isRunning ? 0 : p.net)}${AppMoneyFormatter.format(p.net.abs())}',
        ),
      );
    }

    final readoutTitle = point.isRunning
        ? '${point.period.label} · ${t.analysis.trend.toDate(date: CycleMonthFormatter.formatDayMonth(point.asOf!))}'
        : point.period.label;

    return Column(
      key: const ValueKey('analysis-trend'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        DsSectionHeader(title: t.analysis.trend.title),
        const SizedBox(height: 8),
        SpotlightTarget(
          spotlightKey: SpotlightKey.analysisTrend,
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                ExcludeSemantics(
                  child: Wrap(
                    spacing: AppSpacing.space4,
                    runSpacing: AppSpacing.space1,
                    children: [
                      _LegendSwatch(
                        color: c.income,
                        label: t.analysis.trend.income,
                      ),
                      _LegendSwatch(
                        color: c.error,
                        label: t.analysis.trend.expense,
                      ),
                    ],
                  ),
                ),
                AppTrendChart(
                  columns: [for (final p in trend) column(p)],
                  selected: selected,
                  onSelect: (index) => bloc.add(AnalysisTrendSelected(index)),
                  axisLabel: compactAmount,
                ),
                Container(
                  key: const ValueKey('analysis-readout'),
                  decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Text(readoutTitle, style: ds.typography.labelMd.copyWith(color: c.textPrimary)),
                      _ReadoutRow(
                        label: t.analysis.trend.income,
                        text: '${_sign(point.income)}${AppMoneyFormatter.format(point.income)}',
                        color: c.income,
                      ),
                      _ReadoutRow(
                        label: t.analysis.trend.expense,
                        text:
                            '${AmountVisibility.hidden || point.expense == 0 ? '' : '−'}'
                            '${AppMoneyFormatter.format(point.expense)}',
                      ),
                      _ReadoutRow(
                        label: t.analysis.trend.net,
                        text:
                            '${point.isRunning ? '' : _sign(point.net)}'
                            '${AppMoneyFormatter.format(point.net.abs())}',
                      ),
                      if (!isViewed)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DsButton.ghost(
                            key: const ValueKey('analysis-trend-jump'),
                            onPressed: () => bloc.add(
                              AnalysisPeriodJumped(point.period.start),
                            ),
                            label: t.analysis.trend.seePeriod(period: point.period.name),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.space1,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Text(
          label,
          style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary),
        ),
      ],
    );
  }
}

class _ReadoutRow extends StatelessWidget {
  const _ReadoutRow({required this.label, required this.text, this.color});

  final String label;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.ds.typography.bodySm.copyWith(color: context.ds.colors.textSecondary)),
        const SizedBox(width: AppSpacing.space2),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              text,
              style: context.numberStyles.amountSm.copyWith(color: color),
            ),
          ),
        ),
      ],
    );
  }
}
