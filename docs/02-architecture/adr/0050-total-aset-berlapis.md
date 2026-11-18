# Total aset berlapis: dana operasional, tabungan, investasi

## 1. Metadata

- **Decision ID:** ADR-050
- **Tanggal:** 2026-11-17
- **Fase roadmap:** Fase 30 (hero berlapis, sebagian B-98); Fase 31 menambah
  lapis Investasi; Fase 32 (perubahan antarperiode, riwayat kekayaan B-100)
- **Status:** Accepted (disetujui pemilik 17 Nov 2026)
- **Cakupan:** `shared/wealth` (baru: hitungan lapisan), `features/wallet`
  (hero dan urutan bagian tab Dompet), `features/home` (kartu saldo Beranda)
- **Bergantung pada:** ADR-012, ADR-043 (design system v2), ADR-047, ADR-048
  Revisi 1
- **Rancangan produk:** [WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md)
  §3, §7, keputusan 8; dokumen sumber pemilik "Financial Layers"

## 2. Konteks

Angka utama di hero tab Dompet dan Beranda saat ini adalah **Total saldo**:
jumlah saldo dompet aktif. Dengan tujuan tabungan yang memiliki dompet sendiri
(ADR-048 Revisi 1) dan investasi yang segera menyusul, pemilik meminta
(17 Nov 2026) hero disesuaikan menyeluruh ke tiga **lapisan keuangan**: **Dana
operasional**, **Tabungan**, **Investasi**, sambil tetap menjaga rincian per
dompet, per tujuan, dan per instrumen. Nama angka utama menjadi **Total aset**
(WEALTH_ASSETS keputusan 8; "Kekayaan bersih" baru sesudah utang, B-59).

## 3. Keputusan

### 3.1 Hitungan (satu tempat, tanpa hitung ganda)

`shared/wealth/` menyediakan `WealthLayers.of(wallets, goals, [holdings])`:

| Lapis | Isi |
|---|---|
| **Dompet** (sebelumnya "Dana operasional") | Σ `currentBalance` dompet **aktif** yang **bukan** milik tujuan. Boleh negatif (mis. kartu). |
| **Tabungan** | Σ `currentBalance` dompet milik tujuan (status tujuan apa pun), selama dompetnya aktif. |
| **Investasi** | Σ nilai pasar instrumen aktif (Fase 31; 0 sampai ada). |
| **Total aset** | Jumlah ketiganya. |

Setiap dompet masuk tepat satu lapis. Dompet nonaktif yang bukan milik tujuan
tidak dihitung, sama seperti Total saldo sekarang. `WealthLayers` juga memberi
daftar per butir (dompet, tujuan, instrumen) untuk rincian. Semua `int` sen.

### 3.2 Hero tab Dompet

- Label **TOTAL ASET**, angka = Total aset (hitung naik dan Sembunyikan
  nominal seperti sekarang).
- `stats`: satu `DsHeroStatTile` per lapis yang punya isi: Dana operasional
  dan Tabungan di Fase 30; Investasi muncul sesudah instrumen pertama
  (Fase 31). Lapis Tabungan tampil sejak tujuan pertama dibuat, walau Rp0.
- `footer`: satu batang proporsi tipis per lapis (bagian positif saja; lapis
  negatif tidak menggambar batang tetapi angkanya tetap tampil).
- Keterangan bawah: "n dompet · n tujuan".

### 3.3 Urutan dan rincian tab Dompet

Bagian di bawah hero mengikuti lapisan, dan rincian per butir tetap ada:

1. **Dana operasional**: kartu Sebaran saldo (kini hanya dompet operasional)
   dan grid dompet seperti sekarang, tanpa dompet milik tujuan.
2. **Tabungan**: bagian tujuan (kartu per tujuan dengan kemajuan).
3. **Investasi**: daftar instrumen (Fase 31).
4. Baris dompet nonaktif dan Tambah dompet tetap di bawah.

### 3.4 Beranda

Kartu saldo Beranda memakai label **Total aset** dan angka yang sama, dengan
deretan lapis ringkas (ubin lapis yang punya isi). Arus periode dan footer
perkiraan tetap. Judul ringkas saat digulir memakai Total aset.

### 3.5 Yang tidak berubah

- Perkiraan dan Rencana tetap membaca saldo dompet aktif (dompet milik tujuan
  ikut, karena ia dompet sungguhan).
- Kata "saldo" tetap hanya untuk isi dompet; Total aset bukan saldo.
- Perubahan Total aset antarperiode (dari transaksi/valuasi/penyesuaian) dan
  riwayatnya tetap Fase 32 (B-98 sisa, B-100).

## 4. Opsi yang dipertimbangkan

- **Opsi A — Tetap Total saldo, lapisan di halaman terpisah.** Ditolak pemilik.
- **Opsi B — Hero berlapis memakai `stats` dan `footer` `DsHeroBalanceCard`
  yang sudah ada (Dipilih).** Tanpa komponen baru; lapis bertambah sendiri
  saat datanya ada.

## 5. Konsekuensi

- **Positif:** satu angka utama yang jujur terhadap semua uang dan aset;
  rincian per butir tetap; tidak ada hitung ganda karena setiap dompet masuk
  satu lapis.
- **Negatif:** label hero berubah di dua layar; uji widget yang mencari
  "Total saldo" disesuaikan; tur spotlight `homeBalance`/`walletSummary` perlu
  teks baru.
- **Dokumen yang ikut:** WEALTH_ASSETS (§7, istilah "dompet harian" menjadi
  "dana operasional"), PROJECT_GLOSSARY, `writing.md`.

## 6. Revisi

- 2026-11-17: dibuat (Proposed), lalu disetujui pemilik (Accepted).
- 2026-11-17: Revisi 1 (keputusan pemilik): lapis "Dana operasional" bernama
  **Dompet** / **Wallets** (bukan terjemahan harfiah); tab Dompet dirombak
  menjadi hero Total aset → kartu **Sebaran aset** (tingkat pertama: batang
  dan persen per lapis; mengetuk lapis memilih segmen) → pemilih segmen
  **Dompet | Tabungan** (Investasi menyusul) → isi segmen: tingkat kedua
  Sebaran dompet atau Sebaran tabungan (bar dan donut per butir, persen di
  dalam lapis) lalu grid dompet atau daftar tujuan. Menggantikan urutan
  bertumpuk di §3.3.
- 2026-11-17: Revisi 2 (umpan balik pemilik): hero tanpa ubin lapis;
  sebaran antarlapis (batang dan legenda persen yang bisa diketuk) pindah ke
  kaki hero, sehingga kartu Sebaran aset terpisah dihapus. App bar tab Dompet
  (`WalletTopBar`) mewarisi hero saat hero tergulir: latar bergradasi ke warna
  hero, sudut bawah membulat dan berbayang, judul memudar naik lalu label
  TOTAL ASET dan nominal masuk, ikon dan bilah status terang; hero sedikit
  mengecil dan memudar saat pergi. Urutan di bawah hero: segmen Dompet |
  Tabungan (menempel) → sebaran butir segmen → daftar.

