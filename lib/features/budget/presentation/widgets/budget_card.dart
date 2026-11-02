import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
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
    final ds = context.ds;
    final c = ds.colors;
    final overspent = progress.spendingStatus == BudgetItemStatus.overspent;
    final active = progress.status == BudgetStatus.active;
    final ratio = progress.progress;
    // Satu badge per kartu: Lewat (masalah) > Rutin > status bila bukan aktif.
    final Widget? badge = overspent
        ? DsBadge(
            label: t.home.budgetOverBy(amount: AppMoneyFormatter.format(-progress.remaining)),
            tone: DsBadgeTone.danger,
          )
        : isRecurring
        ? DsBadge(
            key: const ValueKey('budget-recurring-badge'),
            label: t.budget.recurringBadge,
            tone: DsBadgeTone.income,
          )
        : !active
        ? DsBadge(label: budgetStatusLabel(progress.status), tone: DsBadgeTone.neutral)
        : null;
    return Opacity(
      opacity: active ? 1 : 0.7,
      child: Semantics(
        button: true,
        label: budget.name,
        child: DsCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DsIconTile.asset(
                    asset: isRecurring ? ClayIcons.repeat : ClayIcons.piggy,
                    size: DsIconTileSize.sm,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(budget.name, style: ds.typography.titleMd),
                        Text(
                          '$walletName · ${budgetRangeLabel(budget)}',
                          style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[const SizedBox(width: 8), Flexible(child: badge)],
                ],
              ),
              const SizedBox(height: 12),
              // Penanda waktu hanya untuk anggaran yang sedang berjalan.
              DsSegmentMeter(
                value: ratio,
                tone: budgetMeterTone(ratio),
                pace: active ? budget.elapsedRatio(DateTime.now()) : null,
                semanticLabel: '${(ratio * 100).round()}%',
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 8,
                children: [
                  Text(
                    t.home.budgetSpentOf(
                      spent: AppMoneyFormatter.format(progress.spent),
                      planned: AppMoneyFormatter.format(progress.plannedAmount),
                    ),
                    style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '${t.budget.remainingLabel} ',
                      children: [
                        TextSpan(
                          text: AppMoneyFormatter.format(progress.remaining),
                          style: ds.typography.amountSm.copyWith(
                            color: progress.remaining < 0 ? c.error : c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
