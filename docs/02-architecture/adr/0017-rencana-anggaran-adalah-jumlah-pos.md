# Rencana anggaran adalah jumlah posnya

## 1. Metadata

- **Decision ID:** ADR-017
- **Tanggal:** 2026-09-25
- **Fase roadmap:** Fase 4
- **Status:** Accepted
- **Cakupan:** Fitur `budget` dan formulir anggaran.
- **Merevisi:** rumus `budget.plannedAmount` di
  [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) bagian "Anggaran", dan kriteria
  "Menampilkan selisih antara jumlah nominal seluruh pos dan nominal rencana
  anggaran" di FR-BUD-002 [PRD 2.0](../../01-product/prd-saldough-2.0.md).

## 2. Konteks

Model semula punya dua angka rencana: `budget.plannedAmount` yang diketik
pemilik, dan `plannedAmount` tiap pos. Formulir yang dibangun di T-4.6
menampilkan keduanya terpisah, ditambah baris "Selisih dengan rencana".
Setelah mencobanya, pemilik menilai ini membingungkan: menambah pos tidak
mengubah nominal rencana anggaran.

Dokumen sendiri tidak konsisten soal ini. Rumusnya menyebut rencana anggaran
"diketik pemilik", tetapi bukti di bagian yang sama menyebut rencana
Rp3.068.500 sebagai "jumlah `plannedAmount` seluruh pos di dalam satu
anggaran". Rujukan visual `pixel_kas_tambah_anggaran` juga menampilkan
"Total Rencana Anggaran" yang sama dengan jumlah posnya.

Ada juga masalah yang lebih dalam. Transaksi hanya bisa ditautkan ke pos,
bukan ke anggaran, jadi `budget.spent = Σ item.spent`. Akibatnya:

- Anggaran tanpa pos tidak pernah bisa mencatat pengeluaran. Nominal
  rencananya hanya angka yang tidak terlacak.
- Selisih antara rencana anggaran dan jumlah pos tidak bisa dipakai, karena
  tidak ada pos untuk menautkan transaksinya.

## 3. Keputusan

**`budget.plannedAmount = Σ item.plannedAmount`.** Nilai ini turunan dan
tidak disimpan. Formulir tidak lagi punya kolom nominal rencana; yang tampil
adalah "Total rencana anggaran" yang ikut berubah setiap kali pos ditambah,
disunting, atau dihapus.

**Anggaran wajib punya minimal satu pos.** Formulir tidak bisa disimpan
tanpa pos, dan menjelaskan alasannya. Entitas tetap menerima daftar pos
kosong (rencana nol) supaya data lama tidak rusak.

**Ruang cadangan dibuat sebagai pos biasa**, misalnya "Lain-lain" atau
"Cadangan", sehingga pengeluaran dari cadangan pun tetap bisa ditautkan dan
dilacak.

## 4. Konsekuensi

- `Budget` kehilangan field `plannedAmount` dan mendapat getter dengan nama
  yang sama. `CalculateBudgetProgress`, ringkasan, kartu, dan rincian tidak
  berubah, karena semuanya sudah membaca `budget.plannedAmount`.
- `BudgetModel` naik ke skema 2: kunci `plannedAmount` tingkat anggaran tidak
  lagi ditulis, dan diabaikan saat dokumen skema 1 dibaca. Tidak perlu
  migrasi.
- Baris "Selisih dengan rencana" dan pintasan "Pakai jumlah pos" dihapus
  dari formulir, begitu pula kunci i18n-nya.
- Kriteria selisih di FR-BUD-002 dicoret dan diganti kriteria "rencana
  anggaran adalah jumlah pos".

## 5. Alternatif yang ditolak

**Rencana tetap angka sendiri, tetapi otomatis mengikuti jumlah pos sampai
pemilik mengubahnya.** Formulir jadi lebih ramah, tetapi dua angka tetap
ada, dan selisihnya tetap tidak bisa dilacak karena tidak ada pos untuk
menautkan transaksinya.
