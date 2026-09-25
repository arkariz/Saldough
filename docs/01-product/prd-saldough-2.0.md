# Product Requirements Document: Saldough 2.0

## 1. Ringkasan

Saldough adalah aplikasi Flutter untuk Android dan iOS untuk **mencatat,
memahami, dan mengelola keuangan pribadi** berdasarkan aktivitas keuangan yang
benar-benar terjadi. Intinya tiga hal: **di mana uang berada**, **apa yang
terjadi padanya**, dan **ke mana ia direncanakan pergi**.

Alurnya satu kalimat:

```
Rencanakan  →  Catat  →  Pahami
  Anggaran      CATAT     Beranda
```

Pengguna merencanakan penggunaan uang lewat **Anggaran**, mencatat kejadian
finansial lewat **CATAT**, mengetahui posisi uangnya lewat **Dompet**, dan
melacak pekerjaan freelance yang sudah dikerjakan tetapi belum dibayar lewat
**Worklog**.

| | |
|---|---|
| **Nama produk** | Saldough |
| **Platform** | Android dan iOS |
| **Versi dokumen** | 2.0 |
| **Status** | Draf, menunggu implementasi |
| **Jenis produk** | Pengelolaan keuangan pribadi |
| **Pengguna sasaran** | Perorangan |
| **Bahasa utama** | Indonesia |
| **Pemilik** | muhammadrisky1401@gmail.com |
| **Terakhir diperbarui** | 17 September 2026 |

> **Catatan versi (17 September 2026):** Dokumen ini menggantikan
> [PRD 1.0](prd-saldough-1.0.md), bukan memperbaruinya. Saldough 1.0 adalah
> pengganti digital sistem empat Google Spreadsheet milik pemilik: produknya
> berporos pada siklus bulanan, rollover antar bulan, dan baris roll-up. Produk
> itu tidak dilanjutkan. PRD 1.0 tetap ada di tempatnya sebagai rekaman
> sejarah, dan seluruh identitas `FR-CYCLE`, `FR-TPL`, `FR-GROC`, `FR-CARD`,
> dan `FR-INV` di dalamnya tidak lagi berlaku.

> **Catatan perluasan (17 September 2026):** Versi pertama dokumen ini ditulis
> untuk **satu pengguna**, yaitu pemilik. Atas arahan pemilik, dokumen ini
> sekarang ditulis **setingkat produk**: kebutuhannya dinyatakan untuk pengguna
> perorangan pada umumnya, supaya PRD bisa menjadi sumber tunggal untuk desain
> antarmuka, pengembangan, dan validasi cakupan. Pemilik tetap menjadi pengguna
> pertama dan satu-satunya penguji MVP. Konsekuensi yang belum selesai dari
> perluasan ini dicatat jujur di [§3](#ukuran-keberhasilan) dan
> [§13](#13-pertanyaan-terbuka), bukan disembunyikan.

Saldough **mencatat**, bukan **melakukan**. Aplikasi ini tidak memindahkan uang,
tidak membayar, tidak menarik atau menyetor dana, dan tidak terhubung ke bank
mana pun. Ketika pengguna mencatat transfer dari BCA ke GoPay, yang terjadi
adalah dua angka di dalam aplikasi berubah — bukan sebuah transaksi perbankan.
Batasan ini bukan kekurangan teknis melainkan definisi produk, dan seluruh
kosakata antarmuka harus mencerminkannya.

## 2. Pernyataan masalah

Pengelolaan keuangan pribadi tercecer di banyak tempat sekaligus. Saldo
rekening harus diingat atau dicek satu per satu; pengeluaran dicatat manual
tetapi dampaknya terhadap rencana tidak kelihatan; riwayat transaksi ada
tetapi tidak bisa dipakai untuk memahami keadaan dengan cepat.

Empat masalah muncul berulang:

- **Uang tersebar, posisinya tidak pernah utuh.** Rekening bank, tunai, dompet
  digital, dan tabungan masing-masing punya angkanya sendiri, dan tidak ada
  satu tempat yang menjumlahkannya.
- **Anggaran disalahpahami sebagai uang yang sudah dipisahkan.** Membuat
  anggaran belanja Rp3.000.000 terasa seperti menyisihkan Rp3.000.000, padahal
  uangnya masih utuh di rekening. Aplikasi yang mengaburkan beda ini membuat
  penggunanya merasa lebih kaya daripada kenyataan.
- **Penghasilan freelance yang sudah dikerjakan tercampur dengan yang sudah
  diterima.** Pekerjaan senilai Rp1.800.000 yang baru dibayar akhir bulan bukan
  uang yang bisa dipakai hari ini, tetapi banyak pencatatan memperlakukan
  keduanya sama.
- **Mencatat terasa merepotkan.** Kalau pencatatan menuntut pengguna tahu lebih
  dulu di layar mana ia harus berada, kebiasaan mencatatnya berhenti — dan
  begitu berhenti, seluruh fitur lain kehilangan nilainya.

Akibatnya pertanyaan yang paling sederhana justru paling sulit dijawab:

- Berapa uang saya sekarang?
- Bulan ini saya sudah menerima berapa, dan menghabiskan berapa?
- Anggaran mana yang hampir habis?
- Uang saya ada di mana?
- Berapa penghasilan freelance yang sudah saya kerjakan tetapi belum diterima?

> **Asal usul.** Masalah di atas ditemukan lewat pengalaman pemilik mengelola
> keuangannya dengan empat Google Spreadsheet yang saling mereferensi manual,
> lalu dengan Saldough 1.0 yang menirunya persis. Pendekatan itu memecahkan
> pencatatan bulanan tetapi tidak punya konsep saldo maupun transaksi, sehingga
> tiga masalah pertama tidak bisa diselesaikan dari dalam modelnya sendiri.
> Rekamannya ada di
> [analisis proses manual](../00-foundation/MANUAL_PROCESS_ANALYSIS.md).

## 3. Tujuan dan ukuran keberhasilan

### Tujuan utama

Memberi pengguna **gambaran keadaan keuangan pribadi yang jelas dan mudah
dipahami**, tanpa spreadsheet dan tanpa pencatatan yang rumit.

### Tujuan turunan

- Menjawab "berapa uang saya, dan di mana" dalam satu layar, kapan saja.
- Membuat pencatatan satu transaksi memakan waktu di bawah sepuluh detik, lewat
  satu titik masuk yang selalu sama.
- Membantu pengguna mengendalikan pengeluaran lewat anggaran, tanpa pernah
  menyiratkan anggaran memisahkan uang.
- Memisahkan dengan tegas antara uang yang **ada**, uang yang
  **direncanakan**, dan uang yang **sudah dikerjakan tetapi belum diterima**.
- Memberi rasa kemajuan terhadap keadaan keuangan, bukan sekadar daftar angka.
- Tetap berguna tanpa koneksi internet dan tanpa akun.

### Ukuran keberhasilan

Ukuran yang dipakai adalah **ukuran perilaku**, bukan ukuran kesombongan.
Pertanyaannya bukan berapa banyak layar yang dibuka, melainkan apakah pencatatan
menjadi kebiasaan.

| Ukuran | Definisi |
|---|---|
| Aktivasi | Pengguna mencatat transaksi pertamanya |
| Frekuensi pencatatan | Jumlah transaksi yang dicatat per pengguna aktif per minggu |
| Adopsi anggaran | Pengguna membuat sedikitnya satu anggaran |
| Keterlibatan anggaran | Pengguna kembali membuka progres anggarannya |
| Adopsi freelance | Pengguna memakai worklog atau pelacakan pembayaran |
| Retensi | Pengguna masih aktif pada hari ke-7 dan hari ke-30 |

Isyarat produk yang paling menentukan:

> **Apakah pengguna kembali untuk mencatat transaksi secara rutin?**

Kalau kebiasaan mencatat tidak terbentuk, fitur lain kehilangan nilainya.

⚠ **Ukuran ini belum bisa diukur lintas pengguna di MVP, dan itu disengaja.**
NFR-SEC-001 melarang panggilan jaringan sama sekali, dan MVP tidak punya akun
maupun backend — sehingga tidak ada telemetri yang bisa menghitung "persentase
pengguna". Di MVP keenam ukuran itu dinilai pada **pemakaian pemilik sendiri**,
diamati langsung. Menambahkan telemetri berarti membatalkan NFR-SEC-001, dan
itu keputusan pemilik, bukan keputusan yang boleh diambil diam-diam saat
menulis kode. Pertanyaannya terbuka di [§13](#13-pertanyaan-terbuka).

### Ukuran keberhasilan MVP

Sampai telemetri diputuskan, MVP dinyatakan berhasil kalau:

- Pemilik memakai Saldough sebagai satu-satunya catatan keuangannya selama satu
  bulan penuh tanpa kembali ke spreadsheet.
- Saldo tercatat tiap dompet cocok dengan saldo sebenarnya di akhir bulan, tanpa
  penyesuaian manual.
- Seluruh pencatatan transaksi berjalan lewat satu alur yang sama.
- Tidak ada satu pun selisih rupiah antara nominal yang dicatat dan nominal yang
  ditampilkan.

## 4. Pengguna sasaran

### Pengguna utama

Perorangan yang ingin mengelola keuangan pribadinya secara manual — karyawan,
pekerja lepas, pengembang, mahasiswa, profesional muda, atau keluarga kecil.
Yang menyatukan mereka bukan profesinya melainkan keadaannya: uangnya ada di
beberapa tempat, sebagian penghasilannya tidak datang di tanggal yang pasti,
dan ia mau mencatat asal mencatatnya tidak merepotkan.

Ciri-ciri yang diasumsikan produk ini:

- punya beberapa rekening bank, uang tunai, dompet digital, dan tabungan;
- punya penghasilan tetap, penghasilan lepas, atau keduanya;
- menjalankan beberapa anggaran sekaligus, dengan periode yang tidak selalu
  sama;
- terbiasa dengan aplikasi ponsel, tidak terbiasa dengan akuntansi.

### Pengguna pertama

Pemilik aplikasi, yang mengelola keuangannya sendiri dengan dua sumber
penghasilan (gaji tetap dan freelance per jam) dan menyimpan uang di beberapa
tempat sekaligus. Ia adalah satu-satunya pengguna MVP dan satu-satunya penguji
[ukuran keberhasilan](#ukuran-keberhasilan) di atas.

### Bukan pengguna sasaran

Pelaku usaha yang butuh pembukuan, tim yang butuh keuangan bersama, dan siapa
pun yang mengharapkan aplikasi ini terhubung ke rekeningnya. Peran kedua di satu
akun baru relevan kalau sinkronisasi antar perangkat dikerjakan, dan itu di luar
MVP.

### Kasus penggunaan utama

- Mencatat pengeluaran sesaat setelah terjadi, sambil berdiri di kasir.
- Memeriksa sisa anggaran sebelum memutuskan membeli sesuatu.
- Memindahkan catatan uang antar dompet setelah melakukan transfer sungguhan.
- Mencatat jam kerja freelance di akhir hari.
- Mencatat bahwa pembayaran freelance akhirnya cair.
- Melihat gambaran bulan berjalan: masuk berapa, keluar berapa, sisa berapa.

## 5. Proposisi nilai

Saldough menjawab pertanyaan yang tidak bisa dijawab spreadsheet: berapa uang
yang ada sekarang, di mana, dan apa saja yang sudah terjadi padanya. Ia
melakukannya tanpa backend, tanpa akun, tanpa koneksi bank, dan tanpa
mengirimkan satu byte pun ke luar perangkat.

Dua pembeda terhadap aplikasi keuangan umum:

- **Anggaran dinyatakan sebagai rencana, bukan pemesanan uang.** Membuat
  anggaran tidak pernah mengubah saldo dompet mana pun, dan antarmuka tidak
  pernah menyiratkan sebaliknya.
- **Penghasilan yang sudah dikerjakan dipisahkan dari yang sudah diterima.**
  Pembedaan ini penting bagi pekerja lepas dan biasanya tidak tersedia di
  aplikasi sejenis.

### Prinsip produk

Lima kalimat yang menjadi tulang produk ini. Setiap keputusan fitur diukur
terhadapnya.

1. **Ketahui di mana uangmu.** Dompet menjawab posisi uang.
2. **Ketahui apa yang terjadi.** Transaksi menjawab kejadian finansial.
3. **Ketahui ke mana uang direncanakan pergi.** Anggaran menjawab rencana.
4. **Ketahui apa yang sudah kamu peroleh.** Worklog freelance menjawab
   penghasilan yang sudah dikerjakan.
5. **Jaga hambatan mencatat tetap rendah.** CATAT membuat pencatatan jadi
   tindakan utama yang selalu satu ketukan jauhnya.

## 6. Cakupan MVP

### Termasuk dalam MVP

- Dompet: buat, sunting, saldo awal, saldo tercatat, riwayat per dompet.
- Transaksi: pemasukan, pengeluaran, transfer, daftar, rincian, penyaring,
  sunting, hapus.
- Alur CATAT sebagai titik masuk tunggal pencatatan manual.
- Anggaran: beberapa anggaran aktif sekaligus, pos anggaran, progres, status,
  penyaring, dan template dasar.
- Freelance: proyek, worklog, pembayaran, dan pencatatan pembayaran diterima.
- Beranda sebagai ringkasan, beserta keadaan kosongnya.
- Terang dan gelap, bahasa Indonesia dan Inggris.

### Di luar MVP

- Sinkronisasi bank, impor transaksi otomatis, dan pemrosesan pembayaran.
- Kartu kredit sebagai dompet liabilitas. Modelnya menampungnya tanpa konsep
  tambahan, tetapi tidak dikerjakan sekarang.
- Impor data historis dari Saldough 1.0. Aplikasi mulai dari saldo awal.
- Investasi, pelacakan utang, laporan tahunan, analitik lanjutan, dan
  akuntansi.
- Multi-mata-uang, akun bersama, sinkronisasi antar perangkat.
- Transaksi berulang otomatis.
- Pemindaian struk, ekspor-impor data, dan asisten keuangan berbasis AI.

**Template freelance** ([FR-FRL-006](#75-freelance)) termasuk dalam dokumen ini
tetapi **bukan bagian dari MVP wajib**. Ia dikerjakan di Fase 7 bersama template
anggaran, setelah lingkaran inti terbukti berjalan.

### Definisi selesai MVP

MVP dianggap cukup untuk dirilis ketika satu lingkaran penuh bisa dijalankan
dari awal sampai akhir, dan tiap langkahnya menggerakkan angka persis seperti
yang dijanjikan model:

```
Buat dompet
      ↓
Catat pemasukan          →  saldo dompet naik
      ↓
Buat anggaran            →  saldo dompet TIDAK berubah
      ↓
Catat pengeluaran        →  saldo dompet turun, terpakai anggaran naik
      ↓
Catat transfer           →  dompet A turun, dompet B naik, total tetap
      ↓
Catat worklog freelance  →  diperoleh naik, saldo dompet TIDAK berubah
      ↓
Catat pembayaran         →  saldo dompet naik tepat satu kali,
                            pembayaran jadi sudah dibayar
```

Lingkaran inilah produknya. Fitur lain tidak boleh mengganggu atau memperumit
lingkaran ini; kalau sebuah fitur membuat salah satu langkah di atas terasa
lebih berat, fitur itu yang salah tempat.

## 7. Kebutuhan fungsional

### 7.1 Dompet

**FR-WAL-001 — Mengelola daftar dompet**

- [ ] Menambah dompet dengan nama, ikon, dan saldo awal.
- [ ] Menyunting nama dan ikon dompet tanpa mengubah saldo tercatatnya.
- [ ] Menandai dompet tidak aktif supaya tidak muncul di pemilih dompet, tanpa
      menghapus transaksinya.
- [ ] Menghapus dompet hanya kalau belum punya transaksi sama sekali, dengan
      konfirmasi.

**FR-WAL-002 — Menetapkan saldo awal**

- [ ] Menerima saldo awal saat dompet dibuat, boleh nol.
- [ ] Memperlakukan saldo awal sebagai pernyataan keadaan, bukan transaksi
      setoran, sehingga ia tidak muncul di riwayat transaksi.
- [ ] Mengizinkan saldo awal disunting belakangan, dan menghitung ulang saldo
      tercatat saat itu juga.

**FR-WAL-003 — Menampilkan saldo**

- [ ] Menampilkan seluruh dompet aktif beserta saldo tercatatnya.
- [ ] Menampilkan total saldo seluruh dompet aktif.
- [ ] Menampilkan saldo negatif dengan warna `expense` dan tanda minus, bukan
      sebagai kesalahan.

**FR-WAL-004 — Menampilkan rincian satu dompet**

- [ ] Menampilkan nama, ikon, dan saldo tercatat dompet.
- [ ] Menampilkan transaksi terbaru dompet itu.
- [ ] Menyediakan jalan ke daftar transaksi lengkap yang sudah tersaring ke
      dompet itu.
- [ ] Menyediakan pintasan ke CATAT dengan dompet ini sudah terpilih.

### 7.2 Transaksi

**FR-TXN-001 — Mencatat pemasukan**

- [ ] Menerima nominal, dompet tujuan, tanggal, kategori, dan catatan opsional.
- [ ] Menambah saldo dompet tujuan sebesar nominal yang dicatat.
- [ ] Menolak nominal nol atau negatif.

**FR-TXN-002 — Mencatat pengeluaran**

- [ ] Menerima nominal, dompet asal, tanggal, kategori, dan catatan opsional.
- [ ] Menerima tautan opsional ke satu pos anggaran.
- [ ] Mengurangi saldo dompet asal sebesar nominal yang dicatat.
- [ ] Mengizinkan saldo dompet menjadi negatif, dan menampilkannya apa adanya.
- [ ] Menawarkan hanya pos anggaran yang dompetnya sama dengan dompet asal.

**FR-TXN-003 — Mencatat transfer**

- [ ] Menerima dompet asal, dompet tujuan, nominal, tanggal, dan catatan.
- [ ] Mengurangi saldo dompet asal dan menambah saldo dompet tujuan dengan
      nominal yang sama.
- [ ] Tidak mengubah total saldo seluruh dompet.
- [ ] Menolak transfer ke dompet yang sama dengan asalnya.
- [ ] Menyatakan dengan jelas bahwa ini transfer yang dicatat, bukan transfer
      yang dijalankan aplikasi.

**FR-TXN-004 — Menampilkan riwayat transaksi**

- [ ] Menampilkan seluruh transaksi terurut dari yang terbaru, dikelompokkan per
      tanggal.
- [ ] Menyediakan penyaring jenis: semua, pemasukan, pengeluaran, transfer.
- [ ] Menyediakan penyaring dompet dan kategori.
- [ ] Menampilkan jenis, judul atau kategori, dompet, nominal, dan tanggal untuk
      tiap transaksi.
- [ ] Membedakan pemasukan, pengeluaran, dan transfer secara visual.

**FR-TXN-005 — Menyunting dan menghapus transaksi**

- [ ] Menyunting seluruh field transaksi, termasuk dompet dan nominalnya.
- [ ] Menghitung ulang saldo dompet yang terdampak setelah penyuntingan,
      termasuk saat dompetnya berpindah.
- [ ] Menghapus transaksi dengan konfirmasi, dan mengembalikan saldo dompet ke
      keadaan sebelum transaksi itu ada.

**FR-TXN-006 — Menampilkan rincian satu transaksi**

- [ ] Menampilkan jenis, nominal, kategori, dompet, tanggal, dan catatan.
- [ ] Menampilkan anggaran dan pos anggaran yang tertaut, kalau ada, beserta
      jalan ke anggaran itu.
- [ ] Menampilkan transfer sebagai pasangan asal dan tujuan — "Dari", "Ke",
      "Jumlah" — dengan judul **Transfer tercatat**.
- [ ] Tidak memakai kosakata yang menyiratkan aplikasi menjalankan transaksi,
      seperti "Transfer berhasil", "Pembayaran berhasil", atau "Kirim Uang".
- [ ] Menyediakan aksi sunting dan hapus untuk transaksi itu.

### 7.3 Alur CATAT

**FR-REC-001 — Titik masuk tunggal pencatatan**

- [ ] Menyediakan tombol CATAT di navigasi bawah, dibedakan secara visual dari
      tujuan navigasi biasa.
- [ ] Menawarkan tiga pilihan saat dibuka: catat pemasukan, catat pengeluaran,
      catat transfer.
- [ ] Menjadi satu-satunya jalur pembuatan transaksi manual, sehingga tidak ada
      formulir pencatatan tersendiri di Beranda, Dompet, Transaksi, Anggaran,
      maupun Freelance.

**FR-REC-002 — Pintasan kontekstual**

- [ ] Menyediakan pintasan dari layar lain yang membuka CATAT dengan field
      terkait sudah terisi, misalnya dompet dari layar rincian dompet atau pos
      anggaran dari layar anggaran.
- [ ] Memakai alur, validasi, dan entitas yang sama persis dengan CATAT biasa.

### 7.4 Anggaran

**FR-BUD-001 — Mengelola beberapa anggaran aktif**

- [ ] Membuat anggaran dengan nama, dompet, periode, dan minimal satu pos.
      Nominal rencananya adalah jumlah pos
      ([ADR-017](../02-architecture/adr/0017-rencana-anggaran-adalah-jumlah-pos.md)).
- [ ] Mengizinkan beberapa anggaran aktif sekaligus tanpa mengharuskan yang lama
      ditutup lebih dulu.
- [ ] Mengizinkan beberapa anggaran berbagi satu dompet.
- [ ] Mengizinkan anggaran berbeda punya periode berbeda.
- [ ] Mengarsipkan dan mengaktifkan kembali anggaran tanpa menghapus transaksi
      yang sudah tertaut padanya.
- [ ] **Tidak mengubah saldo dompet mana pun saat anggaran dibuat, disunting,
      diarsipkan, atau dihapus.**

**FR-BUD-002 — Mengelola pos anggaran**

- [ ] Menambah, menyunting, dan menghapus pos di dalam satu anggaran.
- [ ] Menerima nominal rencana per pos.
- [ ] Menerima jumlah dan harga satuan opsional untuk pos yang berupa daftar
      belanja, dan menghitung nominal rencananya dari keduanya.
- [ ] Menampilkan nominal rencana anggaran sebagai jumlah seluruh pos, yang
      ikut berubah setiap kali pos ditambah, disunting, atau dihapus.
      (Menggantikan kriteria "selisih antara jumlah pos dan nominal rencana
      anggaran" — dicabut ADR-017.)

**FR-BUD-003 — Menautkan transaksi ke pos anggaran**

- [ ] Menautkan satu pengeluaran ke paling banyak satu pos anggaran berjenis
      pengeluaran.
- [ ] Menautkan satu transfer ke paling banyak satu pos anggaran berjenis
      transfer, yang dompet tujuannya sama dengan dompet tujuan transfer itu
      ([ADR-018](../02-architecture/adr/0018-jenis-pos-anggaran.md)).
- [ ] Menghitung `spent` sebuah pos dari transaksi yang tertaut padanya, bukan
      dari nilai yang disimpan.
- [ ] Hanya menghitung pengeluaran yang `walletId`-nya sama dengan dompet
      anggaran, dan transfer yang `fromWalletId`-nya sama dengan dompet
      anggaran dan `toWalletId`-nya sama dengan dompet tujuan pos.
- [ ] Memastikan satu transaksi menaikkan paling banyak satu pos anggaran,
      supaya tidak terhitung ganda.
- [ ] Memperbarui progres seketika saat transaksi dicatat, disunting, atau
      dihapus.

**FR-BUD-004 — Menampilkan Ikhtisar Anggaran**

Ini layar daftar, dicapai dari navigasi bawah.

- [ ] Menampilkan ringkasan lintas seluruh anggaran aktif di puncak layar:
      total rencana, total terpakai, dan total sisa.
- [ ] **Menampilkan daftar seluruh anggaran, bukan papan satu anggaran.**
- [ ] Menampilkan pada tiap kartu anggaran: nama, dompet, periode, nominal
      rencana, terpakai, sisa, progres, dan status.
- [ ] Menampilkan anggaran yang lewat anggaran dengan warna `overBudget`, bukan
      sebagai kesalahan.
- [ ] Membuka rincian anggaran saat sebuah kartu ditekan.

**FR-BUD-005 — Template anggaran**

- [ ] Membuat, menyunting, menggandakan, mengaktifkan, menonaktifkan, dan
      menghapus template.
- [ ] Membuat anggaran aktif baru dari sebuah template.
- [ ] Memperlakukan anggaran hasil template sebagai anggaran mandiri yang
      perubahannya tidak memengaruhi templatenya.
- [ ] Tidak mengubah saldo dompet mana pun saat template dibuat atau disunting.

**FR-BUD-006 — Menyaring daftar anggaran**

- [ ] Menyaring anggaran berdasarkan status: semua, aktif, selesai, atau
      nonaktif.
- [ ] Menyaring anggaran berdasarkan dompet.
- [ ] Menjaga penyaringnya tetap sederhana — daftar dan pilihan, bukan
      antarmuka akuntansi.

**FR-BUD-007 — Menampilkan rincian satu anggaran**

- [ ] Menampilkan nama, dompet, periode, nominal rencana, terpakai, sisa, dan
      progres anggaran itu.
- [ ] Menampilkan seluruh pos anggaran beserta nominal rencana, terpakai, sisa,
      dan progresnya masing-masing.
- [ ] Menampilkan status tiap pos: belum terpakai, terpakai sebagian, selesai,
      atau lewat anggaran.
- [ ] Menampilkan pos yang lewat anggaran dengan warna `overBudget`, bukan
      sebagai kesalahan.
- [ ] Menyediakan satu pintasan di tiap pos sesuai jenisnya — **Catat
      Pengeluaran** atau **Catat Transfer** — yang membuka CATAT dengan dompet,
      pos, sisa nominal, dan (untuk pos transfer) dompet tujuan sudah terisi —
      bukan formulir pencatatan tersendiri. Tidak ada pintasan di tingkat
      anggaran, karena transaksi tanpa pos tidak terhitung (ADR-018).
- [ ] Menampilkan transaksi yang sudah tertaut ke anggaran itu.

### 7.5 Freelance

**FR-FRL-001 — Mengelola proyek freelance**

- [ ] Menambah, menyunting, dan menghapus proyek beserta tarif per jamnya.
- [ ] Mengelola aturan potongan tiap proyek, baik per mil maupun nominal tetap.

**FR-FRL-002 — Mencatat worklog**

- [ ] Mencatat entri kerja berisi proyek, tanggal, jumlah jam, dan catatan
      opsional.
- [ ] Menghitung nominal yang diperoleh dari jam dikali tarif per jam, dan
      menampilkan tarif yang dipakai di entri itu.
- [ ] Menampilkan tanggal pembayaran, dompet tujuan, dan status pembayaran entri
      itu kalau ia sudah masuk ke sebuah pembayaran.
- [ ] Menyunting dan menghapus entri yang belum masuk pembayaran.
- [ ] **Tidak mengubah saldo dompet mana pun.**

**FR-FRL-003 — Mengelompokkan worklog jadi pembayaran**

- [ ] Menggabungkan beberapa entri worklog jadi satu pembayaran.
- [ ] Menghitung gaji kotor, seluruh potongan, dan gaji bersih pembayaran itu.
- [ ] Menerima tanggal pembayaran yang diperkirakan.
- [ ] Tidak mengharuskan pembayaran mengikuti batas bulan kalender.

**FR-FRL-004 — Mencatat pembayaran diterima**

- [ ] Mencatat bahwa sebuah pembayaran benar-benar diterima, beserta dompet
      tujuannya.
- [ ] Membuat tepat satu transaksi pemasukan sebesar gaji bersih.
- [ ] Menambah saldo dompet tujuan tepat satu kali.
- [ ] Menandai pembayaran itu sudah dibayar, dan mencegahnya dicatat dua kali.
- [ ] Menyatakan dengan jelas bahwa ini pencatatan pembayaran, bukan pembayaran
      yang dijalankan aplikasi.

**FR-FRL-005 — Ikhtisar Freelance**

- [ ] Menyediakan satu layar Ikhtisar Freelance dengan tiga tab: Worklog sebagai
      tab bawaan, Pembayaran, dan Template.
- [ ] Menyembunyikan tab Template sampai FR-FRL-006 dikerjakan di Fase 7,
      sehingga MVP hanya menampilkan dua tab.
- [ ] Menampilkan total jam kerja, nominal yang diperoleh, yang sudah dibayar,
      dan yang belum dibayar.
- [ ] Menampilkan daftar pembayaran beserta status dan tanggalnya.
- [ ] **Dicapai dari dua titik masuk yang keduanya mendarat di layar yang
      sama:** ringkasan di Beranda, dan CATAT → Catat Pemasukan → Freelance.
- [ ] Bukan tujuan navigasi bawah.

**FR-FRL-006 — Template freelance**

Di luar MVP wajib; dikerjakan di Fase 7 bersama template anggaran.

- [ ] Menyimpan struktur kerja berulang berisi proyek atau klien, tarif per jam,
      dompet bawaan, jadwal pembayaran, dan penanda aktif atau nonaktif.
- [ ] Membuat, menyunting, menggandakan, mengaktifkan, menonaktifkan, dan
      menghapus template.
- [ ] Membuat proyek freelance baru dari sebuah template.
- [ ] **Tidak mengubah saldo dompet mana pun saat template dibuat atau
      disunting.**

### 7.6 Beranda

**FR-HOME-001 — Ringkasan saldo dan arus bulan berjalan**

- [ ] Menampilkan total saldo seluruh dompet aktif.
- [ ] Menampilkan total pemasukan bulan berjalan.
- [ ] Menampilkan total pengeluaran bulan berjalan.
- [ ] Tidak menghitung transfer sebagai pemasukan maupun pengeluaran.

**FR-HOME-002 — Ringkasan anggaran**

- [ ] Menampilkan total nominal rencana, total terpakai, dan total sisa seluruh
      anggaran aktif.
- [ ] Menyediakan jalan ke layar Anggaran.

**FR-HOME-003 — Ringkasan freelance**

- [ ] Menampilkan total jam kerja, nominal yang diperoleh, yang sudah dibayar,
      dan yang belum dibayar.
- [ ] Menampilkan tanggal pembayaran terdekat yang belum diterima.
- [ ] Menyediakan satu jalan ke Ikhtisar Freelance.
- [ ] **Tidak menampilkan entri worklog satu per satu.** Beranda memuat
      ringkasan, bukan daftar kerja.
- [ ] Menyembunyikan ringkasan ini sepenuhnya kalau tidak ada pembayaran yang
      tertunda.

**FR-HOME-004 — Transaksi terbaru**

- [ ] Menampilkan beberapa transaksi terbaru.
- [ ] Menyediakan jalan ke layar Transaksi.

**FR-HOME-005 — Keadaan kosong dan langkah pertama**

- [ ] Menampilkan "Belum ada transaksi" beserta ajakan **Catat Transaksi**
      selama belum ada satu pun transaksi tercatat.
- [ ] Mengarahkan ajakan itu ke alur CATAT yang sama, bukan ke formulir
      tersendiri.
- [ ] Mengarahkan pengguna yang belum punya dompet untuk membuat dompet
      pertamanya beserta saldo awalnya lebih dulu.
- [ ] Menyembunyikan kartu ringkasan yang belum punya isi, alih-alih
      menampilkan angka nol berderet.

## 8. Kebutuhan non-fungsional

### 8.1 Ketepatan

**NFR-ACC-001** Seluruh nominal disimpan sebagai bilangan bulat satuan sen, dan
pembulatan hanya terjadi saat menampilkan. Aturan ini wajib karena potongan
pajak freelance 2,5% menghasilkan pecahan setengah rupiah, dan pembulatan yang
terlalu dini meleset satu rupiah dari catatan pemilik.

**NFR-ACC-002** Setiap rumus domain punya uji unit yang memakai angka nyata
sebagai kasus uji, bukan angka karangan.

**NFR-ACC-003** Saldo dompet yang disimpan harus selalu sama persis dengan
saldo yang dihitung ulang dari seluruh transaksi. Karena saldo disimpan demi
kecepatan, penyeimbangnya adalah fungsi penghitungan ulang beserta uji yang
membuktikan keduanya identik.

### 8.2 Kinerja

**NFR-PERF-001** Beranda tampil penuh dalam waktu di bawah satu detik pada
perangkat kelas menengah.

**NFR-PERF-002** Waktu tampil Beranda dan layar Dompet tidak ikut bertambah
seiring bertambahnya riwayat transaksi. Riwayat bertahun-tahun tidak boleh
memaksa pemindaian menyeluruh untuk menampilkan saldo.

### 8.3 Keandalan

**NFR-REL-001** Seluruh fungsi berjalan tanpa koneksi internet.

**NFR-REL-002** Data bertahan setelah aplikasi ditutup, diperbarui, dan
perangkat dinyalakan ulang.

**NFR-REL-003** Setiap dokumen tersimpan membawa `schemaVersion` supaya
perubahan bentuk data di masa depan bisa dimigrasikan, bukan dibuang.

### 8.4 Kegunaan

**NFR-UX-001** Pencatatan satu transaksi selesai dalam satu layar, tanpa
berpindah halaman di tengah jalan.

**NFR-UX-002** Seluruh teks antarmuka memakai istilah yang persis sama dengan
[glosarium](../00-foundation/PROJECT_GLOSSARY.md).

**NFR-UX-003** Aplikasi mendukung mode terang dan gelap, dan seluruh warna
semantiknya lolos rasio kontras 4,5:1 terhadap latar di kedua mode.

**NFR-UX-004** Antarmuka tersedia dalam bahasa Indonesia sebagai bahasa dasar
dan bahasa Inggris sebagai tambahan.

**NFR-UX-005** Kosakata antarmuka menyatakan pencatatan, bukan tindakan
keuangan. Tidak ada tombol atau pesan yang menyiratkan aplikasi memindahkan,
mengirim, atau membayarkan uang.

### 8.5 Keamanan

**NFR-SEC-001** Tidak ada data keuangan yang meninggalkan perangkat. Aplikasi
tidak melakukan panggilan jaringan sama sekali di MVP.

### 8.6 Dukungan platform

**NFR-PLAT-001** Aplikasi berjalan di Android dengan `minSdk` 23 dan di iOS,
memakai Flutter 3.47.2 dan Dart 3.13.2.

## 9. Arsitektur tingkat tinggi

Saldough memakai tiga zona folder `core`, `shared`, dan `features`, dengan
pemisahan lapisan domain, data, dan presentation di tiap fitur. State dikelola
`package:state_management`; kesalahan mengalir sebagai `Either<Failure, T>`;
penyimpanan lokal berbasis dokumen JSON di atas Hive; navigasi memakai registri
rute bertipe. Seluruh keputusan itu diwarisi dari Saldough 1.0 tanpa perubahan,
dan alasannya ada di [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md),
[ADR-0003](../02-architecture/adr/0003-effect-bloc-state-management.md),
[ADR-0005](../02-architecture/adr/0005-either-failure-convention.md), dan
[ADR-0004](../02-architecture/adr/0004-typed-route-registry-navigation.md).

Yang baru hanya dua: bentuk model domainnya
([ADR-011](../02-architecture/adr/0011-model-domain-dompet-transaksi-anggaran.md))
dan tata letak penyimpanan buku besar transaksi
([ADR-012](../02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md)).
Gambaran lengkapnya di
[ARCHITECTURE_OVERVIEW.md](../02-architecture/ARCHITECTURE_OVERVIEW.md).

## 10. Prinsip antarmuka

Navigasi bawah berisi lima tujuan dengan CATAT di tengah sebagai tindakan utama
yang dibedakan secara visual:

```
Beranda | Anggaran | CATAT | Transaksi | Dompet
```

Bahasa visualnya diuraikan di
[ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md): dasar
perkamen hangat, tinta gelap yang terbaca, warna semantik terpisah untuk
pemasukan, pengeluaran, dan peringatan, kartu bergaris tepi tegas dengan
bayangan keras beroffset, dan satu set ikon pixel-art isometrik yang dipakai
konsisten. Yang dihindari: biru fintech generik, gradasi berlebihan,
glassmorphism, dan nuansa perbankan korporat — bayangan keras di sini
disengaja, bukan pengecualian dari larangan itu.

Identitasnya **pixel-art bergaya indie game modern**, bukan retro nostalgia
murni. Judul dan angka besar memakai satu peran huruf tebal; teks isi memakai
peran humanis yang mudah dibaca; nominal dan lencana status memakai huruf
tabular supaya digit rata di kolom. Tidak ada huruf display pixel terpisah —
identitas "pixel"-nya ada di ikon, bukan di tipografi. Angka adalah isi utama
hampir tiap layar, jadi keterbacaan angka diutamakan di atas gaya, dan seluruh
nominal memakai pengelompokan ribuan dan tanda minus yang jelas.

Ikon memakai satu set pixel-art yang dipakai konsisten lewat lapisan `AppIcon`:
satu konsep selalu memakai ikon yang sama di seluruh aplikasi, tidak ada ikon
Material yang dipanggil langsung dari berkas halaman, tidak ada emoji, tidak ada
logo bank atau perusahaan sungguhan, dan status dinyatakan lewat bentuk ikon
maupun warnanya sekaligus — bukan warna saja.

### Lima prinsip antarmuka

1. **Mencatat, bukan memproses.** Antarmuka selalu menyatakan bahwa aplikasi
   merekam kejadian. "Catat Transfer", bukan "Transfer". "Transfer tercatat",
   bukan "Transfer berhasil".
2. **Uang nyata berbeda dari uang rencana.** Tidak ada satu pun elemen yang
   menyiratkan membuat anggaran mengeluarkan uang dari dompet.
3. **Diperoleh berbeda dari diterima.** Penghasilan freelance selalu
   menampilkan ketiganya terpisah: diperoleh, sudah dibayar, belum dibayar.
4. **Satu sistem pencatatan.** Seluruh pembuatan transaksi manual bermuara ke
   CATAT. Pintasan kontekstual boleh mengisi field lebih dulu, tetapi tidak
   boleh membuat alur paralel.
5. **Kerumitan bertingkat.** Tindakan sederhana tetap sederhana. Template, pos
   anggaran, dan pelacakan pembayaran freelance tidak boleh membuat pencatatan
   satu pengeluaran jadi lebih berat.

## 11. Risiko dan mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Saldo tersimpan melenceng dari riwayat transaksi | Angka utama aplikasi salah tanpa disadari | Fungsi penghitungan ulang plus uji yang membuktikan keduanya identik (NFR-ACC-003) |
| Riwayat transaksi tumbuh tanpa batas | Aplikasi melambat setelah beberapa tahun | Partisi dokumen per bulan, bukan satu dokumen tunggal (ADR-012) |
| Ikatan anggaran ke satu dompet terasa mengekang | Belanja yang dibayar dari dompet lain tidak terhitung | Diterima sebagai keputusan sadar, dicatat di ADR-011; ditinjau ulang setelah satu bulan pemakaian |
| Aset ikon pixel-art belum tersedia saat UI dikerjakan | Fase UI tertahan | Lapisan `AppIcon` memetakan kunci semantik ke aset, sehingga penggantian set ikon tidak menyentuh berkas halaman |
| Pemilik harus memasukkan saldo awal seluruh dompet dari nol | Data awal salah, seluruh angka ikut salah | Saldo awal bisa disunting kapan saja dan saldo tercatat dihitung ulang saat itu juga (FR-WAL-002) |
| Pencatatan terasa merepotkan sehingga ditinggalkan | Aplikasi tidak dipakai | Satu titik masuk tunggal, satu layar per transaksi, target di bawah sepuluh detik |

## 12. Pengembangan setelah MVP

- Kartu kredit sebagai dompet bersaldo negatif, beserta pencatatan pembayaran
  tagihannya sebagai transfer.
- Transaksi berulang untuk langganan bulanan.
- Laporan bulanan dan tahunan beserta grafiknya.
- Sinkronisasi antar perangkat.
- Impor mutasi rekening.
- Tujuan menabung dengan target nominal dan tenggat.

## 13. Pertanyaan terbuka

- Spesifikasi aset ikon pixel-art: cakupan, format, dan ukurannya belum
  ditentukan. Pemilik akan mengirimkan asetnya.
- Apakah kategori transaksi perlu daftar bawaan, atau seluruhnya diketik
  pemilik sendiri.
- Apakah periode anggaran perlu lebih dari mingguan dan bulanan.
- **Bagaimana ukuran keberhasilan perilaku diukur.** Aktivasi, frekuensi
  pencatatan, adopsi anggaran, dan retensi D7/D30 tidak bisa dihitung lintas
  pengguna tanpa telemetri, sementara NFR-SEC-001 melarang panggilan jaringan
  sama sekali. Pilihannya: tetap tanpa telemetri dan menilai dari pemakaian
  pemilik sendiri, atau membatalkan NFR-SEC-001. Keputusan pemilik.
- **Daftar kategori transaksi dan anggaran final.** Aset dari pemilik sudah
  membawa 14 ikon kategori konkret (lihat
  [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md)),
  jauh lebih kaya dari 4 kunci generik yang ada sekarang. Sinyal kuat, tapi
  daftar final tetap keputusan produk tersendiri, belum diambil.
- Apakah status pembayaran freelance perlu status ketiga, "lewat jatuh
  tempo", selain "belum dibayar" dan "sudah dibayar" — aset membawa ikon
  untuk itu (`icon_freelance_overdue_payment`) yang belum punya padanan di
  `PaymentStatus`.

## 14. Lampiran

- [Glosarium](../00-foundation/PROJECT_GLOSSARY.md) — istilah dan nama kode.
- [Analisis proses manual](../00-foundation/MANUAL_PROCESS_ANALYSIS.md) —
  kebiasaan keuangan pemilik yang melatarbelakangi produk ini.
- [Model domain](../02-architecture/DOMAIN_MODEL.md) — entitas, rumus, dan
  invarian.
- [User stories](user-stories.md) — kebutuhan di atas dari sudut pandang
  pemilik.
- [PRD 1.0](prd-saldough-1.0.md) — produk pendahulu, sebagai rekaman sejarah.
