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
      child: Text(label.toUpperCase(), style: labelSmStyle(context, color: color)),
    );
  }
}

/// Ringkasan upah dan jam (FR-FRL-005, rujukan
/// `pixel_kas_freelance_overview_worklog`): waktu kerja, total diperoleh,
/// sudah diterima, belum diterima, dan bilah porsinya — semuanya gaji kotor.
/// Kalau sudah ada pembayaran, di bawahnya menyusul baris tertunda dan
/// diterima versi gaji BERSIH, dengan label "(bersih)" supaya tidak tertukar
/// dengan ubin kotor (T-5.9).
class FreelanceSummaryCard extends StatelessWidget {
  /// Membuat [FreelanceSummaryCard].
  const FreelanceSummaryCard({
    required this.summary,
    required this.projectCount,
    required this.payments,
    super.key,
  });

  /// Ringkasan yang ditampilkan.
  final FreelanceSummary summary;

  /// Angka pembayaran seluruh proyek (bersih).
  final ProjectPaymentStats payments;

  /// Jumlah proyek.
  final int projectCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = summary.earned == 0 ? 0.0 : summary.paid / summary.earned;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.freelance.summaryTitle.toUpperCase(), style: labelSmStyle(context, color: colors.ink2)),
          const SizedBox(height: AppSpacing.space2),
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
                const SizedBox(width: AppSpacing.space2),
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
          const SizedBox(height: AppSpacing.space2),
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
                    color: colors.positive,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: _Tile(
                    icon: IconKey.pending,
                    label: t.freelance.unpaidLabel,
                    value: AppMoneyFormatter.format(summary.unpaid),
                    caption: t.freelance.unpaidCaption,
                    color: colors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (summary.earned > 0) ...[
            const SizedBox(height: AppSpacing.space2),
            FreelanceShareBar(parts: [(summary.paid, colors.positive), (summary.unpaid, colors.warning)]),
            const SizedBox(height: 4),
            Text(
              t.freelance.paidRatio(percent: (ratio * 100).round()),
              style: labelSmStyle(context, color: colors.ink2),
            ),
          ],
          if (payments.pendingCount > 0) ...[
            const SizedBox(height: AppSpacing.space2),
            FreelanceAmountLine(
              icon: IconKey.pending,
              label: t.freelance.pendingTotalLabel,
              caption: t.freelance.nextExpected(
                count: payments.pendingCount,
                date: CycleMonthFormatter.formatDateShort(payments.nextExpectedDate!),
              ),
              amount: payments.pendingNet,
              color: colors.warning,
            ),
          ],
          if (payments.paidCount > 0) ...[
            const SizedBox(height: AppSpacing.space1),
            FreelanceAmountLine(
              icon: IconKey.paid,
              label: t.freelance.paidTotalLabel,
              caption: t.freelance.paymentCount(count: payments.paidCount),
              amount: payments.paidNet,
              color: colors.positive,
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
    final ink = color ?? colors.ink;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space2),
      decoration: BoxDecoration(
        color: color == null ? colors.surface2 : colors.tinted(ink, 0.12),
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
                child: Text(label.toUpperCase(), style: labelSmStyle(context, color: colors.ink2)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(value, style: context.numberStyles.amount.copyWith(color: ink)),
          ),
          Text(caption, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink2)),
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
      null => (IconKey.worklog, t.freelance.statusUnbilled, colors.ink2, null),
      FreelancePayment(isPaid: false) => (
        IconKey.pending,
        t.freelance.statusPending,
        colors.warning,
        t.freelance.expectedOn(date: CycleMonthFormatter.formatDateShort(payment.expectedDate)),
      ),
      FreelancePayment() => (
        IconKey.paid,
        t.freelance.statusPaid,
        colors.positive,
        t.freelance.receivedOn(
          date: CycleMonthFormatter.formatDateShort(payment.receivedDate!),
          wallet: walletName ?? t.freelance.unknownWallet,
        ),
      ),
    };
    return AppTappable(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.space2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FreelanceIconBox(statusIcon, color: payment == null ? null : statusColor, size: 40),
                const SizedBox(width: AppSpacing.space2),
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
            const SizedBox(height: AppSpacing.space1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: AppSpacing.space1),
              decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatHoursTimesRate(entry.hours, entry.hourlyRate),
                      style: context.numberStyles.amountSm.copyWith(color: colors.ink2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  // Nominal mengecil di layar sempit atau teks diperbesar.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        AppMoneyFormatter.format(entry.earnedAmount),
                        style: context.numberStyles.amount.copyWith(color: colors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (statusDetail != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  AppIcon(IconKey.locked, size: 14, color: colors.ink2),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FreelanceIconBox(IconKey.invoice, size: 40),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleMedium),
                    Text(
                      t.freelance.paymentEntriesSummary(count: entryCount, hours: hours),
                      style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
              FreelanceBadge(
                label: paid ? t.freelance.statusPaid : t.freelance.statusPending,
                color: paid ? colors.positive : colors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          NetPayBreakdownCard(breakdown: breakdown),
          const SizedBox(height: AppSpacing.space2),
          Text(
            paid
                ? t.freelance.receivedOn(
                    date: CycleMonthFormatter.formatDate(payment.receivedDate!),
                    wallet: walletName ?? t.freelance.unknownWallet,
                  )
                : t.freelance.expectedOn(date: CycleMonthFormatter.formatDate(payment.expectedDate)),
            style: textTheme.bodyMedium?.copyWith(color: paid ? colors.positive : colors.warning),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            Wrap(spacing: AppSpacing.space2, runSpacing: AppSpacing.space2, children: actions),
          ],
        ],
      ),
    );
  }
}
