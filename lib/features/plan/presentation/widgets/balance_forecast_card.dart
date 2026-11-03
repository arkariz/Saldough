import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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

  static String _approx(int sen) => '≈${AppMoneyFormatter.formatApprox(sen)}';

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
    final selected = _selected == null || _selected! >= days.length ? null : days[_selected!];
    final reduced = DsMotion.reduced(context);
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 20,
                  child: selected == null
                      ? null
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: c.actionPrimary.withValues(alpha: 0.10),
                              borderRadius: DsRadius.fullAll,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              child: Text(
                                t.plan.chartPoint(
                                  date: CycleMonthFormatter.formatDayMonth(selected.date),
                                  amount: _approx(selected.balance),
                                ),
                                style: ds.typography.labelMd.copyWith(fontSize: 11, color: c.actionPrimary),
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
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
                        () => _selected = (dx / constraints.maxWidth * (days.length - 1)).round().clamp(
                          0,
                          days.length - 1,
                        ),
                      );
                      // Garis tergambar dari kiri ke kanan sekali saat pertama tampil.
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: reduced ? 1 : 0, end: 1),
                        duration: const Duration(milliseconds: 1100),
                        curve: DsMotion.easeOutExpo,
                        builder: (context, progress, _) => GestureDetector(
                          onHorizontalDragStart: (d) => select(d.localPosition.dx),
                          onHorizontalDragUpdate: (d) => select(d.localPosition.dx),
                          onTapDown: (d) => select(d.localPosition.dx),
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, 120),
                            painter: _ChartPainter(
                              balances: [for (final d in days) d.balance],
                              line: c.actionPrimary,
                              zero: c.textMuted,
                              negative: c.error,
                              marker: c.textPrimary,
                              ring: c.surfaceCard,
                              lowIndex: low == null ? null : days.indexOf(low),
                              selectedIndex: _selected,
                              progress: progress,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        widget.isFuture ? CycleMonthFormatter.formatDayMonth(days.first.date) : t.plan.todayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        CycleMonthFormatter.formatDayMonth(widget.lastDay),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
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

/// Saldo per hari sebagai anak tangga: garis putus-putus karena perkiraan,
/// area tipis di atas nol (aksi) dan di bawahnya (merah), garis nol, penanda
/// bulat untuk titik terendah dan titik terpilih. [progress] (0–1) menggambar
/// dari kiri ke kanan.
class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.balances,
    required this.line,
    required this.zero,
    required this.negative,
    required this.marker,
    required this.ring,
    required this.lowIndex,
    required this.selectedIndex,
    this.progress = 1,
  });

  final List<int> balances;
  final Color line;
  final Color zero;
  final Color negative;
  final Color marker;
  final Color ring;
  final int? lowIndex;
  final int? selectedIndex;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (balances.length < 2) return;
    final minValue = [...balances, 0].reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = [...balances, 0].reduce((a, b) => a > b ? a : b).toDouble();
    final span = (maxValue - minValue).abs() < 1 ? 1.0 : maxValue - minValue;
    double x(int i) => i / (balances.length - 1) * size.width;
    double y(num value) => size.height - 6 - (value - minValue) / span * (size.height - 12);
    final zeroY = y(0);

    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, -8, size.width * progress, size.height + 8));

    // Anak tangga: datar sepanjang hari, lalu turun/naik tegak.
    final steps = Path()..moveTo(x(0), y(balances[0]));
    for (var i = 1; i < balances.length; i++) {
      steps
        ..lineTo(x(i), y(balances[i - 1]))
        ..lineTo(x(i), y(balances[i]));
    }
    final area = Path.from(steps)
      ..lineTo(x(balances.length - 1), zeroY)
      ..lineTo(x(0), zeroY)
      ..close();
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(0, 0, size.width, zeroY))
      ..drawPath(area, Paint()..color = line.withValues(alpha: 0.12))
      ..restore()
      ..save()
      ..clipRect(Rect.fromLTRB(0, zeroY, size.width, size.height))
      ..drawPath(area, Paint()..color = negative.withValues(alpha: 0.18))
      ..restore();
    if (minValue < 0) {
      canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), Paint()..color = zero);
    }

    final stroke = Paint()
      ..color = line
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final metric in steps.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, (d + 5).clamp(0, metric.length)), stroke);
      }
    }
    canvas.restore();

    void dot(int i, double radius, Color fill) {
      final center = Offset(x(i), y(balances[i]));
      canvas
        ..drawCircle(center, radius + 2.5, Paint()..color = ring)
        ..drawCircle(center, radius, Paint()..color = fill);
    }

    if (progress >= 0.98) {
      if (lowIndex case final i? when i >= 0 && i < balances.length) {
        dot(i, 4.5, balances[i] < 0 ? negative : marker);
      }
      if (selectedIndex case final i? when i < balances.length) {
        canvas.drawLine(Offset(x(i), 0), Offset(x(i), size.height), Paint()..color = zero.withValues(alpha: 0.6));
        dot(i, 5.5, line);
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.balances != balances ||
      old.selectedIndex != selectedIndex ||
      old.line != line ||
      old.ring != ring ||
      old.progress != progress;
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
