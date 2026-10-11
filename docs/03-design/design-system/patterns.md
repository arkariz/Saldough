# Pola layar

## Navigasi

- Navigasi bawah berisi empat tujuan dan tombol Catat di tengah: Beranda, Riwayat, [Catat], Anggaran, Dompet. Tombol Catat adalah satu-satunya pintu mencatat transaksi manual.
- Catat pakai suara ada di dalam sheet Catat (tombol mikrofon di bar atas sheet). Tekan lama tombol Catat langsung membuka mode suara. Tidak ada tombol melayang kedua.
- Akun dibuka dari tombol profil di kanan atas Beranda. Freelance dibuka dari kartu Freelance di Beranda. Kotak masuk notifikasi dibuka dari banner di Beranda dan Riwayat, dan dari Akun.
- Halaman turunan (rincian anggaran, rincian dompet, freelance, kotak masuk, akun) menyembunyikan navigasi bawah dan memakai tombol kembali.
- Tab yang punya beberapa bagian setara memakai SubTabs tepat di bawah bar atas: Rencana (Bulan ini, Anggaran, Rutin) dan Riwayat (Daftar, Analisis). Riwayat mengingat segmen terakhir; pintu dari kartu Arus Beranda selalu membuka Analisis.

## Anatomi halaman tab

1. Bar atas besar: judul `headline` di kiri, paling banyak dua tombol ikon di kanan.
2. Angka utama halaman (`amount-hero`) dengan label `body-sm` di atasnya.
3. Paling banyak satu banner perhatian.
4. Bagian-bagian: judul bagian di atas `bg`, isi di kartu `surface`.
5. Ruang bawah `space-12` supaya isi terakhir tidak tertutup navigasi.

## Anatomi halaman turunan

1. Bar atas: kembali, judul `title`, menu lainnya.
2. Ringkasan di atas, rincian di bawah.
3. Satu tindakan utama menempel di bawah layar (`shadow-bar` di atasnya), lebar penuh.

## Daftar

- Riwayat dikelompokkan per hari. Kepala grup: "Hari ini · Senin, 28 Sep" di kiri, selisih hari itu di kanan (`amount-sm`, `ink-2`).
- Satu kartu per grup, baris dipisahkan `line` yang menjorok.
- Baris transaksi: tile kategori (ikon piksel), judul (catatan, atau nama kategori bila catatan kosong), subjudul "Dompet · jam", nominal bertanda di kanan.
- Baris yang menunggu tindakan (dari notifikasi) memakai badge "Perlu dicek", bukan latar berwarna.

## Form dan Catat

- Semua form muncul sebagai sheet dari bawah. Catat memakai sheet tinggi penuh.
- Urutan Catat: jenis (kontrol segmen) → nominal (keypad) → kategori (chip, kategori terakhir dipakai di depan) → dompet → tanggal → catatan → Simpan.
- Nilai bawaan pintar: dompet terakhir dipakai, tanggal hari ini, kategori yang paling sering di jam yang sama.
- Akibat ke saldo ditulis satu kali sebagai bantuan di bawah baris dompet ("Saldo Tunai jadi Rp331.000"), bukan banner aturan dan ringkasan ganda.
- Tombol Simpan menyebut jenisnya ("Simpan pengeluaran") dan nonaktif sampai nominal dan dompet terisi.

## Ringkasan dulu, rincian kemudian

- Beranda: total saldo → yang perlu tindakan → bulan ini → anggaran → freelance → transaksi terbaru.
- Anggaran: sisa → bar dengan penanda waktu → daftar pos → transaksi tertaut.
- Dompet: total → sebaran per dompet → daftar dompet.

## Penanda waktu anggaran

Bar anggaran memuat garis tipis `ink` yang menandai seberapa jauh periode sudah berjalan. Bila isi bar ada di kiri garis, belanja lebih lambat dari waktu ("Aman"). Bila di kanan dan sudah 85% atau lebih, statusnya "Hampir habis".

## Keadaan per layar

Setiap layar punya empat keadaan yang dirancang: memuat (skeleton), kosong (EmptyState), galat (pesan + Coba lagi), dan berisi. Keadaan kosong pertama kali di Beranda berupa daftar langkah: tambah dompet, catat transaksi pertama, buat anggaran (opsional).

## Periode keuangan

- "Bulan" di aplikasi adalah periode keuangan yang dimulai di tanggal pilihan pengguna (1–28 atau hari terakhir bulan). Namanya mengikuti PeriodHeader: nama bulan bila mulai tanggal 1, selain itu rentangnya.
- Satu-satunya tempat mengubah awal bulan keuangan: ketuk PeriodHeader di Rencana › Bulan ini, atau baris "Awal bulan keuangan" di Akun. Keduanya membuka lembar DayPicker yang sama.
- Periode peralihan diberi penanda netral "Periode peralihan · {n} hari" di Bulan ini, kepala kartu Arus Beranda, dan kepala Analisis. Penanda ini keterangan, tidak pernah memakai warna atau ikon peringatan. Peringatan tetap hanya untuk risiko berbasis saldo (siapkan dana, titik terendah negatif).

## Analisis

Riwayat › Analisis menjawab "uangku ke mana, dibanding biasanya". Hanya membaca, tanpa perkiraan.

1. PeriodStepper (‹ periode ›, maju berhenti di periode berjalan).
2. SegmentedControl Pengeluaran / Pemasukan, lalu chip penyaring dompet "Semua dompet ▾".
3. Kartu ringkasan: label, total (`amount-hero`), pembanding `tk-cmp`, lalu 0–3 sorotan sebagai baris bertautan di kartu yang sama.
4. Daftar kategori dengan ShareRow: lima teratas, Lainnya yang bisa dibuka, lalu kartu Tanpa kategori dengan "Beri kategori".
5. Baris informasi transfer di luar kartu.
6. Bagian "6 bulan terakhir" dengan TrendChart dan readout periode terpilih.

Nada netral di seluruh layar: tanpa `warning` atau `danger`, tanpa `≈`, tanpa bingkai putus-putus. Arah perubahan disampaikan oleh panah `ink-2` dan kata, bukan warna.

