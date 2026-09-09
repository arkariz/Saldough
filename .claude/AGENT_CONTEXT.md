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

## Tiga jebakan terbesar

Repositori acuan arsitektur, `new-health-duel`, berbeda dari Saldough di tiga
titik. Menyalin polanya tanpa menyadari ini akan salah.

| Hal | `new-health-duel` | **Saldough** |
|---|---|---|
| Kesalahan | `Either<Failure, T>` dengan `dartz` | `throw Failure`, tangkap dengan `on Failure catch` |
| Efek bloc | Kelas EffectBloc lokal | `package:state_management` |
| Navigasi | Konstanta string `AppRoutes` | `RouteKey` bertipe dari `package:navigation` |

Repositori `flutter-architecture-studi` **tidak dipakai sama sekali**. Folder
`lib/v2` yang pernah disebut tidak ada, dan `lib/app` memakai Riverpod yang
bertentangan dengan paket state internal.

## Aturan yang mengikat

### Lapisan

- Lapisan `domain` **tidak boleh** mengimpor Flutter, Hive, atau
  `api_storage`. Dart murni saja.
- Lapisan `presentation` **tidak boleh** mengimpor lapisan `data`. Keduanya
  bertemu di `domain` lewat antarmuka repository.
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

- Repository dan use case mengembalikan `Future<T>`, bukan
  `Future<Either<Failure, T>>`.
- Kegagalan dilempar sebagai turunan `Failure`.
- Penangkapan memakai `on Failure catch`. **`on Exception catch` tidak akan
  menangkapnya**, karena `Failure` bukan turunan `Exception`.
- Setiap penangan event bloc yang menyentuh repository wajib punya
  `on Failure catch`.
- Pesan untuk pengguna diambil dari `failure.userMessage`, tidak pernah dari
  `failure.message`.

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
- Memakai `Either`, `dartz`, atau `fpdart`.
- Memakai `freezed`. Monorepo internal tidak memakainya di mana pun.
- Menyalin kelas dasar EffectBloc dari `new-health-duel`.
- Mengimpor Flutter di lapisan domain.
- Memakai `double` untuk nominal uang.
- Menyunting nominal baris roll-up secara langsung.
- Menyalin nominal baris roll-up saat rollover.
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

## Kapan harus berhenti dan bertanya

Berhenti dan laporkan ke pemilik kalau menemui hal berikut. Jangan menebak.

- `flutter pub get` gagal karena `resolution: workspace` pada paket internal.
  Ini gerbang Fase 0 dan sudah punya jalur pemulihan tertulis di
  [ADR-0001](../docs/02-architecture/adr/0001-internal-package-dependency-strategy.md).
- Butuh tarif per jam `Gaji Menul`. Tidak tercatat di spreadsheet mana pun.
- Butuh tanggal cetak tagihan tiap kartu.
- Butuh saldo awal pos tujuan.
- Perlu memastikan apakah pos di bagian pinjaman sama dengan pos di bagian
  alokasi.
- Hasil hitung berbeda dari spreadsheet. Cari akarnya di aturan pembulatan lebih
  dulu, dan jangan mengubah rumusnya sampai penyebabnya jelas.

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
