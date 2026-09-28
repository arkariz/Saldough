import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_overview_page.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/features/home/presentation/widgets/home_cards.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_detail_page.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_date_group_card.dart';
import 'package:state_management/state_management.dart';

/// Beranda (Fase 6, FR-HOME-001..005), rujukan visual `pixel_kas_beranda` dan
/// `pixel_kas_beranda_belum_ada_data`.
///
/// Perpindahan ke tab lain dan alur CATAT dioper [AppShellPage] lewat
/// callback, supaya bloc tab-tab itu ikut disegarkan dengan cara yang sama
/// seperti saat tabnya dipilih dari navigasi bawah. Ajakan mencatat membuka
/// alur CATAT yang SAMA (aturan 8), bukan formulir tersendiri.
class HomePage extends StatefulWidget {
  /// Membuat [HomePage].
  const HomePage({
    required this.onRecord,
    required this.onShowBudgets,
    required this.onShowTransactions,
    required this.onShowWallets,
    super.key,
  });

  /// Membuka alur CATAT.
  final Future<void> Function() onRecord;

  /// Pindah ke tab Anggaran.
  final VoidCallback onShowBudgets;

  /// Pindah ke tab Transaksi.
  final VoidCallback onShowTransactions;

  /// Pindah ke tab Dompet (membuat dompet pertama).
  final VoidCallback onShowWallets;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
  }

  /// Menjalankan [open] lalu menyegarkan Beranda — angka bisa berubah di
  /// layar yang dibukanya (mencatat, menerima pembayaran, menyunting).
  Future<void> _thenRefresh(Future<void> Function() open) async {
    final bloc = context.read<HomeBloc>();
    await open();
    bloc.add(const HomeRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.appShell.homeTabLabel)),
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => switch (state) {
            HomeState(isLoading: true) => const AppSkeletonPage(),
            HomeState(loadFailed: true) => _LoadError(
              onRetry: () => context.read<HomeBloc>().add(const HomeStarted()),
            ),
            _ => _content(context, state),
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, HomeState state) {
    final budget = state.budget;
    final freelance = state.freelance;
    // TR-HOME (ADR-021 §3.4): mulai begitu ada dompet. Kartu arus dan
    // anggaran hanya disorot kalau tampil -- langkahnya dilewati diam-diam.
    return TourTrigger(
      tour: TourId.home,
      ready: !state.hasNoWallets,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        children: [
          SpotlightTarget(
            spotlightKey: SpotlightKey.homeBalance,
            child: HomeBalanceCard(
              total: state.totalBalance,
              activeWallets: state.activeWallets,
              hasNoWallets: state.hasNoWallets,
            ),
          ),
          // Kartu tanpa isi disembunyikan, bukan diisi angka nol (FR-HOME-005).
          if (state.hasTransactions) ...[
            const SizedBox(height: AppSpacing.md),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeCashFlow,
              child: HomeCashFlowRow(cashFlow: state.cashFlow, month: state.month),
            ),
          ],
          if (budget != null) ...[
            const SizedBox(height: AppSpacing.md),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeBudget,
              child: HomeBudgetCard(overview: budget, onOpen: widget.onShowBudgets),
            ),
          ],
          if (freelance != null) ...[
            const SizedBox(height: AppSpacing.md),
            HomeFreelanceCard(
              overview: freelance,
              onOpen: () => _thenRefresh(() => openFreelanceOverview(context)),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (state.hasTransactions) ...[
            HomeSectionHeader(
              icon: IconKey.transactions,
              title: t.home.recentTitle,
              trailing: HomeTextLink(label: t.home.seeAll, onTap: widget.onShowTransactions),
            ),
            for (final transaction in state.recentTransactions) ...[
              const SizedBox(height: AppSpacing.sm),
              TransactionRow(
                transaction: transaction,
                walletsById: state.walletsById,
                onTap: () => _thenRefresh(() => openTransactionDetail(context, transaction)),
              ),
            ],
          ] else ...[
            HomeEmptyTransactions(
              hasNoWallets: state.hasNoWallets,
              onRecord: () => _thenRefresh(widget.onRecord),
              onAddWallet: widget.onShowWallets,
              onBudget: widget.onShowBudgets,
            ),
            const SizedBox(height: AppSpacing.lg),
            const HomeGuide(),
          ],
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.home.loadErrorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.common.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
