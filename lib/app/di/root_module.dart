import 'package:api_storage/api_storage.dart';
import 'package:di/di.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_storage/hive_storage.dart';
import 'package:navigation/navigation.dart';
import 'package:saldough/app/shell/app_shell_page.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/foundation/analytics/app_bootstrap_firebase.dart';
import 'package:saldough/core/foundation/navigation/app_route_registry.dart';
import 'package:saldough/core/language/language.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/account/presentation/navigation/account_route_module.dart';
import 'package:saldough/features/budget/data/adapters/budget_item_catalog_impl.dart';
import 'package:saldough/features/budget/data/adapters/budget_overview_source_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_repository_impl.dart';
import 'package:saldough/features/budget/data/repositories/budget_template_repository_impl.dart';
import 'package:saldough/features/budget/domain/repositories/budget_repository.dart';
import 'package:saldough/features/budget/domain/repositories/budget_template_repository.dart';
import 'package:saldough/features/budget/presentation/navigation/budget_route_module.dart';
import 'package:saldough/features/freelance/data/adapters/freelance_overview_source_impl.dart';
import 'package:saldough/features/freelance/data/repositories/freelance_repository_impl.dart';
import 'package:saldough/features/freelance/domain/repositories/freelance_repository.dart';
import 'package:saldough/features/freelance/presentation/navigation/freelance_route_module.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/features/onboarding/presentation/onboarding_route.dart';
import 'package:saldough/features/onboarding/presentation/pages/onboarding_page.dart' show OnboardingOutcome;
import 'package:saldough/features/record/di/notification_capture_module.dart';
import 'package:saldough/features/record/presentation/navigation/record_route_module.dart';
import 'package:saldough/features/transaction/presentation/navigation/transaction_route_module.dart';
import 'package:saldough/features/wallet/presentation/navigation/wallet_route_module.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Pendaftaran dependensi akar, dipanggil dari [DiBoot.run]. Urutannya
/// mengikat — lihat ARCHITECTURE_OVERVIEW.md bagian "Bootstrap":
/// penyimpanan → repository bersama → modul fitur → router.
abstract final class RootModule {
  RootModule._();

  /// Seluruh modul rute fitur yang terdaftar di aplikasi (ADR-0004,
  /// ADR-030 §3.3). Fitur membuka layar fitur lain hanya lewat kunci rute,
  /// dan `pushRoute` mencari simpulnya di registri ini.
  ///
  /// ⚠ Daftar ini tumbuh manual tiap fitur baru ditambahkan — tidak ada
  /// penemuan otomatis, sesuai desain `FeatureRouteModule`.
  static const List<FeatureRouteModule> featureModules = [
    AccountRouteModule(),
    BudgetRouteModule(),
    FreelanceRouteModule(),
    RecordRouteModule(),
    TransactionRouteModule(),
    WalletRouteModule(),
  ];

  /// Menjalankan seluruh pendaftaran akar ke [container].
  static Future<void> registerAll(GetIt container) async {
    await _registerStorage(container);
    _registerSharedRepositories(container);
    final registry = _registerRouteRegistry(container);
    await _registerRouter(container, registry);
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
      // Satu instans untuk dua peran: buku besar, dan port migrasi label
      // kategori lama (ADR-026 §3.4) yang butuh tata letak buku besar.
      ..registerLazySingleton<TransactionRepositoryImpl>(
        () => TransactionRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      ..registerLazySingleton<TransactionRepository>(container.call<TransactionRepositoryImpl>)
      // Sinyal buku besar (ADR-030 §3.4): satu instans untuk seluruh scope.
      ..registerLazySingleton<LedgerChanges>(LedgerChanges.new)
      ..registerLazySingleton<LegacyCategoryLabels>(container.call<TransactionRepositoryImpl>)
      // Kategori (ADR-026), kunci `category/all`. Dipakai CATAT, Transaksi,
      // dan layar Kategori di Akun.
      ..registerLazySingleton<CategoryRepository>(
        () => CategoryRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Milik fitur `budget`, tetapi dibaca juga oleh CATAT dan rincian
      // transaksi lewat port — satu instans di akar (lihat `BudgetScope`).
      ..registerLazySingleton<BudgetRepository>(
        () => BudgetRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Template anggaran (T-7.1), kunci `budget_template/all`. Di akar
      // bersama `BudgetRepository` supaya `BudgetScope` cukup membawanya.
      ..registerLazySingleton<BudgetTemplateRepository>(
        () => BudgetTemplateRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Port milik `record` (pemilih pos anggaran CATAT, T-4.4),
      // diimplementasikan `budget` — pola port kecil ADR-0009.
      ..registerLazySingleton<BudgetItemCatalog>(
        () => BudgetItemCatalogImpl(repository: container<BudgetRepository>()),
      )
      // Port milik `home` (ringkasan anggaran Beranda, T-6.2),
      // diimplementasikan `budget` — pola port kecil ADR-0009.
      ..registerLazySingleton<BudgetOverviewSource>(
        () => BudgetOverviewSourceImpl(
          budgetRepository: container<BudgetRepository>(),
          transactionRepository: container<TransactionRepository>(),
        ),
      )
      // Milik fitur `freelance`, di akar karena `FreelanceScope` dibuat dan
      // dibuang tiap Ikhtisar Freelance dibuka (lihat `FreelanceScope`), dan
      // Beranda (Fase 6) akan membacanya juga.
      ..registerLazySingleton<FreelanceRepository>(
        () => FreelanceRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Port milik `home` (ringkasan freelance Beranda, T-6.3),
      // diimplementasikan `freelance`.
      ..registerLazySingleton<FreelanceOverviewSource>(
        () => FreelanceOverviewSourceImpl(repository: container<FreelanceRepository>()),
      )
      // Progres onboarding dan tur spotlight (ADR-021 §3.1), kunci
      // `tutorial/progress`. Bukan data keuangan.
      ..registerLazySingleton<TutorialProgressRepository>(
        () => TutorialProgressRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Pilihan bahasa (ADR-028), kunci `settings/language`. Mengganti bahasa
      // ikut mengganti nama kategori bawaan yang belum diganti pengguna.
      ..registerLazySingleton<LanguagePreferenceRepository>(
        () => LanguagePreferenceRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      ..registerLazySingleton<ChangeAppLanguage>(
        () => ChangeAppLanguage(
          repository: container<LanguagePreferenceRepository>(),
          afterChange: (from, to) async {
            await RelocalizeBuiltInCategories(repository: container<CategoryRepository>())(
              oldName: (key) => from.buildSync().category.builtIn[key],
              newName: (key) => to.buildSync().category.builtIn[key],
            );
          },
        ),
      )
      // Pertanyaan bahasa ucapan sekali untuk pengguna lama (ADR-028 §3.8).
      ..registerLazySingleton<SpeechLanguagePrompt>(
        () => SpeechLanguagePrompt(
          repository: container<LanguagePreferenceRepository>(),
          changeLanguage: container<ChangeAppLanguage>(),
        ),
      )
      // Pilihan mata uang (ADR-025 §3.5), kunci `settings/currency`.
      ..registerLazySingleton<CurrencyPreferenceRepository>(
        () => CurrencyPreferenceRepositoryImpl(storage: container<KeyValueStorage>()),
      )
      // Identitas opsional (ADR-023). Singleton akar karena status masuk
      // dibaca dari mana saja (ikon akun di Beranda) tanpa terikat satu
      // layar/scope.
      ..registerLazySingleton<AuthRepository>(FirebaseAuthRepositoryImpl.new);
    // Catat dari notifikasi (ADR-032): pemroses di akar, dipicu shell.
    NotificationCaptureModule.register(container);
  }

  static RouteRegistry _registerRouteRegistry(GetIt container) {
    final registry = RouteRegistry.fromModules(featureModules);
    container.registerSingleton<RouteRegistry>(registry);
    return registry;
  }

  static Future<void> _registerRouter(GetIt container, RouteRegistry registry) async {
    container.registerSingleton<GoRouter>(
      AppRouteRegistry.build(
        registry: registry,
        initialLocation: await _initialLocation(container),
        homeBuilder: (context, state) => AppShellPage(
          startAction: switch (state.extra) {
            OnboardingOutcome.createWallet => ShellStartAction.createWallet,
            OnboardingOutcome.signIn => ShellStartAction.openAccount,
            _ => null,
          },
        ),
        onboardingBuilder: buildOnboardingRoute,
        // `screen_view` otomatis (ADR-023) -- belum ada event kustom.
        observers: [AppBootstrap.analyticsObserver],
      ),
    );
  }

  // Shell navigasi Saldough 2.0 (`AppShellPage`, lima slot navigasi bawah)
  // di `/home` adalah layar awal -- kecuali onboarding belum selesai di
  // perangkat ini (ADR-021 §3.2, KO-1). Dibaca sekali di sini, sebelum
  // `runApp`, jadi tidak ada frame yang berkedip. Dokumen progres rusak
  // dianggap belum dilihat.
  static Future<String> _initialLocation(GetIt container) async {
    final progress = (await container<TutorialProgressRepository>().load()).getOrElse((_) => TutorialProgress.empty);
    return progress.onboardingDone ? AppRouteRegistry.homePath : AppRouteRegistry.onboardingPath;
  }
}
