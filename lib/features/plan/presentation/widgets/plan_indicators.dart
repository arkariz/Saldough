import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Indikator bulan ini (acuan "Indikator Kesehatan Arus Kas"): kisi 2×2 kartu
/// kecil yang hanya memakai angka yang sudah dihitung layar ini, tanpa
/// penilaian. Tiap kartu: label, ubin clay bulat, angka besar yang berhitung
/// naik, keterangan, dan (bila relevan) meter tipis yang menyala berurutan.
class PlanIndicators extends StatelessWidget {
  /// Membuat [PlanIndicators].
  const PlanIndicators({
    required this.plan,
    required this.lowest,
    required this.committedShare,
    required this.previousShare,
    required this.unplannedPerDay,
    super.key,
  });

  /// Rencana bulan ini.
  final MonthPlan plan;

  /// Hari saldo terendah, atau `null` tanpa perkiraan.
  final ProjectedDay? lowest;

  /// Porsi pemasukan terencana yang sudah terikat (0–100), atau `null`.
  final int? committedShare;

  /// Porsi bulan sebelumnya untuk pembanding, atau `null`.
  final int? previousShare;

  /// Rata-rata di luar rencana per hari (sen), atau `null` bila belum cukup riwayat.
  final int? unplannedPerDay;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final budgetRatio = plan.budgetPlanned <= 0 ? null : plan.budgetSpent / plan.budgetPlanned;
    final share = committedShare;
    final previous = previousShare;
    final low = lowest;
    final cards = <Widget>[
      if (share != null)
        _Indicator(
          label: t.plan.indLockedTitle,
          asset: ClayIcons.piggy,
          count: share,
          format: (n) => '$n%',
          caption: previous == null ? t.plan.indLockedOf : t.plan.indLockedPrev(percent: previous),
          meter: share.clamp(0, 100) / 100,
          meterTone: share > 100 ? DsMeterTone.danger : DsMeterTone.normal,
        ),
      if (budgetRatio != null)
        _Indicator(
          label: t.plan.indBudgetTitle,
          asset: ClayIcons.expenseArrow,
          count: (budgetRatio * 100).round(),
          format: (n) => '$n%',
          caption: t.home.budgetSpentOf(
            spent: AppMoneyFormatter.formatApprox(plan.budgetSpent),
            planned: AppMoneyFormatter.formatApprox(plan.budgetPlanned),
          ),
          meter: budgetRatio.clamp(0.0, 1.0),
          meterTone: budgetRatio > 1
              ? DsMeterTone.danger
              : (budgetRatio >= 0.85 ? DsMeterTone.warning : DsMeterTone.normal),
        ),
      _Indicator(
        label: t.plan.indPerDayTitle,
        asset: ClayIcons.coffee,
        count: unplannedPerDay,
        format: AppMoneyFormatter.formatApprox,
        caption: unplannedPerDay == null ? t.plan.indPerDayNone : t.plan.unplannedToggle,
        compactValue: true,
      ),
      if (low != null)
        _Indicator(
          label: t.plan.indLowTitle,
          asset: ClayIcons.warning,
          count: low.balance,
          format: (n) => '≈${AppMoneyFormatter.formatApprox(n)}',
          caption: CycleMonthFormatter.formatDayMonth(low.date),
          warn: low.balance < 0,
          compactValue: true,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            t.plan.indicatorsTitle.toUpperCase(),
            style: ds.typography.pixelCaption.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < cards.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Expanded(
                  child: DsReveal(index: i, child: cards[i]),
                ),
                if (i + 1 < cards.length)
                  Expanded(
                    child: DsReveal(index: i + 1, child: cards[i + 1]),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.label,
    required this.asset,
    required this.count,
    required this.format,
    required this.caption,
    this.meter,
    this.meterTone = DsMeterTone.normal,
    this.warn = false,
    this.compactValue = false,
  });

  final String label;
  final String asset;

  /// Nilai yang berhitung naik; `null` menampilkan strip.
  final int? count;
  final String Function(int value) format;
  final String caption;
  final double? meter;
  final DsMeterTone meterTone;
  final bool warn;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final valueStyle = ds.typography.headlineMd.copyWith(
      fontSize: compactValue ? 18 : 26,
      height: compactValue ? 26 / 18 : 32 / 26,
      fontWeight: FontWeight.w700,
      color: warn ? c.error : c.textPrimary,
    );
    return DsCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ds.typography.labelMd.copyWith(fontSize: 11, color: c.textSecondary),
                ),
              ),
              const SizedBox(width: 6),
              DsIconTile.asset(asset: asset, size: DsIconTileSize.xs),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: count == null
                ? Text('—', style: valueStyle)
                : DsCountUp(
                    value: count!,
                    builder: (context, current) => Text(format(current), style: valueStyle),
                  ),
          ),
          if (meter != null) ...[
            const SizedBox(height: 8),
            DsSegmentMeter(
              value: meter!,
              tone: meterTone,
              thin: true,
              segments: 12,
              semanticLabel: '${(meter! * 100).round()}%',
            ),
          ],
          const SizedBox(height: 6),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
