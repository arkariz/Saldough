import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';
import 'package:saldough/features/freelance/presentation/widgets/net_pay_breakdown_card.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_widgets.dart';

/// Lencana kecil berwarna.
class FreelanceBadge extends StatelessWidget {
  /// Membuat [FreelanceBadge].
  const FreelanceBadge({required this.label, required this.color, super.key});

  /// Teks lencana.
  final String label;

  /// Warna tinta.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: colors.tinted(color, 0.18), borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: color)),
    );
  }
}

/// Ringkasan upah dan jam (FR-FRL-005, rujukan
/// `pixel_kas_freelance_overview_worklog`): waktu kerja, total diperoleh,
/// sudah diterima, belum diterima, dan bilah porsinya. Semuanya gaji kotor.
class FreelanceSummaryCard extends StatelessWidget {
  /// Membuat [FreelanceSummaryCard].
  const FreelanceSummaryCard({required this.summary, required this.projectCount, super.key});

  /// Ringkasan yang ditampilkan.
  final FreelanceSummary summary;

  /// Jumlah proyek.
  final int projectCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = summary.earned == 0 ? 0.0 : summary.paid / summary.earned;
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.freelance.summaryTitle.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Tile(
                    icon: IconKey.workCompleted,
                    label: t.freelance.totalHoursLabel,
                    value: t.freelance.hoursValue(hours: summary.totalHours),
                    caption: t.freelance.projectCount(count: projectCount),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Tile(
                    icon: IconKey.hourlyRate,
                    label: t.freelance.earnedLabel,
                    value: AppMoneyFormatter.format(summary.earned),
                    caption: t.freelance.earnedCaption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Tile(
                    icon: IconKey.paid,
                    label: t.freelance.paidLabel,
                    value: AppMoneyFormatter.format(summary.paid),
                    caption: t.freelance.paidCaption,
                    color: colors.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Tile(
                    icon: IconKey.pending,
                    label: t.freelance.unpaidLabel,
                    value: AppMoneyFormatter.format(summary.unpaid),
                    caption: t.freelance.unpaidCaption,
                    color: colors.pending,
                  ),
                ),
              ],
            ),
          ),
          if (summary.earned > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FreelanceShareBar(parts: [(summary.paid, colors.income), (summary.unpaid, colors.pending)]),
            const SizedBox(height: 4),
            Text(
              t.freelance.paidRatio(percent: (ratio * 100).round()),
              style: transactionLabelStyle(context, color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value, required this.caption, this.color});

  final IconKey icon;
  final String label;
  final String value;
  final String caption;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = color ?? colors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color == null ? colors.surfaceLow : colors.tinted(ink, 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(value, style: PixelTypography.tabularMono(context, fontSize: 17, color: ink)),
          ),
          Text(caption, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}

/// Kartu satu entri worklog di rincian proyek: ikon status, tanggal kerja,
/// catatan, jam × tarif, diperoleh, dan status tagihannya (FR-FRL-002).
/// Entri yang sudah ditagih terkunci ([onTap] `null`).
class WorklogEntryCard extends StatelessWidget {
  /// Membuat [WorklogEntryCard].
  const WorklogEntryCard({
    required this.entry,
    required this.payment,
    required this.walletName,
    required this.onTap,
    super.key,
  });

  /// Entri yang ditampilkan.
  final WorklogEntry entry;

  /// Pembayaran yang menagihkannya, atau `null`.
  final FreelancePayment? payment;

  /// Nama dompet tujuan pembayaran yang sudah diterima.
  final String? walletName;

  /// Membuka formulir sunting; `null` kalau entri terkunci.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final payment = this.payment;
    final (statusIcon, statusLabel, statusColor, statusDetail) = switch (payment) {
      null => (IconKey.worklog, t.freelance.statusUnbilled, colors.textMuted, null),
      FreelancePayment(isPaid: false) => (
        IconKey.pending,
        t.freelance.statusPending,
        colors.pending,
        t.freelance.expectedOn(date: CycleMonthFormatter.formatDateShort(payment.expectedDate)),
      ),
      FreelancePayment() => (
        IconKey.paid,
        t.freelance.statusPaid,
        colors.income,
        t.freelance.receivedOn(
          date: CycleMonthFormatter.formatDateShort(payment.receivedDate!),
          wallet: walletName ?? t.freelance.unknownWallet,
        ),
      ),
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: TransactionSlab(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FreelanceIconBox(statusIcon, color: payment == null ? null : statusColor, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(CycleMonthFormatter.formatDateWithWeekday(entry.date), style: textTheme.titleSmall),
                      if (entry.note case final note?) Text(note, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                FreelanceBadge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatHoursTimesRate(entry.hours, entry.hourlyRate),
                      style: PixelTypography.tabularMono(context, fontSize: 12, color: colors.textMuted),
                    ),
                  ),
                  Text(
                    AppMoneyFormatter.format(entry.earnedAmount),
                    style: PixelTypography.tabularMono(context, fontSize: 15, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
            if (statusDetail != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  AppIcon(IconKey.locked, size: 14, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(statusDetail, style: textTheme.bodySmall?.copyWith(color: statusColor)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kartu satu pembayaran: proyek, status, entri tercakup, rincian gaji,
/// tanggal, dan aksinya (FR-FRL-003/004/005).
class FreelancePaymentCard extends StatelessWidget {
  /// Membuat [FreelancePaymentCard].
  const FreelancePaymentCard({
    required this.payment,
    required this.title,
    required this.breakdown,
    required this.entryCount,
    required this.hours,
    required this.walletName,
    required this.actions,
    super.key,
  });

  /// Pembayaran yang ditampilkan.
  final FreelancePayment payment;

  /// Judul kartu, mis. rentang tanggal kerja yang ditagih.
  final String title;

  /// Rincian gajinya.
  final NetPayBreakdown breakdown;

  /// Jumlah entri tercakup.
  final int entryCount;

  /// Total jam entri tercakup.
  final int hours;

  /// Nama dompet tujuan (pembayaran yang sudah diterima).
  final String? walletName;

  /// Tombol aksi di dasar kartu.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final paid = payment.isPaid;
    return TransactionSlab(
      shadowColor: paid ? colors.income : colors.pending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FreelanceIconBox(IconKey.invoice, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    Text(
                      t.freelance.paymentEntriesSummary(count: entryCount, hours: hours),
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              FreelanceBadge(
                label: paid ? t.freelance.statusPaid : t.freelance.statusPending,
                color: paid ? colors.income : colors.pending,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NetPayBreakdownCard(breakdown: breakdown),
          const SizedBox(height: AppSpacing.sm),
          Text(
            paid
                ? t.freelance.receivedOn(
                    date: CycleMonthFormatter.formatDate(payment.receivedDate!),
                    wallet: walletName ?? t.freelance.unknownWallet,
                  )
                : t.freelance.expectedOn(date: CycleMonthFormatter.formatDate(payment.expectedDate)),
            style: textTheme.bodyMedium?.copyWith(color: paid ? colors.income : colors.pending),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
          ],
        ],
      ),
    );
  }
}
