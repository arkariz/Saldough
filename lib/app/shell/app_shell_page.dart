import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_keys.dart';
import 'package:saldough/features/budget/di/budget_scope.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/host/recurring_budget_host.dart';
import 'package:saldough/features/budget/presentation/pages/budget_list_page.dart';
import 'package:saldough/features/home/di/home_scope.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/features/home/presentation/pages/home_page.dart';
import 'package:saldough/features/notification_capture/presentation/host/notification_capture_host.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/capture_inbox_banner.dart';
import 'package:saldough/features/plan/presentation/funding_loader.dart';
import 'package:saldough/features/plan/presentation/pages/plan_month_page.dart';
import 'package:saldough/features/plan/presentation/pages/plan_page.dart';
import 'package:saldough/features/plan/presentation/widgets/plan_forecast_row.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_keys.dart';
import 'package:saldough/features/recurring/presentation/host/recurring_reminder_host.dart';
import 'package:saldough/features/recurring/presentation/pages/recurring_page.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_pending.dart';
import 'package:saldough/features/recurring/presentation/widgets/recurring_starter_chips.dart';
import 'package:saldough/features/transaction/di/transaction_scope.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:saldough/features/voice_capture/presentation/navigation/voice_capture_route_keys.dart';
import 'package:saldough/features/wallet/di/wallet_scope.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/pages/wallet_list_page.dart';
import 'package:state_management/state_management.dart';

/// Shell navigasi Saldough 2.0 — empat tab (Beranda, Rencana, Transaksi,
/// Dompet) di navigasi bawah, dan dua tombol mengambang bertumpuk di kanan
/// bawah: CATAT (besar) dan catat pakai suara (kecil, di atasnya). Dipasang
/// di rute `/home` (T-2.3, cutover T-3.4).
///
/// Kedua tombol mengambang membuka rute alur fitur `record`
/// (`RecordRouteKeys.sheet` dan `.voice`, ADR-030 §3.3), bukan tab. Alur itu
/// memegang `RecordScope`-nya sendiri, jadi shell tidak lagi memasang
/// `RecordBloc`; tab lain segar sesudah CATAT lewat `LedgerChanges`
/// (ADR-030 §3.4), bukan dimuat ulang dari sini.
///
/// Tiap tab memasang `ScopeWidget` fiturnya di sini karena tab persisten
/// selama shell hidup (`IndexedStack` menjaga seluruh tab tetap di pohon
/// widget). Semua scope dibangun dari `ScopeProvider` akar yang sama,
/// ditangkap SEKALI di awal `build`, bukan dari kontainer scope lain.
/// `EffectListener` tiap bloc tab dipasang di sini supaya snackbar hasil
/// formulir tetap tampil walau lembarnya sudah tertutup.
class AppShellPage extends StatefulWidget {
  /// Membuat [AppShellPage].
  const AppShellPage({this.startAction, super.key});

  /// Aksi yang dijalankan sekali sesudah shell siap, mis. membuka formulir
  /// dompet dari ajakan akhir onboarding (ADR-021 §3.2).
  final ShellStartAction? startAction;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  /// Indeks tab `IndexedStack` dan navigasi bawah (0..3).
  int _activeTab = 0;

  /// [AppShellPage.startAction] sudah dijalankan -- hanya sekali per shell.
  bool _startActionDone = false;

  /// Segmen tab Rencana yang tampil (T-15.4). Awal sesi Bulan ini, sesudah
  /// itu segmen terakhir selama shell hidup (KT-L4). Tidak disimpan.
  PlanSegment _planSegment = PlanSegment.thisMonth;

  static const _homeTabIndex = 0;
  static const _planTabIndex = 1;
  static const _transactionsTabIndex = 2;
  static const _walletsTabIndex = 3;

  /// Membuka alur CATAT atau catat pakai suara (ADR-027).
  Future<void> _openRecord(BuildContext context, {bool voice = false}) => voice
      ? context.pushRoute(VoiceCaptureRouteKeys.capture, const EmptyInput())
      : context.pushRoute(RecordRouteKeys.sheet, const RecordSheetInput());

  /// Menjalankan [AppShellPage.startAction] sekali, sesudah frame pertama
  /// yang context-nya sudah berada di bawah seluruh `BlocProvider` shell.
  void _maybeRunStartAction(BuildContext context) {
    final action = widget.startAction;
    if (action == null || _startActionDone) return;
    _startActionDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      switch (action) {
        case ShellStartAction.createWallet:
          // Dompet yang tersimpan memancarkan `LedgerChanges`; Beranda
          // memuat ulang sendiri.
          await openAddWalletSheet(context);
        case ShellStartAction.openAccount:
          await context.pushRoute(AccountRouteKeys.page, const EmptyInput());
      }
    });
  }

  void _onDestinationSelected(BuildContext context, int tabIndex) {
    // Perubahan transaksi dan saldo sampai lewat `LedgerChanges` (ADR-030
    // §3.4); menyegarkan tab saat tampil tetap dipertahankan untuk data
    // tanpa sinyal (anggaran, ringkasan freelance) dan penulis di luar
    // aplikasi ini.
    if (tabIndex == _walletsTabIndex) context.read<WalletBloc>().add(const WalletRefreshed());
    if (tabIndex == _planTabIndex) context.read<BudgetBloc>().add(const BudgetRefreshed());
    if (tabIndex == _homeTabIndex) context.read<HomeBloc>().add(const HomeRefreshed());
    // Snackbar (mis. Urungkan) milik tab sebelumnya kehilangan konteksnya.
    if (tabIndex != _activeTab) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _activeTab = tabIndex);
  }

  /// Membuka tab Rencana pada [segment] (PLAN_TAB_LAYOUT §3.3: tautan dari
  /// tempat lain membuka segmen yang tepat).
  void _showPlan(BuildContext context, PlanSegment segment) {
    setState(() => _planSegment = segment);
    _onDestinationSelected(context, _planTabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    // Empat tujuan nyata di `IndexedStack`, urutan Beranda, Rencana,
    // Transaksi, Dompet. Dibangun dengan context DI BAWAH seluruh
    // `BlocProvider` (lihat `Builder` di bawah), karena callback Beranda dan
    // `_onDestinationSelected` membaca bloc-bloc itu.
    List<Widget> tabsFor(BuildContext context) => [
      HomePage(
        onRecord: () => _openRecord(context),
        onShowBudgets: () => _showPlan(context, PlanSegment.budget),
        onShowTransactions: () => _onDestinationSelected(context, _transactionsTabIndex),
        onShowWallets: () => _onDestinationSelected(context, _walletsTabIndex),
        notice: CaptureInboxBanner(container: parentContainer),
        pendingRecurring: RecurringPendingCard(
          spotlight: (tour: TourId.home, key: SpotlightKey.homePending),
          container: parentContainer,
          onShowAll: () => _showPlan(context, PlanSegment.recurring),
        ),
        forecast: PlanForecastRow(
          container: parentContainer,
          onTap: () => _showPlan(context, PlanSegment.thisMonth),
        ),
      ),
      PlanPage(
        selected: _planSegment,
        onChanged: (segment) => setState(() => _planSegment = segment),
        segments: {
          PlanSegment.thisMonth: PlanMonthPage(
            container: parentContainer,
            onShowRecurring: () => _showPlan(context, PlanSegment.recurring),
            onShowBudget: () => _showPlan(context, PlanSegment.budget),
            pending: RecurringPendingCard(
              container: parentContainer,
              onShowAll: () => _showPlan(context, PlanSegment.recurring),
            ),
            starters: const RecurringStarterChips(),
          ),
          PlanSegment.budget: const BudgetListPage(embedded: true),
          PlanSegment.recurring: RecurringPage(container: parentContainer),
        },
      ),
      const TransactionListPage(),
      const WalletListPage(),
    ];
    return ScopeWidget<TransactionScope>(
      create: () => TransactionScope(parentContainer: parentContainer),
      builder: (context, transactionScope) => BlocProvider.value(
        value: transactionScope.container<TransactionBloc>(),
        child: EffectListener<TransactionBloc, TransactionState>(
          child: ScopeWidget<WalletScope>(
            create: () => WalletScope(parentContainer: parentContainer),
            builder: (context, walletScope) => BlocProvider.value(
              value: walletScope.container<WalletBloc>(),
              child: EffectListener<WalletBloc, WalletState>(
                child: ScopeWidget<BudgetScope>(
                  create: () => BudgetScope(parentContainer: parentContainer),
                  builder: (context, budgetScope) => BlocProvider.value(
                    value: budgetScope.container<BudgetBloc>(),
                    child: EffectListener<BudgetBloc, BudgetState>(
                      child: ScopeWidget<HomeScope>(
                        create: () => HomeScope(parentContainer: parentContainer),
                        builder: (context, homeScope) => BlocProvider.value(
                          value: homeScope.container<HomeBloc>(),
                          child: EffectListener<HomeBloc, HomeState>(
                            child: Builder(
                              builder: (context) {
                                _maybeRunStartAction(context);
                                // Catat dari notifikasi (ADR-032): proses saat dibuka,
                                // resume, tangkapan baru, dan ketukan pengingat.
                                // Anggaran rutin (ADR-036 §3.2): lahir saat dibuka dan saat tanggal berganti.
                                return RecurringBudgetHost(
                                  container: parentContainer,
                                  child: NotificationCaptureHost(
                                    container: parentContainer,
                                    // Pengingat rutin (ADR-035 §3.8): jadwal dan ketukan notifikasi.
                                    child: RecurringReminderHost(
                                      container: parentContainer,
                                      onShowRecurring: () => _showPlan(context, PlanSegment.recurring),
                                      // Siapkan dana (ADR-036 §3.6): hitungan fitur `plan`.
                                      fundingWarnings: () => loadFundingWarnings(parentContainer),
                                      child: Scaffold(
                                        body: IndexedStack(
                                          index: _activeTab,
                                          // `IndexedStack` menjaga tab tersembunyi tetap hidup;
                                          // tur hanya boleh mulai di tab yang tampil (ADR-021 §3.3).
                                          children: [
                                            for (final (i, tab) in tabsFor(context).indexed)
                                              TourVisibility(visible: i == _activeTab, child: tab),
                                          ],
                                        ),
                                        floatingActionButton: _RecordFabs(
                                          onRecord: () => unawaited(_openRecord(context)),
                                          onVoice: () => unawaited(_openRecord(context, voice: true)),
                                        ),
                                        bottomNavigationBar: NavigationBar(
                                          selectedIndex: _activeTab,
                                          onDestinationSelected: (tabIndex) =>
                                              _onDestinationSelected(context, tabIndex),
                                          destinations: [
                                            NavigationDestination(
                                              icon: const AppIcon(IconKey.home),
                                              label: t.appShell.homeTabLabel,
                                            ),
                                            NavigationDestination(
                                              icon: const AppIcon(IconKey.budget),
                                              label: t.appShell.planTabLabel,
                                            ),
                                            NavigationDestination(
                                              icon: const AppIcon(IconKey.transactions),
                                              label: t.appShell.transactionsTabLabel,
                                            ),
                                            NavigationDestination(
                                              icon: const AppIcon(IconKey.wallets),
                                              label: t.appShell.walletsTabLabel,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aksi yang dijalankan [AppShellPage] sekali saat dibuka.
enum ShellStartAction {
  /// Pindah ke tab Dompet dan membuka formulir tambah dompet — ajakan
  /// "Buat Dompet Pertama" onboarding (KO-6).
  createWallet,

  /// Membuka layar Akun — "Sudah punya akun? Masuk" onboarding (ADR-024).
  openAccount,
}

/// Dua tombol mengambang bertumpuk di kanan bawah: catat pakai suara (kecil,
/// atas) dan CATAT (besar, bawah). Gaya "Interaktif" ADR-015 -- kotak aksen
/// bergaris tepi dan bayangan keras -- supaya tindakan utama aplikasi tidak
/// tampil setara tab (prinsip produk #5, UX-13).
class _RecordFabs extends StatelessWidget {
  const _RecordFabs({required this.onRecord, required this.onVoice});

  final VoidCallback onRecord;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SpotlightTarget(
          spotlightKey: SpotlightKey.homeVoice,
          child: _PixelFab(
            key: const ValueKey('shell-voice-fab'),
            icon: IconKey.microphone,
            label: t.record.voice.micLabel,
            size: 60,
            background: colors.cardBackground,
            foreground: colors.textPrimary,
            onTap: onVoice,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SpotlightTarget(
          spotlightKey: SpotlightKey.homeRecord,
          child: _PixelFab(
            key: const ValueKey('shell-record-fab'),
            icon: IconKey.record,
            label: t.appShell.recordAction,
            size: 60,
            background: colors.accent,
            foreground: colors.onAccent,
            onTap: onRecord,
          ),
        ),
      ],
    );
  }
}

class _PixelFab extends StatelessWidget {
  const _PixelFab({
    required this.icon,
    required this.label,
    required this.size,
    required this.background,
    required this.foreground,
    required this.onTap,
    super.key,
  });

  final IconKey icon;
  final String label;
  final double size;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppTappable(
      label: label,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.pixelSmAll,
          border: Border.all(color: colors.edge, width: AppBorder.pixelThick),
          boxShadow: AppElevation.hardShadow(colors.edge),
        ),
        child: AppIcon(icon, size: size * 0.45, color: foreground),
      ),
    );
  }
}
