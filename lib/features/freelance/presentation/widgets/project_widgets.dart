import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';

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
                Text(label.toUpperCase(), style: labelSmStyle(context, color: color ?? colors.ink2)),
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
    final terms = [
      '${AppMoneyFormatter.format(project.hourlyRate)}/${t.freelance.hourShort}',
      t.freelance.hoursValue(hours: stats.totalHours),
    ].join(' · ');
    final unpaid = stats.earned - stats.paidAmount;
    // Baris proyek (prototipe `Freelance.dc.html`): belum diterima di kanan,
    // atau badge Lunas bila seluruh kerjanya sudah dibayar.
    return AppListRow(
      leading: const AppIconTile(IconKey.freelance),
      title: project.name,
      subtitle: terms,
      onTap: onTap,
      trailing: unpaid > 0
          ? AppMoneyText(unpaid)
          : stats.earned > 0
          ? AppBadge(t.freelance.paidOffBadge, tone: AppTone.positive, icon: IconKey.check)
          : null,
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
    return AppButton.secondary(label: t.freelance.projectAddTitle, icon: IconKey.add, expand: true, onPressed: onTap);
  }
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: 6),
            decoration: BoxDecoration(
              color: colors.tinted(colors.warning, 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(badge.toUpperCase(), style: labelSmStyle(context, color: colors.warning)),
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
                style: labelSmStyle(context, color: colors.ink2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
