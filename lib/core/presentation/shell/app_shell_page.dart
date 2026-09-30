import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/presentation/pages/account_page.dart';
import 'package:saldough/features/budget/di/budget_scope.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_state.dart';
import 'package:saldough/features/budget/presentation/pages/budget_list_page.dart';
import 'package:saldough/features/home/di/home_scope.dart';
import 'package:saldough/features/home/presentation/bloc/home_bloc.dart';
import 'package:saldough/features/home/presentation/bloc/home_state.dart';
import 'package:saldough/features/home/presentation/pages/home_page.dart';
import 'package:saldough/features/record/di/record_scope.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/features/record/presentation/capture/open_voice_record.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:saldough/features/transaction/di/transaction_scope.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:saldough/features/wallet/di/wallet_scope.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:saldough/features/wallet/presentation/bloc/wallet_state.dart';
import 'package:saldough/features/wallet/presentation/pages/wallet_list_page.dart';
import 'package:state_management/state_management.dart';

/// Shell navigasi Saldough 2.0 — empat tab (Beranda, Anggaran, Transaksi,
/// Dompet) di navigasi bawah, dan dua tombol mengambang bertumpuk di kanan
/// bawah: CATAT (besar) dan catat pakai suara (kecil, di atasnya). Dipasang
/// di rute `/home` (T-2.3, cutover T-3.4).
///
/// Sejak perbaikan T-11.5 (30 Sep 2026) CATAT tidak lagi berada di tengah
/// navigasi bawah: kedua tombol mengambang membuka lembar, bukan tab --
/// [openRecordSheet] untuk formulir dan [openVoiceRecord] untuk suara
/// (ADR-027).
///
/// Keempat tab sudah nyata: Beranda (Fase 6), Anggaran (T-4.5), Transaksi
/// (T-2.5), dan Dompet (T-2.7). Beranda menerima callback perpindahan tab dan
/// CATAT dari shell ini, supaya bloc tujuannya disegarkan dengan cara yang
/// sama seperti saat tabnya dipilih dari navigasi bawah.
///
/// CATAT sendiri (T-2.4) sudah nyata: menekannya membuka satu lembar
/// formulir `features/record/` dengan pengalih tiga jenis (FR-REC-001, UX-1),
/// lewat [openRecordSheet] (diekstrak dari
/// `State` ini ke fungsi tingkat atas di T-2.5 supaya CTA keadaan kosong
/// `TransactionListPage` bisa memicu alur yang SAMA, bukan formulir
/// pencatatan tersendiri — CLAUDE.md aturan 8). `RecordBloc` dipasang
/// sekali lewat `ScopeWidget<RecordScope>` yang membungkus seluruh shell
/// (bukan dibuat ulang tiap lembar dibuka) supaya `EffectListener`-nya
/// tetap bisa menampilkan galat/berhasil walau kedua lembar (pilihan lalu
/// formulir) sudah tertutup — pola yang sama seperti snackbar
/// `IncomeSourceBloc` tetap tampil di `IncomeSourceListPage` setelah
/// `IncomeSourceEditSheet` ditutup.
///
/// `TransactionScope`/`TransactionBloc` (T-2.5) dipasang dengan pola yang
/// SAMA — `ScopeWidget<TransactionScope>` BERSEBELAHAN dengan
/// `ScopeWidget<RecordScope>` (bukan bersarang di dalamnya), keduanya
/// dibangun dari [parentContainer] akar yang sama, ditangkap SEKALI di awal
/// `build`. Ini isolasi yang benar: `TransactionScope` membawa
/// `WalletRepository`/`TransactionRepository` langsung dari kontainer akar,
/// bukan diam-diam lewat kontainer `RecordScope` (yang kebetulan membawa
/// keduanya juga, tapi mengandalkan itu akan membuat `TransactionScope`
/// diam-diam bergantung pada keberadaan `RecordScope`, sesuatu yang bisa
/// berubah). `TransactionBloc` dipasang di level shell (bukan di dalam
/// `TransactionListPage` sendiri) karena tab ini persisten selama shell
/// hidup (`IndexedStack` menjaga seluruh tab tetap ada di pohon widget,
/// tidak dibangun ulang tiap tab aktif berpindah) — sama alasannya
/// `RecordBloc` dipasang di level shell, bukan di dalam tiap lembar CATAT.
///
/// Seluruh shell ini (tab dan lembar yang dibukanya) dibungkus
/// `PixelTheme` — bahasa visual ADR-015 (palet, tipografi, radius, garis
/// tepi) — sebagai pembungkus TERLUAR, di luar kedua `ScopeWidget` di atas.
/// Layar dan lembar baru berikutnya otomatis mewarisinya cukup dengan
/// dirender di dalam shell ini, tanpa perlu membungkus dirinya sendiri.
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

  static const _homeTabIndex = 0;
  static const _budgetTabIndex = 1;
  static const _transactionsTabIndex = 2;
  static const _walletsTabIndex = 3;

  /// Membuka alur CATAT, lalu memuat ulang daftar transaksi: `TransactionBloc`
  /// hidup di level shell dan hanya memuat saat `TransactionListPage` dibuat,
  /// jadi tanpa ini transaksi yang baru dicatat tidak tampil di tab Transaksi
  /// sampai aplikasi dimulai ulang.
  Future<void> _openRecord(BuildContext context, {bool voice = false}) async {
    final transactions = context.read<TransactionBloc>();
    final wallets = context.read<WalletBloc>();
    final budgets = context.read<BudgetBloc>();
    final home = context.read<HomeBloc>();
    await (voice ? openVoiceRecord(context) : openRecordSheet(context));
    transactions.add(const TransactionRefreshed());
    wallets.add(const WalletRefreshed());
    budgets.add(const BudgetRefreshed());
    home.add(const HomeRefreshed());
  }

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
          final home = context.read<HomeBloc>();
          await openAddWalletSheet(context);
          home.add(const HomeRefreshed());
        case ShellStartAction.openAccount:
          await openAccountPage(context);
      }
    });
  }

  void _onDestinationSelected(BuildContext context, int tabIndex) {
    // Saldo dompet bisa berubah lewat transaksi yang disunting/dihapus di tab
    // Transaksi, jadi disegarkan tiap tab Dompet dibuka.
    if (tabIndex == _walletsTabIndex) context.read<WalletBloc>().add(const WalletRefreshed());
    // Progres anggaran dihitung dari transaksi, yang bisa berubah di tab lain
    // (FR-BUD-003: progres berubah seketika saat transaksi disunting/dihapus).
    if (tabIndex == _budgetTabIndex) context.read<BudgetBloc>().add(const BudgetRefreshed());
    // Angka Beranda dihitung dari seluruh fitur lain, yang bisa berubah di
    // tab mana pun.
    if (tabIndex == _homeTabIndex) context.read<HomeBloc>().add(const HomeRefreshed());
    setState(() => _activeTab = tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    // Empat tujuan nyata di `IndexedStack`, urutan Beranda, Anggaran,
    // Transaksi, Dompet — sama seperti destinations minus CATAT. Dibangun
    // dengan context DI BAWAH seluruh `BlocProvider` (lihat `Builder` di
    // bawah), karena callback Beranda membaca bloc-bloc itu.
    List<Widget> tabsFor(BuildContext context) => [
      HomePage(
        onRecord: () => _openRecord(context),
        onShowBudgets: () => _onDestinationSelected(context, _budgetTabIndex),
        onShowTransactions: () => _onDestinationSelected(context, _transactionsTabIndex),
        onShowWallets: () => _onDestinationSelected(context, _walletsTabIndex),
      ),
      const BudgetListPage(),
      const TransactionListPage(),
      const WalletListPage(),
    ];
    // PixelTheme membungkus SELURUH shell (tab + lembar CATAT yang dibuka
    // dari dalamnya) dengan bahasa visual ADR-015 -- lihat dokumentasi
    // kelas [PixelTheme]. Tema global (`AppTheme`/ADR-0006) tidak disentuh;
    // layar lama di luar shell ini tidak terpengaruh. Dipasang sebagai
    // pembungkus TERLUAR, di luar kedua `ScopeWidget` di bawah.
    return PixelTheme(
      child: ScopeWidget<RecordScope>(
        create: () => RecordScope(parentContainer: parentContainer),
        builder: (context, recordScope) {
          return BlocProvider.value(
            value: recordScope.container<RecordBloc>(),
            child: EffectListener<RecordBloc, RecordState>(
              // `ScopeWidget<TransactionScope>` BERSEBELAHAN dengan
              // `ScopeWidget<RecordScope>` di atas, bukan bersarang di
              // dalamnya -- keduanya dibangun dari [parentContainer] akar
              // yang sama (ditangkap sebelum ScopeWidget pertama), bukan
              // dari kontainer RecordScope. Lihat dokumentasi kelas
              // [AppShellPage].
              child: ScopeWidget<TransactionScope>(
                create: () => TransactionScope(parentContainer: parentContainer),
                builder: (context, transactionScope) {
                  return BlocProvider.value(
                    value: transactionScope.container<TransactionBloc>(),
                    // Snackbar hasil sunting/hapus transaksi (T-2.6). Dipasang
                    // di shell, bukan di layar rincian, supaya tetap tampil
                    // walau layar rincian sudah ditutup saat hasilnya tiba.
                    child: EffectListener<TransactionBloc, TransactionState>(
                      // `Builder` di sini bukan hiasan: context yang dipakai
                      // `_onDestinationSelected`/`openRecordSheet` HARUS berada
                      // DI BAWAH kedua `BlocProvider` di atas supaya
                      // `context.read<RecordBloc>()` menemukannya. Context
                      // milik parameter `builder` ScopeWidget ATAU
                      // `build(BuildContext context)` di luar sini keduanya
                      // leluhur `BlocProvider` ini, bukan keturunannya.
                      child: ScopeWidget<WalletScope>(
                        create: () => WalletScope(parentContainer: parentContainer),
                        builder: (context, walletScope) => BlocProvider.value(
                          value: walletScope.container<WalletBloc>(),
                          // Snackbar hasil tambah/sunting/hapus dompet (T-2.7), di shell supaya
                          // tetap tampil walau formulirnya sudah tertutup saat hasilnya tiba.
                          child: EffectListener<WalletBloc, WalletState>(
                            // Anggaran (Fase 4): pola yang sama seperti dompet.
                            child: ScopeWidget<BudgetScope>(
                              create: () => BudgetScope(parentContainer: parentContainer),
                              builder: (context, budgetScope) => BlocProvider.value(
                                value: budgetScope.container<BudgetBloc>(),
                                child: EffectListener<BudgetBloc, BudgetState>(
                                  // Beranda (Fase 6): pola yang sama.
                                  child: ScopeWidget<HomeScope>(
                                    create: () => HomeScope(parentContainer: parentContainer),
                                    builder: (context, homeScope) => BlocProvider.value(
                                      value: homeScope.container<HomeBloc>(),
                                      child: EffectListener<HomeBloc, HomeState>(
                                        child: Builder(
                                          builder: (context) {
                                            _maybeRunStartAction(context);
                                            return Scaffold(
                                            body: IndexedStack(
                                                index: _activeTab,
                                                // `IndexedStack` menjaga tab tersembunyi tetap
                                                // hidup; tur hanya boleh mulai di tab yang tampil
                                                // (ADR-021 §3.3).
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
                                                  label: t.appShell.budgetTabLabel,
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
                  );
                },
              ),
            ),
          );
        },
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
