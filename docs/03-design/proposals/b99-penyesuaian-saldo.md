# Rupa B-99: Penyesuaian saldo

**Tanggal:** 17 November 2026. **Status:** dipakai di kode Fase 29 (T-29.5,
T-29.6), dibuat agen engineer atas permintaan pemilik tanpa papan prototipe
terpisah. **Dasar:** [ADR-047](../../02-architecture/adr/0047-penyesuaian-saldo.md),
[WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md) §6 dan §11,
design system v2 (`docs/03-design/design-system-v2/`, widget `context.ds`).
Tidak ada token atau komponen baru; semua bagian memakai komponen yang ada.

## 1. Ubah dompet: kolom saldo

| Bagian | Rupa |
|---|---|
| Label | **Saldo sekarang** (dompet baru tetap **Saldo awal**). |
| Tanda | Tombol bulat kecil **±** (`Symbols.exposure_rounded`) di kiri simbol mata uang (`DsPressable`, target 48dp). Mengetuknya membalik tanda; kolom bernilai negatif menampilkan `−` di depan simbol dengan warna `textPrimary`, tanpa merah (saldo negatif bukan kesalahan, FR-WAL-003). Ada juga di Dompet baru (saldo awal boleh negatif). |
| Nilai awal | Saldo tercatat apa adanya, termasuk negatif. Mata uang tanpa desimal dengan saldo bersen pecahan menampilkan bagian utuhnya, bukan kolom kosong; kolom yang tidak disentuh tidak pernah mengubah saldo. |
| Keterangan, belum diubah | "Isi dengan jumlah uang di dompet ini sekarang. Selisihnya dicatat sebagai penyesuaian saldo hari ini; saldo hari-hari sebelumnya tidak berubah." |
| Pratinjau, sudah diubah | Menggantikan keterangan di kartu saldo yang sama (tanpa kartu baru): baris tebal `bodyMd` **"Selisih +Rp500 dicatat sebagai penyesuaian saldo hari ini."** dan baris `bodySm` sekunder "Tahu transaksi mana yang salah? Sunting transaksinya saja." Selisih 0 kembali ke keterangan biasa. |
| Chip cepat | Tetap (+100rb, +1jt, …, Hapus). Chip menambah besaran; tanda tidak berubah. Hapus mengosongkan dan mengembalikan tanda ke positif. |

## 2. Sesudah simpan

Snackbar satu slot: **"Selisih +Rp500 dicatat sebagai penyesuaian saldo."**
Bila saldo tidak diubah: "Dompet diperbarui." seperti sekarang.

## 3. Riwayat

| Bagian | Rupa |
|---|---|
| Baris | `DsLedgerRow` jenis netral (warna nominal `textSecondary`, judul `textPrimary`), tile `DsIconTile` netral dengan ikon `Symbols.balance_rounded`, judul "Penyesuaian saldo" (atau catatannya bila ada), subjudul "Dompet · 08.00", nominal bertanda **+Rp500** / **−Rp500**. Tanpa lencana kategori. |
| Filter jenis | Chip **"Penyesuaian n"** sesudah Transfer, **hanya tampil bila ada penyesuaian** (atau chip itu sedang terpilih). "Semua" tetap memuatnya; memilih jenis lain otomatis menyembunyikannya. |
| Total kepala periode | Tidak berubah: penyesuaian bukan pemasukan atau pengeluaran. |

Selisih disengaja dari brief: tidak ada chip "Sembunyikan penyesuaian" yang
terpisah. Penyesuaian jarang, chip jenis lain sudah menyembunyikannya, dan
satu chip lagi menambah baris yang harus digeser di 360dp.

## 4. Rincian penyesuaian

| Bagian | Rupa |
|---|---|
| Kartu utama | Tile ikon yang sama ukuran besar, lencana netral "Penyesuaian saldo", nominal bertanda warna `textSecondary`, tanggal dan jam. |
| Kartu rincian | Jenis: Penyesuaian saldo · Dompet: nama dompet. |
| Catatan | "Selisih saat saldo dompet diubah di Ubah dompet. Bukan pemasukan atau pengeluaran. Hapus untuk mengembalikan saldo seperti sebelumnya." |
| Tindakan | Hanya **Hapus** (danger), dengan pola hapus yang sama seperti transaksi lain: langsung, dengan Urungkan di snackbar (UX-8). Tanpa Ubah, Catat lagi, dan Jadikan rutin. |

## 5. Ekspor

Kolom Jenis: "Penyesuaian saldo (tambah)" / "Penyesuaian saldo (kurang)",
Arus 0 (ADR-047 §3.7).

## 6. Pemeriksaan

360dp terang/gelap id/en; teks pratinjau terbungkus tanpa terpotong;
nominal ikut Sembunyikan nominal (baris Riwayat memakai `AppMoneyText.format`);
target sentuh tombol ± 48dp.
