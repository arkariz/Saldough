# Pos anggaran punya jenis: pengeluaran atau transfer

## 1. Metadata

- **Decision ID:** ADR-018
- **Tanggal:** 2026-09-25
- **Fase roadmap:** Fase 4
- **Status:** Accepted
- **Cakupan:** Fitur `budget`, pemilih pos di CATAT (`record`), dan layar
  rincian anggaran.
- **Merevisi:** tabel `BudgetItem` dan rumus `item.spent` di
  [DOMAIN_MODEL.md](../DOMAIN_MODEL.md); kriteria FR-BUD-003 dan FR-BUD-007 di
  [PRD 2.0](../../01-product/prd-saldough-2.0.md).

## 2. Konteks

Pos anggaran semula tidak berjenis. Pengeluaran maupun transfer boleh
ditautkan ke pos mana saja, asalkan dompetnya cocok. Setelah layar rincian
anggaran dibangun (T-4.10), pemilik menemukan tiga kerancuan:

1. Setiap pos punya dua tombol, "Catat Pengeluaran" dan "Catat Transfer",
   sehingga tidak jelas pos itu untuk apa.
2. Pos yang dimaksudkan sebagai rencana transfer (misalnya setoran tabungan)
   tetap bisa dirinci jadi jumlah × harga satuan, dan tidak punya dompet
   tujuan.
3. Layar rincian juga punya tombol di tingkat anggaran. Tombol itu hanya
   mengisi dompet, bukan pos. Transaksi yang disimpan tanpa memilih pos tidak
   terhitung ke anggaran sama sekali, walaupun dicatat dari layar anggaran.

Rujukan visual `pixel_kas_tambah_anggaran` sebenarnya sudah membedakan pos
"PENGELUARAN" dan "RENCANA TRANSFER", tetapi domainnya belum mendukung.

## 3. Keputusan

**`BudgetItem` punya `kind`: `expense` atau `transfer`.**

| | Pos pengeluaran | Pos transfer |
|---|---|---|
| Nominal | Diketik langsung, atau jumlah × harga satuan | Diketik langsung saja |
| `targetWalletId` | `null` | Wajib, dan berbeda dari dompet anggaran |
| Terhitung ke `spent` | `ExpenseTransaction` dengan `walletId` = dompet anggaran | `TransferTransaction` dari dompet anggaran ke `targetWalletId` |

Transaksi yang tertaut ke pos yang berbeda jenis, atau ke pos transfer dengan
dompet tujuan lain, tidak terhitung. Aturan ini ditulis di satu tempat
(`countsTowardBudgetItem`) dan dipakai baik untuk hitungan progres maupun
untuk daftar transaksi tertaut.

**Pencatatan dari layar anggaran hanya lewat pos.** Tombol di tingkat
anggaran dihapus. Tiap pos punya satu tombol sesuai jenisnya, yang membuka
CATAT biasa dengan dompet anggaran, pos, dan sisa nominal sudah terisi, plus
dompet tujuan untuk pos transfer.

**Pemilih pos di CATAT menyaring per jenis.** Formulir pengeluaran hanya
menawarkan pos pengeluaran dari dompet asal. Formulir transfer hanya
menawarkan pos transfer yang dompet anggarannya dompet asal dan dompet
tujuannya dompet tujuan transfer.

**Jenis pos dikunci setelah pos punya transaksi tertaut.** Mengganti jenis
akan membuat transaksi lama diam-diam berhenti terhitung.

## 4. Konsekuensi

- Pos yang tersimpan tanpa `kind` dibaca sebagai pengeluaran; tidak perlu
  migrasi.
- Transfer lama yang tertaut ke pos pengeluaran berhenti terhitung. Aplikasi
  belum dirilis, jadi dampaknya hanya pada data uji.
- Kalau dompet anggaran diganti menjadi dompet tujuan salah satu pos
  transfer, formulir anggaran menolak disimpan dan menjelaskan alasannya.
- Port `BudgetItemOption` milik `record` mendapat `transferToWalletId`
  (`null` = pos pengeluaran).

## 5. Alternatif yang ditolak

**Pos tetap tanpa jenis, dengan tombol yang lebih jelas.** Kerancuan dua
tombol per pos dan pos transfer tanpa dompet tujuan tetap ada, dan hitungan
`spent` tetap menerima transaksi jenis apa pun.

**Jenis pos bebas diganti walau sudah ada transaksi tertaut.** Mengganti
jenis membuat transaksi yang sudah tercatat berhenti terhitung tanpa
peringatan yang terlihat di angka.
