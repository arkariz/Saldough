import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/net_pay_breakdown.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_format.dart';
import 'package:saldough/features/freelance/presentation/widgets/net_pay_breakdown_card.dart';

/// Lencana status Freelance: [DsBadge] dengan label kapital.
class FreelanceBadge extends StatelessWidget {
  /// Membuat [FreelanceBadge].
  const FreelanceBadge({required this.label, required this.tone, super.key});

  /// Teks lencana.
  final String label;

  /// Nada lencana.
  final DsBadgeTone tone;

  @override
  Widget build(BuildContext context) => DsBadge(label: label, tone: tone);
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

/// Kartu satu entri worklog di rincian proyek (rupa v2): ikon status, tanggal
/// kerja, catatan, jam × tarif, diperoleh, dan status tagihannya (FR-FRL-002).
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
    final ds = context.ds;
    final c = ds.colors;
    final payment = this.payment;
    final (asset, iconTone, badgeTone, statusLabel, statusColor, statusDetail) = switch (payment) {
      null => (
        ClayIcons.clipboard,
        DsIconTileTone.neutral,
        DsBadgeTone.neutral,
        t.freelance.statusUnbilled,
        c.textSecondary,
        null,
      ),
      FreelancePayment(isPaid: false) => (
        ClayIcons.hourglass,
        DsIconTileTone.warning,
        DsBadgeTone.warning,
        t.freelance.statusPending,
        c.warning,
        t.freelance.expectedOn(date: CycleMonthFormatter.formatDateShort(payment.expectedDate)),
      ),
      FreelancePayment() => (
        ClayIcons.done,
        DsIconTileTone.income,
        DsBadgeTone.income,
        t.freelance.statusPaid,
        c.income,
        t.freelance.receivedOn(
          date: CycleMonthFormatter.formatDateShort(payment.receivedDate!),
          wallet: walletName ?? t.freelance.unknownWallet,
        ),
      ),
    };
    return DsCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsIconTile.asset(asset: asset, tone: iconTone),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CycleMonthFormatter.formatDateWithWeekday(entry.date),
                      style: ds.typography.titleMd.copyWith(fontSize: 14),
                    ),
                    if (entry.note case final note?)
                      Text(note, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FreelanceBadge(label: statusLabel, tone: badgeTone),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.baseAll),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatHoursTimesRate(entry.hours, entry.hourlyRate),
                    style: ds.typography.amountSm.copyWith(color: c.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                // Nominal mengecil di layar sempit atau teks diperbesar.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      AppMoneyFormatter.format(entry.earnedAmount),
                      style: ds.typography.amount.copyWith(color: c.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (statusDetail != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: c.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(statusDetail, style: ds.typography.bodySm.copyWith(fontSize: 12, color: statusColor)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu satu pembayaran (tagihan): judul rentang kerja, status, rincian gaji,
/// tanggal, dan aksinya (FR-FRL-003/004/005). Aksi utama (Catat diterima)
/// penuh lebar di dasar kartu; aksi lain ada di [menu] pojok kanan atas.
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
    this.menu,
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

  /// Tombol aksi di dasar kartu, ditumpuk penuh lebar.
  final List<Widget> actions;

  /// Menu aksi tambahan di pojok kanan atas (mis. Ubah tanggal, Hapus).
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final paid = payment.isPaid;
    return DsCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DsIconTile.asset(asset: ClayIcons.invoice, tone: paid ? DsIconTileTone.income : DsIconTileTone.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ds.typography.titleMd.copyWith(fontSize: 14)),
                    Text(
                      t.freelance.paymentEntriesSummary(count: entryCount, hours: hours),
                      style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FreelanceBadge(
                label: paid ? t.freelance.statusPaid : t.freelance.statusPending,
                tone: paid ? DsBadgeTone.income : DsBadgeTone.warning,
              ),
              ?menu,
            ],
          ),
          const SizedBox(height: 12),
          NetPayBreakdownCard(breakdown: breakdown),
          const SizedBox(height: 10),
          Text(
            paid
                ? t.freelance.receivedOn(
                    date: CycleMonthFormatter.formatDate(payment.receivedDate!),
                    wallet: walletName ?? t.freelance.unknownWallet,
                  )
                : t.freelance.expectedOn(date: CycleMonthFormatter.formatDate(payment.expectedDate)),
            style: ds.typography.bodyMd.copyWith(color: paid ? c.income : c.warning),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final (i, action) in actions.indexed) ...[if (i > 0) const SizedBox(height: 8), action],
          ],
        ],
      ),
    );
  }
}
