import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/card/di/card_scope.dart';
import 'package:saldough/features/card/presentation/bloc/card_bloc.dart';
import 'package:saldough/features/card/presentation/pages/card_page.dart';
import 'package:saldough/features/cycle/di/cycle_scope.dart';
import 'package:saldough/features/cycle/presentation/bloc/cycle_bloc.dart';
import 'package:saldough/features/cycle/presentation/pages/cycle_page.dart';
import 'package:saldough/features/grocery/di/grocery_scope.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';
import 'package:saldough/features/grocery/presentation/pages/grocery_page.dart';
import 'package:saldough/features/income/di/income_scope.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_bloc.dart';
import 'package:saldough/features/income/presentation/pages/income_source_list_page.dart';
import 'package:saldough/features/investment/di/investment_scope.dart';
import 'package:saldough/features/investment/presentation/bloc/investment_bloc.dart';
import 'package:saldough/features/investment/presentation/pages/investment_page.dart';
import 'package:state_management/state_management.dart';

/// Shell navigasi utama — bottom navigation bar 4 tab (Siklus/Pemasukan/
/// Belanja/Investasi), meniru struktur Design Canvas prototipe komik.
///
/// Satu-satunya tempat di `core/` yang boleh mengimpor presentation+DI
/// kelima fitur ini langsung — `RootModule` sudah melakukan hal serupa
/// untuk modul rute masing-masing, jadi ini bukan pelanggaran baru terhadap
/// "fitur privat, tidak diimpor fitur lain" (ADR-0009): shell ini, seperti
/// `RootModule`, memang dirancang untuk melihat banyak fitur sekaligus.
///
/// Setiap tab tetap dipasang lewat `ScopeWidget` milik fiturnya sendiri,
/// pola yang sama seperti di `XRouteModule` masing-masing — shell ini
/// TIDAK menjadi lingkup dependensi baru, hanya menata widget.
/// `IndexedStack` menjaga tiap tab (termasuk scroll position dan bloc)
/// tetap hidup saat berpindah tab, bukan dibangun ulang dari nol.
///
/// Worklog (dari tab Pemasukan) BUKAN tab tersendiri — dicapai lewat
/// `NavigatePushEffect` yang didorong tombol di layar Pemasukan (lihat
/// `IncomeSourceBloc`), tampil sebagai layar yang menutupi bottom nav.
/// Kartu Kredit SEBALIKNYA sekarang SUB-TAB di dalam tab Belanja (lewat
/// `TabBar`, bukan `NavigatePushEffect` lagi) — permintaan pemilik supaya
/// Belanja dan Kartu Kredit masing-masing punya bagian sendiri tanpa
/// menambah ikon baru di bottom nav. Lihat `_GroceryCardTab`.
class MainShellPage extends StatefulWidget {
  /// Membuat [MainShellPage].
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final parentContainer = ScopeProvider.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _CycleTab(parentContainer: parentContainer, isActive: _index == 0),
          _IncomeTab(parentContainer: parentContainer),
          _GroceryCardTab(parentContainer: parentContainer),
          _InvestmentTab(parentContainer: parentContainer),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calendar_month), label: t.shell.cycleTabLabel),
          NavigationDestination(icon: const Icon(Icons.payments), label: t.shell.incomeTabLabel),
          NavigationDestination(icon: const Icon(Icons.shopping_cart), label: t.shell.groceryTabLabel),
          NavigationDestination(icon: const Icon(Icons.savings), label: t.shell.investmentTabLabel),
        ],
      ),
    );
  }
}

// Siklus bulan berjalan sebagai tab awal — sama seperti
// `CycleRouteModule._currentCycleId` dan `currentCycleId()` di
// `investment_state.dart`, duplikasi kecil yang sudah ada sebelumnya
// (bukan pola baru yang diperkenalkan shell ini).
String _currentCycleId() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

class _CycleTab extends StatefulWidget {
  const _CycleTab({required this.parentContainer, required this.isActive});

  final GetIt parentContainer;

  /// True kalau tab ini yang sedang tampil di bottom nav.
  final bool isActive;

  @override
  State<_CycleTab> createState() => _CycleTabState();
}

class _CycleTabState extends State<_CycleTab> {
  CycleBloc? _bloc;

  @override
  void didUpdateWidget(_CycleTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tab ini baru saja diaktifkan kembali lewat bottom nav (balik dari
    // Pemasukan/Belanja). Sumber pemasukan, rencana belanja, atau kartu bisa
    // saja baru disunting di tab lain itu sejak siklus ini terakhir dimuat --
    // tanpa muat ulang di sini, baris pemasukan/anggaran yang tertaut tidak
    // pernah menyegarkan label/nominalnya di layar, dan sumber pemasukan baru
    // tidak terdeteksi saat menambah baris (laporan pemilik). Muat ulang
    // SIKLUS YANG SAMA (bukan reset ke bulan berjalan) supaya pilihan
    // navigasi chevron pemilik tidak ditimpa balik -- kebalikan dari
    // penjaga UX-07 di `build`, yang justru mencegah muat ulang berulang
    // saat tab TIDAK benar-benar berpindah.
    if (!oldWidget.isActive && widget.isActive) {
      final bloc = _bloc;
      if (bloc != null && bloc.state.cycle.id.isNotEmpty) {
        bloc.add(CycleOpened(bloc.state.cycle.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<CycleScope>(
      create: () => CycleScope(parentContainer: widget.parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<CycleBloc>();
        _bloc = bloc;
        // UX-07: `builder` jalan lagi setiap kali tab ini pindah (rebuild
        // `IndexedStack` induk), bukan hanya sekali. Pancarkan `CycleOpened`
        // hanya saat bloc benar-benar belum memuat siklus mana pun --
        // supaya posisi navigasi bulan yang dipilih pemilik (chevron) tidak
        // ditimpa balik ke bulan berjalan tiap kali balik ke tab ini. Muat
        // ulang saat tab DIAKTIFKAN lagi ditangani `didUpdateWidget` di atas.
        final cycleId = bloc.state.cycle.id.isEmpty ? _currentCycleId() : bloc.state.cycle.id;
        if (bloc.state.cycle.id.isEmpty) bloc.add(CycleOpened(cycleId));
        return BlocProvider.value(value: bloc, child: CyclePage(cycleId: cycleId));
      },
    );
  }
}

class _IncomeTab extends StatelessWidget {
  const _IncomeTab({required this.parentContainer});

  final GetIt parentContainer;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<IncomeScope>(
      create: () => IncomeScope(parentContainer: parentContainer),
      builder: (context, scope) => BlocProvider.value(
        value: scope.container<IncomeSourceBloc>()..add(const IncomeSourcesLoaded()),
        child: const IncomeSourceListPage(),
      ),
    );
  }
}

/// Tab "Belanja" — Rencana Belanja dan Kartu Kredit sebagai DUA sub-tab
/// (`TabBar`) di bawah satu `AppBar`, bukan lagi satu layar dengan tombol
/// yang men-`push` layar kartu (laporan pemilik: masing-masing ingin jadi
/// bagiannya sendiri). Kedua fitur tetap punya `ScopeWidget`/bloc masing-
/// masing (ADR-0009) — yang baru hanya TATA LETAKnya, disusun bersarang di
/// sini karena shell memang satu-satunya tempat yang boleh melihat lebih
/// dari satu fitur sekaligus (lihat catatan kelas `MainShellPage`).
class _GroceryCardTab extends StatefulWidget {
  const _GroceryCardTab({required this.parentContainer});

  final GetIt parentContainer;

  @override
  State<_GroceryCardTab> createState() => _GroceryCardTabState();
}

class _GroceryCardTabState extends State<_GroceryCardTab> {
  // UX-17: builder tiap ScopeWidget jalan lagi setiap pindah tab (sama
  // seperti UX-07 di _CycleTab) -- tanpa penjaga ini, GroceryPlanLoaded/
  // CardOpened terpancar ulang tiap kali tab Belanja ini pindah (bukan
  // hanya saat sub-tab Belanja/Kartu sendiri yang berpindah).
  bool _dispatchedGroceryLoad = false;
  bool _dispatchedCardLoad = false;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<GroceryScope>(
      create: () => GroceryScope(parentContainer: widget.parentContainer),
      builder: (context, groceryScope) {
        final groceryBloc = groceryScope.container<GroceryBloc>();
        if (!_dispatchedGroceryLoad) {
          _dispatchedGroceryLoad = true;
          groceryBloc.add(const GroceryPlanLoaded());
        }
        return ScopeWidget<CardScope>(
          create: () => CardScope(parentContainer: widget.parentContainer),
          builder: (context, cardScope) {
            final cardBloc = cardScope.container<CardBloc>();
            if (!_dispatchedCardLoad) {
              _dispatchedCardLoad = true;
              cardBloc.add(const CardOpened());
            }
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: groceryBloc),
                BlocProvider.value(value: cardBloc),
              ],
              child: const _GroceryCardTabView(),
            );
          },
        );
      },
    );
  }
}

class _GroceryCardTabView extends StatelessWidget {
  const _GroceryCardTabView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.shell.groceryTabLabel),
          bottom: TabBar(
            tabs: [
              Tab(text: t.grocery.pageTitle),
              Tab(text: t.card.pageTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            GroceryPage(embedded: true),
            CardPage(embedded: true),
          ],
        ),
      ),
    );
  }
}

class _InvestmentTab extends StatelessWidget {
  const _InvestmentTab({required this.parentContainer});

  final GetIt parentContainer;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<InvestmentScope>(
      create: () => InvestmentScope(parentContainer: parentContainer),
      builder: (context, scope) => BlocProvider.value(
        value: scope.container<InvestmentBloc>()..add(const InvestmentOpened()),
        child: const InvestmentPage(),
      ),
    );
  }
}
