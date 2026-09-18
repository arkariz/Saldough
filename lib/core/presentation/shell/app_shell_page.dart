import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/record/di/record_scope.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/bloc/record_state.dart';
import 'package:saldough/features/record/presentation/widgets/expense_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/income_form_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice_sheet.dart';
import 'package:saldough/features/record/presentation/widgets/transfer_form_sheet.dart';
import 'package:state_management/state_management.dart';

/// Shell navigasi baru Saldough 2.0 — lima tujuan (Beranda, Anggaran, CATAT,
/// Transaksi, Dompet) dengan CATAT di tengah, dipasang di rute sementara
/// `/shell` (T-2.3). Berdampingan dengan `MainShellPage` sampai T-3.4
/// menukar `/home` ke sini dan menghapus `MainShellPage` beserta rute
/// sementara ini.
///
/// CATAT **bukan** tujuan navigasi biasa — menekannya tidak mengganti isi
/// `IndexedStack`, melainkan membuka lembar pilihan (lihat
/// [_openRecordSheet]). Empat tujuan lain dipetakan ke `IndexedStack`
/// lewat [_tabIndexFor]/[_navIndexFor], menyisipkan CATAT di posisi tengah
/// tanpa memberinya slot `IndexedStack`.
///
/// Isi tiap tab masih [_ComingSoonTab] sampai fiturnya sendiri dibangun:
/// Transaksi (T-2.5), Dompet (T-2.7), Anggaran (Fase 4), Beranda (Fase 6).
/// Menukarnya jadi layar sungguhan berarti mengganti satu entri di daftar
/// `tabs` pada `build`, bukan menulis ulang shell ini.
///
/// CATAT sendiri (T-2.4) sudah nyata: menekannya membuka
/// [RecordChoiceSheet] (tiga pilihan, FR-REC-001), lalu satu dari tiga
/// formulir `features/record/`. `RecordBloc` dipasang sekali lewat
/// `ScopeWidget<RecordScope>` yang membungkus seluruh shell (bukan dibuat
/// ulang tiap lembar dibuka) supaya `EffectListener`-nya tetap bisa
/// menampilkan galat/berhasil walau kedua lembar (pilihan lalu formulir)
/// sudah tertutup — pola yang sama seperti snackbar `IncomeSourceBloc`
/// tetap tampil di `IncomeSourceListPage` setelah `IncomeSourceEditSheet`
/// ditutup.
///
/// Seluruh shell ini (tab dan lembar yang dibukanya) dibungkus
/// `PixelTheme` — bahasa visual ADR-015 (palet, tipografi, radius, garis
/// tepi) — sebagai pembungkus TERLUAR, di luar `ScopeWidget<RecordScope>`.
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
      unawaited(_openRecordSheet(context));
      return;
    }
    setState(() => _activeTab = _tabIndexFor(navIndex));
  }

  /// Membuka alur CATAT: [RecordChoiceSheet] (tiga pilihan, FR-REC-001),
  /// lalu satu dari tiga formulir. Kedua lembar sengaja terpisah, bukan
  /// satu lembar yang berpindah "halaman" internal — masing-masing
  /// `showModalBottomSheet` sendiri, dengan [Navigator.pop] yang
  /// mengembalikan pilihan/hasilnya ke sini.
  ///
  /// Formulir TIDAK membaca `RecordBloc` lewat `context` sendiri (rute
  /// modalnya bukan keturunan `BlocProvider` yang dipasang di [build] —
  /// keduanya cabang terpisah dari `Navigator` yang sama). [_bloc] diambil
  /// di sini, di context yang benar, lalu wallet-nya diteruskan sebagai
  /// data biasa dan event hasil formulir dikirim balik ke bloc secara
  /// eksplisit — pola yang sama seperti `IncomeSourceEditSheet`.
  Future<void> _openRecordSheet(BuildContext context) async {
    final bloc = context.read<RecordBloc>()..add(const RecordWalletsLoaded());
    await bloc.stream.firstWhere((s) => !s.isLoading);
    if (!context.mounted) return;

    final choice = await showModalBottomSheet<RecordChoice>(
      context: context,
      builder: (_) => const RecordChoiceSheet(),
    );
    if (choice == null || !context.mounted) return;

    final wallets = bloc.state.wallets;
    final event = await showModalBottomSheet<RecordEvent>(
      context: context,
      isScrollControlled: true,
      builder: (_) => switch (choice) {
        RecordChoice.income => IncomeFormSheet(wallets: wallets),
        RecordChoice.expense => ExpenseFormSheet(wallets: wallets),
        RecordChoice.transfer => TransferFormSheet(wallets: wallets),
      },
    );
    if (event != null) bloc.add(event);
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
      _ComingSoonTab(icon: IconKey.transactions, label: t.appShell.transactionsTabLabel),
      _ComingSoonTab(icon: IconKey.wallets, label: t.appShell.walletsTabLabel),
    ];
    // PixelTheme membungkus SELURUH shell (tab + lembar CATAT yang dibuka
    // dari dalamnya) dengan bahasa visual ADR-015 -- lihat dokumentasi
    // kelas [PixelTheme]. Tema global (`AppTheme`/ADR-0006) tidak disentuh;
    // layar lama di luar shell ini tidak terpengaruh. Dipasang sebagai
    // pembungkus TERLUAR, di luar `ScopeWidget<RecordScope>`.
    return PixelTheme(
      child: ScopeWidget<RecordScope>(
        create: () => RecordScope(parentContainer: parentContainer),
        builder: (context, scope) {
          return BlocProvider.value(
            value: scope.container<RecordBloc>(),
            child: EffectListener<RecordBloc, RecordState>(
              // `Builder` di sini bukan hiasan: context yang dipakai
              // `_onDestinationSelected`/`_openRecordSheet` HARUS berada DI
              // BAWAH `BlocProvider` di atas supaya `context.read<RecordBloc>()`
              // menemukannya. Context milik parameter `builder` ScopeWidget
              // ATAU `build(BuildContext context)` di luar sini keduanya
              // leluhur `BlocProvider` ini, bukan keturunannya.
              child: Builder(
                builder: (context) => Scaffold(
                  body: IndexedStack(index: _activeTab, children: tabs),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: _navIndexFor(_activeTab),
                    onDestinationSelected: (navIndex) => _onDestinationSelected(context, navIndex),
                    destinations: [
                      NavigationDestination(icon: const AppIcon(IconKey.home), label: t.appShell.homeTabLabel),
                      NavigationDestination(icon: const AppIcon(IconKey.budget), label: t.appShell.budgetTabLabel),
                      NavigationDestination(icon: const AppIcon(IconKey.record), label: t.appShell.recordAction),
                      NavigationDestination(
                        icon: const AppIcon(IconKey.transactions),
                        label: t.appShell.transactionsTabLabel,
                      ),
                      NavigationDestination(icon: const AppIcon(IconKey.wallets), label: t.appShell.walletsTabLabel),
                    ],
                  ),
                ),
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
