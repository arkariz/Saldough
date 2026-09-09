# User stories

Dokumen ini menerjemahkan kebutuhan fungsional di
[PRD](prd-saldough-1.0.md) menjadi cerita dari sudut pandang pemilik. Gunakan
dokumen ini saat merancang alur layar; gunakan PRD saat memastikan kelengkapan
kebutuhan.

Semua cerita memakai satu peran, yaitu **pemilik**, karena MVP dipakai satu
orang. Peran kedua baru muncul pada tahap sinkronisasi.

Setiap cerita mencantumkan requirement PRD yang dipenuhinya.

## Epik 1: Menutup bulan

Ini alur paling sering dipakai dan paling banyak memakan waktu pada proses
manual.

**US-01 — Membuat bulan baru tanpa menyalin manual**

Sebagai pemilik, saya ingin membuat siklus bulan berikutnya dalam satu tindakan,
supaya saya tidak perlu menyalin blok bulan lalu dan menyuntingnya baris per
baris.

- Baris tetap terbawa, baris insidental tidak.
- Baris roll-up dihitung ulang, bukan disalin nominalnya.
- Memenuhi FR-TPL-001 dan FR-TPL-003.

**US-02 — Diingatkan baris mana yang belum ditinjau**

Sebagai pemilik, saya ingin tiap baris hasil rollover ditandai perlu ditinjau,
supaya tidak ada baris lama yang lolos tanpa saya periksa.

- Baris yang belum ditinjau tampil dengan warna `needsReview`.
- Ringkasan siklus menampilkan berapa baris yang masih menunggu.
- Penanda hilang setelah saya mengonfirmasi baris itu.
- Memenuhi FR-TPL-002.

Cerita ini lahir dari kesalahan nyata: label `Kos agustus - september` terbawa
tiga bulan berturut-turut tanpa terdeteksi.

**US-03 — Melihat sisa bulan berjalan kapan saja**

Sebagai pemilik, saya ingin melihat sisa bulan ini dari layar utama, supaya saya
bisa memutuskan pengeluaran saat sedang di luar.

- Sisa tampil sebagai total pemasukan dikurangi total anggaran.
- Sisa negatif tampil sebagai kondisi lewat anggaran, bukan kesalahan.
- Memenuhi FR-CYCLE-001.

**US-04 — Menambah pengeluaran tak terduga**

Sebagai pemilik, saya ingin menambah baris anggaran insidental seperti `bengkel`
atau `Barber`, supaya pengeluaran di luar rencana tetap tercatat tanpa mengotori
template bulan berikutnya.

- Baris baru bawaannya insidental.
- Baris insidental tidak terbawa saat rollover.
- Memenuhi FR-CYCLE-002 dan FR-TPL-001.

## Epik 2: Penghasilan freelance

Alur ini menggantikan penjumlahan jam manual dan perhitungan potongan tangan.

**US-05 — Mencatat jam kerja hari ini dengan cepat**

Sebagai pemilik, saya ingin mencatat jam kerja hari ini dalam satu layar singkat
dari ponsel, supaya saya tidak perlu membuka Google Form di laptop.

- Cukup mengisi tanggal dan jumlah jam.
- Selesai di bawah 15 detik.
- Memenuhi FR-TIME-001 dan NFR-UX-001.

**US-06 — Menandai awal periode tagihan**

Sebagai pemilik, saya ingin menandai sebuah entri sebagai hari buku baru, supaya
periode tagihan mengikuti kesepakatan kerja saya, bukan bulan kalender.

- Penanda membuka buku jam baru.
- Buku jam bisa membentang lintas bulan.
- Memenuhi FR-TIME-001 dan FR-TIME-002.

**US-07 — Menutup buku dan mendapat gaji bersih**

Sebagai pemilik, saya ingin menutup buku jam lalu langsung mendapat gaji bersih,
supaya saya tidak menjumlah jam dan menghitung pajak 2,5% dengan tangan.

- Gaji kotor dihitung dari total jam dikali tarif.
- Potongan diterapkan otomatis.
- Rincian gaji kotor, potongan, dan gaji bersih terlihat.
- Memenuhi FR-TIME-003 dan FR-INC-003.

**US-08 — Memasukkan gaji bersih ke bulan yang tepat**

Sebagai pemilik, saya ingin memilih siklus bulan mana yang menerima gaji bersih
dari sebuah buku jam, karena periode tagihan tidak selalu jatuh di bulan yang
sama.

- Baris pemasukan terisi otomatis dari hasil hitung.
- Memenuhi FR-TIME-003 dan FR-INC-002.

## Epik 3: Belanja

Alur ini menghapus penyalinan satu angka dari spreadsheet `bulanan`.

**US-09 — Menyusun daftar belanja mingguan dan bulanan**

Sebagai pemilik, saya ingin mengelola dua daftar belanja terpisah, supaya
struktur yang sudah saya pakai tetap sama.

- Daftar mingguan dan bulanan dikelola sendiri-sendiri.
- Tiap item punya nama, jumlah, dan harga satuan.
- Memenuhi FR-GROC-001.

**US-10 — Menimpa harga yang tidak sesuai perkalian**

Sebagai pemilik, saya ingin mengetik harga manual pada item tertentu, karena
kadang saya membeli sebagian saja atau mendapat harga berbeda.

- Harga bawaan tetap jumlah dikali harga satuan.
- Item yang harganya ditimpa diberi tanda.
- Memenuhi FR-GROC-002.

Cerita ini lahir dari data nyata: sampo tercatat `1 × Rp41.300` dengan harga
Rp24.000, dan popok tercatat `1 × Rp180.000` dengan harga Rp22.500.

**US-11 — Total belanja masuk anggaran otomatis**

Sebagai pemilik, saya ingin total belanja sebulan langsung menjadi satu baris
anggaran, supaya saya tidak mengetik ulang angkanya.

- Total dihitung sebagai subtotal mingguan dikali pengali minggu ditambah
  subtotal bulanan.
- Baris anggaran ikut berubah saat daftar belanja disunting.
- Memenuhi FR-GROC-003.

## Epik 4: Kartu kredit

Alur ini menghapus penjumlahan transaksi manual dan pengetikan ulang total.

**US-12 — Mencatat transaksi segera setelah terjadi**

Sebagai pemilik, saya ingin mencatat transaksi kartu dari ponsel begitu
transaksi terjadi, supaya tidak ada yang terlewat sampai akhir siklus.

- Transaksi masuk ke siklus yang sedang berjalan secara otomatis.
- Memenuhi FR-CARD-002 dan NFR-UX-001.

**US-13 — Menyimpan catatan tanpa mengotori nama merchant**

Sebagai pemilik, saya ingin menulis catatan seperti `cicilan 1` di kolom
terpisah, supaya nama merchant tetap bersih dan bisa dikenali sebagai langganan.

- Catatan disimpan terpisah dari nama merchant.
- Memenuhi FR-CARD-002.

**US-14 — Tidak mengetik ulang langganan tiap siklus**

Sebagai pemilik, saya ingin langganan seperti Netflix dan Claude AI disiapkan
otomatis tiap siklus baru, supaya saya tinggal mengonfirmasi.

- Transaksi langganan muncul menunggu konfirmasi.
- Nominal bisa disesuaikan sebelum dikonfirmasi, karena harga langganan berubah.
- Memenuhi FR-CARD-004.

**US-15 — Total tagihan masuk anggaran otomatis**

Sebagai pemilik, saya ingin total tiap siklus tagihan langsung menjadi baris
`CC TOKPED` atau `CC BRI TOUCH` di anggaran, supaya saya tidak menjumlah dan
menyalinnya.

- Baris anggaran ikut berubah saat transaksi disunting.
- Memenuhi FR-CARD-005.

## Epik 5: Investasi

Alur ini menggantikan perhitungan persentase manual dan pengecekan validator
secara visual.

**US-16 — Membagi sisa ke pos tujuan berdasarkan persentase**

Sebagai pemilik, saya ingin mengisi persentase tiap pos lalu nominalnya dihitung
otomatis, supaya saya tidak mengalikan sendiri.

- Budget investasi adalah sisa ditambah return deposit.
- Nominal tiap pos adalah budget dikali persentasenya.
- Memenuhi FR-INV-002.

**US-17 — Diperingatkan kalau persentase tidak genap 100**

Sebagai pemilik, saya ingin diperingatkan kalau total persentase bukan 100,
supaya tidak ada sisa yang menggantung tanpa tujuan.

- Jumlah persentase selalu terlihat.
- Jumlah 0 diterima sebagai tanda bulan itu belum dialokasikan.
- Memenuhi FR-INV-003.

**US-18 — Meminjam dana antar pos**

Sebagai pemilik, saya ingin mencatat peminjaman dana dari satu pos untuk
keperluan pos lain beserta pengembaliannya, supaya saldo tiap pos tetap benar.

- Pokok dan pengembalian dicatat terpisah, karena nilainya bisa berbeda.
- Saldo kedua pos ikut diperbarui.
- Memenuhi FR-INV-004 dan FR-INV-005.

Cerita ini lahir dari data nyata: pokok Rp9.300.000 dikembalikan Rp9.331.000.

**US-19 — Memakai satu daftar pos di semua tempat**

Sebagai pemilik, saya ingin daftar pos yang sama dipakai untuk alokasi maupun
pinjaman, supaya tidak ada pos yang tercatat di satu tempat tapi hilang di
tempat lain.

- Memenuhi FR-INV-001.

## Epik 6: Pindah dari spreadsheet

**US-20 — Membuka aplikasi dengan riwayat yang sudah ada**

Sebagai pemilik, saya ingin data November 2025 sampai September 2026 sudah ada
saat pertama membuka aplikasi, supaya saldo pos saya benar dan saya bisa
langsung melanjutkan, bukan memulai dari nol.

- Siklus bulanan, riwayat jam kerja, transaksi kartu, dan pos tujuan ikut
  termuat.
- Angkanya sama persis dengan spreadsheet asli.
- Memenuhi FR-SEED-001.

**US-21 — Percaya bahwa hitungannya benar**

Sebagai pemilik, saya ingin hasil hitung aplikasi sama persis dengan
spreadsheet saya, supaya saya berani berhenti membuka spreadsheet.

- Tidak ada selisih rupiah pada data historis.
- Memenuhi FR-CYCLE-004, NFR-ACC-001, dan NFR-ACC-002.

## Prioritas

Urutan ini menentukan susunan fase di
[ROADMAP](../04-planning/ROADMAP.md).

| Prioritas | Cerita | Alasan |
|---|---|---|
| Wajib | US-01 sampai US-04, US-21 | Siklus bulanan adalah inti produk. Tanpa ini tidak ada yang bisa dipakai. |
| Wajib | US-05 sampai US-08 | Penghasilan freelance berubah tiap bulan dan paling banyak menuntut hitungan manual. |
| Wajib | US-09 sampai US-15 | Dua titik salin manual yang tersisa. |
| Wajib | US-16 sampai US-19 | Melengkapi siklus bulanan sampai tuntas. |
| Sebaiknya | US-20 | Membuat aplikasi langsung berguna, tetapi aplikasi tetap jalan tanpanya. |

## Langkah berikutnya

Lanjutkan ke [PRD](prd-saldough-1.0.md) untuk kebutuhan lengkapnya, atau ke
[daftar tugas](../04-planning/TASK_LIST.md) untuk melihat urutan pengerjaannya.
