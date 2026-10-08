import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';

/// Satu kartu di layar Anggaran (T-4.5, rujukan `pixel_kas_daftar_anggaran`).
///
/// ⚠ Delapan isian wajib: nama, dompet, periode, nominal rencana, terpakai,
/// sisa, progres, dan status. Nama dompet selalu terbaca tanpa membuka
/// anggarannya. Lewat anggaran ditandai badge yang menyebut selisihnya
/// (FR-BUD-004, design system ProgressBar).
class BudgetCard extends StatelessWidget {
  /// Membuat [BudgetCard].
  const BudgetCard({
    required this.budget,
    required this.progress,
    required this.walletName,
    required this.onTap,
    this.isRecurring = false,
    super.key,
  });

  /// Anggaran yang ditampilkan.
  final Budget budget;

  /// Progres anggaran itu.
  final BudgetProgress progress;

  /// Nama dompet anggaran (atau label "tidak ditemukan").
  final String walletName;

  /// Dipanggil saat kartu diketuk.
  final VoidCallback onTap;

  /// Anggaran rutin (Ulangi tiap periode, ADR-036; T-16.16 K6).
  final bool isRecurring;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final overspent = progress.spendingStatus == BudgetItemStatus.overspent;
    final active = progress.status == BudgetStatus.active;
    // Satu badge per kartu: Lewat (masalah) > Rutin > status bila bukan aktif.
    final Widget? badge = overspent
        ? AppBadge(
            t.home.budgetOverBy(amount: AppMoneyFormatter.format(-progress.remaining)),
            tone: AppTone.danger,
          )
        : isRecurring
        ? AppBadge(
            t.budget.recurringBadge,
            key: const ValueKey('budget-recurring-badge'),
            tone: AppTone.brand,
            icon: IconKey.schedule,
          )
        : !active
        ? AppBadge(budgetStatusLabel(progress.status))
        : null;
    return Opacity(
      opacity: active ? 1 : 0.7,
      child: AppCard(
        onTap: onTap,
        semanticsLabel: budget.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.name, style: textTheme.titleMedium),
                      Text(
                        '$walletName · ${budgetRangeLabel(budget)}',
                        style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: AppSpacing.space2), Flexible(child: badge)],
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            // Penanda waktu hanya untuk anggaran yang sedang berjalan.
            AppProgressBar(value: progress.progress, pace: active ? budget.elapsedRatio(DateTime.now()) : null),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.space2,
              children: [
                Text(
                  t.home.budgetSpentOf(
                    spent: AppMoneyFormatter.format(progress.spent),
                    planned: AppMoneyFormatter.format(progress.plannedAmount),
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                Text.rich(
                  TextSpan(
                    text: '${t.budget.remainingLabel} ',
                    children: [
                      TextSpan(
                        text: AppMoneyFormatter.format(progress.remaining),
                        style: context.numberStyles.amountSm.copyWith(
                          color: progress.remaining < 0 ? colors.danger : colors.ink,
                        ),
                      ),
                    ],
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
