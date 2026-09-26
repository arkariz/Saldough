# Glosarium proyek

Dokumen ini mendefinisikan istilah yang dipakai konsisten di seluruh
dokumentasi dan kode Saldough. Gunakan istilah ini apa adanya. Kalau sebuah
konsep belum ada di sini, tambahkan dulu sebelum memakainya di dokumen lain.

Setiap istilah punya dua bentuk: **nama Indonesia** untuk dipakai di teks
antarmuka dan percakapan, dan **nama kode** dalam bahasa Inggris untuk dipakai
sebagai nama kelas, field, dan file. Kode Saldough seluruhnya berbahasa Inggris;
bahasa Indonesia hanya muncul di berkas terjemahan slang.

> **Catatan revisi (17 September 2026):** Seluruh istilah domain di dokumen ini
> diganti. Saldough 1.0 memakai kosakata spreadsheet — siklus bulanan, baris
> pemasukan, roll-up, rollover, pos tujuan. Saldough 2.0 berporos pada dompet,
> transaksi, dan anggaran, jadi kosakata lama tidak lagi punya rujukan di kode.
> Istilah 1.0 masih bisa dibaca lewat riwayat git dan lewat
> [arsip perencanaan](../99-archive/README.md). Bagian arsitektur dan konvensi
> penamaan tidak berubah kecuali satu koreksi yang disebut di tempatnya.

## Bahasa yang dipakai aplikasi

Saldough **mencatat** apa yang terjadi pada uang pemilik. Ia tidak memindahkan
uang, tidak membayar, tidak menarik atau menyetor dana, dan tidak terhubung ke
bank mana pun. Kosakata antarmuka harus mencerminkan itu.

| Pakai | Jangan pakai | Sebabnya |
|---|---|---|
| Catat Transfer | Transfer Sekarang | Aplikasi tidak memindahkan uang, hanya mencatat bahwa uang sudah dipindahkan |
| Transfer tercatat | Transfer berhasil | "Berhasil" menyiratkan ada operasi keuangan yang dijalankan |
| Catat Pembayaran | Bayar Sekarang | Pembayaran terjadi di luar aplikasi |
| Pembayaran tercatat | Pembayaran berhasil | Sama seperti di atas |
| Catat Pengeluaran | Kirim Uang | Aplikasi tidak punya kemampuan mengirim apa pun |
| Pengeluaran tercatat | Pembayaran terkirim | Yang tersimpan adalah catatan, bukan perintah bayar |
| Transfer tercatat — Dari, Ke, Jumlah | Transfer Successful | Judul rincian transfer menyatakan rekaman, bukan hasil operasi |

## Dompet dan transaksi

Istilah di bagian ini adalah inti produk: di mana uang berada, dan apa yang
terjadi padanya.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Dompet | `Wallet` | Tempat uang pemilik tercatat berada. Contoh: `BCA`, `Bank Capital`, `Tunai`, `GoPay`, `Tabungan`. Tidak terhubung ke lembaga keuangan mana pun. |
| Saldo awal | `initialBalance` | Nominal yang dinyatakan pemilik saat dompet dibuat. Bukan transaksi setoran. |
| Saldo tercatat | `currentBalance` | Saldo dompet saat ini menurut catatan aplikasi. |
| Total saldo | `totalBalance` | Jumlah saldo seluruh dompet aktif. Angka utama di Beranda. |
| Transaksi | `Transaction` | Satu peristiwa keuangan yang benar-benar terjadi. Punya tanggal. Tiga jenis di bawah ini. |
| Pemasukan | `IncomeTransaction` | Menambah saldo satu dompet. |
| Pengeluaran | `ExpenseTransaction` | Mengurangi saldo satu dompet. Boleh ditautkan ke satu pos anggaran. |
| Transfer | `TransferTransaction` | Memindahkan catatan uang dari satu dompet ke dompet lain. Total saldo tidak berubah, hanya tempatnya. Boleh ditautkan ke satu pos anggaran, untuk pos yang berupa rencana pemindahan seperti setoran tabungan. |
| Kategori | `categoryKey` | Label pengelompokan transaksi, misalnya `makan` atau `transport`. |
| Catat | `record` | Satu-satunya titik masuk pembuatan transaksi manual. Lihat bagian berikutnya. |

Perhatikan bahwa **membuat anggaran tidak pernah mengubah saldo dompet**. Saldo
hanya berubah kalau ada transaksi yang dicatat. Aturan ini dijabarkan di
[ADR-011](../02-architecture/adr/0011-model-domain-dompet-transaksi-anggaran.md).

## Pencatatan

Istilah di bagian ini menjelaskan alur pembuatan transaksi.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| CATAT | `RecordRouteKeys.sheet` | Tombol utama di navigasi bawah yang membuka pilihan jenis transaksi. Satu-satunya jalur kanonik pembuatan transaksi manual. |
| Catat Pemasukan | `RecordKind.income` | Membuat satu `IncomeTransaction`. |
| Catat Pengeluaran | `RecordKind.expense` | Membuat satu `ExpenseTransaction`. |
| Catat Transfer | `RecordKind.transfer` | Membuat satu `TransferTransaction`. |
| Pintasan kontekstual | — | Tombol di layar lain (misalnya rincian dompet) yang membuka CATAT dengan satu field sudah terisi. Bukan alur pencatatan tersendiri. |

## Anggaran

Istilah di bagian ini menjelaskan rencana pengeluaran. Anggaran adalah rencana,
bukan pemesanan uang.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Anggaran | `Budget` | Satu rencana pengeluaran untuk satu periode, terikat pada satu dompet. Boleh ada beberapa sekaligus. |
| Pos anggaran | `BudgetItem` | Satu baris di dalam anggaran, misalnya `Belanja` atau `Listrik`. |
| Pos pengeluaran | `BudgetItemKind.expense` | Pos rencana belanja. Hanya pengeluaran dari dompet anggaran yang terhitung. |
| Pos transfer | `BudgetItemKind.transfer` | Pos rencana pemindahan dana, misalnya setoran tabungan. Punya dompet tujuan; hanya transfer dari dompet anggaran ke dompet itu yang terhitung. |
| Nominal rencana | `plannedAmount` | Berapa yang direncanakan. Di tingkat pos diketik (atau jumlah × harga satuan); di tingkat anggaran selalu jumlah seluruh posnya (ADR-017). |
| Jumlah dan harga satuan | `quantity`, `unitPrice` | Rincian opsional sebuah pos, untuk pos yang berupa daftar belanja. |
| Terpakai | `spent` | Jumlah transaksi yang tertaut, baik pengeluaran maupun transfer. Dihitung dari transaksi, tidak pernah disimpan. |
| Sisa anggaran | `remaining` | Nominal rencana dikurangi terpakai. Boleh negatif. |
| Progres | `progress` | Terpakai dibagi nominal rencana. |
| Belum terpakai | `BudgetItemStatus.planned` | Belum ada transaksi yang tertaut. |
| Terpakai sebagian | `BudgetItemStatus.partiallySpent` | Sudah ada transaksi tertaut, masih di bawah rencana. |
| Selesai | `BudgetItemStatus.completed` | Terpakai sama dengan nominal rencana. |
| Lewat anggaran | `BudgetItemStatus.overspent` | Terpakai melebihi nominal rencana. |
| Periode | `BudgetPeriod` | Rentang berlakunya anggaran: `weekly` atau `monthly`. |
| Template anggaran | `BudgetTemplate` | Definisi yang bisa dipakai ulang untuk membuat anggaran baru. Bukan anggaran aktif. |
| Anggaran aktif | status turunan | Belum diarsipkan dan periodenya belum lewat. |
| Anggaran selesai | status turunan | Belum diarsipkan tetapi periodenya sudah lewat. |
| Anggaran nonaktif | `isArchived` | Diarsipkan pemilik. Transaksi yang tertaut padanya tetap ada. |

Perhatikan bahwa **Selesai** dipakai dua kali dengan cakupan berbeda: sebagai
status sebuah **pos** ia berarti terpakai sama dengan rencana, sementara sebagai
status sebuah **anggaran** ia berarti periodenya sudah lewat. Di antarmuka,
status anggaran selalu ditulis lengkap — "Anggaran selesai" — supaya tidak
tertukar.

Sebuah anggaran terikat pada **satu** dompet, dan hanya transaksi yang keluar
dari dompet itu yang menambah `spent` — pengeluaran dicocokkan lewat `walletId`,
transfer lewat `fromWalletId`. Konsekuensinya dicatat terbuka sebagai risiko di
[ADR-011](../02-architecture/adr/0011-model-domain-dompet-transaksi-anggaran.md).

## Freelance

Istilah di bagian ini menjelaskan penghasilan yang sudah dikerjakan tetapi belum
tentu sudah diterima. Ini domain pendukung, bukan inti.

| Nama Indonesia | Nama kode | Arti |
|---|---|---|
| Proyek freelance | `FreelanceProject` | Klien atau proyek beserta tarif per jam dan aturan potongannya. |
| Tarif per jam | `hourlyRate` | Nilai rupiah per satu jam kerja. |
| Worklog | `WorklogEntry` | Satu entri kerja: tanggal, jumlah jam, dan tarif per jam yang dipakai. |
| Diperoleh | `earnedAmount` | Jam dikali tarif. Pekerjaan yang sudah selesai, **belum tentu diterima**. |
| Ikhtisar Freelance | `FreelanceOverviewPage` | Satu layar tanpa tab — ringkasan upah dan jam, lalu kartu proyek yang menggabungkan worklog dan pembayaran — tujuan dari kedua titik masuk freelance. Entri dan pembayaran dikelola di rincian proyek (`FreelanceProjectPage`), yang bertab Worklog dan Pembayaran. |
| Pembayaran freelance | `FreelancePayment` | Kumpulan worklog yang ditagihkan sebagai satu pembayaran. |
| Belum dibayar | `PaymentStatus.pending` | Pembayaran belum diterima. Tidak menyentuh saldo dompet. |
| Sudah dibayar | `PaymentStatus.paid` | Pembayaran sudah dicatat diterima, dan sudah menghasilkan satu `IncomeTransaction`. |
| Tanggal pembayaran | `expectedDate` | Perkiraan kapan pembayaran diterima. |
| Potongan | `DeductionRule` | Pengurang gaji kotor, berupa per mil atau nominal tetap. |
| Gaji kotor | `grossPay` | Total jam dikali tarif per jam. |
| Gaji bersih | `netPay` | Gaji kotor dikurangi seluruh potongan. Angka inilah yang jadi nominal `IncomeTransaction` saat pembayaran dicatat. |
| Template freelance | `FreelanceTemplate` | Struktur kerja berulang — tarif, potongan, dompet bawaan, jadwal — yang bisa dipakai membuat proyek baru. **Deprecated** 26 Sep 2026, tidak dikerjakan. |

Bedakan dengan tegas antara **diperoleh** dan **diterima**. Kerja yang sudah
selesai tidak pernah menambah saldo dompet. Saldo baru berubah saat pemilik
mencatat bahwa pembayarannya benar-benar diterima.

Perhatikan juga bahwa **pembayaran tidak mengikuti bulan kalender**. Satu
pembayaran bisa mencakup jam kerja yang membentang dari akhir bulan ke
pertengahan bulan berikutnya, dan panjangnya bervariasi dari delapan hari sampai
hampir satu bulan.

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
| `Failure` | Kelas dasar kesalahan dari `package:failures`. Dikembalikan sebagai `Left` dari `Either<Failure, T>` lewat `RepositoryGuard`, bukan dilempar dengan `throw`. |
| `RepositoryGuard` | Mixin yang membungkus operasi data supaya kesalahannya keluar sebagai `Left`, bukan sebagai lemparan. |
| `RouteKey` | Identitas rute bertipe dari `package:navigation`, misalnya `wallet.detail`. |
| `RouteInput` | Argumen bertipe yang dikirim ke sebuah rute. |
| `FeatureRouteModule` | Kumpulan rute milik satu fitur. |
| `IsolatedScope` | Kontainer dependensi terpisah milik satu fitur, dari `package:di`. |
| `StoredValue` | Pembungkus baca-tulis satu nilai di penyimpanan, dari `package:api_storage`. |
| `AppIcon` | Pembungkus ikon yang memetakan kunci semantik ke aset gambar, supaya penggantian set ikon tidak menyentuh berkas halaman. |

> **Koreksi (17 September 2026):** Baris `Failure` di atas sebelumnya berbunyi
> "Dilempar dengan `throw`, bukan dibungkus `Either`". Itu sudah salah sejak
> [ADR-0005](../02-architecture/adr/0005-either-failure-convention.md) dibalik
> pada 10 September 2026, tetapi glosariumnya tidak ikut diperbarui. Kode selalu
> mengikuti ADR-0005, jadi yang keliru hanya dokumen ini.

## Konvensi penamaan

Aturan ini berlaku untuk seluruh kode dan dokumen di repositori.

- Kelas memakai `PascalCase`, misalnya `Wallet` dan `TransactionBloc`.
- Variabel dan fungsi memakai `camelCase`, misalnya `currentBalance`.
- Berkas memakai `snake_case`, misalnya `expense_transaction.dart`.
- Anggota privat diawali garis bawah, misalnya `_recomputeBalance`.
- Nama entitas domain tidak disingkat. Tulis `FreelancePayment`, bukan
  `FrlPayment`.
- Nama dompet dan kategori disimpan sebagai data, bukan sebagai enum. Pemilik
  bisa menambah atau mengubahnya tanpa mengubah kode.
- Jenis transaksi justru sebaliknya: `IncomeTransaction`, `ExpenseTransaction`,
  dan `TransferTransaction` adalah tipe tertutup (`sealed`), karena menambah
  jenis baru mengubah aturan perhitungan saldo dan harus dipikirkan, bukan
  diketik pemilik.

## Langkah berikutnya

Lanjutkan ke [PRD 2.0](../01-product/prd-saldough-2.0.md) untuk melihat apa yang
dibangun, atau ke [DOMAIN_MODEL.md](../02-architecture/DOMAIN_MODEL.md) untuk
melihat entitas dan rumusnya. Untuk memahami kebiasaan keuangan pemilik yang
melatarbelakangi produk ini, baca
[MANUAL_PROCESS_ANALYSIS.md](MANUAL_PROCESS_ANALYSIS.md) — dokumen itu tetap
berlaku meski produknya berganti bentuk.
