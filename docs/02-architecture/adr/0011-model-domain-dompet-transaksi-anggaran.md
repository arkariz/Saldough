# Model domain inti: dompet, transaksi, dan anggaran

## 1. Metadata

- **Decision ID:** ADR-011
- **Tanggal:** 2026-09-17, diperluas 2026-09-17
- **Fase roadmap:** Fase 0
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Saldough 1.0 adalah pengganti digital sistem empat Google Spreadsheet milik
pemilik. Agregat intinya `MonthlyCycle`: satu dokumen per bulan berisi baris
pemasukan, baris anggaran, dan rencana investasi — setara satu blok tabel di
spreadsheet utama.

Setelah dipakai, model itu menunjukkan satu keterbatasan yang tidak bisa
diperbaiki dari dalam: **ia tidak punya konsep transaksi maupun saldo.**
`IncomeLine` dan `BudgetLine` adalah baris rencana milik sebuah bulan, tanpa
tanggal dan tanpa dompet asal. Satu-satunya entitas berbentuk transaksi nyata di
seluruh kode 1.0 adalah `CardTransaction`, dan ia terkunci di dalam fitur kartu.
Tidak ada satu pun field yang menyatakan berapa isi sebuah rekening pada hari
tertentu.

Akibatnya tiga pertanyaan paling dasar tidak bisa dijawab: berapa uang saya
sekarang, di mana uang itu, dan apa saja yang sudah terjadi padanya. Pertanyaan
itu tidak bisa diturunkan dari agregat bulanan, karena arah penurunannya satu
arah — transaksi bisa diringkas jadi total bulanan, tetapi total bulanan tidak
bisa dipecah kembali jadi transaksi tanpa mengarang data.

Batasan lain yang membentuk keputusan ini:

- Aplikasi hanya **mencatat**. Ia tidak memindahkan uang, tidak membayar, dan
  tidak terhubung ke bank. Model domainnya harus mencerminkan itu, bukan meniru
  sistem perbankan.
- Belanja mingguan, tagihan yang periodenya bukan bulan kalender, dan
  penghasilan freelance yang periodenya delapan hari sampai sebulan semuanya
  harus muat tanpa dipaksa masuk kotak `YYYY-MM`.
- Pemilik menilai alur 1.0 terlalu rumit. Model baru harus lebih sedikit
  konsepnya, bukan lebih banyak.
- Penghasilan freelance punya sifat yang tidak dimiliki pemasukan biasa:
  pekerjaannya selesai jauh sebelum uangnya diterima. Sifat itu harus terlihat
  di model, bukan disamarkan.

## 3. Keputusan

Saldough memakai **`Wallet` dan `Transaction` sebagai inti**, **`Budget`
beserta `BudgetItem` dan `BudgetTemplate` sebagai lapisan rencana**, dan
**`FreelanceProject`, `WorklogEntry`, serta `FreelancePayment` sebagai domain
pendukung**. `MonthlyCycle` beserta seluruh turunannya dihapus.

Bentuk lengkap tiap entitas ada di [DOMAIN_MODEL.md](../DOMAIN_MODEL.md).
Yang mengikat implementasi:

### Anggaran adalah rencana, bukan pemesanan uang

Membuat, menyunting, atau menghapus `Budget`, `BudgetItem`, maupun
`BudgetTemplate` **tidak pernah** mengubah saldo dompet mana pun. Dompet
bersaldo Rp5.000.000 yang dijadikan sumber anggaran Rp3.000.000 tetap bersaldo
Rp5.000.000. Saldo hanya berubah kalau ada transaksi yang dicatat.

### Satu anggaran terikat satu dompet, dan ikatan itu menyaring

`Budget.walletId` wajib terisi. Hanya transaksi yang keluar dari dompet itu yang
menambah `spent`: pengeluaran dicocokkan lewat `walletId`, transfer lewat
`fromWalletId`. Transaksi dari dompet lain tidak terhitung meski ditautkan ke pos
anggaran itu, dan pemilih pos di antarmuka hanya menawarkan pos yang dompetnya
cocok.

> **Catatan perluasan (17 September 2026):** Versi pertama ADR ini hanya
> mengizinkan **pengeluaran** ditautkan ke pos anggaran; `TransferTransaction`
> tidak punya `budgetItemId` sama sekali. Itu **keliru**, dan sekarang
> diperluas. Sebagian rencana pengeluaran memang berbentuk pemindahan, bukan
> belanja: anggaran `Tabungan` dari dompet `BCA` dipenuhi dengan mentransfer ke
> dompet `Tabungan`. Tanpa tautan itu, anggaran semacam itu tidak bisa berjalan
> sama sekali — dan itu persis kebiasaan nyata pemilik, yang dulu membagi sisa
> bulanan ke enam pos tabungan. Dua aturan menyertai perluasan ini: transfer
> dicocokkan lewat `fromWalletId` (bukan `walletId`), dan satu transaksi tetap
> hanya boleh menaikkan **satu** pos anggaran supaya tidak terhitung ganda saat
> dompet tujuannya juga punya anggaran.
>
> Perluasan kedua di tanggal yang sama: `Budget` mendapat `isArchived`. Versi
> pertama tidak punya siklus hidup anggaran sama sekali, sehingga penyaring
> "aktif / selesai / nonaktif" yang diminta produk tidak bisa diimplementasikan.
> Hanya `nonaktif` yang butuh penanda tersimpan; `aktif` dan `selesai` turunan
> dari periodenya, mengikuti prinsip bahwa yang bisa dihitung tidak disimpan.

### Beberapa anggaran aktif sekaligus

Tidak ada kewajiban menutup satu anggaran sebelum membuat yang lain. Beberapa
anggaran boleh berbagi satu dompet, dan boleh berbeda periode. Tidak ada objek
anggaran bulanan global.

### Kerja selesai bukan uang diterima

`WorklogEntry` menambah nilai yang **diperoleh** dan tidak pernah menyentuh
saldo dompet. Saldo baru berubah saat `FreelancePayment` dicatat diterima, yang
membuat **tepat satu** `IncomeTransaction` sebesar gaji bersih.
`incomeTransactionId` yang sudah terisi adalah penjaganya supaya pembayaran yang
sama tidak bisa dicatat dua kali.

### Transfer memindahkan, bukan menambah atau mengurangi

`TransferTransaction` mengurangi satu dompet dan menambah dompet lain dengan
nominal sama. Ia tidak pernah dihitung sebagai pemasukan maupun pengeluaran di
ringkasan mana pun.

### Nilai turunan tidak disimpan

`spent`, `remaining`, `progress`, status pos, gaji kotor, gaji bersih, dan total
saldo semuanya dihitung ulang saat diakses. Satu-satunya pengecualian adalah
`Wallet.currentBalance`, yang diputuskan terpisah di
[ADR-012](0012-tata-letak-penyimpanan-buku-besar.md) beserta penyeimbangnya.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Pertahankan `MonthlyCycle`, tambahkan dompet di sampingnya**
- **Opsi B — Dompet dan transaksi saja, tanpa lapisan anggaran**
- **Opsi C — Dompet dan transaksi sebagai inti, anggaran sebagai lapisan
  rencana di atasnya (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Pertahankan `MonthlyCycle`, tambahkan dompet di sampingnya

Menyimpan seluruh kode 1.0 dan menambahkan `Wallet` beserta `Transaction`
sebagai fitur baru. Baris anggaran bulanan tetap ada, dan dompet hidup
berdampingan dengannya.

Keuntungannya jelas: tidak ada kode yang dibuang, dan pekerjaan pivot jadi
penambahan murni. Masalahnya, model itu langsung punya dua sumber kebenaran
untuk pertanyaan yang sama. Pengeluaran `listrik` akan tercatat dua kali — satu
sebagai baris anggaran bulan Maret, satu lagi sebagai transaksi bertanggal — dan
tidak ada aturan yang bisa menentukan mana yang benar saat keduanya berbeda.
Pemilik harus memutuskan sendiri, tiap kali, layar mana yang dipercaya.

Opsi ini juga tidak menyelesaikan keluhan yang memicu pivot. Alur 1.0 dinilai
rumit; menambahkan satu model lagi di sampingnya membuatnya lebih rumit, bukan
kurang.

### Opsi B — Dompet dan transaksi saja, tanpa lapisan anggaran

Hanya `Wallet` dan `Transaction`. Anggaran ditinggalkan seluruhnya, dan pemilik
memantau pengeluarannya lewat riwayat dan penyaring kategori.

Ini model paling kecil dan paling jujur: setiap angka di aplikasi berasal dari
peristiwa yang benar-benar terjadi. Ia juga menghapus seluruh pertanyaan sulit
soal bagaimana rencana berinteraksi dengan kenyataan.

Yang hilang adalah kebiasaan nyata pemilik. Ia menganggarkan secara sadar tiap
bulan, merinci belanja jadi puluhan pos dengan harga satuan, dan memutuskan
pembelian berdasarkan sisa anggaran — bukan berdasarkan riwayat. Menghapus
anggaran berarti memindahkan pekerjaan itu kembali ke luar aplikasi, yang
persis masalah yang ingin diselesaikan sejak awal.

### Opsi C — Dompet dan transaksi sebagai inti, anggaran sebagai lapisan rencana (Dipilih)

Transaksi adalah satu-satunya sumber kebenaran; anggaran membaca darinya dan
tidak pernah menulis ke saldo. Rencana dan kenyataan jadi dua lapisan yang
terpisah dengan arah ketergantungan yang jelas.

Yang membuat opsi ini menang bukan cuma kelengkapannya, tetapi berapa banyak
konsep lama yang ia **serap tanpa menambah apa pun**:

| Kebiasaan nyata pemilik | Di model 1.0 | Di model 2.0 |
|---|---|---|
| Enam pos tabungan | `Goal`, `Allocation`, `CalculateGoalBalances` | Enam `Wallet` |
| Membagi sisa 15% ke satu pos | `AllocationPercentage`, invarian total 0/100 | Satu `TransferTransaction` |
| Satu pos meminjami pos lain | `GoalLoan` | Satu `TransferTransaction` |
| Belanja kartu kredit | `CardStatement`, periode cetak | `ExpenseTransaction` dari dompet kartu |
| Membayar tagihan kartu | tidak termodelkan | Satu `TransferTransaction` |
| Daftar belanja 35 item berharga satuan | `GroceryPlan`, `GroceryItem`, pengali minggu | `Budget` dengan 35 `BudgetItem` |

Seluruh fitur investasi dan sebagian besar fitur kartu hilang bukan karena
dibuang, melainkan karena primitif transfer sudah mengerjakannya. Model yang
lebih umum ternyata lebih kecil, bukan lebih besar.

Kelemahannya nyata dan diterima sadar. Yang terbesar: mengikat anggaran ke satu
dompet membuat pengeluaran dari dompet lain tidak terhitung, padahal belanja
pemilik sungguhan campur antara tunai, BCA, dan GoPay. Alternatifnya —
`walletId` opsional yang hanya jadi nilai bawaan formulir — lebih longgar tetapi
membuat pertanyaan "anggaran ini menghabiskan uang siapa" tidak punya jawaban
pasti. Pemilik memilih ikatan yang keras, dan konsekuensinya dicatat di bagian 6
supaya bisa ditinjau setelah dipakai sebulan.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Pertanyaan "berapa uang saya dan di mana" punya jawaban tunggal yang bisa
  dihitung, bukan disusun manual dari beberapa layar.
- Menambah jenis dompet baru — tabungan, kartu, dompet digital — tidak
  memerlukan konsep domain baru sama sekali.
- Periode apa pun bisa ditampung. Anggaran mingguan, pembayaran freelance
  delapan hari, dan tagihan yang melintasi bulan tidak lagi dipaksa masuk kotak
  `YYYY-MM`.
- Ringkasan bulanan jadi hasil query atas transaksi, bukan entitas yang harus
  dibuat, ditutup, dan dijaga konsistensinya.
- Jumlah konsep yang harus dipahami pemilik turun dari sembilan domain jadi
  tiga lingkaran.

### Yang menjadi lebih sulit

- Pemilik harus mencatat transaksi satu per satu. Model 1.0 cukup menuliskan
  satu angka per baris per bulan; model 2.0 menuntut disiplin harian. Kalau
  pencatatan itu tidak berjalan, seluruh angka aplikasi jadi salah.
- Saldo awal tiap dompet harus diisi dari nol, karena tidak ada satu pun saldo
  yang tercatat di data 1.0.
- Anggaran yang terikat satu dompet menuntut pemilik konsisten membayar satu
  kategori dari satu dompet, atau menerima bahwa sebagian belanjanya tidak
  terhitung.

### Risiko yang diterima

- **Ikatan anggaran ke dompet terasa mengekang.** Belanja yang dibayar dari
  dompet di luar `Budget.walletId` tidak menambah `spent`, sehingga progres
  anggaran bisa terlihat lebih rendah dari kenyataan. Diterima atas pilihan
  eksplisit pemilik. Kriteria peninjauannya ada di bagian 8.
- **Kartu kredit belum termodelkan sebagai liabilitas.** Model menampungnya
  sebagai dompet bersaldo negatif tanpa konsep tambahan, tetapi aturan
  tagihannya belum dirancang.
- **Kategori transaksi belum punya daftar bawaan.** Kalau pemilik mengetik
  kategori yang berbeda-beda untuk hal yang sama, penyaring jadi kurang
  berguna.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- `Transaction` adalah `sealed class` dengan tepat tiga anggota. Menambah
  anggota keempat mengubah aturan perhitungan saldo dan wajib lewat ADR baru.
- Nominal transaksi selalu positif. Arah uang ditentukan jenis transaksinya,
  bukan tanda nominalnya.
- `fromWalletId` dan `toWalletId` pada transfer harus berbeda.
- Setiap perhitungan `spent` wajib menyaring dompetnya: `expense.walletId` dan
  `transfer.fromWalletId`, keduanya terhadap `budget.walletId`. Melewatkan
  penyaring itu membuat angka anggaran salah tanpa gejala yang kelihatan.
- Satu transaksi hanya boleh punya satu `budgetItemId`. Jangan menambahkan
  tautan kedua "supaya transfer bisa terhitung di anggaran asal dan tujuan" —
  itu menghasilkan hitung ganda.
- Potongan persentase selalu dihitung dari gaji kotor, tidak pernah dari nilai
  berjalan setelah potongan sebelumnya.
- `FreelancePayment` yang `status = paid` wajib punya `incomeTransactionId`.
  Keduanya berubah dalam satu operasi, tidak pernah terpisah.

### Antipola yang harus dihindari

- Menyimpan `spent`, `remaining`, `progress`, atau status pos sebagai field.
  Semuanya dihitung ulang.
- Membuat entitas "ringkasan bulanan". Ringkasan adalah hasil query, bukan
  agregat yang disimpan.
- Membuat transaksi penyeimbang untuk membetulkan catatan yang salah. Transaksi
  disunting atau dihapus, dan saldo dihitung ulang.
- Memperlakukan `initialBalance` sebagai transaksi pemasukan. Ia pernyataan
  keadaan, dan tidak muncul di riwayat.
- Menghidupkan kembali mekanisme roll-up 1.0, yaitu baris anggaran yang
  nominalnya dihitung dari fitur lain. Di model 2.0, angka terpakai selalu
  berasal dari transaksi nyata.

## 8. Kriteria peninjauan ulang

Keputusan ini ditinjau ulang kalau salah satu terjadi:

- Setelah satu bulan pemakaian, pemilik mendapati lebih dari seperempat
  pengeluaran sebuah anggaran dibayar dari dompet di luar `Budget.walletId`.
  Itu tanda ikatan wajib anggaran–dompet perlu dilonggarkan jadi opsional.
- Pemilik berhenti mencatat transaksi harian selama lebih dari satu minggu
  berturut-turut. Itu tanda biaya pencatatannya terlalu tinggi dan modelnya
  perlu jalan pintas, misalnya transaksi berulang.
- Kartu kredit dimasukkan ke cakupan. Aturan tagihan dan pembayarannya perlu
  ADR sendiri.
- Muncul kebutuhan satu transaksi ditautkan ke lebih dari satu pos anggaran.
  Model saat ini sengaja membatasinya jadi paling banyak satu.
- Pemilik mendapati anggaran yang berisi campuran pos belanja dan pos setoran
  terasa membingungkan dibaca. Kalau itu terjadi, pemisahan jenis pos perlu
  dipertimbangkan.

## 9. Artefak terkait

### Dokumentasi

- [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) — bentuk lengkap tiap entitas, rumus,
  dan invariannya.
- [PRD 2.0](../../01-product/prd-saldough-2.0.md) — kebutuhan fungsional yang
  diturunkan dari model ini.
- [ADR-012](0012-tata-letak-penyimpanan-buku-besar.md) — tata letak penyimpanan
  transaksi dan alasan `Wallet.currentBalance` disimpan.
- [ADR-014](0014-strategi-pivot-saldough-2.md) — cara peralihan dari model lama
  dikerjakan.
- [ADR-0008](0008-monthly-cycle-template-and-rollup.md) — keputusan yang
  digantikan ADR ini.
- [PROJECT_GLOSSARY.md](../../00-foundation/PROJECT_GLOSSARY.md) — istilah
  Indonesia dan nama kodenya.

### Rujukan kode

- `lib/features/wallet/domain/` — `Wallet`.
- `lib/features/transaction/domain/` — `Transaction` beserta ketiga anggotanya.
- `lib/features/budget/domain/` — `Budget`, `BudgetItem`, `BudgetTemplate`.
- `lib/features/freelance/domain/` — `FreelanceProject`, `WorklogEntry`,
  `FreelancePayment`, dan `CalculateNetPay` yang dipindahkan dari
  `lib/shared/income/`.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-17
**Status implementasi:** Disetujui, belum diimplementasikan
