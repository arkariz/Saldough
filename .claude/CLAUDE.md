# CLAUDE.md — Konteks proyek Saldough

**Terakhir diperbarui:** 28 September 2026
**Fase saat ini:** MVP selesai (Fase 0–7); Fase 9 (onboarding, tur spotlight, lapis info) selesai 28 Sep 2026 di branch `claude/fase-9-onboarding`

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
| **Tugas dan progres** | `docs/04-planning/TASK_LIST.md`, plus `docs/04-planning/UX_REVIEW_FIXES.md` (perbaikan hasil review UX), `docs/04-planning/ONBOARDING_PLAN.md` (onboarding dan tur spotlight), `docs/04-planning/PLAY_DATA_SAFETY.md` (draf formulir Keamanan Data Play Console untuk akun/sinkronisasi/analitik), `docs/04-planning/PLAY_STORE_LISTING.md` (setelan toko dan listing Play, ASO) |
| **Keputusan arsitektur** | `docs/02-architecture/adr/` |
| **Situs web (landing, kebijakan privasi, uji coba)** | Repo `arkariz/tanukonomy-web`, progres di `docs/TASKS.md` repo itu |
| **Rujukan visual (layar dan ikon dari pemilik)** | `docs/stitch_pixel_finance_tracker/`, dijelaskan di [ADR-015](../docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md) |
| **Kebiasaan keuangan pemilik** | `docs/00-foundation/MANUAL_PROCESS_ANALYSIS.md` |
| **Dokumen Saldough 1.0** | `docs/99-archive/` |

## Status

**Rebranding:** nama aplikasi baru **Tanukonomy** dipilih 27 Sep 2026
(maskot tanuki juru catat), belum dieksekusi — T-8.3, riset di
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
Beranda). Ini pertama kalinya aplikasi memanggil jaringan; syarat sebelum
submit Play Store (setelan Firebase Console, bukan kode) ada di
`docs/04-planning/PLAY_DATA_SAFETY.md`.
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

Cutover Fase 3 selesai: kode Saldough 1.0 (`cycle`, `card`, `investment`,
`grocery`, `income`, worklog lama, `shared/goal`, `shared/income`) sudah
dihapus, dan kini repositori hanya memuat model **Dompet + Transaksi +
Anggaran**. Baseline sesudah cutover: 11.369 baris Dart di `lib/` (tanpa
berkas `.g.dart`), 33 berkas uji, 333 uji lulus, `flutter analyze` bersih.
Kode 1.0 bisa dipulihkan dari riwayat git (commit `13c7939` sebelum pivot).

Yang sudah berjalan: CATAT (pemasukan, pengeluaran, transfer, dengan tautan
opsional ke pos anggaran), riwayat Transaksi, Dompet, Anggaran (daftar,
rincian, pos, arsip, penyaring), dan Freelance (proyek, worklog, pembayaran,
pencatatan pembayaran diterima; dibuka dari CATAT → Catat Pemasukan).
Beranda (Fase 6) juga sudah berjalan: total saldo, arus bulan berjalan,
ringkasan anggaran dan freelance, transaksi terbaru, dan keadaan kosong.
Fase 7 juga selesai: template anggaran (layar, gandakan, aktif/nonaktif,
anggaran dari template), ikon SVG, bentuk ADR-015, dan poles state.
Seluruh tugas MVP di TASK_LIST sudah tercentang. Keputusan yang menunggu
pemilik ada di bagian "Keputusan terbuka" TASK_LIST. KT-1 sudah diputuskan
dan dikerjakan di T-8.1: transaksi hanya boleh ditautkan ke pos anggaran yang
periodenya mencakup tanggalnya, sehingga anggaran cukup membaca dokumen bulan
periodenya.

**Jalur UX/UI di luar MVP:** 22 perbaikan hasil review UX dan UI 27 Sep
2026 ada di `docs/04-planning/UX_REVIEW_FIXES.md` (UX-1 s.d. UX-22). Saat
mengecek progres, baca dokumen itu bersama TASK_LIST. Seluruh 22 item selesai
28 Sep 2026 (ADR-020 Accepted; UX-1 dikerjakan bersama T-9.6).

**Situs web:** landing Tanukonomy, halaman `/beta` untuk uji coba tertutup,
kebijakan privasi, serta syarat dan ketentuan ada di repo terpisah
`arkariz/tanukonomy-web` (Astro statis, id/en). Tangkapan layarnya dirender
dari aplikasi ini lewat `tools/screenshots/` di repo itu; kalau tampilan
aplikasi berubah besar, render ulang. Klaim di situs (tanpa server, tanpa
akun, tanpa analitik) harus tetap benar terhadap aplikasi.

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
   formulir pencatatan tersendiri di layar mana pun.

Aturan selengkapnya ada di `.claude/AGENT_CONTEXT.md`.

## Kalau terhambat

Berhenti dan laporkan ke pemilik. Jangan menebak. Daftar hal yang perlu jawaban
pemilik ada di `.claude/AGENT_CONTEXT.md` bagian "Kapan harus berhenti dan
bertanya".
