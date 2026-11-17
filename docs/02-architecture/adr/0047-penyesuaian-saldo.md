# Penyesuaian saldo: selisih koreksi saldo dicatat, bukan menggeser saldo awal

## 1. Metadata

- **Decision ID:** ADR-047
- **Tanggal:** 2026-11-17
- **Fase roadmap:** Fase 29 (B-99, lihat TASK_LIST)
- **Status:** Accepted (arah diputuskan pemilik 17 Nov 2026 lewat KT-W1 = B;
  rincian teknis disetujui pemilik 17 Nov 2026)
- **Cakupan:** `shared/transaction` (entitas, model, kueri, use case),
  `shared/wallet` (hitung saldo), `features/wallet` (Ubah dompet),
  `features/transaction` (Riwayat, detail), `features/data_portability`
  (ekspor, cadangan), semua pembaca Arus (`analysis`, `plan`, `budget`,
  `home`), `shared/recurring` (pencocokan), `features/notification_capture`
- **Bergantung pada:** ADR-012 (saldo di-cache), ADR-030 (`LedgerChanges`),
  ADR-038 (periode lampau tidak dipotong ulang), ADR-040 (`BackupRegistry`,
  ekspor)
- **Mengubah:** perilaku Ubah dompet sejak `0.11.0+17` (tanpa ADR);
  larangan "transaksi penyeimbang" di `.claude/AGENT_CONTEXT.md`
- **Rancangan produk:** [WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md) §6; PRD FR-AST-004

## 2. Konteks

Sejak `0.11.0+17`, kolom saldo di Ubah dompet berarti **saldo saat ini**.
`WalletBloc._onEdited` menghitung netto transaksi dompet, lalu menyimpan
`initialBalance = angka diisi − netto` tanpa membuat catatan apa pun. Akibatnya:

1. Selisih antara catatan dan uang nyata hilang tanpa jejak.
2. Saldo **seluruh** periode lampau ikut bergeser, padahal ADR-038 menjanjikan
   periode lampau tidak dipotong ulang. Riwayat kekayaan (B-100), kemajuan
   tujuan tabungan (B-96), dan buku periode yang sudah ditutup (Fase 27) tidak
   bisa dipercaya di atas perilaku ini.
3. Saldo negatif atau berpecahan sen tampil sebagai kolom kosong di formulir.

Pemilik memutuskan KT-W1 = **B** (17 Nov 2026): selisih dicatat sebagai
**Penyesuaian saldo** bertanggal hari ini, bukan pemasukan dan bukan
pengeluaran, dan saldo periode lampau tidak bergeser. Pada 17 Nov 2026 pemilik
juga menyetujui usul PO: penyesuaian **bisa dihapus**, tetapi **nominalnya
tidak bisa disunting**.

## 3. Keputusan

Tanukonomy menambah anggota keempat tipe tertutup `Transaction`:
**`BalanceAdjustmentTransaction`**. Satu penyesuaian dicatat setiap kali
pengguna mengubah saldo dompet ke angka yang berbeda dari saldo terhitungnya.
Penyesuaian ikut menghitung saldo dompet dan tidak pernah ikut Arus.

### 3.1 Entitas

```dart
final class BalanceAdjustmentTransaction extends Transaction {
  final String walletId;
  final AdjustmentDirection direction; // increase | decrease
  // amount: selisih absolut, > 0 (invarian dasar Transaction tetap berlaku)
  // categoryId: selalu null; tanpa budgetItemId; recurrence selalu null
}
```

- **Arah lewat `direction`, bukan tanda nominal.** Invarian `amount > 0` di
  `Transaction` (assert di konstruktor dan DOMAIN_MODEL) tetap utuh: arah uang
  ditentukan jenisnya, seperti tiga anggota lain.
- Tanpa kategori, pos anggaran, rutin, atau ikon sumber. `withRecurrence`
  pada penyesuaian mengembalikan dirinya sendiri; penyesuaian tidak pernah
  menjadi kandidat pencocokan rutin.
- `date` = waktu penyimpanan (hari ini). Penyesuaian tidak bisa diberi tanggal
  lampau; itulah yang menjaga periode lampau tetap utuh.
- `note` boleh diisi bila rupa menyediakannya; bawaannya kosong.

### 3.2 Mencatat dari Ubah dompet

`WalletBloc._onEdited` tidak lagi menyentuh `initialBalance`:

1. Bila kolom saldo diisi dengan angka yang berbeda dari saldo yang
   ditampilkan, hitung saldo dompet dari transaksi
   (`CalculateWalletBalance` atas seluruh transaksi, bukan cache
   `currentBalance`), lalu `selisih = angka diisi − saldo terhitung`.
2. Simpan perubahan nama, ikon, dan status aktif seperti sekarang.
3. Bila `selisih ≠ 0`, catat satu `BalanceAdjustmentTransaction` lewat
   **`RecordTransaction`**. Use case itu sudah menghitung ulang dompet
   (`walletIdsOf`) dan mengumumkan `LedgerChanges`. `WalletBloc` mendapat
   `RecordTransaction` lewat DI. Fitur `wallet` boleh mengimpor use case
   `shared/transaction` (ADR-030).
4. Bila langkah 3 gagal, nama dan ikon tetap tersimpan, saldo tidak berubah,
   dan pengguna mendapat pesan bahwa saldo belum tersimpan.

Ubah nama atau ikon saja tidak pernah membuat penyesuaian. Saldo awal
(`initialBalance`) hanya diisi saat **membuat** dompet. Dompet nonaktif boleh
disesuaikan.

### 3.3 Saldo

`CalculateWalletBalance` dan `RecomputeWalletBalances` menjumlahkan penyesuaian:
`increase` menambah, `decrease` mengurangi saldo `walletId`. Uji: saldo sesudah
penyesuaian sama dengan angka yang diisi, dan hasil cache sama dengan hitung
ulang penuh.

### 3.4 Semua pembaca Arus mengecualikan penyesuaian

Penyesuaian bernilai **0** untuk setiap hitungan pemasukan, pengeluaran, atau
selisih periode: `CalculateCashFlow` (kartu Arus Beranda, Rencana, Daftar
Riwayat), `summarize_period` dan kategori Analisis, `calculate_budget_progress`
(terpakai pos), `month_review`, serta Buku Periode dan Kartu Periode (ADR-045,
branch Fase 27). Uji kecocokan total buku tetap berlaku.

Switch pada `Transaction` **tidak memakai `default`/`_`**. Penambahan anggota
keempat sengaja membuat kompilasi gagal di setiap pembaca (34 berkas memakai
`TransferTransaction`), supaya tiap pembaca memutuskan secara eksplisit. Branch
yang digabung belakangan, termasuk Fase 27, memperbaiki switch-nya sendiri
dengan aturan yang sama.

### 3.5 Riwayat, detail, dan hapus

- Penyesuaian tampil di Riwayat sebagai jenis tersendiri dengan tanda + atau −,
  dalam rupa netral (bukan warna atau ikon pemasukan/pengeluaran).
  `TransactionTypeFilter` mendapat `adjustment`; cara menyembunyikannya
  ditentukan rupa (B-99, designer).
- Detail penyesuaian hanya menyediakan **Hapus** (dengan konfirmasi) lewat
  `RecordTransaction.delete`, yang mengembalikan saldo. Penyesuaian tidak
  pernah membuka formulir CATAT; tidak ada sunting nominal. Untuk mengoreksi,
  pengguna menghapus lalu mengubah saldo lagi lewat Ubah dompet.

### 3.6 Penyimpanan dan cadangan

- `TransactionModel.type = 'adjustment'` dengan field `direction`
  (`'increase'`/`'decrease'`). `schemaVersion` naik **2 → 3**. Data versi 2
  terbaca tanpa migrasi karena perubahannya hanya menambah.
- `transactionSchema` di `app_backup_registry.dart` naik ke 3, sehingga build
  lama **menolak** cadangan baru dengan pesan versi, bukan crash di
  `toEntity()` karena jenis tak dikenal.
- Partisi tetap ADR-012: dokumen bulan tanggal penyesuaian (bulan berjalan).

### 3.7 Ekspor

`ExportKind` mendapat `adjustmentIncrease` dan `adjustmentDecrease` dengan
label "Penyesuaian saldo (tambah)" dan "Penyesuaian saldo (kurang)" (en:
"Balance adjustment (increase/decrease)"). Kolom Nominal tetap positif seperti
baris lain, kolom Dompet berisi `walletId`, kategori kosong, dan `flowOf` = 0.
Jumlah kolom Arus per Awal periode tetap sama dengan kartu Arus.

### 3.8 Aturan 8 dan larangan "transaksi penyeimbang"

- **Pengecualian aturan 8:** penyesuaian saldo dicatat dari layar Ubah dompet,
  bukan dari CATAT, karena ia bukan peristiwa uang yang diketik pengguna,
  melainkan selisih antara catatan dan uang nyata. ADR-044 §3.6 (Proposed)
  juga menyebut dirinya "pengecualian ketiga". Nomor urut ditetapkan saat
  kedua ADR Accepted; sampai itu, teks aturan 8 menyebut pengecualian menurut
  isinya, bukan nomornya.
- **Larangan di `AGENT_CONTEXT.md`** ("Membuat transaksi penyeimbang untuk
  membetulkan catatan yang salah") **tetap berlaku** untuk catatan yang
  diketahui salah: sunting atau hapus transaksinya. Penyesuaian saldo adalah
  satu-satunya pengecualian. Ia hanya lahir dari Ubah dompet, untuk menyamakan
  catatan dengan uang nyata ketika sumber selisihnya tidak diketahui. Teks UI
  di dekat pratinjau selisih mengarahkan: bila tahu transaksi mana yang salah,
  sunting transaksi itu. Kode lain tidak boleh membuat penyesuaian.

### 3.9 Analitik

`balance_adjusted` dengan parameter `direction` (`increase`/`decrease`), tanpa
nominal (ADR-023).

### 3.10 Data lama

Tidak ada migrasi. Dompet yang `initialBalance`-nya sudah digeser perilaku
lama dibiarkan apa adanya; hanya perilaku ke depan yang berubah.

### 3.11 Formulir

Kolom saldo di Ubah dompet berlabel "Saldo sekarang", menerima saldo negatif
dan berpecahan sen (perbaikan nilai awal yang kosong), dan menampilkan
pratinjau selisih sebelum disimpan. Kolom "Saldo awal" hanya ada di Dompet baru.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Tetap menggeser `initialBalance`** (perilaku `0.11.0+17`).
  Ditolak lewat KT-W1: periode lampau bergeser dan jejak hilang.
- **Opsi B — Pemasukan/Pengeluaran berkategori "Penyesuaian".** Bocor ke Arus,
  Analisis, dan anggaran, kecuali setiap pembaca memeriksa kategori. Kategori
  bisa dihapus atau diganti nama oleh pengguna (ADR-026). Ditolak.
- **Opsi C — Subtipe baru dengan nominal bertanda.** Melanggar invarian
  `amount > 0` yang dipakai banyak kode dan uji. Ditolak.
- **Opsi D — Entitas "jangkar saldo"** (saldo dompet = Y per tanggal X, bukan
  transaksi). Mengubah rumus saldo di semua tempat, tidak muncul di Riwayat
  sebagai jejak, dan rumit diekspor. Ditolak.
- **Opsi E — Subtipe baru `BalanceAdjustmentTransaction` dengan `direction`
  (Dipilih).** Jejak terlihat, periode lampau utuh, invarian nominal positif
  utuh, dan kompilator memaksa setiap pembaca memutuskan.

## 5. Konsekuensi

- **Positif:** saldo historis stabil, sehingga B-96, B-100, dan Buku Periode
  bisa dipercaya; selisih terlihat dan bisa dihapus; satu aturan Arus yang
  jelas untuk anggota baru.
- **Negatif:** sapuan sekitar 36 berkas yang men-switch `Transaction`; skema
  transaksi naik sehingga build lama menolak cadangan baru; konflik kompilasi
  yang disengaja dengan branch Fase 27 saat digabung.
- **Dokumen yang ikut diperbarui:** DOMAIN_MODEL (anggota keempat),
  PROJECT_GLOSSARY dan `writing.md` (Penyesuaian saldo), `AGENT_CONTEXT.md`
  dan `.claude/CLAUDE.md` (aturan 8, larangan penyeimbang, paragraf "Ubah saldo
  dompet"), EXPORT_BACKUP (jenis baru).

## 6. Pertanyaan terbuka

1. Apakah penyesuaian bisa diberi catatan (`note`) dari Ubah dompet? Ditentukan
   rupa; domain sudah mendukung.
2. Cara menyembunyikan penyesuaian di Riwayat: filter "Semua kecuali
   penyesuaian" atau saklar tersendiri. Ditentukan rupa.

## 7. Revisi

- 2026-11-17: dibuat (Proposed), lalu disetujui pemilik (Accepted).
