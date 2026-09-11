# Roadmap

Dokumen ini menjelaskan urutan pengerjaan Saldough dan alasan di balik
urutannya. Untuk daftar tugas yang bisa langsung dikerjakan beserta
progresnya, lihat [TASK_LIST.md](TASK_LIST.md).

## Prinsip penyusunan fase

Tiga aturan menentukan urutan di bawah ini.

**Risiko terbesar diuji lebih dulu.** Resolusi paket internal berpotensi gagal
karena deklarasi `resolution: workspace`. Kalau itu terjadi, seluruh rencana
arsitektur berubah. Karena itu resolusi dijadikan gerbang paling awal, bukan
detail teknis yang diurus sambil jalan.

**Setiap fase menghasilkan aplikasi yang tetap berjalan.** Tidak ada fase yang
meninggalkan aplikasi dalam keadaan rusak menunggu fase berikutnya.

**Urutan mengikuti aliran data, bukan kemudahan.** Siklus bulanan dikerjakan
lebih dulu karena semua fitur lain memasok angka ke sana. Membangun pemasok
sebelum penerimanya berarti tidak ada tempat untuk membuktikan hasilnya benar.

## Ringkasan fase

| Fase | Nama | Hasil |
|---|---|---|
| 0 | Gerbang dependensi | Resolusi paket terbukti berhasil |
| 1 | Fondasi | Aplikasi berjalan dengan tema, terjemahan, DI, dan rute |
| 2 | Siklus bulanan | Inti produk bisa dipakai |
| 3 | Pemasukan dan timesheet | Penghasilan freelance terhitung otomatis |
| 4 | Roll-up | Tiga titik salin manual hilang |
| 5 | Investasi | Siklus bulanan lengkap |
| 6 | Seed | Riwayat spreadsheet tersedia di aplikasi |
| 7 | Sinkronisasi | Di luar MVP |

Fase 0 sampai 6 membentuk MVP. Fase 7 dikerjakan setelahnya.

## Fase 0: Gerbang dependensi

Membuktikan bahwa paket internal bisa di-resolve dari repositori terpisah.

Fase ini adalah gerbang. Tidak ada pekerjaan Fase 1 yang dimulai sebelum
`flutter pub get` berhasil, karena kegagalan di sini mengubah cara seluruh
aplikasi disusun.

Kalau resolusi gagal, jalur pemulihan yang sudah disetujui adalah mendorong
branch kompatibilitas di `advance-mobile-platform` yang melepas
`resolution: workspace` pada paket yang dipakai. Rinciannya ada di
[ADR-0001](../02-architecture/adr/0001-internal-package-dependency-strategy.md).

**Selesai kalau:** `flutter pub get` dan `flutter analyze` berjalan bersih pada
proyek kosong yang sudah menarik seluruh paket internal.

## Fase 1: Fondasi

Menyiapkan kerangka aplikasi tanpa fitur domain.

Isi fase ini adalah lapisan tema beserta tokennya, penyiapan slang dua bahasa,
bootstrap dua fase dengan `DiBoot`, registri rute, penangan efek, dan widget
bersama seperti `AppCard` dan `AppMoneyText`.

Widget bersama sengaja dibuat di fase ini, bukan nanti saat pengulangan sudah
terlanjur muncul. Di `new-health-duel`, dekorasi kartu yang sama terulang di
sekitar delapan berkas justru karena widget bersamanya tidak pernah dibuat.

Pemformat uang juga masuk fase ini, karena aturan pembulatan setengah ke atas
dari satuan sen harus ada sebelum ada layar yang menampilkan nominal.

**Selesai kalau:** aplikasi berjalan di Android dan iOS, menampilkan satu layar
contoh dengan tema terang dan gelap, teks dari slang, dan navigasi lewat efek.

## Fase 2: Siklus bulanan

Membangun inti produk.

Fase ini mencakup entitas `MonthlyCycle`, baris pemasukan dan anggaran, rumus
total dan sisa, tampilan siklus, penyuntingan baris, serta template dan
rollover.

Rollover dengan penanda perlu ditinjau adalah bagian terpenting, karena inilah
yang menjawab nyeri utama pemilik. Rinciannya ada di
[ADR-0008](../02-architecture/adr/0008-monthly-cycle-template-and-rollup.md).

Baris roll-up sudah dikenali jenisnya di fase ini, tetapi sumbernya baru ada di
Fase 4. Sampai itu, baris roll-up ditampilkan bernilai nol dengan penanda bahwa
sumbernya belum tersedia.

**Selesai kalau:** pemilik bisa membuat siklus, menyunting baris, melihat sisa
termasuk sisa negatif, dan membuat bulan berikutnya lewat rollover.

## Fase 3: Pemasukan dan timesheet

Menghapus perhitungan gaji manual.

Fase ini mencakup sumber pemasukan dengan tiga tipenya, aturan potongan
persentase dan nominal tetap, pencatatan jam kerja, pengelompokan ke buku jam
lewat penanda hari buku baru, serta penutupan buku yang menghasilkan gaji bersih
dan menyuntikkannya ke baris pemasukan.

Fase ini butuh satu jawaban dari pemilik sebelum bisa selesai, yaitu tarif per
jam pada sumber `Gaji Menul`. Nilai itu tidak tercatat di spreadsheet mana pun
dan tidak bisa disimpulkan balik dari data yang ada.

**Selesai kalau:** menutup satu buku jam menghasilkan gaji bersih yang sama
persis dengan catatan spreadsheet untuk bulan yang sama.

## Fase 4: Roll-up

Menghapus tiga titik salin manual yang tersisa.

Fase ini mencakup rencana belanja dengan daftar mingguan dan bulanan beserta
harga timpaan, kartu kredit dengan siklus tagihan dan transaksi, langganan
berulang, dan penyambungan keduanya ke baris anggaran roll-up.

Setelah fase ini, tidak ada lagi angka yang perlu disalin antar dokumen. Ini
tonggak terpenting produk: sejak titik ini, aplikasi sudah lebih baik daripada
spreadsheet untuk pemakaian sehari-hari.

**Selesai kalau:** menyunting daftar belanja atau menambah transaksi kartu
langsung mengubah baris anggaran tanpa tindakan tambahan.

## Fase 5: Investasi

Melengkapi siklus bulanan sampai tuntas.

Fase ini mencakup pos tujuan bersaldo, alokasi persentase dengan validasi total
100, pinjaman antar pos, dan riwayat pergerakan saldo tiap pos.

Fase ini terakhir di antara fitur domain karena bergantung pada sisa, yang baru
benar setelah pemasukan dan seluruh roll-up tersedia.

**Selesai kalau:** alokasi menghasilkan nominal yang sama persis dengan
spreadsheet, dan saldo pos memperhitungkan alokasi maupun pinjaman.

## Fase 6: Seed

Menulis data historis yang pemilik punya langsung ke penyimpanan lokal,
sekali jalan, lewat skrip pengembang — BUKAN fitur di dalam aplikasi.

> **Catatan revisi (11 September 2026):** fase ini semula dibayangkan
> sebagai layar impor di dalam aplikasi ("Impor Seed") yang memuat rentang
> tetap November 2025–September 2026. Pemilik memutuskan sebaliknya:
> operasi sekali pakai tanpa UI dan tanpa versi produksi (tidak ikut
> ter-*build* ke rilis), cakupan data mengikuti apa yang pemilik benar-
> benar punya saat skrip dijalankan — bisa sebagian, bisa tidak mencakup
> semua jenis data sama sekali. Lihat ADR-0009 untuk pola implementasinya
> (`tool/`, bukan `features/seed/`).

Fase ini tetap jadi pembuktian menyeluruh untuk data yang diimpor: kalau
angkanya cocok persis dengan spreadsheet asli, aplikasi terbukti bisa
dipercaya untuk bagian itu.

Fase ini butuh data historis sungguhan dari pemilik sebelum bisa dikerjakan
— tiga jawaban terkonfirmasi sebelumnya (saldo awal tiap pos tujuan,
tanggal cetak tagihan tiap kartu, kepastian pos pinjaman sama dengan pos
alokasi) sudah terjawab, tapi datanya sendiri (isi keempat spreadsheet)
belum tersedia di repositori ini.

**Selesai kalau:** seluruh data yang pemilik sediakan termuat dan tidak ada
satu pun selisih rupiah terhadap spreadsheet, untuk bagian yang diimpor.

## Fase 7: Sinkronisasi

Di luar MVP. Mencakup sinkronisasi ke Firebase atau Google Drive, dan rumah
tangga dua pengguna.

Keputusan penyimpanan berbasis dokumen JSON di
[ADR-0002](../02-architecture/adr/0002-local-first-hive-document-storage.md)
sengaja menyiapkan jalan ke sini, karena dokumen JSON bisa dipetakan langsung ke
dokumen Firestore atau berkas di Drive.

Fase ini juga yang menghidupkan `api_network` dan `dio_network`, dua paket
internal yang sengaja ditunda pada MVP.

## Ketergantungan antar fase

```
Fase 0 ──► Fase 1 ──► Fase 2 ──┬──► Fase 3 ──┐
                                │             ├──► Fase 5 ──► Fase 6 ──► Fase 7
                                └──► Fase 4 ──┘
```

Fase 3 dan Fase 4 tidak saling bergantung dan bisa dikerjakan dalam urutan mana
pun setelah Fase 2 selesai.

## Yang bisa dikerjakan lebih awal

Tiga pertanyaan terbuka di
[PRD bagian 13](../01-product/prd-saldough-1.0.md) sebaiknya dijawab pemilik
sebelum fase yang membutuhkannya dimulai, supaya tidak menjadi penghambat.

| Pertanyaan | Dibutuhkan pada |
|---|---|
| Tarif per jam `Gaji Menul` | Fase 3 |
| Tanggal cetak tagihan tiap kartu | Fase 4 |
| Saldo awal tiap pos tujuan | Fase 6 |
| Apakah pos pinjaman sama dengan pos alokasi | Fase 5 |
