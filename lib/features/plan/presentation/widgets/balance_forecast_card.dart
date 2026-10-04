import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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
  int? _selected;

  static String _approx(int sen) => '≈${AppMoneyFormatter.format(sen)}';

  void _showDetails(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final b = widget.projection.breakdown;
        final textTheme = Theme.of(sheetContext).textTheme;
        Widget line(String label, int amount, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(label, style: textTheme.bodyMedium)),
              Text(
                amount < 0 ? '−${AppMoneyFormatter.format(-amount)}' : AppMoneyFormatter.format(amount),
                style: textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w700 : null),
              ),
            ],
          ),
        );
        final perDay = widget.projection.unplannedPerDay;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.plan.detailsTitle, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                line(t.plan.detailsNow, widget.projection.startBalance),
                line(t.plan.detailsIncome, b.income),
                line(t.plan.detailsBills, -b.recurringOut),
                line(t.plan.detailsBudget, -b.budget),
                if (perDay != null)
                  line(t.plan.detailsUnplanned(perDay: AppMoneyFormatter.format(perDay)), -b.unplanned),
                if (b.uncertain != 0) line(t.plan.detailsUncertain, b.uncertain),
                if (b.transfers != 0) line(t.plan.detailsTransfers, b.transfers),
                const Divider(),
                line(
                  t.plan.detailsEnd(date: CycleMonthFormatter.formatDayMonth(widget.lastDay)),
                  widget.projection.endBalance,
                  bold: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.plan.unplannedToggle),
                  subtitle: widget.unplannedAvailable ? null : Text(t.plan.unplannedUnavailable),
                  value: widget.unplannedAvailable && widget.includeUnplanned,
                  onChanged: widget.unplannedAvailable
                      ? (value) {
                          widget.onUnplannedToggled(value);
                          Navigator.of(sheetContext).pop();
                        }
                      : null,
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final projection = widget.projection;
    final low = projection.lowest;
    final days = projection.days;
    final selected = _selected == null || _selected! >= days.length ? null : days[_selected!];
    return CustomPaint(
      painter: _DashedBorderPainter(color: colors.edge),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.plan.balanceTitle.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
            if (widget.wallets.length > 1) ...[
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppChoiceChip(
                      label: t.plan.allWallets,
                      selected: widget.walletId == null,
                      onTap: () => widget.onWalletChanged(null),
                    ),
                    for (final wallet in widget.wallets) ...[
                      const SizedBox(width: AppSpacing.xs),
                      AppChoiceChip(
                        label: wallet.name,
                        selected: widget.walletId == wallet.id,
                        onTap: () => widget.onWalletChanged(wallet.id),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            if (widget.isFuture && days.isNotEmpty)
              _Tile(
                label: t.plan.startOf(date: CycleMonthFormatter.formatDayMonth(days.first.date)),
                amount: projection.startBalance,
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
            if (days.length > 1) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 18,
                child: selected == null
                    ? null
                    : Text(
                        t.plan.chartPoint(
                          date: CycleMonthFormatter.formatDayMonth(selected.date),
                          amount: _approx(selected.balance),
                        ),
                        style: textTheme.bodySmall,
                      ),
              ),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    void select(double dx) => setState(
                      () =>
                          _selected = (dx / constraints.maxWidth * (days.length - 1)).round().clamp(0, days.length - 1),
                    );
                    return GestureDetector(
                      onHorizontalDragStart: (d) => select(d.localPosition.dx),
                      onHorizontalDragUpdate: (d) => select(d.localPosition.dx),
                      onTapDown: (d) => select(d.localPosition.dx),
                      child: CustomPaint(
                        size: Size(constraints.maxWidth, 72),
                        painter: _ChartPainter(
                          balances: [for (final d in days) d.balance],
                          line: colors.textPrimary,
                          zero: colors.overBudget,
                          marker: colors.accent,
                          lowIndex: low == null ? null : days.indexOf(low),
                          selectedIndex: _selected,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Text(
                    widget.isFuture ? CycleMonthFormatter.formatDayMonth(days.first.date) : t.plan.todayLabel,
                    style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    CycleMonthFormatter.formatDayMonth(widget.lastDay),
                    style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => _showDetails(context), child: Text('${t.plan.detailsAction} ›')),
            ),
          ],
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final formatted = AppMoneyFormatter.format(amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
        Semantics(
          label: t.plan.approx(amount: formatted),
          excludeSemantics: true,
          child: FitStart(
            child: Text(
              '≈$formatted',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: warn ? colors.overBudget : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Garis saldo per hari, tinta netral (bukan hijau/merah); garis nol bila
/// ada saldo di bawah nol, penanda titik terendah dan titik terpilih.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.balances,
    required this.line,
    required this.zero,
    required this.marker,
    required this.lowIndex,
    required this.selectedIndex,
  });

  final List<int> balances;
  final Color line;
  final Color zero;
  final Color marker;
  final int? lowIndex;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (balances.length < 2) return;
    final minValue = [...balances, 0].reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = balances.reduce((a, b) => a > b ? a : b).toDouble();
    final span = (maxValue - minValue).abs() < 1 ? 1.0 : maxValue - minValue;
    Offset at(int i) => Offset(
      i / (balances.length - 1) * size.width,
      size.height - 4 - (balances[i] - minValue) / span * (size.height - 8),
    );
    if (minValue < 0) {
      final y = at(0).dy + (balances[0] - 0) / span * (size.height - 8);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()..color = zero.withValues(alpha: 0.5));
    }
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < balances.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    if (lowIndex case final i? when i >= 0) canvas.drawCircle(at(i), 4, Paint()..color = marker);
    if (selectedIndex case final i? when i < balances.length) {
      canvas
        ..drawLine(Offset(at(i).dx, 0), Offset(at(i).dx, size.height), Paint()..color = line.withValues(alpha: 0.3))
        ..drawCircle(at(i), 4, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.balances != balances || old.selectedIndex != selectedIndex || old.line != line;
}

/// Bingkai putus-putus untuk angka perkiraan (PLAN_TAB_LAYOUT §7.2).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
