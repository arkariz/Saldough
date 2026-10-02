# Analisis pesaing: transaksi rutin, tagihan, dan perkiraan arus kas

**Tanggal riset:** 2 Oktober 2026.
**Untuk:** keputusan fitur di
[RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md): di mana Tanukonomy
harus berbeda, di mana cukup setara, dan apa yang tidak perlu dibangun.
**Metode dan batasannya:** halaman fitur, pusat bantuan resmi, dan forum
komunitas pesaing (daftar di [Sumber](#sumber)). Aplikasinya **tidak diuji
langsung**. Sel bertanda `?` berarti belum terverifikasi, bukan berarti fiturnya
tidak ada. Fitur pesaing cepat berubah, jadi periksa ulang sebelum dipakai
untuk materi pemasaran.

## 1. Kesimpulan

1. **Pasarnya terbelah dua, dan tengahnya kosong.** Pencatat manual yang
   dipakai di Indonesia (Money Lover, Money Manager, Cashew, Wallet) punya
   fitur rutin. Perkiraannya lemah atau tidak ada, dan sebagian mencatat rutin
   diam-diam pada tanggalnya. Aplikasi perencanaan dengan perkiraan yang kuat
   (Simplifi, Monarch, PocketSmith) bergantung pada koneksi bank, berbayar,
   dan dibuat untuk pasar AS. Belum ada aplikasi yang memberi **perkiraan yang
   bisa dipercaya untuk orang yang mencatat sendiri tanpa koneksi bank**.
2. **Keluhan terbesar soal perkiraan adalah angka yang terlalu bagus.**
   Perkiraan arus kas Simplifi hanya memakai rutin. Belanja yang direncanakan,
   seperti belanja dapur dan bensin, tidak ikut dihitung. Pengguna di forum
   komunitasnya menyebut perkiraan seperti itu berbahaya. Desain Tanukonomy
   sudah memasukkan anggaran dan rata-rata belanja di luar rencana (§7.4–7.5
   desain).
3. **Senjata yang hanya dimiliki Tanukonomy di kelas manual adalah catat dari
   notifikasi (ADR-032) dan suara (ADR-027/029).** Kalau digabung dengan
   rutin, kemunculan bisa terkonfirmasi sendiri saat notifikasi bank masuk,
   kenaikan harga langganan terdeteksi tanpa koneksi bank, dan autodebet yang
   gagal ketahuan karena notifikasinya tidak pernah datang. Aplikasi berbasis
   bank mendapatkan hal ini dari koneksi banknya. Aplikasi manual lain tidak
   punya jalan ke sana.
4. **Fitur yang harus setara, karena tanpanya fitur rutin terasa kurang:**
   pengingat, lewati satu kemunculan, berakhir setelah N kali atau pada tanggal
   tertentu, nominal yang bisa berubah, mengubah transaksi lama menjadi rutin,
   total langganan per bulan dan per tahun, serta saran pola rutin.
5. **Kerentanan terbesar kita: rutin harus diisi dulu.** Aplikasi berbasis
   bank mendeteksi rutin sendiri dari riwayat. Kita harus menebusnya lewat
   chip pembuka, "Jadikan Rutin", saran dari pola riwayat dan notifikasi, serta
   suara.

## 2. Peta pesaing

| Lapis | Siapa | Kenapa relevan |
|---|---|---|
| **Langsung**: pencatat manual yang dipakai di Indonesia | Money Lover, Money Manager (Realbyte), Cashew, Wallet (BudgetBakers) | Dipakai orang yang sama dengan cara yang sama: mencatat sendiri. |
| **Tidak langsung**: perencanaan berbasis bank | YNAB, Simplifi, Monarch, PocketSmith, PocketGuard, Copilot, Rocket Money, Actual Budget | Menetapkan standar fitur rutin dan perkiraan. Tidak terhubung ke bank Indonesia. |
| **Bersebelahan** | Finku (Indonesia; terhubung bank, e-wallet, dan investasi; ada pengingat tagihan); aplikasi bank dan e-wallet (autodebet, menu tagihan) | Bisa menambah perencanaan kapan saja, dan sudah memegang datanya. |
| **Pengganti** | Spreadsheet (cara pemilik sebelumnya), alarm atau kalender, autodebet tanpa dicatat, "diingat saja" | Pesaing yang paling sering menang: tidak melakukan apa-apa. |

```
                      MELIHAT KE DEPAN (perkiraan)
                               │
              ┌ Tanukonomy  ┐  │   PocketSmith   Simplifi
              │  (sasaran)  │  │   Monarch
              └─────────────┘  │
  MANUAL ──────────────────────┼────────────────────── BERBASIS BANK
     Wallet   Money Lover      │   Copilot   PocketGuard
                               │   Rocket Money
     Cashew   Money Manager    │   Finku
     spreadsheet               │
                      MELIHAT KE BELAKANG (pencatatan)
```

Kuadran kiri atas belum diisi siapa pun.

## 3. Matriks fitur

Skala: **Kuat** (unggul dan dalam), **Cukup** (berfungsi, tidak istimewa),
**Lemah** (ada, tapi celahnya nyata), **Tidak ada**, **?** (belum
terverifikasi). Kolom Tanukonomy adalah **desain sasaran**, bukan keadaan
aplikasi sekarang. Rilis tempat kemampuan itu masuk ditulis dalam kurung.

### 3.1 Terhadap pencatat manual (pesaing langsung)

| Kemampuan | Money Lover | Money Manager | Cashew | Wallet | Tanukonomy (desain) |
|---|---|---|---|---|---|
| **Mengurangi lupa** | | | | | |
| Pengingat jatuh tempo | Cukup | ? | Cukup | Cukup | Kuat: kartu (R1), notifikasi sebelum jatuh tempo (R3) |
| Ditinjau sebelum tercatat | Lemah: transaksi berulang masuk sendiri; tagihan diatur terpisah | Tidak ada: tercatat sendiri pada tanggalnya | Cukup: "bayar saat siap" | ? | Kuat: bawaan ditinjau, satu ketuk, otomatis bila diminta |
| Dicocokkan dengan transaksi dari jalur lain | ? | Tidak ada | ? | ? | Kuat: notifikasi dan manual, ±3 hari (R1) |
| Memberi tahu bila kejadian **tidak** datang | Tidak ada | Tidak ada | Tidak ada | Tidak ada | Kuat: "belum terlihat di notifikasi" (R3) |
| **Efisiensi** | | | | | |
| Mengubah transaksi lama menjadi rutin | ? | ? | ? | Kuat | Kuat: "Jadikan Rutin" (R1) |
| Saran pola rutin | ? | ? | ? | Kuat | Cukup → Kuat: dari riwayat dan notifikasi (R3) |
| Nominal yang berubah-ubah | Kuat: konsep "Bills" terpisah | ? | ? | ? | Kuat: satu konsep, sakelar "bisa berubah" |
| N kali, cicilan | Kuat: For/Until/Forever | Kuat: cicilan dibagi per bulan | ? | ? | Kuat: plus progres k/N dan momen lunas |
| Dibuat lewat suara | Tidak ada | Tidak ada | Tidak ada | Tidak ada | Kuat: "tiap bulan", "12 kali" (R3) |
| **Wawasan** | | | | | |
| Perkiraan saldo | Cukup: tab FUTURE, saldo dompet jadi angka perkiraan | Lemah: rutin tampil baru pada tanggalnya | Tidak disebut | Cukup: saldo diharapkan dikurangi pembayaran terencana | Kuat: harian, titik terendah |
| Perkiraan ikut menghitung anggaran dan belanja harian | ? | Tidak ada | Tidak ada | ? | Kuat (R1) |
| Perkiraan per dompet | Cukup | ? | ? | ? | Kuat (R2) |
| Sisa setelah komitmen | ? | ? | ? | ? | Kuat: "Uang nganggur" (R1) |
| Total langganan per bulan dan per tahun | ? | ? | Kuat | ? | Setara (R1) |
| Deteksi kenaikan harga | Tidak ada | Tidak ada | Tidak ada | Tidak ada | Kuat: dari nominal tercatat dan notifikasi (R3) |
| **Konteks** | | | | | |
| Tanpa koneksi bank | Ya | Ya | Ya | Ya, bank opsional | Ya |

### 3.2 Terhadap aplikasi perencanaan (pesaing tidak langsung)

| Kemampuan | YNAB | Simplifi | Monarch | PocketSmith |
|---|---|---|---|---|
| Ditinjau sebelum tercatat | Kuat: Enter Now / Skip / disetujui saat tiba | Lewat bank | Cukup: centang sudah dibayar | Lewat bank |
| Hanya kemunculan berikutnya yang ditampilkan | Kuat | ? | ? | ? |
| Deteksi rutin otomatis | Tidak ada | Kuat, dari bank | Kuat, dari bank | ? |
| Pengingat | ? | Kuat | Kuat: 3 hari sebelumnya | Cukup: kalender |
| Perkiraan saldo | ? (bukan fokus produk) | Kuat: hingga 1 tahun | Kuat: beberapa bulan; Forecasting lanjutan di paket Plus | Kuat: harian, 6 bulan sampai 30 tahun menurut paket |
| Perkiraan ikut menghitung belanja yang direncanakan | — | **Lemah**: Planned Spending tidak ikut, dikeluhkan pengguna | ? | Kuat: dari anggaran yang dijadwalkan |
| Skenario "bagaimana kalau" | — | ? | ? | Kuat |
| Tanpa koneksi bank | Bisa akun manual | Bergantung bank | Bergantung bank | ? |
| Harga | Berlangganan | Berlangganan | Berlangganan ($14,99/bulan menurut ulasan) | Berlangganan, bertingkat |

Rujukan lain yang patut ditiru:

- **PocketGuard Leftover**: pemasukan dikurangi tagihan, anggaran, dan tujuan
  menabung, lalu diulang dari awal tiap tanggal 1. Padanannya di desain kita
  adalah "Uang nganggur".
- **Copilot**: menangkap perubahan harga dan bisa menjeda rutin. Perkiraan arus
  kas masih berupa permintaan pengguna di roadmap-nya.
- **Rocket Money**: memberi tahu kenaikan harga langganan bila naik lebih dari
  $1,99 **dan** lebih dari 5%. Ambang ganda ini mencegah peringatan karena
  selisih receh.
- **Actual Budget**: mencocokkan transaksi masuk dengan jadwal bila tanggalnya
  dalam ±2 hari, dan setiap jadwal bisa diatur masuk otomatis atau disetujui
  manual.
- **Money Lover**: memisahkan "Recurring Transactions" (nominal tetap, masuk
  sendiri) dari "Bills" (nominal disesuaikan dulu). Pengguna harus memilih
  konsep yang benar sejak awal. Desain kita memakai satu konsep dengan sakelar
  nominal "bisa berubah".

## 4. Posisi

| Produk | Untuk siapa | Klaim | Pembeda |
|---|---|---|---|
| Money Lover | Pencatat manual, pasar Asia termasuk Indonesia | Pengelola uang serba ada | Rutin plus tagihan, tab FUTURE |
| Money Manager | Pencatat manual yang suka rinci | Buku kas pribadi | Cicilan dicatat berbasis akrual |
| Cashew | Pencatat manual yang ingin gratis dan lokal | Pelacak anggaran dan pengeluaran | Jenis transaksi upcoming/subscription/repeating, gratis, open source |
| Simplifi / Monarch | Rumah tangga AS dengan banyak rekening | Gambaran keuangan lengkap | Deteksi otomatis dari bank, perkiraan saldo |
| PocketSmith | Perencana jangka panjang | Lihat masa depan keuanganmu | Kalender saldo harian, skenario, puluhan tahun |

**Usulan posisi Tanukonomy:**

> Untuk orang Indonesia yang mencatat keuangannya sendiri tanpa
> menghubungkan bank, Tanukonomy adalah buku catatan yang **mengingat yang
> rutin untukmu** dan **jujur soal bulan depan**: berapa yang benar-benar bebas,
> dan kapan uangmu paling tipis. Berbeda dari pencatat lain yang mencatat
> rutin diam-diam tanpa perkiraan, dan dari aplikasi perencanaan luar negeri
> yang butuh koneksi bank dan tidak menghitung belanja harian, angka
> Tanukonomy bisa dibongkar baris demi baris, dan seluruh datanya tetap di
> ponselmu.

Klaim yang **jangan** dipakai karena sudah diklaim semua pesaing: "tidak akan
lupa tagihan lagi", "kendalikan keuanganmu", dan "anggaran mudah".

## 5. Kekuatan dan kelemahan

| Pesaing | Kekuatan nyata | Kelemahan nyata |
|---|---|---|
| Money Lover | Jadwal lengkap (berapa kali, sampai tanggal, selamanya); tagihan dengan nominal yang disesuaikan; sudah dikenal di Indonesia | Dua konsep untuk satu kebutuhan; transaksi berulang masuk sendiri sehingga angka basi bisa lolos |
| Money Manager | Cicilan yang matang | Rutin tercatat otomatis pada tanggalnya; tidak terlihat sebelumnya kecuali setelan diubah |
| Cashew | Gratis, lokal, open source, Flutter; total langganan diekstrapolasi per bulan dan per tahun | Tidak ada perkiraan saldo yang dijelaskan |
| Wallet | Mengubah transaksi lama menjadi terencana dengan cepat; saran pola; saldo diharapkan | Kekuatan penuhnya bergantung koneksi bank, yang terbatas di Indonesia |
| YNAB | Alur setujui atau lewati yang paling rapi; hanya kemunculan berikutnya yang tampil | Bukan alat perkiraan; kurva belajar tinggi; berbayar |
| Simplifi | Perkiraan hingga 1 tahun, deteksi otomatis | Belanja yang direncanakan tidak ikut diperkirakan; laporan rutin terduplikasi di forum komunitas; hanya untuk bank AS dan Kanada |
| Monarch | Kalender rutin, centang sudah dibayar, pengingat 3 hari sebelumnya | Perkiraan lanjutan hanya di paket mahal; bergantung bank |
| PocketSmith | Perkiraan paling dalam (harian, skenario, puluhan tahun) | Rumit untuk pengguna biasa; berbayar bertingkat |

## 6. Peluang

| # | Celah | Bukti | Jawaban di desain |
|---|---|---|---|
| O1 | Perkiraan yang terlalu bagus merusak kepercayaan | Keluhan Planned Spending di komunitas Simplifi | Anggaran + rata-rata di luar rencana + "Dari mana angka ini" |
| O2 | Pencatat manual tidak punya perkiraan yang serius | Matriks §3.1 | Rencana bulan, titik terendah, per dompet |
| O3 | Rutin manual tidak tahu apakah kejadian sungguh terjadi | Tidak ada pesaing manual yang mencocokkan | Pencocokan dengan notifikasi; "belum terlihat" |
| O4 | Rutin yang tercatat diam-diam menghasilkan angka basi | Money Lover, Money Manager | Ditinjau secara bawaan, otomatis hanya untuk nominal tetap |
| O5 | Kerangka AS tidak cocok untuk Indonesia (gaji dua mingguan, bank AS) | Pesaing perencanaan berbasis bank AS | Bulan keuangan mulai tanggal gajian, chip pembuka lokal (BPJS, kos, cicilan, paylater, arisan, kiriman orang tua) |
| O6 | Cicilan diperlakukan seperti transaksi biasa | Matriks | Progres k/N, "bebas cicilan mulai …", momen lunas |
| O7 | Mencatat terasa sebagai beban dan sumber rasa bersalah | Riset personal informatics: biaya mencatat dan emosi negatif adalah alasan utama berhenti | Satu ketuk, cocok sendiri, nada tanpa menghakimi |

## 7. Ancaman dan kerentanan

| Ancaman | Kemungkinan | Dampak | Penangkal |
|---|---|---|---|
| Rutin harus diisi sendiri, sementara aplikasi bank mendeteksinya otomatis | Pasti | Tinggi: perkiraan kosong berarti tidak berguna | Chip pembuka, Jadikan Rutin, saran pola dari riwayat dan notifikasi, suara |
| Catat dari notifikasi hanya ada di Android | Pasti | Pengguna iOS tidak mendapat pencocokan otomatis | Di iOS cukup kartu dan pengingat; jangan menjanjikan pencocokan di materi iOS |
| Format notifikasi bank berubah dan pencocokan meleset diam-diam | Sedang | Kemunculan tidak terkonfirmasi | Tetap ada jalur manual; "belum terlihat" berbunyi sebagai pertanyaan, bukan vonis |
| Money Lover atau Cashew menambah perkiraan | Sedang | Pembeda O2 menipis | Pembeda yang lebih sulit ditiru: O1, O3, O5 |
| Finku atau aplikasi bank menambah perkiraan berbasis data bank | Rendah sampai sedang | Tinggi untuk pengguna yang rela menghubungkan bank | Posisi privasi: tanpa kredensial bank, data di perangkat |
| Perkiraan meleset jauh di bulan pertama | Sedang | Kepercayaan runtuh | "Di luar rencana" baru tampil sesudah ada riwayat sebulan; akurasi bulan lalu ditampilkan jujur |
| Rutin terduplikasi atau angka ganda (dilaporkan di Simplifi dan Budget Flow) | Sedang | Tinggi | Invarian satu kemunculan untuk paling banyak satu transaksi; status diturunkan, tidak disimpan ganda |

## 8. Implikasi strategis

**Berbeda di sini, lima hal yang sulit ditiru pesaing:**

1. **Perkiraan jujur**: anggaran, belanja di luar rencana, dan bebas hitung
   ganda, dengan setiap angka bisa dibongkar (O1, O2).
2. **Rutin yang terkonfirmasi sendiri**: dicocokkan dengan catat dari
   notifikasi. Sekaligus mendeteksi autodebet yang tidak datang dan kenaikan
   harga, tanpa koneksi bank (O3).
3. **Pengingat yang tahu saldo**: pengingat sebelum jatuh tempo memakai
   perkiraan per dompet ("saldo BCA kurang untuk cicilan besok"), bukan
   sekadar "tagihan besok" (O2, O3).
4. **Konteks Indonesia**: bulan keuangan dimulai tanggal gajian, chip pembuka
   lokal, cicilan dan paylater sebagai warga kelas satu, kalimat yang
   mencatat, bukan membayar (O5, O6).
5. **Hambatan nyaris nol tanpa angka basi**: satu ketuk, cocok sendiri, suara,
   dan otomatis hanya untuk nominal tetap (O4, O7).

**Cukup setara:** pengingat, lewati, N kali dan sampai tanggal, jeda, nominal
yang bisa berubah, Jadikan Rutin, total langganan per bulan dan per tahun,
saran pola.

**Jangan dibangun:**

- Koneksi bank, autodebet, atau "bayar sekarang". Itu di luar definisi produk.
- Perkiraan puluhan tahun dan bunga majemuk ala PocketSmith. Itu bukan
  pekerjaan pengguna sasaran.
- Streak harian yang menghukum hari kosong. Rasa bersalah termasuk alasan
  orang berhenti mencatat.
- Nasihat keuangan atau skor kesehatan keuangan dari AI.

**Pantau:** perkiraan di Money Lover dan Cashew (catatan rilis), fitur
perencanaan di Finku dan aplikasi bank besar, dan perkembangan open API
perbankan Indonesia.

Rinciannya diterjemahkan ke desain di
[RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md) §3A (posisi), §7A
(penjagaan kesalahan), dan §7B (wawasan).

## Sumber

Diakses 2 Oktober 2026.

- Money Lover: [Set up recurring transactions](https://note.moneylover.me/how-to-add-frequently-incurred-transactions), [Manage recurring transactions and bills](https://note.moneylover.me/manage-recurring-transaction-bills/)
- Money Manager (Realbyte): [How to set up a repeat schedule / installment](https://help.realbyteapps.com/hc/en-us/articles/360046668993-How-to-set-up-a-repeat-schedule-installment)
- Cashew: [Repositori GitHub](https://github.com/jameskokoska/Cashew), [catatan rilis 6.x di APKMirror](https://www.apkmirror.com/apk/dapper-app-developer/cashew-expense-budget-tracker)
- Wallet (BudgetBakers): [Planned payments](https://budgetbakers.com/planned-payments)
- YNAB: [Scheduled Transactions: A Guide](https://support.ynab.com/en_us/scheduled-transactions-a-guide-BygrAIFA9)
- Simplifi: [Projected Cash Flow](https://quicken.com/features/projected-cashflow), [Using projected cash flow](https://support.simplifi.quicken.com/en/articles/3357429-using-projected-cash-flow), [Managing recurring transactions](https://support.simplifi.quicken.com/en/articles/3625912-managing-recurring-transactions), [Permintaan komunitas: Planned Spending di perkiraan](https://community.simplifimoney.com/discussion/comment/7841), [Cash Flow is DANGEROUS without all planned spending](https://community.simplifimoney.com/discussion/comment/17618), [Laporan rutin terduplikasi](https://community.simplifimoney.com/discussion/14727/recurring-series-income-and-bills-subscriptions-are-duplicated-in-the-mobile-app-edited)
- Monarch: [Track recurring bills and subscriptions](https://www.monarchmoney.com/whats-new/track-recurring-bills-and-subscriptions), [Ulasan The Penny Hoarder](https://www.thepennyhoarder.com/budgeting/monarch-money-review/)
- PocketSmith: [Cash flow forecasts](https://www.pocketsmith.com/tour/cash-flow-forecasts/), [Budgets and planning](https://www.pocketsmith.com/features/budgets-and-planning)
- PocketGuard: [Leftover](https://pocketguard.com/help/leftover)
- Copilot: [Create recurrings](https://help.copilot.money/en/articles/3760068-create-recurrings), [Permintaan perkiraan arus kas](https://feedback.copilot.money/feature-requests/p/income-vs-expenses-cash-flow-graph)
- Rocket Money: [Subscription price increase](https://www.rocketmoney.com/learn/personal-finance/is-there-an-app-that-can-tell-me-when-my-subscription-price-increased)
- Actual Budget: [Schedules](https://actualbudget.org/docs/schedules)
- Finku: [Bisnis.com, Finku mudahkan milenial atur keuangan](https://teknologi.bisnis.com/read/20211215/266/1477961/finku-mudahkan-milenial-atur-keuangan)
- Budget Flow: [Laporan bug rutin merusak perkiraan](https://budgetflow.featurebase.app/p/bug-recurring-transactions-corrupt-forecastdatabase-and-incorrect-balances-return-after)
- Riset alasan berhenti mencatat: [Epstein dkk., Beyond Abandonment to Next Steps (PMC5428074)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5428074/)
