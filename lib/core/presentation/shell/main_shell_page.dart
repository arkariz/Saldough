import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
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
/// keempat fitur ini langsung — `RootModule` sudah melakukan hal serupa
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
/// Worklog (dari tab Pemasukan) dan Card (dari tab Belanja) BUKAN tab
/// tersendiri — keduanya dicapai lewat `NavigatePushEffect` yang didorong
/// tombol di layar masing-masing (lihat `IncomeSourceBloc`/`GroceryBloc`),
/// tampil sebagai layar yang menutupi bottom nav, sesuai alur di Design
/// Canvas.
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
          _CycleTab(parentContainer: parentContainer),
          _IncomeTab(parentContainer: parentContainer),
          _GroceryTab(parentContainer: parentContainer),
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

class _CycleTab extends StatelessWidget {
  const _CycleTab({required this.parentContainer});

  final GetIt parentContainer;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<CycleScope>(
      create: () => CycleScope(parentContainer: parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<CycleBloc>();
        // UX-07: `builder` jalan lagi setiap kali tab ini pindah (rebuild
        // `IndexedStack` induk), bukan hanya sekali. Pancarkan `CycleOpened`
        // hanya saat bloc benar-benar belum memuat siklus mana pun --
        // supaya posisi navigasi bulan yang dipilih pemilik (chevron) tidak
        // ditimpa balik ke bulan berjalan tiap kali balik ke tab ini.
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

class _GroceryTab extends StatefulWidget {
  const _GroceryTab({required this.parentContainer});

  final GetIt parentContainer;

  @override
  State<_GroceryTab> createState() => _GroceryTabState();
}

class _GroceryTabState extends State<_GroceryTab> {
  // UX-17: builder ScopeWidget jalan lagi setiap pindah tab (sama seperti
  // UX-07 di _CycleTab) -- tanpa penjaga ini, GroceryPlanLoaded terpancar
  // ulang tiap kali, dan grocery_page.dart mengganti SELURUH body dengan
  // spinner (membuang posisi scroll) padahal datanya sudah ada.
  bool _dispatchedInitialLoad = false;

  @override
  Widget build(BuildContext context) {
    return ScopeWidget<GroceryScope>(
      create: () => GroceryScope(parentContainer: widget.parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<GroceryBloc>();
        if (!_dispatchedInitialLoad) {
          _dispatchedInitialLoad = true;
          bloc.add(const GroceryPlanLoaded());
        }
        return BlocProvider.value(value: bloc, child: const GroceryPage());
      },
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
