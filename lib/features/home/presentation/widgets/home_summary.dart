import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kartu saldo Beranda (prototipe `Main.dc.html`, komponen HeroCard): total
/// saldo dompet aktif (FR-HOME-001) di kartu terakota dengan tanuki, dan
/// tautan "Di N dompet" ke tab Dompet. Tanpa dompet, tautannya tidak ada;
/// ajakan membuat dompet pertama ada di bawah (FR-HOME-005).
class HomeBalanceCard extends StatelessWidget {
  /// Membuat [HomeBalanceCard].
  const HomeBalanceCard({
    required this.total,
    required this.walletCount,
    required this.onShowWallets,
    super.key,
  });

  /// Total saldo tercatat dompet aktif, sen.
  final int total;

  /// Jumlah dompet aktif.
  final int walletCount;

  /// Membuka tab Dompet.
  final VoidCallback onShowWallets;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppHeroCard(
      label: t.home.balanceLabel,
      amount: HeroAmount(
        AppMoneyFormatter.format(total),
        color: colors.onBrand,
        symbolColor: colors.onBrand,
      ),
      linkLabel: walletCount == 0
          ? null
          : t.home.walletLink(count: walletCount),
      onLinkTap: onShowWallets,
    );
  }
}

/// Bulan berjalan di Beranda: pemasukan dan pengeluaran berdampingan, lalu
/// selisihnya di bawah garis (ringkasan bergaya buku kas, design system
/// Card). Transfer sudah dikecualikan di [cashFlow] (FR-HOME-001).
class HomeMonthCard extends StatelessWidget {
  /// Membuat [HomeMonthCard].
  const HomeMonthCard({required this.cashFlow, this.footer, super.key});

  /// Arus bulan berjalan.
  final CashFlow cashFlow;

  /// Isi tambahan di bawah selisih (perkiraan saldo akhir bulan, T-15.13).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    Widget stat(String label, int sen, MoneyKind kind) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
        FitStart(child: AppMoneyText(sen, kind: kind)),
      ],
    );
    final net = cashFlow.income - cashFlow.expense;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: stat(
                  t.home.incomeStat,
                  cashFlow.income,
                  MoneyKind.income,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: stat(
                  t.home.expenseStat,
                  cashFlow.expense,
                  MoneyKind.expense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.home.netLabel,
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Flexible(
                child: FitStart(
                  child: AppMoneyText(
                    net,
                    size: MoneySize.small,
                    color: colors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.space2),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Ringkasan anggaran aktif (FR-HOME-002) sebagai kartu yang membuka tab
/// Rencana: badge status, sisa (`amount-lg`), bar kotak, dan "terpakai
/// dari rencana" di bawahnya. Status: Aman di bawah 85%, Hampir habis
/// 85–100%, Lewat menyebut selisihnya.
class HomeBudgetCard extends StatelessWidget {
  /// Membuat [HomeBudgetCard].
  const HomeBudgetCard({
    required this.overview,
    required this.onOpen,
    super.key,
  });

  /// Ringkasan anggaran aktif.
  final BudgetOverview overview;

  /// Membuka tab Rencana pada segmen Anggaran.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final ratio = overview.plannedAmount <= 0
        ? 0.0
        : overview.spent / overview.plannedAmount;
    final (badge, tone) = switch (AppProgressBar.statusFor(ratio)) {
      AppBarStatus.safe => (t.home.budgetSafe, AppTone.positive),
      AppBarStatus.nearlyOut => (t.home.budgetNearlyOut, AppTone.warning),
      AppBarStatus.over => (
        t.home.budgetOverBy(
          amount: AppMoneyFormatter.format(-overview.remaining),
        ),
        AppTone.danger,
      ),
    };
    return AppCard(
      onTap: onOpen,
      semanticsLabel: t.home.budgetAction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.home.budgetTitle, style: textTheme.titleMedium),
              ),
              const SizedBox(width: AppSpacing.space2),
              Flexible(child: AppBadge(badge, tone: tone)),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            t.home.budgetRemaining,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
          FitStart(
            child: AppMoneyText(
              overview.remaining,
              kind: MoneyKind.remaining,
              size: MoneySize.large,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppProgressBar(value: ratio),
          const SizedBox(height: AppSpacing.space2),
          Text(
            t.home.budgetSpentOf(
              spent: AppMoneyFormatter.format(overview.spent),
              planned: AppMoneyFormatter.format(overview.plannedAmount),
            ),
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}

/// Pintu masuk Freelance di Beranda (ADR-034 §4): satu baris "Belum
/// diterima" dengan jumlah tagihan dan perkiraan terdekat (FR-HOME-003).
class HomeFreelanceCard extends StatelessWidget {
  /// Membuat [HomeFreelanceCard].
  const HomeFreelanceCard({
    required this.overview,
    required this.onOpen,
    super.key,
  });

  /// Ringkasan freelance.
  final FreelanceOverview overview;

  /// Membuka Ikhtisar Freelance.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      children: [
        AppListRow(
          leading: const AppIconTile(IconKey.freelance),
          title: t.home.freelanceRowTitle,
          subtitle: t.home.freelanceRowSub(
            count: overview.pendingCount,
            date: CycleMonthFormatter.formatDayMonth(overview.nextExpectedDate),
          ),
          trailing: AppMoneyText(overview.unpaid),
          chevron: true,
          semanticsLabel: t.home.freelanceAction,
          onTap: onOpen,
        ),
      ],
    );
  }
}
