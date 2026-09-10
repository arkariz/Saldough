import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/features/example_note/presentation/navigation/example_note_route_module.dart';
import 'package:saldough/shared/goal/goal.dart';

/// Pendaftaran dependensi akar, dipanggil dari [DiBoot.run]. Urutannya
/// mengikat — lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap":
/// penyimpanan → repository lintas fitur → modul fitur → router.
abstract final class RootModule {
  RootModule._();

  /// Seluruh modul rute fitur yang terdaftar di aplikasi.
  ///
  /// ⚠ Daftar ini tumbuh manual tiap fitur baru ditambahkan — tidak ada
  /// penemuan otomatis, sesuai desain `FeatureRouteModule`.
  static const _featureModules = [ExampleNoteRouteModule()];

  /// Menjalankan seluruh pendaftaran akar ke [container].
  static Future<void> registerAll(GetIt container) async {
    await _registerStorage(container);
    _registerSharedRepositories(container);
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

  // Lihat T-1.12 — example_note adalah fitur bukti pola, belum ada layar
  // home sungguhan sampai Fase 2. Lokasi awal diarahkan ke sana sementara.
  static String get _initialLocation => '/example_note/list';
}
