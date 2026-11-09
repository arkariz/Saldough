# Rencana konten Threads: 4 minggu pertama sesudah rilis

**Tanggal:** 9 November 2026
**Status:** Draf untuk pemilik; belum ada yang diunggah
**Versi aplikasi acuan:** `1.0.0+23` (produksi)
**Rujukan:** [PLAY_STORE_LISTING.md](PLAY_STORE_LISTING.md) §5 (klaim yang
dihindari), [PLAY_DATA_SAFETY.md](PLAY_DATA_SAFETY.md),
[ADR-041](../02-architecture/adr/0041-monetisasi-hak-plus-dan-uji-coba.md) §3.6
(batas Gratis), [ADR-044](../02-architecture/adr/0044-catat-dari-notifikasi-v2.md)
§3.8 (Gratis dan Plus di Catat dari notifikasi)

Dokumen ini berisi rencana dan naskah siap unggah untuk akun Threads
Tanukonomy, atau akun pribadi pemilik. Postingan ditulis dari sudut pandang
pemilik sebagai pembuat aplikasi ("aku"), karena di Threads orang lebih mudah
percaya pada pembuat yang bercerita daripada pada akun merek yang beriklan.

## 1. Tujuan dan ukuran

Ukurannya bukan jumlah pengikut, melainkan **pemasangan yang datang dari
Threads dan bertahan**.

| Ukuran | Sumber | Target 4 minggu (hipotesis, sesuaikan sesudah minggu 1) |
|---|---|---|
| Klik ke Play Store | Tautan pendek atau jumlah kunjungan listing | Dicatat per postingan |
| Pemasangan dari Threads | Play Console › Statistik › Akuisisi, sumber `utm_source=threads` | 50 |
| Masih mencatat di minggu kedua | Firebase Analytics, kohort per minggu pasang | Dibandingkan dengan sumber lain |
| Balasan per postingan | Threads Insights | Postingan dengan balasan terbanyak dijadikan pola |

### Tautan Play Store dengan UTM

Pakai satu kode kampanye per postingan supaya terlihat postingan mana yang
mendatangkan pemasangan:

```
https://play.google.com/store/apps/details?id=com.arkarizdev.tanukonomy&referrer=utm_source%3Dthreads%26utm_medium%3Dsocial%26utm_campaign%3D<kode>
```

`<kode>` mengikuti kolom **Kode** di kalender (§4), mis. `w1-notif`.

## 2. Aturan main

1. **Ritme:** 3–4 postingan per minggu, lebih baik rutin daripada banyak.
   Balas setiap komentar, terutama di jam pertama sesudah unggah.
2. **Satu postingan, satu gagasan.** Setiap postingan di bawah 500 karakter
   (batas Threads); kalau lebih, jadikan utas.
3. **Satu topik per postingan.** Usulan topik ada di kalender; pilih yang
   paling sesuai di kolom topik Threads.
4. **Tautan:** uji dua cara di minggu 1, yaitu tautan di badan postingan dan
   tautan di balasan pertama. Pakai cara yang klik dan jangkauannya lebih baik.
   Tautan Play Store juga dipasang di bio.
5. **Media:** rekaman layar pendek (10–20 detik, tanpa suara pun tetap jelas)
   lebih kuat daripada tangkapan layar diam. Pakai data contoh, jangan data
   keuangan pribadi.
6. **Gaya bahasa:** "aku" dan "kamu", santai, tanpa huruf kapital semua,
   paling banyak satu emoji. Kosakata produk tetap berlaku: aplikasi
   **mencatat**, bukan **melakukan** ("catat transfer", bukan "transfer").

### Klaim yang boleh dan tidak

Semua postingan harus benar terhadap aplikasi `1.0.0+23`.

| Boleh | Jangan |
|---|---|
| "Tidak terhubung ke bank, tidak minta kata sandi bank" | "100% privat", "tanpa pelacakan" (Analytics dan Crashlytics ada) |
| "Catatan keuanganmu tersimpan di ponsel" | "Tidak ada data yang keluar dari ponsel" (teks Catat Cerdas dikirim ke Gemini) |
| "Catat manual tetap jalan tanpa internet" | "Offline sepenuhnya" (suara dan Catat Cerdas butuh internet) |
| "Gratis dipakai, ada Plus untuk fitur tambahan" | "Gratis selamanya", "terbaik", "#1" |
| "Catat dari notifikasi, di Android" | Menyebut fitur ini ada di iPhone |
| Nama bank dan e-wallet sebagai contoh notifikasi yang dibaca | Menyiratkan kerja sama atau dukungan resmi dari bank atau e-wallet |

**Gratis dan Plus di Catat dari notifikasi** (ADR-041 §3.6, ADR-044 §3.8):
Gratis membaca **1 aplikasi sumber** (bawaan Remote Config
`free_notification_sources`) dan membuka Catat yang sudah terisi untuk
diperiksa. Satu ketuk di kartu, tombol Catat di notifikasi, Catat semua, dan
catat otomatis per bentuk notifikasi hanya untuk Plus. Postingan demo yang
memperlihatkan satu ketuk atau catat otomatis wajib menyebut "dengan Plus".

## 3. Empat pilar konten

| Pilar | Isi | Porsi |
|---|---|---|
| **Cerita pembuat** | Membangun aplikasi sendirian, angka nyata, yang gagal | 1 per minggu |
| **Masalah uang sehari-hari** | Gajian cepat habis, transfer dikira pengeluaran, freelance telat dibayar | 1 per minggu |
| **Demo fitur** | Rekaman layar satu fitur dengan satu manfaat | 1 per minggu |
| **Ngobrol** | Pertanyaan, jajak pendapat, minta masukan | 1 per minggu |

## 4. Kalender

Hari hanya usulan. Teks lengkap di §5. Tanda `[…]` wajib diisi atau dicocokkan
pemilik sebelum diunggah.

| Minggu | Hari | No | Pilar | Judul kerja | Media | Kode |
|---|---|---|---|---|---|---|
| 1 | Sen | P1 | Cerita pembuat | Perkenalan | Foto layar Beranda | `w1-intro` |
| 1 | Rab | P2 | Demo fitur | Catat dari notifikasi | Rekaman layar 15 detik | `w1-notif` |
| 1 | Jum | P3 | Ngobrol | Bulan dimulai tanggal gajian | Tanpa media / jajak pendapat | `w1-gajian` |
| 2 | Sen | P4 | Masalah sehari-hari | Transfer bukan pengeluaran | Tangkapan layar Catat Transfer | `w2-transfer` |
| 2 | Rab | P5 | Masalah sehari-hari | Utas freelance (4 bagian) | Tangkapan layar Freelance | `w2-freelance` |
| 2 | Jum | P6 | Cerita pembuat | Anggaran itu rencana | Tanpa media | `w2-anggaran` |
| 3 | Sen | P7 | Demo fitur | Catat pakai suara | Rekaman layar 10 detik | `w3-suara` |
| 3 | Rab | P8 | Masalah sehari-hari | Total langganan bulanan | Tangkapan layar segmen Rutin | `w3-rutin` |
| 3 | Jum | P9 | Ngobrol | Tim matcha atau pink | Dua tangkapan layar tema | `w3-tema` |
| 4 | Sen | P10 | Cerita pembuat | Aman kasih akses notifikasi? | Tanpa media | `w4-privasi` |
| 4 | Rab | P11 | Demo fitur | Datamu bisa dibawa pergi | Rekaman layar ekspor | `w4-ekspor` |
| 4 | Jum | P12 | Cerita pembuat | Angka 4 minggu pertama | Tanpa media | `w4-angka` |
| 4 | Min | P13 | Ngobrol | Apa yang paling bikin kesal? | Tanpa media | `w4-masukan` |

## 5. Naskah

### P1 — Perkenalan

> Halo Threads. Aku bikin aplikasi catatan keuangan sendirian, dan baru saja
> rilis di Play Store.
>
> Namanya Tanukonomy. Maskotnya tanuki juru catat.
>
> Awalnya buat diriku sendiri: gaji tetap plus freelance, uang tersebar di
> beberapa rekening dan e-wallet, dan tiap akhir bulan bingung uangnya ke mana.
>
> Di akun ini aku mau cerita prosesnya, termasuk yang gagal. Kalau kamu juga
> sering merasa "kok gajian cepat habis", ikuti saja.

Topik: Keuangan Pribadi. Pemilik cocokkan klaim "sendirian".

### P2 — Catat dari notifikasi

> Alasan paling sering yang kudengar kenapa orang berhenti mencatat keuangan:
> capek mengetik tiap jajan.
>
> Jadi fitur yang paling kuseriusi di Tanukonomy: catat dari notifikasi.
>
> Bayar pakai m-banking atau e-wallet, notifikasinya masuk, lalu Tanukonomy
> menyusun catatannya: nominal, dompet, kategori. Kamu tinggal cek dan simpan.
>
> Hanya di Android, dan kamu sendiri yang memilih aplikasi mana yang boleh
> dibaca.

Media: rekaman bayar, notifikasi masuk, Catat terisi, Simpan. Kalau rekaman
memakai satu ketuk atau catat otomatis, tambahkan kalimat "Dengan Plus, cukup
satu ketuk."

### P3 — Bulan dimulai tanggal gajian

> Pertanyaan buat yang gajian bulanan: kamu menghitung "bulan" dari tanggal 1
> atau dari tanggal gajian?
>
> Aku dari tanggal [tanggal gajian pemilik]. Makanya di Tanukonomy awal bulan
> keuangan bisa diatur sendiri, tanggal 1 sampai 28 atau hari terakhir bulan.
> Ringkasan bulan ini, anggaran, dan analisisnya ikut tanggal itu.
>
> Kamu tanggal berapa?

Pakai jajak pendapat Threads kalau tersedia: "Tanggal 1", "Tanggal 25",
"Akhir bulan", "Tidak tentu".

### P4 — Transfer bukan pengeluaran

> Kesalahan yang paling sering kulakukan waktu mencatat keuangan di
> spreadsheet: memindahkan uang dari rekening ke e-wallet kucatat sebagai
> pengeluaran.
>
> Hasilnya laporan bulanan bilang aku boros, padahal uangnya cuma pindah
> tempat.
>
> Di Tanukonomy, transfer antar dompet dicatat terpisah. Total uangmu tetap,
> hanya tempatnya yang berubah. Tidak dihitung pemasukan, tidak dihitung
> pengeluaran.

### P5 — Utas freelance

> (1/4) Utas buat freelancer: kenapa "kerja selesai" belum berarti "uang
> masuk".

> (2/4) Dulu aku mencatat freelance begini: proyek selesai, langsung kutulis
> plus Rp5 juta. Lalu klien membayar tiga minggu kemudian, kadang dicicil.
> Akibatnya aku merasa lebih kaya daripada kenyataannya.

> (3/4) Sekarang di Tanukonomy kupisah. Jam kerja dicatat per proyek, lalu
> dikelompokkan jadi tagihan. Saldo dompet baru bertambah waktu pembayarannya
> benar-benar diterima.

> (4/4) Jadi ada dua angka yang terlihat jelas bedanya: berapa yang sudah
> kamu kerjakan, dan berapa yang sudah benar-benar ada di rekening. Freelance
> dibuka dari Catat, lalu Catat Pemasukan.

Pemilik cocokkan contoh "Rp5 juta, tiga minggu" dengan pengalaman sendiri.

### P6 — Anggaran itu rencana

> Hal yang baru kusadari waktu membuat fitur anggaran: anggaran itu rencana,
> bukan uang yang dikunci.
>
> Membuat anggaran makan Rp1,5 juta tidak membuat saldomu berkurang Rp1,5
> juta. Saldo baru berkurang waktu kamu benar-benar belanja.
>
> Kedengarannya sepele, tapi aku sering bingung sendiri waktu dua hal itu
> tercampur. Jadi di Tanukonomy keduanya terpisah: saldo di Dompet, rencana
> di Rencana.

### P7 — Catat pakai suara

> Tekan lama tombol Catat, lalu bilang "makan siang 35 ribu".
>
> Tanukonomy mengisi formulirnya: nominal, jenis, kategori. Kalau kamu
> menyebut nama dompetnya, dompetnya ikut terisi. Kamu tinggal cek lalu
> simpan.
>
> Fitur ini butuh internet karena ucapanmu ditafsirkan Gemini. Tanpa sinyal,
> catat manual tetap jalan.

Media: rekaman tekan lama, bicara, formulir terisi. Pemilik cek di build
produksi bahwa nama dompet memang ikut terisi.

### P8 — Total langganan bulanan

> Coba hitung: berapa total langganan bulananmu? Streaming, penyimpanan awan,
> gym, cicilan.
>
> Aku kaget waktu pertama menjumlahkan punyaku.
>
> Di Tanukonomy kamu bisa mencatat tagihan rutin, dapat pengingat, dan melihat
> totalnya. Waktu tagihannya datang dan nominalnya tetap, cukup konfirmasi
> satu ketuk.

### P9 — Tim matcha atau pink

> Pertanyaan penting yang tidak ada hubungannya dengan uang: tim matcha atau
> tim pink?
>
> Tanukonomy sekarang punya dua pilihan warna di Akun › Tampilan. Aku
> memakai [pilihan pemilik].
>
> Kalau kamu boleh menambah satu warna lagi, warna apa?

Media: dua tangkapan layar Beranda berdampingan, data contoh.

### P10 — Aman kasih akses notifikasi?

> Pertanyaan yang paling sering kuterima: "Aman nggak kasih akses notifikasi?"
>
> Jawaban jujurnya:
> • Kamu sendiri yang memilih aplikasi mana yang dibaca. Yang lain diabaikan.
> • Notifikasi OTP tidak diproses.
> • Teks notifikasi disimpan di ponsel paling lama 7 hari.
> • Kalau teksnya sulit dibaca, teks itu dikirim ke Gemini dengan saldo dan
>   nomor rekening disamarkan.
> • Tanukonomy tidak terhubung ke bank dan tidak minta kata sandi bank.

Sebelum diunggah, cocokkan dengan kebijakan privasi situs (lihat B-20, T-26.27).

### P11 — Datamu bisa dibawa pergi

> Datamu milikmu, bukan milik aplikasinya.
>
> Di Tanukonomy kamu bisa mengekspor semua catatan ke spreadsheet (xlsx atau
> CSV) kapan saja, dan membuat berkas cadangan untuk dipindahkan ke ponsel
> baru.
>
> Kalau suatu hari kamu berhenti memakainya, catatanmu tetap bisa kamu bawa.

Media: Akun › Data kamu › Ekspor ke spreadsheet, berkas terbuka di Sheets.

### P12 — Angka 4 minggu pertama

> Laporan jujur 4 minggu sejak Tanukonomy rilis:
>
> • [X] pemasangan
> • [Y]% masih mencatat di minggu kedua
> • Fitur yang paling sering dipakai: [fitur]
> • Keluhan terbanyak: [keluhan], dan ini yang sedang kuperbaiki
>
> Terima kasih buat yang sudah mencoba dan memberi masukan. Pelajaran
> terbesarku sejauh ini: [satu kalimat].

Angka dari Play Console dan Firebase Analytics. Jangan dibulatkan ke atas.

### P13 — Apa yang paling bikin kesal?

> Buat yang sudah memakai Tanukonomy seminggu lebih: satu hal yang paling
> bikin kamu kesal apa?
>
> Aku baca semua balasan. [Kalau sudah ada: "Perbaikan X di pembaruan
> terakhir datang dari komentar di sini."]
>
> Kalau menurutmu aplikasinya berguna, ulasan di Play Store sangat membantu
> aplikasi kecil seperti ini ditemukan orang lain.

Jangan menawarkan imbalan untuk ulasan dan jangan meminta bintang tertentu
(kebijakan Play).

## 6. Jawaban siap pakai untuk komentar

| Pertanyaan | Jawaban |
|---|---|
| Ada di iPhone? | Belum, sekarang baru Android. Kalau versi iPhone sudah siap, aku umumkan di sini. |
| Gratis? | Gratis dipakai: catat, dompet, anggaran, rutin, freelance, analisis. Ada Plus untuk fitur tambahan seperti catat satu ketuk dari notifikasi dan lebih banyak aplikasi sumber. [Pemilik cocokkan dengan status penjualan Plus, `plus_launch_at`.] |
| Bank atau e-wallet apa saja? | Tanukonomy membaca notifikasi dari aplikasi yang kamu pilih. Kalau ada yang belum terbaca dengan benar, kirimi aku contohnya (tanpa nomor rekening) supaya bisa kuperbaiki. |
| Tersambung ke rekening? | Tidak. Tanukonomy hanya mencatat. Tidak ada kata sandi bank dan tidak ada akses ke rekening. |
| Kalau ganti ponsel? | Buat cadangan di Akun › Data kamu, lalu pulihkan di ponsel baru. |
| Harus punya akun? | Tidak wajib. Akun opsional. |

## 7. Sesudah 4 minggu

1. Urutkan postingan menurut pemasangan (kode UTM) dan balasan.
2. Pilar yang paling banyak mendatangkan pemasangan dapat porsi dua kali lipat
   di bulan berikutnya.
3. Pertanyaan yang berulang di komentar dijadikan postingan sendiri.
4. Catat hasilnya di bawah dokumen ini sebagai bahan bulan kedua.
