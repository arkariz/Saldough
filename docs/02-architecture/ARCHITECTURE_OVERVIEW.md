# Gambaran arsitektur

Dokumen ini menjelaskan bagaimana Saldough disusun: lapisan, struktur folder,
paket yang dipakai, dan cara sebuah fitur ditulis dari ujung ke ujung. Ini
dokumen teknis utama proyek.

Baca [DOMAIN_MODEL.md](DOMAIN_MODEL.md) lebih dulu kalau belum paham entitas
dan rumusnya. Setiap keputusan besar di sini punya ADR tersendiri yang
menjelaskan alasannya; tautannya disebutkan di tempatnya masing-masing.

## Dasar keputusan

Saldough menggabungkan dua sumber acuan yang berbeda perannya.

**Struktur** diambil dari `new-health-duel`: Clean Architecture berbasis fitur,
tiga lapisan, modul dependensi per fitur, dan susunan lapisan tema.

**Mesin runtime** diambil dari paket internal `arkariz/advance-mobile-platform`
sesuai permintaan pemilik: state, navigasi, kesalahan, penyimpanan, dan injeksi
dependensi.

Penggabungan ini menimbulkan tiga perbedaan sadar dari `new-health-duel`.
Ketiganya wajib diketahui sebelum menulis kode, karena menyalin pola
`new-health-duel` mentah-mentah akan salah di tiga titik ini.

| Hal | `new-health-duel` | **Saldough** | Alasan |
|---|---|---|---|
| Kesalahan | `Either<Failure, T>` dengan `dartz` | `throw Failure` dan `on Failure catch` | [ADR-0005](adr/0005-throw-catch-failure-convention.md) |
| Efek bloc | Kelas EffectBloc lokal | `package:state_management` | [ADR-0003](adr/0003-effect-bloc-state-management.md) |
| Navigasi | Konstanta string di atas `go_router` | Registri rute bertipe `package:navigation` | [ADR-0004](adr/0004-typed-route-registry-navigation.md) |

Repositori `flutter-architecture-studi` **tidak** dipakai sebagai acuan. Folder
`lib/v2` yang semula disebut tidak ada di repositori itu, dan `lib/app` yang ada
memakai Riverpod sehingga bertentangan dengan `package:state_management`.

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

```
saldough/
├── assets/
│   └── i18n/
│       ├── strings_id.i18n.json          # bahasa dasar
│       └── strings_en.i18n.json
├── lib/
│   ├── main.dart                         # bootstrap dua fase
│   ├── app.dart                          # MaterialApp.router
│   ├── core/
│   │   ├── di/
│   │   │   ├── di.dart                   # DiBoot
│   │   │   └── src/{app_injectable.dart, root_module.dart}
│   │   ├── effect_handler/
│   │   │   ├── app_effect_registry.dart
│   │   │   └── src/{nav_effect_handler.dart, feedback_effect_handler.dart}
│   │   ├── navigation/
│   │   │   ├── app_route_registry.dart
│   │   │   └── route_node_go_router_ext.dart
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
│   └── features/
│       ├── cycle/                        # siklus bulanan
│       ├── income/                       # sumber pemasukan
│       ├── worklog/                      # timesheet dan buku jam
│       ├── grocery/                      # rencana belanja
│       ├── card/                         # kartu kredit
│       ├── investment/                   # pos tujuan dan alokasi
│       └── seed/                         # impor data historis
└── test/
    └── features/                         # cermin struktur lib/features
```

Setiap fitur punya susunan yang sama:

```
features/cycle/
├── data/
│   ├── models/           # model serialisasi dengan fromJson dan toJson
│   ├── datasources/      # akses Hive
│   └── repositories/     # implementasi antarmuka domain
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
  bloc_test: ^10.0.0
  build_runner: any
  injectable_generator: any
  json_serializable: any
  mocktail: ^1.0.4
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
pola dua tahap `new-health-duel`.

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
tipe hasilnya langsung, bukan `Either`.

```dart
abstract interface class CycleRepository {
  Future<MonthlyCycle> getCycle(String id);
  Future<List<String>> listCycleIds();
  Future<void> saveCycle(MonthlyCycle cycle);
}
```

Use case memuat rumus dan merupakan tempat paling penting untuk diuji.
`CalculateRemainder`, `RollOverCycle`, dan `CalculateNetPay` semuanya Dart murni
sehingga bisa diuji tanpa Flutter.

### Data

Model serialisasi terpisah dari entitas domain, dengan `fromJson` dan `toJson`
tulis tangan mengikuti pola `User` di `app_example`. Setiap dokumen menyertakan
`schemaVersion`.

Implementasi repository menerjemahkan kesalahan mentah menjadi `Failure`:

```dart
final class CycleRepositoryImpl implements CycleRepository {
  @override
  Future<MonthlyCycle> getCycle(String id) async {
    try {
      final stored = await _storage.read(CycleStorageKeys.cycle(id).value);
      if (stored == null) {
        throw PersistenceFailure(
          code: StorageFailureCode.keyNotFound,
          message: 'Cycle $id not found in local storage',
          userMessage: null,
        );
      }
      return CycleModel.fromJson(jsonDecode(stored)).toEntity();
    } on FormatException catch (error, stackTrace) {
      throw SystemFailure(
        code: const FailureCode('PERSISTENCE_PARSE_ERROR'),
        message: 'Failed to parse cycle $id',
        details: FailureDetails(cause: error, stackTrace: stackTrace),
      );
    }
  }
}
```

Perhatikan bahwa `Failure` dilempar, bukan dikembalikan. `Failure` bukan turunan
`Exception`, sehingga penangkapannya harus memakai `on Failure catch`, bukan
`on Exception catch`.

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

Bloc menangkap `Failure` dan memancarkan efek. Efek ditulis sebagai `extension`
di berkas `part`, supaya berkas bloc tetap ringkas.

```dart
Future<void> _onRollOverRequested(
  CycleRollOverRequested event,
  Emitter<CycleState> emit,
) async {
  emit(state.copyWith(isLoading: true));
  try {
    final next = await _rollOverCycle(event.fromCycleId);
    emit(state.copyWith(
      cycle: next,
      isLoading: false,
      effect: _effectCycleCreated(next.id),
    ));
  } on Failure catch (failure) {
    emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
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
| Bloc | `bloc_test`, dengan repository dipalsukan memakai `mocktail` |
| Widget | Uji widget untuk komponen bersama |

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
- Impor antar fitur hanya lewat `<fitur>_route_keys.dart`.
- Seluruh impor memakai `package:saldough/...`, bukan impor relatif, kecuali di
  dalam berkas barrel dan direktif `part`.
- Nominal bertipe `int` dalam satuan sen. Tidak pernah `double`.
- Kegagalan dilempar sebagai `Failure` dan ditangkap dengan `on Failure catch`.
- `effect` tidak pernah masuk `props`.
- Warna, jarak, sudut, dan durasi selalu lewat token, tidak pernah harfiah.
- Teks antarmuka selalu lewat slang, tidak pernah harfiah.
- Ikuti kode paket internal, bukan README-nya. Beberapa README diketahui tidak
  sinkron dengan kodenya.

## Langkah berikutnya

Lanjutkan ke [ROADMAP.md](../04-planning/ROADMAP.md) untuk urutan fase, atau ke
[TASK_LIST.md](../04-planning/TASK_LIST.md) untuk daftar tugas yang bisa
dikerjakan.
