import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
    required this.onShowBudget,
    this.isForecast = false,
    this.withoutPayday = false,
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

  /// Periode peralihan tanpa gajian (FINANCIAL_PERIOD P-8): angka negatif
  /// tanpa warna peringatan, dengan satu kalimat penjelas. Peringatan
  /// berbasis saldo tetap di tempatnya sendiri.
  final bool withoutPayday;

  /// Baris "Di luar rencana": selisih sisa dari rencana, supaya angka besar
  /// tetap sama dengan jumlah baris.
  int get offPlan => plan.remaining - plan.planned;

  static void _showInfo(BuildContext context) => showAppSheet<void>(
    context,
    builder: (sheetContext) {
      final ds = sheetContext.ds;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DsIconTile.asset(asset: ClayIcons.coins, size: DsIconTileSize.lg),
              ),
              const SizedBox(height: 12),
              Text(
                t.plan.infoTitle,
                textAlign: TextAlign.center,
                style: ds.typography.headlineMd.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              for (final line in [
                t.plan.infoIncome,
                t.plan.infoBills,
                t.plan.infoBudget,
                t.plan.infoOffPlan,
                t.plan.infoResult,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line, style: ds.typography.bodyMd),
                ),
              const SizedBox(height: 6),
              Text(t.plan.infoNotBalance, style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final remaining = plan.remaining;
    final outflow = plan.plannedRecurringOut + plan.budgetPlanned;
    return DsSummaryHero(
      label: t.plan.unplannedTitle(month: monthLabel),
      badge: isForecast ? t.plan.forecastBadge : null,
      amount: remaining,
      negative: remaining < 0 && !withoutPayday,
      format: AppMoneyFormatter.format,
      ratio: plan.plannedIncome <= 0 ? 0 : outflow / plan.plannedIncome,
      asset: ClayIcons.coins,
      semanticLabel: '${t.plan.unplannedTitle(month: monthLabel)} ${AppMoneyFormatter.format(remaining)}',
      labelTrailing: DsIconButton.onHero(
        icon: Icons.info_outline,
        label: t.plan.infoAction,
        onPressed: () => _showInfo(context),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (withoutPayday)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                t.plan.transitionNoPayday,
                key: const ValueKey('unplanned-no-payday'),
                style: ds.typography.bodySm.copyWith(color: c.onHeroMuted),
              ),
            ),
          DsSummaryGlass(
            child: Column(
              children: [
                _Row(label: t.plan.incomeRow, amount: plan.plannedIncome, onTap: onShowRecurring),
                _Row(label: t.plan.billsRow, amount: -plan.plannedRecurringOut, onTap: onShowRecurring),
                _Row(label: t.plan.budgetRow, amount: -plan.budgetPlanned, onTap: onShowBudget),
                if (offPlan != 0) _Row(label: t.plan.offPlanRow, amount: offPlan),
              ],
            ),
          ),
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
    final ds = context.ds;
    final c = ds.colors;
    // Nol tanpa tanda: "Rp0", bukan "+Rp0" (T-18.18).
    final sign = amount < 0 ? '−' : (amount > 0 ? '+' : '');
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: ds.typography.bodySm.copyWith(color: c.onHeroMuted)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '$sign${AppMoneyFormatter.format(amount.abs())}',
                style: ds.typography.amountSm.copyWith(color: amount > 0 ? c.primaryFixed : c.onHero),
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: c.onHeroMuted),
          ],
        ],
      ),
    );
    return onTap == null
        ? row
        : DsPressable(semanticLabel: label, onPressed: onTap, pressedScale: 0.99, builder: (context, _) => row);
  }
}
