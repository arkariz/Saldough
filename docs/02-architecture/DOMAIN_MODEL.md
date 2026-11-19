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

"Sen" berarti seperseratus satuan utama **mata uang aktif**. Aplikasi memakai
satu mata uang untuk seluruh data, dipilih pengguna (bawaan Rupiah); mengganti
mata uang tidak mengonversi angka, hanya simbol dan formatnya
([ADR-025](adr/0025-satu-mata-uang-per-aplikasi.md)). Contoh di bawah memakai
Rupiah.

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

Sebelas entitas, dikelompokkan jadi tiga lingkaran: inti, rencana, dan
pendukung.

| Entitas | Lingkaran | Peran |
|---|---|---|
| `Wallet` | Inti | Tempat uang tercatat berada |
| `Transaction` | Inti | Peristiwa yang terjadi pada uang |
| `Budget` | Rencana | Rencana pengeluaran satu periode |
| `BudgetItem` | Rencana | Satu baris di dalam rencana itu |
| `BudgetTemplate` | Rencana | Definisi yang bisa dipakai ulang |
| `RecurringRule` | Rencana | Transaksi yang dijadwalkan berulang ([ADR-035](adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)) |
| `SavingsGoal` | Rencana | Tujuan tabungan yang memiliki satu dompet sendiri ([ADR-048](adr/0048-tujuan-tabungan.md)) |
| `FreelanceProject` | Pendukung | Klien beserta tarif dan potongannya |
| `WorklogEntry` | Pendukung | Kerja yang sudah selesai |
| `FreelancePayment` | Pendukung | Tagihan yang menunggu dibayar |
| ~~`FreelanceTemplate`~~ | Pendukung | Deprecated 26 Sep 2026, tidak dikerjakan |

Tidak ada entitas untuk saldo turunan, ringkasan bulanan, `spent`, `remaining`,
`progress`, `status`, kemunculan rutin, uang nganggur, perkiraan saldo,
kemajuan tujuan, perkiraan tanggal tercapai, maupun Total aset dan lapisannya.
Semuanya dihitung ulang saat diakses.

## Dompet

`Wallet` menyatakan di mana uang pemilik tercatat berada. Ia tidak terhubung ke
lembaga keuangan mana pun; `BCA Rp5.000.000` berarti "pemilik menyatakan
tercatat ada Rp5.000.000 di sana".

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas dompet. |
| `name` | `String` | Nama yang dipilih pemilik, misalnya `BCA` atau `GoPay`. |
| `iconKey` | `String` | Kunci semantik ikon, bukan path aset. Lihat [ADR-015](adr/0015-adopsi-bahasa-visual-pixel-kas.md). **Hanya tampilan:** dompet tidak punya jenis, dan ikon tidak memberi kemampuan apa pun (keputusan pemilik 17 Nov 2026, WEALTH_ASSETS keputusan 11). Peran dompet tabungan hanya berasal dari tujuan yang memilikinya (ADR-048 Revisi 1): dompet milik tujuan dibuat otomatis bersama tujuannya, lihat [Tujuan tabungan](#tujuan-tabungan). |
| `colorKey` | `String?` | Warna latar kartu pilihan pengguna (kunci warna kategori design system, mis. `teal`); kosong = bawaan. **Hanya tampilan**, tanpa arti domain (T-30.15). |
| `createdAt` | `DateTime?` | Saat dompet dibuat (ADR-050 §3.6, Fase 32); diisi `WalletBloc` saat membuat dompet. **Tidak memengaruhi saldo.** Dompet dari sebelum Fase 32 `null` dan oleh Riwayat kekayaan dianggap ada sejak transaksi tertuanya. Field tambahan tanpa naik skema (seperti `colorKey`); tidak ikut ekspor spreadsheet, ikut cadangan. |
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
               ± Σ adjustment.amount dengan adjustment.walletId = wallet.id
                                     (+ increase, − decrease; ADR-047)

totalBalance   = Σ wallet.currentBalance  untuk wallet.isActive
```

Sejak ADR-050, angka teratas tab Dompet dan Beranda adalah **Total aset**,
yang memecah `totalBalance` per lapis; lihat [Total aset](#total-aset).

Rumus pertama itulah yang dipakai `recomputeWalletBalances()` untuk membuktikan
bahwa nilai tersimpan tidak melenceng. Bukti: dompet bersaldo awal Rp5.000.000
yang menerima pemasukan Rp2.615.438, mengeluarkan Rp3.068.500, dan mengirim
transfer Rp1.000.000 berakhir di Rp3.546.938 — dan angka itu harus sama persis
apakah dibaca dari `currentBalance` atau dihitung ulang dari nol.

Saldo boleh negatif. Itu keadaan nyata, bukan kesalahan, dan ditampilkan dengan
warna `expense` beserta tanda minus U+2212.

## Transaksi

`Transaction` adalah tipe tertutup (`sealed`) dengan empat anggota. Ia tertutup
karena menambah jenis baru mengubah aturan perhitungan saldo, jadi harus
dipikirkan dan diuji, bukan diketik pemilik.

Field yang dimiliki keempatnya:

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas transaksi. |
| `date` | `DateTime` | Kapan peristiwanya terjadi, bukan kapan dicatat. |
| `amount` | `int` | Nominal dalam sen. Selalu positif; arahnya ditentukan jenisnya. |
| `note` | `String` | Catatan bebas, boleh kosong. |
| `recurrence` | `RecurrenceLink?` | Kemunculan rutin yang dipenuhi transaksi ini: `ruleId`, `occurrenceDate`, `linkedBy` (`user`/`auto`). Unik per pasangan `ruleId` + `occurrenceDate` ([ADR-035](adr/0035-transaksi-rutin-rencana-dan-perkiraan.md) §3.2). Null untuk transaksi biasa. |
| `sourceIconId` | `String?` | Ikon notifikasi asal transaksi (Catat dari notifikasi, [ADR-032](adr/0032-catat-dari-notifikasi.md) §3.10): hash isi PNG di penyimpanan ikon `source_icon/<id>`. Hanya tampilan; tidak memengaruhi perhitungan apa pun. Null untuk transaksi manual. |

Pemasukan dan pengeluaran juga punya `categoryId: String?` (kategori, boleh
kosong; lihat bagian Kategori di bawah). Transfer tidak berkategori
([ADR-026](adr/0026-sistem-kategori.md)).

### Pemasukan

`IncomeTransaction` menambah saldo satu dompet.

| Field | Tipe | Keterangan |
|---|---|---|
| `walletId` | `String` | Dompet yang bertambah. |
| `categoryId` | `String?` | Kategori pemasukan, boleh kosong. |
| `freelancePaymentId` | `String?` | Pembayaran freelance yang melahirkan transaksi ini. Kalau terisi, transaksi hanya bisa diubah lewat pembayarannya ([ADR-019](adr/0019-tarif-di-entri-dan-transaksi-milik-pembayaran.md)). |

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

Tautan juga hanya sah kalau **tanggal transaksi berada di dalam periode
anggaran** (`budget.startDate ≤ date < budget.endDate`, keputusan KT-1). Pemilih
pos hanya menawarkan pos anggaran yang periodenya mencakup tanggal transaksi;
mengubah tanggal ke luar periode melepas tautannya. Karena itu `spent` sebuah
anggaran cukup dihitung dari dokumen bulan yang disentuh periodenya, tidak
dari seluruh riwayat (NFR-PERF-002).

**Pengecualian transaksi tertaut rutin (ADR-038 §3.5, 10 Okt 2026).** Untuk
transaksi yang tertaut kemunculan rutin dengan selisih tanggal paling lama
7 hari, aturan di atas memakai **tanggal periode** (`occurrenceDate`), bukan
`date`. Cicilan untuk kemunculan 25 Okt yang dibayar 24 Okt terhitung di pos
anggaran periode 25 Okt, tempat ia direncanakan. Karena itu `spent` boleh
membaca satu dokumen bulan tetangga.

### Transfer

`TransferTransaction` memindahkan catatan uang antar dompet. Ia tidak mengubah
total uang pemilik, hanya tempatnya.

| Field | Tipe | Keterangan |
|---|---|---|
| `fromWalletId` | `String` | Dompet yang berkurang. |
| `toWalletId` | `String` | Dompet yang bertambah. Harus berbeda dari `fromWalletId`. |
| `budgetItemId` | `String?` | Pos anggaran yang ditambahi angka terpakainya, untuk pos yang memang berupa rencana pemindahan dana. Null berarti transfer di luar anggaran mana pun. |

Transfer bisa ditautkan ke pos anggaran karena sebagian rencana pengeluaran
memang berbentuk pemindahan, bukan belanja. Anggaran `Tabungan` dari dompet
`BCA` dipenuhi dengan mentransfer ke dompet `Tabungan`, bukan dengan
mengeluarkan uang. Yang menentukan apakah transfer itu terhitung adalah
`fromWalletId` — uang keluar dari dompet anggaran — bukan `walletId` seperti
pada pengeluaran.

Transfer tidak pernah dihitung sebagai pemasukan maupun pengeluaran di ringkasan
mana pun. Kalau ia ikut dihitung, satu pemindahan Rp1.000.000 dari BCA ke GoPay
akan tampil sebagai pemasukan Rp1.000.000 sekaligus pengeluaran Rp1.000.000 —
dua angka yang sama-sama tidak benar.

### Penyesuaian saldo

`BalanceAdjustmentTransaction` mencatat selisih saat pemilik mengubah saldo
dompet di Ubah dompet ([ADR-047](adr/0047-penyesuaian-saldo.md)). Ia mengubah
saldo satu dompet, tetapi **bukan pemasukan dan bukan pengeluaran**: bernilai 0
di setiap hitungan Arus, Analisis, anggaran, Rencana, dan Buku Periode.

| Field | Tipe | Keterangan |
|---|---|---|
| `walletId` | `String` | Dompet yang saldonya disesuaikan. |
| `direction` | `AdjustmentDirection` | `increase` menambah saldo, `decrease` menguranginya. `amount` tetap positif. |

Tanpa kategori, pos anggaran, rutin, atau ikon sumber. Tanggalnya selalu hari
pencatatan, jadi saldo hari-hari sebelumnya tidak bergeser. Hanya lahir dari
Ubah dompet; bisa dihapus (saldo kembali), tidak bisa disunting. Saldo awal
(`initialBalance`) hanya diisi saat dompet dibuat.

### Transaksi investasi

`InvestmentTransaction` mencatat pembelian atau penjualan instrumen dari satu
dompet lewat CATAT ([ADR-049](adr/0049-investasi-manual.md)). Beli mengurangi
saldo dompet, jual menambahnya, tetapi **bukan pemasukan dan bukan
pengeluaran**: bernilai 0 di Arus, Analisis, anggaran, dan Rencana, sama
seperti penyesuaian saldo.

| Field | Tipe | Keterangan |
|---|---|---|
| `walletId` | `String` | Dompet sumber (beli) atau tujuan (jual); bukan dompet milik tujuan tabungan. |
| `instrumentId` | `String` | Instrumen yang dibeli atau dijual. |
| `side` | `InvestmentSide` | `buy` atau `sell`. |
| `quantity` | `int` | Jumlah berskala ×10.000 (lot, unit, gram), atau nominal obligasi dalam sen. |

`amount` = total dibayar termasuk biaya (beli) atau hasil bersih sesudah biaya
(jual). Tanpa kategori, pos anggaran, atau rutin. Dividen dan kupon bukan
transaksi investasi: dicatat sebagai pemasukan berkategori Investasi.

## Instrumen investasi

`Instrument` (`shared/investment`, ADR-049) adalah satu kepemilikan: nama,
jenis (`stock`, `mutualFund`, `bond`, `gold`, `other`), kode opsional, dan
kepemilikan awal opsional (`OpeningHolding`: tanggal, jumlah, nilai perolehan,
tanpa dompet). Satuan diturunkan dari jenis: saham lot (1 lot = 100 lembar),
reksa dana unit, emas gram, obligasi nominal, lainnya unit.

`InstrumentValuation` menyimpan **harga per satuan harga** pada satu tanggal
(sen per lembar/unit/gram; obligasi basis poin ×100 dari nominal), satu per
instrumen per tanggal, dengan sumber `manual` atau `sheet`.

Posisi tidak disimpan: `InstrumentPosition.replay` memutar ulang kepemilikan
awal dan transaksi investasi urut tanggal lalu `id`, memakai **rata-rata
tertimbang**. Jual: `bagian = round(nilai perolehan × jumlah jual ÷ jumlah)`
(jual habis memakai seluruh nilai perolehan), `untung/rugi terwujud += hasil −
bagian`. Nilai pasar = jumlah × harga valuasi terakhir, atau nilai perolehan
bila belum pernah divaluasi; ditandai kedaluwarsa sesudah 30 hari. Aktif bila
jumlah > 0 atau belum ada aktivitas; Selesai bila jumlah 0 sesudah ada
aktivitas.

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
| `endDate` | `DateTime?` | Akhir periode (eksklusif) bila berbeda dari `period.endFrom(startDate)`. Hanya diisi untuk menyelaraskan anggaran rutin ke periode peralihan ([ADR-038](adr/0038-periode-keuangan-berriwayat-dan-peralihan.md) §3.3). Null pada hampir semua anggaran. |
| `items` | `List<BudgetItem>` | Pos-pos di dalamnya. **Minimal satu** saat dibuat lewat formulir. |
| `isArchived` | `bool` | Anggaran yang diarsipkan tidak muncul di daftar aktif, tetapi transaksi yang tertaut padanya tetap ada dan tetap terhitung di riwayat. |

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
| `unitPrice` | `int?` | Harga satuan dalam sen. Hanya untuk pos pengeluaran. |
| `kind` | `BudgetItemKind` | `expense` (rencana belanja) atau `transfer` (rencana pemindahan dana). Bawaan `expense`. |
| `targetWalletId` | `String?` | Dompet tujuan. **Wajib** untuk pos transfer, dan berbeda dari dompet anggaran; `null` untuk pos pengeluaran. |

Kalau `quantity` dan `unitPrice` terisi, `plannedAmount` dihitung dari keduanya;
kalau tidak, ia diketik langsung. Dua field itu ada supaya daftar belanja
pemilik — yang sungguhan berisi 35 item dengan harga satuan — tetap bisa dicatat
serinci sebelumnya, tanpa memerlukan domain belanja tersendiri.

Pos berjenis ([ADR-018](adr/0018-jenis-pos-anggaran.md)). Transaksi yang
tertaut ke pos yang berbeda jenis tidak terhitung, begitu pula transfer yang
dompet tujuannya bukan `targetWalletId` pos itu. Pos transfer selalu diketik
langsung, tanpa jumlah × harga satuan.

Nilai turunan yang dihitung, bukan disimpan:

```
item.plannedAmount = quantity × unitPrice          bila keduanya terisi
item.spent         = bila item.kind = expense:
                       Σ expense.amount
                       dengan expense.budgetItemId = item.id
                       dan    expense.walletId     = budget.walletId
                       dan    expense.date di dalam periode anggaran
                     bila item.kind = transfer:
                       Σ transfer.amount
                       dengan transfer.budgetItemId = item.id
                       dan    transfer.fromWalletId = budget.walletId
                       dan    transfer.toWalletId   = item.targetWalletId
                       dan    transfer.date di dalam periode anggaran
item.remaining     = item.plannedAmount − item.spent
item.progress      = item.spent ÷ item.plannedAmount

budget.plannedAmount = Σ item.plannedAmount
budget.spent         = Σ item.spent
budget.remaining     = budget.plannedAmount − budget.spent
```

Bukti: daftar belanja nyata pemilik berisi subtotal mingguan Rp576.600 yang
berulang empat kali dalam sebulan ditambah subtotal bulanan Rp762.100,
menghasilkan rencana Rp3.068.500. Di model 2.0 angka itu bukan lagi hasil rumus
pengali minggu, melainkan jumlah `plannedAmount` seluruh pos di dalam satu
anggaran bulanan.

Nominal rencana anggaran **tidak diketik terpisah** dari posnya
([ADR-017](adr/0017-rencana-anggaran-adalah-jumlah-pos.md)). Transaksi hanya
bisa ditautkan ke pos, jadi rencana yang tidak terbagi ke pos tidak pernah bisa
dilacak. Ruang cadangan dibuat sebagai pos biasa, misalnya `Lain-lain`.

Status anggaran dihitung dari `isArchived` dan periodenya, bukan disimpan:

```
aktif    : bukan isArchived, dan periodenya belum lewat
selesai  : bukan isArchived, dan periodenya sudah lewat
nonaktif : isArchived
```

Ketiganya adalah penyaring di layar Anggaran. Hanya `nonaktif` yang butuh
penanda tersimpan; dua lainnya turunan dari tanggal, sehingga sebuah anggaran
berpindah dari `aktif` ke `selesai` sendirinya tanpa ada yang menuliskannya.

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
| `schedule` | `BudgetSchedule?` | Anggaran rutin ([ADR-036](adr/0036-anggaran-rutin-dan-perkiraan-ke-depan.md)): `walletId`, `period`, `anchorDate` (bulanan tanggal 1–28), `isActive`. Template berjadwal melahirkan anggaran tiap periode. |

Membuat anggaran dari template menghasilkan `Budget` mandiri: menyuntingnya
tidak mengubah templatenya, dan menyunting template tidak mengubah anggaran yang
sudah lahir darinya. Template tidak menyimpan dompet maupun periode; keduanya
dipilih saat anggaran dibuat. Setiap pos mendapat id baru, supaya transaksi
yang tertaut ke pos satu anggaran tidak ikut terhitung di anggaran lain dari
template yang sama. Kalau dompet tujuan sebuah pos transfer sama dengan dompet
anggaran yang dipilih, pemilik diminta menyesuaikan dompet tujuannya sebelum
anggaran dibuat.

Anggaran yang lahir dari template berjadwal membawa `Budget.templateId`, dan
setiap posnya `BudgetItem.templateItemId` (id pos template), kunci yang stabil
antarperiode untuk dialog lingkup dan tautan rutin ke pos (ADR-036 §3.3–3.4).

## Transaksi rutin

`RecurringRule` adalah **rencana** transaksi yang berulang, bukan transaksi.
Membuat, mengubah, menjeda, atau menghapusnya tidak pernah mengubah saldo.
Keputusannya di [ADR-035](adr/0035-transaksi-rutin-rencana-dan-perkiraan.md), perilakunya di
[RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md).

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas rutin. |
| `kind` | `TransactionKind` | Pemasukan, pengeluaran, atau transfer. |
| `amount` | `int` | Nominal dalam sen. Untuk `estimated`, perkiraannya nominal tercatat terakhir. |
| `amountMode` | `fixed` / `estimated` | Nominal tetap atau kira-kira (dikonfirmasi tiap kali dicatat). |
| `walletId` / `fromWalletId`, `toWalletId` | `String` | Seperti transaksi. |
| `categoryId` | `String?` | Pemasukan dan pengeluaran saja. |
| `note` | `String` | |
| `schedule` | `RecurrenceSchedule` | `frequency` (`weekly`/`monthly`/`yearly`), `interval`, `anchorDate`, `anchorDay`. |
| `end` | `RecurrenceEnd` | `none`, `untilDate`, atau `count`. |
| `paymentMode` | `autoDebit` / `manual` / null | Pengeluaran dan transfer; null diperlakukan `manual`. |
| `remindDaysBefore` | `int` | Pengingat H−n untuk `manual`, bawaan 1. |
| `autoRecord` | `bool` | Catat otomatis saat jatuh tempo (R3); hanya untuk `fixed`. |
| `skippedDates` | `Set<DateTime>` | Kemunculan yang dilewati. Satu-satunya status kemunculan yang disimpan. |
| `isPaused` | `bool` | Dijeda: tidak ada kemunculan menunggu maupun perkiraan. |

Kemunculan dihitung dari `schedule`. Hari patokan bulanan dijepit ke akhir
bulan yang lebih pendek tetapi tidak bergeser: patokan 31 menjadi 28/29 Feb
lalu kembali 31 Mar. Status kemunculan diturunkan:

```
tercatat  : ada transaksi dengan recurrence (ruleId, tanggal)
dilewati  : tanggal ada di skippedDates
menunggu  : tanggal ≤ hari ini, bukan keduanya, dan kemunculan terbaru yang sudah tiba
terlewat  : seperti menunggu, tetapi bukan yang terbaru
terjadwal : tanggal > hari ini
```

**Uang nganggur** dan **perkiraan saldo** adalah hitungan murni dari rutin,
anggaran, dan transaksi. Rumusnya hanya di
[RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md)
§7.2, §7.2a, dan §7.3–7.5, tidak disalin ke sini. Uang nganggur adalah arus
satu bulan keuangan, **bukan saldo**.

**Anggaran rutin (R2)** adalah `BudgetTemplate` yang punya `schedule?`
(`walletId`, `period`, `anchorDate`, `isActive`). Anggaran yang lahir darinya
membawa `templateId`, dan posnya membawa `templateItemId` (ADR-035 §3.9).

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
| `hourlyRate` | `int` | Tarif per jam dalam sen, disalin dari proyek saat entri dicatat ([ADR-019](adr/0019-tarif-di-entri-dan-transaksi-milik-pembayaran.md)). |
| `note` | `String?` | Catatan bebas tentang apa yang dikerjakan. |
| `paymentId` | `String?` | Pembayaran yang menagihkan entri ini. Null berarti belum ditagihkan. |

`WorklogEntry` **tidak pernah** menyentuh saldo dompet mana pun. Mencatat kerja
bukan menerima uang.

Tanggal pembayaran, dompet tujuan, dan status pembayaran **tidak** disimpan di
entri. Ketiganya diturunkan lewat `paymentId`, sehingga satu entri tidak pernah
bisa menyatakan status yang berbeda dari pembayaran yang menagihkannya.

Tarif per jam **disimpan** di entri, bukan diturunkan dari proyek. Mengubah
tarif proyek hanya berlaku untuk entri berikutnya, sehingga kerja yang sudah
selesai tidak berubah nilainya ([ADR-019](adr/0019-tarif-di-entri-dan-transaksi-milik-pembayaran.md)).
Entri yang sudah masuk pembayaran tidak bisa disunting atau dihapus.

### Pembayaran

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas pembayaran. |
| `projectId` | `String` | Proyek yang ditagihkan. |
| `entryIds` | `List<String>` | Entri worklog yang tercakup, semuanya dari proyek yang sama. |
| `deductionRules` | `List<DeductionRule>` | Potongan, disalin dari proyek saat pembayaran dibuat ([ADR-019](adr/0019-tarif-di-entri-dan-transaksi-milik-pembayaran.md)). |
| `expectedDate` | `DateTime` | Perkiraan tanggal diterima. |
| `walletId` | `String?` | Dompet tujuan. Terisi saat pembayaran dicatat diterima. |
| `status` | `PaymentStatus` | `pending` atau `paid`. |
| `incomeTransactionId` | `String?` | Transaksi pemasukan yang lahir saat pembayaran dicatat diterima. |
| `receivedDate` | `DateTime?` | Tanggal uangnya diterima, sama dengan tanggal transaksinya. Terisi bersama `incomeTransactionId`. |

Nilai turunan yang dihitung, bukan disimpan:

```
entry.earnedAmount = entry.hours × entry.hourlyRate
payment.grossPay   = Σ earnedAmount untuk seluruh entri tercakup
deduction(rule)    = grossPay × rule.value ~/ 1000   bila rule.kind = percentage
                     (rule dari payment.deductionRules)
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
itu di `incomeTransactionId`, dan berubah status jadi `paid`. Field itu, begitu
terisi, jadi penjaga supaya pembayaran yang sama tidak bisa dicatat dua kali.

Id transaksi itu diturunkan dari id pembayaran (`freelance-<paymentId>`), dan
transaksinya ditulis lebih dulu. Kalau penulisan pembayaran gagal di tengah,
mencatat ulang menimpa transaksi yang sama, bukan membuat yang kedua.
Transaksinya tidak bisa disunting atau dihapus dari tab Riwayat; pembayaran
yang sudah diterima punya aksi **Batalkan penerimaan** yang mengembalikannya ke
`pending` lebih dulu, baru menghapus transaksinya.

Pembayaran yang masih `pending` boleh diubah tanggal perkiraannya, atau dihapus
supaya entrinya kembali belum ditagihkan. Proyek hanya bisa dihapus selama
belum punya entri worklog.

### Template freelance (deprecated)

*(Deprecated 26 Sep 2026 atas keputusan pemilik; tidak dikerjakan.)* Rancangan di
bawah disimpan sebagai catatan sejarah; jangan membuat entitas ini.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas template. |
| `name` | `String` | Nama klien atau proyek. |
| `hourlyRate` | `int` | Tarif per jam dalam sen. |
| `deductionRules` | `List<DeductionRule>` | Potongan bawaan. |
| `defaultWalletId` | `String?` | Dompet tujuan bawaan untuk pembayarannya. |
| `paymentSchedule` | `PaymentSchedule` | Jadwal penagihan bawaan. |
| `isEnabled` | `bool` | Template nonaktif tidak ditawarkan saat membuat proyek. |

Hubungannya dengan `FreelanceProject` sama persis dengan hubungan
`BudgetTemplate` dengan `Budget`: template adalah **definisi**, proyek adalah
**salinan mandiri**. Menyunting template tidak pernah mengubah proyek yang sudah
dibuat darinya, dan membuat atau menyunting template tidak pernah menyentuh
saldo dompet mana pun.

## Tujuan tabungan

`SavingsGoal` ([ADR-048](adr/0048-tujuan-tabungan.md), Revisi 1) adalah rencana
mengumpulkan sejumlah uang, mis. "Dana darurat Rp20 jt". Ia **rencana, bukan
pemesanan uang** (aturan 5): tujuan sendiri tidak pernah membuat transaksi dan
tidak mengubah saldo dompet mana pun.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas tujuan. |
| `name` | `String` | Nama pilihan pemilik; data pengguna. Disalin ke dompetnya. |
| `targetAmount` | `int` | Target dalam sen, > 0. |
| `iconKey` | `String` | Ikon tujuan; disalin ke dompetnya. |
| `walletId` | `String` | Dompet milik tujuan (wajib, tepat satu). |
| `createdAt` | `DateTime` | Saat dibuat; awal riwayat untuk perkiraan. |
| `status` | `SavingsGoalStatus` | `active`, `completed`, atau `archived`. |
| `targetDate` | `DateTime?` | Target tanggal; hanya penanda. |
| `description` | `String?` | Keterangan bebas. |
| `completedAt` | `DateTime?` | Saat pertama tercapai. |

**Dompet milik tujuan.** `CreateSavingsGoal` membuat satu dompet bernama dan
berikon sama dengan tujuannya; kolom opsional "Sudah terkumpul" menjadi
`initialBalance` dompet itu (saldo awal, bukan transaksi). Dompet ini
**hanya menerima dan mengirim transfer**: `RecordTransaction` menolak
pemasukan dan pengeluaran ber-`walletId` dompet tujuan (`ValidationFailure`
`goalWalletTransferOnly`), sedangkan penyesuaian saldo tetap boleh. Ia tidak
tampil di grid tab Dompet, tidak bisa dihapus dari Dompet, dan ikut terhapus
bersama semua transaksinya saat tujuannya dihapus (§8.2).

Nilai turunan:

```
collected  = wallet(goal.walletId).currentBalance
remaining  = max(0, targetAmount − collected)
percent    = collected ≤ 0 ? 0 : floor(collected × 100 ÷ targetAmount)  (boleh > 100)
reached    = collected ≥ targetAmount
```

`active` menjadi `completed` saat `reached`, lewat `SyncSavingsGoalStatus`
yang dipicu `LedgerChanges`. **Completed tidak kembali ke Active otomatis**
bila saldo turun; pengguna bisa mengaktifkannya lagi, tunduk batas Gratis
(2 tujuan Active, `EntitlementLimits.freeSavingsGoals`).

**Perkiraan tanggal tercapai (Plus, ADR-048 §3.6).** `SavingsGoalEstimate`:

```
periode   = paling banyak 3 periode keuangan lengkap terakhir yang berakhir
            sesudah goal.createdAt
laju      = Σ netto dompet tujuan di periode itu ÷ jumlah periode
            netto = pemasukan + transfer masuk − pengeluaran − transfer keluar
            (penyesuaian saldo = 0; anggota periode lewat periodDateOf)
tanggal   = awal (periode berjalan + ceil(remaining ÷ laju) periode)
skenario  = laju (atau 0 bila ≤ 0) + rata-rata uang nganggur periode lengkap
            terakhir (port IdleMoneyAverage, dihitung features/plan)
```

Tanpa periode lengkap atau laju ≤ 0: "Belum bisa diperkirakan". Uang nganggur
≤ 0 menyembunyikan skenario. Perkiraan dengan laju sesudah `targetDate`
memberi baris "Perkiraan melewati target tanggal".

## Total aset

`WealthLayers` ([ADR-050](adr/0050-total-aset-berlapis.md),
`shared/wealth`) memecah uang tercatat ke tiga lapis. Setiap dompet aktif masuk
**tepat satu** lapis, jadi tidak ada hitung ganda:

```
dompet     = Σ currentBalance dompet aktif yang bukan milik tujuan
tabungan   = Σ currentBalance dompet aktif milik tujuan
investasi  = Σ nilai pasar instrumen aktif (Fase 31; 0 sampai ada)
totalAset  = dompet + tabungan + investasi
```

Lapis negatif (mis. kartu) tetap dijumlah apa adanya; batang proporsi hanya
menggambar bagian positif. Nama **Kekayaan bersih** baru dipakai sesudah utang
tercatat (B-48, B-59).

### Riwayat kekayaan

`WealthHistory` (`shared/wealth/domain/wealth_history.dart`, ADR-050 §3.6,
Fase 32) menghitung Total aset **pada tanggal mana pun** tanpa menyimpan
apa pun: murni, dari dompet, transaksi, instrumen, dan valuasi saat ini.

```
dompet(d)     = initialBalance + efek transaksi bertanggal ≤ d   (rumus CalculateWalletBalance)
investasi(d)  = Σ jumlah(d) × valuasi terakhir ≤ d               (InstrumentSummary.of(asOf: d))
totalAset(d)  = Σ dompet(d) + investasi(d)
```

- Hanya dompet yang **aktif sekarang** dihitung, mulai dari `createdAt` atau,
  bila `null`, dari transaksi tertuanya. Mengarsipkan dompet tidak membuat
  riwayat melompat.
- Titik "kedaluwarsa" bila ada instrumen yang dipegang dengan valuasi terakhir
  lebih tua dari 30 hari pada tanggal itu (atau belum pernah divaluasi).
- **Pecahan perubahan** (`change(dari, ke)`) memisah selisih Total aset menjadi
  empat golongan yang **berjumlah tepat** selisihnya (invarian, diuji untuk
  semua pasangan tanggal):

| Golongan | Isi |
|---|---|
| Arus | Pemasukan − pengeluaran, ditambah transfer ke/dari dompet yang tidak dihitung. Transfer antar dompet yang sama-sama dihitung saling meniadakan. |
| Nilai investasi | Perubahan nilai instrumen + uang dompet yang masuk/keluar lewat beli/jual − nilai perolehan kepemilikan awal. Bukan pemasukan. |
| Penyesuaian | Σ penyesuaian saldo (ADR-047). |
| Pencatatan awal | `initialBalance` dompet yang mulai dihitung pada periode itu, saldo hasil transaksi mundur sebelum periode, dan nilai perolehan kepemilikan awal yang masuk pada periode itu. |

Gratis hanya dihitung untuk `freeAnalysisPeriods` periode terakhir; Plus
seluruhnya. Tidak ada proyeksi atau janji imbal hasil.

## Periode keuangan

Bukan entitas tersimpan selain pengaturannya. Detail di
[ADR-038](adr/0038-periode-keuangan-berriwayat-dan-peralihan.md) dan
[FINANCIAL_PERIOD.md](../01-product/features/FINANCIAL_PERIOD.md).

| Konsep | Kode | Keterangan |
|---|---|---|
| Jadwal awal bulan | `FinancialMonthSchedule` (`settings/financial_month_schedule`) | Daftar `(effectiveFrom, startDay)`, `startDay` 1–28 atau hari terakhir bulan. Periode yang sudah selesai tidak pernah dipotong ulang. |
| Periode | `financialPeriodOf(date, schedule)` → `FinancialPeriod(start, end, isTransition)` | `start ≤ d < end`. Satu periode peralihan (13–46 hari) terbentuk saat awal bulan diubah. |
| Tanggal periode transaksi | `periodDateOf(transaction)` | `recurrence.occurrenceDate` bila tertaut kemunculan rutin dan selisihnya ≤ 7 hari, selain itu `date`. Dipakai untuk keanggotaan periode dan pos anggaran (KT-1); saldo dan partisi tetap memakai `date`. |

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
5. **Worklog tidak menyentuh saldo.** Mencatat,
   menyunting, atau menghapus `WorklogEntry` tidak
   mengubah saldo dompet mana pun.
6. **Pembayaran menghasilkan tepat satu transaksi.** Sebuah `FreelancePayment`
   yang `paid` punya tepat satu `incomeTransactionId`, dan tidak bisa dicatat
   diterima untuk kedua kalinya.
7. **Nominal transaksi selalu positif.** Arah uang ditentukan jenis transaksi,
   bukan tanda nominalnya.
8. **Transfer butuh dua dompet berbeda.** `fromWalletId` tidak boleh sama dengan
   `toWalletId`.
9. **Transaksi hanya menambah `spent` anggaran yang sedompet.** Pengeluaran
   dicocokkan lewat `walletId`, transfer lewat `fromWalletId`. Transaksi dari
   dompet lain tidak terhitung, meski tertaut ke pos anggaran itu.
10. **Satu transaksi menaikkan paling banyak satu pos anggaran.** Baik
    pengeluaran maupun transfer hanya punya satu `budgetItemId`, sehingga satu
    peristiwa tidak pernah terhitung di dua anggaran sekaligus.
11. **Transfer yang tertaut pos anggaran tetap tidak mengubah total saldo.**
    Menautkannya ke anggaran hanya memengaruhi angka rencana, bukan uangnya.
12. **Saldo boleh negatif.** Ini keadaan nyata, bukan kondisi kesalahan, dan
    tidak boleh menolak penyimpanan.
13. **Transaksi hanya menambah `spent` anggaran yang periodenya mencakup
    tanggalnya.** Transaksi tertaut yang bertanggal di luar periode (data
    sebelum keputusan KT-1) tidak terhitung.
14. **Rutin tidak menyentuh saldo.** Membuat, mengubah, menjeda, atau menghapus
    `RecurringRule`, juga melahirkan anggaran rutin, tidak mengubah saldo
    dompet mana pun. Hanya transaksi tercatat yang mengubahnya.
15. **Satu kemunculan menghasilkan paling banyak satu transaksi.** Pasangan
    `recurrence.ruleId` + `recurrence.occurrenceDate` unik di seluruh buku
    besar.
16. **Transfer rutin tidak mengubah perkiraan saldo total**, hanya perkiraan
    per dompet.
17. **Pos anggaran dengan rutin tertaut tidak dihitung ganda** di uang
    nganggur maupun perkiraan: `keluar_pos = max(sisa_pos, rutin tertaut yang
    belum tercatat)`.
18. **Penyesuaian saldo bernilai 0 di Arus.** `BalanceAdjustmentTransaction`
    mengubah saldo dompetnya, tetapi tidak pernah terhitung sebagai
    pemasukan, pengeluaran, `spent` anggaran, uang nganggur, maupun laju
    tujuan.
18a. **Transaksi investasi bernilai 0 di Arus**, dan posisi instrumen tidak
    pernah negatif: penjualan, sunting, atau hapus yang membuat jumlah
    negatif di titik mana pun ditolak `RecordTransaction` lewat
    `InvestmentLedgerGuard`. Instrumen yang masih punya transaksi tidak bisa
    dihapus.
19. **Tujuan tidak menyentuh saldo.** Membuat, mengubah, mengarsipkan, atau
    mengaktifkan lagi `SavingsGoal` tidak membuat transaksi. "Sudah
    terkumpul" menjadi saldo awal dompet baru, bukan transaksi.
20. **Satu tujuan tepat satu dompet, satu dompet paling banyak satu tujuan.**
    `walletId` unik di seluruh tujuan.
21. **Dompet tujuan hanya untuk transfer.** Tidak ada pemasukan atau
    pengeluaran ber-`walletId` dompet milik tujuan.
22. **Total aset tanpa hitung ganda.** Setiap dompet aktif masuk tepat satu
    lapis, dan jumlah lapis Dompet + Tabungan sama dengan `totalBalance`.

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
- ~~Daftar kategori transaksi.~~ Diputuskan 30 Sep 2026: set bawaan yang bisa
  diubah pengguna ([ADR-026](adr/0026-sistem-kategori.md) §3.2).

## Kategori

`Category` ([ADR-026](adr/0026-sistem-kategori.md)) mengelompokkan pemasukan
dan pengeluaran. Daftar datar, dipisah per jenis, berisi kategori bawaan yang
bisa diubah dan kategori buatan pengguna.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | `builtin.<key>`, `legacy.<jenis>.<label>` (hasil migrasi), atau id buatan. |
| `kind` | `CategoryKind` | `expense` atau `income`. |
| `name` | `String` | Nama tampilan; data milik pengguna. |
| `builtInKey` | `String?` | Kunci kategori bawaan (alias dan ikon). |
| `iconKey` | `String?` | Ikon; kosong berarti ditebak dari nama. |
| `isArchived` | `bool` | Tidak ditawarkan lagi, tetapi transaksi lama tetap menunjuknya. |
| `sortOrder` | `int` | Urutan di pemilih. |

Aturan: kategori tidak dihapus selama ada transaksi, cukup diarsipkan;
transaksi hanya boleh menunjuk kategori berjenis sama; transfer tidak pernah
berkategori.

## Langkah berikutnya

Lanjutkan ke [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) untuk melihat
bagaimana entitas di atas dipetakan ke lapisan dan folder, atau ke
[ADR-011](adr/0011-model-domain-dompet-transaksi-anggaran.md) untuk alasan di
balik bentuk modelnya.
