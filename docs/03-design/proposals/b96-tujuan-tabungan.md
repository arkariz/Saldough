# Rupa B-96: Tujuan tabungan

**Tanggal:** 17 November 2026. **Status:** dipakai di kode Fase 30 (T-30.5,
T-30.6), dibuat agen atas keputusan pemilik (ADR-048 §6.3), tanpa papan
prototipe. **Dasar:** [ADR-048](../../02-architecture/adr/0048-tujuan-tabungan.md),
[WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md) §4 dan §11,
design system v2 (`context.ds`). Tanpa token atau komponen baru.

## 0. Revisi tata letak (17 Nov 2026, keputusan pemilik)

Tab Dompet: hero **Total aset** (ubin Dompet, Tabungan, Investasi bila ada) →
kartu **Sebaran aset** (`AssetLayerCard`: batang proporsi per lapis dan chip
lapis berisi persen dan nominal; mengetuk chip memilih segmen; tampil bila
lapis yang berisi ≥ 2) → **pemilih segmen** `DsSegmentedPill` Dompet | Tabungan
(dengan jumlah) → isi segmen. Segmen Dompet: Sebaran dompet (bar/donut per
dompet), kepala dompet dan Urutkan, grid, dompet nonaktif, Tambah dompet.
Segmen Tabungan: Sebaran tabungan (bar/donut per tujuan, bila ≥ 2 tujuan
berisi) lalu bagian Tujuan. Lapis uang sehari-hari bernama **Dompet** /
**Wallets**. Bagian §1 di bawah tetap berlaku untuk isi kartu tujuan; letaknya
kini di segmen Tabungan, bukan di dasar halaman.

### 0a. Revisi kedua (17 Nov 2026, umpan balik pemilik)

- Sebaran aset memakai komponen yang sama persis dengan Sebaran dompet dan
  Sebaran tabungan (`WalletSpreadCard`: batang, kunci warna, donut saat
  dibuka), dengan lapis sebagai irisan; memilih lapis memilih segmen.
- Tab Dompet memakai sliver: hero dan Sebaran aset ikut tergulir; pemilih
  segmen `SliverPersistentHeader` menempel di bawah app bar dengan garis bawah
  tipis saat menempel; begitu hero tergulir lewat, judul app bar menjadi
  "Total aset Rp…". Judul "Dompet n" ganda di bawah segmen dihapus (judul
  hanya di mode Atur).
- Formulir tujuan memakai komponen formulir bersama (`AppFormHeader`,
  `AppSectionLabel`, `AppFormTextField`, `AppFormMoneyField`, `DsFieldRow`
  untuk target tanggal, `DsInlineBanner` untuk draf), sama dengan formulir
  proyek freelance dan dompet.

### 0b. Revisi ketiga (17 Nov 2026, umpan balik pemilik)

Menggantikan 0 dan 0a untuk tab Dompet:

| Bagian | Rupa |
|---|---|
| Hero | TOTAL ASET tanpa ubin lapis. Kaki hero: batang proporsi per lapis (warna terang di atas gradasi) dan legenda per lapis "Dompet · 97%" + nominal; legenda segmen terpilih berbingkai; mengetuk legenda memilih segmen. Satu lapis saja: keterangan "n dompet aktif". |
| App bar | `WalletTopBar`. Kemajuan mengikuti gulir dari separuh hero sampai hero lewat. Latar memudar ke gradasi hero, sudut bawah membulat sampai 24 dan berbayang; judul halaman memudar naik di paruh pertama, label TOTAL ASET dan nominal putih masuk dari bawah di paruh kedua (tidak bertumpuk); ikon aksi dan bilah status terang. Gerak dikurangi: tanpa geser. |
| Hero saat pergi | Mengecil 6% dan memudar 60% bersama kemajuan yang sama. |
| Di bawah hero | Segmen Dompet \| Tabungan menempel di bawah app bar → sebaran butir segmen (Sebaran dompet atau Sebaran tabungan) → daftar segmen. |

## 1. Tab Dompet: bagian Tujuan

Di bawah grid dompet (sebelum baris dompet nonaktif):

| Bagian | Rupa |
|---|---|
| Kepala | `DsSectionHeader` "Tujuan" dengan aksi teks **Buat tujuan**. |
| Kosong | `DsCard` satu baris: tile ikon celengan netral, "Kumpulkan uang untuk sesuatu, mis. dana darurat. Hubungkan dompet tabunganmu; kemajuannya mengikuti saldonya.", tombol sekunder **Buat tujuan**. |
| Kartu tujuan | `DsCard` per tujuan Active dan Completed; tujuan Archived tampil redup di bawah subjudul **Diarsipkan** (selisih dari usulan awal baris "n tujuan diarsipkan": jumlahnya kecil, satu layar lebih sederhana): tile ikon clay, nama, "Rp3.200.000 dari Rp10.000.000", `DsSegmentMeter` tipis, persen di kanan. Completed: lencana **Tercapai**. Nominal ikut Sembunyikan nominal. |
| Lencana dompet | Kartu dompet yang tertaut ke tujuan Active/Completed memuat lencana netral **Tujuan: <nama>** di baris persen. |

## 2. Formulir Buat/Ubah tujuan (halaman penuh)

Urutan: kepala dengan ikon terpilih bergoyang · **Nama** (wajib) · **Target**
(kolom uang seperti formulir dompet) · **Ikon** (pemilih ubin 48dp yang sama
dengan kategori dan dompet) · **Hubungkan dompet** · **Target tanggal**
(opsional, pemilih tanggal) · **Keterangan** (opsional) · tombol **Simpan**.

Hubungkan dompet: daftar chip dompet aktif dan nonaktif (`DsFilterChip`,
bisa memilih banyak). Dompet yang sudah terhubung ke tujuan lain tampil
nonaktif dengan subteks "Sudah di <tujuan>". Teks bantu: "Satu dompet hanya
untuk satu tujuan. Belum punya dompet tabungan? Buat dompet baru di tab Dompet
lalu hubungkan di sini."

Gratis dengan 2 tujuan aktif: Simpan menyimpan isian sebagai draf lalu membuka
paywall P11; membuka Buat tujuan lagi mengisi formulir dari draf dengan baris
"Melanjutkan draf" dan aksi **Buang draf**.

## 3. Rincian tujuan

| Bagian | Rupa |
|---|---|
| Kartu utama | Tile besar, nama, terkumpul besar, "dari Rp10.000.000", meter, "Kurang Rp6.800.000" atau lencana **Tercapai**. Target tanggal bila ada. |
| Dompet | `DsListCard` dompet tertaut dengan saldo masing-masing; dompet nonaktif berlencana "Nonaktif". |
| Riwayat | Baris transaksi (`TransactionLedgerRow`) yang menyentuh dompet tertaut, 20 terbaru. Kosong: "Belum ada catatan di dompet ini." |
| Tindakan | **Ubah**, **Arsipkan** (atau **Aktifkan lagi** untuk Archived/Completed), **Hapus tujuan** (konfirmasi: "Saldo dompet tidak berubah."). |

## 4. Umpan balik

- Tersimpan: snackbar "Tujuan tersimpan."
- Baru tercapai (terdeteksi saat buku besar berubah, di tab Dompet): snackbar
  satu kali "<nama> tercapai." Tanpa streak atau perayaan besar.

## 5. Pemeriksaan

360dp terang/gelap id/en; nama panjang membungkus; target sentuh 48dp;
nominal tersembunyi bila Sembunyikan nominal aktif.
