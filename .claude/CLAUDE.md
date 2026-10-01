# CLAUDE.md — Konteks proyek Saldough

**Terakhir diperbarui:** 1 Oktober 2026
**Fase saat ini:** MVP selesai (Fase 0–7), Fase 9 (onboarding, tur spotlight, lapis info) selesai 28 Sep 2026; Fase 8 (tindak lanjut pasca-MVP, persiapan rilis) berjalan; Fase 11 (Catat Cerdas) berjalan; Fase 12 (rapikan batas arsitektur, ADR-030) selesai 1 Okt 2026. Versi `0.3.0+4` (tag terbaru `0.3.0+4-patch-2`), belum dirilis publik.

## Apa ini

Saldough adalah aplikasi Flutter untuk Android dan iOS untuk mencatat dan
mengelola keuangan pribadi. Intinya tiga hal: **di mana uang berada**, **apa
yang terjadi padanya**, dan **ke mana ia direncanakan pergi**.

Aplikasi ini **mencatat**, bukan **melakukan**. Ia tidak memindahkan uang, tidak
membayar, tidak menarik atau menyetor dana, dan tidak terhubung ke bank mana
pun. Batasan itu definisi produk, bukan kekurangan teknis, dan seluruh kosakata
antarmuka harus mencerminkannya: "Catat Transfer", bukan "Transfer Sekarang".

## Pencarian cepat

| Butuh | Berkas |
|---|---|
| **Aturan arsitektur** | `.claude/AGENT_CONTEXT.md` |
| **Entitas dan rumus** | `docs/02-architecture/DOMAIN_MODEL.md` |
| **Struktur kode** | `docs/02-architecture/ARCHITECTURE_OVERVIEW.md` |
| **Istilah** | `docs/00-foundation/PROJECT_GLOSSARY.md` |
| **Kebutuhan produk** | `docs/01-product/prd-saldough-2.0.md` |
| **Tugas, progres, antrean, dan cara menambah tugas baru** | `docs/04-planning/TASK_LIST.md` (bagian "Menambah tugas baru" dan "Antrean"), plus `docs/04-planning/UX_REVIEW_FIXES.md` (perbaikan hasil review UX), `docs/04-planning/ONBOARDING_PLAN.md` (onboarding dan tur spotlight), `docs/04-planning/PLAY_DATA_SAFETY.md` (draf formulir Keamanan Data Play Console untuk akun/sinkronisasi/analitik), `docs/04-planning/PLAY_STORE_LISTING.md` (setelan toko dan listing Play, ASO), `docs/04-planning/VOICE_INPUT_RESEARCH.md` (riset dan rencana Catat lewat Suara serta sistem kategori) |
| **Keputusan arsitektur** | `docs/02-architecture/adr/` |
| **Situs web (landing, kebijakan privasi, uji coba)** | Repo `arkariz/tanukonomy-web`, progres di `docs/TASKS.md` repo itu |
| **Rujukan visual (layar dan ikon dari pemilik)** | `docs/stitch_pixel_finance_tracker/`, dijelaskan di [ADR-015](../docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md) |
| **Kebiasaan keuangan pemilik** | `docs/00-foundation/MANUAL_PROCESS_ANALYSIS.md` |
| **Dokumen Saldough 1.0** | `docs/99-archive/` |
| **Email rilis untuk penguji** | Skill `release-email` (`.claude/skills/release-email/`) |

## Status

**Rebranding:** nama aplikasi **Tanukonomy** (dipilih 27 Sep 2026, maskot
tanuki juru catat) sudah dipakai di aplikasi dan toko; prasyarat merek
dagang/domain/nama toko dilaporkan pemilik selesai 29 Sep 2026. Sisa T-8.3:
sapuan nama di dokumen (B-1) dan ikon iOS (B-12). Riset di
`docs/01-product/ASO_NAME_RESEARCH.md`.

**Fitur online (T-8.4):** invarian lama "tanpa panggilan jaringan sama
sekali" **tidak lagi mutlak**. NFR-SEC-001/NFR-REL-001 di
`docs/01-product/prd-saldough-2.0.md` §8 direvisi 28 Sep 2026 untuk
mengizinkan ini, dengan syarat pencatatan inti (CATAT, Transaksi, Dompet,
Anggaran, Freelance) tetap wajib berfungsi penuh tanpa koneksi.
**Identitas opsional, Analytics, dan Crashlytics sudah masuk kode 29 Sep
2026** — lihat
[ADR-023](../docs/02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md):
`lib/shared/auth/` (Firebase Auth, Google Sign-In + email/sandi untuk
peninjau Play), `lib/core/foundation/analytics/` (Firebase Analytics,
Crashlytics), `lib/features/account/` (layar Akun, ikon di app bar
Beranda). Ini pertama kalinya aplikasi memanggil jaringan; setelan Firebase
Console dan formulir Keamanan Data sudah dikerjakan pemilik (29 Sep 2026);
catatannya ada di `docs/04-planning/PLAY_DATA_SAFETY.md`.
**Akun tetap opsional** (tanpa gerbang login) dan data lokal milik
perangkat, bukan akun —
[ADR-024](../docs/02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)
(29 Sep 2026, T-8.5). Galat auth dipetakan ke `AuthFailureCodes`, teksnya
di i18n `account.errors.*`, bukan di lapisan data.
**Sinkronisasi data keuangan ke server belum ada** — di luar cakupan
ADR-023, proyek terpisah yang jauh lebih besar; tulis ADR baru begitu
desainnya ada, wajib mematuhi ADR-024 §3.3 (ganti akun = data diganti
dengan peringatan, tanpa penggabungan), jangan menebak di kode.

**Mata uang (T-8.6):** satu mata uang untuk seluruh aplikasi, bawaan IDR,
dipilih di layar Akun —
[ADR-025](../docs/02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md).
Nominal tetap `int` sen (seperseratus satuan utama). Tampilkan lewat
`AppMoneyFormatter`, input lewat `money_input.dart`; jangan menulis `Rp`
atau simbol lain langsung di widget.

**Rilis Android (T-8.7):** penandatanganan rilis lewat
`android/key.properties` (gitignore, tidak ada di repo), versi kini `0.3.0+4`,
Shorebird (`shorebird.yaml`), `google-services.json` sudah di repo. Pemilik
sudah membangun, mengunggah, dan mempublikasikan **closed testing** di Play
Console (29 Sep 2026) dan mengisi formulir Keamanan Data serta listing.
**Tab Transaksi bernama Riwayat** (id) / **History** (en) sejak 29 Sep 2026
(T-8.8) karena "Transactions" terbungkus di 360dp; kata "transaksi" sebagai
benda tidak diganti, dan kunci i18n `appShell.transactionsTabLabel` tetap.
Antrean pekerjaan yang sudah diketahui tapi belum dijadwalkan (`B-n`, mis.
sapuan nama Tanukonomy di dokumen, klaim situs yang basi karena akun/analitik
sudah ada, ikon iOS, sinkronisasi) ada di TASK_LIST.

Cutover Fase 3 selesai: kode Saldough 1.0 (`cycle`, `card`, `investment`,
`grocery`, `income`, worklog lama, `shared/goal`, `shared/income`) sudah
dihapus, dan kini repositori hanya memuat model **Dompet + Transaksi +
Anggaran**. Baseline sesudah cutover: 11.369 baris Dart di `lib/` (tanpa
berkas `.g.dart`), 33 berkas uji, 333 uji lulus. Baseline 29 Sep 2026:
28.413 baris, 69 berkas uji, 609 uji lulus, `flutter analyze` tanpa error
atau peringatan (11 info `unnecessary_unawaited` di uji, B-9). Baseline 1 Okt
2026 (sesudah Fase 12): 34.516 baris, 88 berkas uji, 867 uji lulus,
`flutter analyze` bersih; sesudah T-8.10–8.12 (1 Okt 2026): 847 uji lulus
(uji palet 1.0 dan `AppChip` ikut dihapus).
Kode 1.0 bisa dipulihkan dari riwayat git (commit `13c7939` sebelum pivot).

Yang sudah berjalan: CATAT (pemasukan, pengeluaran, transfer, dengan tautan
opsional ke pos anggaran), riwayat Transaksi, Dompet, Anggaran (daftar,
rincian, pos, arsip, penyaring), dan Freelance (proyek, worklog, pembayaran,
pencatatan pembayaran diterima; dibuka dari CATAT → Catat Pemasukan).
Beranda (Fase 6) juga sudah berjalan: total saldo, arus bulan berjalan,
ringkasan anggaran dan freelance, transaksi terbaru, dan keadaan kosong.
Fase 7 juga selesai: template anggaran (layar, gandakan, aktif/nonaktif,
anggaran dari template), ikon SVG, bentuk ADR-015, dan poles state.
Fase 11 (berjalan) menambah kategori bawaan yang bisa diubah (ADR-026),
pilihan bahasa aplikasi (ADR-028), dan Catat pakai suara yang mengisi
formulir CATAT (ADR-027/029); navigasi bawah kini 4 tab dengan dua FAB
(suara dan CATAT) di kanan bawah.
Seluruh tugas MVP di TASK_LIST sudah tercentang. Tugas baru (improvement
atau fitur) ditambahkan mengikuti "Menambah tugas baru" di TASK_LIST; jangan
membuat daftar tugas di dokumen lain. Keputusan yang menunggu
pemilik ada di bagian "Keputusan terbuka" TASK_LIST. KT-1 sudah diputuskan
dan dikerjakan di T-8.1: transaksi hanya boleh ditautkan ke pos anggaran yang
periodenya mencakup tanggalnya, sehingga anggaran cukup membaca dokumen bulan
periodenya.

**Jalur UX/UI di luar MVP:** 22 perbaikan hasil review UX dan UI 27 Sep
2026 ada di `docs/04-planning/UX_REVIEW_FIXES.md` (UX-1 s.d. UX-22). Saat
mengecek progres, baca dokumen itu bersama TASK_LIST. Seluruh 22 item selesai
28 Sep 2026 (ADR-020 Accepted; UX-1 dikerjakan bersama T-9.6).

**Batas arsitektur (Fase 12, ADR-030):** akar komposisi di `lib/app/`;
`core/` tidak mengimpor fitur. Fitur lain dibuka lewat kunci rute
(`<fitur>_route_keys.dart` + `context.pushRoute`), tiap rute memasang
scope-nya sendiri; CATAT, sunting transaksi, dan suara adalah rute alur
transparan fitur `record`. Layar saldo/transaksi segar lewat `LedgerChanges`
(bukan `*Refreshed` dari shell). Tampilan entitas bersama di
`shared/<modul>/presentation/` lewat `<modul>_presentation.dart`. Semua ini
dijaga `test/architecture/import_boundaries_test.dart`.

**Catat dari notifikasi (ADR-032, 1 Okt 2026, berjalan T-11.17–11.21):**
Android saja. Layanan native hanya menampung notifikasi dari aplikasi yang
dipilih pengguna yang lolos filter whitelist-nya (bawaan: frasa pasti transaksi; bukan OTP); Dart memprosesnya saat aplikasi
hidup/dibuka: pola → aturan → Gemini, lalu tingkat otomatis menentukan
dicatat langsung (`RecordTransaction`) atau masuk kotak masuk. Teks notifikasi
paling lama 7 hari di perangkat.

**Tema (ADR-031, 1 Okt 2026):** `PixelTheme.light`/`.dark` adalah tema
`MaterialApp`; jangan membungkus layar atau rute dengan `PixelTheme`/`Theme`.
`AppTheme`, palet 1.0, dan `google_fonts` sudah dihapus. Uji widget yang
warnanya penting memasang `MaterialApp(theme: PixelTheme.light, …)`.

**Situs web:** landing Tanukonomy, halaman `/beta` untuk uji coba tertutup,
kebijakan privasi, serta syarat dan ketentuan ada di repo terpisah
`arkariz/tanukonomy-web` (Astro statis, id/en). Tangkapan layarnya dirender
dari aplikasi ini lewat `tools/screenshots/` di repo itu; kalau tampilan
aplikasi berubah besar, render ulang. Klaim di situs harus tetap benar
terhadap aplikasi: sejak ADR-023 aplikasi punya akun opsional, Analytics, dan
Crashlytics, jadi klaim lama "tanpa akun, tanpa analitik" perlu diganti (B-4).

**Fase 9 (onboarding dan tur):** desainnya di
[ADR-021](../docs/02-architecture/adr/0021-onboarding-dan-tur-spotlight.md).
Progres tutorial dicatat **per langkah** (`SpotlightKey`), jadi elemen yang
baru muncul belakangan disorot sekali saat pertama tampil. Layar baru yang
butuh tur: pasang `SpotlightTarget` di titik pemakaian widget, `TourTrigger`
di halaman, tambah kunci ke `tourSteps` dan teks `tour.*`. Mode gelap
dilunakkan ke arang hangat (ADR-016 §7). Teks antarmuka menjelaskan manfaat
dan cara kerja, bukan penafian ("bukan transfer bank otomatis" dan
sejenisnya sudah dihapus 28 Sep 2026).

## Fakta proyek

- Repositori: `arkariz/Saldough`
- Satu branch dan satu PR per fase, misalnya `claude/pivot-docs-fase-0`
- Nama paket Dart: `saldough`, seluruh impor memakai `package:saldough/...`
- Flutter 3.47.2, Dart 3.13.2, Android `minSdk` 23
- Penyimpanan lokal-first; fitur online sedang direncanakan, lihat "Status"
- Terjemahan slang, bahasa dasar `id`, tambahan `en`
- Keadaan sebelum pivot: commit `13c7939`
- Filter RTK proyek di `.rtk/filters.toml` (`flutter test`/`analyze`/`build`,
  `pub get`). Sesudah mengubahnya: `rtk trust -y` lalu `rtk verify` — kalau
  tidak, filter diam-diam diabaikan.

## Repositori acuan

| Repositori | Peran | Catatan |
|---|---|---|
| `arkariz/advance-mobile-platform` | Paket internal: state, navigasi, failure, storage, DI | Dipakai sebagai git dependency, sebagian dipin ke SHA mentah — lihat komentar di `pubspec.yaml` |
| `arkariz/flutter-architecture-studi-bank` | **Acuan struktur arsitektur** | Branch `refactor/platform-migration`, folder `lib/v2`. Hanya dibaca. Jangan salin bagian legacy GetX/`mobile_dsl`-nya |
| `arkariz/new-health-duel` | **Acuan pola teknis theming saja** (struktur `ThemeExtension`) | Hanya dibaca. Bukan acuan visual — bahasa visual Saldough 2.0 ada di [ADR-015](../docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md) |
| `arkariz/flutter-architecture-studi` (tanpa `-bank`) | **Tidak dipakai** | `lib/v2` tidak ada di repo ini; `lib/app` memakai Riverpod yang bertentangan |

## Preferensi pemilik

- Percakapan dalam bahasa Indonesia.
- Dokumentasi lebih dulu, kode menyusul.
- Prosa dokumen berbahasa Indonesia; nama kelas, field, dan berkas berbahasa
  Inggris.
- Ketepatan angka lebih penting daripada kecepatan.
- **Biaya token dan batas laju pemakaian agen adalah pertimbangan nyata.**
  Kerjakan dengan cara yang paling sedikit ronde verifikasi gagalnya, bukan yang
  paling banyak berkasnya dibaca. Kode yang tidak dibuka biayanya nol.

## Aturan paling penting

Empat aturan teknis, diwarisi utuh dari Saldough 1.0 dan masih berlaku penuh:

1. **Uang bertipe `int` satuan sen.** Bukan `double`, dan pembulatan hanya saat
   menampilkan.
2. **Kesalahan dikembalikan sebagai `Either<Failure, T>`** lewat
   `RepositoryGuard`, bukan dilempar. Bloc membongkarnya dengan `switch` pada
   `Left`/`Right`.
3. **Mesin state dari `package:state_management`.** Jangan pakai Riverpod atau
   GetX.
4. **Struktur folder 3 zona** `core`/`shared`/`features`, bukan feature-first
   murni.

Empat aturan domain, baru di Saldough 2.0 dan paling sering salah:

5. **Anggaran adalah rencana, bukan pemesanan uang.** Membuat anggaran tidak
   pernah mengubah saldo dompet.
6. **Kerja selesai bukan uang diterima.** Worklog tidak pernah menyentuh saldo;
   hanya pencatatan pembayaran diterima yang mengubahnya.
7. **Transfer tidak mengubah total uang**, hanya tempatnya — dan tidak pernah
   dihitung sebagai pemasukan maupun pengeluaran.
8. **CATAT satu-satunya jalur pembuatan transaksi manual.** Jangan membuat
   formulir pencatatan tersendiri di layar mana pun. Pencatatan otomatis dari
   notifikasi (ADR-032, tingkat otomatis 2/3) memakai use case yang sama,
   `RecordTransaction`, tanpa formulir; draf yang perlu ditinjau selalu
   membuka CATAT.

Aturan selengkapnya ada di `.claude/AGENT_CONTEXT.md`.

## Kalau terhambat

Berhenti dan laporkan ke pemilik. Jangan menebak. Daftar hal yang perlu jawaban
pemilik ada di `.claude/AGENT_CONTEXT.md` bagian "Kapan harus berhenti dan
bertanya".
