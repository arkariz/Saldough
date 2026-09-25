import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';

/// Kotak ikon pixel berlatar tipis, dipakai di kartu dan judul freelance.
class FreelanceIconBox extends StatelessWidget {
  /// Membuat [FreelanceIconBox].
  const FreelanceIconBox(this.icon, {this.color, this.size = 44, super.key});

  /// Ikon.
  final IconKey icon;

  /// Warna latar tipis; bawaan permukaan netral.
  final Color? color;

  /// Sisi kotak.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color == null ? colors.surfaceMid : colors.tinted(color!, 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppIcon(icon, size: size * 0.7),
    );
  }
}

/// Bilah porsi horizontal: tiap bagian selebar nominalnya.
class FreelanceShareBar extends StatelessWidget {
  /// Membuat [FreelanceShareBar].
  const FreelanceShareBar({required this.parts, this.height = 8, super.key});

  /// Nominal dan warna tiap bagian; nominal nol dilewati.
  final List<(int, Color)> parts;

  /// Tinggi bilah.
  final double height;

  @override
  Widget build(BuildContext context) {
    final visible = parts.where((p) => p.$1 > 0).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: height,
        child: Row(
          // `stretch`: ColoredBox tanpa anak setinggi nol kalau tinggi Row
          // tidak dipaksakan ke anak-anaknya.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (amount, color) in visible)
              Expanded(
                flex: amount,
                child: ColoredBox(color: color),
              ),
          ],
        ),
      ),
    );
  }
}

/// Kartu satu proyek di tab Worklog: ikon, nama, tarif dan potongan, angka
/// belum ditagih, bilah porsi (belum ditagih / tertunda / diterima), dan
/// tanggal entri terakhir. Mengetuknya membuka rincian proyek.
class ProjectCard extends StatelessWidget {
  /// Membuat [ProjectCard].
  const ProjectCard({required this.project, required this.stats, required this.onTap, super.key});

  /// Proyek yang ditampilkan.
  final FreelanceProject project;

  /// Angka proyek.
  final ProjectStats stats;

  /// Membuka rincian proyek.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final terms = [
      '${AppMoneyFormatter.format(project.hourlyRate)}/${t.freelance.hourShort}',
      for (final rule in project.deductionRules) describeDeduction(rule),
    ].join(' · ');
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: TransactionSlab(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const FreelanceIconBox(IconKey.freelance, size: 48),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: textTheme.titleMedium),
                        Text(terms, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                      ],
                    ),
                  ),
                  AppIcon(IconKey.chevronRight, color: colors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    const AppIcon(IconKey.workCompleted, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.freelance.unbilledLabel.toUpperCase(),
                            style: transactionLabelStyle(context, color: colors.textMuted),
                          ),
                          Text(
                            stats.unbilledCount == 0
                                ? t.freelance.unbilledNone
                                : t.freelance.hoursValue(hours: stats.unbilledHours),
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppMoneyFormatter.format(stats.unbilledAmount),
                      style: PixelTypography.tabularMono(context, fontSize: 16, color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              if (stats.earned > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                FreelanceShareBar(
                  parts: [
                    (stats.paidAmount, colors.income),
                    (stats.pendingAmount, colors.pending),
                    (stats.unbilledAmount, colors.textMuted.withValues(alpha: 0.35)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  AppIcon(IconKey.calendar, size: 16, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      switch (stats.lastEntryDate) {
                        final date? => t.freelance.lastEntryOn(date: CycleMonthFormatter.formatDateShort(date)),
                        null => t.freelance.noEntriesYet,
                      },
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ),
                  Text(
                    t.freelance.entryCountLabel(count: stats.entryCount),
                    style: transactionLabelStyle(context, color: colors.textMuted),
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

/// Kartu satu proyek di tab Pembayaran: ikon tagihan, nama, lalu tagihan
/// tertunda (gaji bersih, jumlah, perkiraan terdekat) dan yang sudah
/// diterima. Mengetuknya membuka tab Pembayaran di rincian proyek.
class ProjectPaymentCard extends StatelessWidget {
  /// Membuat [ProjectPaymentCard].
  const ProjectPaymentCard({required this.project, required this.stats, required this.onTap, super.key});

  /// Proyek yang ditampilkan.
  final FreelanceProject project;

  /// Angka pembayaran proyek.
  final ProjectPaymentStats stats;

  /// Membuka rincian proyek di tab Pembayaran.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    Widget line(IconKey icon, String label, int amount, String caption, Color color) => Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: colors.tinted(color, 0.1), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          AppIcon(icon, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: transactionLabelStyle(context, color: color)),
                Text(caption, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              ],
            ),
          ),
          Text(
            AppMoneyFormatter.format(amount),
            style: PixelTypography.tabularMono(context, fontSize: 15, color: colors.textPrimary),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: TransactionSlab(
          shadowColor: stats.pendingCount > 0 ? colors.pending : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const FreelanceIconBox(IconKey.invoice, size: 48),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(project.name, style: textTheme.titleMedium)),
                  AppIcon(IconKey.chevronRight, color: colors.textMuted),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (stats.isEmpty)
                Text(t.freelance.projectPaymentsNone, style: textTheme.bodyMedium?.copyWith(color: colors.textMuted))
              else ...[
                line(
                  IconKey.pending,
                  t.freelance.statusPending,
                  stats.pendingNet,
                  switch (stats.nextExpectedDate) {
                    final date? => t.freelance.nextExpected(
                      count: stats.pendingCount,
                      date: CycleMonthFormatter.formatDateShort(date),
                    ),
                    null => t.freelance.pendingNone,
                  },
                  colors.pending,
                ),
                const SizedBox(height: AppSpacing.xs),
                line(
                  IconKey.paid,
                  t.freelance.statusPaid,
                  stats.paidNet,
                  t.freelance.paymentCount(count: stats.paidCount),
                  colors.income,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu bergaris putus-putus di akhir daftar proyek: ajakan menambah
/// proyek.
class AddProjectCard extends StatelessWidget {
  /// Membuat [AddProjectCard].
  const AddProjectCard({required this.onTap, super.key});

  /// Membuka formulir proyek baru.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: colors.textMuted),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(IconKey.add, color: colors.accent),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  t.freelance.projectAddTitle.toUpperCase(),
                  style: transactionLabelStyle(context, size: 12, color: colors.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    void line(Offset from, Offset to) {
      final length = (to - from).distance;
      final direction = (to - from) / length;
      for (var d = 0.0; d < length; d += dash + gap) {
        final end = d + dash > length ? length : d + dash;
        canvas.drawLine(from + direction * d, from + direction * end, paint);
      }
    }

    final r = Offset.zero & size;
    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}

/// Ilustrasi keadaan kosong freelance: susunan ikon pixel besar dengan
/// lencana, judul, penjelasan, dan tombol opsional (pola `BudgetEmptyState`).
class FreelanceEmptyState extends StatelessWidget {
  /// Membuat [FreelanceEmptyState].
  const FreelanceEmptyState({
    required this.badge,
    required this.title,
    required this.body,
    required this.icons,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Teks lencana di atas ilustrasi.
  final String badge;

  /// Judul.
  final String title;

  /// Penjelasan.
  final String body;

  /// Ikon ilustrasi: yang pertama besar di tengah, sisanya mengapit kecil.
  final List<IconKey> icons;

  /// Label tombol; tanpa tombol kalau `null`.
  final String? actionLabel;

  /// Aksi tombol.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final [main, ...sides] = icons;
    return TransactionSlab(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: colors.tinted(colors.pending, 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge.toUpperCase(), style: transactionLabelStyle(context, size: 12, color: colors.pending)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (sides.isNotEmpty) Opacity(opacity: 0.7, child: AppIcon(sides.first, size: 48)),
              const SizedBox(width: AppSpacing.sm),
              AppIcon(main, size: 88),
              const SizedBox(width: AppSpacing.sm),
              if (sides.length > 1) Opacity(opacity: 0.7, child: AppIcon(sides[1], size: 48)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bilah aksi yang menempel di dasar layar freelance, tidak ikut digulir.
class FreelanceBottomBar extends StatelessWidget {
  /// Membuat [FreelanceBottomBar].
  const FreelanceBottomBar({required this.children, super.key});

  /// Tombol-tombolnya, dibagi rata selebar layar.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border(top: BorderSide(color: colors.edge, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
        child: Row(
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: child),
            ],
          ],
        ),
      ),
    );
  }
}

/// Judul kelompok bulan di daftar entri: ikon kalender, nama bulan, dan
/// subtotal jam serta nominal bulan itu.
class WorklogMonthHeader extends StatelessWidget {
  /// Membuat [WorklogMonthHeader].
  const WorklogMonthHeader({required this.month, required this.hours, required this.amount, super.key});

  /// Bulan (tahun dan bulannya saja yang dipakai).
  final DateTime month;

  /// Subtotal jam.
  final int hours;

  /// Subtotal nominal, sen.
  final int amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          const AppIcon(IconKey.calendar, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(CycleMonthFormatter.format(key), style: Theme.of(context).textTheme.titleSmall)),
          Text(
            '${t.freelance.hoursValue(hours: hours)} · ${AppMoneyFormatter.format(amount)}',
            style: transactionLabelStyle(context, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
