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
    BudgetItemStatus.planned => colors.ink2,
    BudgetItemStatus.partiallySpent => colors.ink,
    BudgetItemStatus.completed => colors.warning,
    BudgetItemStatus.overspent => colors.danger,
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

  /// Tidak dipakai lagi: latar mengikuti nada [AppBadge].
  final Color? background;

  @override
  Widget build(BuildContext context) => AppBadge(label, tone: toneFromColor(context.appColors, color));
}

/// [AppProgressBar] anggaran selebar induknya; [height] 6 atau kurang memakai
/// varian tipis (baris pos).
class BudgetProgressBar extends StatelessWidget {
  /// Membuat [BudgetProgressBar] untuk rasio [value].
  const BudgetProgressBar({required this.value, this.height = 10, super.key});

  /// Rasio progres (boleh > 1).
  final double value;

  /// Tinggi segmen.
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppProgressBar(value: value, thin: height <= 6);
  }
}
