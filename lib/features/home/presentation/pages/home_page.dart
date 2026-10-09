import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/freelance/presentation/navigation/freelance_route_keys.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/features/home/presentation/widgets/home_cards.dart';
import 'package:saldough/features/home/presentation/widgets/home_summary.dart';
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
    this.pendingRecurring,
    this.forecast,
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

  /// Kartu Menunggu dicatat (T-15.6), disisipkan akar komposisi supaya
  /// `home` tidak mengimpor fitur `recurring`; tampil hanya bila ada isinya.
  final Widget? pendingRecurring;

  /// Baris perkiraan saldo akhir bulan (T-15.13), disisipkan akar komposisi.
  final Widget? forecast;

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
        title: Text(t.appShell.homeTabLabel, style: Theme.of(context).textTheme.headlineSmall),
        centerTitle: false,
        actions: [
          // Menu tur (KO-4, ADR-021 §3.5) dulu ada di kartu saldo; kartu
          // terakota tidak memuat tombol lain (design system HeroCard).
          const TutorialInfoButton(tour: TourId.home),
          // Sembunyikan nominal (ADR-034 §4): berlaku di semua nominal
          // aplikasi, tersimpan di setelan.
          AppIconButton(
            key: const ValueKey('home-hide-amounts'),
            icon: AmountVisibility.hidden ? IconKey.visibilityOff : IconKey.visibility,
            label: AmountVisibility.hidden ? t.home.showAmounts : t.home.hideAmounts,
            onPressed: AmountVisibility.toggle,
          ),
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space12),
        children: [
          // Urutan `patterns.md`: total saldo → yang perlu tindakan → bulan
          // ini → anggaran → freelance → transaksi terbaru.
          // Tanpa dompet, Beranda langsung ke langkah awal (`BerandaKosong`):
          // total Rp0 tidak memberi informasi (FR-HOME-005).
          if (!state.hasNoWallets)
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeBalance,
              child: HomeBalanceCard(
                total: state.totalBalance,
                walletCount: state.activeWallets.length,
                onShowWallets: widget.onShowWallets,
              ),
            ),
          // Banner kotak masuk membawa jarak atasnya sendiri (kosong = tidak ada).
          ?widget.notice,
          ?widget.pendingRecurring,
          // Kartu tanpa isi disembunyikan, bukan diisi angka nol (FR-HOME-005).
          if (state.hasTransactions) ...[
            const SizedBox(height: AppSpacing.space6),
            AppSectionHeader(
              CycleMonthFormatter.formatMonthName(state.month),
              actionLabel: t.appShell.transactionsTabLabel,
              onAction: widget.onShowTransactions,
            ),
            const SizedBox(height: AppSpacing.space2),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeCashFlow,
              child: HomeMonthCard(cashFlow: state.cashFlow, footer: widget.forecast),
            ),
          ] else if (widget.forecast case final forecast?) ...[
            const SizedBox(height: AppSpacing.space6),
            forecast,
          ],
          if (budget != null) ...[
            const SizedBox(height: AppSpacing.space6),
            AppSectionHeader(t.appShell.budgetTabLabel, actionLabel: t.home.seeAll, onAction: widget.onShowBudgets),
            const SizedBox(height: AppSpacing.space2),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeBudget,
              child: HomeBudgetCard(overview: budget, onOpen: widget.onShowBudgets),
            ),
          ],
          if (freelance != null) ...[
            const SizedBox(height: AppSpacing.space6),
            AppSectionHeader(t.home.freelanceTitle),
            const SizedBox(height: AppSpacing.space2),
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeFreelance,
              child: HomeFreelanceCard(
                overview: freelance,
                onOpen: () => _thenRefresh(() => context.pushRoute(FreelanceRouteKeys.overview, const EmptyInput())),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space6),
          if (state.hasTransactions) ...[
            SpotlightTarget(
              spotlightKey: SpotlightKey.homeRecent,
              child: AppSectionHeader(
                t.home.recentTitle,
                actionLabel: t.home.seeAll,
                onAction: widget.onShowTransactions,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            AppListCard(
              children: [
                for (final transaction in state.recentTransactions)
                  TransactionRow(
                    transaction: transaction,
                    walletsById: state.walletsById,
                    onTap: () => _thenRefresh(
                      () => context.pushRoute(TransactionRouteKeys.detail, TransactionDetailInput(transaction)),
                    ),
                  ),
              ],
            ),
          ] else ...[
            HomeFirstSteps(
              hasNoWallets: state.hasNoWallets,
              onRecord: () => _thenRefresh(widget.onRecord),
              onAddWallet: widget.onShowWallets,
              onBudget: widget.onShowBudgets,
            ),
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
  Widget build(BuildContext context) =>
      AppErrorState(title: t.home.loadErrorTitle, retryLabel: t.common.retry, onRetry: onRetry);
}
