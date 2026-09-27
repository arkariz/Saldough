import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

// Kartu-kartu Beranda, mengikuti rujukan visual `pixel_kas_beranda` dan
// `pixel_kas_beranda_belum_ada_data` (ADR-015): panel bergaris tepi dengan
// bayangan keras, lencana bersudut tegas, garis putus-putus, dan tombol kecil
// "Lihat … →". Hiasan rujukan yang tidak punya dasar di produk sengaja tidak
// dibangun: "Status: Sinkron" (Saldough tidak terhubung ke mana pun),
// "Estimasi total" (saldo tercatat pasti), tombol "Intip", dan level/quest.

/// Kartu total saldo dompet aktif (FR-HOME-001) beserta strip dompetnya. Tanpa
/// dompet sama sekali, kartu ini mengarahkan membuat dompet pertama
/// (FR-HOME-005).
class HomeBalanceCard extends StatelessWidget {
  /// Membuat [HomeBalanceCard].
  const HomeBalanceCard({
    required this.total,
    required this.activeWallets,
    required this.hasNoWallets,
    required this.onAddWallet,
    super.key,
  });

  /// Total saldo tercatat dompet aktif, sen.
  final int total;

  /// Dompet aktif, urutan simpan.
  final List<Wallet> activeWallets;

  /// Belum ada dompet sama sekali.
  final bool hasNoWallets;

  /// Membuka jalan membuat dompet pertama.
  final VoidCallback onAddWallet;

  /// Dompet yang muat di strip; sisanya diringkas "+n lainnya".
  static const _stripCount = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final formatted = AppMoneyFormatter.format(total);
    final sign = formatted.startsWith('−') ? '−' : '';
    final number = formatted.replaceFirst(RegExp('^−?Rp'), '');
    return AppHardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _IconBox(IconKey.walletSavings),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  t.home.balanceLabel.toUpperCase(),
                  style: transactionLabelStyle(context, size: 11, color: colors.textMuted),
                ),
              ),
              if (hasNoWallets) _Badge(t.home.startBadge, color: colors.expense),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FitStart(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${sign}Rp',
                  style: PixelTypography.tabularMono(context, fontSize: 16, color: colors.accent),
                ),
                const SizedBox(width: 4),
                Text(number, style: PixelTypography.tabularMono(context, fontSize: 32, color: colors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasNoWallets) ...[
            Row(
              children: [
                AppIcon(IconKey.empty, size: 18, color: colors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(t.home.noWalletsBody, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _Strip(
              child: Row(
                children: [
                  _IconBox(IconKey.wallets, color: colors.pending),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(t.home.addWalletPrompt, style: textTheme.bodySmall)),
                  const SizedBox(width: AppSpacing.xs),
                  _TextLink(label: t.home.addWalletAction, onTap: onAddWallet),
                ],
              ),
            ),
          ] else
            _Strip(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.home.walletCount(count: activeWallets.length).toUpperCase(),
                    style: transactionLabelStyle(context, color: colors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      for (final (index, wallet) in activeWallets.take(_stripCount).indexed) ...[
                        if (index > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _MiniTile(
                            label: wallet.name,
                            value: AppMoneyFormatter.format(wallet.currentBalance),
                          ),
                        ),
                      ],
                      if (activeWallets.length > _stripCount) ...[
                        const SizedBox(width: 6),
                        _MiniTile(
                          label: t.home.moreWallets(count: activeWallets.length - _stripCount),
                          value: '',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pemasukan dan pengeluaran bulan berjalan, dua kartu berdampingan
/// (FR-HOME-001). Transfer sudah dikecualikan di [cashFlow].
class HomeCashFlowRow extends StatelessWidget {
  /// Membuat [HomeCashFlowRow].
  const HomeCashFlowRow({required this.cashFlow, required this.month, super.key});

  /// Arus bulan berjalan.
  final CashFlow cashFlow;

  /// Bulan berjalan.
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final monthLabel = CycleMonthFormatter.formatMonthShort(month);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FlowTile(
              label: t.home.incomeLabel(month: monthLabel),
              tag: t.home.incomeTag,
              amount: cashFlow.income,
              icon: IconKey.income,
              color: colors.income,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _FlowTile(
              label: t.home.expenseLabel(month: monthLabel),
              tag: t.home.expenseTag,
              amount: cashFlow.expense,
              icon: IconKey.expense,
              color: colors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({
    required this.label,
    required this.tag,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String tag;
  final int amount;
  final IconKey icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppHardCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
              ),
              const SizedBox(width: AppSpacing.xs),
              _IconBox(icon, color: color),
            ],
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.sm),
          Text(tag.toUpperCase(), style: transactionLabelStyle(context, color: color)),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(amount),
              style: PixelTypography.tabularMono(context, fontSize: 18, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan anggaran aktif (FR-HOME-002): persen terpakai, bilah bersegmen,
/// terpakai dari rencana, sisa, dan jalan ke layar Anggaran.
class HomeBudgetCard extends StatelessWidget {
  /// Membuat [HomeBudgetCard].
  const HomeBudgetCard({required this.overview, required this.onOpen, super.key});

  /// Ringkasan anggaran aktif.
  final BudgetOverview overview;

  /// Membuka layar Anggaran.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ratio = overview.plannedAmount <= 0 ? 0.0 : overview.spent / overview.plannedAmount;
    final percent = (ratio * 100).round();
    final barColor = AppSegmentedProgressBar.colorFor(context, ratio);
    final over = overview.remaining < 0;
    return AppHardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            icon: IconKey.budget,
            title: t.home.budgetTitle,
            badge: _Badge(t.home.budgetUsedBadge(percent: percent), color: barColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SegmentBar(ratio: ratio, color: barColor),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.home.budgetSpent(amount: AppMoneyFormatter.format(overview.spent)),
                  style: transactionLabelStyle(context, color: colors.textMuted),
                ),
              ),
              Flexible(
                child: Text(
                  t.home.budgetPlanned(amount: AppMoneyFormatter.format(overview.plannedAmount)),
                  textAlign: TextAlign.end,
                  style: transactionLabelStyle(context, color: colors.textMuted),
                ),
              ),
            ],
          ),
          const _DashedDivider(),
          _Footer(
            leading: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (over ? t.home.budgetOver : t.home.budgetRemaining).toUpperCase(),
                  style: transactionLabelStyle(context, color: colors.textMuted),
                ),
                FitStart(
                  child: Text(
                    AppMoneyFormatter.format(overview.remaining),
                    style: PixelTypography.tabularMono(
                      context,
                      fontSize: 18,
                      color: over ? colors.overBudget : colors.income,
                    ),
                  ),
                ),
              ],
            ),
            action: _HardLinkButton(label: t.home.budgetAction, onTap: onOpen),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan freelance (FR-HOME-003): jam, diperoleh, diterima dan belum
/// diterima — semuanya gaji KOTOR, sama dengan puncak Ikhtisar Freelance —
/// perkiraan pembayaran terdekat, dan satu jalan ke Ikhtisar. Tidak ada entri
/// worklog satu per satu.
class HomeFreelanceCard extends StatelessWidget {
  /// Membuat [HomeFreelanceCard].
  const HomeFreelanceCard({required this.overview, required this.onOpen, super.key});

  /// Ringkasan freelance.
  final FreelanceOverview overview;

  /// Membuka Ikhtisar Freelance.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppHardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            icon: IconKey.worklog,
            title: t.home.freelanceTitle,
            badge: _Badge(t.home.freelancePendingBadge(count: overview.pendingCount), color: colors.pending),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Strip(
            child: Row(
              children: [
                Expanded(
                  child: _StatText(
                    label: t.home.freelanceHours,
                    value: t.freelance.hoursValue(hours: overview.totalHours),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatText(
                    label: t.home.freelanceEarned,
                    value: AppMoneyFormatter.format(overview.earned),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.sm,
            runSpacing: 2,
            children: [
              Text(
                t.home.freelancePaid(amount: AppMoneyFormatter.format(overview.paid)),
                style: transactionLabelStyle(context, color: colors.income),
              ),
              Text(
                t.home.freelanceUnpaid(amount: AppMoneyFormatter.format(overview.unpaid)),
                style: transactionLabelStyle(context, color: colors.pending),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _SplitGauge(paid: overview.paid, unpaid: overview.unpaid),
          const _DashedDivider(),
          _Footer(
            leading: Row(
              children: [
                const AppIcon(IconKey.calendar, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    t.home.freelanceNext(date: CycleMonthFormatter.formatDateShort(overview.nextExpectedDate)),
                    style: transactionLabelStyle(context, color: colors.textMuted),
                  ),
                ),
              ],
            ),
            action: _HardLinkButton(label: t.home.freelanceAction, onTap: onOpen),
          ),
        ],
      ),
    );
  }
}

/// Judul bagian "Transaksi terbaru" dengan tautan "Lihat semua" (FR-HOME-004).
class HomeSectionHeader extends StatelessWidget {
  /// Membuat [HomeSectionHeader].
  const HomeSectionHeader({required this.icon, required this.title, this.trailing, super.key});

  /// Ikon judul.
  final IconKey icon;

  /// Judul.
  final String title;

  /// Isi kanan, mis. tautan atau keterangan.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 22),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        ?trailing,
      ],
    );
  }
}

/// Tautan teks kecil beraksen dengan panah, mis. "Lihat semua ›".
class HomeTextLink extends StatelessWidget {
  /// Membuat [HomeTextLink].
  const HomeTextLink({required this.label, required this.onTap, super.key});

  /// Teks tautan.
  final String label;

  /// Aksi.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _TextLink(label: label, onTap: onTap, chevron: true);
}

/// Keadaan kosong Beranda (FR-HOME-005): "Belum ada transaksi" dengan ajakan
/// yang membuka alur CATAT yang sama — atau, tanpa dompet sama sekali,
/// ajakan membuat dompet pertama lebih dulu.
class HomeEmptyTransactions extends StatelessWidget {
  /// Membuat [HomeEmptyTransactions].
  const HomeEmptyTransactions({
    required this.hasNoWallets,
    required this.onRecord,
    required this.onAddWallet,
    required this.onBudget,
    super.key,
  });

  /// Belum ada dompet sama sekali.
  final bool hasNoWallets;

  /// Membuka alur CATAT.
  final VoidCallback onRecord;

  /// Membuka jalan membuat dompet pertama.
  final VoidCallback onAddWallet;

  /// Membuka layar Anggaran.
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return AppHardCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 112,
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: colors.tinted(colors.accent, 0.2), offset: const Offset(4, -4))],
            ),
            child: const AppIcon(IconKey.transactions, size: 80),
          ),
          const SizedBox(height: AppSpacing.md),
          _Badge(t.home.emptyBadge, color: colors.textMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(t.home.emptyTitle, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasNoWallets ? t.home.emptyNoWalletBody : t.home.emptyBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: hasNoWallets
                ? AppButton(label: t.home.createWalletAction, onPressed: onAddWallet)
                : AppButton(label: t.home.recordAction, onPressed: onRecord),
          ),
          const SizedBox(height: AppSpacing.sm),
          _TextLink(label: t.home.budgetLink, onTap: onBudget, color: colors.expense),
        ],
      ),
    );
  }
}

/// Panduan singkat tiga aturan utama di keadaan kosong Beranda.
class HomeGuide extends StatelessWidget {
  /// Membuat [HomeGuide].
  const HomeGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rules = [
      (IconKey.wallets, t.home.guideWalletTitle, t.home.guideWalletTag, t.home.guideWalletBody, colors.income),
      (IconKey.budget, t.home.guideBudgetTitle, t.home.guideBudgetTag, t.home.guideBudgetBody, colors.expense),
      (
        IconKey.freelance,
        t.home.guideFreelanceTitle,
        t.home.guideFreelanceTag,
        t.home.guideFreelanceBody,
        colors.pending,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          icon: IconKey.worklog,
          title: t.home.guideTitle,
          trailing: Text(
            t.home.guideCount.toUpperCase(),
            style: transactionLabelStyle(context, color: colors.textMuted),
          ),
        ),
        for (final (index, (icon, title, tag, body, color)) in rules.indexed) ...[
          const SizedBox(height: AppSpacing.sm),
          TransactionSlab(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconBox(icon, color: color, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${(index + 1).toString().padLeft(2, '0')}. $title',
                            style: PixelTypography.tabularMono(context, fontSize: 13, color: colors.textPrimary),
                          ),
                          _Badge(tag, color: colors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(body, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Judul kartu: ikon, judul, dan lencana di kanan.
class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.icon, required this.title, required this.badge});

  final IconKey icon;
  final String title;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 22),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        const SizedBox(width: AppSpacing.xs),
        badge,
      ],
    );
  }
}

/// Lencana bersudut tegas bergaris tepi tipis, isian tipis [color].
class _Badge extends StatelessWidget {
  const _Badge(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tinted(color, 0.18),
        border: Border.all(color: colors.textPrimary),
      ),
      child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textPrimary)),
    );
  }
}

/// Kotak ikon kecil bergaris tepi, isian tipis [color].
class _IconBox extends StatelessWidget {
  const _IconBox(this.icon, {this.color, this.size = 24});

  final IconKey icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color == null ? colors.surfaceMid : colors.tinted(color!, 0.22),
        border: Border.all(color: colors.textPrimary),
      ),
      child: AppIcon(icon, size: size * 0.75),
    );
  }
}

/// Strip bergaris tepi tipis berlatar permukaan rendah di dalam kartu.
class _Strip extends StatelessWidget {
  const _Strip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        border: Border.all(color: colors.textPrimary),
      ),
      child: child,
    );
  }
}

/// Ubin kecil satu dompet di strip kartu saldo.
class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        border: Border.all(color: colors.textPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: transactionLabelStyle(context, color: colors.textMuted),
          ),
          if (value.isNotEmpty)
            FitStart(
              child: Text(value, style: PixelTypography.tabularMono(context, fontSize: 12, color: colors.textPrimary)),
            ),
        ],
      ),
    );
  }
}

/// Label kecil redup di atas nilai tebal.
class _StatText extends StatelessWidget {
  const _StatText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textMuted)),
        FitStart(
          child: Text(value, style: PixelTypography.tabularMono(context, color: colors.textPrimary)),
        ),
      ],
    );
  }
}

/// Bilah 10 segmen selebar kartu dalam bingkai bergaris tepi — "HP bar"
/// rujukan. Tiap segmen 10%; lewat rencana memenuhi seluruh bilah.
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.ratio, required this.color});

  final double ratio;
  final Color color;

  static const _segments = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filled = (ratio.clamp(0.0, 1.0) * _segments).round();
    return Container(
      height: 20,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        border: Border.all(color: colors.textPrimary, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _segments; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(child: ColoredBox(color: i < filled ? color : colors.surfaceMid)),
          ],
        ],
      ),
    );
  }
}

/// Bilah dua bagian diterima / belum diterima, lebarnya sesuai nominal.
class _SplitGauge extends StatelessWidget {
  const _SplitGauge({required this.paid, required this.unpaid});

  final int paid;
  final int unpaid;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        border: Border.all(color: colors.textPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paid > 0)
            Expanded(
              flex: paid,
              child: ColoredBox(color: colors.income),
            ),
          if (unpaid > 0)
            Expanded(
              flex: unpaid,
              child: ColoredBox(color: colors.tinted(colors.pending, 0.6)),
            ),
        ],
      ),
    );
  }
}

/// Garis putus-putus pemisah kaki kartu.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.divider;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dash = 6.0;
          const gap = 4.0;
          final count = (constraints.maxWidth / (dash + gap)).floor();
          return Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(
                  width: dash,
                  height: 2,
                  child: ColoredBox(color: color),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Kaki kartu: isi di kiri, tombol di kanan.
class _Footer extends StatelessWidget {
  const _Footer({required this.leading, required this.action});

  final Widget leading;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: leading),
        const SizedBox(width: AppSpacing.sm),
        // Tombol boleh menyempit (labelnya membungkus) di layar sempit atau
        // teks diperbesar, alih-alih meluber.
        Flexible(child: action),
      ],
    );
  }
}

/// Tombol kecil bergaris tepi berbayangan keras dengan panah, mis.
/// "Lihat Anggaran →". Ditekan menggeser isi dan menghapus bayangannya.
class _HardLinkButton extends StatefulWidget {
  const _HardLinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HardLinkButton> createState() => _HardLinkButtonState();
}

class _HardLinkButtonState extends State<_HardLinkButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          transform: Matrix4.translationValues(_pressed ? 2 : 0, _pressed ? 2 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surfaceLow,
            border: Border.all(color: colors.textPrimary),
            boxShadow: [if (!_pressed) BoxShadow(color: colors.textPrimary, offset: const Offset(2, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  style: PixelTypography.tabularMono(context, fontSize: 12, color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 14, color: colors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tautan teks kecil tebal.
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap, this.chevron = false, this.color});

  final String label;
  final VoidCallback onTap;
  final bool chevron;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.appColors.accent;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(label, style: PixelTypography.tabularMono(context, fontSize: 12, color: ink)),
              ),
              if (chevron) Icon(Icons.chevron_right, size: 16, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}
