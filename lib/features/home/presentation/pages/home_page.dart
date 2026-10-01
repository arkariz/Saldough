import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/freelance/presentation/navigation/freelance_route_keys.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/features/home/presentation/widgets/home_cards.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_keys.dart';
import 'package:saldough/shared/auth/auth_presentation.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
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
    this.notice,
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

  /// Kartu pemberitahuan di bawah total saldo, disisipkan akar komposisi
  /// (mis. kotak masuk Catat dari notifikasi, ADR-032); `null` = tidak ada.
  final Widget? notice;

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
      appBar: AppBar(
        title: Text(t.appShell.homeTabLabel),
        actions: [
          // Titik masuk layar Akun (ADR-023/024) -- identitas opsional, bukan
          // navigasi bawah karena bukan aktivitas harian.
          AccountAvatarButton(onPressed: () => context.pushRoute(AccountRouteKeys.page, const EmptyInput())),
        ],
      ),
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
    // TR-HOME (ADR-021 §3.4): mulai begitu ada dompet. Kartu yang baru
    // muncul belakangan (arus, anggaran, Freelance, transaksi terbaru)
    // disorot sendiri saat pertama tampil -- progres dicatat per langkah.
    return TourTrigger(
      tour: TourId.home,
      ready: !state.hasNoWallets,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.fabClearance),
        children: [
          SpotlightTarget(
            spotlightKey: SpotlightKey.homeBalance,
            child: HomeBalanceCard(
              total: state.totalBalance,
              activeWallets: state.activeWallets,
              hasNoWallets: state.hasNoWallets,
            ),
          ),
          ?widget.notice,
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
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeFreelance,
              child: HomeFreelanceCard(
                overview: freelance,
                onOpen: () => _thenRefresh(() => context.pushRoute(FreelanceRouteKeys.overview, const EmptyInput())),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (state.hasTransactions) ...[
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeRecent,
              child: HomeSectionHeader(
                icon: IconKey.transactions,
                title: t.home.recentTitle,
                trailing: HomeTextLink(label: t.home.seeAll, onTap: widget.onShowTransactions),
              ),
            ),
            for (final transaction in state.recentTransactions) ...[
              const SizedBox(height: AppSpacing.sm),
              TransactionRow(
                transaction: transaction,
                walletsById: state.walletsById,
                onTap: () => _thenRefresh(
                  () => context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
                ),
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
