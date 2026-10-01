# Gambaran arsitektur

Dokumen ini menjelaskan bagaimana Saldough disusun: lapisan, struktur folder,
paket yang dipakai, dan cara sebuah fitur ditulis dari ujung ke ujung. Ini
dokumen teknis utama proyek.

Baca [DOMAIN_MODEL.md](DOMAIN_MODEL.md) lebih dulu kalau belum paham entitas
dan rumusnya. Setiap keputusan besar di sini punya ADR tersendiri yang
menjelaskan alasannya; tautannya disebutkan di tempatnya masing-masing.

## Dasar keputusan

Saldough menggabungkan tiga sumber acuan dengan peran berbeda.

**Struktur dan mesin runtime** diambil dari
`arkariz/flutter-architecture-studi-bank` (branch `refactor/platform-migration`,
folder `lib/v2`) — aplikasi mobile banking produksi yang memakai paket
**mobile-platform** dari GitLab privat, counterpart persis dari
`arkariz/advance-mobile-platform` (GitHub publik) yang dikonsumsi Saldough.
Nama paket dan versi tag-nya identik (`failures-v2.0.2`,
`state_management-v2.2.0`, `navigation-v1.1.1`, `di-v1.1.2`, dst.), sehingga
konvensi yang divalidasi di sana berlaku langsung untuk Saldough: tiga zona
folder `core`/`shared`/`features` ([ADR-0009](adr/0009-core-shared-features-zone-layout.md)),
`Either<Failure, T>` untuk kesalahan ([ADR-0005](adr/0005-either-failure-convention.md)),
efek bloc lewat `package:state_management` ([ADR-0003](adr/0003-effect-bloc-state-management.md)),
dan navigasi lewat `package:navigation` ([ADR-0004](adr/0004-typed-route-registry-navigation.md)).

**Pola teknis tema** diambil dari `arkariz/new-health-duel` (struktur
`core/theme/`, mekanisme `ThemeExtension`) — repo acuan arsitektur memakai
`mobile_dsl`, design system privat yang tidak bisa diakses, sehingga perannya
di Saldough terbatas pada struktur kode. **Bahasa visualnya** (palet gaya
komik/meme, pasangan huruf Archivo Black/Space Grotesk/Bangers) bukan dari
`new-health-duel` maupun repo acuan lain — itu keputusan gaya pemilik
langsung, diverifikasi lewat Design Canvas sebelum diterapkan.
Lihat [ADR-0006](adr/0006-design-token-semantic-color-mapping.md).

Repositori `flutter-architecture-studi` (tanpa `-bank`) **tidak** dipakai.
Folder `lib/v2` yang semula disebut tidak ada di repositori itu — yang ada
`lib/app`, memakai Riverpod, bertentangan dengan `package:state_management`.

### Bagian repo acuan yang sengaja TIDAK disalin

`flutter-architecture-studi-bank` sedang migrasi dari GetX legacy ke stack ini
(pola *Strangler Fig*). Saldough greenfield tidak punya legacy, sehingga
bagian berikut tidak relevan dan tidak disalin dalam bentuk apa pun:

| Bagian repo acuan | Kenapa tidak disalin |
|---|---|
| `ArchitectureBride*`, seam `Get.find()`/`Get.put()` | Jembatan boot dari GetX legacy ke shell v2 — Saldough tidak punya legacy untuk dijembatani |
| `getx_nav_effect_handler`, `StartupDestination` legacy | Spesifik migrasi, tidak ada "legacy" di Saldough |
| `mobile_dsl` | Design system privat mereka — Saldough pakai pola teknis `ThemeExtension` dari `new-health-duel`, palet/tipografi (gaya komik/meme) orisinal |
| Ejaan `fondation`, `architecture_bride` | Typo konsisten di repo mereka — Saldough pakai ejaan baku `foundation/` |

Yang dipertahankan dari urutan boot mereka hanyalah **urutannya**: pasang
`Bloc.observer` → jalankan `di.run()` → daftarkan effect handler → render
router → jalankan `di.warmUp()` setelah frame pertama. Saldough tetap
`main()` → `runApp()` langsung, tanpa jembatan apa pun.

## Lapisan

Saldough memakai tiga lapisan dengan aturan ketergantungan searah. Panah
menunjuk arah ketergantungan yang diizinkan.

```
presentation  ──►  domain  ◄──  data
     │                            │
     └──────────►  core  ◄────────┘
```

| Lapisan | Isi | Boleh bergantung pada |
|---|---|---|
| `domain` | Entitas, antarmuka repository, use case | Tidak ada. Dart murni. |
| `data` | Model serialisasi, sumber data, implementasi repository | `domain`, `core` |
| `presentation` | Bloc, state, halaman, widget | `domain`, `core` |
| `core` | Tema, terjemahan, infrastruktur rute dan efek, widget bersama, tanpa makna bisnis | Paket eksternal |
| `app` | Akar komposisi: `RootModule`, `SaldoughApp`, `AppShellPage` | Semua zona |

Aturan yang paling sering dilanggar dan paling penting dijaga: **lapisan domain
tidak boleh mengimpor Flutter**. Tidak `material.dart`, tidak `widgets.dart`,
tidak Hive, tidak `api_storage`. Domain berisi rumus keuangan, dan rumus itu
harus bisa diuji tanpa menjalankan Flutter.

Lapisan `presentation` tidak pernah mengimpor `data`. Keduanya bertemu di
`domain` lewat antarmuka repository, dan disambungkan di modul dependensi fitur.

`lib/app/` adalah satu-satunya tempat (bersama `main.dart`) yang boleh melihat
semua fitur; `core/` tidak mengimpor `shared/` maupun `features/`
([ADR-030](adr/0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md)
§3.1). Seluruh aturan impor ini dijaga `test/architecture/import_boundaries_test.dart`.

## Struktur folder

Saldough memakai tiga zona tidak tumpang tindih — `core/`, `shared/<module>/`,
`features/<feature>/` — sesuai [ADR-0009](adr/0009-core-shared-features-zone-layout.md).
Ini mengganti asumsi feature-first sederhana dari rencana awal, yang tidak
punya jawaban untuk di mana entitas lintas fitur (seperti `Wallet` dan
`Transaction`) seharusnya tinggal.

```
saldough/
├── assets/i18n/{id,en}.i18n.json         # bahasa dasar id
├── lib/
│   ├── main.dart                         # bootstrap dua fase
│   ├── app/                              # AKAR KOMPOSISI (ADR-030 §3.1)
│   │   ├── app.dart                      # SaldoughApp, MaterialApp.router
│   │   ├── di/{di.dart, root_module.dart}   # DiBoot, RootModule (+ featureModules)
│   │   └── shell/app_shell_page.dart     # empat tab + tombol CATAT/suara
│   ├── core/                             # infra lintas fitur, TANPA makna bisnis
│   │   ├── foundation/
│   │   │   ├── effect_handler/           # penangan efek baku, feedbackSnackBar
│   │   │   ├── navigation/               # AppRouteRegistry, RouteNodeGoRouterExt, pushRoute
│   │   │   ├── analytics/                # Firebase Analytics, Crashlytics, App Check (ADR-023)
│   │   │   └── repository_guard.dart     # mixin RepositoryGuard — ADR-0005
│   │   ├── theme/                        # tema global PixelTheme (ADR-031), token, AppColorsExtension
│   │   ├── presentation/                 # widget bersama (AppCard, AppForm*, RunOnce), spotlight, motion
│   │   ├── utils/formatters/             # uang (AppMoneyFormatter, money_input) dan tanggal
│   │   ├── currency/  language/  tutorial/  config/
│   │   └── i18n/                         # keluaran slang
│   ├── shared/                           # kapabilitas dipakai ≥2 fitur, module-first
│   │   ├── wallet/                       # wallet.dart (domain+data), wallet_presentation.dart
│   │   ├── transaction/                  # + LedgerChanges, transaction_query, transaction_presentation.dart
│   │   ├── category/                     # ADR-026; category_presentation.dart
│   │   ├── budget_catalog/               # port baca BudgetItemCatalog (ADR-030 §3.5)
│   │   └── auth/                         # identitas opsional (ADR-023/024); auth_presentation.dart
│   └── features/                         # graf milik satu fitur
│       ├── home/                         # ringkasan; domain/ hanya berisi port
│       ├── wallet/  transaction/  budget/  freelance/  account/  onboarding/
│       └── record/                       # CATAT — satu-satunya penulis transaksi manual; capture/ (ADR-027/029)
└── test/                                 # cermin lib/, + architecture/ dan helpers/
```

Setiap `features/<feature>/` punya susunan internal yang sama — `domain/`
dan `data/` privat (tidak diimpor fitur lain), `presentation/`, dan `di/`:

```
features/budget/
├── data/
│   ├── adapters/          # implementasi port milik fitur lain (pola port ADR-0009)
│   ├── models/            # model serialisasi dengan fromJson dan toJson
│   └── repositories/      # implementasi antarmuka domain, with RepositoryGuard
├── di/
│   └── budget_scope.dart  # IsolatedScope
├── domain/
│   ├── entities/          # Budget, BudgetItem, BudgetTemplate
│   ├── repositories/      # abstract interface class
│   └── usecases/          # CalculateBudgetProgress
└── presentation/
    ├── bloc/              # budget_bloc.dart + part budget_effect/budget_event, budget_state.dart
    ├── navigation/
    │   ├── budget_route_keys.dart        # SATU-SATUNYA berkas yang boleh diimpor fitur lain
    │   └── budget_route_module.dart      # RouteNode + scope milik rute
    ├── pages/             # halaman besar dipecah ke part *_sections.dart
    └── widgets/
```

Fitur `home` hanya berisi `presentation/`, `di/`, dan `domain/` untuk **port**
miliknya (`BudgetOverviewSource`, `FreelanceOverviewSource`), yang
implementasinya ada di `data/adapters/` fitur penyedia dan dikawat di
`RootModule`. Port **baca** yang dipakai ≥2 fitur tinggal di `shared/`
(`shared/budget_catalog/`, dipakai `record` dan `transaction`); port **tulis**
tetap milik fitur konsumen. `record` punya `domain/capture/` dan
`data/capture/` untuk Catat Cerdas (ADR-027, ADR-029).

`shared/<module>/` disusun module-first — `domain/` + `data/` di balik barrel
`<module>.dart` — dan diimpor dari luar hanya lewat barrel. Tampilan entitas
modul yang dipakai ≥2 fitur boleh tinggal di `presentation/` modul itu, lewat
barrel kedua `<module>_presentation.dart` supaya `domain/` yang mengimpor
barrel utama tidak ikut menarik Flutter; tanpa bloc, page, scope, atau rute
(ADR-030 §3.2).

## Cara memilih pola DI

Repo acuan punya *decision tree* eksplisit untuk empat situasi yang berbeda.
Saldough memakainya langsung:

| Yang didaftarkan | Pola | Contoh Saldough |
|---|---|---|
| Bloc screen-local, tanpa dependensi repository | `BlocProvider.create()` di level rute | Bloc formulir sederhana yang tidak menyentuh penyimpanan |
| Singleton app-wide, kelas sendiri, ctor sinkron | `@LazySingleton(as: Interface)` langsung — **default** | `AppMoneyFormatter`, layanan lokal tanpa dependensi async |
| Tipe pihak ketiga / async / `@Named` | Factory method di kelas `@module` | `HiveKeyValueStorage.initialize(...)` di `RootModule` |
| Graf milik satu fitur, dependensi induk perlu dibatasi, atau ada urutan async | `IsolatedScope` di `features/<fitur>/di/<fitur>_scope.dart` | `BudgetScope`, `FreelanceScope` |

Heuristik satu baris: **`shared/` → root injectable · `features/` → scope ·
bloc screen-local → route provider.**

`IsolatedScope` punya tiga hook berurutan dan mengikat — lihat contoh lengkap
di bagian "Injeksi dependensi" di bawah: `bridge()` (whitelist dependensi
induk satu per satu) → `register()` (wiring lokal) → `afterInit()` (urutan
async, tidak pernah mendaftar dependensi baru).

## Pemetaan paket

Tabel ini memetakan setiap peran arsitektur ke paket yang menyediakannya.

| Peran | Paket | Kelas utama |
|---|---|---|
| State dan efek | `state_management` 2.2.0 | `UiState<T>`, `UiEffect`, `EffectRegistry`, `EffectListener<B,S>`, `AppBlocObserver` |
| Navigasi | `navigation` 1.1.1 | `RouteKey<TInput>`, `RouteInput`, `RouteNode`, `FeatureRouteModule`, `RouteRegistry` |
| Kesalahan | `failures` 2.0.2 | `Failure` tersegel, `FailureCode`, `FailureDetails` |
| Struktur data | `models` 1.1.3 | `Paginated<T>` |
| Kontrak penyimpanan | `api_storage` 1.1.0 | `KeyValueStorage`, `StorageKey`, `StoredValue<T>`, `JsonSerializer<T>` |
| Implementasi penyimpanan | `hive_storage` 1.1.1 | `HiveKeyValueStorage`, `HiveSecureStorage` |
| Injeksi dependensi | `di` 1.1.2 | `DiBoot`, `IsolatedScope`, `ScopeProvider`, `ScopeWidget` |
| Versi pihak ketiga | `dependencies` 1.4.0 | Ekspor ulang `equatable`, `json_annotation` |
| Aturan lint | `linter` 1.0.2 | Konfigurasi `very_good_analysis` |
| Test double | `memory_storage` 1.1.1 | `InMemoryKeyValueStorage` |

Dua catatan jujur soal pemakaian paket ini.

`models` hanya menyediakan `Paginated<T>` dan `PaginatedMapper`. Karena seluruh
data MVP tersimpan lokal dan bervolume kecil, tidak ada layar yang butuh
penomoran halaman. Paket ini kemungkinan besar **tidak terpakai** sampai tahap
sinkronisasi. Paket tetap didaftarkan agar konsisten dengan permintaan pemilik,
tetapi jangan memaksakan pemakaiannya.

`api_network` dan `dio_network` **tidak** dipakai pada MVP karena tidak ada
backend. Keduanya masuk pada tahap sinkronisasi.

`dependencies` kini benar-benar dipakai, bukan cuma terpasang: paket ini
mengekspor ulang `fpdart`, sumber `Either`/`left`/`right`/`unit` yang dipakai
di seluruh repository dan bloc sejak [ADR-0005](adr/0005-either-failure-convention.md).
Impor selalu lewat `package:dependencies/dependencies.dart`, tidak langsung
dari `package:fpdart`.

## Rantai alat

| Komponen | Versi | Catatan |
|---|---|---|
| Flutter | 3.47.2 stabil | Terverifikasi tersedia pada 9 September 2026 |
| Dart | 3.13.2 | Memenuhi kebutuhan minimum paket internal, yaitu `^3.11.4` |
| Android `minSdk` | 23 | Dituntut `flutter_secure_storage` 10 yang dipakai `hive_storage` |

## Dependensi

Deklarasi berikut adalah `pubspec.yaml` SALDOUGH YANG SEBENARNYA, terverifikasi
lewat `flutter pub get` dan `flutter analyze` yang berhasil bersih pada
10 September 2026. Rincian diagnosis dan kenapa sebagian paket dipin ke commit
SHA (bukan tag) ada di [ADR-0001](adr/0001-internal-package-dependency-strategy.md).

> **Catatan:** Setiap paket internal menyatakan `resolution: workspace` di
> pubspec-nya sendiri — ini TIDAK dihapus, tetap diperlukan untuk pengelolaan
> monorepo lewat melos. Risiko resolusi yang sebenarnya bukan baris itu,
> melainkan URL GitLab privat yang dipakai paket-paket itu untuk saling
> mereferensikan; lihat ADR-0001 bagian "Hasil sebenarnya".

```yaml
name: saldough
description: Pencatatan keuangan pribadi, pengganti sistem spreadsheet manual.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ^3.11.4

dependencies:
  # Paket internal — dipin ke commit SHA pada branch kompatibilitas
  # `claude/saldough-flutter-finance-app-06ufsv` di advance-mobile-platform
  # untuk api_storage/models/state_management/hive_storage, karena tag
  # aslinya menunjuk commit lama yang isinya masih mereferensikan paket
  # sibling lewat URL GitLab privat. Paket lain (dependencies/di/failures/
  # navigation) tidak pernah rusak (tidak punya dependensi internal di blok
  # `dependencies:` regulernya) sehingga tetap dipin ke tag asli.
  api_storage:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: infrastructure/storage/api_storage
      ref: 275181ec7d43d423d5293ab676445a4e43a736ee  # api_storage-v1.1.0 + fix URL
  dependencies:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: shared/dependencies
      ref: dependencies-v1.4.0
  di:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: shared/di
      ref: di-v1.1.2
  failures:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: core/failures
      ref: failures-v2.0.2
  flutter:
    sdk: flutter
  go_router: ^17.3.0
  google_fonts: ^8.1.0
  hive_storage:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: infrastructure/storage/hive_storage
      ref: 9b96fb4353f913270f72518198e598e900d6646c  # hive_storage-v1.1.1 + fix URL + fix ref api_storage
  intl: ^0.20.2
  models:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: core/models
      ref: 275181ec7d43d423d5293ab676445a4e43a736ee  # models-v1.1.3 + fix URL
  navigation:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: fondation/navigation
      ref: navigation-v1.1.1
  slang: ^4.7.0
  slang_flutter: ^4.7.0
  state_management:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: fondation/state_management
      ref: 275181ec7d43d423d5293ab676445a4e43a736ee  # state_management-v2.2.0 + fix URL

dev_dependencies:
  bloc_test: ^10.0.0
  build_runner: any
  flutter_test:
    sdk: flutter
  injectable_generator: any
  json_serializable: any
  linter:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: shared/linter
      ref: linter-v1.0.2
  memory_storage:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: infrastructure/storage/memory_storage
      ref: 9b96fb4353f913270f72518198e598e900d6646c  # memory_storage-v1.1.1 + fix URL + fix ref api_storage
  mocktail: ^1.0.4
  slang_build_runner: ^4.7.0

flutter:
  uses-material-design: true
  assets:
    - assets/i18n/
```

Versi paket pihak ketiga di atas adalah titik awal. Pastikan ulang saat Fase 0,
karena resolusi bisa menuntut penyesuaian.

## Bootstrap

Aplikasi dimulai dalam dua fase, mengikuti pola `DiBoot` dari `package:di` dan
urutan boot yang divalidasi di `flutter-architecture-studi-bank` (minus
jembatan legacy GetX mereka — lihat bagian "Dasar keputusan").

Fase pertama ditunggu sebelum `runApp`, berisi hal yang dibutuhkan bingkai
pertama: penyimpanan, tema, terjemahan, dan router. Fase kedua berjalan setelah
`runApp` tanpa ditunggu, berisi hal yang bisa menyusul.

```dart
final GetIt rootGetIt = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocaleSettings.useDeviceLocale();
  await di.run(rootGetIt);

  registerEffectHandlers(router: router);

  runApp(TranslationProvider(
    child: SaldoughApp(getIt: rootGetIt, router: router),
  ));

  di.warmUp(rootGetIt);
}
```

Urutan pendaftaran dependensi bersifat mengikat, karena tiap langkah bergantung
pada langkah sebelumnya:

1. Penyimpanan, yaitu kotak Hive.
2. Repository lintas fitur, yaitu pos tujuan dan sumber pemasukan.
3. Modul fitur.
4. Router, karena membutuhkan modul rute seluruh fitur.

Penangan efek didaftarkan **sebelum** `runApp`. `EffectRegistry.register`
menegaskan satu tipe efek hanya boleh terdaftar sekali, dan efek yang belum
terdaftar melempar `UnregisteredEffectError` saat dipancarkan.

## Menulis satu fitur

Bagian ini menjelaskan alur satu fitur dari domain sampai antarmuka. Contohnya
memakai modul `shared/transaction` dan fitur `budget`.

### Domain

Entitas adalah Dart murni dengan `Equatable`, tanpa `freezed`. Monorepo internal
tidak memakai `freezed` di mana pun, jadi Saldough mengikutinya.

Antarmuka repository memakai `abstract interface class` dan mengembalikan
`Future<Either<Failure, T>>` — lihat [ADR-0005](adr/0005-either-failure-convention.md).

```dart
abstract interface class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> listByMonth(String monthId);
  Future<Either<Failure, Transaction>> getById(String monthId, String id);
  Future<Either<Failure, Unit>> record(Transaction transaction);
  Future<Either<Failure, Unit>> recomputeWalletBalances();
}
```

Use case memuat rumus dan merupakan tempat paling penting untuk diuji.
`CalculateBudgetProgress`, `CalculateWalletBalance`, dan `CalculateNetPay`
semuanya Dart murni sehingga bisa diuji tanpa Flutter.

### Data

Model serialisasi terpisah dari entitas domain, dengan `fromJson` dan `toJson`
tulis tangan mengikuti pola `User` di `app_example`. Setiap dokumen menyertakan
`schemaVersion`.

Implementasi repository memakai `with RepositoryGuard` dari
`core/foundation/repository_guard.dart` untuk memusatkan pemetaan exception
mentah menjadi `Failure`:

```dart
final class TransactionRepositoryImpl
    with RepositoryGuard
    implements TransactionRepository {
  const TransactionRepositoryImpl({required this._storage});
  final KeyValueStorage _storage;

  @override
  Future<Either<Failure, Transaction>> getById(String monthId, String id) =>
      guard(() async {
    final month = await _readMonth(monthId);
    final found = month.where((t) => t.id == id).firstOrNull;
    if (found == null) {
      throw StateError('Transaction $id not found in $monthId');
    }
    return found;
  });

  @override
  Failure? mapCustomError(Object error) => error is StateError
      ? PersistenceFailure(code: StorageFailureCode.keyNotFound, message: error.message)
      : null;
}
```

`guard()` menangkap `FormatException` (kegagalan penguraian) secara otomatis;
exception lain (seperti `StateError` di atas) ditangkap oleh cabang generik
`guard()` dan diteruskan ke hook `mapCustomError`, yang setiap implementasi
repository boleh override untuk memetakan exception spesifik fiturnya sendiri
— persis pola `AuthRepositoryImpl.mapCustomError` di
[ADR-0005](adr/0005-either-failure-convention.md). Kode pemanggil (bloc) tidak
pernah menangkap exception — ia hanya membongkar `Either` yang dikembalikan.

### Presentation

State memperluas `UiState<T>`. Field yang memengaruhi tampilan masuk `props`;
`effect` tidak pernah masuk `props`.

```dart
final class BudgetState extends UiState<BudgetState> {
  const BudgetState({
    required this.budgets,
    required this.isLoading,
    super.effect,
  });

  factory BudgetState.initial() =>
      const BudgetState(budgets: [], isLoading: true);

  final List<Budget> budgets;
  final bool isLoading;

  @override
  BudgetState copyWith({
    List<Budget>? budgets,
    bool? isLoading,
    UiEffect? effect,
  }) =>
      BudgetState(
        budgets: budgets ?? this.budgets,
        isLoading: isLoading ?? this.isLoading,
        effect: effect,
      );

  @override
  List<Object?> get props => [budgets, isLoading];
}
```

Bloc membongkar `Either` dengan `switch` dan memancarkan efek sesuai cabangnya.
Efek ditulis sebagai `extension` di berkas `part`, supaya berkas bloc tetap
ringkas.

```dart
Future<void> _onBudgetSaved(
  BudgetSaved event,
  Emitter<BudgetState> emit,
) async {
  emit(state.copyWith(isLoading: true));
  final result = await _repository.saveBudget(event.budget);
  switch (result) {
    case Left(value: final failure):
      emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
    case Right():
      add(const BudgetsLoaded());
  }
}
```

Halaman membungkus isinya dengan `EffectListener`:

```dart
EffectListener<BudgetBloc, BudgetState>(
  child: BlocBuilder<BudgetBloc, BudgetState>(
    builder: (context, state) => BudgetView(budgets: state.budgets),
  ),
)
```

### Navigasi

Kunci rute dan modul rute dipisah agar fitur lain tidak menarik pohon widget
(ADR-0004, ditegakkan ulang oleh ADR-030 §3.3).

```dart
// wallet_route_keys.dart — satu-satunya berkas yang boleh diimpor fitur lain
final class WalletDetailInput extends RouteInput {
  const WalletDetailInput(this.wallet);
  final Wallet wallet;
}

abstract final class WalletRouteKeys {
  static const detail = RouteKey<WalletDetailInput>('wallet.detail');
}
```

Modul rute memasang lingkup dependensi rutenya sendiri. Kontainer induk
diambil **sebelum** `ScopeWidget` disisipkan, karena `ScopeProvider` belum ada
di pohon saat `create` dijalankan. Tidak ada bloc yang dipinjam dari rute
pemanggil; `RunOnce` memicu `*Started`.

```dart
RouteNode.typed<WalletDetailInput>(
  key: WalletRouteKeys.detail,
  builder: (context, input) {
    final parentContainer = ScopeProvider.of(context);
    return ScopeWidget<WalletScope>(
      create: () => WalletScope(parentContainer: parentContainer),
      builder: (context, scope) {
        final bloc = scope.container<WalletBloc>();
        return BlocProvider.value(
          value: bloc,
          child: EffectListener<WalletBloc, WalletState>(
            child: RunOnce(action: () => bloc.add(const WalletStarted()), child: WalletDetailPage(wallet: input.wallet)),
          ),
        );
      },
    );
  },
),
```

Modul didaftarkan di `RootModule.featureModules`. Membuka rute:

- dari ketukan widget: `context.pushRoute(WalletRouteKeys.detail, WalletDetailInput(wallet))`
  — pasangan kunci–input dicek saat kompilasi, hasilnya `Future` hasil rute;
- dari logika bloc: `NavigatePushEffect(keyId: WalletRouteKeys.detail.id, input: …)`.

`pushRoute` membangun rute Flutter dari `RouteNode` yang sama dengan yang
didaftarkan ke `go_router`, lalu mendorongnya ke Navigator akar. Di Saldough
`RouteTransition.slideFromBottom` berarti **lembar modal** setinggi layar
(tema pemanggil ikut), dan `RouteTransition.none` berarti **rute alur
transparan**: tak terlihat, memegang scope fiturnya, membuka lembar/dialognya
sendiri, lalu menutup diri dengan hasilnya. CATAT, sunting transaksi, dan catat
pakai suara (`RecordRouteKeys.sheet/edit/voice`) adalah alur, supaya
`RecordBloc` hidup sampai penyimpanan dan snackbarnya selesai.

Rute yang menulis lalu menutup diri menunggu efek hasilnya dulu (blocnya ikut
tertutup bersama rute). Layar anak di dalam satu alur fitur yang berbagi bloc
pembukanya (template anggaran, rincian proyek, kategori) boleh tetap
`Navigator.push` di dalam fiturnya.

**Shell navigasi utama** (`AppShellPage`, `lib/app/shell/`) — empat tab
(Beranda/Anggaran/Riwayat/Dompet) dan dua tombol mengambang (CATAT, suara),
layar awal aplikasi. Satu `GoRoute` mentah didaftarkan langsung di
`AppRouteRegistry.build`, karena bukan milik satu fitur. Tiap tab dipasang
lewat `ScopeWidget` fiturnya di dalam `IndexedStack` (bukan
`StatefulShellRoute` — catatan revisi ADR-0004 §8). Tombol mengambang membuka
rute alur `record`; shell tidak memasang `RecordBloc`.

### Sinkronisasi antarfitur

Layar yang menampilkan saldo atau transaksi tetap segar lewat `LedgerChanges`
(`shared/transaction/domain/`, ADR-030 §3.4), bukan dimuat ulang oleh shell
atau halaman lain. Sinyal dipancarkan **sekali per unit kerja, sesudah
transaksi dan saldo tertulis** — oleh `RecordTransaction` dan `WalletBloc`,
tidak pernah oleh repository — dan membawa sumbernya. Bloc pelanggan
(`TransactionBloc`, `WalletBloc`, `BudgetBloc`, `HomeBloc`,
`WalletActivityBloc`) berlangganan lewat `ledgerChanges.from(this)` di
konstruktor, batal di `close`, dan memuat ulang tanpa kerangka. Anggaran dan
freelance disegarkan saat kembali dari rute dan saat tab dipilih.

### Injeksi dependensi

Setiap fitur punya `IsolatedScope`. Lingkup mendapat kontainer `GetIt` baru yang
tidak mewarisi apa pun, sehingga dependensi induk harus didaftarkan ulang secara
eksplisit di `bridge`. Ini disengaja oleh paket, dan berfungsi sebagai daftar
putih ketergantungan fitur.

```dart
final class BudgetScope extends IsolatedScope {
  BudgetScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<KeyValueStorage>(parent<KeyValueStorage>());
    c.registerSingleton<WalletRepository>(parent<WalletRepository>());
    c.registerSingleton<TransactionRepository>(parent<TransactionRepository>());
    c.registerSingleton<LedgerChanges>(parent<LedgerChanges>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<BudgetBloc>(
      () => BudgetBloc(
        repository: c<BudgetRepository>(),
        walletRepository: c<WalletRepository>(),
        transactionRepository: c<TransactionRepository>(),
        ledgerChanges: c<LedgerChanges>(),
      ),
      dispose: (bloc) => bloc.close(),
    );
  }
}
```

## Pengujian

Struktur `test/` mencerminkan `lib/`. Prioritas pengujian mengikuti risiko:
use case domain paling utama, karena di situlah rumus keuangan berada.

| Yang diuji | Cara |
|---|---|
| Use case domain | Uji unit Dart murni, memakai angka nyata dari catatan keuangan pemilik |
| Repository | `InMemoryKeyValueStorage` dari `memory_storage` |
| Bloc | `bloc_test`, dengan repository dipalsukan memakai `mocktail` — lihat [ADR-0010](adr/0010-mocktail-bloc-test-convention.md) |
| Widget | Uji widget untuk komponen bersama |

Batas zona dan lapisan dijaga `test/architecture/import_boundaries_test.dart`
(ADR-030 §3.8): ia membaca impor `lib/` dan melaporkan setiap impor terlarang.

Saldough memakai `mocktail` untuk mock/stub dan `bloc_test` untuk menguji
bloc; fake tulis tangan hanya untuk antarmuka berperilaku (`AuthRepository`,
`SpeechTranscriber`, `SpeechToText`, catatan revisi ADR-0010). Ini **menyimpang** dari repo acuan arsitektur (`flutter-architecture-studi-bank`
memakai fake tulis tangan tanpa pustaka mocking) — penyimpangan ini atas
permintaan eksplisit pemilik, bukan temuan teknis. Lihat
[ADR-0010](adr/0010-mocktail-bloc-test-convention.md) untuk contoh lengkap
dan alasannya.

Aturan yang mengikat: **setiap rumus di
[DOMAIN_MODEL.md](DOMAIN_MODEL.md) punya uji unit dengan angka nyata sebagai
kasus ujinya.** Ini memenuhi NFR-ACC-002, dan merupakan satu-satunya cara
membuktikan angka yang ditampilkan aplikasi bisa dipercaya.

Kasus uji yang wajib ada, seluruhnya memakai angka dari catatan keuangan nyata
pemilik:

| Rumus | Masukan | Keluaran yang benar |
|---|---|---|
| `netPay` | kotor 3.117.500, pajak 2,5% | 3.039.563 |
| `netPay` | kotor 2.682.500 (37 jam × 72.500), pajak 2,5% | 2.615.438 |
| `currentBalance` | awal 5.000.000, masuk 2.615.438, keluar 3.068.500, transfer keluar 1.000.000 | 3.546.938 |
| `currentBalance` negatif | awal 500.000, keluar 1.837.042 | −1.337.042 |
| `totalBalance` setelah transfer | dompet A −1.000.000, dompet B +1.000.000 | tidak berubah |
| `budget.spent` | pos 1.000.000 + 500.000 + 300.000 + 700.000 + 500.000 | 3.000.000 |
| `item.status` | rencana 1.000.000, terpakai 1.200.000 | `overspent` |

Dua uji paling penting berdiri di atas alasan yang berbeda.

`netPay` menjaga aritmatika integer sen. Membulatkan pajak sebelum
menguranginya menghasilkan 3.039.562, meleset satu rupiah dari catatan pemilik.

**Uji saldo tersimpan versus saldo turunan** menjaga keputusan
[ADR-012](adr/0012-tata-letak-penyimpanan-buku-besar.md). Ia mencatat
serangkaian transaksi, lalu membuktikan `wallet.currentBalance` identik dengan
hasil `recomputeWalletBalances()`. Tanpa uji itu, keputusan menyimpan nilai
turunan tidak boleh diambil sama sekali.

## Lint

`analysis_options.yaml` cukup berisi satu baris, mengikuti seluruh paket di
monorepo:

```yaml
include: package:linter/analysis_options.yaml
```

Konfigurasi itu memuat `very_good_analysis` dengan `lines_longer_than_80_chars`
dan `comment_references` dimatikan.

## Aturan yang mengikat

Daftar ini merangkum batasan yang tersebar di dokumen ini. Melanggarnya berarti
menyimpang dari arsitektur.

- Lapisan domain tidak mengimpor Flutter, Hive, atau paket infrastruktur.
- Lapisan presentation tidak mengimpor lapisan data.
- `core/` tidak pernah berisi entitas bisnis — hanya infra tanpa makna
  domain — dan tidak mengimpor `shared/`, `features/`, maupun `app/`.
- Akar komposisi (`RootModule`, `SaldoughApp`, `AppShellPage`) di `lib/app/`.
- `shared/<module>/` diimpor hanya lewat barrel-nya (`<module>.dart` atau
  `<module>_presentation.dart`), tidak pernah lewat jalur berkas di dalamnya.
- Impor antar fitur hanya lewat `<fitur>_route_keys.dart`, kecuali adapter
  `data/adapters/` yang mengimplementasikan port fitur konsumen.
- Layar fitur lain dibuka lewat `context.pushRoute(kunci, input)`; tidak ada
  bloc yang diteruskan antarrute.
- Penulis buku besar memancarkan `LedgerChanges` sesudah unit kerjanya;
  tidak ada `*Refreshed` bloc fitur lain dari shell atau halaman.
- Seluruh impor memakai `package:saldough/...`, bukan impor relatif, kecuali di
  dalam berkas barrel dan direktif `part`.
- Nominal bertipe `int` dalam satuan sen. Tidak pernah `double`.
- Kegagalan dikembalikan sebagai `Either<Failure, T>` lewat `RepositoryGuard`,
  tidak pernah dilempar dengan `throw Failure`.
- `effect` tidak pernah masuk `props`.
- Warna, jarak, sudut, dan durasi selalu lewat token, tidak pernah harfiah.
- Teks antarmuka selalu lewat slang, tidak pernah harfiah.
- Pengujian memakai `mocktail`/`bloc_test`, bukan fake tulis tangan (kecuali
  antarmuka berperilaku, ADR-0010).
- `test/architecture/import_boundaries_test.dart` harus lulus.
- Ikuti kode paket internal, bukan README-nya. Beberapa README diketahui tidak
  sinkron dengan kodenya.

## Langkah berikutnya

Lanjutkan ke [ROADMAP.md](../04-planning/ROADMAP.md) untuk urutan fase, atau ke
[TASK_LIST.md](../04-planning/TASK_LIST.md) untuk daftar tugas yang bisa
dikerjakan.
