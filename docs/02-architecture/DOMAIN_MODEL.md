# Model domain

Dokumen ini menerjemahkan kebutuhan produk di
[PRD 2.0](../01-product/prd-saldough-2.0.md) menjadi entitas, rumus, dan
invarian yang bisa langsung diimplementasikan.

Model ini murni domain. Tidak ada satu pun entitas di sini yang boleh mengimpor
Flutter, Hive, atau paket infrastruktur lain. Aturan lengkapnya ada di
[ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md).

> **Catatan versi (17 September 2026):** Dokumen ini ditulis ulang total untuk
> Saldough 2.0. Model 1.0 berporos pada `MonthlyCycle` dengan baris pemasukan
> dan anggaran milik satu bulan; model 2.0 berporos pada dompet, transaksi
> bertanggal, dan anggaran yang berdiri sendiri. Tidak ada satu pun entitas 1.0
> yang bertahan apa adanya. Versi lamanya bisa dibaca lewat riwayat git.

## Aturan representasi uang

Seluruh nominal adalah `int` dalam satuan **sen**, bukan rupiah, dan bukan
`double`. Pembulatan hanya terjadi saat menampilkan.

Aturan ini bukan preferensi gaya. Potongan pajak freelance 2,5% menghasilkan
pecahan setengah rupiah, dan membulatkannya terlalu dini meleset satu rupiah:

```
grossPay   = Rp3.117.500          = 311.750.000 sen
pajak 2,5% = 311.750.000 × 25 ~/ 1000 =   7.793.750 sen
netPay     = 311.750.000 − 7.793.750  = 303.956.250 sen
tampil     = Rp3.039.563            (pembulatan setengah ke atas)
```

Kalau pajaknya dibulatkan lebih dulu ke Rp77.938, gaji bersihnya jadi
Rp3.039.562 — meleset satu rupiah dari catatan pemilik. Menghitung di satuan sen
dengan tarif per mil menghilangkan kebutuhan pembulatan perantara sama sekali.

Pembulatan tampilan memakai setengah ke atas dan aritmetika bilangan bulat
murni, bukan `~/` yang memotong ke arah nol dan salah untuk nilai negatif
(`-7 ~/ 2` menghasilkan `-3`, padahal yang benar `-4`).

## Ringkasan entitas

Delapan entitas, dikelompokkan jadi tiga lingkaran: inti, rencana, dan
pendukung.

| Entitas | Lingkaran | Peran |
|---|---|---|
| `Wallet` | Inti | Tempat uang tercatat berada |
| `Transaction` | Inti | Peristiwa yang terjadi pada uang |
| `Budget` | Rencana | Rencana pengeluaran satu periode |
| `BudgetItem` | Rencana | Satu baris di dalam rencana itu |
| `BudgetTemplate` | Rencana | Definisi yang bisa dipakai ulang |
| `FreelanceProject` | Pendukung | Klien beserta tarif dan potongannya |
| `WorklogEntry` | Pendukung | Kerja yang sudah selesai |
| `FreelancePayment` | Pendukung | Tagihan yang menunggu dibayar |

Tidak ada entitas untuk saldo turunan, ringkasan bulanan, `spent`, `remaining`,
`progress`, maupun `status`. Semuanya dihitung ulang saat diakses.

## Dompet

`Wallet` menyatakan di mana uang pemilik tercatat berada. Ia tidak terhubung ke
lembaga keuangan mana pun; `BCA Rp5.000.000` berarti "pemilik menyatakan
tercatat ada Rp5.000.000 di sana".

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas dompet. |
| `name` | `String` | Nama yang dipilih pemilik, misalnya `BCA` atau `GoPay`. |
| `iconKey` | `String` | Kunci semantik ikon, bukan path aset. Lihat [ADR-013](adr/0013-bahasa-visual-dan-sistem-ikon.md). |
| `initialBalance` | `int` | Saldo saat dompet dibuat, dalam sen. Boleh nol, boleh negatif. |
| `currentBalance` | `int` | Saldo tercatat saat ini, dalam sen. Disimpan demi kecepatan, lihat catatan di bawah. |
| `isActive` | `bool` | Dompet tidak aktif tidak muncul di pemilih, tapi transaksinya tetap ada. |

`currentBalance` adalah satu-satunya nilai turunan yang **disimpan** di seluruh
model ini. Penyimpangan itu diambil sadar karena total saldo adalah angka utama
aplikasi dan tidak boleh memaksa pemindaian seluruh riwayat tiap kali layar
digambar. Alasan lengkap dan penyeimbangnya ada di
[ADR-012](adr/0012-tata-letak-penyimpanan-buku-besar.md).

Nilai turunan yang dihitung, bukan disimpan:

```
currentBalance = initialBalance
               + Σ income.amount     dengan income.walletId     = wallet.id
               − Σ expense.amount    dengan expense.walletId    = wallet.id
               + Σ transfer.amount   dengan transfer.toWalletId = wallet.id
               − Σ transfer.amount   dengan transfer.fromWalletId = wallet.id

totalBalance   = Σ wallet.currentBalance  untuk wallet.isActive
```

Rumus pertama itulah yang dipakai `recomputeWalletBalances()` untuk membuktikan
bahwa nilai tersimpan tidak melenceng. Bukti: dompet bersaldo awal Rp5.000.000
yang menerima pemasukan Rp2.615.438, mengeluarkan Rp3.068.500, dan mengirim
transfer Rp1.000.000 berakhir di Rp3.546.938 — dan angka itu harus sama persis
apakah dibaca dari `currentBalance` atau dihitung ulang dari nol.

Saldo boleh negatif. Itu keadaan nyata, bukan kesalahan, dan ditampilkan dengan
warna `expense` beserta tanda minus U+2212.

## Transaksi

`Transaction` adalah tipe tertutup (`sealed`) dengan tiga anggota. Ia tertutup
karena menambah jenis baru mengubah aturan perhitungan saldo, jadi harus
dipikirkan dan diuji, bukan diketik pemilik.

Field yang dimiliki ketiganya:

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas transaksi. |
| `date` | `DateTime` | Kapan peristiwanya terjadi, bukan kapan dicatat. |
| `amount` | `int` | Nominal dalam sen. Selalu positif; arahnya ditentukan jenisnya. |
| `note` | `String` | Catatan bebas, boleh kosong. |
| `categoryKey` | `String?` | Label pengelompokan, boleh kosong. |

### Pemasukan

`IncomeTransaction` menambah saldo satu dompet.

| Field | Tipe | Keterangan |
|---|---|---|
| `walletId` | `String` | Dompet yang bertambah. |

### Pengeluaran

`ExpenseTransaction` mengurangi saldo satu dompet, dan boleh ditautkan ke satu
pos anggaran.

| Field | Tipe | Keterangan |
|---|---|---|
| `walletId` | `String` | Dompet yang berkurang. |
| `budgetItemId` | `String?` | Pos anggaran yang ditambahi angka terpakainya. Null berarti pengeluaran di luar anggaran mana pun. |

Tautan ke pos anggaran hanya sah kalau dompet anggarannya sama dengan
`walletId`. Aturan itu ditegakkan saat pengeluaran disimpan, dan pemilih pos di
antarmuka hanya menawarkan pos yang memenuhinya.

### Transfer

`TransferTransaction` memindahkan catatan uang antar dompet. Ia tidak mengubah
total uang pemilik, hanya tempatnya.

| Field | Tipe | Keterangan |
|---|---|---|
| `fromWalletId` | `String` | Dompet yang berkurang. |
| `toWalletId` | `String` | Dompet yang bertambah. Harus berbeda dari `fromWalletId`. |

Transfer tidak pernah dihitung sebagai pemasukan maupun pengeluaran di ringkasan
mana pun. Kalau ia ikut dihitung, satu pemindahan Rp1.000.000 dari BCA ke GoPay
akan tampil sebagai pemasukan Rp1.000.000 sekaligus pengeluaran Rp1.000.000 —
dua angka yang sama-sama tidak benar.

## Anggaran

`Budget` adalah rencana pengeluaran, bukan pemesanan uang. Membuatnya tidak
pernah mengubah saldo dompet mana pun.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas anggaran. |
| `name` | `String` | Nama yang dipilih pemilik, misalnya `Belanja` atau `Rumah tangga`. |
| `walletId` | `String` | Dompet sumber. **Wajib**, dan menyaring pengeluaran mana yang terhitung. |
| `period` | `BudgetPeriod` | `weekly` atau `monthly`. |
| `startDate` | `DateTime` | Awal berlakunya periode. |
| `plannedAmount` | `int` | Nominal rencana dalam sen. |
| `items` | `List<BudgetItem>` | Pos-pos di dalamnya. Boleh kosong. |

Beberapa anggaran boleh aktif sekaligus, boleh berbagi satu dompet, dan boleh
berbeda periode. Tidak ada kewajiban menutup satu anggaran sebelum membuat yang
lain.

### Pos anggaran

`BudgetItem` adalah satu baris di dalam anggaran.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas pos. |
| `name` | `String` | Nama pos, misalnya `Ikan kembung` atau `Listrik`. |
| `plannedAmount` | `int` | Nominal rencana dalam sen. |
| `quantity` | `int?` | Jumlah barang, untuk pos yang berupa daftar belanja. |
| `unitPrice` | `int?` | Harga satuan dalam sen. |

Kalau `quantity` dan `unitPrice` terisi, `plannedAmount` dihitung dari keduanya;
kalau tidak, ia diketik langsung. Dua field itu ada supaya daftar belanja
pemilik — yang sungguhan berisi 35 item dengan harga satuan — tetap bisa dicatat
serinci sebelumnya, tanpa memerlukan domain belanja tersendiri.

Nilai turunan yang dihitung, bukan disimpan:

```
item.plannedAmount = quantity × unitPrice          bila keduanya terisi
item.spent         = Σ expense.amount
                     dengan expense.budgetItemId = item.id
                     dan    expense.walletId     = budget.walletId
item.remaining     = item.plannedAmount − item.spent
item.progress      = item.spent ÷ item.plannedAmount

budget.plannedAmount = nominal yang diketik pemilik
budget.spent         = Σ item.spent
budget.remaining     = budget.plannedAmount − budget.spent
```

Bukti: daftar belanja nyata pemilik berisi subtotal mingguan Rp576.600 yang
berulang empat kali dalam sebulan ditambah subtotal bulanan Rp762.100,
menghasilkan rencana Rp3.068.500. Di model 2.0 angka itu bukan lagi hasil rumus
pengali minggu, melainkan jumlah `plannedAmount` seluruh pos di dalam satu
anggaran bulanan.

Status pos dihitung dari `spent` dan `plannedAmount`:

```
planned         : spent = 0
partiallySpent  : 0 < spent < plannedAmount
completed       : spent = plannedAmount
overspent       : spent > plannedAmount
```

### Template anggaran

`BudgetTemplate` adalah definisi yang bisa dipakai ulang, bukan anggaran aktif.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas template. |
| `name` | `String` | Nama template. |
| `items` | `List<BudgetItem>` | Pos bawaan beserta nominal rencananya. |
| `isEnabled` | `bool` | Template nonaktif tidak ditawarkan saat membuat anggaran. |

Membuat anggaran dari template menghasilkan `Budget` mandiri: menyuntingnya
tidak mengubah templatenya, dan menyunting template tidak mengubah anggaran yang
sudah lahir darinya.

## Freelance

Domain pendukung. Ia ada karena penghasilan freelance punya satu sifat yang
tidak dimiliki pemasukan biasa: pekerjaannya selesai jauh sebelum uangnya
diterima.

### Proyek

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas proyek. |
| `name` | `String` | Nama klien atau proyek. |
| `hourlyRate` | `int` | Tarif per jam dalam sen. |
| `deductionRules` | `List<DeductionRule>` | Potongan yang berlaku untuk proyek ini. |

`DeductionRule` punya `id`, `label`, `kind` (`percentage` atau `fixedAmount`),
dan `value`. Untuk `percentage`, `value` adalah **per mil**, bukan per seratus:
pajak 2,5% ditulis `25`. Pemilihan per mil bukan gaya melainkan keharusan, sebab
tarif 2,5% tidak bisa diwakili bilangan bulat dalam satuan persen.

### Worklog

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas entri. |
| `projectId` | `String` | Proyek yang dikerjakan. |
| `date` | `DateTime` | Tanggal kerja. |
| `hours` | `int` | Jumlah jam. |
| `paymentId` | `String?` | Pembayaran yang menagihkan entri ini. Null berarti belum ditagihkan. |

`WorklogEntry` **tidak pernah** menyentuh saldo dompet mana pun. Mencatat kerja
bukan menerima uang.

### Pembayaran

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas pembayaran. |
| `projectId` | `String` | Proyek yang ditagihkan. |
| `entryIds` | `List<String>` | Entri worklog yang tercakup. |
| `expectedDate` | `DateTime` | Perkiraan tanggal diterima. |
| `walletId` | `String?` | Dompet tujuan. Terisi saat pembayaran dicatat diterima. |
| `status` | `PaymentStatus` | `pending` atau `paid`. |
| `incomeTransactionId` | `String?` | Transaksi pemasukan yang lahir saat pembayaran dicatat diterima. |

Nilai turunan yang dihitung, bukan disimpan:

```
entry.earnedAmount = entry.hours × project.hourlyRate
payment.grossPay   = Σ earnedAmount untuk seluruh entri tercakup
deduction(rule)    = grossPay × rule.value ~/ 1000   bila rule.kind = percentage
                     rule.value                       bila rule.kind = fixedAmount
payment.netPay     = grossPay − Σ deduction(rule)
```

Setiap potongan persentase selalu dihitung dari **gaji kotor**, bukan dari nilai
berjalan setelah potongan sebelumnya. Potongan tidak beranak.

Bukti dari data nyata pemilik: satu pembayaran berisi 37 jam pada tarif
Rp72.500 menghasilkan gaji kotor Rp2.682.500; pajak 2,5% memotong Rp67.062,50;
gaji bersihnya Rp2.615.437,50 yang tampil sebagai **Rp2.615.438**. Dihitung di
satuan sen:

```
grossPay  = 37 × 7.250.000       = 268.250.000 sen
pajak     = 268.250.000 × 25 ~/ 1000 =   6.706.250 sen
netPay    = 268.250.000 − 6.706.250  = 261.543.750 sen
tampil    = Rp2.615.438
```

Saat pembayaran dicatat diterima, ia membuat **tepat satu**
`IncomeTransaction` sebesar `netPay` ke dompet tujuan, menyimpan id transaksi
itu di `incomeTransactionId`, dan berubah status jadi `paid`. `incomeTransactionId`
yang sudah terisi adalah penjaga supaya pembayaran yang sama tidak bisa dicatat
dua kali.

## Invarian

Aturan berikut harus benar setiap saat, dan masing-masing punya uji unitnya
sendiri.

1. **Uang selalu `int` sen.** Tidak ada `double` di jalur nominal mana pun.
2. **Saldo tersimpan sama dengan saldo turunan.** `wallet.currentBalance` harus
   identik dengan hasil `recomputeWalletBalances()` untuk dompet itu.
3. **Transfer tidak mengubah total.** Sebelum dan sesudah sebuah transfer,
   `totalBalance` seluruh dompet bernilai sama.
4. **Anggaran tidak menyentuh saldo.** Membuat, menyunting, atau menghapus
   `Budget`, `BudgetItem`, maupun `BudgetTemplate` tidak mengubah saldo dompet
   mana pun.
5. **Worklog tidak menyentuh saldo.** Mencatat, menyunting, atau menghapus
   `WorklogEntry` tidak mengubah saldo dompet mana pun.
6. **Pembayaran menghasilkan tepat satu transaksi.** Sebuah `FreelancePayment`
   yang `paid` punya tepat satu `incomeTransactionId`, dan tidak bisa dicatat
   diterima untuk kedua kalinya.
7. **Nominal transaksi selalu positif.** Arah uang ditentukan jenis transaksi,
   bukan tanda nominalnya.
8. **Transfer butuh dua dompet berbeda.** `fromWalletId` tidak boleh sama dengan
   `toWalletId`.
9. **Pengeluaran hanya menambah `spent` anggaran yang sedompet.** Pengeluaran
   dari dompet lain tidak terhitung, meski tertaut ke pos anggaran itu.
10. **Saldo boleh negatif.** Ini keadaan nyata, bukan kondisi kesalahan, dan
    tidak boleh menolak penyimpanan.

## Nilai terkonfirmasi

Nilai berikut sudah dipastikan pemilik dan tidak perlu ditanyakan ulang.

| Nilai | Angka | Sumber |
|---|---|---|
| Tarif freelance per jam | Rp72.500 | Dikonfirmasi pemilik saat Saldough 1.0; tarif ini tidak pernah tercatat di spreadsheet |
| Potongan pajak freelance | 2,5%, ditulis `25` per mil | Konsisten di seluruh riwayat pembayaran |
| Bahasa dasar antarmuka | Indonesia, tambahan Inggris | Preferensi pemilik |

Nilai berikut **belum** ada dan harus diisi pemilik saat aplikasi pertama kali
dipakai, karena Saldough 1.0 tidak pernah mencatatnya sama sekali:

- Daftar dompet beserta saldo awalnya. Tidak ada satu pun saldo dompet yang
  tercatat di data 1.0, jadi tidak ada yang bisa dimigrasikan.
- Daftar kategori transaksi.

## Langkah berikutnya

Lanjutkan ke [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) untuk melihat
bagaimana entitas di atas dipetakan ke lapisan dan folder, atau ke
[ADR-011](adr/0011-model-domain-dompet-transaksi-anggaran.md) untuk alasan di
balik bentuk modelnya.
