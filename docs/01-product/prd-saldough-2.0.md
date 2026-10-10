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
| **Status** | Berlaku; MVP terimplementasi (lihat TASK_LIST) |
| **Jenis produk** | Pengelolaan keuangan pribadi |
| **Pengguna sasaran** | Perorangan |
| **Bahasa utama** | Indonesia |
| **Pemilik** | muhammadrisky1401@gmail.com |
| **Terakhir diperbarui** | 17 September 2026 |

> **Catatan versi (17 September 2026):** Dokumen ini menggantikan
> [PRD 1.0](../99-archive/prd-saldough-1.0.md), bukan memperbaruinya. Saldough 1.0 adalah
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
- Pencatatan inti (CATAT, Transaksi, Dompet, Anggaran, Freelance) tetap
  berguna tanpa koneksi internet dan tanpa akun, walau fitur pelengkap lain
  boleh membutuhkan keduanya (lihat §13).

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
MVP tidak punya akun maupun telemetri pemakaian — sehingga tidak ada cara
menghitung "persentase pengguna". Di MVP keenam ukuran itu dinilai pada
**pemakaian pemilik sendiri**, diamati langsung. NFR-SEC-001 (28 Sep 2026)
sudah direvisi untuk mengizinkan panggilan jaringan bagi fitur online yang
jelas keperluannya, tapi itu **tidak otomatis berarti telemetri perilaku
diizinkan** — mengumpulkan data pemakaian tetap keputusan produk terpisah,
belum diambil. Pertanyaannya terbuka di [§13](#13-pertanyaan-terbuka).

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
yang ada sekarang, di mana, dan apa saja yang sudah terjadi padanya.
Pencatatannya tidak pernah terhubung ke bank sungguhan — transfer yang
dicatat adalah dua angka di dalam aplikasi yang berubah, bukan transaksi
perbankan. Data keuangan pengguna tidak dikirim ke luar perangkat tanpa
keperluan yang jelas dan sepengetahuan pengguna (NFR-SEC-001); ini tetap
berlaku walau fitur online direncanakan (lihat §13).

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
- Transaksi berulang yang **dicatat otomatis tanpa ditinjau**. Transaksi
  rutin yang dijadwalkan dan ditinjau masuk cakupan sesudah MVP lewat
  Fase 15 (§7.8, [ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)).
- Pemindaian struk, ekspor-impor data, dan asisten keuangan berbasis AI.

**Template freelance** ([FR-FRL-006](#75-freelance)) **deprecated** sejak 26 Sep
2026 atas keputusan pemilik dan tidak dikerjakan. Proyek freelance dibuat
langsung lewat Tambah Proyek.

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

- [ ] Menyediakan tombol CATAT yang selalu terlihat dan dibedakan secara
      visual dari tujuan navigasi biasa (FAB di kanan bawah sejak 30 Sep
      2026, T-11.5).
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
- [ ] Hanya menautkan dan menghitung transaksi yang tanggalnya berada di
      dalam periode anggaran. Pemilih pos hanya menawarkan pos anggaran yang
      periodenya mencakup tanggal transaksi (keputusan KT-1).
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
      nonaktif. Penyaring bawaan: aktif (keputusan KT-1).
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
      menampilkan tarif yang dipakai di entri itu. Tarif disalin dari proyek
      saat entri dicatat dan boleh diubah; mengubah tarif proyek tidak
      mengubah entri lama (ADR-019).
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
- [ ] Transaksi pemasukannya hanya bisa diubah lewat pembayarannya: tidak bisa
      disunting atau dihapus dari tab Riwayat, dan pembayaran yang sudah
      diterima bisa dibatalkan penerimaannya (ADR-019).
- [ ] Menyatakan dengan jelas bahwa ini pencatatan pembayaran, bukan pembayaran
      yang dijalankan aplikasi.

**FR-FRL-005 — Ikhtisar Freelance**

- [ ] Menyediakan satu layar Ikhtisar Freelance **tanpa tab**: ringkasan upah
      dan jam, lalu daftar proyek. Tiap kartu proyek menggabungkan sisi
      worklog (belum ditagih) dan sisi pembayaran (tertunda beserta perkiraan
      terdekat, dan diterima). *(Direvisi 25 Sep 2026 atas keputusan pemilik;
      semula tiga tab Worklog, Pembayaran, Template.)*
- [ ] Menyediakan rincian proyek dengan dua tab, Worklog dan Pembayaran, tempat
      entri dan pembayaran proyek itu dikelola.
- [ ] Menampilkan total jam kerja, nominal yang diperoleh, yang sudah dibayar,
      dan yang belum dibayar.
- [ ] Menampilkan daftar pembayaran beserta status dan tanggalnya, per proyek.
- [ ] **Dicapai dari dua titik masuk yang keduanya mendarat di layar yang
      sama:** ringkasan di Beranda, dan CATAT → Catat Pemasukan → Freelance.
- [ ] Bukan tujuan navigasi bawah.

**FR-FRL-006 — Template freelance** — ~~deprecated~~

*(Deprecated 26 Sep 2026 atas keputusan pemilik; tidak dikerjakan.)* Butir di bawah
disimpan sebagai catatan sejarah saja.

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
- [ ] "Bulan berjalan" adalah periode keuangan berjalan (FR-PLN-004), bukan
      bulan kalender; judulnya rentang tanggal bila awal bulan keuangan bukan
      tanggal 1 (revisi 10 Okt 2026,
      [FINANCIAL_PERIOD.md](features/FINANCIAL_PERIOD.md) P-11).
- [ ] Kartu arus menjadi pintu ke Analisis bulan berjalan (FR-ANL-001).

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

### 7.7 Kategori, bahasa, Catat pakai suara, dan Catat dari notifikasi (sesudah MVP, ditambahkan 1 Okt 2026)

Kebutuhan ini lahir di Fase 11. Keputusan rincinya di ADR-026 sampai ADR-029 dan ADR-032;
FR di bawah merangkum perilaku yang dijanjikan ke pengguna.

**FR-CAT-001 — Kategori bawaan yang bisa diubah**

- [x] Menyediakan daftar kategori bawaan per jenis (pengeluaran, pemasukan);
      transfer tidak berkategori (ADR-026 §3.2–3.3).
- [x] Pengguna bisa menambah, mengganti nama, mengarsipkan, dan memulihkan
      kategori dari layar Kategori di Akun, dan menambah kategori langsung dari
      CATAT tanpa membuat transaksi.
- [x] Kategori terarsip tidak ditawarkan di pemilih, tetapi namanya tetap
      tampil pada transaksi lama.
- [x] Label kategori lama dimigrasi tanpa kehilangan transaksi.

**FR-LANG-001 — Bahasa aplikasi dipilih pengguna**

- [x] Pengguna memilih Bahasa Indonesia atau Inggris di langkah pertama
      onboarding, dan bisa menggantinya di Akun (ADR-028).
- [x] Satu pilihan mengatur teks aplikasi dan bahasa pengenal ucapan.
- [x] Nama kategori bawaan yang belum diganti pengguna ikut berganti bahasa;
      nama yang sudah diganti pengguna tidak disentuh.

**FR-VOI-001 — Catat pakai suara**

- [ ] Menyediakan tombol suara yang selalu terlihat di samping CATAT; rekaman
      baru dimulai setelah pengguna menekan tombol rekam, dengan tanda yang
      jelas selama merekam.
- [ ] Satu ucapan menghasilkan draf yang membuka formulir CATAT terisi;
      suara **tidak pernah menyimpan transaksi sendiri** (aturan 8, ADR-027
      §3.4).
- [ ] Nominal hanya diambil dari angka yang benar-benar diucapkan; dompet dan
      kategori hanya dipilih dari yang sudah ada. Bagian yang ragu dikosongkan
      dan ditandai, bukan ditebak.
- [ ] Bila pengenal ucapan gagal (izin ditolak, tidak tersedia, butuh
      internet), pengguna diberi tahu alasannya dan selalu bisa beralih ke
      "Ketik saja".
- [ ] Pencatatan inti tetap penuh tanpa internet; hanya fitur suara yang boleh
      bergantung pada koneksi (NFR-REL-001, ADR-027 §3.5 butir 7).

**FR-NOT-001 — Catat dari notifikasi (Android)**

Keputusan rinci di ADR-032.

- [ ] Pengguna memilih sendiri aplikasi yang didengarkan, filter
      notifikasinya, dan dompetnya. Filter adalah whitelist: hanya notifikasi
      yang memuat frasa filter yang ditangkap; filter bawaan berisi frasa yang
      pasti transaksi. Notifikasi lain diabaikan tanpa disimpan, dan
      notifikasi OTP/kode verifikasi tidak pernah diproses.
- [ ] Aplikasi bank/e-wallet umum punya pola bawaan; pengguna bisa membuat pola
      sendiri dari contoh notifikasi tanpa menulis regex.
- [ ] Pengguna memilih tingkat otomatis: tinjau semua (bawaan), otomatis bila
      lengkap, atau otomatis bila nominal dan dompet yakin. Tangkapan yang
      ragu atau mungkin ganda selalu menunggu tinjauan dan membuka formulir
      CATAT terisi.
- [ ] Pengguna memilih mode penyampaian: pengingat + kotak masuk, atau kotak
      masuk saja.
- [ ] Transaksi yang tercatat otomatis tampil di daftar "Tercatat otomatis"
      selama 7 hari dan bisa ditinjau atau dibatalkan; teks notifikasi tidak
      disimpan lebih dari 7 hari.
- [ ] Nominal hanya diambil dari angka yang tertulis di notifikasi, bukan
      saldo; pencatatan inti tetap penuh tanpa internet.

### 7.8 Rutin dan Rencana (sesudah MVP, ditambahkan 2 Okt 2026)

Kebutuhan ini lahir dari permintaan pemilik 2 Okt 2026. Keputusannya di
[ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md); perilaku dan rumusnya di
[RECURRING_AND_FORECAST.md](features/RECURRING_AND_FORECAST.md), tata letaknya
di [PLAN_TAB_LAYOUT.md](features/PLAN_TAB_LAYOUT.md). Prefiks `FR-RUT-`
dipakai karena `FR-REC-` sudah berarti alur CATAT. Rilis R1a dan R1b ada di
Fase 15; R2 dan R3 di antrean.

**FR-RUT-001 — Membuat transaksi rutin (R1a)**

- [ ] Pemasukan, pengeluaran, dan transfer bisa dijadikan rutin dari baris
      **Ulangi** di formulir CATAT, atau dari **Jadikan Rutin** di rincian
      transaksi. Tidak ada formulir rutin terpisah (aturan 8).
- [ ] Jadwal: tiap minggu, bulan, atau tahun dengan selang N. Berakhir: tidak
      pernah, sampai tanggal, atau setelah N kali (cicilan menampilkan k/N).
- [ ] Nominal tetap atau kira-kira. Cara bayar (autodebet atau bayar sendiri)
      ditanyakan untuk pengeluaran dan transfer, boleh dikosongkan.
- [ ] Tanggal hari ini atau lampau → "Catat & Jadwalkan" (transaksi ini menjadi
      kemunculan pertama). Tanggal masa depan → "Simpan Jadwal" (tidak ada
      transaksi yang dibuat).
- [ ] Chip pembuka lokal (Gaji, Kos/Sewa, Listrik, Internet, BPJS, Cicilan,
      Paylater, Langganan, Kirim ke orang tua, Arisan, Tabungan) membuka
      CATAT mode jadwal yang terisi.
- [ ] Membuat atau mengubah rutin tidak pernah mengubah saldo dompet mana pun.

**FR-RUT-002 — Kemunculan yang menunggu dicatat (R1a)**

- [ ] Kemunculan yang sudah tiba tampil di kartu **Menunggu dicatat** di
      Beranda dan di segmen Rutin, dengan tanggal transaksi bawaan = tanggal
      kemunculan.
- [ ] Nominal tetap: **Catat** satu ketuk dengan snackbar Batalkan; nominal
      kira-kira: Catat membuka CATAT dengan nominal terfokus.
- [ ] **Lewati** satu kemunculan tanpa mengubah rutinnya; **Catat semua** untuk
      beberapa kemunculan bernominal tetap.
- [ ] Satu kemunculan menghasilkan paling banyak satu transaksi. Kemunculan
      lama yang belum diurus dikelompokkan sebagai terlewat, bukan ditumpuk.

**FR-RUT-003 — Pencocokan dengan transaksi dari jalur lain (R1a)**

- [ ] Transaksi dari catat dari notifikasi yang cocok persis dengan satu
      kemunculan (jenis, dompet, nominal, tanggal ±3 hari, satu kandidat)
      ditautkan otomatis, tampil di log "Tercocok otomatis" 7 hari, dan bisa
      dilepas.
- [ ] Draf kotak masuk notifikasi yang cocok diberi label rutinnya dan
      dilengkapi kategori dan catatannya.
- [ ] Kecocokan yang ragu (dua kandidat, nominal atau dompet beda) selalu
      ditanyakan, tidak ditautkan otomatis.

**FR-RUT-004 — Pengingat (R1a)**

- [ ] Notifikasi lokal H−1 (bisa diatur) untuk rutin yang dibayar sendiri, dan
      satu notifikasi pada hari jatuh tempo untuk yang menunggu.
- [ ] Notifikasi rutin bernominal tetap punya aksi **Catat** yang membuka
      aplikasi lalu mencatat satu ketuk dengan Batalkan.
- [ ] Pengingat bisa dimatikan per rutin dan untuk seluruh aplikasi; izin
      notifikasi diminta saat pengingat pertama kali dinyalakan.
- [ ] Teks memakai kosakata mencatat ("jatuh tempo", "Catat"), bukan "Bayar".

**FR-RUT-005 — Mengubah, menjeda, mengakhiri, menghapus (R1a)**

- [ ] Perubahan nominal, dompet, atau jadwal berlaku ke kemunculan berikutnya;
      transaksi yang sudah tercatat tidak berubah.
- [ ] Rutin bisa dijeda dan dilanjutkan; rutin N kali berakhir sendiri dan
      pindah ke kelompok Selesai.
- [ ] Menghapus rutin tidak menghapus transaksinya.

**FR-PLN-001 — Tab Rencana (R1a: Anggaran + Rutin; R1b: + Bulan ini)**

- [ ] Tab Anggaran menjadi **Rencana** (en: Plan) dengan sub-tab yang hanya
      berpindah lewat ketukan: Bulan ini, Anggaran, Rutin.
- [ ] Segmen Anggaran berisi layar Anggaran sebelumnya; penyaring statusnya
      berupa chip.
- [ ] Segmen Rutin mengelompokkan Menunggu, Bulan ini, Nanti, Dijeda/Selesai,
      dengan chip jenis dan total langganan per bulan dan per tahun.
- [ ] Beranda dan notifikasi bisa membuka tab Rencana langsung ke segmen yang
      tepat.

**FR-PLN-002 — Uang nganggur bulan ini (R1b)**

- [ ] Menampilkan uang nganggur: pemasukan terencana dikurangi tagihan rutin
      dan anggaran, lalu dikurangi belanja di luar rencana yang sudah tercatat.
      Angka besar sama dengan jumlah baris di bawahnya.
- [ ] Transfer, termasuk ke Tabungan, tidak mengurangi uang nganggur.
- [ ] Uang nganggur tidak pernah disebut saldo, dan tampil di kartu yang
      terpisah dari saldo dompet.

**FR-PLN-003 — Perkiraan saldo bulan berjalan (R1b)**

- [ ] Menampilkan perkiraan saldo akhir bulan dan saldo **paling tipis**
      beserta tanggalnya, sebagai angka tertulis, bukan hanya di grafik.
- [ ] Perkiraan memasukkan rutin, sisa anggaran (dibagi rata ke sisa hari), dan
      rata-rata belanja di luar rencana bila riwayat sudah sebulan penuh
      (bisa dimatikan); pos dengan rutin tertaut tidak dihitung ganda.
- [ ] Semua angka perkiraan berawalan `≈` dan bisa dibuka rinciannya.

**FR-PLN-004 — Bulan keuangan bisa diatur (R1b, direvisi 10 Okt 2026)**

- [ ] Pengguna memilih tanggal awal bulan keuangan 1–28 atau **hari terakhir
      bulan** (bawaan 1), misalnya tanggal gajian. Tanggal selesai mengikuti
      sendiri; tidak bisa diatur bebas.
- [ ] Bisa diatur dari kepala Rencana › Bulan ini (rentang bisa diketuk) dan
      dari Akun; ditawarkan saat menyimpan rutin pemasukan bulanan bila awal
      bulan masih bawaan.
- [ ] Berlaku untuk Rencana, kartu bulan baru, arus Beranda (FR-HOME-001), dan
      Analisis (FR-ANL-001). Rincian di
      [FINANCIAL_PERIOD.md](features/FINANCIAL_PERIOD.md) dan
      [ADR-038](../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md).

**FR-PLN-006 — Mengubah awal bulan keuangan (Fase 18)**

- [ ] Periode yang sudah selesai tidak pernah berubah.
- [ ] Periode berjalan menjadi satu **periode peralihan** sampai batas baru
      terdekat dengan akhir lamanya (13–46 hari), diperlihatkan sebelum
      disimpan.
- [ ] Anggaran rutin yang patokannya sama dengan awal bulan lama ditawarkan
      ikut pindah; bila ikut, anggaran berjalan diregangkan atau dipendekkan
      ke periode peralihan tanpa celah, nominal tetap. Saldo tidak berubah.
- [ ] Periode peralihan berlabel; uang nganggur negatif di dalamnya tidak
      memicu peringatan; tidak dipakai untuk akurasi perkiraan atau pembanding.

**FR-PLN-007 — Gajian yang maju atau mundur (Fase 18)**

- [ ] Transaksi yang tertaut kemunculan rutin dengan selisih tanggal paling
      lama 7 hari dihitung ke periode kemunculannya. Saldo tetap menurut
      tanggal transaksi.

**FR-PLN-005 — Perkiraan bulan ke depan (R2)**

- [ ] Bulan berjalan + 2 bulan secara bawaan (maksimum 12), per dompet atau
      seluruh dompet, dengan peringatan "siapkan dana" bila dompet diperkirakan
      kurang sebelum autodebet.

**FR-BUD-008 — Anggaran rutin (R2)**

- [ ] Sakelar **Ulangi tiap periode** di formulir anggaran; periode baru lahir
      sendiri dengan pos yang sama (template berjadwal, ADR-035 §3.9).
- [ ] Mengubah anggaran rutin menawarkan "hanya periode ini" atau "periode ini
      dan berikutnya"; pos baru bawaannya hanya periode ini.

### 7.9 Analisis (sesudah MVP, ditambahkan 10 Okt 2026)

Kebutuhan ini lahir dari permintaan pemilik 10 Okt 2026 dan memenuhi
"laporan bulanan" di §12. Perilaku, aturan B-1–B-16, dan contoh angkanya di
[FINANCIAL_ANALYSIS.md](features/FINANCIAL_ANALYSIS.md). R1 di Fase 19, R2 di
antrean (B-38).

**FR-ANL-001 — Ke mana uang pergi (R1)**

- [ ] Segmen **Analisis** di tab Riwayat menampilkan pengeluaran dan
      pemasukan satu periode keuangan per kategori: nominal, persen, lima
      teratas, Lainnya, dan Tanpa kategori; pemasukan freelance tanpa
      kategori dikelompokkan sebagai Freelance.
- [ ] Penyaring dompet; transfer hanya sebagai baris informasi, tidak pernah
      masuk total atau persen.
- [ ] Total sama persis dengan kartu Arus Beranda dan cocok dengan Rencana
      (FINANCIAL_ANALYSIS B-3, B-15).
- [ ] Hanya membaca: tidak menulis data keuangan apa pun.

**FR-ANL-002 — Dibanding biasanya (R1)**

- [ ] Tiap kategori dibandingkan dengan rata-rata sampai tiga periode
      sebelumnya (periode berjalan: sampai hari yang sama); periode peralihan
      tidak dipakai.
- [ ] Paling banyak tiga sorotan bernada netral bila selisih ≥20% dan
      ≥Rp50.000. Tanpa skor, label "boros", atau warna peringatan.

**FR-ANL-003 — Tren (R1)**

- [ ] Pemasukan, pengeluaran, dan selisih enam periode terakhir; mengetuk
      satu periode membuka analisis periode itu. Periode sebelum pencatatan
      pertama tidak ditampilkan.

**FR-ANL-004 — Rincian kategori (R1)**

- [ ] Total, pembanding, tren enam periode, dan transaksi periode itu, dengan
      jalan ke Riwayat tersaring kategori dan periode yang sama (jumlahnya
      sama).

**FR-ANL-005 — Membetulkan Tanpa kategori (R1)**

- [ ] Baris Tanpa kategori membawa **Beri kategori** yang membuka Riwayat
      tersaring "Tanpa kategori"; menyunting lewat CATAT.
- [ ] Lembar kilas balik di tinjau awal bulan membuka Analisis bulan itu.

**FR-ANL-006 — Tahun dan tren total saldo (R2)**

- [ ] Ringkasan setahun per periode dan per kategori, rata-rata per bulan dari
      bulan yang sudah berjalan.
- [ ] Tren total saldo akhir periode (butuh `Wallet.createdAt`, ADR baru).
- [ ] Porsi pengeluaran dari rutin, dan baris "Di luar rencana" di Bulan ini
      membuka Analisis tersaring.

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

**NFR-REL-001** Seluruh fungsi pencatatan inti (CATAT, Transaksi, Dompet,
Anggaran, Freelance) berjalan tanpa koneksi internet. Fitur online yang
direncanakan (§13) boleh membutuhkan koneksi untuk bagiannya sendiri, tapi
tidak boleh memblokir atau memperlambat pencatatan inti saat perangkat
offline.

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

**NFR-SEC-001** Data keuangan pengguna tidak dikirim ke luar perangkat tanpa
keperluan yang jelas dan sepengetahuan pengguna. Panggilan jaringan
diperbolehkan hanya untuk fitur yang secara eksplisit membutuhkannya (mis.
verifikasi pembelian/langganan) — bukan telemetri atau pengumpulan data
pemakaian diam-diam, yang tetap keputusan produk terpisah (lihat §3 dan
§13). ⚠ Direvisi 28 September 2026; sebelumnya melarang panggilan jaringan
sama sekali.

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

Navigasi bawah berisi empat tujuan. CATAT bukan tab: ia FAB utama di kanan
bawah, dengan FAB kecil "Catat pakai suara" di atasnya (revisi 30 Sep 2026,
T-11.5; sebelumnya CATAT adalah slot tengah dari lima):

```
Beranda | Rencana | Riwayat | Dompet           [suara]
                                                [CATAT]
```

Tab ke-2 bernama **Rencana** (id) / **Plan** (en) sejak keputusan 2 Okt 2026
(ADR-035, mulai Fase 15), menggantikan tab Anggaran. Isinya tiga segmen:
Bulan ini, Anggaran, dan Rutin. Di sana berlaku satu aturan bahasa tambahan:
**kata "saldo" hanya untuk isi dompet.** Uang nganggur adalah arus satu
bulan, bukan saldo, dan tidak pernah tampil di kartu yang sama dengan saldo.

Tab riwayat transaksi bernama **Riwayat** (id) / **History** (en) sejak 29
September 2026, karena "Transactions" terbungkus di layar 360dp. Kata
"transaksi" sebagai benda tetap dipakai.

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
- ~~Transaksi berulang untuk langganan bulanan.~~ Dijadwalkan di Fase 15
  sebagai transaksi rutin, tab Rencana, uang nganggur, dan perkiraan (§7.8).
- ~~Laporan bulanan dan tahunan beserta grafiknya.~~ Dijadwalkan sebagai
  Analisis (§7.9): bulanan di Fase 19, tahunan di B-38.
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
  pengguna tanpa telemetri. NFR-SEC-001 direvisi 28 September 2026 sehingga
  tidak lagi melarang panggilan jaringan sama sekali, tapi itu tidak otomatis
  berarti telemetri perilaku diizinkan — mengumpulkan data pemakaian
  pengguna tetap keputusan produk tersendiri, belum diambil. Sampai
  diputuskan, keenam ukuran itu tetap dinilai dari pemakaian pemilik
  sendiri.
- **Arsitektur fitur online yang direncanakan (28 September 2026).** Pemilik
  ingin mengembangkan fitur berbasis jaringan (freemium/paywall dibahas
  sebagai kandidat pertama), tapi bentuknya belum didesain: apakah perlu
  akun, backend sendiri atau murni layanan pihak ketiga (mis. Google Play
  Billing tanpa backend Saldough), dan data apa yang boleh dikirim.
  NFR-SEC-001/NFR-REL-001 sudah direvisi untuk membuka jalan ini, tapi
  keputusan desain konkretnya menyusul sebagai ADR baru sebelum
  diimplementasikan — lihat T-8.4 di TASK_LIST.
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
- [PRD 1.0](../99-archive/prd-saldough-1.0.md) — produk pendahulu, sebagai rekaman sejarah.
