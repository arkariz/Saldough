# Saldough

Aplikasi Flutter untuk Android dan iOS untuk mencatat dan mengelola keuangan
pribadi. Intinya tiga hal: **di mana uang berada** (Dompet), **apa yang
terjadi padanya** (Transaksi lewat CATAT), dan **ke mana ia direncanakan
pergi** (Anggaran), dengan pekerjaan freelance yang belum dibayar dilacak
lewat Freelance.

Nama tampilan di toko adalah **Tanukonomy** (maskot tanuki juru catat, lihat
[ADR-022](docs/02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md));
"Saldough" tetap menjadi nama kode repositori dan paket Dart.

Aplikasi ini **mencatat**, bukan **melakukan**: ia tidak memindahkan uang,
tidak membayar, dan tidak terhubung ke bank mana pun.

**Status (1 Oktober 2026):** MVP selesai (Fase 0–7), onboarding dan tur
(Fase 9) serta perapian batas arsitektur (Fase 12) selesai; Fase 8 (persiapan
rilis) dan Fase 11 (kategori dan suara) berjalan. Versi `0.3.0+4` (tag terbaru
`0.3.0+4-patch-2`), belum dirilis publik. Progres rinci dan antrean tugas ada di
[TASK_LIST.md](docs/04-planning/TASK_LIST.md).

## Yang sudah berjalan

| Bagian | Isi |
|---|---|
| CATAT | Pemasukan, pengeluaran, dan transfer dari satu lembar, dengan tautan opsional ke pos anggaran |
| Riwayat | Transaksi per bulan dikelompokkan per tanggal, penyaring, pencarian lintas bulan, sunting, hapus dengan Urungkan |
| Dompet | Saldo tercatat, total saldo, rincian dengan ringkasan bulan |
| Anggaran | Anggaran, pos, template, progres per pos, arsip |
| Freelance | Proyek, worklog, pembayaran, pencatatan pembayaran diterima |
| Beranda | Total saldo, arus bulan berjalan, ringkasan anggaran dan freelance |
| Onboarding | Pengenalan sekali, tur spotlight per layar, lapis info |
| Akun (opsional) | Masuk dengan Google atau email; pencatatan inti tidak butuh akun atau koneksi |
| Mata uang | Satu mata uang untuk seluruh aplikasi, bawaan IDR, dipilih saat onboarding |
| Bahasa | Indonesia atau Inggris untuk tampilan dan ucapan, dipilih saat onboarding atau di Akun |
| Kategori | Daftar bawaan pemasukan dan pengeluaran yang bisa diubah |
| Catat pakai suara | Satu ucapan mengisi formulir CATAT untuk ditinjau sebelum disimpan |

Sinkronisasi data keuangan ke server **belum ada**; data tinggal di perangkat.

## Mulai dari mana

Baca [dokumentasi](docs/README.md); halaman itu memuat jalur baca sesuai
peran, termasuk cara menambah task improvement atau fitur baru.

Kalau akan langsung menulis kode, mulai dari
[aturan arsitektur](.claude/AGENT_CONTEXT.md) lalu
[daftar tugas](docs/04-planning/TASK_LIST.md).

## Tumpukan teknologi

| Bagian | Pilihan |
|---|---|
| Kerangka | Flutter 3.47.2, Dart 3.13.2, Android `minSdk` 23 |
| Arsitektur | Tiga zona `core`/`shared`/`features` plus akar komposisi `lib/app/` (ADR-030), mengikuti `flutter-architecture-studi-bank` |
| State | Bloc dengan efek terdaftar, dari `package:state_management` |
| Navigasi | Registri rute bertipe dari `package:navigation`, di atas `go_router` |
| Penyimpanan | Lokal-first, Hive lewat `package:api_storage` dan `package:hive_storage` |
| Kesalahan | `Either<Failure, T>` via fpdart (`package:dependencies`) + `RepositoryGuard` |
| Injeksi dependensi | `package:di`, GetIt dengan lingkup per fitur |
| Terjemahan | slang, bahasa dasar Indonesia dan tambahan Inggris |
| Tema | `PixelTheme` sebagai tema global, bahasa visual pixel-art ([ADR-015](docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md), [ADR-031](docs/02-architecture/adr/0031-pixeltheme-jadi-tema-global.md)) |
| Akun dan analitik | Firebase Auth, Analytics, Crashlytics ([ADR-023](docs/02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md)) |
| Pembaruan kode | Shorebird (`shorebird.yaml`) |

Paket internal berasal dari
[`arkariz/advance-mobile-platform`](https://github.com/arkariz/advance-mobile-platform),
dikonsumsi sebagai git dependency; cara dipinnya dijelaskan di komentar
`pubspec.yaml` dan [ADR-0001](docs/02-architecture/adr/0001-internal-package-dependency-strategy.md).

## Ketepatan angka

Seluruh nominal disimpan sebagai bilangan bulat dalam satuan sen (seperseratus
satuan utama mata uang), dan pembulatan hanya dilakukan saat menampilkan.
Aturan ini bukan pilihan gaya: pajak 2,5% pada penghasilan freelance
menghasilkan pecahan setengah rupiah, dan pembulatan yang terlalu dini membuat
hasilnya meleset satu rupiah dari catatan asli.

Setiap rumus domain diuji memakai angka nyata sebagai kasus uji. Rinciannya di
[model domain](docs/02-architecture/DOMAIN_MODEL.md).

## Menjalankan dan menguji

```
flutter pub get
dart run slang          # setelah mengubah assets/i18n/*.i18n.json
flutter analyze
flutter test
```

Build rilis Android memakai kunci unggah dari `android/key.properties`
(tidak ada di repositori); catatannya ada di T-8.7
[TASK_LIST.md](docs/04-planning/TASK_LIST.md). Tiap `flutter build` menulis
ulang `minSdk` di `android/app/build.gradle.kts`; kembalikan ke `23` sebelum
commit.

## Struktur repositori

```
Saldough/
├── .claude/          # konteks dan aturan untuk agent
├── android/, ios/    # proyek platform
├── assets/           # terjemahan (i18n), ikon, ilustrasi, font
├── docs/             # PRD, arsitektur, ADR, dan rencana
├── lib/              # kode aplikasi: app/ (akar komposisi), core/, shared/, features/
├── test/             # cermin struktur lib/
└── tool/             # skrip pengembang sekali pakai
```
