import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

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
/// Lembar CATAT juga masih isian sementara sampai T-2.4. Menukarnya jadi
/// layar sungguhan berarti mengganti satu entri di daftar `tabs` pada
/// `build`, atau isi [_AppShellPageState._openRecordSheet], bukan menulis
/// ulang shell ini.
///
/// Seluruh shell ini (tab dan lembar yang dibukanya) dibungkus
/// `PixelTheme` — bahasa visual ADR-015 (palet, tipografi, radius, garis
/// tepi). Layar dan lembar baru berikutnya otomatis mewarisinya cukup
/// dengan dirender di dalam shell ini, tanpa perlu membungkus dirinya
/// sendiri.
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

  void _onDestinationSelected(int navIndex) {
    if (navIndex == _recordNavIndex) {
      _openRecordSheet(context);
      return;
    }
    setState(() => _activeTab = _tabIndexFor(navIndex));
  }

  /// Lembar CATAT sementara. T-2.4 menggantinya dengan lembar pilihan
  /// pemasukan/pengeluaran/transfer yang sesungguhnya.
  void _openRecordSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(IconKey.record, size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(t.appShell.recordAction, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(t.appShell.comingSoonMessage, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
    // layar lama di luar shell ini tidak terpengaruh.
    return PixelTheme(
      child: Scaffold(
        body: IndexedStack(index: _activeTab, children: tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndexFor(_activeTab),
          onDestinationSelected: _onDestinationSelected,
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
