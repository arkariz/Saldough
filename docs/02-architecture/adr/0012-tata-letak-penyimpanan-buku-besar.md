# Tata letak penyimpanan buku besar transaksi

## 1. Metadata

- **Decision ID:** ADR-012
- **Tanggal:** 2026-09-17
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

[ADR-0002](0002-local-first-hive-document-storage.md) memutuskan Saldough
menyimpan satu dokumen JSON per agregat di atas satu box Hive, tanpa basis data
relasional. Keputusan itu diambil saat agregat terbesarnya adalah `MonthlyCycle`
— satu dokumen per bulan, sepuluh dokumen untuk seluruh riwayat pemilik.
Seluruh dokumen dibaca utuh, disunting di memori, lalu ditulis utuh kembali.

[ADR-011](0011-model-domain-dompet-transaksi-anggaran.md) mengubah bentuk data
secara mendasar. Buku besar transaksi punya tiga sifat yang tidak dimiliki
`MonthlyCycle`:

- **Tidak berbatas.** Ia bertambah selamanya. Pemilik yang mencatat sepuluh
  transaksi seminggu menghasilkan sekitar 500 transaksi setahun, dan aplikasi
  ini dimaksudkan dipakai bertahun-tahun.
- **Banyak penulisan kecil.** Pola pemakaiannya adalah menambah satu transaksi,
  puluhan kali seminggu — bukan menyunting satu dokumen besar sesekali.
- **Banyak pembacaan agregat.** Beranda butuh total pemasukan dan pengeluaran
  bulan berjalan; layar Anggaran butuh jumlah pengeluaran yang tertaut ke tiap
  pos; layar Dompet butuh saldo tiap dompet. Semua itu penjumlahan atas
  transaksi.

Batasan lapisan penyimpanannya juga nyata. `KeyValueStorage` dari
`package:api_storage` hanya menyediakan baca dan tulis satu kunci; tidak ada
indeks, tidak ada query, dan tidak ada transaksi multi-kunci. Apa pun yang
menyerupai query harus disusun sendiri dari pola kunci.

Dua kebutuhan non-fungsional mengikat keputusan ini:
[NFR-PERF-002](../../01-product/prd-saldough-2.0.md) menuntut waktu tampil
Beranda tidak ikut bertambah seiring panjangnya riwayat, dan
[NFR-ACC-003](../../01-product/prd-saldough-2.0.md) menuntut saldo yang
ditampilkan selalu sama persis dengan saldo yang dihitung dari transaksi.

## 3. Keputusan

Saldough menyimpan transaksi **terpartisi per bulan**, dan menyimpan
**`Wallet.currentBalance` sebagai nilai yang di-cache** beserta fungsi
penghitungan ulang yang membuktikannya.

### Tata letak kunci

| Kunci | Isi |
|---|---|
| `transaction` / `_index` | Daftar `YYYY-MM` yang punya dokumen, terurut |
| `transaction` / `YYYY-MM` | Seluruh transaksi bulan itu |
| `wallet` / `all` | Seluruh dompet |
| `budget` / `all` | Seluruh anggaran beserta posnya |
| `budget_template` / `all` | Seluruh template anggaran |
| `freelance` / `projects` | Seluruh proyek freelance |
| `freelance` / `worklog` | Seluruh entri worklog |
| `freelance` / `payments` | Seluruh pembayaran freelance |

Pola `_index` mengikuti preseden `cycle` / `_index` dari Saldough 1.0.
Partisi bulanan dipilih karena cocok dengan cara data dibaca: Beranda hanya
butuh bulan berjalan, dan layar Transaksi mengelompokkan per tanggal sehingga
bisa dimuat per bulan sambil digulir.

Entitas freelance sengaja tidak dipartisi. Lajunya rendah — beberapa entri per
minggu, beberapa pembayaran per bulan — sehingga satu dokumen tetap kecil dalam
hitungan tahun. Kalau kelak tidak lagi benar, ia dipartisi mengikuti pola yang
sama tanpa mengubah keputusan ini.

### `Wallet.currentBalance` disimpan

`currentBalance` ditulis ulang setiap kali transaksi yang menyentuh dompet itu
dicatat, disunting, atau dihapus. Ini **penyimpangan sadar** dari prinsip "nilai
turunan tidak pernah disimpan" yang dipegang di seluruh model lain.

Penyimpangan itu hanya sah dengan tiga penyeimbang, dan ketiganya wajib:

1. Fungsi `recomputeWalletBalances()` yang menghitung ulang seluruh saldo dari
   `initialBalance` ditambah seluruh transaksi, dan menuliskannya.
2. Uji unit yang mencatat serangkaian transaksi lalu membuktikan
   `wallet.currentBalance` identik dengan hasil penghitungan ulang. Tanpa uji
   ini, keputusan ini tidak boleh diambil.
3. Urutan penulisan yang ditetapkan: **dokumen transaksi ditulis lebih dulu,
   dokumen dompet menyusul.** Transaksi adalah kebenaran, saldo adalah
   cache-nya.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Satu dokumen tunggal berisi seluruh transaksi**
- **Opsi B — Satu dokumen per transaksi**
- **Opsi C — Partisi per bulan, dengan saldo dompet di-cache (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Satu dokumen tunggal berisi seluruh transaksi

Kunci `transaction` / `all` berisi seluruh riwayat. Paling sederhana, dan
paling dekat dengan cara `GroceryPlan` atau `GoalLoan` disimpan di Saldough 1.0.

Pembacaannya mudah: satu kali baca memberi segalanya, dan seluruh penjumlahan
bisa dilakukan di memori tanpa aturan tambahan. Untuk seratus transaksi pertama
ia bahkan lebih cepat daripada opsi mana pun.

Yang mematikan adalah biaya penulisannya. Setiap satu transaksi baru menulis
ulang **seluruh** dokumen. Setelah tiga tahun pemakaian, mencatat satu belanja
Rp20.000 berarti menyerialkan dan menulis ulang sekitar 1.500 transaksi. Biaya
itu tumbuh selamanya dan tidak punya batas atas, padahal penulisan adalah operasi
yang paling sering dilakukan pemilik. Ini melanggar NFR-PERF-002 secara
langsung.

### Opsi B — Satu dokumen per transaksi

Kunci `transaction` / `<id>` untuk tiap transaksi. Penulisannya sangat murah dan
berukuran tetap, berapa pun panjang riwayatnya — kebalikan persis dari
kelemahan Opsi A.

Masalahnya berpindah ke pembacaan. `KeyValueStorage` tidak punya indeks maupun
query, jadi "seluruh transaksi bulan ini" berarti membaca setiap kunci satu per
satu, atau memelihara dokumen indeks tersendiri yang isinya tidak lain adalah
daftar transaksi — yang membawa kembali biaya penulisan Opsi A lewat pintu
belakang. Menghitung saldo dompet jadi N pembacaan terpisah, dan Beranda
menyentuh seluruh riwayat untuk menampilkan angka bulan berjalan.

Opsi ini akan masuk akal di atas basis data yang punya indeks. Di atas
penyimpanan kunci-nilai polos, ia menukar satu masalah dengan masalah yang lebih
buruk.

### Opsi C — Partisi per bulan, dengan saldo dompet di-cache (Dipilih)

Kunci `transaction` / `YYYY-MM`. Penulisan menyentuh satu dokumen berisi
transaksi satu bulan saja — sekitar empat puluh sampai seratus entri, dan
ukurannya tidak tumbuh seiring umur aplikasi. Pembacaan cocok dengan cara data
dipakai: Beranda membaca satu dokumen, layar Transaksi membaca per bulan sambil
digulir, dan layar Anggaran membaca bulan-bulan yang dilintasi periodenya.

Satu hal tetap tidak terselesaikan oleh partisi: **saldo dompet bergantung pada
seluruh riwayat**, bukan pada satu bulan. Menghitungnya dari nol berarti membaca
setiap dokumen bulanan yang pernah ada, tiap kali Beranda digambar. Karena total
saldo adalah angka utama aplikasi dan harus tampil di bawah satu detik,
saldonya di-cache di `Wallet.currentBalance`.

Kelemahan opsi ini jujur dan tidak kecil. Menyimpan nilai turunan berarti
menerima kemungkinan **melenceng**: Hive tidak punya transaksi multi-kunci, jadi
kegagalan di antara penulisan dokumen transaksi dan dokumen dompet meninggalkan
saldo yang tidak cocok dengan riwayatnya. Itu sebabnya urutan penulisannya
ditetapkan — transaksi dulu, dompet menyusul — sehingga kegagalan menghasilkan
saldo yang *tertinggal*, bukan saldo yang mengandung uang hantu. Dan itu sebabnya
fungsi penghitungan ulang beserta ujinya dijadikan syarat, bukan pelengkap.

Alternatif tanpa cache — menghitung saldo dari nol tiap kali — lebih murni dan
mustahil melenceng. Ia ditolak bukan karena salah, melainkan karena
mengorbankan angka yang paling sering dilihat pemilik demi kemurnian yang tidak
ia rasakan.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Biaya mencatat satu transaksi tetap, berapa pun panjang riwayatnya.
- Beranda dan layar Dompet menampilkan angkanya tanpa menyentuh riwayat lama.
- Menghapus atau mengarsipkan riwayat lama kelak cukup dengan membuang dokumen
  bulanan yang bersangkutan.
- Bentuk penyimpanannya tetap satu dokumen JSON per kunci, jadi konvensi
  `schemaVersion` dan pola `StoredValue` dari ADR-0002 berlaku apa adanya.

### Yang menjadi lebih sulit

- Menyunting transaksi yang tanggalnya berpindah bulan berarti menyentuh dua
  dokumen: menghapus dari dokumen lama, menambah ke dokumen baru.
- Setiap penulisan transaksi juga harus memperbarui satu atau dua dokumen
  dompet, jadi satu tindakan pemilik menghasilkan beberapa penulisan.
- Laporan yang melintasi banyak bulan harus membaca beberapa dokumen dan
  menggabungkannya sendiri.

### Risiko yang diterima

- **Saldo bisa melenceng dari riwayat** kalau penulisan gagal di tengah jalan.
  Diterima, dengan urutan penulisan yang ditetapkan sebagai pembatas kerusakan
  dan `recomputeWalletBalances()` sebagai pemulihnya.
- **Dokumen bulan sangat sibuk bisa membesar.** Seratus transaksi sebulan masih
  jauh di bawah ukuran yang merepotkan, tetapi batas itu tidak dijaga kode.
- **Entitas freelance belum dipartisi.** Aman untuk laju pemakaian sekarang,
  dan perlu ditinjau kalau pemilik menambah banyak proyek.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Urutan penulisan tidak boleh dibalik: dokumen `transaction` / `YYYY-MM` lebih
  dulu, baru dokumen `wallet` / `all`.
- `transaction` / `_index` diperbarui dalam operasi yang sama saat sebuah bulan
  baru pertama kali punya transaksi.
- Repository transaksi wajib menyediakan `recomputeWalletBalances()`, dan
  fungsi itu wajib punya uji yang membandingkannya dengan `currentBalance`.
- Penyuntingan yang memindahkan transaksi antar bulan wajib menghapus dari
  dokumen asal sebelum menambah ke dokumen tujuan, supaya kegagalan di tengah
  tidak menghasilkan transaksi ganda.
- Setiap dokumen membawa `schemaVersion`, mengikuti ADR-0002.

### Antipola yang harus dihindari

- Membaca seluruh dokumen bulanan untuk menampilkan saldo. Itu persis yang
  dihindari keputusan ini.
- Menyimpan nilai turunan lain — `spent`, `progress`, total bulanan — dengan
  alasan yang sama. Pengecualian ini hanya berlaku untuk
  `Wallet.currentBalance`, karena hanya ia yang bergantung pada seluruh riwayat
  sekaligus ditampilkan di layar pertama.
- Memakai `DateTime.now()` untuk menentukan dokumen tujuan sebuah transaksi.
  Yang menentukan adalah `transaction.date`, bukan kapan pencatatannya
  dilakukan.

## 8. Kriteria peninjauan ulang

- Satu dokumen bulanan melampaui ukuran yang membuat pembacaan Beranda terasa
  lambat. Partisinya diperhalus jadi mingguan, atau penyimpanannya diganti.
- Saldo terbukti pernah melenceng di pemakaian nyata. Kalau itu terjadi lebih
  dari sekali, cache-nya dilepas dan saldo dihitung dari nol.
- `package:api_storage` mendapat dukungan query atau transaksi multi-kunci.
  Sebagian besar alasan keputusan ini hilang, dan Opsi B jadi layak.
- Entitas freelance tumbuh melewati beberapa ratus entri.

## 9. Artefak terkait

### Dokumentasi

- [ADR-0002](0002-local-first-hive-document-storage.md) — keputusan penyimpanan
  dasar yang diperluas ADR ini.
- [ADR-011](0011-model-domain-dompet-transaksi-anggaran.md) — model domain yang
  disimpan dengan tata letak ini.
- [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) — rumus saldo dompet yang dipakai
  `recomputeWalletBalances()`.
- [PRD 2.0](../../01-product/prd-saldough-2.0.md) — NFR-PERF-002 dan
  NFR-ACC-003.

### Rujukan kode

- `lib/features/transaction/data/repositories/` — repository transaksi beserta
  `recomputeWalletBalances()`.
- `lib/features/wallet/data/repositories/` — repository dompet.
- `test/features/transaction/data/` — uji yang membuktikan saldo tersimpan sama
  dengan saldo turunan.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-17
**Status implementasi:** Disetujui, belum diimplementasikan
