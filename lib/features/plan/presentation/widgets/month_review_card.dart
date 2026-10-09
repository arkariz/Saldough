import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final steps = state.reviewSteps;
    final done = state.review.doneSteps;
    final progress = t.plan.reviewProgress(done: state.reviewDoneCount, total: steps.length);
    if (state.review.dismissed) {
      return AppTappable(
        key: const ValueKey('month-review-collapsed'),
        label: t.plan.reviewCollapsed(month: monthLabel, done: state.reviewDoneCount, total: steps.length),
        onTap: () => bloc.add(const PlanReviewDismissed(dismissed: false)),
        child: Row(
          children: [
            Expanded(
              // Labelnya sudah dibacakan `AppTappable` (T-16.16 K7).
              child: ExcludeSemantics(
                child: Text(
                  t.plan.reviewCollapsed(month: monthLabel, done: state.reviewDoneCount, total: steps.length),
                  style: textTheme.bodyMedium,
                ),
              ),
            ),
            const AppIcon(IconKey.chevronRight, size: 18),
          ],
        ),
      );
    }

    Widget step(MonthReviewStep step, String text, List<Widget> actions) {
      final checked = done.contains(step);
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(
              checked ? IconKey.check : IconKey.info,
              size: 18,
              color: checked ? colors.brand : colors.ink2,
            ),
            const SizedBox(width: AppSpacing.space1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: textTheme.bodyMedium),
                  if (!checked) Wrap(spacing: AppSpacing.space1, children: actions),
                ],
              ),
            ),
          ],
        ),
      );
    }

    void mark(MonthReviewStep s) => bloc.add(PlanReviewStepDone(s));
    final estimate = state.estimatedRules.firstOrNull;
    return AppCard(
      key: const ValueKey('month-review-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.plan.reviewTitle(month: monthLabel),
                  style: labelSmStyle(context, color: colors.ink2),
                ),
              ),
              Text(progress, style: textTheme.bodySmall),
            ],
          ),
          if (steps.contains(MonthReviewStep.budgets))
            step(
              MonthReviewStep.budgets,
              t.plan.reviewBudgets(amount: AppMoneyFormatter.format(state.recurringBudgetTotal)),
              [
                AppButton.text(small: true, label: t.plan.reviewOk, onPressed: () => mark(MonthReviewStep.budgets)),
                AppButton.text(small: true, label: t.plan.reviewEdit, onPressed: onShowBudget),
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
                AppButton.text(small: true, label: t.plan.reviewOk, onPressed: () => mark(MonthReviewStep.estimates)),
                AppButton.text(small: true, label: t.plan.reviewEditEstimate, onPressed: onShowRecurring),
              ],
            ),
          if (steps.contains(MonthReviewStep.lookback))
            step(
              MonthReviewStep.lookback,
              accuracyText(state) ?? t.plan.reviewLookback(month: state.previousRange.label),
              [
                AppButton.text(small: true, label: t.plan.reviewSee, onPressed: () async {
                    await showLookbackSheet(context, state);
                    mark(MonthReviewStep.lookback);
                  }),
              ],
            ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(label: t.plan.reviewDone, onPressed: () => bloc.add(const PlanReviewCompleted())),
          AppButton.text(small: true, label: t.plan.reviewLater, onPressed: () => bloc.add(const PlanReviewDismissed())),
        ],
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
      final textTheme = Theme.of(sheetContext).textTheme;
      Widget line(String label, String planned, String actual, {bool bold = false}) {
        final style = textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w700 : null);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
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
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.plan.lookbackTitle(month: state.previousRange.label), style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.space2),
              line('', t.plan.lookbackPlanned, t.plan.lookbackActual, bold: true),
              for (final (label, planned, actual) in rows)
                line(label, AppMoneyFormatter.format(planned), AppMoneyFormatter.format(actual)),
              const Divider(),
              line(
                t.plan.lookbackFree,
                AppMoneyFormatter.format(plan.planned),
                AppMoneyFormatter.format(plan.remaining),
                bold: true,
              ),
              if (accuracy != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(accuracy, key: const ValueKey('lookback-accuracy'), style: textTheme.bodySmall),
              ] else if (biggest.$3 != biggest.$2) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(t.plan.lookbackBiggest(line: biggest.$1), style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      );
    },
  );
}
