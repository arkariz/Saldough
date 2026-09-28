import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

// Kartu-kartu Beranda, rujukan visual `pixel_kas_beranda` dan
// `pixel_kas_beranda_belum_ada_data` (ADR-015).
//
// Pembeda antarkartu (review UX Fase 6) tidak memakai warna per fitur —
// ADR-016 "satu peran, satu warna" melarangnya. Pembedanya:
// 1. Hierarki: kartu saldo memakai `AppHeroCard`, kartu utama yang sama
//    dengan puncak tab Anggaran, Transaksi, dan Dompet.
// 2. Bentuk isi sesuai sifat fiturnya: anggaran = meteran (Sisa jadi angka
//    utama), freelance = tagihan (belum diterima + potongan jatuh tempo).
// 3. Garis aksen kiri berwarna MAKNA: hijau/merah untuk arus, warna status
//    progres untuk anggaran, amber (status tertunda) untuk freelance.
// 4. Ikon kartu = ikon tujuan di navigasi bawah, di kotak 40px.
//
// Hiasan rujukan tanpa dasar produk sengaja tidak dibangun: "Status: Sinkron"
// (Saldough tidak terhubung ke mana pun), "Estimasi total" (saldo tercatat
// pasti), tombol "Intip", dan level/quest.

/// Kartu utama Beranda ([AppHeroCard]): total saldo dompet aktif
/// (FR-HOME-001) beserta strip dompetnya. Tanpa dompet sama sekali, kartu ini
/// hanya menjelaskan; ajakan membuat dompet pertama ada di
/// [HomeEmptyTransactions] (FR-HOME-005, UX-7).
class HomeBalanceCard extends StatelessWidget {
  /// Membuat [HomeBalanceCard].
  const HomeBalanceCard({
    required this.total,
    required this.activeWallets,
    required this.hasNoWallets,
    super.key,
  });

  /// Total saldo tercatat dompet aktif, sen.
  final int total;

  /// Dompet aktif, urutan simpan.
  final List<Wallet> activeWallets;

  /// Belum ada dompet sama sekali.
  final bool hasNoWallets;

  /// Dompet yang muat di strip; sisanya diringkas "+n lainnya".
  static const _stripCount = 3;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return AppHeroCard(
      tour: TourId.home,
      icon: IconKey.home,
      label: t.home.balanceLabel,
      trailing: hasNoWallets ? _Badge(t.home.startBadge, color: colors.accent) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroAmount(AppMoneyFormatter.format(total), color: total < 0 ? colors.expense : null),
          const SizedBox(height: AppSpacing.sm),
          // Tanpa dompet, satu-satunya ajakan membuat dompet ada di kartu
          // kosong di bawah (UX-7) — tidak ada tombol kedua di sini.
          if (hasNoWallets) ...[
            Text(t.home.noWalletsBody, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
          ] else ...[
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
                    child: HeroInset(
                      child: _StatText(
                        label: wallet.name,
                        value: AppMoneyFormatter.format(wallet.currentBalance),
                        uppercase: false,
                      ),
                    ),
                  ),
                ],
                if (activeWallets.length > _stripCount) ...[
                  const SizedBox(width: 6),
                  HeroInset(
                    child: Text(
                      t.home.moreWallets(count: activeWallets.length - _stripCount),
                      style: transactionLabelStyle(context, color: colors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
    return Row(
      children: [
        Expanded(
          child: _FlowTile(
            label: t.home.incomeLabel(month: monthLabel),
            sign: '+',
            amount: cashFlow.income,
            icon: IconKey.income,
            color: colors.income,
            stripe: colors.incomeFill,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _FlowTile(
            label: t.home.expenseLabel(month: monthLabel),
            sign: '−',
            amount: cashFlow.expense,
            icon: IconKey.expense,
            color: colors.expense,
            stripe: colors.expenseFill,
          ),
        ),
      ],
    );
  }
}

/// Satu label, lalu nominal bertanda. Tanda `+`/`−` sudah membawa arah uang,
/// jadi tidak ada label kedua "+ MASUK"/"− KELUAR" (UX-22).
class _FlowTile extends StatelessWidget {
  const _FlowTile({
    required this.label,
    required this.sign,
    required this.amount,
    required this.icon,
    required this.color,
    required this.stripe,
  });

  final String label;
  final String sign;
  final int amount;
  final IconKey icon;
  final Color color;
  final Color stripe;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _StripeCard(
      stripe: stripe,
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
              _IconBox(icon, color: stripe),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FitStart(
            child: Text(
              '$sign${AppMoneyFormatter.format(amount)}',
              style: PixelTypography.tabularMono(context, fontSize: 18, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan anggaran aktif sebagai **meteran** (FR-HOME-002): sisa jadi angka
/// utama, bilah segmen di bawahnya, dan persen terpakai. Garis aksen dan
/// warnanya mengikuti status progres (hijau, amber mendekati batas, merah
/// lewat rencana). Seluruh kartu membuka layar Anggaran.
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
    final status = AppSegmentedProgressBar.colorFor(context, ratio);
    final over = overview.remaining < 0;
    return _TappableCard(
      semanticsLabel: t.home.budgetAction,
      onTap: onOpen,
      child: _StripeCard(
        stripe: status,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeatureHeader(icon: IconKey.budget, title: t.home.budgetTitle),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
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
                            fontSize: 26,
                            color: over ? colors.overBudget : colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _Badge(t.home.budgetUsedBadge(percent: (ratio * 100).round()), color: status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _SegmentBar(ratio: ratio, color: status),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.home.budgetSpentOf(
                spent: AppMoneyFormatter.format(overview.spent),
                planned: AppMoneyFormatter.format(overview.plannedAmount),
              ),
              style: transactionLabelStyle(context, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan freelance sebagai **tagihan** (FR-HOME-003): nominal yang belum
/// diterima (kotor, sama dengan puncak Ikhtisar Freelance) dan potongan
/// "jatuh tempo" berisi perkiraan pembayaran terdekat, dipisah garis sobek
/// seperti struk. Jam, diperoleh, dan diterima turun jadi baris kecil. Garis
/// aksennya amber karena isinya status tertunda. Tidak ada entri worklog satu
/// per satu. Seluruh kartu membuka Ikhtisar Freelance.
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
    return _TappableCard(
      semanticsLabel: t.home.freelanceAction,
      onTap: onOpen,
      child: _StripeCard(
        stripe: colors.pending,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FeatureHeader(icon: IconKey.freelance, title: t.home.freelanceTitle),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t.home.freelanceUnpaidTitle.toUpperCase(),
                          style: transactionLabelStyle(context, color: colors.textMuted),
                        ),
                        FitStart(
                          child: Text(
                            AppMoneyFormatter.format(overview.unpaid),
                            style: PixelTypography.tabularMono(context, fontSize: 24, color: colors.pending),
                          ),
                        ),
                        Text(
                          t.home.freelancePendingInvoices(count: overview.pendingCount),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: _VerticalTear(),
                  ),
                  Expanded(
                    flex: 2,
                    child: _InsetPanel(
                      color: colors.tinted(colors.pending, 0.12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.home.freelanceDueLabel.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: transactionLabelStyle(context, color: colors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          FitStart(
                            child: Text(
                              CycleMonthFormatter.formatDateShort(overview.nextExpectedDate),
                              style: PixelTypography.tabularMono(context, fontSize: 15, color: colors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _DashedDivider(),
            Text(
              t.home.freelanceSummaryLine(
                hours: t.freelance.hoursValue(hours: overview.totalHours),
                earned: AppMoneyFormatter.format(overview.earned),
              ),
              style: transactionLabelStyle(context, color: colors.textMuted),
            ),
            const SizedBox(height: 4),
            _SplitGauge(paid: overview.paid, unpaid: overview.unpaid),
            const SizedBox(height: 4),
            Text(
              t.home.freelancePaid(amount: AppMoneyFormatter.format(overview.paid)),
              style: transactionLabelStyle(context, color: colors.income),
            ),
          ],
        ),
      ),
    );
  }
}

/// Judul bagian, mis. "Transaksi terbaru" dengan tautan "Lihat semua"
/// (FR-HOME-004).
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
        Expanded(
          child: Text(title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
        ),
        // `Flexible`, bukan langsung `?trailing` -- label mikro naik ke
        // 11px minimum (ADR-020 §3.2) butuh sedikit lebih banyak ruang;
        // tanpa ini `trailing` panjang di teks 2x meluap (ketahuan uji
        // Freelance 360px + teks 2x, yang melewati `HomeGuide`).
        if (trailing != null) Flexible(child: trailing!),
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
            decoration: BoxDecoration(color: colors.surfaceHigh, borderRadius: AppRadius.pixelSmAll),
            // Peti kosong, sama dengan ilustrasi "Inventaris kosong" rujukan.
            child: const AppIcon(IconKey.empty, size: 80),
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
          // Anggaran butuh dompet; tanpa dompet tautan ini buntu di layar
          // Anggaran "Buat dompet dulu" (UX-7).
          if (!hasNoWallets) ...[
            const SizedBox(height: AppSpacing.sm),
            _TextLink(label: t.home.budgetLink, onTap: onBudget),
          ],
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
    // Warna kotak ikon mengikuti makna ADR-016: dompet menyimpan uang (hijau),
    // anggaran hanya rencana (netral), freelance berisi status tertunda
    // (amber).
    final rules = <(IconKey, String, String, String, Color?)>[
      (IconKey.wallets, t.home.guideWalletTitle, t.home.guideWalletTag, t.home.guideWalletBody, colors.incomeFill),
      (IconKey.budget, t.home.guideBudgetTitle, t.home.guideBudgetTag, t.home.guideBudgetBody, null),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

/// Kartu keras dengan garis aksen tebal di sisi kiri berwarna [stripe] —
/// penanda fitur sekilas pandang, warnanya selalu warna MAKNA ADR-016.
class _StripeCard extends StatelessWidget {
  const _StripeCard({required this.stripe, required this.child, this.padding = const EdgeInsets.all(AppSpacing.md)});

  final Color stripe;
  final Widget child;
  final EdgeInsets padding;

  static const _stripeWidth = 6.0;

  @override
  Widget build(BuildContext context) {
    return AppHardCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppRadius.pixelSmAll,
        child: Stack(
          children: [
            Padding(
              padding: padding.copyWith(left: padding.left + _stripeWidth),
              child: child,
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: _stripeWidth,
              child: ColoredBox(color: stripe),
            ),
          ],
        ),
      ),
    );
  }
}

/// Membungkus kartu supaya seluruhnya bisa diketuk, dengan label semantik.
class _TappableCard extends StatelessWidget {
  const _TappableCard({required this.semanticsLabel, required this.onTap, required this.child});

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child),
    );
  }
}

/// Judul kartu fitur: ikon tujuan (sama dengan navigasi bawah) di kotak
/// 40px, judul, dan chevron tanda kartu bisa dibuka.
class _FeatureHeader extends StatelessWidget {
  const _FeatureHeader({required this.icon, required this.title});

  final IconKey icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        _IconBox(icon, size: 40),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        AppIcon(IconKey.chevronRight, color: colors.textMuted),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tinted(color, 0.22),
        border: Border.all(color: colors.edge),
      ),
      child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: colors.textPrimary)),
    );
  }
}

/// Kotak ikon bergaris tepi, isian tipis [color] (netral kalau `null`).
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
        color: colors.iconTile(color),
        border: Border.all(color: colors.edge),
      ),
      child: AppIcon(icon, size: size * 0.72),
    );
  }
}

/// Bidang tanpa garis tepi di dalam kartu — cukup latar tipis, supaya garis
/// hitam hanya milik kartu terluar.
class _InsetPanel extends StatelessWidget {
  const _InsetPanel({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color ?? context.appColors.surfaceLow,
        borderRadius: AppRadius.pixelSmAll,
      ),
      child: child,
    );
  }
}

/// Label kecil di atas nilai tebal.
class _StatText extends StatelessWidget {
  const _StatText({required this.label, required this.value, this.uppercase = true});

  final String label;
  final String value;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          uppercase ? label.toUpperCase() : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: transactionLabelStyle(context, color: colors.textMuted),
        ),
        FitStart(
          child: Text(
            value,
            style: PixelTypography.tabularMono(context, fontSize: 12, color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Bilah 10 segmen selebar kartu dalam bingkai — "HP bar" rujukan. Tiap
/// segmen 10%; lewat rencana memenuhi seluruh bilah.
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
        border: Border.all(color: colors.edge, width: AppBorder.pixelThick),
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
        border: Border.all(color: colors.edge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (paid > 0)
            Expanded(
              flex: paid,
              child: ColoredBox(color: colors.incomeFill),
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

/// Garis putus-putus mendatar — garis sobek struk di kartu tagihan.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: SizedBox(
        height: 2,
        width: double.infinity,
        child: CustomPaint(painter: _DashPainter(color: context.appColors.divider, vertical: false)),
      ),
    );
  }
}

/// Garis putus-putus tegak — pemisah potongan "jatuh tempo" di kartu tagihan.
class _VerticalTear extends StatelessWidget {
  const _VerticalTear();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      child: CustomPaint(painter: _DashPainter(color: context.appColors.divider, vertical: true)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.color, required this.vertical});

  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()..color = color;
    final length = vertical ? size.height : size.width;
    for (var d = 0.0; d < length; d += dash + gap) {
      final end = (d + dash).clamp(0.0, length);
      canvas.drawRect(
        vertical ? Rect.fromLTRB(0, d, size.width, end) : Rect.fromLTRB(d, 0, end, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => oldDelegate.color != color || oldDelegate.vertical != vertical;
}

/// Tautan teks kecil beraksen.
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap, this.chevron = false});

  final String label;
  final VoidCallback onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final ink = context.appColors.accent;
    // Simpul semantik sendiri: tanpa `container`, tautan di kartu kosong
    // tergabung ke label kartu dan tidak bisa diaktifkan tersendiri (UX-12).
    return Semantics(
      container: true,
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
              if (chevron) AppIcon(IconKey.chevronRight, size: 16, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}
