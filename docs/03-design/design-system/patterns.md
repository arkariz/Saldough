# Pola layar

## Navigasi

- Navigasi bawah berisi empat tujuan dan tombol Catat di tengah: Beranda, Riwayat, [Catat], Anggaran, Dompet. Tombol Catat adalah satu-satunya pintu mencatat transaksi manual.
- Catat pakai suara ada di dalam sheet Catat (tombol mikrofon di bar atas sheet). Tekan lama tombol Catat langsung membuka mode suara. Tidak ada tombol melayang kedua.
- Akun dibuka dari tombol profil di kanan atas Beranda. Freelance dibuka dari kartu Freelance di Beranda. Kotak masuk notifikasi dibuka dari banner di Beranda dan Riwayat, dan dari Akun.
- Halaman turunan (rincian anggaran, rincian dompet, freelance, kotak masuk, akun) menyembunyikan navigasi bawah dan memakai tombol kembali.

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
