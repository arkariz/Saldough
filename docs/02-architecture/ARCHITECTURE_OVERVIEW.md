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

**Tema** tetap diambil dari `arkariz/new-health-duel`
([ADR-0006](adr/0006-design-token-semantic-color-mapping.md)) — repo
acuan arsitektur memakai `mobile_dsl`, design system privat yang tidak bisa
diakses, sehingga perannya di Saldough terbatas pada struktur kode, bukan
tampilan.

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
| `mobile_dsl` | Design system privat mereka — tema Saldough dari `new-health-duel` |
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
| `core` | Tema, terjemahan, DI, router, widget bersama | Paket eksternal |

Aturan yang paling sering dilanggar dan paling penting dijaga: **lapisan domain
tidak boleh mengimpor Flutter**. Tidak `material.dart`, tidak `widgets.dart`,
tidak Hive, tidak `api_storage`. Domain berisi rumus keuangan, dan rumus itu
harus bisa diuji tanpa menjalankan Flutter.

Lapisan `presentation` tidak pernah mengimpor `data`. Keduanya bertemu di
`domain` lewat antarmuka repository, dan disambungkan di modul dependensi fitur.

## Struktur folder

Saldough memakai tiga zona tidak tumpang tindih — `core/`, `shared/<module>/`,
`features/<feature>/` — sesuai [ADR-0009](adr/0009-core-shared-features-zone-layout.md).
Ini mengganti asumsi feature-first sederhana dari rencana awal, yang tidak
punya jawaban untuk di mana entitas lintas fitur (seperti `Goal`) seharusnya
tinggal.

```
saldough/
├── assets/
│   └── i18n/
│       ├── strings_id.i18n.json          # bahasa dasar
│       └── strings_en.i18n.json
├── lib/
│   ├── main.dart                         # bootstrap dua fase
│   ├── app.dart                          # MaterialApp.router
│   ├── core/                             # infra lintas fitur, TANPA makna bisnis
│   │   ├── di/
│   │   │   ├── di.dart                   # DiBoot
│   │   │   └── src/{app_injectable.dart, root_module.dart}
│   │   ├── foundation/
│   │   │   ├── effect_handler/
│   │   │   │   ├── app_effect_registry.dart
│   │   │   │   └── src/{nav_effect_handler.dart, snackbar_effect_handler.dart, dialog_effect_handler.dart}
│   │   │   ├── navigation/
│   │   │   │   ├── app_route_registry.dart
│   │   │   │   └── route_node_go_router_ext.dart
│   │   │   └── repository_guard.dart     # mixin RepositoryGuard — lihat ADR-0005
│   │   ├── storage/
│   │   │   ├── app_storage.dart
│   │   │   └── app_storage_keys.dart
│   │   ├── theme/
│   │   │   ├── theme.dart                # barrel
│   │   │   ├── app_theme.dart
│   │   │   ├── tokens/{app_spacing, app_radius, app_durations, app_elevation}.dart
│   │   │   └── extensions/app_colors_extension.dart
│   │   ├── presentation/widgets/         # AppCard, AppButton, AppChip, AppMoneyText
│   │   ├── utils/formatters/             # pemformat uang dan tanggal
│   │   └── i18n/                         # keluaran slang
│   ├── shared/                           # kapabilitas dipakai ≥2 fitur, module-first
│   │   └── goal/
│   │       ├── goal.dart                 # barrel — satu-satunya jalur impor ke modul ini
│   │       ├── domain/{goal.dart, goal_repository.dart}
│   │       └── data/{goal_model.dart, goal_repository_impl.dart}
│   └── features/                         # graf milik satu fitur
│       ├── cycle/                        # siklus bulanan
│       ├── income/                       # sumber pemasukan
│       ├── worklog/                      # timesheet dan buku jam
│       ├── grocery/                      # rencana belanja
│       ├── card/                         # kartu kredit
│       ├── investment/                   # alokasi & pinjaman antar pos (konsumen shared/goal)
│       └── seed/                         # impor data historis
└── test/
    ├── shared/                           # cermin struktur lib/shared
    └── features/                         # cermin struktur lib/features
```

Setiap `features/<feature>/` punya susunan internal yang sama — `domain/`
dan `data/` privat (tidak diimpor fitur lain), `presentation/`, dan `di/`:

```
features/cycle/
├── data/
│   ├── models/           # model serialisasi dengan fromJson dan toJson
│   ├── datasources/      # akses Hive
│   └── repositories/     # implementasi antarmuka domain, with RepositoryGuard
├── di/
│   └── cycle_scope.dart  # IsolatedScope
├── domain/
│   ├── entities/         # MonthlyCycle, BudgetLine, IncomeLine
│   ├── repositories/     # abstract interface class
│   └── usecases/         # RollOverCycle, CalculateRemainder
└── presentation/
    ├── bloc/
    │   ├── cycle_bloc.dart
    │   ├── cycle_event.dart
    │   ├── cycle_side_effect.dart        # part dari cycle_bloc.dart
    │   └── state/cycle_state.dart
    ├── navigation/
    │   ├── cycle_route_keys.dart         # satu-satunya berkas yang boleh diimpor fitur lain
    │   └── cycle_route_module.dart
    ├── pages/
    └── widgets/
```

`shared/<module>/` (lihat `shared/goal/` di atas) disusun module-first —
`domain/` + `data/` di balik satu barrel, **tanpa `presentation/`** — dan
diimpor fitur lain hanya lewat barrel itu, tidak pernah lewat jalur berkas di
dalamnya.

## Cara memilih pola DI

Repo acuan punya *decision tree* eksplisit untuk empat situasi yang berbeda.
Saldough memakainya langsung:

| Yang didaftarkan | Pola | Contoh Saldough |
|---|---|---|
| Bloc screen-local, tanpa dependensi repository | `BlocProvider.create()` di level rute | Bloc formulir sederhana yang tidak menyentuh penyimpanan |
| Singleton app-wide, kelas sendiri, ctor sinkron | `@LazySingleton(as: Interface)` langsung — **default** | `AppMoneyFormatter`, layanan lokal tanpa dependensi async |
| Tipe pihak ketiga / async / `@Named` | Factory method di kelas `@module` | `HiveKeyValueStorage.initialize(...)` di `RootModule` |
| Graf milik satu fitur, dependensi induk perlu dibatasi, atau ada urutan async | `IsolatedScope` di `features/<fitur>/di/<fitur>_scope.dart` | `CycleScope`, `InvestmentScope` |

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

Deklarasi berikut memakai URL GitHub publik dan tag yang sudah diverifikasi
lewat `git ls-remote --tags` pada 9 September 2026. Rincian keputusannya ada di
[ADR-0001](adr/0001-internal-package-dependency-strategy.md).

> **Peringatan:** Setiap paket internal menyatakan `resolution: workspace` di
> pubspec-nya. Deklarasi itu berpotensi menggagalkan resolusi dari repositori
> luar. Verifikasi `flutter pub get` adalah gerbang Fase 0. Jangan memulai
> pekerjaan fase berikutnya sebelum resolusi berhasil.

```yaml
name: saldough
description: Pencatatan keuangan pribadi, pengganti sistem spreadsheet manual.
publish_to: none
version: 0.1.0+1

environment:
  sdk: ^3.11.4

dependencies:
  flutter:
    sdk: flutter

  # Paket internal
  api_storage:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: infrastructure/storage/api_storage
      ref: api_storage-v1.1.0
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
  hive_storage:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: infrastructure/storage/hive_storage
      ref: hive_storage-v1.1.1
  models:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: core/models
      ref: models-v1.1.3
  navigation:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: fondation/navigation
      ref: navigation-v1.1.1
  state_management:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: fondation/state_management
      ref: state_management-v2.2.0

  # Pihak ketiga
  go_router: ^17.3.0
  google_fonts: ^8.1.0
  intl: ^0.20.2
  slang: ^4.7.0
  slang_flutter: ^4.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: any
  injectable_generator: any
  json_serializable: any
  slang_build_runner: ^4.7.0
  linter:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: shared/linter
      ref: linter-v1.0.2
  memory_storage:
    git:
      url: https://github.com/arkariz/advance-mobile-platform
      path: infrastructure/storage/memory_storage
      ref: memory_storage-v1.1.1

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
memakai fitur siklus bulanan.

### Domain

Entitas adalah Dart murni dengan `Equatable`, tanpa `freezed`. Monorepo internal
tidak memakai `freezed` di mana pun, jadi Saldough mengikutinya.

Antarmuka repository memakai `abstract interface class` dan mengembalikan
`Future<Either<Failure, T>>` — lihat [ADR-0005](adr/0005-either-failure-convention.md).

```dart
abstract interface class CycleRepository {
  Future<Either<Failure, MonthlyCycle>> getCycle(String id);
  Future<Either<Failure, List<String>>> listCycleIds();
  Future<Either<Failure, Unit>> saveCycle(MonthlyCycle cycle);
}
```

Use case memuat rumus dan merupakan tempat paling penting untuk diuji.
`CalculateRemainder`, `RollOverCycle`, dan `CalculateNetPay` semuanya Dart murni
sehingga bisa diuji tanpa Flutter.

### Data

Model serialisasi terpisah dari entitas domain, dengan `fromJson` dan `toJson`
tulis tangan mengikuti pola `User` di `app_example`. Setiap dokumen menyertakan
`schemaVersion`.

Implementasi repository memakai `with RepositoryGuard` dari
`core/foundation/repository_guard.dart` untuk memusatkan pemetaan exception
mentah menjadi `Failure`:

```dart
final class CycleRepositoryImpl with RepositoryGuard implements CycleRepository {
  const CycleRepositoryImpl({required this._storage});
  final KeyValueStorage _storage;

  @override
  Future<Either<Failure, MonthlyCycle>> getCycle(String id) => guard(() async {
    final stored = await _storage.read(CycleStorageKeys.cycle(id).value);
    if (stored == null) {
      throw StateError('Cycle $id not found in local storage');
    }
    return CycleModel.fromJson(jsonDecode(stored)).toEntity();
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
final class CycleState extends UiState<CycleState> {
  const CycleState({
    required this.cycle,
    required this.isLoading,
    super.effect,
  });

  factory CycleState.initial() =>
      CycleState(cycle: MonthlyCycle.empty(), isLoading: false);

  final MonthlyCycle cycle;
  final bool isLoading;

  @override
  CycleState copyWith({MonthlyCycle? cycle, bool? isLoading, UiEffect? effect}) =>
      CycleState(
        cycle: cycle ?? this.cycle,
        isLoading: isLoading ?? this.isLoading,
        effect: effect,
      );

  @override
  List<Object?> get props => [cycle, isLoading];
}
```

Bloc membongkar `Either` dengan `switch` dan memancarkan efek sesuai cabangnya.
Efek ditulis sebagai `extension` di berkas `part`, supaya berkas bloc tetap
ringkas.

```dart
Future<void> _onRollOverRequested(
  CycleRollOverRequested event,
  Emitter<CycleState> emit,
) async {
  emit(state.copyWith(isLoading: true));
  final result = await _rollOverCycle(event.fromCycleId);
  switch (result) {
    case Left(value: final failure):
      emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
    case Right(value: final next):
      emit(state.copyWith(
        cycle: next,
        isLoading: false,
        effect: _effectCycleCreated(next.id),
      ));
  }
}
```

Halaman membungkus isinya dengan `EffectListener`:

```dart
EffectListener<CycleBloc, CycleState>(
  child: BlocBuilder<CycleBloc, CycleState>(
    builder: (context, state) => CycleView(cycle: state.cycle),
  ),
)
```

### Navigasi

Kunci rute dan modul rute dipisah agar fitur lain tidak menarik pohon widget.

```dart
// cycle_route_keys.dart — satu-satunya berkas yang boleh diimpor fitur lain
final class CycleDetailInput extends RouteInput {
  const CycleDetailInput({required this.cycleId});
  final String cycleId;
}

abstract final class CycleRouteKeys {
  static const detail = RouteKey<CycleDetailInput>('cycle.detail');
}
```

Modul rute adalah tempat lingkup dependensi fitur dipasang. Kontainer induk
harus diambil **sebelum** `ScopeWidget` disisipkan, karena `ScopeProvider` belum
ada di pohon saat `create` dijalankan.

```dart
RouteNode.typed<CycleDetailInput>(
  key: CycleRouteKeys.detail,
  builder: (context, input) {
    final parentContainer = ScopeProvider.of(context);
    return ScopeWidget<CycleScope>(
      create: () => CycleScope(parentContainer: parentContainer),
      builder: (context, scope) => BlocProvider.value(
        value: scope.container.get<CycleBloc>(),
        child: CyclePage(cycleId: input.cycleId),
      ),
    );
  },
),
```

### Injeksi dependensi

Setiap fitur punya `IsolatedScope`. Lingkup mendapat kontainer `GetIt` baru yang
tidak mewarisi apa pun, sehingga dependensi induk harus didaftarkan ulang secara
eksplisit di `bridge`. Ini disengaja oleh paket, dan berfungsi sebagai daftar
putih ketergantungan fitur.

```dart
final class CycleScope extends IsolatedScope {
  CycleScope({required super.parentContainer});

  @override
  void bridge(GetIt c) {
    c.registerSingleton<KeyValueStorage>(parent<KeyValueStorage>());
    c.registerSingleton<GoalRepository>(parent<GoalRepository>());
  }

  @override
  void register(GetIt c) {
    c.registerLazySingleton<CycleRepository>(
      () => CycleRepositoryImpl(storage: c<KeyValueStorage>()),
    );
    c.registerLazySingleton<CycleBloc>(
      () => CycleBloc(repository: c<CycleRepository>()),
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
| Use case domain | Uji unit Dart murni, memakai angka nyata dari spreadsheet |
| Repository | `InMemoryKeyValueStorage` dari `memory_storage` |
| Bloc | Fake tulis tangan (`_FakeXyz implements Interface`), `bloc.add()` + `await bloc.stream.firstWhere(...)` — lihat [ADR-0010](adr/0010-hand-rolled-test-fakes.md) |
| Widget | Uji widget untuk komponen bersama |

Saldough **tidak** memakai `mocktail` atau `bloc_test`. Repo acuan arsitektur
tidak memakai keduanya — seluruh pengujian memakai fake tulis tangan, cocok
untuk interface Saldough yang sempit (2-4 metode). Lihat
[ADR-0010](adr/0010-hand-rolled-test-fakes.md) untuk contoh lengkap dan
alasannya.

Aturan yang mengikat: **setiap rumus di
[DOMAIN_MODEL.md](DOMAIN_MODEL.md) punya uji unit dengan angka nyata dari
spreadsheet sebagai kasus ujinya.** Ini memenuhi NFR-ACC-002, dan merupakan
satu-satunya cara membuktikan aplikasi bisa dipercaya menggantikan
spreadsheet.

Kasus uji yang wajib ada, seluruhnya sudah diverifikasi terhadap data asli:

| Rumus | Masukan | Keluaran yang benar |
|---|---|---|
| `groceryRollUp` | mingguan 576.600, bulanan 762.100, pengali 4 | 3.068.500 |
| `netPay` | kotor 3.117.500, pajak 2,5% | 3.039.563 |
| `netPay` | kotor 2.682.500, pajak 2,5% | 2.615.438 |
| `remainder` | pemasukan 15.839.563, anggaran 13.382.490 | 2.457.073 |
| `remainder` negatif | pemasukan 8.900.000, anggaran 10.237.042 | −1.337.042 |
| `allocation.amount` | budget 3.086.960, 15% | 463.044 |
| `allocation.amount` | budget 3.086.960, 55% | 1.697.828 |

Uji `netPay` adalah yang paling penting. Membulatkan pajak sebelum
menguranginya menghasilkan 3.039.562, meleset satu rupiah. Uji ini yang menjaga
aturan aritmatika integer sen tidak dilanggar diam-diam.

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
  domain.
- `shared/<module>/` diimpor hanya lewat barrel-nya (`<module>.dart`), tidak
  pernah lewat jalur berkas di dalamnya.
- Impor antar fitur hanya lewat `<fitur>_route_keys.dart`.
- Seluruh impor memakai `package:saldough/...`, bukan impor relatif, kecuali di
  dalam berkas barrel dan direktif `part`.
- Nominal bertipe `int` dalam satuan sen. Tidak pernah `double`.
- Kegagalan dikembalikan sebagai `Either<Failure, T>` lewat `RepositoryGuard`,
  tidak pernah dilempar dengan `throw Failure`.
- `effect` tidak pernah masuk `props`.
- Warna, jarak, sudut, dan durasi selalu lewat token, tidak pernah harfiah.
- Teks antarmuka selalu lewat slang, tidak pernah harfiah.
- Pengujian memakai fake tulis tangan, tidak `mocktail`/`bloc_test`.
- Ikuti kode paket internal, bukan README-nya. Beberapa README diketahui tidak
  sinkron dengan kodenya.

## Langkah berikutnya

Lanjutkan ke [ROADMAP.md](../04-planning/ROADMAP.md) untuk urutan fase, atau ke
[TASK_LIST.md](../04-planning/TASK_LIST.md) untuk daftar tugas yang bisa
dikerjakan.
