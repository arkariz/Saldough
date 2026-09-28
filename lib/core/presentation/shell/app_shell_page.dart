import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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

/// Shell navigasi baru Saldough 2.0 — lima tujuan (Beranda, Anggaran, CATAT,
/// Transaksi, Dompet) dengan CATAT di tengah, dipasang di rute `/home`
/// (T-2.3, ditukar dari rute sementara `/shell` saat cutover T-3.4).
///
/// CATAT **bukan** tujuan navigasi biasa — menekannya tidak mengganti isi
/// `IndexedStack`, melainkan membuka lembar pilihan (lihat
/// [openRecordSheet]). Empat tujuan lain dipetakan ke `IndexedStack`
/// lewat [_tabIndexFor]/[_navIndexFor], menyisipkan CATAT di posisi tengah
/// tanpa memberinya slot `IndexedStack`.
///
/// Keempat tab sudah nyata: Beranda (Fase 6), Anggaran (T-4.5), Transaksi
/// (T-2.5), dan Dompet (T-2.7). Beranda menerima callback perpindahan tab dan
/// CATAT dari shell ini, supaya bloc tujuannya disegarkan dengan cara yang
/// sama seperti saat tabnya dipilih dari navigasi bawah.
///
/// CATAT sendiri (T-2.4) sudah nyata: menekannya membuka
/// [RecordChoiceSheet] (tiga pilihan, FR-REC-001), lalu satu dari tiga
/// formulir `features/record/`, lewat [openRecordSheet] (diekstrak dari
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
  /// Indeks tab `IndexedStack` (0..3), TIDAK termasuk CATAT. CATAT tidak
  /// pernah jadi tab "terpilih" yang persisten — menekannya membuka lembar
  /// lalu kembali ke tab yang sedang aktif.
  int _activeTab = 0;

  /// [AppShellPage.startAction] sudah dijalankan -- hanya sekali per shell.
  bool _startActionDone = false;

  static const _recordNavIndex = 2;
  static const _homeTabIndex = 0;
  static const _budgetTabIndex = 1;
  static const _transactionsTabIndex = 2;
  static const _walletsTabIndex = 3;

  /// Indeks `IndexedStack` (0..3) untuk indeks `NavigationBar` (0..4,
  /// melompati CATAT di posisi 2).
  int _tabIndexFor(int navIndex) => navIndex < _recordNavIndex ? navIndex : navIndex - 1;

  /// Kebalikan [_tabIndexFor] — indeks `NavigationBar` untuk tab aktif.
  int _navIndexFor(int tabIndex) => tabIndex < _recordNavIndex ? tabIndex : tabIndex + 1;

  /// Membuka alur CATAT, lalu memuat ulang daftar transaksi: `TransactionBloc`
  /// hidup di level shell dan hanya memuat saat `TransactionListPage` dibuat,
  /// jadi tanpa ini transaksi yang baru dicatat tidak tampil di tab Transaksi
  /// sampai aplikasi dimulai ulang.
  Future<void> _openRecord(BuildContext context) async {
    final transactions = context.read<TransactionBloc>();
    final wallets = context.read<WalletBloc>();
    final budgets = context.read<BudgetBloc>();
    final home = context.read<HomeBloc>();
    await openRecordSheet(context);
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
      }
    });
  }

  void _onDestinationSelected(BuildContext context, int navIndex) {
    if (navIndex == _recordNavIndex) {
      unawaited(_openRecord(context));
      return;
    }
    // Saldo dompet bisa berubah lewat transaksi yang disunting/dihapus di tab
    // Transaksi, jadi disegarkan tiap tab Dompet dibuka.
    if (_tabIndexFor(navIndex) == _walletsTabIndex) context.read<WalletBloc>().add(const WalletRefreshed());
    // Progres anggaran dihitung dari transaksi, yang bisa berubah di tab lain
    // (FR-BUD-003: progres berubah seketika saat transaksi disunting/dihapus).
    if (_tabIndexFor(navIndex) == _budgetTabIndex) context.read<BudgetBloc>().add(const BudgetRefreshed());
    // Angka Beranda dihitung dari seluruh fitur lain, yang bisa berubah di
    // tab mana pun.
    if (_tabIndexFor(navIndex) == _homeTabIndex) context.read<HomeBloc>().add(const HomeRefreshed());
    setState(() => _activeTab = _tabIndexFor(navIndex));
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
        onShowBudgets: () => _onDestinationSelected(context, _navIndexFor(_budgetTabIndex)),
        onShowTransactions: () => _onDestinationSelected(context, _navIndexFor(_transactionsTabIndex)),
        onShowWallets: () => _onDestinationSelected(context, _navIndexFor(_walletsTabIndex)),
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
                                            body: IndexedStack(index: _activeTab, children: tabsFor(context)),
                                            bottomNavigationBar: NavigationBar(
                                              selectedIndex: _navIndexFor(_activeTab),
                                              onDestinationSelected: (navIndex) =>
                                                  _onDestinationSelected(context, navIndex),
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
                                                  icon: const _RecordNavIcon(),
                                                  label: t.appShell.recordAction,
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
}

/// Ikon slot CATAT: kotak aksen dengan garis tepi dan bayangan keras level
/// "Interaktif" ADR-015 ("FAB CATAT"), supaya tindakan utama aplikasi tidak
/// tampil setara empat tab lain (prinsip produk #5, UX-13).
class _RecordNavIcon extends StatelessWidget {
  const _RecordNavIcon();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 44,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.accent,
        borderRadius: AppRadius.pixelSmAll,
        border: Border.all(color: colors.textPrimary, width: AppBorder.pixelThick),
        boxShadow: AppElevation.hardShadow(colors.textPrimary),
      ),
      child: AppIcon(IconKey.record, size: 20, color: colors.onAccent),
    );
  }
}
