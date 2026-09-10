# Dokumentasi Saldough

Saldough adalah aplikasi Flutter untuk Android dan iOS yang menggantikan sistem
pencatatan keuangan berbasis empat Google Spreadsheet yang dikelola manual.
Dokumentasi ini memuat seluruh keputusan produk dan arsitekturnya.

Halaman ini adalah titik masuk. Ikuti jalur baca yang sesuai peran Anda di
bawah.

**Status proyek:** dokumentasi selesai, implementasi belum dimulai.
**Versi dokumentasi:** 1.1
**Terakhir diperbarui:** 10 September 2026

## Jalur baca

### Baru bergabung di proyek ini

Baca berurutan. Tiga dokumen pertama memakan sekitar 20 menit dan cukup untuk
memahami produknya.

1. [Analisis proses manual](00-foundation/MANUAL_PROCESS_ANALYSIS.md) —
   bagaimana pemilik bekerja hari ini, dan mengapa aplikasi ini dibuat.
2. [Glosarium proyek](00-foundation/PROJECT_GLOSSARY.md) — istilah yang dipakai
   di seluruh dokumen dan kode.
3. [PRD](01-product/prd-saldough-1.0.md) — apa yang dibangun.
4. [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md) — bagaimana
   membangunnya.
5. [Daftar tugas](04-planning/TASK_LIST.md) — apa yang bisa dikerjakan sekarang.

### Akan menulis kode

Mulai dari arsitektur, lalu langsung ke tugas. ADR yang disebut di bawah
menjelaskan konvensi yang divalidasi dari repositori acuan, dan menyalin pola
acuan tanpa membacanya akan salah — terutama karena sebagian konvensi baru
dikonfirmasi lewat eksplorasi kedua (10 September 2026) dan membalik keputusan
pertama.

1. [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md)
2. [Model domain](02-architecture/DOMAIN_MODEL.md) — terutama aturan
   representasi uang.
3. [ADR-0003](02-architecture/adr/0003-effect-bloc-state-management.md),
   [ADR-0004](02-architecture/adr/0004-typed-route-registry-navigation.md),
   [ADR-0005](02-architecture/adr/0005-either-failure-convention.md), dan
   [ADR-0009](02-architecture/adr/0009-core-shared-features-zone-layout.md)
4. [Daftar tugas](04-planning/TASK_LIST.md)

### Meninjau keputusan arsitektur

1. [Roadmap](04-planning/ROADMAP.md) untuk urutan dan alasannya.
2. Seluruh [ADR](02-architecture/adr/) secara berurutan.
3. [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md) untuk
   melihat penerapannya.

## Susunan dokumen

Direktori diberi prefiks angka untuk menegaskan urutan baca.

```
docs/
├── README.md                  # halaman ini
├── 00-foundation/             # asal masalah dan istilah
│   ├── MANUAL_PROCESS_ANALYSIS.md
│   └── PROJECT_GLOSSARY.md
├── 01-product/                # apa yang dibangun
│   ├── prd-saldough-1.0.md
│   └── user-stories.md
├── 02-architecture/           # bagaimana membangunnya
│   ├── ARCHITECTURE_OVERVIEW.md
│   ├── DOMAIN_MODEL.md
│   └── adr/
└── 04-planning/               # urutan dan progres
    ├── ROADMAP.md
    └── TASK_LIST.md
```

## Daftar ADR

| ADR | Judul | Status |
|---|---|---|
| [0000](02-architecture/adr/0000-template.md) | Template | — |
| [0001](02-architecture/adr/0001-internal-package-dependency-strategy.md) | Strategi dependensi paket internal | Accepted |
| [0002](02-architecture/adr/0002-local-first-hive-document-storage.md) | Penyimpanan lokal berbasis dokumen dengan Hive | Accepted |
| [0003](02-architecture/adr/0003-effect-bloc-state-management.md) | State management berbasis bloc dengan efek terdaftar | Accepted |
| [0004](02-architecture/adr/0004-typed-route-registry-navigation.md) | Navigasi lewat registri rute bertipe | Accepted |
| [0005](02-architecture/adr/0005-either-failure-convention.md) | Konvensi kesalahan: `Either<Failure, T>` via fpdart | Accepted (revisi) |
| [0006](02-architecture/adr/0006-design-token-semantic-color-mapping.md) | Token desain dan pemetaan warna semantik | Accepted |
| [0007](02-architecture/adr/0007-slang-localization.md) | Terjemahan antarmuka dengan slang | Accepted |
| [0008](02-architecture/adr/0008-monthly-cycle-template-and-rollup.md) | Siklus bulanan: template, rollover, dan roll-up | Accepted |
| [0009](02-architecture/adr/0009-core-shared-features-zone-layout.md) | Struktur folder: zona core / shared / features | Accepted |
| [0010](02-architecture/adr/0010-hand-rolled-test-fakes.md) | Konvensi pengujian: fake tulis tangan | Accepted |

## Pertanyaan yang sering muncul

| Pertanyaan | Jawabannya ada di |
|---|---|
| Mengapa aplikasi ini dibuat? | [Analisis proses manual](00-foundation/MANUAL_PROCESS_ANALYSIS.md) |
| Apa arti istilah "buku jam" atau "roll-up"? | [Glosarium](00-foundation/PROJECT_GLOSSARY.md) |
| Mengapa nominal disimpan dalam satuan sen? | [Model domain](02-architecture/DOMAIN_MODEL.md), bagian aturan representasi uang |
| Mengapa kesalahan dikembalikan sebagai `Either<Failure, T>`? | [ADR-0005](02-architecture/adr/0005-either-failure-convention.md) |
| Mengapa struktur foldernya tiga zona, bukan feature-first sederhana? | [ADR-0009](02-architecture/adr/0009-core-shared-features-zone-layout.md) |
| Mengapa `flutter-architecture-studi` (tanpa `-bank`) tidak dipakai? | [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md), bagian dasar keputusan |
| Mengapa tidak memakai `mocktail`/`bloc_test`? | [ADR-0010](02-architecture/adr/0010-hand-rolled-test-fakes.md) |
| Apa risiko terbesar proyek ini? | [ADR-0001](02-architecture/adr/0001-internal-package-dependency-strategy.md) |
| Berapa nilai seed yang sudah dikonfirmasi pemilik? | [Model domain](02-architecture/DOMAIN_MODEL.md#nilai-seed-terkonfirmasi) |
| Apa yang dikerjakan berikutnya? | [Daftar tugas](04-planning/TASK_LIST.md) |

## Konvensi penulisan

Aturan ini berlaku untuk seluruh dokumen di direktori ini.

- **Bahasa.** Prosa memakai bahasa Indonesia, karena domainnya berbahasa
  Indonesia dan pembacanya berbahasa Indonesia. Nama kelas, field, dan berkas
  memakai bahasa Inggris.
- **Penamaan berkas.** `SCREAMING_SNAKE_CASE.md` untuk dokumen tetap,
  `kebab-case.md` untuk artefak berversi dan ADR.
- **ADR.** Empat digit berurutan, sembilan seksi sesuai
  [template](02-architecture/adr/0000-template.md). Opsi ditandai
  `(Dipilih)` pada yang menang.
- **Requirement.** Diberi identitas seperti `FR-CYCLE-001` dan dirujuk dari ADR
  maupun daftar tugas.
- **Angka.** Setiap rumus disertai angka bukti dari spreadsheet asli. Jangan
  menulis rumus tanpa buktinya.
- **Struktur.** Satu H1 per dokumen. Setiap judul diikuti minimal satu paragraf
  pengantar sebelum daftar atau sub-judul.
- **Tautan.** Memakai tautan relatif antar dokumen, dengan teks tautan yang
  bermakna saat dibaca terpisah.

## Aturan pemeliharaan

Dokumentasi ini diperlakukan sebagai artefak yang diaudit, bukan spesifikasi
sekali tulis.

- Kotak centang di PRD dan daftar tugas hanya dicentang kalau pekerjaannya
  benar-benar selesai dan terverifikasi.
- Setiap ADR yang dirujuk harus benar-benar ada. Jangan merujuk ADR yang belum
  ditulis.
- Perubahan keputusan arsitektur ditulis sebagai ADR baru yang menggantikan yang
  lama, bukan dengan menyunting ADR lama.
- Temuan baru soal proses manual masuk ke
  [analisis proses manual](00-foundation/MANUAL_PROCESS_ANALYSIS.md) lebih dulu,
  baru diturunkan ke dokumen lain.
