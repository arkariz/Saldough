# Glosarium proyek

Dokumen ini mendefinisikan istilah yang dipakai konsisten di seluruh
dokumentasi dan kode Saldough. Gunakan istilah ini apa adanya. Kalau sebuah
konsep belum ada di sini, tambahkan dulu sebelum memakainya di dokumen lain.

Setiap istilah punya dua bentuk: **nama Indonesia** untuk dipakai di teks
antarmuka dan percakapan, dan **nama kode** dalam bahasa Inggris untuk dipakai
sebagai nama kelas, field, dan file. Kode Saldough seluruhnya berbahasa Inggris;
bahasa Indonesia hanya muncul di berkas terjemahan slang.

## Istilah domain

Istilah di bagian ini berasal langsung dari cara kerja pemilik, seperti direkam
di [MANUAL_PROCESS_ANALYSIS.md](MANUAL_PROCESS_ANALYSIS.md).

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Siklus bulanan | `MonthlyCycle` | Satu bulan anggaran utuh, berisi pemasukan, anggaran, dan rencana investasi. Diidentifikasi dengan `YYYY-MM`. Setara satu blok tabel di spreadsheet utama. |
| Baris pemasukan | `IncomeLine` | Satu baris di bagian PEMASUKAN, misalnya `Gaji Koko` atau `THR Laufey`. |
| Baris anggaran | `BudgetLine` | Satu baris di bagian ANGGARAN SEBULAN, misalnya `listrik` atau `Kos`. |
| Baris tetap | `isTemplate: true` | Baris yang muncul hampir tiap bulan dan ikut terbawa saat rollover. |
| Baris insidental | `isTemplate: false` | Baris yang hanya berlaku di satu bulan dan tidak terbawa saat rollover. |
| Roll-up | `BudgetLineKind.rollUp` | Baris anggaran yang nominalnya bukan diketik, melainkan dihitung dari sumber lain. Tiga yang ada: belanja, dan dua kartu kredit. |
| Sisa | `remainder` | Total pemasukan dikurangi total anggaran. Boleh negatif. |
| Lewat anggaran | `isOverBudget` | Kondisi saat sisa bernilai negatif. |
| Template siklus | `CycleTemplate` | Kumpulan baris tetap yang dipakai membuat siklus bulan berikutnya. |
| Rollover | `rollOver` | Tindakan membuat siklus bulan baru dari template. |

## Pemasukan dan jam kerja

Istilah di bagian ini menjelaskan bagaimana penghasilan freelance per jam
berubah menjadi satu baris pemasukan.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Sumber pemasukan | `IncomeSource` | Definisi sumber penghasilan yang berlaku lintas bulan, bukan nominal per bulan. |
| Gaji tetap | `IncomeSourceKind.fixedSalary` | Sumber pemasukan bernominal sama tiap bulan. Contoh: `Gaji Koko`. |
| Freelance per jam | `IncomeSourceKind.hourlyFreelance` | Sumber pemasukan yang nominalnya dihitung dari jam kerja dikali tarif. Contoh: `Gaji Menul`. |
| Sekali jalan | `IncomeSourceKind.adHoc` | Pemasukan sekali jalan tanpa aturan hitung. Contoh: `THR Laufey`. |
| Tarif per jam | `hourlyRate` | Nilai rupiah per satu jam kerja freelance. |
| Catatan jam | `WorkLogEntry` | Satu entri jam kerja harian: tanggal, jumlah jam, dan penanda buku baru. |
| Hari buku baru | `startsNewBook` | Penanda pada catatan jam yang menandakan awal periode tagihan baru. |
| Buku jam | `BillingBook` | Satu periode tagihan freelance, yaitu kumpulan catatan jam dari satu penanda buku baru sampai penanda berikutnya. |
| Total jam | `totalHours` | Jumlah seluruh jam dalam satu buku jam. |
| Gaji kotor | `grossPay` | Total jam dikali tarif per jam. |
| Potongan | `DeductionRule` | Pengurang gaji kotor, berupa persentase atau nominal tetap. |
| Gaji bersih | `netPay` | Gaji kotor dikurangi seluruh potongan. Angka ini yang masuk ke baris pemasukan. |

Perhatikan bahwa **buku jam tidak sama dengan bulan kalender**. Satu buku jam
bisa membentang dari akhir bulan ke pertengahan bulan berikutnya, dan panjangnya
bervariasi dari delapan hari sampai hampir satu bulan.

## Belanja

Istilah di bagian ini menjelaskan bagaimana dua daftar belanja menjadi satu
baris anggaran.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Rencana belanja | `GroceryPlan` | Kumpulan daftar mingguan dan bulanan beserta pengali minggunya. |
| Daftar mingguan | `weeklyItems` | Bahan yang habis tiap minggu dan dibeli berulang. |
| Daftar bulanan | `monthlyItems` | Kebutuhan yang bertahan sebulan dan dibeli sekali. |
| Item belanja | `GroceryItem` | Satu bahan: nama, jumlah, harga satuan, dan harga. |
| Harga timpaan | `amountOverride` | Harga yang diketik manual dan mengabaikan hasil jumlah dikali harga satuan. |
| Pengali minggu | `weeksPerMonth` | Berapa kali daftar mingguan dihitung dalam sebulan. Default empat. |
| Total sebulan | `groceryRollUp` | Subtotal mingguan dikali pengali minggu, ditambah subtotal bulanan. |

## Kartu kredit

Istilah di bagian ini menjelaskan bagaimana transaksi kartu menjadi satu baris
anggaran.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Kartu | `CreditCard` | Satu kartu kredit beserta tanggal cetak tagihannya. |
| Siklus tagihan | `CardStatement` | Satu periode tagihan pada satu kartu, berisi transaksi periode itu. |
| Transaksi kartu | `CardTransaction` | Satu transaksi: tanggal, merchant, nominal, dan catatan. |
| Langganan | `RecurringSubscription` | Template transaksi yang berulang tiap siklus dengan nominal tetap. Contoh: Netflix Rp65.000. |
| Total tagihan | `cardRollUp` | Jumlah seluruh transaksi dalam satu siklus tagihan. |

## Investasi

Istilah di bagian ini menjelaskan pembagian sisa ke pos tujuan.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Pos tujuan | `Goal` | Tujuan keuangan bersaldo. Contoh: `ANAK`, `RUMAH`, `PENSIUN`, `SEKOLAH`, `KYOTO`, `SAHAM`. |
| Rencana investasi | `InvestmentPlan` | Bagian siklus bulanan yang membagi sisa ke pos tujuan. |
| Return deposit | `returnDeposit` | Tambahan dana di luar sisa yang ikut dibagikan ke pos. |
| Budget investasi | `investmentBudget` | Sisa ditambah return deposit. Ini yang dibagi berdasarkan persentase. |
| Alokasi | `Allocation` | Bagian satu pos: persentase dan nominal hasil hitungnya. |
| Pinjaman antar pos | `GoalLoan` | Peminjaman dana dari satu pos untuk keperluan pos lain. |
| Pokok pinjaman | `principal` | Nominal yang dipinjam. |
| Pengembalian | `repaid` | Nominal yang dikembalikan. Boleh berbeda dari pokok. |

## Istilah arsitektur

Istilah di bagian ini berasal dari paket internal yang dipakai Saldough.
Penjelasan lengkapnya ada di
[ARCHITECTURE_OVERVIEW.md](../02-architecture/ARCHITECTURE_OVERVIEW.md).

| Istilah | Arti |
|---|---|
| `UiState` | Kelas dasar state dari `package:state_management`. Membawa `effect` yang sengaja dikecualikan dari `props`. |
| `UiEffect` | Aksi sekali jalan dari bloc ke UI, misalnya menampilkan snackbar atau berpindah halaman. |
| `EffectRegistry` | Pendaftaran penangan efek. Memetakan tipe efek ke fungsi penanganannya. |
| `EffectListener` | Widget yang menjembatani efek dari bloc ke penanganannya di UI. |
| `Failure` | Kelas dasar kesalahan dari `package:failures`. Dilempar dengan `throw`, bukan dibungkus `Either`. |
| `RouteKey` | Identitas rute bertipe dari `package:navigation`, misalnya `cycle.detail`. |
| `RouteInput` | Argumen bertipe yang dikirim ke sebuah rute. |
| `FeatureRouteModule` | Kumpulan rute milik satu fitur. |
| `IsolatedScope` | Kontainer dependensi terpisah milik satu fitur, dari `package:di`. |
| `StoredValue` | Pembungkus baca-tulis satu nilai di penyimpanan, dari `package:api_storage`. |
| Roll-up otomatis | Mekanisme yang memperbarui baris anggaran roll-up saat sumbernya berubah. |

## Konvensi penamaan

Aturan ini berlaku untuk seluruh kode dan dokumen di repositori.

- Kelas memakai `PascalCase`, misalnya `MonthlyCycle` dan `CycleBloc`.
- Variabel dan fungsi memakai `camelCase`, misalnya `totalHours`.
- Berkas memakai `snake_case`, misalnya `monthly_cycle.dart`.
- Anggota privat diawali garis bawah, misalnya `_calculateRemainder`.
- Nama entitas domain tidak disingkat. Tulis `CardStatement`, bukan `CardStmt`.
- Nama pos tujuan disimpan sebagai data, bukan sebagai enum. Pemilik bisa
  menambah atau mengubah pos tanpa mengubah kode.

## Langkah berikutnya

Lanjutkan ke [MANUAL_PROCESS_ANALYSIS.md](MANUAL_PROCESS_ANALYSIS.md) untuk
memahami asal setiap istilah domain, atau ke
[DOMAIN_MODEL.md](../02-architecture/DOMAIN_MODEL.md) untuk melihat entitas dan
rumusnya.
