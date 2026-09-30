# Dokumentasi Saldough

Saldough adalah aplikasi Flutter untuk Android dan iOS untuk mencatat dan
mengelola keuangan pribadi, berporos pada Dompet, Transaksi, dan Anggaran,
dengan Freelance Worklog sebagai domain pendukung. Aplikasi ini mencatat,
bukan melakukan — ia tidak memindahkan uang, tidak membayar, dan tidak
terhubung ke bank mana pun. Dokumentasi ini memuat seluruh keputusan produk
dan arsitekturnya.

Halaman ini adalah titik masuk. Ikuti jalur baca yang sesuai peran Anda di
bawah.

**Status proyek:** MVP selesai (Fase 0–7) dan onboarding selesai (Fase 9);
Fase 8 (tindak lanjut pasca-MVP, persiapan rilis) berjalan. Nama tampilan
aplikasi kini **Tanukonomy** ([ADR-022](02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md));
dokumen ini masih memakai nama kode "Saldough" sampai prasyarat ganti nama
terpenuhi.
**Versi dokumentasi:** 2.1
**Terakhir diperbarui:** 29 September 2026

## Jalur baca

### Baru bergabung di proyek ini

Baca berurutan. Tiga dokumen pertama memakan sekitar 20 menit dan cukup untuk
memahami produknya.

1. [Analisis proses manual](00-foundation/MANUAL_PROCESS_ANALYSIS.md) —
   bagaimana pemilik bekerja hari ini, dan mengapa aplikasi ini dibuat.
2. [Glosarium proyek](00-foundation/PROJECT_GLOSSARY.md) — istilah yang dipakai
   di seluruh dokumen dan kode.
3. [PRD 2.0](01-product/prd-saldough-2.0.md) — apa yang dibangun.
4. [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md) — bagaimana
   membangunnya.
5. [Roadmap](04-planning/ROADMAP.md) — urutan fase pengerjaannya.
6. [Daftar tugas](04-planning/TASK_LIST.md) — apa yang bisa dikerjakan sekarang.

### Akan menulis kode

Mulai dari arsitektur, lalu langsung ke tugas. ADR yang disebut di bawah
menjelaskan konvensi yang divalidasi dari repositori acuan, dan menyalin pola
acuan tanpa membacanya akan salah — terutama karena sebagian konvensi baru
dikonfirmasi lewat eksplorasi kedua dan membalik keputusan pertama.

1. [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md)
2. [Model domain](02-architecture/DOMAIN_MODEL.md) — terutama aturan
   representasi uang dan model Dompet/Transaksi/Anggaran.
3. [ADR-0003](02-architecture/adr/0003-effect-bloc-state-management.md),
   [ADR-0004](02-architecture/adr/0004-typed-route-registry-navigation.md),
   [ADR-0005](02-architecture/adr/0005-either-failure-convention.md),
   [ADR-0009](02-architecture/adr/0009-core-shared-features-zone-layout.md),
   dan
   [ADR-011](02-architecture/adr/0011-model-domain-dompet-transaksi-anggaran.md)
4. [ADR-014](02-architecture/adr/0014-strategi-pivot-saldough-2.md) — strategi
   pivot dan alasannya. Invarian "jangan sentuh fitur lama" sudah tidak
   berlaku sejak cutover Fase 3; kode 1.0 tinggal di riwayat git.
5. [Daftar tugas](04-planning/TASK_LIST.md)

### Menambah task improvement atau fitur

1. [Daftar tugas](04-planning/TASK_LIST.md), bagian "Menambah tugas baru"
   (langkah dan templat), lalu tabel "Antrean" untuk melihat apa yang sudah
   menunggu.
2. [Perbaikan hasil review UX](04-planning/UX_REVIEW_FIXES.md) kalau
   temuannya soal UX atau tampilan; daftar itu punya nomor `UX-n` sendiri.
3. Keputusan yang mengubah arsitektur atau perilaku produk: tulis ADR baru
   (nomor berikutnya di tabel di bawah) dan tautkan dari tugasnya.
4. Setelah selesai, perbarui ringkasan progres di TASK_LIST dan bagian
   "Status" di [`.claude/CLAUDE.md`](../.claude/CLAUDE.md).

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
│   ├── prd-saldough-2.0.md
│   ├── user-stories.md
│   └── ASO_NAME_RESEARCH.md       # riset nama Tanukonomy dan kata kunci toko
├── 02-architecture/           # bagaimana membangunnya
│   ├── ARCHITECTURE_OVERVIEW.md
│   ├── DOMAIN_MODEL.md
│   └── adr/
├── 04-planning/                # urutan dan progres
│   ├── ROADMAP.md
│   ├── TASK_LIST.md           # tugas, progres, antrean B-n; mulai dari sini
│   ├── UI_UX_DESIGN_TASKS.md  # rencana desain awal (tidak dipakai, lihat bannernya)
│   ├── UX_REVIEW_FIXES.md     # perbaikan hasil review UX 2.0 (UX-1..UX-22)
│   ├── ONBOARDING_PLAN.md     # rencana onboarding dan tur (Fase 9)
│   ├── ONBOARDING_ART_BRIEF.md
│   ├── PLAY_DATA_SAFETY.md    # draf formulir Keamanan Data Play Console
│   └── PLAY_STORE_LISTING.md  # setelan toko dan listing Play (ASO)
├── stitch_pixel_finance_tracker/  # rujukan visual dari pemilik — lihat ADR-015
└── 99-archive/                 # rekaman Saldough 1.0, dibekukan
    ├── README.md
    ├── ROADMAP-1.0.md
    ├── TASK_LIST-1.0.md
    ├── UI_UX_DESIGN_TASKS-1.0.md
    └── UX_REVIEW_FIXES-1.0.md
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
| [0006](02-architecture/adr/0006-design-token-semantic-color-mapping.md) | Token desain dan pemetaan warna semantik | Superseded by ADR-013 |
| [0007](02-architecture/adr/0007-slang-localization.md) | Terjemahan antarmuka dengan slang | Accepted |
| [0008](02-architecture/adr/0008-monthly-cycle-template-and-rollup.md) | Siklus bulanan: template, rollover, dan roll-up | Superseded by ADR-011 |
| [0009](02-architecture/adr/0009-core-shared-features-zone-layout.md) | Struktur folder: zona core / shared / features | Accepted |
| [0010](02-architecture/adr/0010-mocktail-bloc-test-convention.md) | Konvensi pengujian: `mocktail` dan `bloc_test` | Accepted (revisi) |
| [0011](02-architecture/adr/0011-model-domain-dompet-transaksi-anggaran.md) | Model domain inti: dompet, transaksi, dan anggaran | Accepted |
| [0012](02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md) | Tata letak penyimpanan buku besar transaksi | Accepted |
| [0013](02-architecture/adr/0013-bahasa-visual-dan-sistem-ikon.md) | Bahasa visual v2 dan sistem ikon | Superseded by ADR-015 |
| [0014](02-architecture/adr/0014-strategi-pivot-saldough-2.md) | Strategi pivot ke Saldough 2.0 | Accepted |
| [0015](02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md) | Adopsi bahasa visual dari paket desain pemilik | Accepted |
| [0016](02-architecture/adr/0016-revisi-palet-satu-peran-satu-warna.md) | Revisi palet ADR-015: satu peran, satu warna | Accepted |
| [0017](02-architecture/adr/0017-rencana-anggaran-adalah-jumlah-pos.md) | Rencana anggaran adalah jumlah posnya | Accepted |
| [0018](02-architecture/adr/0018-jenis-pos-anggaran.md) | Pos anggaran punya jenis: pengeluaran atau transfer | Accepted |
| [0019](02-architecture/adr/0019-tarif-di-entri-dan-transaksi-milik-pembayaran.md) | Tarif di entri worklog, transaksi milik pembayaran freelance | Accepted |
| [0020](02-architecture/adr/0020-hierarki-penekanan-bahasa-visual-pixel.md) | Hierarki penekanan di dalam bahasa visual pixel | Accepted |
| [0021](02-architecture/adr/0021-onboarding-dan-tur-spotlight.md) | Onboarding dan tur spotlight | Accepted |
| [0022](02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md) | Ganti nama aplikasi menjadi Tanukonomy | Accepted (sebagian dilaksanakan) |
| [0023](02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md) | Identitas opsional: Firebase Auth, Analytics, Crashlytics | Accepted |
| [0024](02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md) | Kepemilikan data lokal dan akun | Accepted |
| [0025](02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md) | Satu mata uang per aplikasi | Accepted |
| [0026](02-architecture/adr/0026-sistem-kategori.md) | Sistem kategori: daftar bawaan yang bisa diubah | Accepted |
| [0027](02-architecture/adr/0027-catat-cerdas-interpreter-yang-bisa-diganti.md) | Catat Cerdas: bukti teks, interpreter yang bisa diganti, draf CATAT | Accepted |
| [0028](02-architecture/adr/0028-bahasa-aplikasi-dipilih-pengguna.md) | Bahasa aplikasi dipilih pengguna (tampilan + ucapan) | Accepted |
| [0029](02-architecture/adr/0029-catat-cerdas-paket-bahasa-tanggal-dan-jalur-cloud.md) | Catat Cerdas per bahasa: paket bahasa, tanggal pasti, jalur langsung ke cloud | Accepted |
| [0030](02-architecture/adr/0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md) | Batas antarfitur: akar komposisi, rute bertipe, sinyal buku besar, presentasi di shared | Accepted |

ADR berikutnya memakai nomor **0030**.

## Pertanyaan yang sering muncul

| Pertanyaan | Jawabannya ada di |
|---|---|
| Mengapa aplikasi ini dibuat? | [Analisis proses manual](00-foundation/MANUAL_PROCESS_ANALYSIS.md) |
| Apa arti istilah "worklog" atau "CATAT"? | [Glosarium](00-foundation/PROJECT_GLOSSARY.md) |
| Mengapa nominal disimpan dalam satuan sen? | [Model domain](02-architecture/DOMAIN_MODEL.md), bagian aturan representasi uang |
| Mengapa kesalahan dikembalikan sebagai `Either<Failure, T>`? | [ADR-0005](02-architecture/adr/0005-either-failure-convention.md) |
| Mengapa struktur foldernya tiga zona, bukan feature-first sederhana? | [ADR-0009](02-architecture/adr/0009-core-shared-features-zone-layout.md) |
| Mengapa `flutter-architecture-studi` (tanpa `-bank`) tidak dipakai? | [Gambaran arsitektur](02-architecture/ARCHITECTURE_OVERVIEW.md), bagian dasar keputusan |
| Mengapa pengujian memakai `mocktail`/`bloc_test` padahal repo acuan tidak? | [ADR-0010](02-architecture/adr/0010-mocktail-bloc-test-convention.md) |
| Mengapa membuat anggaran tidak mengubah saldo dompet? | [Model domain](02-architecture/DOMAIN_MODEL.md) dan [ADR-011](02-architecture/adr/0011-model-domain-dompet-transaksi-anggaran.md) |
| Ke mana fitur lama (`cycle`, `card`, `investment`, `grocery`, `income`) pergi? (dihapus di cutover Fase 3) | [ADR-014](02-architecture/adr/0014-strategi-pivot-saldough-2.md) |
| Bagaimana cara memulihkan kode Saldough 1.0? | [Indeks arsip](99-archive/README.md) |
| Di mana desain visual layarnya? | [Tugas desain UI/UX](04-planning/UI_UX_DESIGN_TASKS.md), rujukannya di `docs/stitch_pixel_finance_tracker/` |
| Kenapa ada bayangan keras beroffset di tiap kartu? | [ADR-015](02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md) |
| Bagaimana menambah tugas baru? | [Daftar tugas](04-planning/TASK_LIST.md), bagian "Menambah tugas baru" |
| Apa yang menunggu di antrean? | [Daftar tugas](04-planning/TASK_LIST.md), bagian "Antrean" |
| Apa yang harus diisi sebelum submit ke Play Store? | [PLAY_DATA_SAFETY.md](04-planning/PLAY_DATA_SAFETY.md) dan [PLAY_STORE_LISTING.md](04-planning/PLAY_STORE_LISTING.md) |
| Apa yang dikerjakan berikutnya? | [Daftar tugas](04-planning/TASK_LIST.md) dan [perbaikan hasil review UX](04-planning/UX_REVIEW_FIXES.md) |

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
- **Requirement.** Diberi identitas seperti `FR-WAL-001` dan dirujuk dari ADR
  maupun daftar tugas.
- **Angka.** Setiap rumus disertai angka bukti dari catatan keuangan nyata
  pemilik. Jangan menulis rumus tanpa buktinya.
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
- Dokumen yang isinya rekaman riwayat produk yang sudah dihentikan dipindahkan
  ke [`docs/99-archive/`](99-archive/README.md) dan dibekukan di sana, bukan
  dihapus maupun disunting mengikuti keputusan baru.
