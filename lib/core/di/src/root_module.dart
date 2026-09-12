import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/presentation/shell/main_shell_page.dart';
import 'package:saldough/features/card/data/adapters/card_catalog_impl.dart';
import 'package:saldough/features/card/data/card_roll_up_resolver.dart';
import 'package:saldough/features/card/data/repositories/card_statement_repository_impl.dart';
import 'package:saldough/features/card/data/repositories/credit_card_repository_impl.dart';
import 'package:saldough/features/card/presentation/navigation/card_route_module.dart';
import 'package:saldough/features/cycle/data/adapters/cycle_income_writer_impl.dart';
import 'package:saldough/features/cycle/data/adapters/cycle_investment_gateway_impl.dart';
import 'package:saldough/features/cycle/data/adapters/grocery_cycle_gateway_impl.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_repository_impl.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';
import 'package:saldough/features/cycle/presentation/navigation/cycle_route_module.dart';
import 'package:saldough/features/example_note/presentation/navigation/example_note_route_module.dart';
import 'package:saldough/features/grocery/data/grocery_roll_up_resolver.dart';
import 'package:saldough/features/grocery/data/repositories/grocery_plan_repository_impl.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_cycle_gateway.dart';
import 'package:saldough/features/grocery/presentation/navigation/grocery_route_module.dart';
import 'package:saldough/features/income/domain/repositories/income_worklog_gateway.dart';
import 'package:saldough/features/income/presentation/navigation/income_route_module.dart';
import 'package:saldough/features/investment/domain/repositories/cycle_investment_gateway.dart';
import 'package:saldough/features/investment/presentation/navigation/investment_route_module.dart';
import 'package:saldough/features/worklog/data/adapters/income_worklog_gateway_impl.dart';
import 'package:saldough/features/worklog/data/repositories/worklog_repository_impl.dart';
import 'package:saldough/features/worklog/domain/repositories/cycle_income_writer.dart';
import 'package:saldough/features/worklog/presentation/navigation/worklog_route_module.dart';
import 'package:saldough/shared/goal/goal.dart';
import 'package:saldough/shared/income/income.dart';

/// Pendaftaran dependensi akar, dipanggil dari [DiBoot.run]. Urutannya
/// mengikat — lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap":
/// penyimpanan → repository lintas fitur → modul fitur → router.
abstract final class RootModule {
  RootModule._();

  /// Seluruh modul rute fitur yang terdaftar di aplikasi.
  ///
  /// ⚠ Daftar ini tumbuh manual tiap fitur baru ditambahkan — tidak ada
  /// penemuan otomatis, sesuai desain `FeatureRouteModule`. `example_note`
  /// tetap terdaftar sebagai fitur bukti pola (lihat T-1.12), dapat dicapai
  /// lewat menu pengembang mode debug, bukan lagi lokasi awal.
  static const List<FeatureRouteModule> _featureModules = [
    CycleRouteModule(),
    IncomeRouteModule(),
    WorklogRouteModule(),
    GroceryRouteModule(),
    CardRouteModule(),
    InvestmentRouteModule(),
    ExampleNoteRouteModule(),
  ];

  /// Menjalankan seluruh pendaftaran akar ke [container].
  static Future<void> registerAll(GetIt container) async {
    await _registerStorage(container);
    _registerSharedRepositories(container);
    _registerCrossFeatureAdapters(container);
    final registry = _registerRouteRegistry(container);
    _registerRouter(container, registry);
  }

  static Future<void> _registerStorage(GetIt container) async {
    final storage = await HiveKeyValueStorage.initialize(
      boxName: 'saldough_kv',
    );
    container.registerSingleton<KeyValueStorage>(storage);
  }

  static void _registerSharedRepositories(GetIt container) {
    container.registerLazySingleton<GoalRepository>(
      () => GoalRepositoryImpl(storage: container<KeyValueStorage>()),
    );
    container.registerLazySingleton<IncomeSourceRepository>(
      () => IncomeSourceRepositoryImpl(storage: container<KeyValueStorage>()),
    );
  }

  // `RollUpResolver` adalah antarmuka milik `cycle` (Fase 2), diimplementasi
  // fitur sumber datanya sendiri — `grocery` (`GroceryRollUpResolver`) dan
  // `card` (`CardRollUpResolver`, T-4.6-T-4.12), masing-masing hanya
  // menangani sumbernya sendiri dan jatuh ke `unavailable()` untuk sumber
  // lain. `_CompositeRollUpResolver` di bawah menggabungkan keduanya di
  // belakang satu `RollUpResolver`, mendelegasikan berdasar tipe
  // `RollUpSource` — lihat catatan revisi di roll_up_resolver.dart.
  //
  // `CycleIncomeWriter` adalah port milik fitur `worklog` (T-3.9), bukan
  // milik `cycle` — diimplementasikan di sini karena RootModule, bukan
  // fitur mana pun, yang boleh melihat data/domain lebih dari satu fitur
  // untuk mengawatnya (lihat catatan revisi ADR-0009). `CycleRepositoryImpl`
  // di sini adalah instance TERPISAH dari yang dipakai `CycleScope` — sama
  // seperti `GroceryPlanRepositoryImpl`/`CardStatementRepositoryImpl` di
  // bawah, semuanya menunjuk dokumen `KeyValueStorage` yang sama
  // (satu-satunya sumber kebenaran), jadi aman dipakai bersamaan tanpa
  // cache yang bisa basi.
  static void _registerCrossFeatureAdapters(GetIt container) {
    container.registerLazySingleton<RollUpResolver>(
      () => _CompositeRollUpResolver(
        grocery: GroceryRollUpResolver(
          repository: GroceryPlanRepositoryImpl(
            storage: container<KeyValueStorage>(),
          ),
        ),
        card: CardRollUpResolver(
          repository: CardStatementRepositoryImpl(
            storage: container<KeyValueStorage>(),
          ),
        ),
      ),
    );
    container.registerLazySingleton<CycleIncomeWriter>(
      () => CycleIncomeWriterImpl(
        cycleRepository: CycleRepositoryImpl(
          storage: container<KeyValueStorage>(),
          resolver: container<RollUpResolver>(),
          incomeSourceRepository: container<IncomeSourceRepository>(),
        ),
      ),
    );
    // `CycleInvestmentGateway` adalah port milik fitur `investment` (T-5.3,
    // T-5.7), bukan milik `cycle` — pola baca+tulis yang sama seperti
    // `CycleIncomeWriter` di atas, hanya arahnya dua arah.
    container.registerLazySingleton<CycleInvestmentGateway>(
      () => CycleInvestmentGatewayImpl(
        cycleRepository: CycleRepositoryImpl(
          storage: container<KeyValueStorage>(),
          resolver: container<RollUpResolver>(),
          incomeSourceRepository: container<IncomeSourceRepository>(),
        ),
      ),
    );
    // `CardCatalog` adalah port milik fitur `cycle` — layar siklus perlu
    // daftar kartu (hanya id+nama) untuk menautkan baris anggaran baru ke
    // tagihan kartu tertentu (laporan pemilik: sebelumnya tidak ada cara
    // melakukan ini dari UI). Arahnya baca-saja, beda dari
    // `CycleIncomeWriter`/`CycleInvestmentGateway` di atas yang juga menulis.
    container.registerLazySingleton<CardCatalog>(
      () => CardCatalogImpl(
        repository: CreditCardRepositoryImpl(storage: container<KeyValueStorage>()),
      ),
    );
    // `GroceryCycleGateway` adalah port milik fitur `grocery` — layar
    // Rencana Belanja perlu daftar `id` siklus untuk memilih bulan mana yang
    // sedang dilihat/disunting (tautan 1:1 `GroceryPlan`↔`MonthlyCycle`,
    // laporan pemilik), pola baca-saja yang sama seperti `CardCatalog`.
    container.registerLazySingleton<GroceryCycleGateway>(
      () => GroceryCycleGatewayImpl(
        cycleRepository: CycleRepositoryImpl(
          storage: container<KeyValueStorage>(),
          resolver: container<RollUpResolver>(),
          incomeSourceRepository: container<IncomeSourceRepository>(),
        ),
      ),
    );
    // `IncomeWorklogGateway` adalah port milik fitur `income` — layar
    // Sumber Pemasukan perlu ringkasan buku jam TERBUKA tiap sumber
    // freelance, supaya tiap tile menampilkannya sendiri beserta tombol
    // langsung ke layar catatan jam kerja (laporan pemilik: alur sumber
    // freelance → catat jam → suntik ke siklus terasa membingungkan).
    // Pola baca-saja yang sama seperti `CardCatalog`/`GroceryCycleGateway`.
    container.registerLazySingleton<IncomeWorklogGateway>(
      () => IncomeWorklogGatewayImpl(
        repository: WorklogRepositoryImpl(storage: container<KeyValueStorage>()),
      ),
    );
  }

  static RouteRegistry _registerRouteRegistry(GetIt container) {
    final registry = RouteRegistry.fromModules(_featureModules);
    container.registerSingleton<RouteRegistry>(registry);
    return registry;
  }

  static void _registerRouter(GetIt container, RouteRegistry registry) {
    container.registerSingleton<GoRouter>(
      AppRouteRegistry.build(
        registry: registry,
        initialLocation: _initialLocation,
        homeBuilder: (context) => const MainShellPage(),
      ),
    );
  }

  // Shell navigasi utama (`MainShellPage`, bottom nav 4 tab) sebagai layar
  // awal sejak wiring navigasi lintas fitur — sebelumnya layar siklus
  // bulanan langsung (Fase 2), kini salah satu tab di dalam shell.
  static const String _initialLocation = AppRouteRegistry.homePath;
}

/// Menggabungkan resolver roll-up tiap fitur sumber (`grocery`, `card`) jadi
/// satu [RollUpResolver], mendelegasikan berdasar tipe [RollUpSource] —
/// lihat catatan di [RootModule._registerCrossFeatureAdapters]. Tinggal di
/// sini (bukan di `features/cycle/`) karena menggabungkan tipe dari dua
/// fitur sekaligus, sama seperti alasan port lintas-fitur lain dikawat di
/// `RootModule` (ADR-0009).
final class _CompositeRollUpResolver implements RollUpResolver {
  const _CompositeRollUpResolver({required this._grocery, required this._card});

  final RollUpResolver _grocery;
  final RollUpResolver _card;

  @override
  Future<RollUpResolution> resolve(RollUpSource source) {
    return switch (source) {
      GroceryRollUpSource() => _grocery.resolve(source),
      CardRollUpSource() => _card.resolve(source),
    };
  }
}
