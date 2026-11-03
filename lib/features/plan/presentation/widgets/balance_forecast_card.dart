import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_balance_chart.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Kartu **Saldo dompet ≈** (PLAN_TAB_LAYOUT §4.9, §7.2): bingkai
/// putus-putus karena perkiraan, dua ubin (akhir bulan dan paling tipis),
/// grafik yang bisa digeser, dan lembar Rincian. Kata "saldo" hanya di sini.
class BalanceForecastCard extends StatefulWidget {
  /// Membuat [BalanceForecastCard].
  const BalanceForecastCard({
    required this.projection,
    required this.lastDay,
    required this.wallets,
    required this.walletId,
    required this.onWalletChanged,
    required this.unplannedAvailable,
    required this.includeUnplanned,
    required this.onUnplannedToggled,
    this.isFuture = false,
    super.key,
  });

  /// Bulan depan (ADR-036 §3.5): ubin Awal ≈ dan tanpa label "hari ini".
  final bool isFuture;

  /// Perkiraan sampai akhir bulan.
  final CashflowProjection projection;

  /// Hari terakhir bulan keuangan.
  final DateTime lastDay;

  /// Dompet aktif (chip tampil bila lebih dari satu).
  final List<Wallet> wallets;

  /// Dompet terpilih; `null` = semua.
  final String? walletId;

  /// Ganti dompet.
  final ValueChanged<String?> onWalletChanged;

  /// Riwayat sudah sebulan penuh: sakelar jajan harian bisa dinyalakan.
  final bool unplannedAvailable;

  /// Sakelar jajan harian.
  final bool includeUnplanned;

  /// Ganti sakelar.
  final ValueChanged<bool> onUnplannedToggled;

  @override
  State<BalanceForecastCard> createState() => _BalanceForecastCardState();
}

class _BalanceForecastCardState extends State<BalanceForecastCard> {
  void _showDetails(BuildContext context) => showAppSheet<void>(
    context,
    builder: (_) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final ds = sheetContext.ds;
        final c = ds.colors;
        final b = widget.projection.breakdown;
        Widget line(String label, int amount, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: ds.typography.bodyMd.copyWith(fontWeight: bold ? FontWeight.w700 : null),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount < 0 ? '−${AppMoneyFormatter.format(-amount)}' : AppMoneyFormatter.format(amount),
                style: ds.typography.amountSm.copyWith(
                  fontWeight: bold ? FontWeight.w800 : null,
                  color: amount < 0 ? c.textPrimary : (bold ? c.textPrimary : c.income),
                ),
              ),
            ],
          ),
        );
        final perDay = widget.projection.unplannedPerDay;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: DsIconTile.asset(asset: ClayIcons.chart, size: DsIconTileSize.lg),
                ),
                const SizedBox(height: 12),
                Text(
                  t.plan.detailsTitle,
                  textAlign: TextAlign.center,
                  style: ds.typography.headlineMd.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 12),
                DsCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      line(t.plan.detailsNow, widget.projection.startBalance),
                      line(t.plan.detailsIncome, b.income),
                      line(t.plan.detailsBills, -b.recurringOut),
                      line(t.plan.detailsBudget, -b.budget),
                      if (perDay != null)
                        line(t.plan.detailsUnplanned(perDay: AppMoneyFormatter.format(perDay)), -b.unplanned),
                      if (b.uncertain != 0) line(t.plan.detailsUncertain, b.uncertain),
                      if (b.transfers != 0) line(t.plan.detailsTransfers, b.transfers),
                      Divider(height: 12, color: c.outlineSubtle),
                      line(
                        t.plan.detailsEnd(date: CycleMonthFormatter.formatDayMonth(widget.lastDay)),
                        widget.projection.endBalance,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DsListCard(
                  children: [
                    MergeSemantics(
                      child: DsSettingRow(
                        leading: DsIconTile.asset(asset: ClayIcons.coffee, size: DsIconTileSize.sm),
                        title: t.plan.unplannedToggle,
                        subtitle: widget.unplannedAvailable ? null : t.plan.unplannedUnavailable,
                        trailing: Switch(
                          value: widget.unplannedAvailable && widget.includeUnplanned,
                          onChanged: widget.unplannedAvailable
                              ? (value) {
                                  widget.onUnplannedToggled(value);
                                  Navigator.of(sheetContext).pop();
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final projection = widget.projection;
    final low = projection.lowest;
    final days = projection.days;
    return CustomPaint(
      painter: _DashedBorderPainter(color: c.outline),
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceCard, borderRadius: DsRadius.lgAll),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kepala: ikon grafik clay, judul, dan pintu Rincian. Chip dompet di
              // baris sendiri: di 360dp judul dan lebih dari dua chip tidak muat.
              Row(
                children: [
                  DsIconTile.asset(asset: ClayIcons.chart, size: DsIconTileSize.sm),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.plan.balanceTitle, style: ds.typography.titleMd)),
                  SizedBox(
                    width: 104,
                    child: DsInlineAction(
                      dense: true,
                      label: '${t.plan.detailsAction} ›',
                      onPressed: () => _showDetails(context),
                    ),
                  ),
                ],
              ),
              if (widget.wallets.length > 1) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DsFilterChip(
                        label: t.plan.allWallets,
                        selected: widget.walletId == null,
                        onTap: () => widget.onWalletChanged(null),
                      ),
                      for (final wallet in widget.wallets) ...[
                        const SizedBox(width: 8),
                        DsFilterChip(
                          label: wallet.name,
                          selected: widget.walletId == wallet.id,
                          onTap: () => widget.onWalletChanged(wallet.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (widget.isFuture && days.isNotEmpty) ...[
                _Tile(
                  label: t.plan.startOf(date: CycleMonthFormatter.formatDayMonth(days.first.date)),
                  amount: projection.startBalance,
                ),
                const SizedBox(height: 8),
              ],
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Expanded(
                      child: _Tile(
                        label: t.plan.endOf(date: CycleMonthFormatter.formatDayMonth(widget.lastDay)),
                        amount: projection.endBalance,
                      ),
                    ),
                    if (low != null)
                      Expanded(
                        child: _Tile(
                          label: t.plan.lowestOn(date: CycleMonthFormatter.formatDayMonth(low.date)),
                          amount: low.balance,
                          warn: low.balance < 0,
                        ),
                      ),
                  ],
                ),
              ),
              if (days.length > 1) ...[
                const SizedBox(height: 14),
                // Legenda seperti acuan: titik aksi untuk kurva, cincin untuk terendah.
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _LegendDot(color: c.actionPrimary, label: t.plan.legendBalance),
                    if (low != null)
                      _LegendDot(
                        color: low.balance < 0 ? c.error : c.textPrimary,
                        ring: true,
                        label: t.plan.lowestOn(date: CycleMonthFormatter.formatDayMonth(low.date)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Semantics(
                  container: true,
                  label: low == null
                      ? null
                      : t.plan.chartSemantics(
                          low: AppMoneyFormatter.format(low.balance),
                          date: CycleMonthFormatter.formatDayMonth(low.date),
                          end: AppMoneyFormatter.format(projection.endBalance),
                        ),
                  excludeSemantics: true,
                  child: PlanBalanceChart(days: days, low: low, isFuture: widget.isFuture),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.amount, this.warn = false});

  final String label;
  final int amount;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final formatted = AppMoneyFormatter.formatApprox(amount);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: warn ? c.errorContainer.withValues(alpha: 0.5) : c.surfaceSunken,
        borderRadius: DsRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
            const SizedBox(height: 2),
            Semantics(
              label: t.plan.approx(amount: formatted),
              excludeSemantics: true,
              child: FitStart(
                child: Text('≈$formatted', style: ds.typography.amount.copyWith(color: warn ? c.error : c.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.ring = false});

  final Color color;
  final String label;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ring ? ds.colors.surfaceCard : color,
            border: ring ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ds.typography.labelMd.copyWith(fontSize: 11, color: ds.colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Bingkai putus-putus untuk angka perkiraan (PLAN_TAB_LAYOUT §7.2).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
