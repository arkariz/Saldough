import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/di/record_scope.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/features/record/presentation/open_record_sheet.dart';
import 'package:saldough/features/transaction/di/transaction_scope.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/pages/transaction_list_page.dart';
import 'package:state_management/state_management.dart';

/// Shell navigasi baru Saldough 2.0 — lima tujuan (Beranda, Anggaran, CATAT,
/// Transaksi, Dompet) dengan CATAT di tengah, dipasang di rute sementara
/// `/shell` (T-2.3). Berdampingan dengan `MainShellPage` sampai T-3.4
/// menukar `/home` ke sini dan menghapus `MainShellPage` beserta rute
/// sementara ini.
///
/// CATAT **bukan** tujuan navigasi biasa — menekannya tidak mengganti isi
/// `IndexedStack`, melainkan membuka lembar pilihan (lihat
/// [openRecordSheet]). Empat tujuan lain dipetakan ke `IndexedStack`
/// lewat [_tabIndexFor]/[_navIndexFor], menyisipkan CATAT di posisi tengah
/// tanpa memberinya slot `IndexedStack`.
///
/// Isi tiap tab masih [_ComingSoonTab] sampai fiturnya sendiri dibangun:
/// Dompet (T-2.7), Anggaran (Fase 4), Beranda (Fase 6). Transaksi (T-2.5)
/// sudah nyata: `TransactionListPage`. Menukar tab sisanya jadi layar
/// sungguhan berarti mengganti satu entri di daftar `tabs` pada `build`,
/// bukan menulis ulang shell ini.
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
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  /// Indeks tab `IndexedStack` (0..3), TIDAK termasuk CATAT. CATAT tidak
  /// pernah jadi tab "terpilih" yang persisten — menekannya membuka lembar
  /// lalu kembali ke tab yang sedang aktif.
  int _activeTab = 0;

  static const _recordNavIndex = 2;

  /// Indeks `IndexedStack` (0..3) untuk indeks `NavigationBar` (0..4,
  /// melompati CATAT di posisi 2).
  int _tabIndexFor(int navIndex) => navIndex < _recordNavIndex ? navIndex : navIndex - 1;

  /// Kebalikan [_tabIndexFor] — indeks `NavigationBar` untuk tab aktif.
  int _navIndexFor(int tabIndex) => tabIndex < _recordNavIndex ? tabIndex : tabIndex + 1;

  void _onDestinationSelected(BuildContext context, int navIndex) {
    if (navIndex == _recordNavIndex) {
      unawaited(openRecordSheet(context));
      return;
    }
    setState(() => _activeTab = _tabIndexFor(navIndex));
  }

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    // Empat tujuan nyata di `IndexedStack`, urutan Beranda, Anggaran,
    // Transaksi, Dompet — sama seperti destinations minus CATAT. Dibangun
    // di `build` (bukan `static const`) karena labelnya lewat `t`, yang
    // bukan konstanta kompilasi.
    final tabs = [
      _ComingSoonTab(icon: IconKey.home, label: t.appShell.homeTabLabel),
      _ComingSoonTab(icon: IconKey.budget, label: t.appShell.budgetTabLabel),
      const TransactionListPage(),
      _ComingSoonTab(icon: IconKey.wallets, label: t.appShell.walletsTabLabel),
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
                      child: Builder(
                        builder: (context) => Scaffold(
                          body: IndexedStack(index: _activeTab, children: tabs),
                          bottomNavigationBar: NavigationBar(
                            selectedIndex: _navIndexFor(_activeTab),
                            onDestinationSelected: (navIndex) => _onDestinationSelected(context, navIndex),
                            destinations: [
                              NavigationDestination(icon: const AppIcon(IconKey.home), label: t.appShell.homeTabLabel),
                              NavigationDestination(
                                icon: const AppIcon(IconKey.budget),
                                label: t.appShell.budgetTabLabel,
                              ),
                              NavigationDestination(
                                icon: const AppIcon(IconKey.record),
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

/// Isian sementara satu tab, sampai fitur sungguhannya dibangun.
class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.icon, required this.label});

  final IconKey icon;

  /// Judul tab, sudah diterjemahkan oleh pemanggil.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, size: 48, color: colors.textMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(t.appShell.comingSoonMessage, style: TextStyle(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
