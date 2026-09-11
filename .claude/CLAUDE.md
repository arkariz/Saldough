# CLAUDE.md — Konteks proyek Saldough

**Terakhir diperbarui:** 10 September 2026
**Fase saat ini:** Dokumentasi selesai, menunggu Fase 0 (gerbang dependensi)

## Apa ini

Saldough adalah aplikasi Flutter untuk Android dan iOS yang menggantikan sistem
pencatatan keuangan pribadi berbasis empat Google Spreadsheet yang dikelola
manual.

Aplikasi ini menggantikan proses yang sudah berjalan, bukan memperkenalkan cara
menganggar yang baru. Struktur, istilah, dan alurnya sengaja dibuat sama dengan
spreadsheet pemilik. Yang dihapus hanya pekerjaan tangannya.

## Pencarian cepat

| Butuh | Berkas |
|---|---|
| **Aturan arsitektur** | `.claude/AGENT_CONTEXT.md` |
| **Cara kerja pemilik hari ini** | `docs/00-foundation/MANUAL_PROCESS_ANALYSIS.md` |
| **Entitas dan rumus** | `docs/02-architecture/DOMAIN_MODEL.md` |
| **Struktur kode** | `docs/02-architecture/ARCHITECTURE_OVERVIEW.md` |
| **Istilah** | `docs/00-foundation/PROJECT_GLOSSARY.md` |
| **Kebutuhan produk** | `docs/01-product/prd-saldough-1.0.md` |
| **Tugas dan progres (kode)** | `docs/04-planning/TASK_LIST.md` |
| **Tugas dan progres (desain UI/UX)** | `docs/04-planning/UI_UX_DESIGN_TASKS.md` |
| **Keputusan arsitektur** | `docs/02-architecture/adr/` |

## Status

Dokumentasi lengkap. Belum ada satu baris kode Flutter.

Pekerjaan berikutnya adalah **Fase 0**, yaitu membuktikan paket internal bisa
di-resolve. Ini gerbang: jangan memulai fase berikutnya sebelum
`flutter pub get` berhasil. Rinciannya di `docs/04-planning/TASK_LIST.md`.

## Fakta proyek

- Repositori: `arkariz/Saldough`
- Branch kerja: `claude/saldough-flutter-finance-app-06ufsv`
- Nama paket Dart: `saldough`, seluruh impor memakai `package:saldough/...`
- Flutter 3.47.2, Dart 3.13.2, Android `minSdk` 23
- Penyimpanan MVP lokal, tanpa backend
- Terjemahan slang, bahasa dasar `id`, tambahan `en`

## Repositori acuan

| Repositori | Peran | Catatan |
|---|---|---|
| `arkariz/advance-mobile-platform` | Paket internal: state, navigasi, failure, storage, DI | Dipakai sebagai git dependency, dipin per tag |
| `arkariz/flutter-architecture-studi-bank` | **Acuan struktur arsitektur** | Branch `refactor/platform-migration`, folder `lib/v2`. Hanya dibaca, jangan diubah. Jangan salin bagian legacy GetX/`mobile_dsl`-nya |
| `arkariz/new-health-duel` | **Acuan pola teknis theming Flutter saja** (struktur `ThemeExtension`) — bukan lagi acuan visual | Hanya dibaca, jangan diubah. Warna/tipografi (gaya komik/meme) orisinal milik Saldough, lihat [ADR-0006](docs/02-architecture/adr/0006-design-token-semantic-color-mapping.md) |
| `arkariz/flutter-architecture-studi` (tanpa `-bank`) | **Tidak dipakai** | `lib/v2` tidak ada di repo ini; `lib/app` memakai Riverpod yang bertentangan |

Paket internal diambil dari `https://github.com/arkariz/advance-mobile-platform`,
bukan dari URL SSH GitLab yang tertulis di pubspec monorepo. URL itu tidak bisa
diakses. `flutter-architecture-studi-bank` memakai paket identik (nama dan versi
tag sama) dari counterpart privatnya — ini memvalidasi pilihan paket tersebut.

## Preferensi pemilik

- Percakapan dalam bahasa Indonesia.
- Dokumentasi lebih dulu, kode menyusul.
- Prosa dokumen berbahasa Indonesia; nama kelas, field, dan berkas berbahasa
  Inggris.
- Ketepatan angka lebih penting daripada kecepatan. Aplikasi harus menghasilkan
  angka yang sama persis dengan spreadsheet, sampai rupiah terakhir.

## Aturan paling penting

Empat hal ini paling sering salah kalau pola repositori acuan disalin mentah:

1. **Uang bertipe `int` satuan sen.** Bukan `double`, dan pembulatan hanya saat
   menampilkan.
2. **Kesalahan dikembalikan sebagai `Either<Failure, T>`** lewat
   `RepositoryGuard`, bukan dilempar. Bloc membongkarnya dengan `switch` pada
   `Left`/`Right`.
3. **Mesin state dari `package:state_management`.** Jangan pakai Riverpod
   atau GetX, dan jangan salin jembatan legacy GetX dari repo acuan
   arsitektur — itu khusus migrasi mereka.
4. **Struktur folder 3 zona** `core`/`shared`/`features`, bukan feature-first
   murni.

Empat nilai seed (tarif per jam, tanggal cetak kartu, saldo awal pos, dan
desain `GoalLoan`) sudah dikonfirmasi pemilik — lihat
`.claude/AGENT_CONTEXT.md` bagian "Nilai seed yang sudah terkonfirmasi".

Aturan selengkapnya ada di `.claude/AGENT_CONTEXT.md`.

## Kalau terhambat

Berhenti dan laporkan ke pemilik. Jangan menebak. Daftar hal yang perlu jawaban
pemilik ada di `.claude/AGENT_CONTEXT.md` bagian "Kapan harus berhenti dan
bertanya".
