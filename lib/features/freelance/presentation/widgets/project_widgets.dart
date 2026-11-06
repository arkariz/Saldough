import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';

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
      borderRadius: BorderRadius.circular(4),
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

/// Satu proyek di Ikhtisar Freelance (T-5.9, rupa v2): ikon clay, nama, tarif
/// dan jam; di kanan nominal yang belum diterima, atau lencana Lunas bila
/// seluruh kerjanya sudah dibayar. Mengetuknya membuka rincian proyek. Barisnya
/// ditaruh di `DsListCard`.
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
    final ds = context.ds;
    final c = ds.colors;
    final terms = [
      '${AppMoneyFormatter.format(project.hourlyRate)}/${t.freelance.hourShort}',
      t.freelance.hoursValue(hours: stats.totalHours),
    ].join(' · ');
    final unpaid = stats.earned - stats.paidAmount;
    final trailing = unpaid > 0
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  AppMoneyFormatter.format(unpaid),
                  style: ds.typography.pixelAmount.copyWith(color: c.textPrimary),
                ),
              ),
              Text(
                t.freelance.unpaidLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ds.typography.bodySm.copyWith(fontSize: 11, color: c.textMuted),
              ),
            ],
          )
        : stats.earned > 0
        ? DsBadge(label: t.freelance.paidOffBadge, tone: DsBadgeTone.income)
        : null;
    return DsPressable(
      onPressed: onTap,
      pressedScale: 1,
      builder: (_, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: pressed ? c.surfaceHover.withValues(alpha: DsOpacity.rowPressed) : Colors.transparent,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DsIconTile.asset(asset: ClayIcons.stylus),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ds.typography.bodyMd.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    terms,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 140), child: trailing),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol bergaris putus-putus di bawah daftar proyek: ajakan menambah
/// proyek.
class AddProjectCard extends StatelessWidget {
  /// Membuat [AddProjectCard].
  const AddProjectCard({required this.onTap, this.limited = false, super.key});

  /// Membuka formulir proyek baru.
  final VoidCallback onTap;

  /// Batas proyek Gratis sudah tercapai: tombol diberi lencana Plus.
  final bool limited;

  @override
  Widget build(BuildContext context) => DsDashedButton(
    label: t.freelance.projectAddTitle,
    trailing: PlusBadge(when: () => limited),
    onPressed: onTap,
  );
}

/// Keadaan kosong freelance (rupa v2): ilustrasi clay yang hidup, judul,
/// penjelasan, dan tombol opsional. Dipakai juga oleh daftar yang kosong di
/// rincian proyek.
class FreelanceEmptyState extends StatelessWidget {
  /// Membuat [FreelanceEmptyState].
  const FreelanceEmptyState({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Judul.
  final String title;

  /// Penjelasan.
  final String body;

  /// Label tombol; tanpa tombol kalau `null`.
  final String? actionLabel;

  /// Aksi tombol.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          const DsEmptyHero(
            asset: ClayIcons.stylus,
            orbit: [ClayIcons.clock, ClayIcons.invoice, ClayIcons.coins],
            size: 112,
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: ds.typography.titleMd.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            DsButton(label: actionLabel!, icon: Icons.add_rounded, expand: true, onPressed: onAction),
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
  Widget build(BuildContext context) => DsStickyBar(
    child: Row(
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ],
    ),
  );
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
    final ds = context.ds;
    final c = ds.colors;
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.calendar_month_outlined, size: 18, color: c.actionPrimary),
          const SizedBox(width: 6),
          Expanded(child: Text(CycleMonthFormatter.format(key), style: ds.typography.titleMd.copyWith(fontSize: 15))),
          const SizedBox(width: 8),
          // Subtotal mengecil di layar sempit atau teks diperbesar.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '${t.freelance.hoursValue(hours: hours)} · ${AppMoneyFormatter.format(amount)}',
                style: ds.typography.pixelCaption.copyWith(color: c.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
