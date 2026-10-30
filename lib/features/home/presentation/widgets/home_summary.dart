import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kartu saldo Beranda (acuan `home-clay.html`, kartu hero): total saldo
/// dompet aktif (FR-HOME-001) di kartu hijau yang menghitung naik saat
/// dibuka, dengan pemasukan dan pengeluaran periode, serta tombol Catat
/// dan Dompet. Menyembunyikan nominal memutar saldo (`DsFlipSwitcher`).
/// Tanpa dompet, ajakan membuat dompet pertama ada di bawah (FR-HOME-005).
class HomeBalanceCard extends StatelessWidget {
  /// Membuat [HomeBalanceCard].
  const HomeBalanceCard({
    required this.total,
    required this.walletCount,
    required this.onShowWallets,
    required this.onRecord,
    this.cashFlow,
    super.key,
  });

  /// Total saldo tercatat dompet aktif, sen.
  final int total;

  /// Jumlah dompet aktif.
  final int walletCount;

  /// Membuka tab Dompet.
  final VoidCallback onShowWallets;

  /// Membuka alur CATAT.
  final VoidCallback onRecord;

  /// Arus periode berjalan; `null` menyembunyikan kotak Masuk/Keluar.
  final CashFlow? cashFlow;

  @override
  Widget build(BuildContext context) {
    final flow = cashFlow;
    final symbol = ActiveCurrency.value.symbol;
    return DsCountUp(
      value: total,
      builder: (context, shown) => DsHeroBalanceCard(
        label: t.home.balanceLabel.toUpperCase(),
        labelIcon: Icons.spa_outlined,
        currencySymbol: symbol,
        // Nominal tanpa penyamaran; `hidden` menggantikannya oleh topeng.
        amount: AppMoneyFormatter.formatRevealed(shown).replaceFirst(symbol, ''),
        hidden: AmountVisibility.hidden,
        toggleLabel: AmountVisibility.hidden ? t.home.showAmounts : t.home.hideAmounts,
        onToggleHidden: AmountVisibility.toggle,
        caption: walletCount == 0 ? null : t.home.walletLink(count: walletCount),
        stats: flow == null
            ? const []
            : [
                DsHeroStatTile(
                  icon: Icons.arrow_downward,
                  label: t.home.incomeStat.toUpperCase(),
                  value: AppMoneyText.format(flow.income, MoneyKind.income),
                ),
                DsHeroStatTile(
                  icon: Icons.arrow_upward,
                  label: t.home.expenseStat.toUpperCase(),
                  value: AppMoneyText.format(flow.expense, MoneyKind.expense),
                  income: false,
                ),
              ],
        actions: [
          DsButton.onHero(label: t.appShell.recordAction, icon: Icons.add_circle_outline, onPressed: onRecord),
          if (walletCount > 0)
            DsButton.onHeroTonal(
              label: t.appShell.walletsTabLabel,
              icon: Icons.account_balance_wallet_outlined,
              onPressed: onShowWallets,
            ),
        ],
      ),
    );
  }
}

/// Bulan berjalan di Beranda: pemasukan dan pengeluaran berdampingan, lalu
/// selisihnya di bawah garis. Transfer sudah dikecualikan di [cashFlow]
/// (FR-HOME-001).
class HomeMonthCard extends StatelessWidget {
  /// Membuat [HomeMonthCard].
  const HomeMonthCard({required this.cashFlow, this.footer, this.onOpenAnalysis, this.analysisLabel, super.key});

  /// Arus bulan berjalan.
  final CashFlow cashFlow;

  /// Isi tambahan di bawah selisih (perkiraan saldo akhir bulan, T-15.13).
  final Widget? footer;

  /// Membuka Analisis periode ini (D4): pasangan Pemasukan/Pengeluaran jadi
  /// pintu bertanda panah. `null` = bukan pintu.
  final VoidCallback? onOpenAnalysis;

  /// Label pembaca layar pintu, mis. "Analisis Oktober: …".
  final String? analysisLabel;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    Widget stat(String label, int sen, MoneyKind kind, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
        FitStart(
          child: Text(AppMoneyText.format(sen, kind), style: ds.typography.amount.copyWith(color: color)),
        ),
      ],
    );
    final net = cashFlow.income - cashFlow.expense;
    final pair = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: stat(t.home.incomeStat, cashFlow.income, MoneyKind.income, c.income)),
        const SizedBox(width: DsSpacing.md - 4),
        Expanded(child: stat(t.home.expenseStat, cashFlow.expense, MoneyKind.expense, c.textPrimary)),
      ],
    );
    final open = onOpenAnalysis;
    return DsCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (open == null)
            Padding(padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.md, DsSpacing.md, 0), child: pair)
          else
            // Pintu: bagian atas kartu membuka Analisis, sisanya tetap
            // tautannya sendiri.
            Semantics(
              button: true,
              label: analysisLabel,
              excludeSemantics: analysisLabel != null,
              child: InkWell(
                key: const ValueKey('home-analysis-door'),
                onTap: open,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.md, DsSpacing.sm + 4, 0),
                  child: Row(
                    children: [
                      Expanded(child: pair),
                      const SizedBox(width: DsSpacing.sm),
                      Icon(Icons.chevron_right, size: 20, color: c.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: DsSpacing.md - 4),
          const Divider(indent: DsSpacing.md, endIndent: DsSpacing.md),
          Padding(
            padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.md - 4, DsSpacing.md, DsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(t.home.flowNet, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                    ),
                    const SizedBox(width: DsSpacing.sm),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          AppMoneyText.format(net, MoneyKind.balance),
                          style: ds.typography.amountSm.copyWith(color: c.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
                if (footer != null) ...[const SizedBox(height: DsSpacing.sm), footer!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan anggaran aktif (FR-HOME-002) sebagai kartu yang membuka tab
/// Rencana: badge status, terpakai dari rencana, sisa, dan meter tersegmen.
/// Status: Aman di bawah 85%, Hampir habis 85–100%, Lewat menyebut
/// selisihnya. Meter bernapas hanya saat hampir habis atau lewat.
class HomeBudgetCard extends StatelessWidget {
  /// Membuat [HomeBudgetCard].
  const HomeBudgetCard({required this.overview, required this.onOpen, super.key});

  /// Ringkasan anggaran aktif.
  final BudgetOverview overview;

  /// Membuka tab Rencana pada segmen Anggaran.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ratio = overview.plannedAmount <= 0 ? 0.0 : overview.spent / overview.plannedAmount;
    final status = AppProgressBar.statusFor(ratio);
    final (badge, tone, meterTone) = switch (status) {
      AppBarStatus.safe => (t.home.budgetSafe, DsBadgeTone.income, DsMeterTone.normal),
      AppBarStatus.nearlyOut => (t.home.budgetNearlyOut, DsBadgeTone.warning, DsMeterTone.warning),
      AppBarStatus.over => (
        t.home.budgetOverBy(amount: AppMoneyFormatter.format(-overview.remaining)),
        DsBadgeTone.danger,
        DsMeterTone.danger,
      ),
    };
    final spentOf = t.home.budgetSpentOf(
      spent: AppMoneyFormatter.format(overview.spent),
      planned: AppMoneyFormatter.format(overview.plannedAmount),
    );
    return Semantics(
      container: true,
      label: t.home.budgetAction,
      child: DsBudgetMeterCard(
        title: t.home.budgetTitle,
        icon: Icons.hourglass_top,
        badge: DsBadge(label: badge.toUpperCase(), tone: tone),
        spent: AppMoneyFormatter.format(overview.spent),
        total: AppMoneyFormatter.format(overview.plannedAmount),
        remaining: '${t.home.budgetRemaining} ${AppMoneyText.format(overview.remaining, MoneyKind.remaining)}',
        value: ratio,
        meterLabel: spentOf,
        tone: meterTone,
        breathing: status != AppBarStatus.safe,
        onTap: onOpen,
      ),
    );
  }
}

/// Pintu masuk Freelance di Beranda (ADR-034 §4): satu baris "Belum
/// diterima" dengan jumlah tagihan dan perkiraan terdekat (FR-HOME-003).
class HomeFreelanceCard extends StatelessWidget {
  /// Membuat [HomeFreelanceCard].
  const HomeFreelanceCard({required this.overview, required this.onOpen, super.key});

  /// Ringkasan freelance.
  final FreelanceOverview overview;

  /// Membuka Ikhtisar Freelance.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: t.home.freelanceAction,
      child: DsListCard(
        children: [
          DsLedgerRow(
            leading: DsIconTile.asset(asset: ClayIcons.stylus, tone: DsIconTileTone.income),
            title: t.home.freelanceRowTitle,
            subtitle: t.home.freelanceRowSub(
              count: overview.pendingCount,
              date: CycleMonthFormatter.formatDayMonth(overview.nextExpectedDate),
            ),
            amount: AppMoneyText.format(overview.unpaid, MoneyKind.balance),
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}
