import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/example_note/presentation/navigation/example_note_route_module.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pendaftaran dependensi akar, dipanggil dari [DiBoot.run]. Urutannya
/// mengikat — lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap":
/// penyimpanan → repository bersama → modul fitur → router.
abstract final class RootModule {
  RootModule._();

  /// Seluruh modul rute fitur yang terdaftar di aplikasi.
  ///
  /// ⚠ Daftar ini tumbuh manual tiap fitur baru ditambahkan — tidak ada
  /// penemuan otomatis, sesuai desain `FeatureRouteModule`. `example_note`
  /// tetap terdaftar sebagai fitur bukti pola (lihat T-1.12), dapat dicapai
  /// lewat menu pengembang mode debug, bukan lagi lokasi awal.
  static const List<FeatureRouteModule> _featureModules = [
    ExampleNoteRouteModule(),
  ];

  /// Menjalankan seluruh pendaftaran akar ke [container].
  static Future<void> registerAll(GetIt container) async {
    await _registerStorage(container);
    _registerSharedRepositories(container);
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
    container
      ..registerLazySingleton<WalletRepository>(
        () => WalletRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      ..registerLazySingleton<TransactionRepository>(
        () => TransactionRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Milik fitur `budget`, tetapi dibaca juga oleh CATAT dan rincian
      // transaksi lewat port — satu instans di akar (lihat `BudgetScope`).
      ..registerLazySingleton<BudgetRepository>(
        () => BudgetRepositoryImpl(storage: container<KeyValueStorage>()),
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
        homeBuilder: (context) => const AppShellPage(),
      ),
    );
  }

  // Shell navigasi Saldough 2.0 (`AppShellPage`, lima slot navigasi bawah)
  // sebagai layar awal. Sejak cutover T-3.4 ia menempati `/home`, bukan lagi
  // rute sementara `/shell`.
  static const String _initialLocation = AppRouteRegistry.homePath;
}
