# CLAUDE.md — Konteks proyek Saldough

**Terakhir diperbarui:** 25 September 2026
**Fase saat ini:** Fase 4 — Anggaran (Fase 0–3 selesai)

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
| **Tugas dan progres** | `docs/04-planning/TASK_LIST.md` |
| **Keputusan arsitektur** | `docs/02-architecture/adr/` |
| **Rujukan visual (layar dan ikon dari pemilik)** | `docs/stitch_pixel_finance_tracker/`, dijelaskan di [ADR-015](../docs/02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md) |
| **Kebiasaan keuangan pemilik** | `docs/00-foundation/MANUAL_PROCESS_ANALYSIS.md` |
| **Dokumen Saldough 1.0** | `docs/99-archive/` |

## Status

Cutover Fase 3 selesai: kode Saldough 1.0 (`cycle`, `card`, `investment`,
`grocery`, `income`, worklog lama, `shared/goal`, `shared/income`) sudah
dihapus, dan kini repositori hanya memuat model **Dompet + Transaksi +
Anggaran**. Baseline sesudah cutover: 11.369 baris Dart di `lib/` (tanpa
berkas `.g.dart`), 33 berkas uji, 333 uji lulus, `flutter analyze` bersih.
Kode 1.0 bisa dipulihkan dari riwayat git (commit `13c7939` sebelum pivot).

Yang sudah berjalan: CATAT (pemasukan, pengeluaran, transfer), riwayat
Transaksi, dan Dompet. Berikutnya Fase 4 (Anggaran), lalu Freelance (Fase 5,
`CalculateNetPay` sudah menunggu di `lib/features/freelance/domain/`) dan
Beranda (Fase 6).

## Fakta proyek

- Repositori: `arkariz/Saldough`
- Satu branch dan satu PR per fase, misalnya `claude/pivot-docs-fase-0`
- Nama paket Dart: `saldough`, seluruh impor memakai `package:saldough/...`
- Flutter 3.47.2, Dart 3.13.2, Android `minSdk` 23
- Penyimpanan lokal, tanpa backend, tanpa panggilan jaringan sama sekali
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
