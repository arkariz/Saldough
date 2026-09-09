# CLAUDE.md — Konteks proyek Saldough

**Terakhir diperbarui:** 9 September 2026
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
| **Tugas dan progres** | `docs/04-planning/TASK_LIST.md` |
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
| `arkariz/new-health-duel` | Acuan struktur dan tema | Hanya dibaca, jangan diubah |
| `arkariz/flutter-architecture-studi` | **Tidak dipakai** | `lib/v2` tidak ada; `lib/app` memakai Riverpod yang bertentangan |

Paket internal diambil dari `https://github.com/arkariz/advance-mobile-platform`,
bukan dari URL SSH GitLab yang tertulis di pubspec monorepo. URL itu tidak bisa
diakses.

## Preferensi pemilik

- Percakapan dalam bahasa Indonesia.
- Dokumentasi lebih dulu, kode menyusul.
- Prosa dokumen berbahasa Indonesia; nama kelas, field, dan berkas berbahasa
  Inggris.
- Ketepatan angka lebih penting daripada kecepatan. Aplikasi harus menghasilkan
  angka yang sama persis dengan spreadsheet, sampai rupiah terakhir.

## Aturan paling penting

Tiga hal ini paling sering salah kalau pola repositori acuan disalin mentah:

1. **Uang bertipe `int` satuan sen.** Bukan `double`, dan pembulatan hanya saat
   menampilkan.
2. **Kesalahan dilempar, bukan dibungkus `Either`.** Tangkap dengan
   `on Failure catch`, bukan `on Exception catch`.
3. **Mesin state dari `package:state_management`.** Jangan menyalin EffectBloc
   lokal `new-health-duel`, jangan memakai Riverpod.

Aturan selengkapnya ada di `.claude/AGENT_CONTEXT.md`.

## Kalau terhambat

Berhenti dan laporkan ke pemilik. Jangan menebak. Daftar hal yang perlu jawaban
pemilik ada di `.claude/AGENT_CONTEXT.md` bagian "Kapan harus berhenti dan
bertanya".
