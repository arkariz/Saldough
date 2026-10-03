# Hierarki penekanan di dalam bahasa visual pixel

## 1. Metadata

- **Decision ID:** ADR-020
- **Tanggal:** 2026-09-27
- **Fase roadmap:** Fase 7 (poles), jalur UX di luar MVP
- **Status:** Superseded by [ADR-034](0034-bahasa-visual-buku-catatan-piksel.md) (3 Okt 2026). Sebelumnya Accepted 28 September 2026
- **Cakupan:** Global — `AppButton`, `transactionLabelStyle`, baris
  transaksi, snackbar, `AppSegmentedProgressBar`, navigasi bawah.
- **Merevisi:** [ADR-015](0015-adopsi-bahasa-visual-pixel-kas.md) §3
  (tipografi, komponen) tanpa mengubah palet, garis tepi, atau bayangan
  kerasnya. Melengkapi [ADR-016](0016-revisi-palet-satu-peran-satu-warna.md)
  untuk warna status.

## 2. Konteks

Review UI 27 September 2026 (lihat
[UX_REVIEW_FIXES.md](../../04-planning/UX_REVIEW_FIXES.md), UX-14 s.d.
UX-22) mengukur kode `main` `185455f` dan merender tujuh layar. Bahasa visual
ADR-015 konsisten, tetapi hampir setiap elemen memakai penekanan yang sama
kuatnya, sehingga mata tidak punya titik mulai. Angka yang terukur:

- `AppButton` hanya punya satu gaya (isian penuh, garis tepi 2px, bayangan
  keras) dan dipakai 40 kali. Tidak ada gaya bergaris tepi atau tonal.
- `transactionLabelStyle` (Space Mono 700) dipakai 112 kali; sekitar 78
  memakai ukuran bawaan 10px dan 10 memakai 9px. Ada 71 pemanggilan
  `toUpperCase()`. Label navigasi bawah 10px.
- Satu pengeluaran di daftar membawa empat penanda merah: garis aksen,
  kotak ikon, nominal, dan lencana "−KELUAR".
- Snackbar sukses memakai `colors.income` (hijau), padahal ADR-016
  menetapkan hijau hanya untuk uang masuk.
- Bilah bersegmen dipakai untuk dua arti: progres anggaran, dan proporsi
  masuk/keluar di kop Transaksi (tanpa legenda).
- ADR-015 menetapkan "FAB CATAT" berelevasi interaktif, tetapi navigasi bawah
  menampilkan CATAT setara empat tab lain.

Pedoman yang dipakai sebagai pembanding: hierarki visual dari variasi skala,
kontras, dan pengelompokan (NN/g); satu tombol berpenekanan tinggi per layar
(Material 3); warna makna dipakai hemat supaya tetap jadi sinyal, dan tidak
pernah satu-satunya penanda (WCAG 1.4.1); huruf kapital untuk teks pendek
berukuran cukup (NN/g).

## 3. Keputusan

Saldough mempertahankan seluruh bahasa visual ADR-015 dan menambahkan
**tingkat penekanan** di dalamnya. Yang mengikat implementasi:

1. **Tombol punya tiga tingkat.** `AppButton` menerima varian:
   - `primary` — gaya sekarang (isian, garis tepi 2px, bayangan interaktif).
     Paling banyak **satu** per layar atau lembar.
   - `secondary` — latar kartu, garis tepi 2px, tanpa bayangan (elevasi
     tingkat 0 ADR-015), teks `textPrimary`.
   - `tertiary` — tautan teks beraksen tanpa bingkai (pola `HomeTextLink`).
   Aksi destruktif memakai `secondary` dengan teks `expense`, bukan isian
   merah, kecuali di dialog konfirmasi.
2. **Label mikro minimal 11px.** Bawaan `transactionLabelStyle` naik ke 11px,
   dan tidak ada label di bawah 11px. Huruf kapital hanya untuk lencana dan
   kop kartu sepanjang 1–3 kata; label lebih panjang memakai huruf biasa.
   Label navigasi bawah minimal 11px.
3. **Satu penanda warna per baris transaksi**, ditambah tanda `+`/`−` dan
   warna nominal. Garis aksen **atau** kotak ikon berwarna, bukan keduanya;
   lencana jenis hanya di layar rincian.
4. **Warna status bukan warna uang.** Snackbar sukses memakai latar netral
   (`textPrimary` dengan teks `background`) dan ikon centang; galat tetap
   `expense`. Hijau dan merah tetap khusus uang masuk dan keluar (ADR-016).
5. **Bilah bersegmen hanya berarti progres terhadap rencana.** Ringkasan
   masuk/keluar memakai angka, bukan bilah.
6. **CATAT tampil sebagai FAB** di tengah navigasi bawah sesuai ADR-015 §3
   (elevasi interaktif, isian `accent`), bukan tab setara.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Biarkan seperti sekarang.**
- **Opsi B — Lunakkan seluruh bahasa visual** (hapus bayangan keras dan garis
  tepi di sebagian besar kartu).
- **Opsi C — Tambah tingkat penekanan di dalam ADR-015 (Dipilih).**

## 5. Analisis konsekuensi

### Opsi A — Biarkan seperti sekarang

Tanpa biaya, tetapi masalah hierarki bertambah seiring layar baru (template
anggaran, poles Fase 7) yang meniru komponen yang sama.

### Opsi B — Lunakkan seluruh bahasa visual

Menyelesaikan masalah penekanan, tetapi membongkar keputusan pemilik di
ADR-015 dan rujukan visual `docs/stitch_pixel_finance_tracker/`. Terlalu
mahal untuk masalah yang bisa diselesaikan lebih kecil.

### Opsi C — Tambah tingkat penekanan di dalam ADR-015 (Dipilih)

Garis tepi, bayangan keras, palet, dan tiga keluarga huruf tetap. Yang
berubah hanya **seberapa sering** penekanan tertinggi dipakai. Kelemahannya:
beberapa layar tidak lagi identik piksel demi piksel dengan rujukan visual
(misalnya bilah di kop Transaksi, lencana di baris transaksi).

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Menentukan aksi utama tiap layar; tinjauan UI cukup memeriksa "berapa
  `primary` di layar ini".
- Warna merah dan hijau kembali jadi sinyal yang bisa dipercaya.

### Yang menjadi lebih sulit

- `AppButton` punya parameter varian yang harus dipilih di 40 titik pakai.
- Label 11px memakan ruang lebih; beberapa baris padat perlu ditata ulang.

### Risiko yang diterima

- Selisih kecil dengan rujukan visual pemilik pada elemen yang disebut di
  Opsi C.

## 7. Catatan implementasi

- Kerjakan lewat item UX-13 s.d. UX-22 di
  [UX_REVIEW_FIXES.md](../../04-planning/UX_REVIEW_FIXES.md), satu item per
  commit, dengan uji widget untuk varian tombol dan snackbar.
- Varian ditambahkan sebagai parameter enum di `AppButton`, bawaan `primary`
  supaya pemanggil lama tidak berubah tampilan sebelum disunting.
- Ukuran label dinaikkan di satu tempat (`transactionLabelStyle`), lalu
  periksa pemanggil ber-`size: 9`.
- Verifikasi di emulator dengan build rilis, mode terang dan gelap, lebar
  390dp dan 360dp.

## 8. Kriteria peninjauan ulang

- Pemilik menilai hasil implementasi terlalu jauh dari rujukan visual.
- Layar baru butuh lebih dari satu aksi utama yang setara.

## 9. Artefak terkait

### Dokumentasi

- [ADR-015](0015-adopsi-bahasa-visual-pixel-kas.md),
  [ADR-016](0016-revisi-palet-satu-peran-satu-warna.md)
- [UX_REVIEW_FIXES.md](../../04-planning/UX_REVIEW_FIXES.md)
- [Visual Hierarchy in UX — NN/g](https://www.nngroup.com/articles/visual-hierarchy-ux-definition/)
- [Buttons — Material Design 3](https://m3.material.io/components/buttons/guidelines)
- [Typography for Glanceable Reading — NN/g](https://www.nngroup.com/articles/glanceable-fonts/)

### Rujukan kode

- `lib/core/presentation/widgets/app_button.dart`
- `lib/core/presentation/widgets/kind_surfaces.dart` (`transactionLabelStyle`)
- `lib/core/foundation/effect_handler/src/snackbar_effect_handler.dart:18`
- `lib/core/presentation/widgets/app_segmented_progress_bar.dart`
- `lib/features/transaction/presentation/widgets/transaction_month_header.dart:183`
- `lib/core/presentation/shell/app_shell_page.dart`

---

**Penulis keputusan:** Claude (draf dari review UI)
**Ditinjau oleh:** Pemilik
**Tanggal disetujui:** 2026-09-28
**Status implementasi:** Berjalan — lihat UX-14, UX-15, UX-16, UX-18, UX-20,
UX-21 di [UX_REVIEW_FIXES.md](../../04-planning/UX_REVIEW_FIXES.md)
