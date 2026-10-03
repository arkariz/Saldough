# Konteks agent Saldough

Berkas ini memuat aturan yang mengikat penulisan kode Saldough. Baca sebelum
menyentuh `lib/`, bukan sesudah.

## Bacaan wajib sebelum menulis kode

| Urutan | Dokumen | Mengapa |
|---|---|---|
| 1 | [ARCHITECTURE_OVERVIEW.md](../docs/02-architecture/ARCHITECTURE_OVERVIEW.md) | Lapisan, struktur folder, pemetaan paket |
| 2 | [DOMAIN_MODEL.md](../docs/02-architecture/DOMAIN_MODEL.md) | Entitas, rumus, invarian, dan aturan representasi uang |
| 3 | [TASK_LIST.md](../docs/04-planning/TASK_LIST.md) | Tugas yang sedang dikerjakan beserta jebakannya |
| 4 | [UX_REVIEW_FIXES.md](../docs/04-planning/UX_REVIEW_FIXES.md) | Perbaikan hasil review UX (di luar MVP), aturan dan keputusan yang menunggu pemilik |

## Empat jebakan terbesar

Empat hal ini yang paling sering salah, dan tiga di antaranya gagal **tanpa
gejala yang kelihatan**.

1. **Menulis simbol mata uang atau teks bahasa langsung di kode.** Mata uang
   aktif bisa 14 pilihan ([ADR-025](../docs/02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md)),
   jadi tidak ada `Rp` di widget: tampilkan lewat `AppMoneyText`/
   `AppMoneyFormatter`, input lewat `money_input.dart`. Teks yang dibaca
   pengguna, termasuk sufiks kecil seperti `rb`/`k` pada chip nominal, selalu
   lewat slang di **kedua** bahasa. Percabangan `if (locale == en)` di kode
   adalah tanda salah.
2. **Menyimpan nilai turunan.** `spent`, `remaining`, `progress`, status pos,
   gaji kotor, gaji bersih, dan total saldo semuanya dihitung ulang saat
   diakses. Satu-satunya pengecualian adalah `Wallet.currentBalance`, dan
   pengecualian itu hanya sah kalau `recomputeWalletBalances()` beserta ujinya
   ada.
3. **Stub repository yang statis di uji bloc.** `Bloc` tidak memancarkan state
   yang sama dengan state sebelumnya. Kalau stub `listX()` selalu mengembalikan
   data yang sama, pemuatan ulang setelah penyimpanan akan tampak seperti bloc
   tidak memancarkan apa pun — dan galatnya berbunyi "expected 1 state, got 0",
   bukan menunjuk ke stubnya. Buat stub mencerminkan hasil penulisan terakhir.
4. **Label yang tidak muat di layar sempit.** Font label minimum 11px
   (ADR-020 §3.2), jadi label bahasa Inggris yang panjang terbungkus di 360dp
   (kasus nyata: "Transactions" di tab bawah, kini "History"). Jangan
   memperbaikinya dengan mengecilkan font; pendekkan katanya, dan uji di lebar
   360dp untuk kedua bahasa dengan font asli dimuat (contoh:
   `test/app/shell/app_shell_page_test.dart`). Di uji widget,
   mengganti bahasa harus lewat
   `tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en))`.

## Aturan yang mengikat

### Lapisan dan zona

- Tiga zona tidak tumpang tindih: `core/` (infra, tanpa makna bisnis, tidak
  mengimpor `shared/`/`features/`/`app/`), `shared/<modul>/` (dipakai ≥2
  fitur, module-first; `presentation/` hanya untuk tampilan entitas modul,
  lewat barrel kedua `<modul>_presentation.dart`), `features/<fitur>/`.
  Akar komposisi (`RootModule`, `SaldoughApp`, `AppShellPage`) di `lib/app/`
  (ADR-030).
- `domain/` tidak mengimpor apa pun — tanpa Flutter, tanpa Hive, tanpa paket
  infrastruktur.
- `presentation/` tidak pernah mengimpor `data/` secara langsung.
- `domain/` dan `data/` sebuah fitur privat; fitur lain hanya boleh mengimpor
  `presentation/navigation/<fitur>_route_keys.dart` dan membuka layarnya
  lewat `context.pushRoute(kunci, input)`. Jangan meneruskan bloc antarrute;
  tiap rute memasang scope-nya sendiri di `<fitur>_route_module.dart`.
- Layar yang menampilkan saldo atau transaksi segar lewat `LedgerChanges`
  (ADR-030 §3.4): penulis memancarkan sesudah unit kerja `Right`
  (`RecordTransaction`, `WalletBloc`), pelanggan berlangganan lewat
  `from(this)` dan batal di `close`. Jangan memanggil `*Refreshed` bloc fitur
  lain.
- `test/architecture/import_boundaries_test.dart` menjaga aturan di atas;
  jangan melonggarkannya tanpa ADR.
- Penulisan lintas fitur lewat port kecil milik fitur konsumen, dikawat di
  `RootModule` — bukan lewat promosi ke `shared/`.
- `Wallet` dan `Transaction` tinggal di `shared/` karena dibaca lebih dari dua
  fitur. Presentation-nya tetap di `features/`.

### Uang

- Selalu `int` satuan sen. Tidak pernah `double`.
- Pembulatan hanya saat menampilkan, setengah ke atas, aritmetika bilangan bulat
  murni. Jangan memakai `~/` untuk pembulatan tampilan — ia memotong ke arah nol
  dan salah untuk nilai negatif.
- Potongan persentase disimpan **per mil**, bukan per seratus. Pajak 2,5%
  ditulis `25`.
- Potongan persentase selalu dihitung dari gaji kotor, tidak pernah dari nilai
  berjalan setelah potongan sebelumnya.

### Kesalahan

- Repository mengembalikan `Future<Either<Failure, T>>` lewat mixin
  `RepositoryGuard`. Tidak pernah melempar.
- Bloc membongkarnya dengan `switch (result) { case Left(...) ... case
  Right(...) ... }`.
- `Failure` tidak memperluas `Exception` maupun `Error`, jadi melemparnya
  melanggar lint `only_throw_errors`.

### State

- State memperluas `UiState<T>`. `effect` tidak pernah masuk `props`.
- Efek dibangun di berkas `part` sebagai `extension` privat.
- Efek sekali jalan lewat `UiEffect` dan `EffectListener`. Transisi state yang
  perlu direaksikan UI dipantau `BlocListener`, bukan dijadikan efek.

### Penyimpanan

- Satu dokumen JSON per kunci, tiap dokumen membawa `schemaVersion`.
- Transaksi dipartisi per bulan: `transaction/YYYY-MM`, dengan indeks
  `transaction/_index`. Bulan tujuan ditentukan `transaction.date`, bukan
  `DateTime.now()`.
- Urutan penulisan mengikat: dokumen transaksi lebih dulu, dokumen dompet
  menyusul. Transaksi adalah kebenaran, saldo adalah cache-nya.

### Tampilan

- Warna lewat `context.appColors`, tidak pernah hex literal di berkas widget.
- Ikon lewat `AppIcon(IconKey.xxx)`. `Icons.*` hanya boleh muncul di berkas peta
  ikon.
- Nominal uang selalu lewat `AppMoneyText`/`AppMoneyFormatter`, tidak pernah string `Rp` atau simbol lain di widget.
- Kosakata menyatakan pencatatan, bukan tindakan keuangan.

### Penamaan

- Kelas `PascalCase`, variabel dan fungsi `camelCase`, berkas `snake_case`,
  anggota privat diawali garis bawah.
- Nama entitas domain tidak disingkat.
- Nama dompet dan kategori disimpan sebagai data, bukan enum. Jenis transaksi
  justru `sealed`, karena menambah jenis mengubah aturan perhitungan saldo.

## Yang TIDAK boleh dilakukan

- Memakai Riverpod, Provider, atau GetX.
- Memakai `freezed`. Monorepo internal tidak memakainya di mana pun.
- Membuat fake tulis tangan (`_FakeXyz implements Interface`) — pakai `mocktail`
  dan `bloc_test`; pengecualian hanya antarmuka berperilaku yang tercatat. Lihat
  [ADR-0010](../docs/02-architecture/adr/0010-mocktail-bloc-test-convention.md).
- Menyalin `ArchitectureBride*`, seam `Get.find()`, atau `mobile_dsl` dari repo
  acuan arsitektur.
- Mengimpor Flutter di lapisan domain.
- Meletakkan entitas bisnis di `core/`.
- Memakai `double` untuk nominal uang.
- Menyimpan `spent`, `remaining`, `progress`, atau status pos sebagai field.
- Membuat entitas "ringkasan bulanan". Ringkasan adalah hasil query.
- Membuat transaksi penyeimbang untuk membetulkan catatan yang salah. Sunting
  atau hapus transaksinya, lalu hitung ulang saldo.
- Memperlakukan `initialBalance` sebagai transaksi pemasukan.
- Membuat formulir pencatatan transaksi di luar alur CATAT.
- Menghitung transfer sebagai pemasukan atau pengeluaran.
- Menambah saldo dompet dari worklog. Hanya pencatatan pembayaran diterima yang
  boleh.
- Menghidupkan kembali mekanisme roll-up, rollover, atau `needsReview` dari
  Saldough 1.0.
- Membuat folder `lib/legacy/` atau sejenisnya (kode 1.0 sudah dihapus; pulihkan dari riwayat git kalau perlu).
- Mengubah branch `main` di repositori manapun.
- Melanjutkan pekerjaan saat terhambat. Berhenti dan laporkan.

## Yang WAJIB dilakukan

- Ikuti **kode** paket internal, bukan README-nya. Beberapa README diketahui
  tidak sinkron. Contoh: `NavigateGoEffect` menerima `keyId` dan `input`, bukan
  `route`; `AppBlocObserver` bukan `const`; `HiveKeyValueStorage` dibuat lewat
  `initialize(boxName:)`.
- Tulis uji unit untuk setiap rumus domain, memakai angka nyata sebagai kasus
  uji.
- Jalankan `flutter analyze` dan `flutter test` sebelum tiap PR, dan pastikan
  keduanya bersih.
- Perbarui kotak centang di `TASK_LIST.md` setelah menyelesaikan tugas.
- Centang hanya kalau benar-benar selesai dan terverifikasi. Pekerjaan sebagian
  tetap kosong disertai catatan `⚠ Sebagian`.

## Membuat atau mengubah tampilan

- Pakai skill `tanukonomy-ui` sebelum menyentuh layar, widget, tema, ikon,
  atau teks antarmuka.
- Sumber kebenaran desain adalah artefak pemilik:
  [design system](https://claude.ai/artifact/HHq7YfEY5Wtc1JXtBhzBQS) dan
  [prototipe](https://claude.ai/artifact/L4176HPgR9gCXACe3gyRbZ). Baca dengan
  alat Artifact; tanpa alat itu, baca salinannya di `docs/03-design/`.
- Bandingkan hasil dengan layar prototipe padanannya dan sebut selisih yang
  disengaja di laporan.
- Spawn agen untuk pekerjaan UI? Sertakan baris ini di prompt-nya: "Baca
  `.claude/skills/tanukonomy-ui/SKILL.md` dan ikuti langkah 1 sebelum menulis
  widget."

## Nilai yang sudah terkonfirmasi (jangan tanya ulang)

| Nilai | Angka |
|---|---|
| Tarif freelance per jam | Rp72.500 |
| Potongan pajak freelance | 2,5%, ditulis `25` per mil |
| Ikatan anggaran ke dompet | Wajib, dan menyaring pengeluaran mana yang terhitung |
| Data historis Saldough 1.0 | Tidak diimpor sama sekali; aplikasi mulai dari saldo awal |
| Aksen utama | `brand` `#A94F33` terang, `#EE8A63` gelap (ADR-034; sampai T-14.1 kode masih `#C2410C`/`#F46B1C` dari ADR-016) |

Nilai berikut **belum ada** dan harus diisi pemilik, bukan dikarang: daftar
dompet beserta saldo awalnya. Kategori transaksi sudah punya daftar bawaan
yang bisa diubah pengguna (ADR-026, `built_in_categories.dart`).

## Kapan harus berhenti dan bertanya

Berhenti dan laporkan ke pemilik kalau menemui hal berikut. Jangan menebak.

- `flutter pub get` gagal menyelesaikan paket internal. Jalur pemulihannya ada
  di [ADR-0001](../docs/02-architecture/adr/0001-internal-package-dependency-strategy.md).
- Saldo tersimpan tidak cocok dengan saldo yang dihitung ulang. Cari akarnya di
  urutan penulisan lebih dulu, dan jangan menambal dengan menulis ulang saldo.
- Sebuah uji lama gagal oleh perubahan yang seharusnya tidak menyentuhnya.
  Itu bukti perubahan itu mengubah perilaku lain — cari tahu apa, jangan
  menyunting uji lamanya supaya lulus.
- Kategori, dompet, atau benda lain butuh ikon piksel yang belum ada di
  `assets/icons/`. Pakai Material Symbols di tile berwarna (design system,
  komponen IconTile), jangan merancang ikon piksel sendiri, dan catat di B-22.
- Tampilan yang dibutuhkan tidak ada di design system maupun prototipe
  ([ADR-034](../docs/02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md)).
  Susun dari komponen yang ada, lalu laporkan supaya artefaknya diperbarui.
- Muncul kebutuhan yang tidak disebut PRD 2.0. Pakai implementasi paling
  sederhana yang masuk akal, lalu laporkan sebagai keputusan terbuka.

## Kasus uji wajib

| Rumus | Masukan | Keluaran yang benar |
|---|---|---|
| `netPay` | kotor 3.117.500, pajak 2,5% | 3.039.563 |
| `netPay` | kotor 2.682.500 (37 jam × 72.500), pajak 2,5% | 2.615.438 |
| `currentBalance` | awal 5.000.000, masuk 2.615.438, keluar 3.068.500, transfer keluar 1.000.000 | 3.546.938 |
| `totalBalance` setelah transfer | dompet A −1.000.000, dompet B +1.000.000 | tidak berubah |
| `budget.spent` | pos 1.000.000 + 500.000 + 300.000 + 700.000 + 500.000 | 3.000.000 |
| `item.status` | rencana 1.000.000, terpakai 1.200.000 | `overspent` |

Dua uji berdiri di atas alasan yang berbeda dan keduanya wajib. `netPay`
menjaga aritmetika integer sen — membulatkan pajak lebih dulu menghasilkan
3.039.562, meleset satu rupiah. **Uji saldo tersimpan versus saldo turunan**
menjaga keputusan [ADR-012](../docs/02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md);
tanpa uji itu, menyimpan `Wallet.currentBalance` tidak boleh dilakukan sama
sekali.
