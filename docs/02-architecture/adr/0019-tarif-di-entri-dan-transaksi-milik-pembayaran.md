# Tarif disimpan di entri worklog, dan transaksi milik pembayaran freelance

## 1. Metadata

- **Decision ID:** ADR-019
- **Tanggal:** 2026-09-25
- **Fase roadmap:** Fase 5
- **Status:** Accepted
- **Cakupan:** Fitur `freelance`, `IncomeTransaction` di `shared/transaction`,
  dan layar rincian transaksi.
- **Merevisi:** tabel `WorklogEntry` dan `FreelancePayment` serta rumus
  `entry.earnedAmount` di [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) bagian
  "Freelance"; tabel `IncomeTransaction` di bagian "Transaksi".

## 2. Konteks

DOMAIN_MODEL semula menurunkan tarif entri dari proyeknya
(`entry.earnedAmount = entry.hours × project.hourlyRate`), dan potongan
pembayaran dari `project.deductionRules`. Akibatnya, mengubah tarif atau
potongan proyek mengubah gaji kotor dan gaji bersih **seluruh** entri dan
pembayaran lama, termasuk pembayaran yang sudah dicatat diterima. Angkanya
lalu tidak lagi sama dengan transaksi pemasukan yang sudah menambah saldo.
PRD FR-FRL-002 juga meminta "tarif yang dipakai di entri itu", yang
menyiratkan tarif milik entri.

Ada lubang kedua. Pembayaran yang diterima melahirkan satu
`IncomeTransaction`. Transaksi itu bisa disunting atau dihapus dari tab
Transaksi seperti transaksi lain. Kalau dihapus, pembayarannya tetap `paid`
dengan `incomeTransactionId` yang tidak menunjuk ke mana pun, saldo sudah
turun, dan penjaga pencatatan ganda mencegah pembayaran itu dicatat ulang.

## 3. Keputusan

**`WorklogEntry` menyimpan `hourlyRate` sendiri.** Nilainya disalin dari
tarif proyek saat entri dicatat, dan boleh diubah di formulir entri.
Mengubah tarif proyek hanya berlaku untuk entri berikutnya.

```
entry.earnedAmount = entry.hours × entry.hourlyRate
```

**`FreelancePayment` menyimpan `deductionRules` sendiri**, disalin dari
proyek saat pembayaran dibuat. Mengubah potongan proyek hanya berlaku untuk
pembayaran berikutnya. Dengan kedua salinan ini, angka sebuah pembayaran
tidak pernah berubah setelah dibuat, karena entri yang sudah masuk
pembayaran juga tidak bisa disunting (FR-FRL-002).

**`IncomeTransaction` punya `freelancePaymentId`.** Transaksi yang field ini
terisi adalah milik pembayarannya:

- Tidak bisa disunting atau dihapus dari tab Transaksi. Rinciannya
  menjelaskan asalnya, dan perubahan hanya lewat Ikhtisar Freelance.
- Pembayaran yang sudah diterima punya aksi **Batalkan penerimaan**, yang
  menghapus transaksinya dan mengembalikan pembayaran ke `pending`.

**Id transaksi pembayaran diturunkan dari id pembayaran**
(`freelance-<paymentId>`). Transaksi ditulis lebih dulu, pembayaran
menyusul (urutan ADR-012: transaksi adalah kebenaran). Kalau penulisan
pembayaran gagal di tengah, mencatat ulang menimpa transaksi yang sama
alih-alih membuat transaksi kedua. Membatalkan penerimaan berjalan terbalik:
pembayaran dikembalikan ke `pending` lebih dulu, baru transaksinya dihapus,
sehingga kegagalan di tengah tidak pernah menyisakan pembayaran `paid` tanpa
transaksi.

**Proyek hanya bisa dihapus selama belum punya entri worklog.** Entri dan
pembayaran menunjuk proyek lewat `projectId`, dan menghapus proyek yang
masih dirujuk akan meninggalkan data yang tidak bisa ditampilkan.

## 4. Konsekuensi

- `CalculateNetPay` menerima `grossPay` langsung, bukan `totalHours` dan
  `hourlyRate`, karena entri dalam satu pembayaran boleh bertarif berbeda.
  Kasus uji 37 jam × Rp72.500 dengan pajak 2,5% tetap menghasilkan
  Rp2.615.438.
- `TransactionModel` mendapat kunci opsional `freelancePaymentId`; transaksi
  lama tanpa kunci itu dibaca sebagai transaksi biasa, tidak perlu migrasi.
- `FreelancePayment` mendapat `receivedDate`, terisi bersama
  `incomeTransactionId`, supaya pembatalan tahu di dokumen bulan mana
  transaksinya tersimpan (ADR-012).
- Tab Transaksi tidak perlu membaca data freelance untuk tahu sebuah
  transaksi terkunci; cukup field di transaksinya sendiri.

## 5. Alternatif yang ditolak

**Mengunci tarif dan potongan proyek setelah proyek punya entri.** Sesuai
DOMAIN_MODEL semula tanpa revisi, tetapi setiap kenaikan tarif memaksa
pemilik membuat proyek baru untuk klien yang sama.

**Menyalin tarif hanya saat pembayaran dibuat.** Entri yang belum
ditagihkan tetap ikut berubah saat tarif proyek diubah, padahal kerjanya
sudah selesai dengan tarif lama.

**Membiarkan transaksi pembayaran bebas dihapus, dan pembayaran otomatis
kembali tertunda.** Tab Transaksi harus membaca dan menulis data freelance
setiap kali menghapus, dan penyuntingan nominal tetap membuat pembayaran
dan transaksinya tidak sama.
