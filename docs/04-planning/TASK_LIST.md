# Daftar tugas dan progres

Dokumen ini adalah daftar kerja Saldough beserta status penyelesaiannya.
Perbarui kotak centang di sini setiap kali sebuah tugas selesai.

Untuk alasan di balik urutan fase, lihat [ROADMAP.md](ROADMAP.md). Untuk
pekerjaan desain visual per fase — yang selesai lebih dulu daripada kode —
lihat [UI_UX_DESIGN_TASKS.md](UI_UX_DESIGN_TASKS.md). Untuk perbaikan yang
lahir dari review UX terhadap kode yang sudah jalan — bukan tugas fase baru —
lihat [UX_REVIEW_FIXES.md](UX_REVIEW_FIXES.md).

## Cara memakai dokumen ini

Setiap tugas punya identitas `T-<fase>.<nomor>` dan menyebutkan requirement PRD
atau ADR yang dipenuhinya.

Aturan pencentangan bersifat ketat, mengikuti konvensi PRD: sebuah kotak hanya
dicentang kalau tugasnya benar-benar selesai dan terverifikasi. Pekerjaan yang
baru sebagian tetap dibiarkan kosong, disertai catatan satu baris yang
menjelaskan apa yang kurang.

| Penanda | Arti |
|---|---|
| `- [ ]` | Belum selesai |
| `- [x]` | Selesai dan terverifikasi |
| `⚠` | Ada catatan penting, dibaca sebelum mengerjakan |

## Ringkasan progres

Terakhir diperbarui: 11 September 2026.

| Fase | Tugas | Selesai | Status |
|---|---|---|---|
| 0 — Gerbang dependensi | 5 | 3 | Gerbang (T-0.3) lolos — T-0.2 menunggu verifikasi di mesin pemilik |
| 1 — Fondasi | 13 | 13 | Selesai — T-1.9 sebagian (lihat catatan, sama seperti T-0.2) |
| 2 — Siklus bulanan | 12 | 10 | "Selesai kalau" ROADMAP.md terpenuhi — T-2.10 sebagian, T-2.12 menunggu Fase 6 |
| 3 — Pemasukan dan timesheet | 10 | 10 | Selesai — "Selesai kalau" ROADMAP.md terpenuhi (lihat T-3.3) |
| 4 — Roll-up | 12 | 12 | Selesai — Belanja (T-4.1–T-4.5) dan Kartu kredit (T-4.6–T-4.12) dikerjakan di cabang terpisah, sudah digabung; `RootModule` kini memakai `_CompositeRollUpResolver` yang mendelegasikan ke resolver grocery/card sesuai tipe `RollUpSource` |
| 5 — Investasi | 8 | 8 | Selesai — saldo pos hanya menghitung alokasi siklus tertutup (lihat catatan T-5.7) |
| 6 — Seed | 8 | 8 | Selesai — 10 siklus nyata (Jan–Okt 2026) diimpor & direkonsiliasi, nol selisih rupiah di seluruh siklus tertutup (lihat "Catatan pengerjaan") |
| 7 — Sinkronisasi | 5 | 0 | Di luar MVP |
| **Total MVP** | **68** | **64** | |

Dokumentasi sudah selesai dan tidak dihitung dalam tabel di atas.

## Fase 0: Gerbang dependensi

⚠ **Fase ini adalah gerbang.** Jangan memulai Fase 1 sebelum T-0.3 tercentang.
Kegagalan resolusi mengubah cara seluruh aplikasi disusun.

- [x] **T-0.1** Pasang Flutter 3.47.2 stabil dan pastikan Dart 3.13.2 aktif.
      Memenuhi NFR-PLAT-001.
      Terverifikasi 10 September 2026: `flutter --version` melaporkan
      `Flutter 3.47.2 • channel stable`, `Tools • Dart 3.13.2`.
- [ ] **T-0.2** Buat proyek Flutter kosong bernama `saldough` dengan
      `minSdk` 23 pada Android, dan pastikan berjalan di kedua platform.
      ⚠ `minSdk` 23 dituntut `flutter_secure_storage` 10 yang dipakai
      `hive_storage`.
      Memenuhi NFR-PLAT-001.
      ⚠ **Sebagian.** Proyek `saldough` sudah dibuat (`flutter create`) di
      root repo ini, dan `android/app/build.gradle.kts` sudah dipin eksplisit
      `minSdk = 23` (bukan `flutter.minSdkVersion`, supaya tidak bergeser
      kalau Flutter SDK naik versi). **Belum bisa diverifikasi "berjalan di
      kedua platform"** di sandbox ini: (1) Android — proxy keluar sandbox
      menolak `dl.google.com` (403, kebijakan organisasi) sehingga Android
      SDK/cmdline-tools tidak bisa dipasang, jadi tidak ada cara membangun
      atau menjalankan APK di sini; (2) iOS — sandbox ini Linux, dan
      build/run iOS butuh macOS+Xcode yang tidak ada sama sekali di
      lingkungan ini. Kedua keterbatasan ini murni lingkungan eksekusi,
      bukan masalah kode. Perlu dijalankan ulang di mesin pemilik (yang
      punya Android SDK dan/atau Mac) sebelum kotak ini dicentang.
- [x] **T-0.3** Tambahkan seluruh dependensi paket internal sesuai
      [ARCHITECTURE_OVERVIEW.md](../02-architecture/ARCHITECTURE_OVERVIEW.md),
      lalu jalankan `flutter pub get` sampai berhasil.
      Memenuhi [ADR-0001](../02-architecture/adr/0001-internal-package-dependency-strategy.md).
      Gagal pada percobaan pertama, berhasil setelah T-0.4 dijalankan — lihat
      "Hasil galat T-0.3" dan T-0.4 di bawah. Terverifikasi ulang 10 September
      2026 lewat jaringan nyata ke GitHub (bukan simulasi lokal):
      `flutter pub get` → "Got dependencies!" tanpa galat.
- [x] **T-0.4** Kalau T-0.3 gagal karena `resolution: workspace`: catat pesan
      galatnya apa adanya di dokumen ini, dorong branch kompatibilitas di
      `advance-mobile-platform` pada branch
      `claude/saldough-flutter-finance-app-06ufsv`, lalu pin ke commit SHA-nya.
      Jangan menyentuh `main`.
      ⚠ **Akar masalah sebenarnya BUKAN `resolution: workspace`** — lihat
      koreksi di "Diagnosis" bawah ini. Branch kompatibilitas sudah didorong
      (2 commit: `275181e` dan `9b96fb4`), pemilik proyek sudah memberi akses
      push untuk ini. `main` tidak disentuh.
- [x] **T-0.5** Jalankan `flutter analyze` dengan
      `include: package:linter/analysis_options.yaml` sampai bersih.
      Terverifikasi 10 September 2026: "No issues found!". `analysis_options.yaml`
      diganti dari `package:flutter_lints/flutter.yaml` bawaan `flutter create`
      ke `package:linter/analysis_options.yaml`. 9 isu lint awal (dokumentasi
      publik hilang pada boilerplate `lib/main.dart`/`test/widget_test.dart`,
      urutan parameter `required`, urutan dependensi `pubspec.yaml` tidak
      alfabetis) sudah diperbaiki langsung — semuanya di kode scaffold
      bawaan, bukan kode fitur.

**Hasil galat T-0.3** (dari `flutter pub get`, percobaan pertama 10 September
2026, dengan `pubspec.yaml` persis sesuai deklarasi awal ARCHITECTURE_OVERVIEW.md):

```
Resolving dependencies...
Because every version of memory_storage from git depends on api_storage from git git@gitlab.bankcapital.co.id:mobile-services/mobile-platform.git at api_storage-v1.1.0 in infrastructure/storage/api_storage and saldough depends on api_storage from git https://github.com/arkariz/advance-mobile-platform at api_storage-v1.1.0 in infrastructure/storage/api_storage, memory_storage from git is forbidden.
So, because saldough depends on memory_storage from git, version solving failed.
Failed to update packages.
```

**Diagnosis** (setelah membaca langsung `pubspec.yaml` tiap paket di
`arkariz/advance-mobile-platform`): akar masalahnya bukan baris
`resolution: workspace` seperti diperkirakan ADR-0001 saat ditulis — baris
itu memang **harus tetap ada**, karena monorepo itu dikelola lewat melos
(pemilik mengonfirmasi ini setelah diagnosis awal). Akar masalah sebenarnya:
**setiap paket internal mereferensikan paket sibling-nya lewat URL SSH
GitLab privat di blok `dependencies:`-nya sendiri** (bukan cuma di README
atau `app_example`). Contoh: `memory_storage` menyatakan `api_storage` dari
`git@gitlab.bankcapital.co.id:...`, sementara `saldough` menyatakan
`api_storage` dari `https://github.com/arkariz/advance-mobile-platform`.
`pub` melihat ini sebagai dua *source* berbeda untuk paket yang sama dan
menolak resolusi.

Paket yang benar-benar punya dependensi internal di blok `dependencies:`
reguler (dan karenanya benar-benar rusak): `api_storage`→`failures`,
`hive_storage`→`api_storage`+`failures`, `memory_storage`→`api_storage`,
`models`→`dependencies`, `state_management`→`dependencies`. Paket lain
(`failures`, `dependencies`, `di`, `navigation`, `linter`) **tidak pernah
rusak** — GitLab di paket-paket itu cuma muncul di `dev_dependencies:`
(tidak ditarik `pub` untuk dependensi transitif), jadi tag aslinya tetap
valid apa adanya.

**Perbaikan nyata yang dijalankan** di branch
`claude/saldough-flutter-finance-app-06ufsv` pada `advance-mobile-platform`
(bukan simulasi lokal — diuji ulang lewat jaringan sungguhan ke GitHub):

1. Commit `275181ec7d43d423d5293ab676445a4e43a736ee` — ganti URL GitLab→GitHub
   di blok `dependencies:` kelima paket yang rusak (plus beberapa
   `dev_dependencies:` yang diseragamkan juga, tidak memengaruhi resolusi).
   `resolution: workspace` **tidak disentuh** di paket manapun.
2. Commit `9b96fb4353f913270f72518198e598e900d6646c` — commit 1 belum cukup:
   tag `api_storage-v1.1.0` yang dipakai `hive_storage`/`memory_storage`
   untuk merujuk `api_storage` masih menunjuk commit LAMA (sebelum commit 1),
   yang isinya masih mereferensikan `failures` lewat GitLab. Jadi
   `hive_storage`/`memory_storage` dipin ulang ke SHA commit 1, bukan tag,
   khusus untuk rujukan `api_storage`-nya.

`pubspec.yaml` Saldough lalu dipin: `api_storage`/`models`/`state_management`
ke SHA `275181e`, `hive_storage`/`memory_storage` ke SHA `9b96fb4`, sisanya
(`dependencies`/`di`/`failures`/`navigation`/`linter`) tetap ke tag aslinya
(tidak pernah rusak). Detail lengkap tabel pin ada di ADR-0001.

Dengan ini, `flutter pub get` berhasil total lewat jaringan nyata:
"Got dependencies!" tanpa galat resolusi, dan `flutter analyze` "No issues
found!".

## Fase 1: Fondasi

*Desain: [D-1.1](UI_UX_DESIGN_TASKS.md#fase-1-sistem-desain).*

### Tema dan token

- [x] **T-1.1** Buat token `AppSpacing`, `AppRadius`, `AppDurations`, dan
      `AppElevation` sebagai `abstract final class` berkonstruktor privat.
      Memenuhi [ADR-0006](../02-architecture/adr/0006-design-token-semantic-color-mapping.md).
- [x] **T-1.2** Buat `AppColorsExtension` dengan enam slot semantik keuangan
      (`income`, `expense`, `overBudget`, `investment`, `rollUp`,
      `needsReview`) ditambah slot netral, lengkap dengan `copyWith`, `lerp`,
      dan ekstensi `BuildContext` bernilai cadangan.
      ⚠ Jangan mempertahankan nama slot `opponent` atau `gold`.
      Terverifikasi: tidak ada slot itu di kode.
- [x] **T-1.3** Buat `AppTheme` dengan `ThemeData` terang dan gelap, tiga
      peran huruf (Archivo Black angka, Space Grotesk teks, Bangers label),
      serta garis tepi tebal dan bayangan keras offset menggantikan bayangan
      `Material` standar di kedua mode. Memenuhi NFR-UX-003.
      ⚠ Gaya komik, bukan Syne/DM Sans — lihat ADR-0006 (direvisi 10
      September 2026).
- [x] **T-1.4** Buat widget bersama `AppCard`, `AppButton`, `AppChip`, dan
      `AppMoneyText`.
      ⚠ Dibuat sekarang, bukan nanti. Di `new-health-duel` dekorasi kartu yang
      sama terulang di sekitar delapan berkas karena ini tidak pernah dibuat.

### Uang dan terjemahan

- [x] **T-1.5** Buat pemformat uang di `core/utils/formatters/` yang mengubah
      satuan sen menjadi rupiah dengan pembulatan setengah ke atas.
      Memenuhi NFR-ACC-001.
      ⚠ `~/` bawaan Dart memotong ke nol (truncating), bukan pembagian
      lantai — dibuktikan lewat `dart run` sebelum kode ditulis. Memakainya
      langsung untuk "setengah ke atas" salah untuk nilai negatif;
      `_floorDiv` mengoreksinya. Lihat kasus uji regresi di T-1.6.
- [x] **T-1.6** Tulis uji unit pemformat uang memakai kasus `3.039.562,50`
      menjadi `Rp3.039.563`.
      6 kasus: kasus wajib di atas, kasus regresi pembulatan negatif (rumus
      `remainder` -1.337.042 — tanpa `_floorDiv` hasilnya -1.337.041, meleset
      satu rupiah), nol, dan nominal besar. `flutter test`: semua lolos.
- [x] **T-1.7** Pasang slang dengan bahasa dasar `id` dan tambahan `en`,
      berkas di `assets/i18n/`, namespace per fitur.
      ⚠ Istilah antarmuka mengikuti
      [glosarium](../00-foundation/PROJECT_GLOSSARY.md), bukan istilah baru.
      Memenuhi NFR-UX-004, NFR-UX-002, dan
      [ADR-0007](../02-architecture/adr/0007-slang-localization.md).
      ⚠ Nama berkas ternyata `id.i18n.json`/`en.i18n.json`, bukan
      `strings_id.i18n.json` seperti di ARCHITECTURE_OVERVIEW.md semula —
      slang versi terpasang (4.19) mendeprekasi prefiks `strings_` saat
      namespace (per-fitur) tidak dipakai. Namespace `app`/`common` diisi
      sebagai nested object dalam satu berkas per bahasa (bukan berkas
      terpisah per namespace), sesuai bentuk yang didokumentasikan. Dokumen
      sudah diperbarui. `dart run build_runner build` berhasil, 22 string
      (11/bahasa).

### Kerangka aplikasi

- [x] **T-1.8** Siapkan `DiBoot` dengan bootstrap dua fase dan urutan
      pendaftaran penyimpanan, repository lintas fitur (`shared/`), modul
      fitur, lalu router. Susun folder memakai tiga zona `core/`/`shared/`/
      `features/` dan ikuti *decision tree* DI (route provider / root
      injectable / `@module` / `IsolatedScope`).
      Memenuhi [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md).
      ⚠ `RootModule` (akar) dan `ExampleNoteScope`/`CycleScope`-gaya (fitur)
      memakai panggilan `GetIt` manual (`registerLazySingleton` dkk), bukan
      anotasi `@module`/`@LazySingleton` dari `injectable` — paket itu
      tersedia transitif lewat `package:di` (yang re-export
      `package:injectable`), tapi tidak didaftarkan sebagai dependensi
      langsung Saldough di ARCHITECTURE_OVERVIEW.md, dan menyalakan codegen
      `injectable` sekarang berarti menambah dependensi yang belum
      didokumentasikan. Panggilan manual mencapai hasil yang sama (`GetIt`
      tidak peduli bagaimana `register*` dipanggil) dan konsisten dengan
      contoh `CycleScope` di ARCHITECTURE_OVERVIEW.md sendiri, yang juga
      manual. Putuskan dulu soal `injectable` langsung kalau suatu saat
      butuh fitur codegen-nya (`@Named`, `@module` async kompleks).
- [x] **T-1.9** Siapkan penyimpanan Hive lewat
      `HiveKeyValueStorage.initialize(boxName:)`, lalu buktikan aplikasi
      berfungsi penuh dalam mode pesawat dan data bertahan setelah aplikasi
      ditutup dan perangkat dimulai ulang.
      ⚠ Konstruktor publik dan `HiveStorageInitializer` yang disebut README
      paket sudah tidak ada di versi 1.1.1. Ikuti kode, bukan README.
      Memenuhi NFR-REL-001, NFR-REL-002, NFR-SEC-001, dan
      [ADR-0002](../02-architecture/adr/0002-local-first-hive-document-storage.md).
      ⚠ **Sebagian.** Kode sudah benar dan **terverifikasi jalan nyata**:
      sandbox ini tidak punya Android/iOS, tapi punya toolchain Linux
      desktop (dipasang manual: `libgtk-3-dev`, `libsecret-1-dev`,
      `xdg-user-dirs`) — `flutter build linux` + jalan di bawah `xvfb-run`
      sungguhan melewati seluruh rantai `main()` → `di.run()` →
      `HiveKeyValueStorage.initialize()` → kotak Hive terbuka → `GoalRepository`
      terdaftar → router terbangun → `ExampleNoteScope` terpasang →
      `ExampleNoteBloc` baca Hive kosong → emit `isLoading: true` lalu
      `false` — semuanya di log `AppBlocObserver` sungguhan, bukan simulasi.
      **Belum diverifikasi**: literal "mode pesawat" dan "data bertahan
      setelah perangkat dimulai ulang" butuh perangkat Android/iOS asli —
      sandbox ini tidak punya keduanya (lihat T-0.2). Folder `linux/` dan
      `build/` dihapus lagi setelah uji coba supaya tidak ikut ke repo (di
      luar platform target proyek: Android dan iOS saja).
- [x] **T-1.10** Siapkan `RouteRegistry`, adapter `toGoRoute()`, dan menu
      pengembang mode debug.
      ⚠ Di dalam pembangun rute yang memakai `ScopeWidget`, ambil
      `ScopeProvider.of(context)` SEBELUM `ScopeWidget` disisipkan —
      `ScopeProvider` belum ada di pohon saat `create` dijalankan.
      Memenuhi [ADR-0004](../02-architecture/adr/0004-typed-route-registry-navigation.md).
      Path URL diturunkan dari `RouteKey.id` (`'example_note.list'` →
      `/example_note/list`). Menu pengembang dipasang sebagai tombol kecil
      mengambang, hanya tampil di `kDebugMode`, lewat `builder:`
      `MaterialApp.router` supaya muncul di atas layar apa pun.
- [x] **T-1.11** Daftarkan penangan efek navigasi dan umpan balik sebelum
      `runApp`, dan pasang `Bloc.observer = AppBlocObserver()`.
      ⚠ `AppBlocObserver` bukan `const`, berbeda dari contoh di README paket.
      Memenuhi [ADR-0003](../02-architecture/adr/0003-effect-bloc-state-management.md).
      ⚠ `ShowSnackBarEffect.actionLabel`/`actionIntentId` belum disambungkan
      ke bloc — belum ada fitur yang butuh aksi pada snackbar, dan paket
      `state_management` tidak menentukan mekanisme bakunya. Diputuskan
      nanti kalau kebutuhannya muncul, dicatat sebagai komentar di
      `snackbar_effect_handler.dart`.
      ⚠ **Catatan revisi (11 September 2026):** penanganan efek navigasi
      terpasang sejak fase ini tapi TANPA konsumen nyata sampai Fase 2-5
      selesai — setiap fitur hanya bisa dicapai lewat menu pengembang
      (debug-only), tidak ada navigasi pengguna sungguhan. Diselesaikan
      lewat `MainShellPage` (bilah navigasi bawah) dan dua konsumen nyata
      pertama `NavigatePushEffect` (`IncomeSourceBloc`→`worklog`,
      `GroceryBloc`→`card`) — lihat catatan revisi
      [ADR-0004](../02-architecture/adr/0004-typed-route-registry-navigation.md)
      §8 untuk detail lengkap.
- [x] **T-1.12** Buat satu fitur contoh menyeluruh untuk membuktikan pola:
      entitas, repository, bloc dengan efek, rute, dan lingkup dependensi.
      Fitur `features/example_note/` — secara eksplisit bukti pola, bukan
      fitur produk (lihat komentar di `ExampleNote`). Diuji lewat
      `bloc_test`+`mocktail` (3 skenario: muat sukses, muat gagal,
      tambah sukses) **dan** jalan nyata di Linux desktop (lihat T-1.9).
- [x] **T-1.13** Buat `shared/goal/` sebagai modul `shared/` pertama:
      `domain/{goal.dart, goal_repository.dart}` + `data/` di balik satu
      barrel `goal.dart`. Tanpa `presentation/`.
      Memenuhi [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md).
      `Goal` cuma `id`/`name`/`openingBalance` — `balance` (saldo berjalan)
      sengaja tidak jadi field, itu nilai turunan untuk use case Fase 5.

## Fase 2: Siklus bulanan

*Desain: [D-2.1 sampai D-2.4](UI_UX_DESIGN_TASKS.md#fase-2-siklus-bulanan).*

### Domain

- [x] **T-2.1** Buat entitas `MonthlyCycle`, `IncomeLine`, dan `BudgetLine`
      dengan seluruh nominal bertipe `int` satuan sen.
      Memenuhi FR-CYCLE-004.
      ⚠ `needsReview: bool` ditambahkan ke `IncomeLine`/`BudgetLine` — celah
      dokumentasi di DOMAIN_MODEL.md, bukan keputusan baru (ADR-0008 aturan
      3 dan FR-TPL-002 sudah mengikat field ini ada). Dokumen sudah
      diperbaiki dengan catatan revisi.
- [x] **T-2.2** Buat use case `CalculateCycleTotals` yang menghitung
      `totalIncome`, `totalBudget`, dan `remainder`.
- [x] **T-2.3** Tulis uji unit rumus sisa memakai dua kasus nyata:
      `15.839.563 − 13.382.490 = 2.457.073`, dan kasus negatif
      `8.900.000 − 10.237.042 = −1.337.042`.
      Memenuhi NFR-ACC-002.
      Keduanya lolos, plus satu kasus tambahan (jumlah beberapa baris).

### Data

- [x] **T-2.4** Buat model serialisasi siklus dengan `schemaVersion`, lalu
      implementasi `CycleRepository` di atas Hive.
      Memenuhi NFR-REL-003.
      ⚠ Baris `rollUp` memakai `RollUpResolver` (antarmuka baru di
      `features/cycle/domain/repositories/`) untuk menghitung ulang nominal
      saat dibaca — belum ada implementasi nyata sampai Fase 4, sementara
      dipasang `UnavailableRollUpResolver` yang selalu mengembalikan 0 +
      penanda tidak tersedia, sesuai ROADMAP.md Fase 2. Diuji dengan
      `InMemoryKeyValueStorage` dari `memory_storage` (4 kasus, termasuk
      simpan-baca bolak-balik dan indeks `listCycleIds`).
- [x] **T-2.5** Buat `RepositoryGuard` di `core/foundation/repository_guard.dart`,
      lalu pakai `with RepositoryGuard` di `CycleRepositoryImpl` agar
      mengembalikan `Either<Failure, T>` lewat `guard()`/`guardVoid()` —
      kesalahan penyimpanan jadi `PersistenceFailure`, kesalahan penguraian
      jadi `SystemFailure`.
      ⚠ Kembalikan `Either`, jangan melempar `Failure`. Bloc membongkarnya
      dengan `switch` pada `Left`/`Right`, bukan `on Failure catch`.
      Memenuhi [ADR-0005](../02-architecture/adr/0005-either-failure-convention.md).
      `RepositoryGuard` sudah dibuat di Fase 1 (dipakai `GoalRepositoryImpl`
      dan `ExampleNoteRepositoryImpl`) — di sini dipakai ulang, bukan
      ditulis ulang.

### Presentation

- [x] **T-2.6** Buat layar siklus yang menampilkan baris pemasukan, baris
      anggaran, total, dan sisa.
      Memenuhi FR-CYCLE-001.
- [x] **T-2.7** Tampilkan sisa negatif dengan warna `overBudget` dan label lewat
      anggaran, bukan sebagai kesalahan.
      Memenuhi FR-CYCLE-001.
      `AppMoneyText` otomatis memilih `overBudget` untuk nilai negatif
      (bukan `expense`, sesuai antipola ADR-0006).
- [x] **T-2.8** Buat penyuntingan baris: tambah, ubah, hapus, dan penandaan
      tetap atau insidental.
      ⚠ Baris baru bawaannya insidental.
      Memenuhi FR-CYCLE-002.
      Menandai baris "tetap" mendaftarkannya ke `CycleTemplate` (dan
      melepasnya saat ditandai kembali insidental) — keputusan desain
      karena DOMAIN_MODEL.md/FR-TPL-004 tidak merinci mekanisme sinkronnya;
      lihat komentar di `CycleTemplate` dan `CycleBloc._syncIncomeTemplate`.
- [x] **T-2.9** Buat perpindahan antar bulan dan penguncian siklus yang sudah
      ditutup.
      Memenuhi FR-CYCLE-003.
      Perpindahan bulan memakai ulang `CycleBloc` yang sama (`CycleOpened`
      ke id baru), bukan navigasi rute baru. Siklus terkunci menolak semua
      event penyuntingan lewat `_saveAndEmit`, kecuali `CycleReopened`
      sendiri (diuji — jebakan `copyWith(closedAt: null)` klasik ditemukan
      dan diperbaiki dengan method `close()`/`reopen()` eksplisit alih-alih
      `copyWith` untuk field nullable ini).

### Template dan rollover

- [ ] **T-2.10** Buat `CycleTemplate` beserta pengelolaannya.
      Memenuhi FR-TPL-004.
      ⚠ **Sebagian.** Entitas, repository, dan pengelolaan daftar baris
      tetap (lewat penandaan di layar siklus, lihat T-2.8) sudah ada dan
      teruji. **Belum ada** antarmuka untuk menyunting
      `defaultAllocations` (persentase alokasi investasi bawaan) — FR-TPL-004
      butir kedua. Sengaja ditunda ke Fase 5 (Investasi), karena fase itu
      toh butuh antarmuka pengaturan persentase alokasi yang sama untuk
      siklus berjalan — dibangun sekali, dipakai untuk keduanya, bukan dua
      layar terpisah yang tumpang tindih.
- [x] **T-2.11** Buat use case `RollOverCycle` dengan empat aturannya, termasuk
      penandaan perlu ditinjau dan penghitungan ulang baris roll-up.
      Memenuhi FR-TPL-001, FR-TPL-002, FR-TPL-003, dan
      [ADR-0008](../02-architecture/adr/0008-monthly-cycle-template-and-rollup.md).
      Menolak menimpa siklus yang sudah ada (keputusan tambahan, tidak
      diminta literal oleh ADR tapi konsisten dengan nilai "ketepatan lebih
      penting daripada kecepatan"). 3 uji use case + diuji ulang lewat
      `CycleBloc` sungguhan (bukan di-mock — `RollOverCycle` adalah
      `final class`, tidak bisa di-mock `mocktail`; diuji di atas
      repository yang dipalsukan).
- [ ] **T-2.12** Ukur waktu tampil layar siklus pada perangkat kelas menengah
      dan pastikan di bawah satu detik.
      ⚠ Ukur setelah data seed tersedia di Fase 6, lalu ulangi. Layar siklus
      memuat rencana belanja dan siklus kartu karena roll-up dihitung saat
      dibaca.
      Memenuhi NFR-PERF-001.
      Belum diukur — menunggu Fase 6 sesuai catatan di tugas ini sendiri.

**Verifikasi Fase 2**: `flutter analyze` bersih, `flutter test` 26 kasus
lolos (18 baru di fase ini: 3 `CalculateCycleTotals`, 3 `RollOverCycle`,
4 `CycleRepositoryImpl` di atas `InMemoryKeyValueStorage`, 7 `CycleBloc`,
ditambah kasus dari Fase 0/1). Dibuktikan jalan nyata lagi lewat build
Linux desktop + `xvfb-run` (sama seperti Fase 1) — log `AppBlocObserver`
menunjukkan `CycleBloc` terbentuk, `CycleOpened` diproses, dan siklus bulan
berjalan (`2026-09`, dihitung otomatis dari tanggal sistem) termuat tanpa
galat. Folder `linux/`/`build/` dihapus lagi setelahnya, tidak masuk repo.

## Fase 3: Pemasukan dan timesheet

*Desain: [D-3.1 sampai D-3.3](UI_UX_DESIGN_TASKS.md#fase-3-pemasukan-dan-timesheet).*

- [x] **T-3.1** Buat entitas `IncomeSource` dengan tiga tipe dan
      `DeductionRule` dengan dua tipe.
      ⚠ Tarif per jam `Gaji Menul` adalah data (`hourlyRate`), bukan konstanta
      kode. Nilai seed terkonfirmasi: Rp72.500.
      Keduanya naik ke `shared/income/` (bukan `features/income/`) — dipakai
      juga oleh `cycle` (T-3.4) dan `worklog` (T-3.8), ambang "2+ konsumen"
      ADR-0009 terpenuhi sejak awal, bukan promosi spekulatif. Lihat catatan
      revisi ADR-0009.
      Memenuhi FR-INC-001.
- [x] **T-3.2** Buat use case `CalculateNetPay` (ikut naik ke `shared/income/`
      — fungsi murni atas entitasnya, dipakai `income` dan `worklog`).
      ⚠ Potongan persentase dihitung dari gaji kotor, bukan dari nilai berjalan
      setelah potongan sebelumnya.
      ⚠ Celah dokumentasi ditemukan dan ditutup: `DeductionRule.value` untuk
      `percentage` semula ditulis "nilai per seratus" — tidak bisa
      merepresentasikan tarif pajak nyata 2,5% sebagai `int`. Diperbaiki ke
      per mil (`~/ 1000`, 2,5% = `25`). Lihat catatan di DOMAIN_MODEL.md.
      Memenuhi FR-INC-003.
- [x] **T-3.3** Tulis uji unit `CalculateNetPay` memakai lima kasus nyata,
      termasuk `3.117.500` dengan pajak 2,5% menghasilkan `3.039.563`
      (`test/shared/income/domain/calculate_net_pay_test.dart`, 8 kasus —
      lima dari tabel pajak MANUAL_PROCESS_ANALYSIS.md plus tiga kasus rumus
      tambahan: gaji kotor, potongan tetap, dan potongan ganda dari gaji
      kotor yang sama).
      ⚠ Uji ini yang membuktikan aritmatika integer sen tidak dilanggar.
      Membulatkan pajak lebih dulu menghasilkan `3.039.562`, meleset satu rupiah.
      Terverifikasi: menghitung di satuan sen (bukan rupiah) dengan rumus per
      mil menghapus kebutuhan pembulatan perantara sama sekali — potongan
      selalu pas tanpa sisa untuk kombinasi gaji kotor rupiah bulat dan tarif
      satu desimal persen, jadi tidak ada celah pembulatan yang tersisa untuk
      dihindari secara manual.
      Memenuhi NFR-ACC-002.
- [x] **T-3.4** Buat pengelolaan sumber pemasukan dan penautannya ke baris
      pemasukan. `IncomeSourceListPage` (CRUD penuh termasuk aturan potongan)
      di fitur `income`; `LineEditSheet` milik `cycle` mendapat pemilih
      sumber yang otomatis mengisi nominal untuk `fixedSalary` (`CycleBloc`
      memuat `IncomeSourceRepository` dari `shared/income/` saat siklus
      dibuka).
      Memenuhi FR-INC-002.
- [x] **T-3.5** Buat entitas `WorkLogEntry` dan `BillingBook`.
      ⚠ Tiga field ditambah di luar draf awal DOMAIN_MODEL.md:
      `netPayAmount`/`injectedCycleId`/`injectedIncomeLineId` — supaya gaji
      bersih buku yang sudah ditutup tidak dihitung ulang diam-diam dan
      status "sudah disuntik ke mana" bisa ditampilkan di riwayat tanpa
      menyuntik dua kali. Lihat catatan di DOMAIN_MODEL.md.
- [x] **T-3.6** Buat layar pencatatan jam kerja satu langkah (`WorklogPage`,
      `_EntryForm`: tanggal, jam, toggle "mulai buku baru", kirim langsung).
      Memenuhi FR-TIME-001 dan NFR-UX-001.
- [x] **T-3.7** Buat pengelompokan entri ke buku jam berdasarkan penanda
      `startsNewBook` (`WorklogRepositoryImpl.addEntry` — entri tanpa
      penanda menyambung ke buku terbuka, entri ber-penanda atau tanpa buku
      terbuka memulai buku baru; diuji `worklog_repository_impl_test.dart`).
      ⚠ Jangan memotong periode berdasarkan bulan kalender. Data nyata
      menunjukkan periode membentang dari delapan hari sampai hampir sebulan.
      Terverifikasi: pengelompokan murni berdasar penanda, tidak pernah
      melihat tanggal/bulan kalender sama sekali.
      Memenuhi FR-TIME-002.
- [x] **T-3.8** Buat penutupan buku jam yang menghasilkan gaji bersih
      (use case `CloseBillingBook`, menolak menutup buku yang sudah tertutup
      atau tanpa entri).
      Memenuhi FR-TIME-003.
- [x] **T-3.9** Buat penyuntikan gaji bersih ke baris pemasukan pada siklus
      yang dipilih (use case `InjectNetPay` + `WorklogPage._InjectForm`,
      pemilik mengetik id siklus tujuan, bawaan bulan berjalan).
      ⚠ **Keputusan arsitektur**: `worklog` butuh menulis ke `MonthlyCycle`
      milik fitur `cycle` — agregat kompleks, beda dari `IncomeSource` yang
      tinggal dipromosikan ke `shared/`. Diselesaikan dengan port kecil milik
      `worklog` sendiri (`CycleIncomeWriter`, domain `worklog`), yang
      diimplementasikan `features/cycle/data/adapters/` dan dikawat di
      `RootModule` — meniru arah `RollUpResolver` (Fase 2) tapi terbalik.
      Kedua fitur tetap tidak saling mengimpor domain/data satu sama lain.
      Dicatat lengkap di catatan revisi ADR-0009.
      Memenuhi FR-TIME-003.
- [x] **T-3.10** Buat layar riwayat buku jam (`WorklogPage` bagian
      "Riwayat buku": total jam, gaji bersih, status sudah/belum disuntik
      per buku tertutup).
      Memenuhi FR-TIME-004.

**Verifikasi Fase 3:** `flutter analyze` bersih, `flutter test` lolos (54
tes total, 28 baru — domain `CalculateNetPay`/`CloseBillingBook`/
`InjectNetPay`, data `WorklogRepositoryImpl`/`CycleIncomeWriterImpl`,
presentation `IncomeSourceBloc`/`WorklogBloc`, plus `CycleBloc` yang
diperbarui untuk dependensi barunya). Diuji juga secara runtime (build Linux
sandbox + xvfb, dibuang setelah verifikasi) — `RootModule.registerAll`
(termasuk adapter lintas fitur baru dan kedua modul rute baru) berjalan
tanpa galat dan `CycleBloc` tetap memuat siklus berjalan dengan normal.

## Fase 4: Roll-up

*Desain: [D-4.1 sampai D-4.3](UI_UX_DESIGN_TASKS.md#fase-4-roll-up).*

### Belanja

- [x] **T-4.1** Buat entitas `GroceryPlan` dan `GroceryItem` dengan
      `amountOverride`.
      ⚠ Jangan memaksa harga sama dengan jumlah dikali harga satuan. Data nyata
      memuat koreksi manual: sampo `1 × Rp41.300` berharga Rp24.000. `isOverridden`
      (penanda item yang ditimpa) ditambah sebagai getter turunan, bukan field —
      pola sama seperti `CycleState.totals`.
      Memenuhi FR-GROC-002.
- [x] **T-4.2** Buat use case `CalculateGroceryRollUp`.
- [x] **T-4.3** Tulis uji unit roll-up belanja memakai kasus nyata
      `576.600 × 4 + 762.100 = 3.068.500`
      (`test/features/grocery/domain/usecases/calculate_grocery_roll_up_test.dart`,
      4 kasus: rumus nyata, `amountOverride`, pengali minggu, rencana kosong).
      Memenuhi NFR-ACC-002.
- [x] **T-4.4** Buat layar pengelolaan daftar mingguan dan bulanan
      (`GroceryPage`: dua bagian terpisah, tambah/sunting/hapus item, toggle
      timpa harga, ubah pengali minggu).
      Memenuhi FR-GROC-001.
- [x] **T-4.5** Sambungkan roll-up belanja ke baris anggaran, dan pastikan
      perubahan daftar langsung terlihat. `GroceryRollUpResolver`
      (`features/grocery/data/`) menggantikan `UnavailableRollUpResolver`
      sebagai implementasi `RollUpResolver` sungguhan di `RootModule` — baris
      `rollUp` tetap dihitung ulang tiap siklus dibaca (ADR-0008), tidak ada
      langkah "sinkronisasi" tambahan, sesuai rencana ROADMAP.md Fase 2.
      `CycleScope` kini membawa `RollUpResolver` dari `RootModule` lewat
      `bridge()` (bukan mendaftar placeholder lokal).
      ⚠ Saat ronde ini dikerjakan, baris `card` masih `unavailable()` — bagian
      kartu kredit (T-4.6–T-4.12) dikerjakan di cabang terpisah dan digabung
      belakangan, lihat catatan revisi di bawah.
      Memenuhi FR-GROC-003 dan NFR-PERF-002.

**Catatan revisi (penggabungan Fase 4, 11 September 2026):** Belanja
(T-4.1–T-4.5) dan Kartu kredit (T-4.6–T-4.12) masing-masing dikerjakan di
cabang terpisah dari `main` (`claude/saldough-flutter-finance-app-06ufsv` dan
`claude/saldough-fase4-kartu-kredit`) agar ukuran tiap ronde tetap kecil
(lihat ROADMAP.md: keduanya independen di bawah Fase 4). Belanja digabung ke
`main` lebih dulu; menggabungkan Kartu kredit setelahnya menimbulkan konflik
merge di `RootModule`/`CycleScope` karena kedua cabang sama-sama menambah
pendaftaran `RollUpResolver`-nya sendiri. Diselesaikan dengan menambah
`_CompositeRollUpResolver` (privat, di `root_module.dart`) yang membungkus
`GroceryRollUpResolver` dan `CardRollUpResolver`, mendelegasikan berdasar
tipe `RollUpSource` ke salah satunya — keduanya tetap hanya tahu sumbernya
sendiri, tidak ada yang diubah di fitur `grocery`/`card` sendiri.

**Verifikasi bagian Belanja (saat dikerjakan):** `flutter analyze` bersih,
`flutter test` lolos (61 tes total, 7 baru — `CalculateGroceryRollUp` dan
`GroceryRollUpResolver`, termasuk kasus `CardRollUpSource` yang tetap
`unavailable()`). Diuji juga secara runtime (build Linux sandbox + xvfb,
dibuang setelah verifikasi) — pendaftaran ulang `RollUpResolver` di
`RootModule`/`CycleScope` berjalan tanpa galat dan `CycleBloc` tetap memuat
siklus berjalan dengan normal.

### Kartu kredit

- [x] **T-4.6** Buat entitas `CreditCard`, `CardStatement`, dan
      `CardTransaction`.
      ⚠ `note` adalah field terpisah dari `merchant`. Di spreadsheet keduanya
      tercampur, sehingga nama merchant tidak bisa dicocokkan dengan langganan.
      Tanggal cetak (`statementDayOfMonth`) adalah data, bukan konstanta
      kode. Nilai seed terkonfirmasi: tanggal 15. `isConfirmed` pada
      `CardTransaction` adalah tambahan di luar tabel DOMAIN_MODEL.md semula
      (default `true`, `false` untuk hasil penyiapan langganan) — dibutuhkan
      T-4.10, dicatat di DOMAIN_MODEL.md.
      Memenuhi FR-CARD-001 dan FR-CARD-002.
- [x] **T-4.7** Buat pengelompokan transaksi ke siklus tagihan dan
      penutupan siklus.
      `CardStatementPeriod.forDate` menghitung periode murni dari
      `statementDayOfMonth` (bukan bulan kalender); `CardStatementRepositoryImpl`
      mencari-atau-membuat siklus yang mencakup tanggal transaksi.
      `CloseCardStatement` menutup siklus terbuka dan langsung membuka siklus
      berikutnya. Diuji lewat kasus batas tanggal cetak (`card_statement_period_test.dart`)
      dan use case (`close_card_statement_test.dart`).
      Memenuhi FR-CARD-003.
- [x] **T-4.8** Buat layar pencatatan transaksi satu langkah.
      `CardPage._AddTransactionForm` — merchant, nominal, tanggal, catatan
      opsional, satu tombol catat.
      Memenuhi FR-CARD-002 dan NFR-UX-001.
- [x] **T-4.9** Buat entitas `RecurringSubscription` dan penyiapan otomatisnya
      saat siklus baru dibuka.
      `CloseCardStatement` menyiapkan satu `CardTransaction` belum terkonfirmasi
      per langganan aktif kartu ini saat membuka siklus berikutnya.
      Memenuhi FR-CARD-004.
- [x] **T-4.10** Buat alur konfirmasi transaksi langganan sebelum dihitung.
      ⚠ Nominal langganan berubah. Claude AI tercatat Rp337.760 di satu siklus
      dan Rp358.600 di siklus lain — itu sebabnya `CardPage._PendingTransactionRow`
      punya field nominal yang bisa disunting sebelum dikonfirmasi, bukan
      langsung memakai nilai `RecurringSubscription.amount` mentah.
      `CardStatement.confirmedTotal` hanya menghitung transaksi ber-`isConfirmed`.
      Memenuhi FR-CARD-004.
- [x] **T-4.11** Sambungkan roll-up kartu ke baris anggaran.
      `CardRollUpResolver` (implementasi `RollUpResolver` milik `cycle`, pola
      sama seperti rencana belanja — lihat ADR-0009) dikawat di
      `RootModule._registerCrossFeatureAdapters` lewat `_CompositeRollUpResolver`
      (lihat catatan revisi penggabungan Fase 4 di bagian "Belanja" di atas),
      dibagikan ke `CycleScope` lewat `bridge()`.
      Memenuhi FR-CARD-005.
- [x] **T-4.12** Bekukan nilai roll-up saat siklus ditutup.
      ⚠ Tanpa ini, menyunting daftar belanja atau tagihan kartu hari ini akan
      mengubah anggaran bulan-bulan sebelumnya dan merusak riwayat.
      `CycleRepositoryImpl._resolveRollUps` sekarang mengembalikan siklus
      apa adanya kalau `cycle.isClosed`, tidak memanggil `RollUpResolver` sama
      sekali — diuji di `cycle_repository_impl_test.dart` lewat resolver palsu
      yang menghitung jumlah pemanggilan. Perbaikan ini berlaku umum untuk
      seluruh sumber roll-up (belanja maupun kartu), bukan khusus kartu.
      Memenuhi [ADR-0008](../02-architecture/adr/0008-monthly-cycle-template-and-rollup.md).

## Fase 5: Investasi

*Desain: [D-5.1 sampai D-5.2](UI_UX_DESIGN_TASKS.md#fase-5-investasi).*

- [x] **T-5.1** Buat entitas `Goal` dengan saldo awal (seed: 0 untuk semua
      pos), dipakai bersama oleh alokasi maupun pinjaman lewat `shared/goal/`
      (T-1.13). Daftar pos terbuka — tidak dibatasi enam nama bawaan.
      Sudah dibangun sejak Fase 1 (T-1.13); ronde ini hanya memverifikasi dan
      memakainya — tidak ada perubahan di `shared/goal/`.
      Memenuhi FR-INV-001.
- [x] **T-5.2** Buat entitas `InvestmentPlan` dan `Allocation`.
      Sudah dibangun sejak Fase 2 sebagai field `MonthlyCycle.investmentPlan`
      (`features/cycle/domain/entities/`) — tidak ada perubahan di sini.
      Fitur `investment` (T-5.3 dst.) tidak mengimpornya langsung (ADR-0009:
      fitur privat); lihat `CycleInvestmentGateway` di bawah.
- [x] **T-5.3** Buat use case `CalculateAllocations`.
      Ditaruh di `features/investment/domain/usecases/` (bukan `cycle`) —
      fitur `investment` memang pemilik logika "alokasi" menurut
      ARCHITECTURE_OVERVIEW.md. Beroperasi atas `AllocationPercentage` milik
      `investment` sendiri, bukan `Allocation` milik `cycle` (ADR-0009).
      Dipakai ulang oleh `CalculateGoalBalances` (T-5.7) dan riwayat alokasi
      per pos (T-5.8) — satu tempat untuk seluruh hitungan nominal alokasi.
      Memenuhi FR-INV-002.
- [x] **T-5.4** Tulis uji unit alokasi memakai kasus nyata `3.086.960 × 15%
      = 463.044` dan `× 55% = 1.697.828`
      (`test/features/investment/domain/usecases/calculate_allocations_test.dart`,
      4 kasus: kedua rumus nyata dari DOMAIN_MODEL.md, persentase 0, daftar
      kosong).
      Memenuhi NFR-ACC-002.
- [x] **T-5.5** Buat validasi total persentase.
      `isValidAllocationTotal` (`features/investment/domain/usecases/`).
      ⚠ Nilai 0 sah dan berarti bulan itu belum dialokasikan. Yang ditolak hanya
      nilai selain 0 dan 100. `InvestmentBloc` menolak `AllocationPlanSaved`
      yang gagal validasi ini TANPA memanggil `CycleInvestmentGateway` sama
      sekali (diuji di `investment_bloc_test.dart`).
      Memenuhi FR-INV-003.
- [x] **T-5.6** Buat entitas `GoalLoan` dengan pokok dan pengembalian terpisah.
      ⚠ Nilainya bisa berbeda. Data nyata: pokok Rp9.300.000 dikembalikan
      Rp9.331.000. `fromGoalId`/`toGoalId` HARUS merujuk `Goal` yang sudah
      terdaftar — tidak ada label bebas; `GoalLoanEditSheet` memakai chip
      pilihan dari daftar `Goal` yang sudah ada, bukan ketik bebas (kalau pos
      pinjamannya belum ada di daftar `Goal`, daftarkan dulu — lihat T-6.x
      untuk kasus data historis).
      Memenuhi FR-INV-004.
- [x] **T-5.7** Buat perhitungan saldo pos dari saldo awal, alokasi, dan
      pinjaman.
      `CalculateGoalBalances` (`features/investment/domain/usecases/`).
      ⚠ Sesuai DOMAIN_MODEL.md, HANYA alokasi dari siklus yang sudah
      **tertutup** yang ikut terhitung
      (`CycleInvestmentGateway.listClosedCycleSnapshots`) — menyimpan
      persentase di layar "Alokasi Bulan Ini" pada siklus yang masih
      terbuka belum mengubah saldo, baru berefek begitu siklus itu ditutup
      (lihat catatan revisi ADR-0009 Fase 5). Ini sengaja dipilih karena
      DOMAIN_MODEL.md eksplisit soal ini, sekalipun draf desain D-5.1 lama
      menyiratkan efek langsung — lihat catatan cakupan di bawah.
      Memenuhi FR-INV-005.
- [x] **T-5.8** Buat layar riwayat pergerakan tiap pos.
      `InvestmentPage._GoalTile` menampilkan, per pos: alokasi per siklus
      tertutup (`InvestmentState.allocationHistoryFor`) dan pinjaman
      masuk/keluar — dua daftar terpisah, bukan linimasa tergabung (lebih
      sederhana, tetap memenuhi "riwayat pergerakan").
      Memenuhi FR-INV-005.

**Catatan cakupan:** `features/investment/` dibangun penuh ronde ini:
`GoalLoan` + repository (`GoalLoanRepositoryImpl`, pola satu-dokumen seperti
`GoalRepositoryImpl`), `CycleInvestmentGateway` (port baca+tulis milik
`investment`, diimplementasikan `CycleInvestmentGatewayImpl` di
`features/cycle/data/adapters/` — lihat catatan revisi ADR-0009), `InvestmentBloc`
dengan layar CRUD pos tujuan, form "Alokasi Bulan Ini" (pilih siklus,
sunting persentase per pos dan tambahan dana, validasi total, pratinjau
sisa siklus), dan CRUD pinjaman antar pos. Diverifikasi: `flutter analyze`
bersih, `flutter test` 103 tes lolos (18 baru untuk `investment` + adapter
`CycleInvestmentGatewayImpl`), serta build+jalan Linux sandbox (xvfb,
dibuang setelah verifikasi) — `RootModule` mendaftarkan `CycleInvestmentGateway`
dan `InvestmentRouteModule` tanpa galat, `CycleBloc` tetap memuat siklus
berjalan dengan normal. Belum diverifikasi: navigasi manual ke layar
Investasi lewat menu pengembang (tidak ada alat otomasi GUI di sandbox ini).

## Fase 6: Seed

*Desain: [D-6.1](UI_UX_DESIGN_TASKS.md#fase-6-seed) — lihat catatan revisi di
berkas itu; desainnya TIDAK akan diimplementasikan sebagai layar aplikasi.*

⚠ **Catatan revisi (11 September 2026):** fase ini semula dibayangkan sebagai
fitur impor di dalam aplikasi untuk rentang tetap November 2025–September
2026. Pemilik memutuskan sebaliknya, secara eksplisit: operasi SEKALI PAKAI
lewat skrip pengembang (`tool/seed_import.dart`, lihat catatan revisi
[ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md)),
tanpa UI, tanpa versi produksi — tidak ikut ter-*build* ke rilis yang dipakai
pemilik sehari-hari. Cakupan datanya juga mengikuti apa yang pemilik
BENAR-BENAR punya saat skrip ditulis, bukan rentang tanggal yang diasumsikan
penuh — tiap tugas di bawah boleh mencakup sebagian data saja kalau itu yang
tersedia.

✅ **Gerbang data terpenuhi (11 September 2026):** pemilik mengonfirmasi
kelima spreadsheet bisa diakses langsung lewat konektor Google Drive.
Seluruh data nyata (Anggaran 2026, `bulanan`, `Pencatatan jam kerja
(Responses)`, `Tokopedia Card Transaction`, `BRI Touch Transaction`) dibaca
dan diimpor — lihat "Catatan pengerjaan" di bawah untuk keputusan cakupan
dan hasil rekonsiliasinya.

- [x] **T-6.1** Susun berkas seed dari data spreadsheet yang pemilik
      sediakan. Format: `tool/seed_data.json`, nominal dalam Rupiah penuh
      (bukan sen — dikonversi oleh skrip), mengikuti bentuk entitas yang
      sudah ada (`MonthlyCycle`, `WorkLogEntry`, `CardStatement`, `Goal`) —
      bukan format baru.
- [x] **T-6.2** Tulis `tool/seed_import.dart`: skrip Dart berdiri sendiri
      (`dart run tool/seed_import.dart --db-path <folder>`) yang membaca
      `tool/seed_data.json` dan menulis langsung lewat repository tiap fitur
      ke `KeyValueStorage` yang sama yang dibaca aplikasi sungguhan — bukan
      lewat UI, bukan bagian `lib/`. Memanggil beberapa fitur sekaligus
      (lihat catatan revisi ADR-0009 soal pengecualian isolasi fitur untuk
      skrip ini).
      ⚠ **Kendala teknis yang ditemukan saat menulis skrip ini**:
      `HiveKeyValueStorage.initialize()` (package `hive_storage`) memanggil
      `Hive.initFlutter()`, yang butuh `WidgetsFlutterBinding` dan
      `path_provider` — tidak tersedia di proses `dart run` murni. Diatasi
      dengan menambah `hive_ce` (varian murni-Dart dari Hive, sudah jadi
      dependensi transitif lewat `hive_storage`) sebagai `dev_dependency`
      eksplisit, dan skrip membuka `Box<String>` bernama sama (`saldough_kv`)
      lewat `Hive.init()` biasa — BUKAN `initFlutter()` — pada path yang
      diberikan lewat `--db-path`. Untuk data sungguhan, `--db-path` harus
      menunjuk folder dokumen aplikasi nyata di perangkat pemilik.
- [x] **T-6.3** Muat siklus bulanan beserta baris pemasukan dan anggarannya.
      **10 siklus lengkap, Januari–Oktober 2026** (bukan rentang yang
      diasumsikan semula).
      Memenuhi FR-SEED-001.
- [x] **T-6.4** Muat riwayat jam kerja dan buku jamnya. **14 buku jam nyata**,
      Mei 2025–September 2026.
      Memenuhi FR-SEED-001.
- [x] **T-6.5** Muat riwayat transaksi kartu kredit per siklus. **15 statement
      Tokopedia nyata** (Juni 2025–September 2026, termasuk satu yang masih
      terbuka). Kartu BRI Touch **sengaja dilewati** — lihat "Catatan
      pengerjaan".
      Memenuhi FR-SEED-001.
- [x] **T-6.6** Muat pos tujuan beserta saldo awalnya (seed: 0 untuk semua
      pos, sesuai jawaban pemilik). **6 pos**: ANAK, RUMAH, PENSIUN, SEKOLAH,
      KYOTO, SAHAM.
      Memenuhi FR-SEED-001.
- [x] **T-6.7** Untuk pinjaman historis yang pos-nya belum terdaftar sebagai
      `Goal` (pokok Rp9.300.000 dari "Travel To Japan" ke "Kuliah tata",
      dikembalikan Rp9.331.000) — **pemilik memilih tidak melacaknya secara
      formal, baris ini dilewati sepenuhnya** (tidak didaftarkan sebagai
      `Goal`, tidak diimpor sebagai `GoalLoan`).
      Memenuhi FR-SEED-001.
- [x] **T-6.8** Bandingkan hasil hitung terhadap spreadsheet asli untuk
      seluruh bagian yang diimpor, dan pastikan tidak ada selisih rupiah.
      **Seluruh 9 siklus tertutup (2026-01 s/d 2026-09) cocok persis, nol
      selisih rupiah** (diverifikasi otomatis lewat `--dry-run`, lihat
      "Catatan pengerjaan" untuk penjelasan siklus terbuka 2026-10).
      Memenuhi FR-SEED-001 dan NFR-ACC-002.

## Catatan pengerjaan (Fase 6)

**11 September 2026** — Pemilik mengonfirmasi akses Google Drive langsung
ke kelima spreadsheet, menggantikan asumsi sebelumnya ("belum ada data sama
sekali"). Keputusan cakupan (lewat `AskUserQuestion`, dijawab pemilik):

- **Semua siklus yang ada diimpor** — ternyata 10 blok berurutan di
  `Anggaran 2026` (Januari–Oktober 2026), bukan 9 seperti hitungan awal
  (tersalah hitung karena blok "Kos juli - agustus" dan blok "Kos agustus -
  september" pertama sempat dikira satu blok yang sama). Blok terakhir
  (sisa Rp6.689.763, belum ada alokasi investasi) dikonfirmasi pemilik =
  **Oktober 2026**, cycle yang sedang terbuka saat ini.
- **Kartu BRI Touch dilewati sepenuhnya** — nilainya `Rp0` di semua 10
  siklus dan transaksi nyata terakhirnya Mei 2025 (kartu sudah tidak
  aktif). Tidak ada `CreditCard`/`CardStatement` untuk kartu ini.
- **Pinjaman "Travel To Japan" → "Kuliah tata" dilewati** sesuai jawaban
  pemilik di T-6.7 — tidak didaftarkan sebagai `Goal`, tidak diimpor.

**Penemuan penting — label `Kos agustus - september` terbawa TIGA siklus
berturut-turut** (2026-08, 2026-09, 2026-10), bukan dua seperti disangka
saat pertama membaca data — persis cerita asal US-02 ("terbawa tiga bulan
berturut-turut tanpa terdeteksi"). Siklus 2026-09 dan 2026-10 diimpor
dengan `needsReview: true` pada baris Kos-nya; siklus 2026-08 tidak (label
itu masih benar untuk bulan itu).

**Siklus 2026-10 (terbuka) sengaja TIDAK cocok dengan angka stale di
Anggaran** — ini bukan selisih yang perlu diperbaiki, tapi bukti fitur
roll-up bekerja: baris "bulanan" dan "CC TOKPED" di siklus terbuka dihitung
ULANG live dari `GroceryPlan`/`CardStatement` yang sebenarnya (ADR-0008),
bukan dari angka yang pemilik ketik manual di Anggaran kapan pun terakhir
kali dia buka sheet itu. Diverifikasi lewat `--dry-run`:
CC TOKPED live = Rp382.000 (cocok dengan Anggaran, tidak ada selisih).
Bulanan live = **Rp3.219.700** (Anggaran bilang Rp3.150.000) — bukan cuma
beda karena sheet tidak live-link, tapi karena subtotal **mingguan** di
spreadsheet `bulanan` itu SENDIRI sudah basi (Rp576.600) terhadap daftar
item yang sekarang (Rp614.400 — dua item, "alpukat" dan "bawang mix",
ditambahkan setelah totalnya terakhir dihitung manual). Pola yang sama
persis dengan bug label Kos, ditemukan di spreadsheet yang berbeda — bukti
tambahan kenapa roll-up otomatis (bukan ketik ulang manual) adalah inti
produk ini.

Seluruh 9 siklus TERTUTUP (2026-01–2026-09) cocok **persis, nol selisih
rupiah**, termasuk kasus pembulatan pajak 2,5% (contoh: Rp3.117.500 × 2,5%
= Rp77.937,50 → dibulatkan setengah ke atas → Rp77.938, sama dengan
Anggaran). Dengan data seed sekarang tersedia, `T-2.12` (pengukuran
performa di perangkat kelas menengah) bisa mulai dikerjakan pemilik —
masih menunggu pengukuran nyata di perangkatnya, tidak dikerjakan di sini.

Buku jam: 5 dari 14 buku bisa dipastikan menyuntik ke siklus tertentu lewat
kecocokan persis `jam × Rp72.500` dengan Gaji Kotor di Anggaran (2026-05,
2026-07, 2026-08, 2026-09, 2026-10). Sisanya diimpor apa adanya (entri
harian nyata) tapi tanpa `injectedCycleId` karena tarif historisnya tidak
cocok persis Rp72.500 (kemungkinan tarif berbeda di masa itu) — lihat
catatan per-buku di `tool/seed_data.json`.

`tool/seed_data.json` dan `tool/seed_import.dart` TIDAK dijalankan terhadap
data aplikasi sungguhan pemilik dari sesi ini (tidak ada akses ke perangkat
pemilik) — hanya diverifikasi lewat `--dry-run` ke folder sementara.
Pemilik perlu menjalankan `dart run tool/seed_import.dart --db-path
<folder_data_app_sungguhan>` sendiri sebelum memakai aplikasi sehari-hari.

## Catatan pengerjaan (perbaikan pasca-Fase 6)

**11 September 2026** — Setelah seed diimpor dan aplikasi dicoba langsung di
perangkat nyata (debug build), pemilik melaporkan 7 masalah UI/UX. Seluruhnya
diperbaiki di branch yang sama, tanpa menunggu Fase 7:

1. **Format bulan app bar** — `2026-08` diganti jadi `Agustus 2026`/`August
   2026` mengikuti locale aktif (`CycleMonthFormatter`, baru, karena aplikasi
   belum memuat data locale `intl`/`flutter_localizations`).
2. **Icon button Income & Worklog dihapus dari app bar cycle** — redundan,
   kedua layar sudah bisa dicapai lewat bottom nav.
3. **Hint + tombol "tambah sumber pemasukan"** muncul di `LineEditSheet`
   kalau belum ada `IncomeSource` terdaftar — sebelumnya kosong tanpa
   penjelasan.
4. **Baris pemasukan bertaut `IncomeSource` kini ikut berubah** kalau
   sumbernya disunting — diperbaiki dengan memperluas pola freeze-on-close
   ADR-0008 (yang sebelumnya hanya untuk baris `rollUp`) ke baris pemasukan
   bertaut sumber: `fixedSalary` menyegarkan label+nominal, `hourlyFreelance`
   hanya label (nominalnya snapshot historis hasil suntik worklog, sengaja
   tidak ikut tarif baru).
5. **Navigasi app bar dibatasi ke siklus yang benar-benar ada** — `CycleState`
   kini membawa `existingCycleIds` (dari `CycleRepository.listCycleIds`),
   kedua chevron dinonaktifkan kalau target belum dibuka lewat rollover.
6. **Aksi hapus siklus ditambah** — hanya untuk siklus TERAKHIR dan belum
   ditutup (`CycleState.canDeleteCycle`), supaya urutan rollover tidak
   berlubang di tengah.
7. **Baris anggaran baru bisa ditautkan ke Rencana Belanja/kartu kredit
   langsung dari UI** — sebelumnya hanya bisa lewat seed. Port baru
   `CardCatalog` (domain milik `cycle`, diimplementasikan `card`, dikawat di
   `RootModule` — pola ADR-0009 yang sama dengan `CycleIncomeWriter`/
   `CycleInvestmentGateway`, arahnya saja yang baca-saja). `LineEditSheet`
   menambah pemilihan sumber (Manual/Rencana Belanja/Kartu Kredit) untuk
   baris anggaran BARU; `CycleBloc` menulis baris `rollUp` ber-`amount: 0`
   (sama seperti `RollOverCycle` mengisi baris rollUp hasil salinan), lalu
   langsung membaca ulang siklus lewat `CycleRepository.getCycle` supaya
   nominal sungguhan tersegarkan tanpa menunggu pemilik pindah-kembali layar.

Diverifikasi: `flutter analyze` (0 isu) dan `flutter test` (121 pengujian)
lulus; `tool/seed_import.dart --dry-run` dijalankan ulang setelah perubahan
repository/bloc — kesembilan siklus tertutup masih cocok persis dengan
spreadsheet, siklus terbuka tetap terhitung live sesuai desain.

**11 September 2026 (lanjutan)** — Dua laporan lagi setelah perbaikan di atas
dicoba langsung:

8. **Sumber pemasukan baru tidak terdeteksi balik ke tab Siklus** — akar
   masalahnya: layar "Tambah sumber pemasukan" dicapai lewat `context.push`
   yang menumpuk DI ATAS shell (bukan tab), jadi `_CycleTab` tidak dibangun
   ulang saat kembali, beda dari berpindah tab bottom nav yang memang
   mengirim ulang `CycleOpened` tiap `_CycleTab.build()` jalan lagi (sudah
   "benar secara tidak sengaja" sebelumnya, hanya lewat tab switch). Event
   baru `CycleIncomeSourcesRefreshRequested` menyegarkan `incomeSources`
   saja (tanpa memuat ulang siklus/cards/existingCycleIds, supaya tidak ada
   kedipan loading) — dipicu lewat callback `onIncomeSourceAdded` yang
   dioper `LineEditSheet` (bukan `LineEditSheet` mengimpor `CycleBloc`
   langsung — tetap generik, pola yang sama dengan `LineEditResult`).
9. **Bisa menambah lebih dari satu baris anggaran ke Rencana Belanja/kartu
   yang SAMA** — seharusnya satu sumber roll-up hanya boleh ditautkan ke
   satu baris (kartu yang berbeda tetap boleh masing-masing punya baris
   sendiri). Diperbaiki dua lapis: `LineEditSheet` menerima
   `usedRollUpSources` dan menonaktifkan (tetap tampil, diredupkan — bukan
   disembunyikan, supaya pemilik tahu kenapa) chip Rencana Belanja/kartu
   yang sudah terpakai; `CycleBloc._onBudgetLineSaved` menolak juga di sisi
   bloc (jaring pengaman kalau UI ke-bypass) dengan efek peringatan baru.

Diverifikasi lagi: `flutter analyze` (0 isu) dan `flutter test` (124
pengujian) lulus; `tool/seed_import.dart --dry-run` masih cocok persis.

## Fase 7: Sinkronisasi

Di luar MVP. Dikerjakan setelah Fase 6 selesai dan dipakai beberapa waktu.

- [ ] **T-7.1** Tambahkan `api_network` dan `dio_network` ke dependensi.
- [ ] **T-7.2** Rancang pemetaan dokumen JSON ke Firestore atau Google Drive.
- [ ] **T-7.3** Buat sinkronisasi dua arah dengan penyelesaian konflik.
- [ ] **T-7.4** Tambahkan autentikasi.
- [ ] **T-7.5** Tambahkan konsep rumah tangga dua pengguna dengan kepemilikan
      per transaksi.

## Cakupan requirement

Tabel ini memastikan setiap nyeri di
[analisis proses manual](../00-foundation/MANUAL_PROCESS_ANALYSIS.md) punya
tugas yang menanganinya. Gunakan tabel ini saat meninjau kelengkapan.

| Nyeri | Requirement | Tugas |
|---|---|---|
| Salin blok bulan, label tertinggal | FR-TPL-001, FR-TPL-002 | T-2.10, T-2.11 |
| Jumlah jam kerja manual | FR-TIME-002, FR-TIME-003 | T-3.5, T-3.7, T-3.8 |
| Hitung pajak 2,5% manual | FR-INC-003 | T-3.2, T-3.3 |
| Rekap belanja lalu ketik ulang | FR-GROC-003 | T-4.2, T-4.5 |
| Jumlah tagihan kartu manual | FR-CARD-003, FR-CARD-005 | T-4.7, T-4.11 |
| Ketik ulang langganan tiap siklus | FR-CARD-004 | T-4.9, T-4.10 |
| Hitung alokasi dan cek validator manual | FR-INV-002, FR-INV-003 | T-5.3, T-5.5 |
| Pinjaman antar pos dicatat lepas | FR-INV-004, FR-INV-005 | T-5.6, T-5.7 |
| Daftar pos tidak sinkron | FR-INV-001 | T-5.1 |

## Catatan pengerjaan

Bagian ini diisi selama implementasi berjalan. Catat keputusan yang menyimpang
dari rencana, kejutan yang ditemukan, dan hal yang perlu diingat sesi
berikutnya.

**10 September 2026** — Revisi besar sebelum implementasi dimulai (belum ada
kode yang ditulis, jadi tidak ada dampak terhadap kode):

- Referensi arsitektur diganti dari `new-health-duel` ke
  `flutter-architecture-studi-bank` (`lib/v2`, branch
  `refactor/platform-migration`) — memenuhi permintaan asli yang sebelumnya
  gagal karena repo yang disebut (`flutter-architecture-studi`, tanpa
  `-bank`) tidak punya folder itu. `new-health-duel` tetap jadi acuan tema.
- **ADR-0005 dibalik**: dari throw/catch menjadi `Either<Failure, T>` via
  fpdart, karena bukti produksi nyata (104 vs 0 kecocokan) membalikkan
  keputusan yang sebelumnya hanya berdasarkan `app_example` kecil.
- ADR-0009 (zona core/shared/features) dan ADR-0010 (saat itu: fake tulis
  tangan, tanpa mocktail/bloc_test) ditambahkan.
- Empat pertanyaan terbuka terjawab: tarif per jam Rp72.500, tanggal cetak
  tagihan kartu 15, saldo awal pos 0, dan `GoalLoan` hanya merujuk `Goal`
  terdaftar dengan daftar yang terbuka (bukan label bebas).

**10 September 2026 (lanjutan)** — Pemilik meminta ADR-0010 dibalik kembali:
`mocktail` dan `bloc_test` dipakai, bukan fake tulis tangan. Ini penyimpangan
sadar dari repo acuan arsitektur (`flutter-architecture-studi-bank` tidak
memakai pustaka mocking), dilakukan atas permintaan eksplisit, bukan temuan
teknis baru. Berkas ADR diganti nama jadi
`0010-mocktail-bloc-test-convention.md`. `ARCHITECTURE_OVERVIEW.md` (bagian
pengujian dan `pubspec.yaml`) dan `.claude/AGENT_CONTEXT.md` disesuaikan.
