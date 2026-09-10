# Model domain

Dokumen ini menerjemahkan proses manual yang direkam di
[MANUAL_PROCESS_ANALYSIS.md](../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
menjadi entitas, rumus, dan invarian yang bisa langsung diimplementasikan.

Model ini murni domain. Tidak ada satu pun entitas di sini yang boleh mengimpor
Flutter, Hive, atau paket infrastruktur lain. Aturan lengkapnya ada di
[ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md).

Nama kelas dan field memakai bahasa Inggris sesuai
[glosarium](../00-foundation/PROJECT_GLOSSARY.md).

## Aturan representasi uang

Sebelum membahas entitas, satu aturan berlaku menyeluruh: **semua nominal
disimpan sebagai bilangan bulat dalam satuan sen**, yaitu seperseratus rupiah.
Pembulatan ke rupiah hanya dilakukan saat menampilkan.

Aturan ini bukan pilihan gaya. Aturan ini diturunkan dari perilaku spreadsheet
yang sebenarnya. Pajak 2,5% menghasilkan pecahan setengah rupiah, dan
spreadsheet tidak membulatkan pajak sebelum menguranginya dari gaji kotor. Kalau
aplikasi membulatkan lebih awal, hasilnya meleset satu rupiah dari catatan
pemilik.

Bukti dari gaji kotor Rp3.117.500:

| Cara hitung | Hasil |
|---|---|
| Bulatkan pajak dulu: `3.117.500 − 77.938` | Rp3.039.562 (meleset) |
| Kurangi eksak lalu bulatkan: `3.117.500 × 0,975` | Rp3.039.563 (cocok) |

Aritmatika integer sen mereproduksi spreadsheet persis di seluruh lima bulan
yang punya data gaji bersih:

| Gaji kotor (sen) | Pajak (sen) | Gaji bersih (sen) | Tampil | Spreadsheet |
|---|---|---|---|---|
| 735.000.000 | 18.375.000 | 716.625.000 | Rp7.166.250 | Rp7.166.250 |
| 105.000.000 | 2.625.000 | 102.375.000 | Rp1.023.750 | Rp1.023.750 |
| 268.250.000 | 6.706.250 | 261.543.750 | Rp2.615.438 | Rp2.615.438 |
| 311.750.000 | 7.793.750 | 303.956.250 | Rp3.039.563 | Rp3.039.563 |
| 108.750.000 | 2.718.750 | 106.031.250 | Rp1.060.313 | Rp1.060.313 |

Tiga konsekuensi yang mengikat implementasi:

- Tipe seluruh field nominal adalah `int` dalam sen. Jangan pernah memakai
  `double` untuk uang.
- Persentase dihitung sebagai `nilai * persen ~/ 100` pada satuan sen, bukan
  lewat perkalian pecahan.
- Pembulatan ke rupiah memakai pembulatan setengah ke atas, dan hanya terjadi di
  lapisan presentasi.

## Ringkasan entitas

Model terbagi menjadi lima kelompok. Siklus bulanan adalah agregat inti; empat
kelompok lain memasok angka ke dalamnya.

```
            ┌─────────────────────────────────────────┐
            │            MonthlyCycle                 │
            │  id: "2026-09"                          │
            │  ├── incomeLines:  List<IncomeLine>     │
            │  ├── budgetLines:  List<BudgetLine>     │
            │  └── investmentPlan: InvestmentPlan     │
            └─────────────────────────────────────────┘
                 ▲              ▲                ▲
                 │              │                │
   ┌─────────────┘        ┌─────┴──────┐    ┌────┴─────────┐
   │                      │            │    │              │
IncomeSource        GroceryPlan   CardStatement        Goal
   │                                    │                 │
WorkLogEntry                     CardTransaction       GoalLoan
   │                                    │
BillingBook                  RecurringSubscription
   │
DeductionRule
```

## Siklus bulanan

`MonthlyCycle` adalah agregat inti dan satu-satunya entitas yang disimpan per
bulan. Satu siklus setara dengan satu blok tabel di spreadsheet utama.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Format `YYYY-MM`, misalnya `2026-09`. |
| `incomeLines` | `List<IncomeLine>` | Baris di bagian pemasukan. |
| `budgetLines` | `List<BudgetLine>` | Baris di bagian anggaran. |
| `investmentPlan` | `InvestmentPlan` | Rencana pembagian sisa. |
| `closedAt` | `DateTime?` | Terisi saat siklus dikunci. Null berarti masih berjalan. |

Nilai turunan yang dihitung, bukan disimpan:

```
totalIncome = Σ incomeLines.amount
totalBudget = Σ budgetLines.amount
remainder   = totalIncome − totalBudget
isOverBudget = remainder < 0
```

`remainder` boleh negatif. Ini bukan kondisi kesalahan, melainkan keadaan nyata
yang pernah terjadi. Bukti: siklus dengan pemasukan Rp8.900.000 dan anggaran
Rp10.237.042 menghasilkan sisa −Rp1.337.042. Antarmuka harus menampilkannya
dengan warna `overBudget`, bukan menolak menyimpannya.

### Baris pemasukan

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas baris. |
| `label` | `String` | Nama yang tampil, misalnya `Gaji Koko`. |
| `amount` | `int` | Nominal dalam sen. |
| `sourceId` | `String?` | Rujukan ke `IncomeSource`. Null untuk baris yang diketik lepas. |
| `isTemplate` | `bool` | True kalau baris ikut terbawa saat rollover. |
| `needsReview` | `bool` | True kalau baris ini hasil rollover yang belum dikonfirmasi pemilik. |

### Baris anggaran

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas baris. |
| `label` | `String` | Nama yang tampil, misalnya `listrik`. |
| `amount` | `int` | Nominal dalam sen. |
| `kind` | `BudgetLineKind` | `manual` atau `rollUp`. |
| `rollUpSource` | `RollUpSource?` | Wajib terisi kalau `kind` bernilai `rollUp`. |
| `isTemplate` | `bool` | True kalau baris ikut terbawa saat rollover. |
| `needsReview` | `bool` | True kalau baris ini hasil rollover yang belum dikonfirmasi pemilik. |

> **Catatan 10 September 2026:** field `needsReview` tidak ada di draf tabel
> ini semula, padahal ADR-0008 aturan 3 dan FR-TPL-002 sudah mengikat bahwa
> setiap baris hasil rollover wajib bisa ditandai "perlu ditinjau" dan
> penandanya wajib bisa dihapus pemilik satu per satu. Ditambahkan saat
> implementasi Fase 2, bukan keputusan produk baru — cuma menutup celah
> dokumentasi. Nilai bawaan `false`; rollover mengisi `true` pada baris hasil
> salinan, dan penyuntingan manual oleh pemilik mengembalikannya ke `false`
> (lihat `RollOverCycle` dan `CycleBloc` di ARCHITECTURE_OVERVIEW.md).

`RollUpSource` menunjuk asal angka untuk baris yang tidak diketik manual:

- `grocery` untuk baris `Bulanan`.
- `card(cardId)` untuk baris `CC TOKPED` dan `CC BRI TOUCH`.

Baris ber-`kind` `rollUp` tidak boleh disunting nominalnya secara langsung.
Nominalnya selalu hasil hitung dari sumbernya. Aturan ini yang menghapus
pekerjaan menyalin angka antar spreadsheet.

## Sumber pemasukan dan jam kerja

Kelompok ini menghasilkan nominal untuk baris pemasukan yang punya `sourceId`.

### Sumber pemasukan

`IncomeSource` adalah definisi yang berlaku lintas bulan, bukan nominal per
bulan.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas sumber. |
| `name` | `String` | Nama, misalnya `Gaji Menul`. |
| `kind` | `IncomeSourceKind` | `fixedSalary`, `hourlyFreelance`, atau `adHoc`. |
| `fixedAmount` | `int?` | Nominal tetap dalam sen. Dipakai kalau `kind` bernilai `fixedSalary`. |
| `hourlyRate` | `int?` | Tarif per jam dalam sen. Dipakai kalau `kind` bernilai `hourlyFreelance`. |
| `deductionRules` | `List<DeductionRule>` | Potongan yang berlaku. Kosong untuk sumber selain freelance. |

### Aturan potongan

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas aturan. |
| `label` | `String` | Nama, misalnya `Pajak`. |
| `kind` | `DeductionKind` | `percentage` atau `fixedAmount`. |
| `value` | `int` | Untuk `percentage`, nilai per mil (perseribu). Untuk `fixedAmount`, nominal dalam sen. |

> **Catatan 10 September 2026:** draf awal menulis `value` sebagai "nilai per
> seratus" (persentase bulat). Itu tidak bisa merepresentasikan tarif pajak
> nyata 2,5% sebagai `int`. Diperbaiki ke per mil (2,5% tersimpan sebagai
> `25`) saat implementasi Fase 3 — menutup celah dokumentasi, bukan keputusan
> produk baru. Rumus di bawah diperbarui mengikuti (`~/ 1000`, bukan
> `~/ 100`).

Aturan yang berlaku hari ini pada `Gaji Menul`: pajak sebesar 2,5% (`value:
25`) sebagai potongan persentase, ditambah potongan bernominal tetap yang
muncul sesekali seperti `jajan` dan `webinar` senilai Rp150.000.

**Nilai `hourlyRate` terkonfirmasi pemilik: Rp72.500.** Ini adalah data yang
tersimpan di `IncomeSource`, bukan konstanta kode — pemilik bisa mengubahnya
kapan saja lewat antarmuka. Nilai ini dipakai sebagai seed Fase 6, bukan nilai
bawaan terprogram.

### Catatan jam dan buku jam

`WorkLogEntry` merekam satu hari kerja.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas entri. |
| `date` | `DateTime` | Tanggal kerja. |
| `hours` | `int` | Jumlah jam. |
| `startsNewBook` | `bool` | True kalau entri ini memulai periode tagihan baru. |

`BillingBook` adalah periode tagihan, yaitu kumpulan entri dari satu penanda
buku baru sampai penanda berikutnya.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas buku. |
| `sourceId` | `String` | Rujukan ke `IncomeSource` bertipe freelance. |
| `startDate` | `DateTime` | Tanggal entri pertama. |
| `endDate` | `DateTime?` | Tanggal entri terakhir. Null selama buku masih terbuka. |
| `entries` | `List<WorkLogEntry>` | Entri dalam periode ini. |
| `netPayAmount` | `int?` | Gaji bersih hasil `CalculateNetPay` saat buku ditutup, dalam sen. Null selama buku masih terbuka — lihat catatan di bawah. |
| `injectedCycleId` | `String?` | Siklus tujuan penyuntikan (T-3.9). Null kalau belum disuntikkan. |
| `injectedIncomeLineId` | `String?` | Baris pemasukan tujuan di siklus itu. Null kalau belum disuntikkan. |

> **Catatan 10 September 2026:** tiga field terakhir tidak ada di draf tabel
> ini semula. Ditambahkan saat implementasi Fase 3 supaya nilai gaji bersih
> sebuah buku yang sudah ditutup tetap tetap (tidak dihitung ulang diam-diam
> kalau `IncomeSource`-nya kelak berubah tarif) dan supaya "sudah disuntikkan
> ke siklus mana" bisa ditampilkan di riwayat (FR-TIME-004) tanpa menyuntik
> dua kali. Menutup celah dokumentasi, bukan keputusan produk baru.

Buku jam **tidak** dipotong per bulan kalender. Periode ditentukan semata oleh
penanda `startsNewBook`. Data nyata menunjukkan panjang periode bervariasi dari
delapan hari sampai hampir satu bulan penuh, misalnya 29 Agustus sampai
5 September 2026 sebanyak 15 jam, dan 29 Oktober sampai 26 November 2025
sebanyak 125 jam.

Rumus dari buku jam menjadi baris pemasukan:

```
totalHours = Σ entries.hours
grossPay   = totalHours × source.hourlyRate
deduction(rule) = rule.kind == percentage
                    ? grossPay × rule.value ~/ 1000
                    : rule.value
netPay     = grossPay − Σ deduction(rule)
```

Potongan persentase selalu dihitung dari gaji kotor, bukan dari nilai berjalan
setelah potongan sebelumnya. Ini sesuai spreadsheet, di mana kolom gaji kotor
berulang di setiap baris potongan.

Rumus di atas dihitung murni dalam sen — `~/` di sini tidak pernah kehilangan
presisi untuk kombinasi gaji kotor rupiah bulat dan tarif satu desimal persen
(sen memberi dua digit presisi ekstra di atas rupiah, mil memberi satu digit
ekstra di atas persen). Spreadsheet aslinya membulatkan potongan ke rupiah
**sebelum** mengurangi dari gaji kotor — itu sumber selisih satu rupiah yang
pernah ditemukan (lihat `docs/00-foundation/MANUAL_PROCESS_ANALYSIS.md`,
kasus Rp3.117.500: membulatkan potongan lebih dulu menghasilkan Rp3.039.562,
padahal jawaban benar Rp3.039.563). `netPay` di sini selalu dihitung dari
`deduction(rule)` yang belum dibulatkan — pembulatan ke rupiah hanya terjadi
saat `AppMoneyFormatter` menampilkannya.

## Belanja

`GroceryPlan` menghasilkan nominal untuk baris anggaran ber-`rollUpSource`
`grocery`.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas rencana. |
| `weeklyItems` | `List<GroceryItem>` | Daftar mingguan. |
| `monthlyItems` | `List<GroceryItem>` | Daftar bulanan. |
| `weeksPerMonth` | `int` | Pengali daftar mingguan. Default 4. |

`GroceryItem` merekam satu bahan.

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | Identitas item. |
| `name` | `String` | Nama bahan. |
| `quantity` | `int` | Jumlah. |
| `unitPrice` | `int` | Harga satuan dalam sen. |
| `amountOverride` | `int?` | Harga manual yang mengabaikan hasil perkalian. |

```
item.amount   = amountOverride ?? (quantity × unitPrice)
weeklySubtotal  = Σ weeklyItems.amount
monthlySubtotal = Σ monthlyItems.amount
groceryRollUp   = weeklySubtotal × weeksPerMonth + monthlySubtotal
```

Bukti: `576.600 × 4 + 762.100 = 3.068.500`, sama persis dengan baris `Bulanan`
di siklus yang bersangkutan.

`amountOverride` wajib ada karena spreadsheet asli memuat koreksi manual. Sampo
tercatat `1 × Rp41.300` tetapi harganya Rp24.000, dan popok tercatat
`1 × Rp180.000` tetapi harganya Rp22.500. Model yang memaksa perkalian akan
menolak data nyata pemilik.

## Kartu kredit

`CardStatement` menghasilkan nominal untuk baris anggaran ber-`rollUpSource`
`card`.

| Entitas | Field |
|---|---|
| `CreditCard` | `id`, `name`, `statementDayOfMonth` |
| `CardStatement` | `id`, `cardId`, `periodStart`, `periodEnd`, `transactions`, `closedAt` |
| `CardTransaction` | `id`, `date`, `merchant`, `amount`, `note`, `isConfirmed` |
| `RecurringSubscription` | `id`, `cardId`, `merchant`, `amount`, `dayOfMonth`, `isActive` |

```
cardRollUp = Σ statement.transactions.where(isConfirmed).amount
```

> **Catatan revisi (T-4.6/T-4.10, 10 September 2026):** `isConfirmed`
> ditambahkan ke `CardTransaction` — tidak ada di tabel semula dokumen ini.
> Bawaan `true` untuk transaksi yang diketik manual; `false` untuk hasil
> penyiapan otomatis dari `RecurringSubscription` yang belum dikonfirmasi
> pemilik (lihat paragraf di bawah). Formula `cardRollUp` di atas juga
> dikoreksi untuk menyaring `isConfirmed` — versi awal menjumlahkan seluruh
> transaksi tanpa penyaring ini, yang berarti nominal langganan yang belum
> dikonfirmasi (dan bisa berubah) akan ikut terhitung ke anggaran sebelum
> pemilik sempat memeriksanya.

**Nilai `statementDayOfMonth` terkonfirmasi pemilik: tanggal 15**, berlaku
sebagai nilai seed untuk kartu yang diimpor di Fase 6. Sama seperti
`hourlyRate`, ini data pada `CreditCard`, bukan konstanta kode — tiap kartu
boleh punya tanggal cetak berbeda dan pemilik bisa mengubahnya.

`CardTransaction` punya field `note` terpisah dari `merchant`. Di spreadsheet,
kolom merchant dipakai menampung catatan seperti `PT Tokopedia cicilan 1` dan
`ulanzi tripod canceled?`. Memisahkan keduanya menjaga nama merchant tetap
bersih sehingga bisa dicocokkan dengan `RecurringSubscription`.

`RecurringSubscription` menyiapkan transaksi berulang di awal siklus baru.
Transaksi hasil penyiapan tetap perlu dikonfirmasi pemilik, karena nominal
langganan bisa berubah. Contoh nyata: Claude AI tercatat Rp337.760 di satu
siklus dan Rp358.600 di siklus lain.

## Investasi

Kelompok ini membagi sisa siklus ke pos tujuan.

### Rencana investasi

| Field | Tipe | Keterangan |
|---|---|---|
| `returnDeposit` | `int` | Tambahan dana dalam sen. Nol kalau tidak ada. |
| `allocations` | `List<Allocation>` | Pembagian per pos. |

| `Allocation` | Tipe | Keterangan |
|---|---|---|
| `goalId` | `String` | Rujukan ke `Goal`. |
| `percentage` | `int` | Persentase, bilangan bulat 0 sampai 100. |

```
investmentBudget  = cycle.remainder + returnDeposit
allocation.amount = investmentBudget × allocation.percentage ~/ 100
```

Bukti dari siklus dengan sisa Rp3.086.960: `× 15% = 463.044` dan
`× 55% = 1.697.828`. Bukti dari siklus dengan sisa Rp5.370.616:
`× 20% = 1.074.123` dan `× 40% = 2.148.246`.

### Pos tujuan dan pinjaman

| Entitas | Field |
|---|---|
| `Goal` | `id`, `name`, `openingBalance` |
| `GoalLoan` | `id`, `fromGoalId`, `toGoalId`, `principal`, `repaid`, `date`, `note` |

```
goal.balance = openingBalance
             + Σ alokasi ke pos ini dari seluruh siklus tertutup
             + Σ pinjaman yang dikembalikan ke pos ini
             − Σ pokok pinjaman yang keluar dari pos ini
```

`principal` dan `repaid` disimpan terpisah karena nilainya bisa berbeda.
Contoh nyata: pinjaman pokok Rp9.300.000 dikembalikan Rp9.331.000, selisih
Rp31.000.

Enam pos yang berlaku hari ini adalah `ANAK`, `RUMAH`, `PENSIUN`, `SEKOLAH`,
`KYOTO`, dan `SAHAM` — **ini bukan daftar tertutup.** Nama pos disimpan sebagai
data, bukan enum, dan FR-INV-001 sudah mengizinkan pemilik menambah pos baru
kapan saja. `GoalLoan` hanya boleh merujuk `Goal` yang benar-benar terdaftar
(lihat invarian di bawah) — ini keputusan sadar, bukan kelonggaran: kalau
pemilik ingin melacak formal pinjaman semacam contoh lama di spreadsheet
(`Travel To Japan`, `Kuliah tata`, yang saat itu tidak ada di pos manapun),
langkahnya adalah mendaftarkan keduanya sebagai `Goal` baru lebih dulu
(dengan `openingBalance` default 0), bukan menulis label bebas di `GoalLoan`.
Ini menutup ketidaksinkronan yang ada di spreadsheet, di mana bagian pinjaman
dan bagian alokasi memakai dua daftar nama yang berbeda.

**Nilai `openingBalance` terkonfirmasi pemilik: 0 untuk seluruh pos**, berlaku
sebagai nilai seed Fase 6. Pemilik memilih tidak merekonstruksi saldo historis
pos tujuan saat ini.

## Template dan rollover

`CycleTemplate` menyimpan kerangka siklus berikutnya.

| Field | Tipe | Keterangan |
|---|---|---|
| `incomeLines` | `List<IncomeLine>` | Baris pemasukan tetap. |
| `budgetLines` | `List<BudgetLine>` | Baris anggaran tetap. |
| `defaultAllocations` | `List<Allocation>` | Persentase alokasi bawaan. |

Rollover membuat siklus bulan baru dengan aturan berikut:

1. Salin hanya baris ber-`isTemplate` true. Baris insidental bulan sebelumnya
   tidak ikut.
2. Untuk baris ber-`kind` `rollUp`, jangan salin nominalnya. Hitung ulang dari
   sumbernya di siklus baru.
3. Tandai setiap baris tetap sebagai perlu ditinjau, supaya pemilik menyesuaikan
   nominal yang berubah seperti listrik dan kos.
4. Salin `defaultAllocations` apa adanya.

Aturan ketiga menjawab langsung nyeri utama pemilik. Label `Kos agustus -
september` yang terbawa tiga bulan berturut-turut membuktikan bahwa penyalinan
manual membuat baris lama lolos tanpa ditinjau.

## Invarian

Aturan berikut harus dijaga model dan diuji.

| Invarian | Alasan |
|---|---|
| `Σ allocations.percentage` bernilai 0 atau 100. | Spreadsheet punya sel validator dengan aturan persis ini. Nilai 0 berarti bulan itu belum dialokasikan. |
| `remainder` boleh negatif. | Terbukti terjadi, dan harus tampil sebagai kondisi lewat anggaran. |
| Baris ber-`kind` `rollUp` tidak bisa disunting nominalnya. | Nominalnya turunan. Menyuntingnya akan memunculkan kembali masalah salin manual. |
| Baris ber-`kind` `rollUp` wajib punya `rollUpSource`. | Tanpa sumber, nominalnya tidak bisa dihitung. |
| Satu buku jam hanya boleh punya satu entri ber-`startsNewBook` true, yaitu entri pertamanya. | Penanda inilah yang mendefinisikan batas periode. |
| `id` siklus unik dan berformat `YYYY-MM`. | Satu bulan hanya boleh punya satu siklus. |
| Seluruh nominal bertipe `int` dalam sen. | Menjaga hasil hitung sama persis dengan spreadsheet. |
| `goalId` pada alokasi dan pinjaman harus menunjuk `Goal` yang ada. | Mencegah ketidaksinkronan daftar pos seperti di spreadsheet. |

## Nilai seed terkonfirmasi

Tiga nilai yang semula tidak bisa disimpulkan dari spreadsheet sudah
dikonfirmasi pemilik pada 10 September 2026. Ketiganya adalah **data seed**,
bukan konstanta kode — field yang menampungnya (`hourlyRate`,
`statementDayOfMonth`, `openingBalance`) tetap bisa disunting pemilik kapan
saja lewat antarmuka.

| Nilai | Field | Seed |
|---|---|---|
| Tarif per jam `Gaji Menul` | `IncomeSource.hourlyRate` | Rp72.500 |
| Tanggal cetak tagihan kartu | `CreditCard.statementDayOfMonth` | 15 |
| Saldo awal tiap pos tujuan | `Goal.openingBalance` | 0 |

Satu hal terkait lain yang juga sudah diputuskan: `GoalLoan` hanya merujuk
`Goal` yang terdaftar, dengan daftar `Goal` yang terbuka — lihat bagian
"Pos tujuan dan pinjaman" di atas.

## Langkah berikutnya

Lanjutkan ke [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) untuk melihat
bagaimana model ini dipetakan ke lapisan dan paket, atau ke
[PRD](../01-product/prd-saldough-1.0.md) untuk melihat kebutuhan produknya.
