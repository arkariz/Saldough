import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';

/// Label periode, mis. `Bulanan`.
String budgetPeriodLabel(BudgetPeriod period) => switch (period) {
  BudgetPeriod.weekly => t.budget.periodWeekly,
  BudgetPeriod.monthly => t.budget.periodMonthly,
};

/// Rentang periode yang terbaca manusia, mis. `1 Sep 2026 – 30 Sep 2026`.
/// Tanggal akhir ditampilkan INKLUSIF (sehari sebelum `Budget.endDate` yang
/// eksklusif) supaya cocok dengan cara orang menyebut rentang.
String budgetRangeLabel(Budget budget) {
  final last = budget.endDate.subtract(const Duration(days: 1));
  return t.budget.periodRange(
    start: CycleMonthFormatter.formatDateShort(budget.startDate),
    end: CycleMonthFormatter.formatDateShort(last),
  );
}

/// Label status siklus hidup: Aktif / Selesai / Nonaktif.
String budgetStatusLabel(BudgetStatus status) => switch (status) {
  BudgetStatus.active => t.budget.filterActive,
  BudgetStatus.finished => t.budget.filterFinished,
  BudgetStatus.archived => t.budget.filterArchived,
};

/// Label empat status pakai (pos maupun anggaran).
String budgetItemStatusLabel(BudgetItemStatus status) => switch (status) {
  BudgetItemStatus.planned => t.budget.itemStatusPlanned,
  BudgetItemStatus.partiallySpent => t.budget.itemStatusPartiallySpent,
  BudgetItemStatus.completed => t.budget.itemStatusCompleted,
  BudgetItemStatus.overspent => t.budget.itemStatusOverspent,
};

/// Warna TEKS status pakai. Lewat anggaran memakai `overBudget` — keadaan
/// nyata, bukan gaya kesalahan (FR-BUD-004/007). Selesai memakai `pending`
/// (batas tercapai), selain itu netral.
Color budgetItemStatusColor(BuildContext context, BudgetItemStatus status) {
  final colors = context.appColors;
  return switch (status) {
    BudgetItemStatus.planned => colors.textMuted,
    BudgetItemStatus.partiallySpent => colors.textPrimary,
    BudgetItemStatus.completed => colors.pending,
    BudgetItemStatus.overspent => colors.overBudget,
  };
}

/// Persentase bulat untuk label, mis. `70`. Rencana nol → 0.
int budgetPercent(int spent, int planned) => planned <= 0 ? 0 : (spent * 100 / planned).round();

/// Lencana kecil berlatar permukaan, huruf kapital — dipakai untuk dompet,
/// periode, dan status di kartu serta rincian anggaran.
class BudgetBadge extends StatelessWidget {
  /// Membuat [BudgetBadge].
  const BudgetBadge({required this.label, this.color, this.background, super.key});

  /// Teks lencana.
  final String label;

  /// Warna teks; bawaan `textMuted`.
  final Color? color;

  /// Warna latar; bawaan `surfaceMid`.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: background ?? colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
      child: Text(
        label.toUpperCase(),
        style: transactionLabelStyle(context, size: 9, color: color ?? colors.textMuted),
      ),
    );
  }
}

/// [AppSegmentedProgressBar] selebar induknya: lebar segmen dihitung dari
/// ruang yang tersedia, bukan tetap 8px, supaya bilah mengisi kartu seperti
/// rujukan visual.
class BudgetProgressBar extends StatelessWidget {
  /// Membuat [BudgetProgressBar] untuk rasio [value].
  const BudgetProgressBar({required this.value, this.height = 10, super.key});

  /// Rasio progres (boleh > 1).
  final double value;

  /// Tinggi segmen.
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const count = 10;
        const gap = 3.0;
        final width = (constraints.maxWidth - gap * (count - 1)) / count;
        return AppSegmentedProgressBar(
          value: value,
          segmentWidth: width,
          segmentHeight: height,
          gap: gap,
        );
      },
    );
  }
}
