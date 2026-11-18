# Investasi manual: instrumen, beli/jual lewat CATAT, valuasi per satuan

## 1. Metadata

- **Decision ID:** ADR-049
- **Tanggal:** 2026-11-18
- **Fase roadmap:** Fase 31 (B-97, lihat TASK_LIST)
- **Status:** Accepted (18 Nov 2026; kelima pertanyaan §6 mengikuti usul engineer)
- **Cakupan:** `shared/investment` (baru: entitas, posisi, valuasi, repositori,
  use case, tampilan bersama), `features/investment` (baru: segmen dan layar
  Investasi, Perbarui massal), `shared/transaction` (anggota kelima
  `Transaction`), `features/record` (jenis CATAT Investasi), `shared/wealth`
  (lapis Investasi), `shared/category` (kategori bawaan Investasi),
  `features/premium` (P12), `features/data_portability` (cadangan, ekspor),
  `core/foundation/entitlement` (batas)
- **Bergantung pada:** ADR-012, ADR-025, ADR-026, ADR-030, ADR-040, ADR-041,
  ADR-047, ADR-048, ADR-050
- **Rancangan produk:** [WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md)
  §5, §10, §12, KT-A1, KT-A2; [FREEMIUM_PAYWALL.md](../../01-product/features/FREEMIUM_PAYWALL.md) P12

## 2. Konteks

Pemilik memutuskan (17 Nov 2026) bahwa investasi adalah **instrumen**, bukan
dompet: nilainya berubah, tidak disebut saldo, dan tidak masuk Arus. Ada dua
pintu: **kepemilikan yang sudah ada** (tanpa dompet) dan **beli/jual dari
dompet** lewat CATAT. Biaya dan pajak masuk nilai perolehan (beli) dan hasil
bersih (jual). Untung terwujud bukan pemasukan; dividen dan kupon adalah
pemasukan biasa. Biaya yang dijual memakai **rata-rata tertimbang** (KT-A1).
Satuan: saham lot (1 lot = 100 lembar), reksa dana unit, emas gram, obligasi
nominal, lainnya unit (KT-A2). Nilai pasar diisi pengguna (tanpa harga
otomatis; B-101 menyusul lewat Google Sheet pengguna), ditandai bila
≥ 30 hari. Gratis 2 instrumen aktif, ke-3 memicu P12.

ADR-050 sudah menyiapkan lapis **Investasi** di Total aset
(`WealthLayers.investment`, 0 sampai ada instrumen). ADR-047 sudah membuktikan
pola anggota baru `Transaction` yang dikecualikan dari Arus lewat switch
eksaustif.

## 3. Keputusan

### 3.1 Entitas `Instrument`

`shared/investment/domain/instrument.dart`:

| Field | Tipe | Arti |
|---|---|---|
| `id` | `String` | |
| `name` | `String` | Mis. "BBCA", "Reksa dana pasar uang X", "Emas Antam" |
| `type` | `InstrumentType` | `stock`, `mutualFund`, `bond`, `gold`, `other` |
| `code` | `String?` | Kode bursa opsional (mis. `BBCA`), dipakai B-101 |
| `opening` | `OpeningHolding?` | Kepemilikan yang sudah ada: `date`, `quantity`, `cost` (sen). Tidak menyentuh dompet |
| `createdAt` | `DateTime` | |

Satuan **diturunkan dari jenis**, tidak disimpan:

| Jenis | Satuan jumlah | Satuan harga (§3.4) |
|---|---|---|
| Saham | lot | per lembar (1 lot = 100 lembar) |
| Reksa dana | unit | per unit (NAB/UP) |
| Emas | gram | per gram |
| Obligasi | nominal (uang) | persen dari nominal (mis. 100,50%) |
| Lainnya | unit | per unit |

Jenis tidak bisa diubah sesudah instrumen punya aktivitas (beli, jual, atau
valuasi), karena arti jumlah dan harga ikut berubah.

### 3.2 Jumlah berskala tetap

Jumlah disimpan sebagai `int` **×10.000** (`quantityScale = 10000`) untuk
semua jenis: 1 lot = 10000, 0,5 gram = 5000, 12,3456 unit reksa dana = 123456.
Saham boleh pecahan lot (odd lot, 1 lembar = 0,01 lot = 100). Obligasi:
jumlah adalah nominal dalam sen ×1 (skala tidak dipakai; Rp1.000.000 nominal =
`100000000`). Uang tetap `int` sen (aturan 1). Tidak ada `double` di domain;
input desimal diurai ke `int` lewat pengurai yang sama dengan `money_input`
(pemisah desimal mengikuti locale).

### 3.3 Beli dan jual: anggota kelima `Transaction`

`InvestmentTransaction` di `shared/transaction/domain/transaction.dart`:
`walletId`, `instrumentId`, `side` (`buy`/`sell`), `quantity` (§3.2),
`amount` positif (beli: total dibayar termasuk biaya dan pajak; jual: hasil
bersih sesudah biaya dan pajak), tanpa kategori, pos anggaran, atau rutin.

- **Saldo dompet:** beli −`amount`, jual +`amount`
  (`CalculateWalletBalance`, `walletIdsOf`).
- **Arus:** 0 di semua pembaca, sama persis dengan penyesuaian (ADR-047
  §3.4): pemasukan, pengeluaran, Analisis, anggaran, Rencana, perkiraan,
  Buku Periode. Switch tetap tanpa `default`/`_`.
- **Disimpan di partisi transaksi** (ADR-012) supaya ikut Riwayat, saldo,
  cadangan, dan ekspor tanpa jalur baru. DTO jenis `'investment'`,
  `TransactionModel.schemaVersion` 3 → 4, `transactionSchema` di registri
  cadangan ikut naik (build lama menolak cadangan baru, bukan crash).
- **Aturan 8:** dicatat lewat **CATAT** (jenis Investasi), jadi **bukan**
  pengecualian. Tambah kepemilikan yang sudah ada tidak membuat `Transaction`
  sama sekali, jadi juga bukan pengecualian. (B-97 di TASK_LIST yang menyebut
  "pengecualian aturan 8" diluruskan.)
- **Sunting dan hapus:** lewat detail transaksi dan CATAT seperti transfer,
  tunduk validasi §3.6.
- **Jatuh tempo** obligasi dicatat sebagai jual.

### 3.4 Valuasi: harga per satuan harga, bertanggal

`InstrumentValuation`: `instrumentId`, `date`, `unitPrice` (`int`), `source`
(`manual`; `sheet` untuk B-101). Arti `unitPrice` mengikuti satuan harga §3.1:
sen per lembar/unit/gram, atau **basis poin ×100** untuk obligasi
(100,50% = `1005000`).

Nilai pasar pada tanggal *d* = jumlah pada *d* × harga valuasi terakhir ≤ *d*,
dibulatkan setengah ke atas ke sen sekali di akhir:

- saham: `qty × 100 × unitPrice ÷ 10000`
- reksa dana, emas, lainnya: `qty × unitPrice ÷ 10000`
- obligasi: `nominal × unitPrice ÷ 1000000`

Dipilih **harga per satuan**, bukan nilai total, supaya nilai tetap benar
sesudah beli/jual berikutnya, supaya Perbarui massal dan B-101 (yang membawa
harga) cukup mengisi satu angka, dan supaya riwayat kekayaan Fase 32 bisa
menghitung nilai di tanggal lampau. Formulir boleh menawarkan "isi nilai total"
yang diubah menjadi harga per satuan (dibulatkan ke sen), tetapi yang disimpan
selalu harga.

Belum pernah divaluasi → nilai pasar = nilai perolehan, ditandai "Belum pernah
diperbarui". Penanda kesegaran: `staleAfterDays = 30` dari tanggal valuasi
terakhir. Satu valuasi per instrumen per tanggal (yang baru menggantikan yang
lama di tanggal yang sama). Valuasi bisa dihapus dari histori.

### 3.5 Posisi diturunkan dengan memutar ulang

`InstrumentPosition.replay(instrument, transactions)` menghasilkan jumlah,
nilai perolehan, dan untung/rugi terwujud. Aktivitas = kepemilikan awal +
`InvestmentTransaction` instrumen itu, urut tanggal lalu urutan pencatatan
(`id`). Rata-rata tertimbang (KT-A1), semuanya `int`:

- beli: `qty += q`, `cost += amount`
- jual: `bagianPerolehan = round(cost × q ÷ qty)` (jual habis → `cost` utuh,
  tanpa sisa pembulatan); `realized += amount − bagianPerolehan`;
  `cost −= bagianPerolehan`; `qty −= q`

Untung/rugi belum terwujud = nilai pasar − `cost`; persen = ÷ `cost` (tidak
ditampilkan bila `cost` = 0). Posisi tidak disimpan sebagai cache di fase ini:
jumlah instrumen kecil dan transaksinya sudah dimuat per bulan. Cache baru
dibuat bila pengukuran menunjukkan lambat.

Status: **Aktif** bila jumlah > 0, atau bila instrumen baru dibuat tanpa
kepemilikan awal dan belum punya transaksi; **Selesai** bila jumlah = 0
sesudah ada aktivitas. Selesai tidak dihitung batas Gratis
dan tidak masuk lapis Investasi, tetapi tetap tampil di bagian "Selesai"
dengan untung/rugi terwujudnya. Membeli lagi membuatnya Aktif (tunduk batas).

### 3.6 Validasi di use case, bukan widget

- Jual lebih dari jumlah yang dimiliki **pada tanggal jual** ditolak
  (`InvestmentFailure.insufficientQuantity`). Tidak ada posisi negatif.
- Menyunting atau menghapus beli (atau kepemilikan awal, atau memundurkan
  tanggal jual) yang membuat posisi negatif di titik mana pun sesudahnya
  ditolak dengan galat yang sama. Pemeriksaan = putar ulang dengan perubahan
  itu.
- Dompet nonaktif dan dompet milik tujuan tidak bisa dipilih (dompet tujuan
  hanya untuk transfer, ADR-048 §8).
- Jumlah dan nominal > 0.

### 3.7 Membuat instrumen

Dua pintu (WEALTH_ASSETS §5.2):

1. **Investasi › Tambah investasi** (formulir instrumen): nama, jenis, kode
   opsional, lalu opsional "Sudah punya": tanggal, jumlah, nilai perolehan.
   Tidak menyentuh dompet.
2. **CATAT › Investasi › Catat pembelian**: pilih instrumen yang ada atau
   "Instrumen baru" (nama dan jenis di dalam formulir). Instrumen dan
   transaksinya disimpan bersama oleh satu use case `RecordInvestment`;
   bila transaksi gagal disimpan, instrumen baru tidak ditinggalkan.

**Catat penjualan** hanya menawarkan instrumen Aktif.

**Hapus instrumen** ditolak selama masih ada `InvestmentTransaction` yang
menunjuknya; pengguna menghapus catatannya dulu di Riwayat (saldo dompet
kembali lewat jalur biasa). Instrumen tanpa transaksi dihapus beserta
valuasinya. Alasan: menghapus transaksi beli/jual diam-diam mengubah saldo
dompet, beda dengan dompet tujuan yang memang milik tujuan (ADR-048 §8).

### 3.8 Dividen dan kupon

Pemasukan biasa (keputusan 5). Kategori bawaan baru **Investasi**
(`key: 'investment'`, ikon `categoryInvestment`, alias dividen/kupon/bunga
obligasi) ditambahkan ke kategori bawaan ADR-026, termasuk untuk pengguna
lama lewat mekanisme yang sama dengan kategori bawaan lain. Menautkan pemasukan
ke instrumen (`IncomeTransaction.instrumentId`) **tidak** dikerjakan di fase
ini; dicatat sebagai butir lanjutan bila pemilik ingin "Dividen diterima" di
layar instrumen.

### 3.9 Penyimpanan, cadangan, ekspor

- Kunci `investment_instruments` (`{schemaVersion: 1, items}`) dan
  `investment_valuations` (`{schemaVersion: 1, items}`), `RepositoryGuard`,
  pola `recurring_rule_repository_impl.dart`.
- `BackupRegistry`: kedua kunci `include` skema 1; referensi
  `transaction_*.instrumentId` dan `investment_valuations.instrumentId` →
  `investment_instruments`; `transaction_*.walletId` untuk jenis investasi
  ikut referensi dompet yang ada. Draf P12 `investment_draft` di-`exclude`
  (alasan: draf sementara).
- Ekspor: `ExportKind.investBuy`/`investSell` di lembar Transaksi (Arus 0),
  lembar baru **Investasi** (instrumen, jenis, jumlah, nilai perolehan, nilai
  pasar, tanggal valuasi, untung/rugi) dan **Valuasi** (histori).

### 3.10 Lapis Investasi dan tab Dompet

`WealthLayers.of(..., investment:)` diisi Σ nilai pasar instrumen Aktif hari
ini. Ubin Investasi di hero dan Beranda muncul sesudah instrumen pertama
(ADR-050 §3.2). Segmen tab Dompet menjadi **Dompet | Tabungan | Investasi**:
daftar instrumen Aktif (nama, jumlah dan satuan, nilai pasar, untung/rugi
belum terwujud, penanda kesegaran), bagian Selesai, tombol Tambah investasi
dan **Perbarui nilai** (Perbarui massal). Satu baris catatan di bawah hero bila
ada instrumen kedaluwarsa. Rupa oleh designer (T-31.1); `context.ds`.

### 3.11 Perbarui massal

Satu layar berisi semua instrumen Aktif: harga terakhir dan tanggalnya, kolom
harga baru, satu tanggal valuasi untuk semua (bawaan hari ini). Simpan membuat
satu valuasi untuk setiap baris yang diisi; baris kosong tidak berubah. Layar
yang sama dipakai B-101 sebagai pratinjau (kolom terisi dari Sheet).

### 3.12 Batas Gratis (P12)

`EntitlementLimits.freeInstruments = 2` (Remote Config `free_instruments`),
`PlusFeature.instruments`, `PaywallTrigger.instrumentLimit`. Dihitung = jumlah
instrumen Aktif (§3.5). Diperiksa saat **membuat** instrumen (kedua pintu §3.7)
dan saat **membeli lagi** instrumen Selesai. Ditolak → isian disimpan sebagai
draf (`investment_draft`) lalu paywall P12, pola ADR-048 §3.5. Plus berakhir:
tidak ada yang diarsipkan; yang ada tetap bisa dicatat beli/jual dan
divaluasi (keputusan 4c).

### 3.13 Analitik

`instrument_added` (`type`, `via`: `existing`/`buy`), `investment_recorded`
(`side`), `valuation_updated` (`count_bucket`, `via`: `single`/`bulk`),
`paywall_shown` P12. Tanpa nama, kode, jumlah, atau nominal (ADR-023).

## 4. Opsi yang dipertimbangkan

| Opsi | Alasan ditolak / dipilih |
|---|---|
| Investasi sebagai dompet berjenis | Ditolak oleh keputusan pemilik (dompet tanpa jenis, nilai bukan saldo). |
| Beli/jual sebagai transfer ke "dompet investasi" | Membuat nilai investasi = saldo; untung/rugi tidak punya tempat. |
| Aktivitas beli/jual di kunci investasi sendiri, bukan `Transaction` | Saldo dompet harus membaca dua sumber; Riwayat, cadangan, dan ekspor butuh jalur baru. Ditolak. |
| **`InvestmentTransaction` di partisi transaksi** | Dipilih: satu sumber saldo, pola ADR-047 sudah terbukti. |
| Valuasi = nilai total | Salah sesudah beli/jual berikutnya, tidak bisa menghitung masa lalu. Ditolak. |
| **Valuasi = harga per satuan** | Dipilih (§3.4). |
| Posisi disimpan (cache) | Belum perlu; risiko basi saat transaksi disunting. Ditunda. |
| FIFO | Ditolak oleh KT-A1. |

## 5. Konsekuensi

- **Positif:** saldo dompet, Riwayat, cadangan, dan ekspor memakai jalur yang
  ada; untung/rugi terhitung tepat dalam `int`; Fase 32 dan B-101 bisa
  membangun di atas valuasi per satuan.
- **Negatif:** sapuan kedua semua switch `Transaction` (sesudah ADR-047);
  skema transaksi naik ke 4; CATAT mendapat jenis keempat yang perlu rupa;
  obligasi memakai satuan harga yang berbeda (persen).
- **Dokumen yang ikut diperbarui:** DOMAIN_MODEL (Instrumen, anggota kelima),
  PROJECT_GLOSSARY dan `writing.md` (istilah §3 WEALTH_ASSETS), EXPORT_BACKUP,
  `AGENT_CONTEXT.md` (Arus mengecualikan investasi), TASK_LIST B-97.

## 6. Pertanyaan yang sudah dijawab (18 Nov 2026: semua mengikuti usul)

1. **Hapus instrumen yang punya catatan** ditolak (§3.7), bukan ikut menghapus
   catatan seperti tujuan. Setuju?
2. **Obligasi** memakai jumlah nominal dan harga dalam persen (§3.4). Atau
   disederhanakan: obligasi seperti "Lainnya" (unit, harga per unit)?
3. **Tautan dividen ke instrumen** ditunda (§3.8); fase ini hanya kategori
   bawaan Investasi. Setuju?
4. **Letak di CATAT**: Investasi sebagai jenis keempat di pengalih jenis
   (Pengeluaran, Pemasukan, Transfer, Investasi), atau pintu terpisah di
   lembar pilihan Catat. Usul engineer: jenis keempat; diputuskan bersama rupa
   (T-31.1).
5. **Pemecahan saham (split) dan saham bonus** tidak didukung khusus (beli
   wajib bernominal > 0). Usul: di luar cakupan fase ini, dicatat di antrean.

## 7. Revisi

- 2026-11-18: dibuat (Proposed), lalu disetujui pemilik (Accepted) dengan
  semua usul §6.
