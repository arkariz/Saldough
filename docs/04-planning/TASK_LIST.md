# Daftar tugas dan progres

Dokumen ini adalah daftar kerja Saldough beserta status penyelesaiannya.
Perbarui kotak centang di sini setiap kali sebuah tugas selesai.

Untuk alasan di balik urutan fase, lihat [ROADMAP.md](ROADMAP.md). Untuk
pekerjaan desain visual per fase — yang selesai lebih dulu daripada kode —
lihat [UI_UX_DESIGN_TASKS.md](UI_UX_DESIGN_TASKS.md).

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

Terakhir diperbarui: 10 September 2026.

| Fase | Tugas | Selesai | Status |
|---|---|---|---|
| 0 — Gerbang dependensi | 5 | 3 | Gerbang (T-0.3) lolos — T-0.2 menunggu verifikasi di mesin pemilik |
| 1 — Fondasi | 13 | 0 | Gerbang Fase 0 lolos, siap dimulai |
| 2 — Siklus bulanan | 12 | 0 | Terkunci oleh Fase 1 |
| 3 — Pemasukan dan timesheet | 10 | 0 | Terkunci oleh Fase 2 |
| 4 — Roll-up | 12 | 0 | Terkunci oleh Fase 2 |
| 5 — Investasi | 8 | 0 | Terkunci oleh Fase 2 |
| 6 — Seed | 7 | 0 | Terkunci oleh Fase 5 |
| 7 — Sinkronisasi | 5 | 0 | Di luar MVP |
| **Total MVP** | **67** | **3** | |

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

- [ ] **T-1.1** Buat token `AppSpacing`, `AppRadius`, `AppDurations`, dan
      `AppElevation` sebagai `abstract final class` berkonstruktor privat.
      Memenuhi [ADR-0006](../02-architecture/adr/0006-design-token-semantic-color-mapping.md).
- [ ] **T-1.2** Buat `AppColorsExtension` dengan enam slot semantik keuangan
      (`income`, `expense`, `overBudget`, `investment`, `rollUp`,
      `needsReview`) ditambah slot netral, lengkap dengan `copyWith`, `lerp`,
      dan ekstensi `BuildContext` bernilai cadangan.
      ⚠ Jangan mempertahankan nama slot `opponent` atau `gold`.
- [ ] **T-1.3** Buat `AppTheme` dengan `ThemeData` terang dan gelap, pasangan
      huruf Syne dan DM Sans, serta aturan batas rambut menggantikan bayangan di
      mode gelap. Memenuhi NFR-UX-003.
- [ ] **T-1.4** Buat widget bersama `AppCard`, `AppButton`, `AppChip`, dan
      `AppMoneyText`.
      ⚠ Dibuat sekarang, bukan nanti. Di `new-health-duel` dekorasi kartu yang
      sama terulang di sekitar delapan berkas karena ini tidak pernah dibuat.

### Uang dan terjemahan

- [ ] **T-1.5** Buat pemformat uang di `core/utils/formatters/` yang mengubah
      satuan sen menjadi rupiah dengan pembulatan setengah ke atas.
      Memenuhi NFR-ACC-001.
- [ ] **T-1.6** Tulis uji unit pemformat uang memakai kasus `3.039.562,50`
      menjadi `Rp3.039.563`.
- [ ] **T-1.7** Pasang slang dengan bahasa dasar `id` dan tambahan `en`,
      berkas di `assets/i18n/`, namespace per fitur.
      ⚠ Istilah antarmuka mengikuti
      [glosarium](../00-foundation/PROJECT_GLOSSARY.md), bukan istilah baru.
      Memenuhi NFR-UX-004, NFR-UX-002, dan
      [ADR-0007](../02-architecture/adr/0007-slang-localization.md).

### Kerangka aplikasi

- [ ] **T-1.8** Siapkan `DiBoot` dengan bootstrap dua fase dan urutan
      pendaftaran penyimpanan, repository lintas fitur (`shared/`), modul
      fitur, lalu router. Susun folder memakai tiga zona `core/`/`shared/`/
      `features/` dan ikuti *decision tree* DI (route provider / root
      injectable / `@module` / `IsolatedScope`).
      Memenuhi [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md).
- [ ] **T-1.9** Siapkan penyimpanan Hive lewat
      `HiveKeyValueStorage.initialize(boxName:)`, lalu buktikan aplikasi
      berfungsi penuh dalam mode pesawat dan data bertahan setelah aplikasi
      ditutup dan perangkat dimulai ulang.
      ⚠ Konstruktor publik dan `HiveStorageInitializer` yang disebut README
      paket sudah tidak ada di versi 1.1.1. Ikuti kode, bukan README.
      Memenuhi NFR-REL-001, NFR-REL-002, NFR-SEC-001, dan
      [ADR-0002](../02-architecture/adr/0002-local-first-hive-document-storage.md).
- [ ] **T-1.10** Siapkan `RouteRegistry`, adapter `toGoRoute()`, dan menu
      pengembang mode debug.
      ⚠ Di dalam pembangun rute yang memakai `ScopeWidget`, ambil
      `ScopeProvider.of(context)` SEBELUM `ScopeWidget` disisipkan —
      `ScopeProvider` belum ada di pohon saat `create` dijalankan.
      Memenuhi [ADR-0004](../02-architecture/adr/0004-typed-route-registry-navigation.md).
- [ ] **T-1.11** Daftarkan penangan efek navigasi dan umpan balik sebelum
      `runApp`, dan pasang `Bloc.observer = AppBlocObserver()`.
      ⚠ `AppBlocObserver` bukan `const`, berbeda dari contoh di README paket.
      Memenuhi [ADR-0003](../02-architecture/adr/0003-effect-bloc-state-management.md).
- [ ] **T-1.12** Buat satu fitur contoh menyeluruh untuk membuktikan pola:
      entitas, repository, bloc dengan efek, rute, dan lingkup dependensi.
- [ ] **T-1.13** Buat `shared/goal/` sebagai modul `shared/` pertama:
      `domain/{goal.dart, goal_repository.dart}` + `data/` di balik satu
      barrel `goal.dart`. Tanpa `presentation/`.
      Memenuhi [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md).

## Fase 2: Siklus bulanan

*Desain: [D-2.1 sampai D-2.4](UI_UX_DESIGN_TASKS.md#fase-2-siklus-bulanan).*

### Domain

- [ ] **T-2.1** Buat entitas `MonthlyCycle`, `IncomeLine`, dan `BudgetLine`
      dengan seluruh nominal bertipe `int` satuan sen.
      Memenuhi FR-CYCLE-004.
- [ ] **T-2.2** Buat use case `CalculateCycleTotals` yang menghitung
      `totalIncome`, `totalBudget`, dan `remainder`.
- [ ] **T-2.3** Tulis uji unit rumus sisa memakai dua kasus nyata:
      `15.839.563 − 13.382.490 = 2.457.073`, dan kasus negatif
      `8.900.000 − 10.237.042 = −1.337.042`.
      Memenuhi NFR-ACC-002.

### Data

- [ ] **T-2.4** Buat model serialisasi siklus dengan `schemaVersion`, lalu
      implementasi `CycleRepository` di atas Hive.
      Memenuhi NFR-REL-003.
- [ ] **T-2.5** Buat `RepositoryGuard` di `core/foundation/repository_guard.dart`,
      lalu pakai `with RepositoryGuard` di `CycleRepositoryImpl` agar
      mengembalikan `Either<Failure, T>` lewat `guard()`/`guardVoid()` —
      kesalahan penyimpanan jadi `PersistenceFailure`, kesalahan penguraian
      jadi `SystemFailure`.
      ⚠ Kembalikan `Either`, jangan melempar `Failure`. Bloc membongkarnya
      dengan `switch` pada `Left`/`Right`, bukan `on Failure catch`.
      Memenuhi [ADR-0005](../02-architecture/adr/0005-either-failure-convention.md).

### Presentation

- [ ] **T-2.6** Buat layar siklus yang menampilkan baris pemasukan, baris
      anggaran, total, dan sisa.
      Memenuhi FR-CYCLE-001.
- [ ] **T-2.7** Tampilkan sisa negatif dengan warna `overBudget` dan label lewat
      anggaran, bukan sebagai kesalahan.
      Memenuhi FR-CYCLE-001.
- [ ] **T-2.8** Buat penyuntingan baris: tambah, ubah, hapus, dan penandaan
      tetap atau insidental.
      ⚠ Baris baru bawaannya insidental.
      Memenuhi FR-CYCLE-002.
- [ ] **T-2.9** Buat perpindahan antar bulan dan penguncian siklus yang sudah
      ditutup.
      Memenuhi FR-CYCLE-003.

### Template dan rollover

- [ ] **T-2.10** Buat `CycleTemplate` beserta pengelolaannya.
      Memenuhi FR-TPL-004.
- [ ] **T-2.11** Buat use case `RollOverCycle` dengan empat aturannya, termasuk
      penandaan perlu ditinjau dan penghitungan ulang baris roll-up.
      Memenuhi FR-TPL-001, FR-TPL-002, FR-TPL-003, dan
      [ADR-0008](../02-architecture/adr/0008-monthly-cycle-template-and-rollup.md).
- [ ] **T-2.12** Ukur waktu tampil layar siklus pada perangkat kelas menengah
      dan pastikan di bawah satu detik.
      ⚠ Ukur setelah data seed tersedia di Fase 6, lalu ulangi. Layar siklus
      memuat rencana belanja dan siklus kartu karena roll-up dihitung saat
      dibaca.
      Memenuhi NFR-PERF-001.

## Fase 3: Pemasukan dan timesheet

*Desain: [D-3.1 sampai D-3.3](UI_UX_DESIGN_TASKS.md#fase-3-pemasukan-dan-timesheet).*

- [ ] **T-3.1** Buat entitas `IncomeSource` dengan tiga tipe dan
      `DeductionRule` dengan dua tipe.
      ⚠ Tarif per jam `Gaji Menul` adalah data (`hourlyRate`), bukan konstanta
      kode. Nilai seed terkonfirmasi: Rp72.500.
      Memenuhi FR-INC-001.
- [ ] **T-3.2** Buat use case `CalculateNetPay`.
      ⚠ Potongan persentase dihitung dari gaji kotor, bukan dari nilai berjalan
      setelah potongan sebelumnya.
      Memenuhi FR-INC-003.
- [ ] **T-3.3** Tulis uji unit `CalculateNetPay` memakai lima kasus nyata,
      termasuk `3.117.500` dengan pajak 2,5% menghasilkan `3.039.563`.
      ⚠ Uji ini yang membuktikan aritmatika integer sen tidak dilanggar.
      Membulatkan pajak lebih dulu menghasilkan `3.039.562`, meleset satu rupiah.
      Memenuhi NFR-ACC-002.
- [ ] **T-3.4** Buat pengelolaan sumber pemasukan dan penautannya ke baris
      pemasukan.
      Memenuhi FR-INC-002.
- [ ] **T-3.5** Buat entitas `WorkLogEntry` dan `BillingBook`.
- [ ] **T-3.6** Buat layar pencatatan jam kerja satu langkah.
      Memenuhi FR-TIME-001 dan NFR-UX-001.
- [ ] **T-3.7** Buat pengelompokan entri ke buku jam berdasarkan penanda
      `startsNewBook`.
      ⚠ Jangan memotong periode berdasarkan bulan kalender. Data nyata
      menunjukkan periode membentang dari delapan hari sampai hampir sebulan.
      Memenuhi FR-TIME-002.
- [ ] **T-3.8** Buat penutupan buku jam yang menghasilkan gaji bersih.
      Memenuhi FR-TIME-003.
- [ ] **T-3.9** Buat penyuntikan gaji bersih ke baris pemasukan pada siklus yang
      dipilih.
      Memenuhi FR-TIME-003.
- [ ] **T-3.10** Buat layar riwayat buku jam.
      Memenuhi FR-TIME-004.

## Fase 4: Roll-up

*Desain: [D-4.1 sampai D-4.3](UI_UX_DESIGN_TASKS.md#fase-4-roll-up).*

### Belanja

- [ ] **T-4.1** Buat entitas `GroceryPlan` dan `GroceryItem` dengan
      `amountOverride`.
      ⚠ Jangan memaksa harga sama dengan jumlah dikali harga satuan. Data nyata
      memuat koreksi manual: sampo `1 × Rp41.300` berharga Rp24.000.
      Memenuhi FR-GROC-002.
- [ ] **T-4.2** Buat use case `CalculateGroceryRollUp`.
- [ ] **T-4.3** Tulis uji unit roll-up belanja memakai kasus nyata
      `576.600 × 4 + 762.100 = 3.068.500`.
      Memenuhi NFR-ACC-002.
- [ ] **T-4.4** Buat layar pengelolaan daftar mingguan dan bulanan.
      Memenuhi FR-GROC-001.
- [ ] **T-4.5** Sambungkan roll-up belanja ke baris anggaran, dan pastikan
      perubahan daftar langsung terlihat.
      Memenuhi FR-GROC-003 dan NFR-PERF-002.

### Kartu kredit

- [ ] **T-4.6** Buat entitas `CreditCard`, `CardStatement`, dan
      `CardTransaction`.
      ⚠ `note` adalah field terpisah dari `merchant`. Di spreadsheet keduanya
      tercampur, sehingga nama merchant tidak bisa dicocokkan dengan langganan.
      Tanggal cetak (`statementDayOfMonth`) adalah data, bukan konstanta
      kode. Nilai seed terkonfirmasi: tanggal 15.
      Memenuhi FR-CARD-001 dan FR-CARD-002.
- [ ] **T-4.7** Buat pengelompokan transaksi ke siklus tagihan dan
      penutupan siklus.
      Memenuhi FR-CARD-003.
- [ ] **T-4.8** Buat layar pencatatan transaksi satu langkah.
      Memenuhi FR-CARD-002 dan NFR-UX-001.
- [ ] **T-4.9** Buat entitas `RecurringSubscription` dan penyiapan otomatisnya
      saat siklus baru dibuka.
      Memenuhi FR-CARD-004.
- [ ] **T-4.10** Buat alur konfirmasi transaksi langganan sebelum dihitung.
      ⚠ Nominal langganan berubah. Claude AI tercatat Rp337.760 di satu siklus
      dan Rp358.600 di siklus lain.
      Memenuhi FR-CARD-004.
- [ ] **T-4.11** Sambungkan roll-up kartu ke baris anggaran.
      Memenuhi FR-CARD-005.
- [ ] **T-4.12** Bekukan nilai roll-up saat siklus ditutup.
      ⚠ Tanpa ini, menyunting daftar belanja hari ini akan mengubah anggaran
      bulan-bulan sebelumnya dan merusak riwayat.
      Memenuhi [ADR-0008](../02-architecture/adr/0008-monthly-cycle-template-and-rollup.md).

## Fase 5: Investasi

*Desain: [D-5.1 sampai D-5.2](UI_UX_DESIGN_TASKS.md#fase-5-investasi).*

- [ ] **T-5.1** Buat entitas `Goal` dengan saldo awal (seed: 0 untuk semua
      pos), dipakai bersama oleh alokasi maupun pinjaman lewat `shared/goal/`
      (T-1.13). Daftar pos terbuka — tidak dibatasi enam nama bawaan.
      Memenuhi FR-INV-001.
- [ ] **T-5.2** Buat entitas `InvestmentPlan` dan `Allocation`.
- [ ] **T-5.3** Buat use case `CalculateAllocations`.
      Memenuhi FR-INV-002.
- [ ] **T-5.4** Tulis uji unit alokasi memakai kasus nyata `3.086.960 × 15%
      = 463.044` dan `× 55% = 1.697.828`.
      Memenuhi NFR-ACC-002.
- [ ] **T-5.5** Buat validasi total persentase.
      ⚠ Nilai 0 sah dan berarti bulan itu belum dialokasikan. Yang ditolak hanya
      nilai selain 0 dan 100.
      Memenuhi FR-INV-003.
- [ ] **T-5.6** Buat entitas `GoalLoan` dengan pokok dan pengembalian terpisah.
      ⚠ Nilainya bisa berbeda. Data nyata: pokok Rp9.300.000 dikembalikan
      Rp9.331.000. `fromGoalId`/`toGoalId` HARUS merujuk `Goal` yang sudah
      terdaftar — tidak ada label bebas. Kalau pos pinjamannya belum ada di
      daftar `Goal`, daftarkan dulu (lihat T-6.x untuk kasus data historis).
      Memenuhi FR-INV-004.
- [ ] **T-5.7** Buat perhitungan saldo pos dari saldo awal, alokasi, dan
      pinjaman.
      Memenuhi FR-INV-005.
- [ ] **T-5.8** Buat layar riwayat pergerakan tiap pos.
      Memenuhi FR-INV-005.

## Fase 6: Seed

*Desain: [D-6.1](UI_UX_DESIGN_TASKS.md#fase-6-seed).*

- [ ] **T-6.1** Susun berkas seed dari data spreadsheet November 2025 sampai
      September 2026.
- [ ] **T-6.2** Muat siklus bulanan beserta baris pemasukan dan anggarannya.
      Memenuhi FR-SEED-001.
- [ ] **T-6.3** Muat riwayat jam kerja dan buku jamnya.
      Memenuhi FR-SEED-001.
- [ ] **T-6.4** Muat riwayat transaksi kartu kredit per siklus.
      Memenuhi FR-SEED-001.
- [ ] **T-6.5** Muat pos tujuan beserta saldo awalnya (seed: 0 untuk semua
      pos, sesuai jawaban pemilik).
      Memenuhi FR-SEED-001.
- [ ] **T-6.6** Untuk pinjaman historis yang pos-nya belum terdaftar sebagai
      `Goal` (contoh nyata: "Travel To Japan", "Kuliah tata") — daftarkan
      keduanya sebagai `Goal` baru (`openingBalance` 0) sebelum mengimpor
      transaksi `GoalLoan`-nya. Kalau pemilik tidak mau melacaknya formal,
      lewati baris pinjaman itu dan catat di bagian "Catatan pengerjaan" di
      bawah.
      Memenuhi FR-SEED-001.
- [ ] **T-6.7** Bandingkan seluruh hasil hitung terhadap spreadsheet asli dan
      pastikan tidak ada selisih rupiah.
      ⚠ Ini pembuktian menyeluruh produk. Kalau ada selisih, cari akarnya di
      aturan pembulatan sebelum mengubah apa pun yang lain.
      Memenuhi FR-SEED-001 dan NFR-ACC-002.

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
