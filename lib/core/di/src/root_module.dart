import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/features/cycle/data/adapters/cycle_income_writer_impl.dart';
import 'package:saldough/features/cycle/data/repositories/cycle_repository_impl.dart';
import 'package:saldough/features/cycle/data/roll_up/unavailable_roll_up_resolver.dart';
import 'package:saldough/features/cycle/presentation/navigation/cycle_route_module.dart';
import 'package:saldough/features/example_note/presentation/navigation/example_note_route_module.dart';
import 'package:saldough/features/income/presentation/navigation/income_route_module.dart';
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
    final storage = await HiveKeyValueStorage.initialize(boxName: 'saldough_kv');
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

  // `CycleIncomeWriter` adalah port milik fitur `worklog` (T-3.9), bukan
  // milik `cycle` — diimplementasikan di sini karena RootModule, bukan
  // fitur mana pun, yang boleh melihat data/domain kedua fitur untuk
  // mengawatnya (lihat catatan revisi ADR-0009). `CycleRepositoryImpl` di
  // sini adalah instance TERPISAH dari yang dipakai `CycleScope` — keduanya
  // menunjuk dokumen `KeyValueStorage` yang sama (satu-satunya sumber
  // kebenaran), jadi aman dipakai bersamaan tanpa cache yang bisa basi.
  static void _registerCrossFeatureAdapters(GetIt container) {
    container.registerLazySingleton<CycleIncomeWriter>(
      () => CycleIncomeWriterImpl(
        cycleRepository: CycleRepositoryImpl(
          storage: container<KeyValueStorage>(),
          resolver: const UnavailableRollUpResolver(),
        ),
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
      ),
    );
  }

  // Siklus bulan berjalan sebagai layar awal (Fase 2). Path GoRoute tidak
  // membawa parameter — id bulan berjalan dipasok lewat
  // CycleRouteModule.defaultInput, bukan lewat URL, karena initialLocation
  // dibuka tanpa `extra` (lihat RouteNodeGoRouterExt.toGoRoute).
  static const _initialLocation = '/cycle/detail';
}
