# User stories

Dokumen ini menerjemahkan kebutuhan fungsional di
[PRD](prd-saldough-2.0.md) menjadi cerita dari sudut pandang pengguna. Gunakan
dokumen ini saat merancang alur layar; gunakan PRD saat memastikan kelengkapan
kebutuhan.

Semua cerita memakai satu peran, yaitu **pengguna** — satu orang yang mengelola
keuangan pribadinya sendiri di satu perangkat. Pemilik adalah pengguna pertama
dan satu-satunya penguji MVP. Peran kedua baru muncul pada tahap sinkronisasi.

> **Catatan versi (17 September 2026):** Seluruh cerita di dokumen ini ditulis
> ulang untuk Saldough 2.0. Cerita 1.0 berporos pada siklus bulanan spreadsheet
> dan sudah tidak punya rujukan di produk maupun kode. Versi lamanya bisa dibaca
> lewat riwayat git.
>
> Cerita US-21 sampai US-24 ditambahkan belakangan, saat PRD ditulis ulang
> setingkat produk. Keduanya sengaja diletakkan di ujung epiknya masing-masing
> alih-alih disisipkan di tengah, supaya nomor cerita yang sudah ada tidak
> bergeser.

## Epik 1: Tahu uang saya di mana

**US-01 — Melihat seluruh uang saya dalam satu layar**

Sebagai pengguna, saya ingin melihat total uang saya beserta rinciannya per
dompet dalam satu layar, supaya saya tidak perlu membuka aplikasi bank satu per
satu untuk tahu posisi keuangan saya.

- Total saldo seluruh dompet aktif tampil paling menonjol.
- Tiap dompet menampilkan nama, ikon, dan saldo tercatatnya.
- Saldo negatif ditampilkan apa adanya dengan tanda minus, bukan ditolak.
- Memenuhi FR-WAL-003 dan FR-HOME-001.

**US-02 — Mendaftarkan tempat uang saya berada**

Sebagai pengguna, saya ingin mendaftarkan rekening, uang tunai, dan dompet
digital saya beserta saldonya hari ini, supaya aplikasi punya titik awal yang
benar.

- Saya mengisi nama, ikon, dan saldo awal.
- Saldo awal adalah pernyataan keadaan, bukan transaksi setoran, jadi ia tidak
  muncul sebagai pemasukan di riwayat.
- Kalau saya salah mengetik saldo awalnya, saya bisa membetulkannya belakangan
  dan seluruh saldo ikut dihitung ulang.
- Memenuhi FR-WAL-001 dan FR-WAL-002.

**US-03 — Menelusuri apa saja yang terjadi pada satu dompet**

Sebagai pengguna, saya ingin membuka satu dompet dan melihat transaksi apa saja
yang menyentuhnya, supaya saya bisa mencocokkan saldo tercatat dengan saldo
sebenarnya.

- Rincian dompet menampilkan transaksi terbarunya.
- Ada jalan ke daftar transaksi lengkap yang sudah tersaring ke dompet itu.
- Ada pintasan mencatat transaksi dengan dompet ini sudah terpilih.
- Memenuhi FR-WAL-004 dan FR-REC-002.

## Epik 2: Mencatat yang terjadi

**US-04 — Mencatat pengeluaran sambil berdiri di kasir**

Sebagai pengguna, saya ingin mencatat pengeluaran dalam hitungan detik lewat satu
tombol yang selalu ada di tempat yang sama, supaya saya benar-benar mencatatnya
dan tidak menundanya sampai lupa.

- Tombol CATAT selalu ada di tengah navigasi bawah dan dibedakan secara visual.
- Satu ketukan membuka pilihan pemasukan, pengeluaran, atau transfer.
- Seluruh pengisian selesai dalam satu layar tanpa berpindah halaman.
- Memenuhi FR-REC-001, FR-TXN-002, dan NFR-UX-001.

**US-05 — Mencatat pemasukan yang masuk**

Sebagai pengguna, saya ingin mencatat uang yang masuk beserta dompet tujuannya,
supaya saldo saya ikut naik dan sumbernya tetap tercatat.

- Saya mengisi nominal, dompet tujuan, tanggal, dan kategori.
- Saldo dompet tujuan bertambah sebesar nominal itu.
- Memenuhi FR-TXN-001.

**US-06 — Mencatat pemindahan uang antar dompet**

Sebagai pengguna, saya ingin mencatat bahwa saya memindahkan uang dari satu
dompet ke dompet lain, supaya kedua saldo ikut berubah tanpa membuat total uang
saya terlihat bertambah atau berkurang.

- Dompet asal berkurang dan dompet tujuan bertambah dengan nominal yang sama.
- Total saldo seluruh dompet tidak berubah sama sekali.
- Layarnya menyatakan dengan jelas bahwa aplikasi hanya mencatat, bukan
  memindahkan uang sungguhan.
- Memenuhi FR-TXN-003 dan NFR-UX-005.

**US-07 — Menelusuri riwayat dan menyaringnya**

Sebagai pengguna, saya ingin melihat seluruh transaksi saya terkelompok per
tanggal dan bisa menyaringnya, supaya saya bisa mencari satu pengeluaran tanpa
menggulir berbulan-bulan.

- Transaksi terurut dari yang terbaru dan dikelompokkan per tanggal.
- Ada penyaring jenis, dompet, dan kategori.
- Pemasukan, pengeluaran, dan transfer bisa dibedakan sekilas.
- Memenuhi FR-TXN-004.

**US-08 — Membetulkan catatan yang salah**

Sebagai pengguna, saya ingin menyunting atau menghapus transaksi yang saya catat
keliru, supaya saldo saya kembali benar tanpa perlu mencatat transaksi
penyeimbang.

- Seluruh field bisa disunting, termasuk dompetnya.
- Saldo dompet lama dan dompet baru sama-sama dihitung ulang saat dompetnya
  berpindah.
- Penghapusan meminta konfirmasi dan mengembalikan saldo ke keadaan sebelumnya.
- Memenuhi FR-TXN-005.

Cerita ini lahir dari kesalahan nyata di Saldough 1.0: sebuah baris berlabel
"Kos agustus - september" terbawa keliru selama tiga bulan berturut-turut karena
membetulkannya terasa lebih repot daripada membiarkannya.

**US-21 — Membuka satu transaksi dan melihat seluruh ceritanya**

Sebagai pengguna, saya ingin menekan satu baris transaksi dan melihat seluruh
keterangannya, supaya saya bisa mengingat kembali apa yang terjadi tanpa
menebak dari nominalnya saja.

- Jenis, nominal, kategori, dompet, tanggal, dan catatan tampil bersama.
- Anggaran dan pos yang tertaut ikut tampil kalau ada, beserta jalan ke sana.
- Transfer tampil sebagai "Dari", "Ke", dan "Jumlah" di bawah judul **Transfer
  tercatat** — bukan "Transfer berhasil".
- Sunting dan hapus bisa dilakukan dari layar itu juga.
- Memenuhi FR-TXN-006.

## Epik 3: Merencanakan pengeluaran

**US-09 — Merencanakan tanpa uang saya ikut terpotong**

Sebagai pengguna, saya ingin membuat anggaran belanja tanpa saldo dompet saya
ikut berkurang, supaya rencana dan kenyataan tidak tercampur.

- Membuat anggaran Rp3.000.000 dari dompet BCA tidak mengubah saldo BCA sama
  sekali.
- Saldo baru berubah kalau saya mencatat pengeluaran sungguhan.
- Memenuhi FR-BUD-001.

**US-10 — Menjalankan beberapa anggaran sekaligus**

Sebagai pengguna, saya ingin punya beberapa anggaran aktif berbarengan dengan
periode yang berbeda-beda, supaya belanja mingguan dan tagihan bulanan tidak
harus dipaksa masuk ke satu kotak yang sama.

- Saya tidak perlu menutup satu anggaran sebelum membuat yang lain.
- Beberapa anggaran boleh memakai dompet yang sama.
- Satu anggaran boleh mingguan sementara yang lain bulanan.
- Memenuhi FR-BUD-001.

**US-11 — Merinci anggaran jadi daftar belanja**

Sebagai pengguna, saya ingin memecah anggaran jadi pos-pos dengan jumlah dan
harga satuan, supaya daftar belanja bulanan saya tetap serinci sebelumnya.

- Tiap pos punya nama dan nominal rencana.
- Pos yang berupa barang belanjaan bisa diisi jumlah dan harga satuan, dan
  nominalnya dihitung dari keduanya.
- Saya bisa melihat selisih antara jumlah seluruh pos dan nominal anggaran.
- Memenuhi FR-BUD-002.

**US-12 — Tahu sisa anggaran sebelum memutuskan membeli**

Sebagai pengguna, saya ingin melihat berapa yang sudah terpakai dan berapa
sisanya per pos, supaya saya bisa memutuskan di tempat apakah sebuah pembelian
masih masuk anggaran.

- Pengeluaran yang saya tautkan ke sebuah pos langsung menambah angka
  terpakainya.
- Tiap pos menampilkan status: belum terpakai, terpakai sebagian, selesai, atau
  lewat anggaran.
- Pos yang lewat anggaran ditandai jelas, bukan diperlakukan sebagai kesalahan.
- Memenuhi FR-BUD-003 dan FR-BUD-004.

**US-13 — Menganggarkan setoran tabungan, bukan cuma belanja**

Sebagai pengguna, saya ingin membuat anggaran untuk uang yang saya sisihkan ke
tabungan, supaya rencana menabung saya terlihat dan terlacak sama seperti
rencana belanja.

- Anggaran `Tabungan` dari dompet BCA saya penuhi dengan mentransfer ke dompet
  Tabungan, bukan dengan mengeluarkan uang.
- Transfer itu menambah angka terpakai pos anggarannya, tetapi tidak mengubah
  total uang saya.
- Satu transfer hanya terhitung di satu anggaran, meski dompet tujuannya juga
  punya anggaran sendiri.
- Memenuhi FR-BUD-003 dan FR-TXN-003.

Cerita ini lahir dari kebiasaan nyata pemilik membagi sisa bulanan ke enam pos
tabungan. Di Saldough 1.0 itu fitur tersendiri; di 2.0 ia cuma transfer yang
ditautkan ke pos anggaran.

**US-14 — Menemukan anggaran yang saya cari di antara banyak anggaran**

Sebagai pengguna, saya ingin melihat ringkasan seluruh anggaran sekaligus lalu
menyaringnya, supaya punya beberapa anggaran aktif tidak membuat layarnya jadi
sulit dibaca.

- Puncak layar menampilkan total rencana, total terpakai, dan total sisa dari
  seluruh anggaran aktif.
- Tiap kartu menampilkan nama, dompet, periode, rencana, terpakai, sisa,
  progres, dan status — dompetnya terbaca tanpa membuka anggarannya.
- Saya bisa menyaring berdasarkan status dan berdasarkan dompet.
- Anggaran yang sudah tidak saya pakai bisa saya arsipkan tanpa menghapus
  transaksinya.
- Memenuhi FR-BUD-004, FR-BUD-006, dan FR-BUD-001.

**US-15 — Tidak menyusun ulang anggaran yang sama tiap bulan**

Sebagai pengguna, saya ingin menyimpan susunan anggaran yang berulang sebagai
template, supaya bulan berikutnya saya tinggal memakainya lagi.

- Template bisa dibuat, disunting, digandakan, diaktifkan, dan dinonaktifkan.
- Anggaran yang lahir dari template berdiri sendiri, dan menyuntingnya tidak
  mengubah templatenya.
- Memenuhi FR-BUD-005.

**US-22 — Membuka satu anggaran dan mencatat langsung dari sana**

Sebagai pengguna, saya ingin membuka satu anggaran, melihat seluruh posnya, dan
mencatat pengeluaran langsung dari layar itu, supaya saya tidak perlu mengingat
sendiri pos mana yang sedang saya belanjakan.

- Nama, dompet, periode, dan angka anggaran tampil di puncak.
- Tiap pos menampilkan rencana, terpakai, sisa, progres, dan statusnya.
- Transaksi yang sudah tertaut ke anggaran itu ikut tampil.
- Pintasan **Catat Pengeluaran** dan **Catat Transfer** membuka CATAT dengan
  dompet dan pos sudah terpilih, bukan formulir tersendiri.
- Memenuhi FR-BUD-007 dan FR-REC-002.

## Epik 4: Penghasilan freelance

**US-16 — Mencatat jam kerja tanpa menganggapnya sudah cair**

Sebagai pengguna, saya ingin mencatat jam kerja freelance saya dan melihat berapa
yang sudah saya peroleh, tanpa angka itu masuk ke saldo dompet saya, supaya saya
tidak merasa punya uang yang sebenarnya belum diterima.

- Saya mencatat proyek, tanggal, dan jumlah jam.
- Aplikasi menghitung nominal yang diperoleh dari jam dikali tarif.
- Saldo dompet saya tidak berubah sama sekali.
- Memenuhi FR-FRL-002.

**US-17 — Menagih beberapa hari kerja sebagai satu pembayaran**

Sebagai pengguna, saya ingin menggabungkan beberapa hari kerja jadi satu
pembayaran beserta potongannya, supaya saya tahu berapa bersih yang akan saya
terima dan kapan.

- Beberapa entri worklog digabung jadi satu pembayaran.
- Gaji kotor, potongan, dan gaji bersihnya terlihat terpisah.
- Periodenya tidak harus mengikuti batas bulan kalender.
- Memenuhi FR-FRL-003.

Periode tagihan nyata pemilik pernah membentang dari delapan hari sampai hampir
sebulan, misalnya 29 Oktober sampai 26 November 2025.

**US-18 — Mencatat pembayaran yang akhirnya cair**

Sebagai pengguna, saya ingin mencatat bahwa sebuah pembayaran freelance sudah
saya terima beserta dompet tujuannya, supaya saldo saya naik tepat sekali dan
statusnya berubah jadi sudah dibayar.

- Pencatatan itu membuat tepat satu transaksi pemasukan sebesar gaji bersih.
- Pembayaran yang sama tidak bisa dicatat dua kali.
- Layarnya menyatakan ini pencatatan, bukan aplikasi yang membayarkan.
- Memenuhi FR-FRL-004 dan NFR-UX-005.

**US-19 — Melihat berapa yang masih menggantung**

Sebagai pengguna, saya ingin melihat total penghasilan freelance yang sudah saya
kerjakan tetapi belum dibayar, supaya saya tahu berapa yang masih ditunggu.

- Ringkasannya muncul di Beranda hanya kalau memang ada yang tertunda.
- Dari situ saya bisa masuk ke daftar worklog dan pembayaran.
- Memenuhi FR-FRL-005 dan FR-HOME-003.

**US-23 — Tidak mengetik ulang tarif klien yang sama tiap kali**

Sebagai pengguna, saya ingin menyimpan klien yang berulang beserta tarif,
potongan, dompet, dan jadwal pembayarannya, supaya proyek berikutnya dari klien
yang sama tinggal dibuat dari situ.

- Template menyimpan proyek atau klien, tarif per jam, potongan, dompet bawaan,
  dan jadwal pembayaran.
- Template bisa dibuat, disunting, digandakan, diaktifkan, dinonaktifkan, dan
  dihapus.
- Proyek yang dibuat dari template adalah salinan mandiri; menyunting
  templatenya tidak mengubah proyek yang sudah berjalan.
- Template tidak pernah mengubah saldo dompet mana pun.
- Di luar MVP wajib; dikerjakan di Fase 7.
- Memenuhi FR-FRL-006.

## Epik 5: Gambaran sehari-hari

**US-20 — Membaca posisi bulan ini sekali lihat**

Sebagai pengguna, saya ingin satu layar yang menjawab berapa uang saya, berapa
yang masuk dan keluar bulan ini, dan bagaimana anggaran saya berjalan, supaya
saya tidak perlu menyusun gambaran itu sendiri dari beberapa layar.

- Total saldo, pemasukan bulan berjalan, dan pengeluaran bulan berjalan tampil
  bersama.
- Transfer tidak ikut dihitung sebagai pemasukan maupun pengeluaran.
- Ringkasan anggaran dan transaksi terbaru ikut tampil.
- Memenuhi FR-HOME-001, FR-HOME-002, dan FR-HOME-004.

**US-24 — Tahu harus mulai dari mana saat aplikasinya masih kosong**

Sebagai pengguna, saya ingin aplikasi memberi tahu langkah pertama saat belum
ada apa-apa di dalamnya, supaya saya tidak berhadapan dengan layar berisi angka
nol dan menyerah di hari pertama.

- Selama belum ada dompet, layar mengarahkan membuat dompet pertama beserta
  saldo awalnya.
- Selama belum ada transaksi, layar menampilkan "Belum ada transaksi" beserta
  ajakan **Catat Transaksi**.
- Ajakan itu membuka alur CATAT yang sama, bukan formulir tersendiri.
- Kartu ringkasan yang belum punya isi disembunyikan, bukan ditampilkan sebagai
  deretan nol.
- Memenuhi FR-HOME-005.

## Prioritas

Urutan pengerjaan mengikuti loop inti produk: tempat uang dulu, lalu peristiwa,
baru rencana.

| Prioritas | Cerita | Alasan |
|---|---|---|
| 1 | US-02, US-05, US-04, US-06 | Tanpa dompet dan transaksi, tidak ada satu pun angka yang bisa ditampilkan |
| 2 | US-01, US-03, US-07, US-08, US-21 | Membaca dan membetulkan apa yang sudah dicatat |
| 3 | US-09 sampai US-14, US-22 | Anggaran butuh transaksi lebih dulu supaya progresnya punya isi |
| 4 | US-16 sampai US-19 | Freelance adalah domain pendukung, bukan inti |
| 5 | US-20, US-24 | Beranda baru bermakna setelah semua di atas menghasilkan data |
| 6 | US-15, US-23 | Template mempercepat pekerjaan yang sudah terbukti berjalan, jadi ia yang terakhir |

## Langkah berikutnya

Lanjutkan ke [DOMAIN_MODEL.md](../02-architecture/DOMAIN_MODEL.md) untuk melihat
entitas dan rumus yang mendukung cerita di atas, atau ke
[TASK_LIST.md](../04-planning/TASK_LIST.md) untuk melihat urutan pengerjaannya.
