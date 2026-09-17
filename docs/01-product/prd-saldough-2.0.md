# Product Requirements Document: Saldough 2.0

## 1. Ringkasan

Saldough adalah aplikasi Flutter untuk Android dan iOS untuk mencatat dan
mengelola keuangan pribadi. Intinya tiga hal: **di mana uang berada**, **apa
yang terjadi padanya**, dan **ke mana ia direncanakan pergi**.

| | |
|---|---|
| **Nama produk** | Saldough |
| **Platform** | Android dan iOS |
| **Versi dokumen** | 2.0 |
| **Status** | Draf, menunggu implementasi |
| **Pemilik** | muhammadrisky1401@gmail.com |
| **Terakhir diperbarui** | 17 September 2026 |

> **Catatan versi (17 September 2026):** Dokumen ini menggantikan
> [PRD 1.0](prd-saldough-1.0.md), bukan memperbaruinya. Saldough 1.0 adalah
> pengganti digital sistem empat Google Spreadsheet milik pemilik: produknya
> berporos pada siklus bulanan, rollover antar bulan, dan baris roll-up. Produk
> itu tidak dilanjutkan. PRD 1.0 tetap ada di tempatnya sebagai rekaman
> sejarah, dan seluruh identitas `FR-CYCLE`, `FR-TPL`, `FR-GROC`, `FR-CARD`,
> dan `FR-INV` di dalamnya tidak lagi berlaku.

Saldough **mencatat**, bukan **melakukan**. Aplikasi ini tidak memindahkan uang,
tidak membayar, tidak menarik atau menyetor dana, dan tidak terhubung ke bank
mana pun. Ketika pemilik mencatat transfer dari BCA ke GoPay, yang terjadi
adalah dua angka di dalam aplikasi berubah — bukan sebuah transaksi perbankan.
Batasan ini bukan kekurangan teknis melainkan definisi produk, dan seluruh
kosakata antarmuka harus mencerminkannya.

## 2. Pernyataan masalah

Pemilik perlu tahu berapa uang yang ia punya dan di mana uang itu berada.
Sebelumnya ia mengelola keuangannya lewat empat Google Spreadsheet yang saling
mereferensi manual, dan Saldough 1.0 dibangun untuk menggantikan proses itu
persis apa adanya.

Pendekatan itu memecahkan masalah pencatatan bulanan, tetapi meninggalkan tiga
masalah yang tidak bisa diselesaikan dari dalam modelnya sendiri:

- **Tidak ada jawaban untuk "berapa uang saya sekarang".** Spreadsheet, dan
  Saldough 1.0 yang menirunya, mencatat rencana per bulan — bukan saldo. Tidak
  ada satu pun tempat yang menyimpan berapa isi rekening atau dompet digital
  pada hari tertentu.
- **Tidak ada catatan peristiwa.** Baris `Kos Rp2.500.000` di bulan Maret
  menyatakan rencana, bukan kejadian. Tidak ada tanggal, tidak ada dompet asal,
  dan tidak ada cara menelusuri ke mana uang benar-benar pergi.
- **Struktur bulanannya mengikat terlalu kencang.** Anggaran belanja mingguan,
  tagihan yang periodenya bukan bulan kalender, dan penghasilan freelance yang
  periodenya delapan hari sampai sebulan semuanya harus dipaksa masuk ke kotak
  `YYYY-MM`.

Masalah keempat muncul dari cara Saldough 1.0 dipakai sehari-hari: alurnya
terasa rumit. Untuk mencatat satu hal, pemilik harus tahu lebih dulu di layar
mana ia berada dan bagaimana angkanya akan mengalir ke tempat lain.

## 3. Tujuan dan ukuran keberhasilan

### Tujuan produk

- Menjawab "berapa uang saya, dan di mana" dalam satu layar, kapan saja.
- Membuat pencatatan satu transaksi memakan waktu di bawah sepuluh detik, lewat
  satu titik masuk yang selalu sama.
- Memisahkan dengan tegas antara uang yang **ada**, uang yang **direncanakan**,
  dan uang yang **sudah dikerjakan tetapi belum diterima**.
- Tetap berguna tanpa koneksi internet dan tanpa akun.

### Ukuran keberhasilan MVP

- Pemilik memakai Saldough sebagai satu-satunya catatan keuangannya selama satu
  bulan penuh tanpa kembali ke spreadsheet.
- Saldo tercatat tiap dompet cocok dengan saldo sebenarnya di akhir bulan, tanpa
  penyesuaian manual.
- Seluruh pencatatan transaksi berjalan lewat satu alur yang sama.
- Tidak ada satu pun selisih rupiah antara nominal yang dicatat dan nominal yang
  ditampilkan.

## 4. Pengguna sasaran

### Persona utama

Pemilik aplikasi: satu orang yang mengelola keuangan pribadinya sendiri, punya
dua sumber penghasilan (gaji tetap dan freelance per jam), menyimpan uang di
beberapa tempat sekaligus (rekening bank, tunai, dompet digital), dan sudah
terbiasa menganggarkan secara sadar.

### Persona sekunder

Tidak ada. MVP dipakai satu orang di satu perangkat. Peran kedua baru relevan
kalau sinkronisasi antar perangkat dikerjakan, dan itu di luar MVP.

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

Berbeda dari aplikasi keuangan umum, Saldough memisahkan secara eksplisit antara
penghasilan yang **sudah dikerjakan** dan yang **sudah diterima** — pembedaan
yang penting bagi pekerja lepas dan biasanya tidak tersedia di aplikasi
sejenis.

## 6. Cakupan MVP

### Termasuk dalam MVP

- Dompet: buat, sunting, saldo awal, saldo tercatat, riwayat per dompet.
- Transaksi: pemasukan, pengeluaran, transfer, daftar, penyaring, sunting,
  hapus.
- Alur CATAT sebagai titik masuk tunggal pencatatan manual.
- Anggaran: beberapa anggaran aktif sekaligus, pos anggaran, progres, status,
  template.
- Freelance: proyek, worklog, pembayaran, dan pencatatan pembayaran diterima.
- Beranda sebagai ringkasan.
- Terang dan gelap, bahasa Indonesia dan Inggris.

### Di luar MVP

- Sinkronisasi bank, impor transaksi otomatis, dan pemrosesan pembayaran.
- Kartu kredit sebagai dompet liabilitas. Modelnya menampungnya tanpa konsep
  tambahan, tetapi tidak dikerjakan sekarang.
- Impor data historis dari Saldough 1.0. Aplikasi mulai dari saldo awal.
- Investasi, laporan tahunan, analitik lanjutan, dan akuntansi.
- Multi-mata-uang, akun bersama, sinkronisasi antar perangkat.
- Transaksi berulang otomatis.
- Pemindaian struk dan saran keuangan otomatis.

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

- [ ] Membuat anggaran dengan nama, dompet, periode, dan nominal rencana.
- [ ] Mengizinkan beberapa anggaran aktif sekaligus tanpa mengharuskan yang lama
      ditutup lebih dulu.
- [ ] Mengizinkan beberapa anggaran berbagi satu dompet.
- [ ] Mengizinkan anggaran berbeda punya periode berbeda.
- [ ] **Tidak mengubah saldo dompet mana pun saat anggaran dibuat, disunting,
      atau dihapus.**

**FR-BUD-002 — Mengelola pos anggaran**

- [ ] Menambah, menyunting, dan menghapus pos di dalam satu anggaran.
- [ ] Menerima nominal rencana per pos.
- [ ] Menerima jumlah dan harga satuan opsional untuk pos yang berupa daftar
      belanja, dan menghitung nominal rencananya dari keduanya.
- [ ] Menampilkan selisih antara jumlah nominal seluruh pos dan nominal rencana
      anggaran.

**FR-BUD-003 — Menautkan pengeluaran ke pos anggaran**

- [ ] Menautkan satu pengeluaran ke paling banyak satu pos anggaran.
- [ ] Menghitung `spent` sebuah pos dari transaksi yang tertaut padanya, bukan
      dari nilai yang disimpan.
- [ ] Hanya menghitung pengeluaran yang dompetnya sama dengan dompet anggaran.
- [ ] Memperbarui progres seketika saat transaksi dicatat, disunting, atau
      dihapus.

**FR-BUD-004 — Menampilkan progres dan status**

- [ ] Menampilkan nominal rencana, terpakai, dan sisa untuk tiap anggaran dan
      tiap pos.
- [ ] Menampilkan status tiap pos: belum terpakai, terpakai sebagian, selesai,
      atau lewat anggaran.
- [ ] Menampilkan pos yang lewat anggaran dengan warna `overBudget`, bukan
      sebagai kesalahan.

**FR-BUD-005 — Template anggaran**

- [ ] Membuat, menyunting, menggandakan, mengaktifkan, menonaktifkan, dan
      menghapus template.
- [ ] Membuat anggaran aktif baru dari sebuah template.
- [ ] Memperlakukan anggaran hasil template sebagai anggaran mandiri yang
      perubahannya tidak memengaruhi templatenya.
- [ ] Tidak mengubah saldo dompet mana pun saat template dibuat atau disunting.

### 7.5 Freelance

**FR-FRL-001 — Mengelola proyek freelance**

- [ ] Menambah, menyunting, dan menghapus proyek beserta tarif per jamnya.
- [ ] Mengelola aturan potongan tiap proyek, baik per mil maupun nominal tetap.

**FR-FRL-002 — Mencatat worklog**

- [ ] Mencatat entri kerja berisi proyek, tanggal, dan jumlah jam.
- [ ] Menghitung nominal yang diperoleh dari jam dikali tarif per jam.
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

**FR-FRL-005 — Ringkasan freelance**

- [ ] Menampilkan total yang sudah diperoleh tetapi belum dibayar.
- [ ] Menampilkan daftar pembayaran beserta statusnya.
- [ ] Dicapai dari Beranda dan dari alur CATAT pemasukan, bukan dari navigasi
      bawah.

### 7.6 Beranda

**FR-HOME-001 — Ringkasan saldo dan arus bulan berjalan**

- [ ] Menampilkan total saldo seluruh dompet aktif.
- [ ] Menampilkan total pemasukan bulan berjalan.
- [ ] Menampilkan total pengeluaran bulan berjalan.
- [ ] Tidak menghitung transfer sebagai pemasukan maupun pengeluaran.

**FR-HOME-002 — Ringkasan anggaran**

- [ ] Menampilkan total nominal rencana dan total terpakai seluruh anggaran
      aktif.
- [ ] Menyediakan jalan ke layar Anggaran.

**FR-HOME-003 — Ringkasan freelance**

- [ ] Menampilkan total penghasilan freelance yang belum dibayar.
- [ ] Menyembunyikan ringkasan ini sepenuhnya kalau tidak ada pembayaran yang
      tertunda.

**FR-HOME-004 — Transaksi terbaru**

- [ ] Menampilkan beberapa transaksi terbaru.
- [ ] Menyediakan jalan ke layar Transaksi.

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
[ADR-013](../02-architecture/adr/0013-bahasa-visual-dan-sistem-ikon.md): dasar
krem hangat, tinta gelap yang terbaca, satu aksen utama yang kuat, warna
semantik terpisah untuk pemasukan, pengeluaran, dan peringatan, serta satu set
ikon pixel-art yang dipakai konsisten. Yang dihindari: biru fintech generik,
gradasi berlebihan, glassmorphism, dan nuansa perbankan korporat.

Angka adalah isi utama layar ini, jadi tipografi angka diutamakan keterbacaannya
di atas gaya. Seluruh nominal memakai pengelompokan ribuan dan tanda minus yang
jelas.

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

## 14. Lampiran

- [Glosarium](../00-foundation/PROJECT_GLOSSARY.md) — istilah dan nama kode.
- [Analisis proses manual](../00-foundation/MANUAL_PROCESS_ANALYSIS.md) —
  kebiasaan keuangan pemilik yang melatarbelakangi produk ini.
- [Model domain](../02-architecture/DOMAIN_MODEL.md) — entitas, rumus, dan
  invarian.
- [User stories](user-stories.md) — kebutuhan di atas dari sudut pandang
  pemilik.
- [PRD 1.0](prd-saldough-1.0.md) — produk pendahulu, sebagai rekaman sejarah.
