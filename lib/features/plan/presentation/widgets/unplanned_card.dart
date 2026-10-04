import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Kartu **Uang nganggur** (PLAN_TAB_LAYOUT §4.9): angka besar = jumlah
/// baris di bawahnya (Pemasukan, Tagihan rutin, Anggaran, Di luar rencana).
/// Angka dan label pendek saja; penjelasan di lembar ⓘ.
class UnplannedCard extends StatelessWidget {
  /// Membuat [UnplannedCard].
  const UnplannedCard({
    required this.plan,
    required this.monthLabel,
    required this.onShowRecurring,
    this.isForecast = false,
    required this.onShowBudget,
    super.key,
  });

  /// Rencana bulan ini.
  final MonthPlan plan;

  /// Label bulan keuangan ("Okt" atau "25 Okt – 24 Nov").
  final String monthLabel;

  /// Baris Pemasukan dan Tagihan rutin → segmen Rutin.
  final VoidCallback onShowRecurring;

  /// Baris Anggaran → segmen Anggaran.
  final VoidCallback onShowBudget;

  /// Bulan depan (ADR-036 §3.5): kepala berlencana PERKIRAAN.
  final bool isForecast;

  /// Baris "Di luar rencana": selisih sisa dari rencana, supaya angka besar
  /// tetap sama dengan jumlah baris.
  int get offPlan => plan.remaining - plan.planned;

  static void _showInfo(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.plan.infoTitle, style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final line in [
                t.plan.infoIncome,
                t.plan.infoBills,
                t.plan.infoBudget,
                t.plan.infoOffPlan,
                t.plan.infoResult,
              ])
                Text(line, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(t.plan.infoNotBalance, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final remaining = plan.remaining;
    return AppHeroCard(
      icon: IconKey.budget,
      label: isForecast
          ? '${t.plan.unplannedTitle(month: monthLabel)} · ${t.plan.forecastBadge}'
          : t.plan.unplannedTitle(month: monthLabel),
      trailing: IconButton(
        tooltip: t.plan.infoAction,
        onPressed: () => _showInfo(context),
        icon: const AppIcon(IconKey.info, size: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroAmount(AppMoneyFormatter.format(remaining), color: remaining < 0 ? colors.overBudget : null),
          const SizedBox(height: AppSpacing.sm),
          _Row(label: t.plan.incomeRow, amount: plan.plannedIncome, onTap: onShowRecurring),
          _Row(label: t.plan.billsRow, amount: -plan.plannedRecurringOut, onTap: onShowRecurring),
          _Row(label: t.plan.budgetRow, amount: -plan.budgetPlanned, onTap: onShowBudget),
          if (offPlan != 0) _Row(label: t.plan.offPlanRow, amount: offPlan),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.amount, this.onTap});

  final String label;
  final int amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sign = amount < 0 ? '−' : '+';
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            '$sign${AppMoneyFormatter.format(amount.abs())}',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
    return onTap == null ? row : AppTappable(label: label, onTap: onTap, child: row);
  }
}
