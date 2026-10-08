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
        color: colors.iconTile(color),
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

/// Satu baris nominal di kartu freelance: ikon, label kapital, keterangan,
/// dan nominal di kanan. Tanpa [color], latarnya permukaan netral dan
/// labelnya redup.
class FreelanceAmountLine extends StatelessWidget {
  /// Membuat [FreelanceAmountLine].
  const FreelanceAmountLine({
    required this.icon,
    required this.label,
    required this.caption,
    required this.amount,
    this.color,
    super.key,
  });

  /// Ikon.
  final IconKey icon;

  /// Label; ditampilkan kapital.
  final String label;

  /// Keterangan di bawah label.
  final String caption;

  /// Nominal, sen.
  final int amount;

  /// Warna label dan latar tipis; `null` untuk baris netral.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: color == null ? colors.surface2 : colors.tinted(color!, 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 28),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: transactionLabelStyle(context, color: color ?? colors.ink2)),
                Text(caption, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space1),
          // Nominal besar di layar sempit atau teks diperbesar mengecil,
          // bukan meluber ke kanan.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                AppMoneyFormatter.format(amount),
                style: context.numberStyles.amount.copyWith(color: colors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu satu proyek di Ikhtisar Freelance (T-5.9): ikon, nama, tarif dan
/// potongan; baris belum ditagih (jam dan nominal kotor); baris tertunda
/// dan diterima (gaji bersih) kalau ada; bilah porsi diterima / tertunda /
/// belum ditagih; dan tanggal entri terakhir. Mengetuknya membuka rincian
/// proyek.
class ProjectCard extends StatelessWidget {
  /// Membuat [ProjectCard].
  const ProjectCard({
    required this.project,
    required this.stats,
    required this.paymentStats,
    required this.onTap,
    super.key,
  });

  /// Proyek yang ditampilkan.
  final FreelanceProject project;

  /// Angka worklog proyek (kotor).
  final ProjectStats stats;

  /// Angka pembayaran proyek (bersih).
  final ProjectPaymentStats paymentStats;

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
          shadowColor: paymentStats.pendingCount > 0 ? colors.warning : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const FreelanceIconBox(IconKey.freelance, size: 48),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.name, style: textTheme.titleMedium),
                        Text(terms, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                      ],
                    ),
                  ),
                  AppIcon(IconKey.chevronRight, color: colors.ink2),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              FreelanceAmountLine(
                icon: IconKey.workCompleted,
                label: t.freelance.unbilledLabel,
                caption: stats.unbilledCount == 0
                    ? t.freelance.unbilledNone
                    : t.freelance.hoursValue(hours: stats.unbilledHours),
                amount: stats.unbilledAmount,
              ),
              if (paymentStats.pendingCount > 0) ...[
                const SizedBox(height: AppSpacing.space1),
                FreelanceAmountLine(
                  icon: IconKey.pending,
                  label: t.freelance.pendingTotalLabel,
                  caption: t.freelance.nextExpected(
                    count: paymentStats.pendingCount,
                    date: CycleMonthFormatter.formatDateShort(paymentStats.nextExpectedDate!),
                  ),
                  amount: paymentStats.pendingNet,
                  color: colors.warning,
                ),
              ],
              if (paymentStats.paidCount > 0) ...[
                const SizedBox(height: AppSpacing.space1),
                FreelanceAmountLine(
                  icon: IconKey.paid,
                  label: t.freelance.paidTotalLabel,
                  caption: t.freelance.paymentCount(count: paymentStats.paidCount),
                  amount: paymentStats.paidNet,
                  color: colors.positive,
                ),
              ],
              if (stats.earned > 0) ...[
                const SizedBox(height: AppSpacing.space2),
                FreelanceShareBar(
                  parts: [
                    (stats.paidAmount, colors.positive),
                    (stats.pendingAmount, colors.warning),
                    (stats.unbilledAmount, colors.ink2.withValues(alpha: 0.35)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.space1),
              Row(
                children: [
                  AppIcon(IconKey.calendar, size: 16, color: colors.ink2),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      switch (stats.lastEntryDate) {
                        final date? => t.freelance.lastEntryOn(date: CycleMonthFormatter.formatDateShort(date)),
                        null => t.freelance.noEntriesYet,
                      },
                      style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                    ),
                  ),
                  Text(
                    t.freelance.entryCountLabel(count: stats.entryCount),
                    style: transactionLabelStyle(context, color: colors.ink2),
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

/// Kartu bergaris putus-putus di atas daftar proyek: ajakan menambah
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
          painter: _DashedBorderPainter(color: colors.ink2),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(IconKey.add, color: colors.brand),
                const SizedBox(width: AppSpacing.space1),
                // Teks diperbesar membungkus ke baris berikutnya, bukan meluber.
                Flexible(
                  child: Text(
                    t.freelance.projectAddTitle.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: transactionLabelStyle(context, color: colors.brand),
                  ),
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
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: 6),
            decoration: BoxDecoration(
              color: colors.tinted(colors.warning, 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge.toUpperCase(), style: transactionLabelStyle(context, color: colors.warning)),
          ),
          const SizedBox(height: AppSpacing.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (sides.isNotEmpty) Opacity(opacity: 0.7, child: AppIcon(sides.first, size: 48)),
              const SizedBox(width: AppSpacing.space2),
              AppIcon(main, size: 88),
              const SizedBox(width: AppSpacing.space2),
              if (sides.length > 1) Opacity(opacity: 0.7, child: AppIcon(sides[1], size: 48)),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(title, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space1),
          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.space6),
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
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.lineStrong, width: 2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space2),
        child: Row(
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.space2),
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
      padding: const EdgeInsets.only(top: AppSpacing.space4, bottom: AppSpacing.space1),
      child: Row(
        children: [
          const AppIcon(IconKey.calendar, size: 20),
          const SizedBox(width: AppSpacing.space1),
          Expanded(child: Text(CycleMonthFormatter.format(key), style: Theme.of(context).textTheme.titleSmall)),
          const SizedBox(width: AppSpacing.space1),
          // Subtotal mengecil di layar sempit atau teks diperbesar.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${t.freelance.hoursValue(hours: hours)} · ${AppMoneyFormatter.format(amount)}',
                style: transactionLabelStyle(context, color: colors.ink2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
