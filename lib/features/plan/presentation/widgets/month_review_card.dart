import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/features/plan/domain/month_review.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_bloc.dart';
import 'package:saldough/features/plan/presentation/bloc/plan_month_state.dart';
import 'package:state_management/state_management.dart';

/// Kartu **tinjau awal bulan** di Bulan ini (J4, PLAN_TAB_LAYOUT §4.1 blok 0,
/// ADR-036 §3.7): tiga langkah yang bisa dicentang di tempat dan dilewati,
/// satu tombol primer "Selesai meninjau", dan "Nanti" yang melipatnya jadi
/// satu baris sampai hari ke-7. Tidak pernah memblokir pencatatan.
class MonthReviewCard extends StatelessWidget {
  /// Membuat [MonthReviewCard].
  const MonthReviewCard({
    required this.state,
    required this.monthLabel,
    required this.onShowBudget,
    required this.onShowRecurring,
    super.key,
  });

  /// State Bulan ini.
  final PlanMonthState state;

  /// Label bulan berjalan.
  final String monthLabel;

  /// Ke segmen Anggaran (Ubah anggaran).
  final VoidCallback onShowBudget;

  /// Ke segmen Rutin (Ubah perkiraan).
  final VoidCallback onShowRecurring;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlanMonthBloc>();
    final ds = context.ds;
    final c = ds.colors;
    final steps = state.reviewSteps;
    final done = state.review.doneSteps;
    final progress = t.plan.reviewProgress(done: state.reviewDoneCount, total: steps.length);
    if (state.review.dismissed) {
      final label = t.plan.reviewCollapsed(month: monthLabel, done: state.reviewDoneCount, total: steps.length);
      return DsPressable(
        key: const ValueKey('month-review-collapsed'),
        semanticLabel: label,
        onPressed: () => bloc.add(const PlanReviewDismissed(dismissed: false)),
        pressedScale: 0.99,
        builder: (context, _) => DsCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              DsIconTile.asset(asset: ClayIcons.clipboard, size: DsIconTileSize.sm),
              const SizedBox(width: 12),
              Expanded(
                // Labelnya sudah dibacakan `DsPressable` (T-16.16 K7).
                child: ExcludeSemantics(child: Text(label, style: ds.typography.bodyMd)),
              ),
              Icon(Icons.chevron_right, size: 20, color: c.textMuted),
            ],
          ),
        ),
      );
    }

    Widget step(MonthReviewStep step, String text, List<DsInlineAction> actions, {bool keepActions = false}) {
      final checked = done.contains(step);
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: 24,
              child: Center(
                child: checked
                    ? SvgPicture.asset(ClayIcons.done, width: 24, height: 24)
                    : Icon(Icons.radio_button_unchecked, size: 20, color: c.textMuted),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text,
                      style: ds.typography.bodyMd.copyWith(color: checked ? c.textSecondary : c.textPrimary),
                    ),
                  ),
                  if (!checked || keepActions) ...[const SizedBox(height: 6), DsInlineActions(actions: actions)],
                ],
              ),
            ),
          ],
        ),
      );
    }

    void mark(MonthReviewStep s) => bloc.add(PlanReviewStepDone(s));
    final estimate = state.estimatedRules.firstOrNull;
    return DsReveal(
      child: DsCard(
        key: const ValueKey('month-review-card'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DsIdleMotion(
                  kind: DsIdleKind.float,
                  child: DsIconTile.asset(asset: ClayIcons.clipboard, size: DsIconTileSize.sm),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.plan.reviewTitle(month: monthLabel), style: ds.typography.titleMd),
                ),
                if (steps.isNotEmpty) DsBadge(label: progress, tone: DsBadgeTone.warm),
              ],
            ),
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 12),
              DsSegmentMeter(
                value: state.reviewDoneCount / steps.length,
                segments: steps.length,
                semanticLabel: progress,
              ),
            ],
            // Periode peralihan: kartu muncul sekali dengan penjelasannya (P-9).
            if (state.range.isTransition)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  t.plan.transitionReview(
                    start: switch (state.activeStart.day) {
                      final day? => t.plan.financialMonthOnDay(day: day),
                      null => t.plan.financialMonthOnLastDay,
                    },
                    range: state.range.rangeLabel,
                  ),
                  key: const ValueKey('month-review-transition'),
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
              ),
            if (steps.contains(MonthReviewStep.budgets))
              step(
                MonthReviewStep.budgets,
                t.plan.reviewBudgets(amount: AppMoneyFormatter.format(state.recurringBudgetTotal)),
                [
                  DsInlineAction(label: t.plan.reviewEdit, onPressed: onShowBudget),
                  DsInlineAction(
                    tone: DsInlineActionTone.primary,
                    label: t.plan.reviewOk,
                    onPressed: () => mark(MonthReviewStep.budgets),
                  ),
                ],
              ),
            if (estimate != null && steps.contains(MonthReviewStep.estimates))
              step(
                MonthReviewStep.estimates,
                t.plan.reviewEstimate(
                  name: estimate.note.isEmpty ? t.record.repeat.fallbackName : estimate.note,
                  amount: AppMoneyFormatter.format(estimate.amount),
                ),
                [
                  DsInlineAction(label: t.plan.reviewEditEstimate, onPressed: onShowRecurring),
                  DsInlineAction(
                    tone: DsInlineActionTone.primary,
                    label: t.plan.reviewOk,
                    onPressed: () => mark(MonthReviewStep.estimates),
                  ),
                ],
              ),
            if (steps.contains(MonthReviewStep.lookback))
              step(
                MonthReviewStep.lookback,
                accuracyText(state) ?? t.plan.reviewLookback(month: state.previousRange.label),
                [
                  DsInlineAction(
                    label: done.contains(MonthReviewStep.lookback) ? t.plan.reviewSeeAgain : t.plan.reviewSee,
                    onPressed: () async {
                      await showLookbackSheet(context, state);
                      mark(MonthReviewStep.lookback);
                    },
                  ),
                ],
                // Kilas balik boleh dibuka berkali-kali sampai kartu ditutup (B-18, T-19.11):
                // pintu "Lihat rincian {bulan}" ke Analisis tetap terjangkau.
                keepActions: true,
              ),
            const SizedBox(height: 16),
            DsButton(label: t.plan.reviewDone, expand: true, onPressed: () => bloc.add(const PlanReviewCompleted())),
            DsButton.ghost(
              label: t.plan.reviewLater,
              expand: true,
              onPressed: () => bloc.add(const PlanReviewDismissed()),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris kilas balik (label, rencana, nyata) bulan lalu (W10).
List<(String, int, int)> lookbackRows(PlanMonthState state) {
  final plan = state.previousPlan;
  return [
    (t.plan.incomeRow, plan.plannedIncome, plan.recordedIncome + plan.unplannedIn),
    (t.plan.billsRow, plan.plannedRecurringOut, plan.recordedRecurringOut),
    (t.plan.budgetRow, plan.budgetPlanned, plan.budgetSpent),
    (t.plan.offPlanRow, 0, plan.unplannedOut),
  ];
}

/// Baris kilas balik dengan selisih rencana vs nyata terbesar.
(String, int, int) _biggest(List<(String, int, int)> rows) =>
    rows.reduce((a, b) => (a.$3 - a.$2).abs() >= (b.$3 - b.$2).abs() ? a : b);

/// Teks akurasi perkiraan bulan lalu (W9), atau `null` tanpa snapshot.
String? accuracyText(PlanMonthState state) {
  final miss = state.forecastMiss;
  if (miss == null) return null;
  final month = state.previousRange.label;
  if (miss == 0) return t.plan.accuracyExact(month: month);
  final biggest = _biggest(lookbackRows(state));
  return biggest.$3 == biggest.$2
      ? t.plan.accuracyMissed(month: month, amount: AppMoneyFormatter.format(miss.abs()))
      : t.plan.accuracyMissedBy(month: month, amount: AppMoneyFormatter.format(miss.abs()), line: biggest.$1);
}

/// Lembar **kilas balik** bulan lalu (W10, ADR-036 §3.7): rencana vs nyata
/// per baris, dihitung ulang dari buku besar, plus akurasi perkiraan (W9).
Future<void> showLookbackSheet(BuildContext context, PlanMonthState state) {
  final plan = state.previousPlan;
  final rows = lookbackRows(state);
  final biggest = _biggest(rows);
  final accuracy = accuracyText(state);
  return showAppSheet<void>(
    context,
    builder: (sheetContext) {
      final ds = sheetContext.ds;
      final c = ds.colors;
      Widget line(String label, String planned, String actual, {bool bold = false, bool head = false}) {
        final style = (head ? ds.typography.labelMd : ds.typography.bodyMd).copyWith(
          fontWeight: bold ? FontWeight.w700 : null,
          color: head ? c.textSecondary : null,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(label, style: style)),
              Expanded(
                flex: 2,
                child: Text(planned, style: style, textAlign: TextAlign.end),
              ),
              Expanded(
                flex: 2,
                child: Text(actual, style: style, textAlign: TextAlign.end),
              ),
            ],
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DsIconTile.asset(asset: ClayIcons.report, size: DsIconTileSize.lg),
              ),
              const SizedBox(height: 12),
              Text(
                t.plan.lookbackTitle(month: state.previousRange.label),
                textAlign: TextAlign.center,
                style: ds.typography.headlineMd.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              DsCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    line('', t.plan.lookbackPlanned, t.plan.lookbackActual, head: true),
                    for (final (label, planned, actual) in rows)
                      line(label, AppMoneyFormatter.format(planned), AppMoneyFormatter.format(actual)),
                    Divider(height: 12, color: c.outlineSubtle),
                    line(
                      t.plan.lookbackFree,
                      AppMoneyFormatter.format(plan.planned),
                      AppMoneyFormatter.format(plan.remaining),
                      bold: true,
                    ),
                  ],
                ),
              ),
              if (accuracy != null) ...[
                const SizedBox(height: 12),
                Text(
                  accuracy,
                  key: const ValueKey('lookback-accuracy'),
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
              ] else if (biggest.$3 != biggest.$2) ...[
                const SizedBox(height: 12),
                Text(
                  t.plan.lookbackBiggest(line: biggest.$1),
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
              ],
              // Pintu ke Analisis periode itu (FINANCIAL_ANALYSIS F8.1, T-19.6).
              const SizedBox(height: 12),
              DsButton.secondary(
                key: const ValueKey('lookback-see-analysis'),
                expand: true,
                label: t.plan.lookbackSeeAnalysis(month: state.previousRange.name),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                    context.pushRoute(
                      AnalysisRouteKeys.open,
                      AnalysisInput(source: AnalysisSource.lookback, periodStart: state.previousRange.start),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
