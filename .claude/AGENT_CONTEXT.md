# Konteks agent Saldough

**Baca dokumen ini lebih dulu sebelum menyentuh kode apa pun.**

Dokumen ini memuat aturan arsitektur yang mengikat. Alasannya ada di
[ADR](../docs/02-architecture/adr/); di sini hanya aturannya.

## Bacaan wajib sebelum menulis kode

| Urutan | Dokumen | Mengapa |
|---|---|---|
| 1 | [ARCHITECTURE_OVERVIEW.md](../docs/02-architecture/ARCHITECTURE_OVERVIEW.md) | Lapisan, struktur folder, pemetaan paket |
| 2 | [DOMAIN_MODEL.md](../docs/02-architecture/DOMAIN_MODEL.md) | Entitas, rumus, dan aturan representasi uang |
| 3 | [TASK_LIST.md](../docs/04-planning/TASK_LIST.md) | Tugas yang sedang dikerjakan |

## Empat jebakan terbesar

Referensi arsitektur Saldough adalah `arkariz/flutter-architecture-studi-bank`
(branch `refactor/platform-migration`, folder `lib/v2`) — bukan
`new-health-duel` (yang kini hanya acuan tema) dan bukan
`flutter-architecture-studi` tanpa `-bank` (tidak dipakai sama sekali, `lib/v2`
di situ tidak ada, `lib/app` yang ada memakai Riverpod).

| Jebakan | Kesalahan yang mudah terjadi | Yang benar untuk Saldough |
|---|---|---|
| Kesalahan | Menyalin asumsi versi dokumen lama: `throw Failure` + `on Failure catch` | `Either<Failure, T>` via fpdart (`package:dependencies`) + `RepositoryGuard`. Lihat [ADR-0005](../docs/02-architecture/adr/0005-either-failure-convention.md) |
| Bagian legacy repo acuan | Menyalin `ArchitectureBride*`, seam `Get.find()`/`Get.put()`, `getx_nav_effect_handler` | Saldough greenfield: `main()` → `runApp()` langsung, tanpa jembatan apa pun. Itu khusus migrasi GetX mereka |
| Design system repo acuan | Menyalin atau mencoba mengakses `mobile_dsl` (privat, tak bisa diakses) | Tema tetap dari `new-health-duel` ([ADR-0006](../docs/02-architecture/adr/0006-design-token-semantic-color-mapping.md)) |
| Ejaan | Meniru typo `fondation`, `architecture_bride` dari repo acuan | Saldough pakai ejaan baku: `foundation/` |

Struktur folder memakai tiga zona `core/`/`shared/<module>/`/`features/<feature>/`,
bukan feature-first murni — lihat
[ADR-0009](../docs/02-architecture/adr/0009-core-shared-features-zone-layout.md).

## Aturan yang mengikat

### Lapisan dan zona

- Lapisan `domain` **tidak boleh** mengimpor Flutter, Hive, atau
  `api_storage`. Dart murni saja.
- Lapisan `presentation` **tidak boleh** mengimpor lapisan `data`. Keduanya
  bertemu di `domain` lewat antarmuka repository.
- `core/` **tidak pernah** berisi entitas bisnis — hanya infra tanpa makna
  domain (DI, navigasi, effect handler, tema, pemformat, `RepositoryGuard`).
- `shared/<module>/` diimpor hanya lewat barrel-nya (`<module>.dart`), tidak
  pernah lewat jalur berkas di dalamnya. Disusun module-first
  (`domain/`+`data/`), **tanpa `presentation/`** kecuali dicatat eksplisit
  sebagai pengecualian di ADR.
- Impor antar fitur hanya lewat `<fitur>_route_keys.dart`. Jangan pernah
  mengimpor berkas halaman fitur lain.
- Seluruh impor memakai `package:saldough/...`. Impor relatif hanya boleh di
  berkas barrel dan direktif `part`.

### Uang

- Nominal bertipe `int` dalam satuan **sen**, yaitu seperseratus rupiah.
- **Jangan pernah** memakai `double` untuk uang.
- Persentase dihitung sebagai `nilai * persen ~/ 100` pada satuan sen.
- Pembulatan ke rupiah memakai setengah ke atas, dan **hanya** di lapisan
  presentasi.

Alasannya konkret: pajak 2,5% menghasilkan pecahan setengah rupiah. Membulatkan
terlalu dini membuat gaji bersih meleset satu rupiah dari catatan pemilik.
`3.117.500` dikurangi pajak menghasilkan `3.039.563`, bukan `3.039.562`.

### Kesalahan

- Repository dan use case mengembalikan `Future<Either<Failure, T>>`, **bukan**
  `Future<T>` polos dan **bukan** melempar `Failure`.
- Implementasi repository memakai `with RepositoryGuard` dan memanggil
  `guard()`/`guardVoid()` — jangan menulis `try`/`catch` manual.
- Bloc membongkar hasilnya dengan `switch` pada `Left`/`Right`, bukan
  `on Failure catch`.
- Impor `Either`/`left`/`right`/`unit` dari `package:dependencies`, bukan
  langsung dari `package:fpdart`.
- Pesan untuk pengguna diambil dari `failure.userMessage`, tidak pernah dari
  `failure.message`.
- Lihat [ADR-0005](../docs/02-architecture/adr/0005-either-failure-convention.md)
  untuk contoh lengkap `RepositoryGuard` dan alasan kebalikan keputusan ini.

### State

- State fitur memperluas `UiState<T>`.
- `effect` **tidak pernah** masuk `props`.
- Efek fitur ditulis sebagai `extension` di berkas `part`.
- Penangan efek didaftarkan sekali sebelum `runApp`.
- Navigasi yang dipicu logika dikirim sebagai efek, bukan dipanggil dari widget.
- `keyId` pada efek navigasi selalu diambil dari konstanta kunci rute, tidak
  pernah string harfiah.

### Tampilan

- Warna selalu lewat `context.appColors` atau `Theme.of(context).colorScheme`.
- Jarak, sudut, durasi, dan elevasi selalu lewat token. Tidak pernah harfiah.
- Teks antarmuka selalu lewat slang. Tidak pernah harfiah.
- Nominal ditampilkan lewat `AppMoneyText`.
- Di mode gelap, kartu memakai batas rambut, bukan bayangan.

### Penamaan

- Kelas `PascalCase`, variabel `camelCase`, berkas `snake_case`.
- Anggota privat diawali garis bawah.
- Nama entitas tidak disingkat. Tulis `CardStatement`, bukan `CardStmt`.
- Nama slot warna semantik: `income`, `expense`, `overBudget`, `investment`,
  `rollUp`, `needsReview`. Jangan memakai `opponent` atau `gold`.

## Yang TIDAK boleh dilakukan

- Memakai Riverpod, Provider, atau GetX.
- Memakai `freezed`. Monorepo internal tidak memakainya di mana pun.
- Memakai `mocktail` atau `bloc_test`. Pakai fake tulis tangan — lihat
  [ADR-0010](../docs/02-architecture/adr/0010-hand-rolled-test-fakes.md).
- Menyalin `ArchitectureBride*`, seam `Get.find()`, atau `mobile_dsl` dari
  repo acuan arsitektur — itu spesifik migrasi legacy mereka.
- Mengimpor Flutter di lapisan domain.
- Meletakkan entitas bisnis di `core/`.
- Memakai `double` untuk nominal uang.
- Menyunting nominal baris roll-up secara langsung.
- Menyalin nominal baris roll-up saat rollover.
- Menulis `GoalLoan` dengan label bebas — `fromGoalId`/`toGoalId` harus
  merujuk `Goal` yang sudah terdaftar.
- Mengubah branch `main` di repositori manapun.
- Melanjutkan pekerjaan saat terhambat. Berhenti dan laporkan.

## Yang WAJIB dilakukan

- Ikuti **kode** paket internal, bukan README-nya. Beberapa README diketahui
  tidak sinkron dengan kodenya. Contoh: `NavigateGoEffect` menerima `keyId` dan
  `input`, bukan `route`; `AppBlocObserver` bukan `const`; `HiveKeyValueStorage`
  dibuat lewat `initialize(boxName:)` dan `HiveStorageInitializer` sudah tidak
  ada.
- Tulis uji unit untuk setiap rumus domain, memakai angka nyata dari spreadsheet
  sebagai kasus uji.
- Perbarui kotak centang di `TASK_LIST.md` setelah menyelesaikan tugas.
- Centang hanya kalau benar-benar selesai dan terverifikasi. Pekerjaan sebagian
  tetap kosong disertai catatan.

## Nilai seed yang sudah terkonfirmasi (jangan tanya ulang)

Empat hal ini sudah dijawab pemilik pada 10 September 2026 — jangan tanya
ulang, langsung pakai nilainya sebagai data seed (bukan konstanta kode):

| Nilai | Field | Seed |
|---|---|---|
| Tarif per jam `Gaji Menul` | `IncomeSource.hourlyRate` | Rp72.500 |
| Tanggal cetak tagihan kartu | `CreditCard.statementDayOfMonth` | 15 |
| Saldo awal tiap pos tujuan | `Goal.openingBalance` | 0 |
| Daftar pos untuk `GoalLoan` | `fromGoalId`/`toGoalId` | Pos resmi terdaftar saja, daftar terbuka (bukan label bebas) |

## Kapan harus berhenti dan bertanya

Berhenti dan laporkan ke pemilik kalau menemui hal berikut. Jangan menebak.

- `flutter pub get` gagal karena `resolution: workspace` pada paket internal.
  Ini gerbang Fase 0 dan sudah punya jalur pemulihan tertulis di
  [ADR-0001](../docs/02-architecture/adr/0001-internal-package-dependency-strategy.md).
- Hasil hitung berbeda dari spreadsheet. Cari akarnya di aturan pembulatan lebih
  dulu, dan jangan mengubah rumusnya sampai penyebabnya jelas.
- Menemukan konvensi di repo acuan yang belum terdokumentasi di ADR manapun
  dan berdampak signifikan pada kode yang sedang ditulis.

## Kasus uji wajib

Angka berikut sudah diverifikasi terhadap spreadsheet asli dan harus menjadi
kasus uji. Kalau salah satu gagal, ada yang salah pada aturan aritmatika.

| Rumus | Masukan | Keluaran |
|---|---|---|
| `groceryRollUp` | 576.600 × 4 + 762.100 | 3.068.500 |
| `netPay` | kotor 3.117.500, pajak 2,5% | 3.039.563 |
| `netPay` | kotor 2.682.500, pajak 2,5% | 2.615.438 |
| `remainder` | 15.839.563 − 13.382.490 | 2.457.073 |
| `remainder` negatif | 8.900.000 − 10.237.042 | −1.337.042 |
| `allocation` | 3.086.960 × 15% | 463.044 |
| `allocation` | 3.086.960 × 55% | 1.697.828 |
