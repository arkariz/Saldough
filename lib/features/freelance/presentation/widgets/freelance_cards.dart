import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
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

/// Lencana status Freelance, diteruskan ke [AppBadge] (nada dari [color]).
class FreelanceBadge extends StatelessWidget {
  /// Membuat [FreelanceBadge].
  const FreelanceBadge({required this.label, required this.color, super.key});

  /// Teks lencana.
  final String label;

  /// Warna tinta.
  final Color color;

  @override
  Widget build(BuildContext context) => AppBadge(label, tone: toneFromColor(context.appColors, color));
}

/// Ringkasan Freelance (prototipe `Freelance.dc.html`): "Belum diterima"
/// (gaji kotor) sebagai angka utama di atas `bg`, yang sudah diterima di
/// bawahnya, lalu satu kartu daftar: tagihan tertunda (bersih) dan jam yang
/// belum ditagih (kotor). Kerja selesai bukan uang diterima: angka utama tidak
/// pernah dijumlahkan ke saldo (aturan 6).
class FreelanceSummaryCard extends StatelessWidget {
  /// Membuat [FreelanceSummaryCard].
  const FreelanceSummaryCard({
    required this.summary,
    required this.projectCount,
    required this.payments,
    this.unbilledHours = 0,
    this.unbilledAmount = 0,
    super.key,
  });

  /// Ringkasan yang ditampilkan.
  final FreelanceSummary summary;

  /// Angka pembayaran seluruh proyek (bersih).
  final ProjectPaymentStats payments;

  /// Jumlah proyek.
  final int projectCount;

  /// Jam kerja yang belum masuk tagihan, seluruh proyek.
  final int unbilledHours;

  /// Gaji kotor jam yang belum ditagih, sen.
  final int unbilledAmount;

  @override
  Widget build(BuildContext context) {
    final unpaid = AppMoneyFormatter.format(summary.unpaid);
    return DsSummaryHero(
      label: t.freelance.unpaidLabel,
      badge: t.freelance.projectCount(count: projectCount),
      amount: summary.unpaid,
      format: AppMoneyFormatter.format,
      // Bagian yang sudah diterima dari seluruh pendapatan: bilah terisi
      // makin penuh saat tagihan dicatat diterima.
      ratio: summary.earned <= 0 ? 0 : summary.paid / summary.earned,
      asset: ClayIcons.stylus,
      semanticLabel: '${t.freelance.unpaidLabel} $unpaid',
      stats: [
        DsSummaryStat(label: t.freelance.paidLabel, value: AppMoneyFormatter.format(summary.paid)),
        DsSummaryStat(label: t.freelance.unbilledLabel, value: AppMoneyFormatter.format(unbilledAmount)),
      ],
      footer: payments.pendingCount > 0 ? _PendingGlass(payments: payments) : null,
    );
  }
}

/// Tagihan tertunda (bersih) di kaki kartu ringkasan: jumlah dan tanggal
/// terdekat, serta nominalnya.
class _PendingGlass extends StatelessWidget {
  const _PendingGlass({required this.payments});

  final ProjectPaymentStats payments;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsSummaryGlass(
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 18, color: c.onHero),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.freelance.pendingTotalLabel, style: ds.typography.bodySm.copyWith(color: c.onHeroMuted)),
                Text(
                  t.freelance.nextExpected(
                    count: payments.pendingCount,
                    date: CycleMonthFormatter.formatDayMonth(payments.nextExpectedDate!),
                  ),
                  style: ds.typography.bodySm.copyWith(fontSize: 12, color: c.onHeroMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                AppMoneyFormatter.format(payments.pendingNet),
                style: ds.typography.amount.copyWith(color: c.onHero),
              ),
            ),
          ),
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
