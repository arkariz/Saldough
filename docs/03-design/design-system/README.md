Tanukonomy adalah aplikasi Android dan iOS untuk mencatat keuangan pribadi: di mana uang berada (Dompet), apa yang terjadi padanya (Riwayat), dan ke mana ia direncanakan pergi (Anggaran). Aplikasi ini mencatat, tidak melakukan. Ia tidak memindahkan uang dan tidak terhubung ke bank. Maskotnya tanuki juru catat bertopi jerami.

Sikap desainnya: **buku catatan yang rapi**. Halaman bersih, tinta yang jelas, angka yang sejajar, dan warna yang dipakai seperti stabilo juru catat, sedikit dan selalu berarti. Kehangatan dan ciri khasnya datang dari tiga hal: maskot tanuki, terakota ikon aplikasi, dan aksen piksel yang terukur (sudut bertangga, ikon piksel, bar kotak-kotak). Teks dan angka tidak pernah berbentuk piksel.

## Prinsip

1. **Satu layar menjawab satu pertanyaan.** Beranda: "uangku aman?". Riwayat: "uangku ke mana?". Anggaran: "masih cukup?". Dompet: "uangku di mana?". Apa pun yang tidak menjawab pertanyaan itu pindah ke layar lain atau dihapus.
2. **Angka memimpin.** Tiap layar punya tepat satu angka utama bergaya `amount-hero`. Angka lain lebih kecil dan berurutan sesuai pentingnya.
3. **Warna berarti sesuatu.** Netral untuk semua hal biasa. `brand` untuk tindakan. `positive`, `warning`, `danger` hanya untuk status, dan selalu ditemani teks atau ikon. Pengeluaran berwarna `ink`, bukan merah.
4. **Kelompokkan dengan ruang, bukan garis.** Kartu `surface` di atas `bg`, jarak `space-6` antarbagian. Tanpa bingkai tebal, tanpa kartu di dalam kartu.
5. **Kata sehari-hari, satu istilah satu makna.** Lihat bagian Menulis. Hapus jargon seperti kas, log, netto, mutasi, inventaris.
6. **Jempol dulu.** Tindakan utama ada di bawah layar. Semua target sentuh minimal `size-touch` (48px).

## Konten

- Sapa pengguna dengan "kamu". Kalimat pendek, aktif, tanpa tanda seru.
- Huruf kapital hanya di awal kalimat dan nama diri: "Transaksi terbaru", bukan "TRANSAKSI TERBARU" atau "Transaksi Terbaru".
- Tombol diawali kata kerja dan menyebut hasilnya: "Simpan pengeluaran", "Tambah dompet", "Catat diterima".
- Nominal ditulis `Rp27.522.000`. Pengeluaran `−Rp45.000` (tanda minus U+2212), pemasukan `+Rp8.500.000`, transfer tanpa tanda.
- Tanggal relatif dulu: "Hari ini", "Kemarin", lalu "Sabtu, 26 Sep". Jam memakai titik: "08.00".
- Jangan menulis penafian atau "aturan" di layar ("Aturan Kas: Saldo Terpotong"). Labelnya sendiri harus sudah menjelaskan. Penjelasan sekali pakai masuk tur pertama kali.
- Glosarium, pola pesan galat, dan pola konfirmasi ada di bagian Menulis.

## Warna

- Latar halaman `bg`. Kartu, sheet, dan navigasi `surface`. Kontrol cekung (track segmen, chip, kolom cari, tombol keypad, tombol sekunder) `surface-2`. Ditekan: `surface-3`. Segmen terpilih `surface-raised`.
- Teks utama `ink`, pendukung `ink-2`, tersier `ink-3`. Ketiganya lolos 4,5:1 di `bg`, `surface`, dan `surface-2` di kedua tema.
- `brand` (terakota ikon aplikasi) untuk tombol utama, tombol Catat, dan tautan teks. Paling banyak satu tombol `brand` terisi per layar. Teks di atasnya `on-brand`. Pilihan aktif memakai `brand-soft` dengan teks `brand-ink`.
- `straw` hanya untuk aksen dekoratif dan ilustrasi. Jangan untuk teks.
- Nominal: pengeluaran `ink`, pemasukan `positive`, transfer `ink-2` dengan tile `info`. Merah tidak dipakai untuk pengeluaran biasa.
- Status anggaran: aman `ink` di bar dengan badge `positive`; 85% atau lebih `warning-fill` dengan badge `warning`; lewat `danger` dengan badge `danger` yang menyebut selisihnya.
- "Perlu dicek" dan "Tertunda" memakai `warning` di atas `warning-soft`.
- Warna kategori (`cat-*-bg` dengan ikon `cat-*`) hanya muncul di tile ikon. Jangan mewarnai teks atau latar baris dengan warna kategori.
- Snackbar `inverse-surface` dengan teks `on-inverse` dan aksi `inverse-brand`.
- Sheet dan dialog di atas `scrim`.

## Tipografi

- Satu keluarga huruf: Plus Jakarta Sans, buatan foundry Indonesia, sudah dibundel aplikasi (`fonts/PlusJakartaSans-Variable.ttf`). Fallback Roboto.
- Semua nominal memakai angka tabular (`font-variant-numeric: tabular-nums`) supaya digit sejajar di daftar.
- Skala: `headline` untuk judul halaman tab, `title` untuk judul bagian dan halaman turunan, `body-strong` untuk judul baris dan teks tombol standar, `body` untuk paragraf dan isi input, `body-sm` untuk subjudul dan bantuan, `label` untuk tombol kecil, chip, segmen, dan tautan, `label-sm` untuk navigasi dan badge, `caption` untuk meta.
- Angka: `amount-display` hanya di Catat, `amount-hero` satu per layar, `amount-lg` di kartu ringkasan, `amount` di baris daftar, `amount-sm` untuk angka pendukung.
- Teks terkecil 12px (`caption`, `label-sm`). Paragraf maksimal sekitar 60 karakter per baris.
- Tidak ada huruf kapital semua, tidak ada monospace, dan tidak ada huruf piksel. Piksel hidup di bentuk dan ikon, bukan di teks.
- Layout harus tetap utuh saat ukuran teks sistem 200%: teks boleh membungkus, tidak boleh terpotong.

## Ruang dan tata letak

- Grid 4px. Margin samping layar `space-4` (16px). Lebar desain acuan 360dp.
- Padding kartu dan baris `space-4`. Jarak antarbagian `space-6`. Jarak antarkartu dalam satu bagian `space-3`.
- Judul bagian (`title`) duduk di luar kartu, di atas `bg`, dengan tautan "Lihat semua" (`label`, warna `brand`) di kanan.
- Baris daftar minimal `size-row` (64px): tile ikon `size-tile`, jarak `space-3`, judul `body-strong`, subjudul `body-sm` `ink-2`, nominal rata kanan `amount`.
- Pemisah antarbaris memakai `line`, menjorok sejajar awal teks, bukan dari tepi kartu.
- Halaman tab: bar atas besar (`headline`), isi, navigasi bawah. Halaman turunan: tombol kembali, judul `title`, tindakan utama menempel di bawah.
- Struktur layar per halaman ada di bagian Pola layar.

## Bentuk dan kedalaman

- **Sudut piksel.** Semua permukaan bersudut tangga dua langkah, bukan lengkung halus. Kartu, daftar, banner, kartu saldo, snackbar, dialog, dan tombol Catat memakai langkah `pixel-step` (4px). Tombol, chip, badge, tile ikon, segmen, tombol keypad, dan kolom input memakai `pixel-step-sm` (2px). Token `radius-*` hanya untuk sudut atas sheet.
- Tanpa bingkai. Permukaan dibedakan dengan warna (`surface` di atas `bg`), bukan garis.
- Kartu rata tanpa bayangan. Bayangan halus `shadow-float` hanya untuk sheet, dialog, dan snackbar.
- **Bayangan piksel** (`shadow-pixel`, keras tanpa blur, warna `brand-deep`) khusus untuk tombol Catat. Ini satu-satunya sisa gaya bayangan lama.
- **Kartu saldo** (komponen HeroCard): satu blok terakota per layar untuk angka utama, dengan kepala tanuki mengintip dari tepi bawah. Hanya di Beranda dan halaman ringkasan.
- **Bar anggaran** tersusun dari kotak 6px dengan jarak 2px. Isi bar memakai warna status.

## Ikon

Dua set, dengan pembagian tegas:

- **Ikon piksel Tanukonomy** (grup aset "Ikon piksel", SVG 32×32) untuk *benda*: kategori, dompet, transfer, freelance, status pembayaran. Tampil selalu 32px (skala 1:1, `image-rendering: pixelated`) di tile `surface-2` 40px bersudut piksel. Jangan diskalakan ke ukuran lain selain 32px atau 64px.
- **Material Symbols Rounded** (24px, bobot 400) untuk *tindakan dan navigasi*: navigasi bawah, tombol ikon, chevron, ikon di baris form dan setelan. Tab aktif berisi 1.
- Kategori: Makan & Minum `category_food` (judul berisi "kopi" memakai `category_coffee`), Belanja Harian `category_groceries`, Transportasi `category_transport` ("bensin" memakai `category_fuel`), Tagihan `category_electricity`, Pulsa & Internet `category_internet`, Kesehatan `category_health`, Hiburan `category_entertainment`, Belanja `category_shopping`, Pendidikan `category_education`, Gaji `income`, Freelance `freelance`, Transfer `transfer`.
- Dompet: Bank `wallet_bank`, Dompet digital `wallet_ewallet`, Uang tunai `wallet_cash`, Tabungan `wallet_savings`, Kartu `wallet_card`.
- Belum ada ikon piksel untuk Keluarga, Donasi, Bonus, Hadiah, dan Lainnya. Sampai dibuat, kategori ini memakai Material Symbols (`family_restroom`, `volunteer_activism`, `stars`, `redeem`, `more_horiz`) di tile berwarna `cat-*`.
- Di mode gelap, garis tepi gelap ikon piksel menyatu dengan tile. Ikon tetap terbaca dari warnanya, tetapi varian bertepi terang perlu dibuat sebelum rilis mode gelap.
- Tanpa emoji di antarmuka.

## Ilustrasi dan maskot

- Ilustrasi tanuki dipakai di keadaan kosong, orientasi, momen selesai, dan kepala tanuki di kartu saldo. Di atas `bg`, `surface`, atau `brand`.
- Render dengan `image-rendering: pixelated` dan ukuran kelipatan bulat dari ukuran aslinya supaya piksel tetap tajam. Lebar 120–200px di keadaan kosong.
- Selain kartu saldo, jangan menaruh maskot di dalam kartu data atau di sebelah angka.
- Aset ada di grup Ilustrasi. Logo aplikasi ada di grup Logo; jangan digambar ulang.

## Gerak

- Durasi: 150ms untuk umpan balik tekan, 250ms untuk sheet dan peralihan kecil, 350ms untuk pindah halaman. Kurva standar (ease-out masuk, ease-in keluar).
- Tidak ada animasi bertangga piksel untuk antarmuka. Animasi maskot boleh di keadaan kosong dan orientasi.
- Hormati setelan kurangi gerakan: ganti geser dan skala dengan pudar, matikan shimmer skeleton.

## Keadaan

- Memuat: skeleton berbentuk isi aslinya (`surface-2`), bukan pemutar di tengah layar. Pemutar hanya di dalam tombol yang sedang menyimpan.
- Kosong: ilustrasi, judul `title` yang menyebut apa yang belum ada, satu kalimat manfaat, satu tombol. Lihat komponen EmptyState.
- Galat: sebut apa yang gagal dan cara memperbaikinya, dengan tombol "Coba lagi". Tanpa kode galat.
- Nonaktif: `opacity-disabled` dan alasan di dekatnya ("Pilih dompet dulu").
- Fokus keyboard: garis `focus` 2px dengan jarak 2px di semua kontrol.
- Tindakan yang bisa dibalik (hapus transaksi, abaikan tangkapan) tidak minta konfirmasi. Tampilkan snackbar dengan "Urungkan". Konfirmasi hanya untuk yang permanen (hapus dompet, hapus akun).

## Aksesibilitas

- Teks 4,5:1 di permukaannya, di kedua tema. Ikon bermakna, garis tepi input, dan isi progress bar minimal 3:1.
- Status tidak boleh dibedakan dengan warna saja: selalu ada kata ("Lewat Rp36.000") atau ikon.
- Pembaca layar membaca nominal lengkap: "minus empat puluh lima ribu rupiah", bukan "minus R P".
- Kontrol ikon saja punya label ("Cari", "Kembali", "Catat pakai suara").
