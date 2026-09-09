# Analisis proses manual

Dokumen ini merekam cara pemilik Saldough mengelola keuangannya hari ini
menggunakan empat Google Spreadsheet yang saling mereferensi secara manual.
Semua dokumen lain dalam repositori ini diturunkan dari sini: PRD mengambil
kebutuhannya dari kolom "nyeri" di bawah, dan `DOMAIN_MODEL.md` mengambil
entitas serta rumusnya dari struktur tabel yang direkam di sini.

Setiap rumus dalam dokumen ini sudah diuji terhadap angka asli di spreadsheet.
Angka buktinya ikut dicantumkan supaya siapa pun bisa memverifikasi ulang tanpa
membuka spreadsheet.

> **Catatan:** Dokumen ini mendeskripsikan proses **yang sedang berjalan**,
> bukan rancangan aplikasi. Jangan menambahkan ide fitur di sini. Ide fitur
> masuk ke [PRD](../01-product/prd-saldough-1.0.md).

**Sumber data:** empat spreadsheet milik `muhammadrisky1401@gmail.com`, dibaca
pada 9 September 2026.

| Spreadsheet | Peran |
|---|---|
| `Anggaran 2026` | Buku utama. Satu blok tabel per bulan. |
| `bulanan` | Daftar belanja mingguan dan bulanan. |
| `Pencatatan jam kerja (Responses)` | Timesheet freelance dari Google Form. |
| `Tokopedia Card Transaction`, `BRI Touch Transaction` | Transaksi kartu kredit per siklus tagihan. |

## Peta aliran data

Tiga spreadsheet satelit menghitung satu angka masing-masing, lalu angka itu
disalin dengan tangan menjadi satu baris di spreadsheet utama. Titik salin
manual inilah yang paling sering menimbulkan kerja berulang dan salah ketik.

```
Pencatatan jam kerja ──► Total Jam per periode ──► Gaji Kotor ──┐
                                                                 ├──► PEMASUKAN
                                              Gaji tetap ────────┘        │
                                                                          ▼
bulanan ──────────────► Total sebulan ─────────► baris "Bulanan" ──┐      │
                                                                    ├──► ANGGARAN
Tokopedia Card ───────► Total per siklus ──────► baris "CC TOKPED" ─┤   SEBULAN
BRI Touch Card ───────► Total per siklus ──────► baris "CC BRI TOUCH"┘     │
                                                                          ▼
                                                    Sisa = Pemasukan − Anggaran
                                                                          │
                                                                          ▼
                                                     Alokasi investasi per pos
```

## Spreadsheet utama: `Anggaran 2026`

Spreadsheet ini berisi satu blok tabel per bulan, disusun berurutan ke bawah.
Setiap blok punya lima bagian tetap dan dua bagian yang hanya muncul sesekali.

### Bagian 1: PEMASUKAN

Daftar sumber pemasukan bulan itu beserta nominalnya, dengan satu sel `Total`
hasil penjumlahan.

| Pemasukan | nominal | Total |
|---|---|---|
| Gaji Menul | Rp3.039.563 | Rp15.839.563 |
| Gaji Koko | Rp12.800.000 | |

Baris di bagian ini berubah tiap bulan. Selain dua baris tetap di atas, muncul
juga baris insidental seperti `THR Laufey`, `Anggaran Pindah`, `Sisa pindah
kos`, `Course bci`, dan `Ambil 'belum teralokasi'`.

Dua sumber pemasukan bersifat tetap secara struktur:

- **Gaji Koko** adalah gaji bulanan tetap. Nilainya stabil di Rp12.800.000
  selama beberapa bulan terakhir.
- **Gaji Menul** adalah penghasilan freelance per jam. Nilainya berubah tiap
  bulan mengikuti jumlah jam kerja, dan dihitung di sub-tabel terpisah.

### Bagian 2: sub-tabel Gaji Menul

Sub-tabel di bagian bawah blok yang menurunkan gaji bersih dari gaji kotor.

| Gaji Kotor | Potongan | Nominal | Gaji Bersih |
|---|---|---|---|
| Rp3.117.500 | Pajak | Rp77.938 | Rp3.039.563 |
| Rp3.117.500 | jajan | | |

Gaji kotor berasal dari total jam kerja pada spreadsheet timesheet. Gaji bersih
adalah gaji kotor dikurangi seluruh potongan, dan angka inilah yang masuk ke
baris `Gaji Menul` di bagian PEMASUKAN.

**Rumus pajak: 2,5% dari gaji kotor.** Rumus ini konsisten di seluruh tujuh
bulan yang punya data:

| Gaji Kotor | Pajak | Pajak ÷ Kotor |
|---|---|---|
| Rp7.350.000 | Rp183.750 | 2,5% |
| Rp1.050.000 | Rp26.250 | 2,5% |
| Rp1.740.000 | Rp43.500 | 2,5% |
| Rp1.960.000 | Rp49.000 | 2,5% |
| Rp2.682.500 | Rp67.063 | 2,5% (dibulatkan dari 67.062,5) |
| Rp3.117.500 | Rp77.938 | 2,5% (dibulatkan dari 77.937,5) |
| Rp1.087.500 | Rp27.188 | 2,5% (dibulatkan dari 27.187,5) |

Potongan lain bersifat insidental dan bernominal tetap, bukan persentase.
Contoh yang ditemukan: `jajan` Rp150.000 dan `webinar` Rp150.000. Baris
potongan `jajan` sering ada tetapi kosong nominalnya.

Pembulatan pajak mengikuti pembulatan setengah ke atas.

### Bagian 3: ANGGARAN SEBULAN

Daftar kebutuhan bulan itu, dengan sel `Total` dan sel `Sisa`.

| Kebutuhan | nominal | Total | Sisa |
|---|---|---|---|
| Kos agustus - september | Rp1.900.000 | Rp13.382.490 | Rp2.457.073 |
| listrik | Rp200.000 | | |
| Bulanan | Rp3.068.500 | | |
| Sabil | Rp800.000 | | |
| Cicilan iphone | Rp2.914.000 | | |
| CC TOKPED | Rp1.386.516 | | |
| tabung | | | |

Baris di bagian ini terbagi dua jenis yang berperilaku berbeda:

- **Baris tetap** muncul hampir setiap bulan: `Kos`, `listrik`,
  `makan` atau `Bulanan`, `Sabil`, `Sisihkan rumah`, `Wifi`, `Laundry`,
  `CC TOKPED`, `CC BRI TOUCH`, dan `tabung`.
- **Baris insidental** hanya muncul di bulan tertentu: `Kulkas`, `kasur`,
  `bengkel`, `Cicilan iphone`, `Donasi`, `Barber`, `Jajan`, `kipas portable`,
  `Pelunasan pelatihan ABA`, `MamyPoko`, `Sufor`, `Gas`, dan lainnya.

Tiga baris tetap nilainya tidak diketik langsung, melainkan disalin dari
spreadsheet lain: `Bulanan` dari spreadsheet `bulanan`, serta `CC TOKPED` dan
`CC BRI TOUCH` dari spreadsheet kartu kredit masing-masing.

**Rumus sisa: total pemasukan dikurangi total anggaran.** Sisa boleh bernilai
negatif, dan pada praktiknya memang pernah negatif.

| Bukti | Pemasukan | Anggaran | Sisa |
|---|---|---|---|
| Blok dengan Bulanan Rp3.068.500 | Rp15.839.563 | Rp13.382.490 | Rp2.457.073 |
| Blok Kos April - Mei | Rp8.900.000 | Rp10.237.042 | −Rp1.337.042 |

Nilai negatif harus diperlakukan sebagai kondisi lewat anggaran yang valid dan
perlu ditampilkan, bukan sebagai kesalahan input.

Label `Kos` sering tidak ikut diperbarui saat blok bulan baru disalin. Tiga blok
berurutan sama-sama berlabel `Kos agustus - september` meski mewakili tiga bulan
berbeda. Ini bukti langsung bahwa penyalinan template dilakukan manual dan rawan
tertinggal.

### Bagian 4: budgeting investasi

Sisa bulan itu dibagi ke enam pos tujuan berdasarkan persentase.

| Sisa gaji | return deposit | Budget |
|---|---|---|
| Rp3.086.960 | Rp0 | Rp3.086.960 |

| Tujuan | Persentase | Nominal |
|---|---|---|
| ANAK | 15 | Rp463.044 |
| RUMAH | 15 | Rp463.044 |
| PENSIUN | 15 | Rp463.044 |
| SEKOLAH | 0 | Rp0 |
| KYOTO | 55 | Rp1.697.828 |
| SAHAM | 0 | Rp0 |

Rumusnya dua tahap. Budget adalah sisa gaji ditambah return deposit, lalu
nominal tiap pos adalah budget dikali persentasenya.

Bukti dari blok dengan sisa Rp3.086.960: `3.086.960 × 15% = 463.044` dan
`3.086.960 × 55% = 1.697.828`. Bukti dari blok dengan sisa Rp5.370.616:
`5.370.616 × 20% = 1.074.123` dan `5.370.616 × 40% = 2.148.246`.

Ada satu sel di pojok kanan tabel yang berisi jumlah seluruh persentase.
Sel ini berfungsi sebagai validator: nilainya harus 100 saat alokasi diisi,
dan 0 saat bulan itu belum dialokasikan. Enam nama pos bersifat tetap dan tidak
pernah berubah antar bulan.

### Bagian 5: pinjaman antar pos

Bagian ini hanya muncul di sebagian bulan. Isinya pencatatan peminjaman dana
dari satu pos tujuan untuk keperluan pos lain.

| Jumlah pinjaman | pengembalian | Jumlah awal | Sumber Dana | Tujuan | Saldo |
|---|---|---|---|---|---|
| Rp9.300.000 | Rp9.331.000 | Rp15.563.000 | Travel To Japan | Kuliah tata | Rp15.594.000 |

Nilai pengembalian di contoh ini lebih besar dari pokok pinjaman, selisih
Rp31.000. Model data harus mengizinkan pengembalian berbeda dari pokok, jadi
pokok dan pengembalian disimpan sebagai dua nilai terpisah.

Perhatikan bahwa nama pos di bagian ini (`Travel To Japan`, `Kuliah tata`)
berbeda dari enam nama pos di bagian alokasi investasi. Keduanya adalah pos
tujuan, tetapi daftarnya tidak sinkron antar bagian.

### Bagian 6: saldo akun investasi

Muncul sekali saja, di blok `Kos Mei - Juni`, sebagai catatan lepas di sisi kiri
tanpa rumus yang menghubungkannya ke bagian lain.

Permata Rp3.213.000, Capital Rp1.000.000, Finansia Rp14.835.000.

## Spreadsheet `bulanan`

Spreadsheet ini merinci belanja kebutuhan rumah tangga dalam dua daftar
terpisah, lalu menggabungkannya menjadi satu angka bulanan.

Kedua daftar punya struktur kolom sama: nama bahan, jumlah, harga satuan, dan
harga.

| Daftar | Jumlah item | Subtotal |
|---|---|---|
| Mingguan | 18 | Rp576.600 |
| Bulanan | 18 | Rp762.100 |

Daftar mingguan berisi bahan segar yang habis tiap minggu: ikan kembung, dada
ayam, udang, tempe, buncis, egg tofu, brokoli, wortel, telur, pepaya, edamame,
SKM, kopi, air mineral, santan, alpukat, dan bawang. Daftar bulanan berisi
kebutuhan yang bertahan sebulan: jeruk, beras, saos sambal, susu UHT, sampo,
minyak goreng, puff pastry, mixed berry, sereal, sabun, tisu basah, oat, telur
asin, nutrijell, nata de coco, popok, bensin, dan penyedap.

**Rumus total sebulan: subtotal mingguan dikali empat, ditambah subtotal
bulanan.**

Bukti: `576.600 × 4 + 762.100 = 3.068.500`. Angka ini sama persis dengan baris
`Bulanan` senilai Rp3.068.500 di spreadsheet utama.

Pengali empat adalah asumsi jumlah minggu dalam sebulan, bukan jumlah minggu
kalender sebenarnya. Aplikasi harus memperlakukannya sebagai nilai yang bisa
diubah, dengan default empat.

Kolom `Harga` tidak selalu sama dengan jumlah dikali harga satuan. Dua contoh
menunjukkan koreksi manual:

| Item | Jumlah | Harga Satuan | Harga tercatat | Hasil perkalian |
|---|---|---|---|---|
| sampo | 1 | Rp41.300 | Rp24.000 | Rp41.300 |
| popok | 1 | Rp180.000 | Rp22.500 | Rp180.000 |

Model data tidak boleh memaksa harga sama dengan hasil perkalian. Harus ada
kemungkinan menimpa nilai hasil hitung dengan angka manual.

Spreadsheet ini juga punya satu sel lepas berlabel `kembalikan` senilai
Rp1.050.473, yang mencatat sisa uang belanja yang dikembalikan.

## Spreadsheet `Pencatatan jam kerja (Responses)`

Spreadsheet ini merekam jam kerja freelance harian dan mengelompokkannya ke
dalam periode tagihan.

Sheet pertama adalah hasil Google Form dengan tiga kolom.

| Timestamp | Jumlah jam kerja hari ini | Hari buku baru |
|---|---|---|
| 8/29/2026 20:03:18 | 6 | Ya |
| 9/5/2026 21:08:44 | 5 | |

Kolom `Hari buku baru` adalah penanda kunci. Nilai `Ya` menandakan bahwa entri
tersebut memulai periode tagihan baru. Periode tagihan tidak mengikuti bulan
kalender, sehingga penanda ini adalah satu-satunya cara menentukan batas
periode.

Sheet berikutnya adalah rekapitulasi manual per periode, satu sheet per periode.

| Tanggal | Hari | Jumlah Jam | Total Jam |
|---|---|---|---|
| 1 Agustus 2026 | Sabtu | 7 | 43 |
| 2 Agustus 2026 | Minggu | 6 | |
| 8 Agustus 2026 | Sabtu | 5 | |

Kolom `Total Jam` hanya diisi di baris pertama dan berisi jumlah seluruh jam
dalam periode itu. Angka inilah yang direferensikan menjadi gaji kotor di
spreadsheet utama.

Beberapa periode yang terekam beserta total jamnya:

| Periode | Total Jam |
|---|---|
| 29 Agustus – 5 September 2026 | 15 |
| 1 – 23 Agustus 2026 | 43 |
| 4 – 26 Juli 2026 | 37 |
| 30 Mei – 27 Juni 2026 | 37 |
| 29 Oktober – 26 November 2025 | 125 |
| 1 – 28 Desember 2025 | 105 |

Panjang periode sangat bervariasi, dari delapan hari sampai hampir satu bulan
penuh. Ini menegaskan bahwa periode ditentukan oleh penanda `Hari buku baru`,
bukan oleh tanggal.

Tarif per jam tidak tercatat di spreadsheet mana pun. Tarif ini perlu
dikonfirmasi ke pemilik saat implementasi, dan sementara diperlakukan sebagai
nilai yang dikonfigurasi pengguna.

## Spreadsheet kartu kredit

Ada dua spreadsheet dengan struktur identik, satu per kartu: `Tokopedia Card
Transaction` dan `BRI Touch Transaction`. Masing-masing berisi satu blok tabel
per siklus tagihan.

| Tanggal | Merchant | Nominal Transaksi | Total |
|---|---|---|---|
| 16 Juli 2026 17:30 | GOJEK RECURRING NON3DS | Rp9.000 | Rp1.386.516 |
| 24 Juli 2026 08:00 | Claude ai | Rp358.600 | |
| 1 Agustus 2026 22:35 | Netflix.com | Rp65.000 | |

Sama seperti timesheet, kolom `Total` hanya diisi di baris pertama dan berisi
jumlah seluruh transaksi dalam siklus itu. Angka inilah yang menjadi baris
`CC TOKPED` atau `CC BRI TOUCH` di spreadsheet utama.

Siklus tagihan berjalan kira-kira dari tanggal 16 sampai tanggal 15 bulan
berikutnya, tetapi batasnya tidak konsisten dan tampaknya mengikuti tanggal
cetak tagihan dari penerbit kartu.

Sebagian merchant muncul berulang setiap siklus dengan nominal tetap. Pola ini
adalah langganan, dan bisa disiapkan otomatis alih-alih diketik ulang.

| Merchant | Pola |
|---|---|
| Netflix.com | Rp65.000 tiap siklus, tanggal 1 sampai 2 |
| GOJEK RECURRING NON3DS | berulang, nominal bervariasi |
| Claude AI | sekitar Rp337.760 sampai Rp358.600 tiap siklus |
| Github Copilot | sekitar Rp171.930 sampai Rp176.690 tiap siklus |

Kolom merchant juga dipakai menampung catatan bebas, karena tidak ada kolom
khusus catatan. Contoh yang ditemukan: `PT Tokopedia cicilan 1`, `ulanzi tripod
canceled?`, `PT Tokopedia - listrik (sudah ada di jago tagihan CC)`, dan sel
lepas `Belum tercatat belanja tokopedia Rp1.029.836`. Model data perlu
menyediakan kolom catatan terpisah supaya nama merchant tetap bersih dan bisa
dicocokkan dengan template langganan.

## Ringkasan nyeri dan kebutuhan

Tabel ini menghubungkan setiap kerja manual yang berulang dengan kemampuan yang
harus disediakan aplikasi. Setiap baris di sini wajib punya minimal satu
requirement di [PRD](../01-product/prd-saldough-1.0.md).

| Nyeri proses manual | Yang harus dilakukan aplikasi |
|---|---|
| Menyalin blok bulan lalu, lalu menyunting baris satu per satu. Label lama sering tertinggal, terbukti dari tiga blok berlabel `Kos agustus - september`. | Membuat siklus bulan baru dari template sekali klik, dengan pemisahan jelas antara baris tetap dan baris insidental. |
| Menjumlah jam kerja tiap periode dengan tangan, lalu mengalikannya ke gaji kotor. | Mencatat jam harian di aplikasi, menutup periode lewat penanda buku baru, dan menghitung gaji kotor otomatis dari total jam dikali tarif. |
| Menghitung pajak 2,5% dan potongan lain dengan tangan. | Menyimpan aturan potongan sebagai persentase atau nominal tetap, lalu menghitung gaji bersih otomatis. |
| Merekap belanja mingguan dan bulanan di spreadsheet terpisah, lalu mengetik ulang hasilnya sebagai satu baris. | Menghitung roll-up belanja otomatis dan menyuntikkannya sebagai satu baris anggaran. |
| Menjumlah transaksi kartu kredit per siklus, lalu mengetik ulang totalnya. | Mencatat transaksi per siklus tagihan dan menyuntikkan totalnya sebagai satu baris anggaran secara otomatis. |
| Mengetik ulang langganan yang sama tiap siklus. | Menyediakan template langganan berulang yang tinggal dikonfirmasi tiap siklus. |
| Menghitung alokasi investasi per pos dengan tangan dan mengecek total persentase secara visual. | Menghitung nominal tiap pos otomatis dari sisa, dan memvalidasi total persentase harus 100. |
| Mencatat pinjaman antar pos secara lepas, tanpa saldo pos yang terjaga. | Menyimpan pos tujuan bersaldo, dengan transaksi pinjam dan kembalikan yang memperbarui saldo. |
| Daftar pos di bagian pinjaman tidak sinkron dengan daftar pos di bagian alokasi. | Menggunakan satu daftar pos tujuan yang dipakai bersama oleh alokasi maupun pinjaman. |

## Hal yang masih perlu dikonfirmasi

Tiga hal tidak bisa disimpulkan dari spreadsheet dan perlu jawaban pemilik
sebelum atau saat implementasi.

- **Tarif per jam freelance.** Tidak tercatat di spreadsheet mana pun. Gaji
  kotor tidak habis dibagi total jam dengan angka bulat, jadi tarif tidak bisa
  disimpulkan balik dari data yang ada.
- **Tanggal cetak tagihan tiap kartu.** Batas siklus terlihat sekitar tanggal
  16, tetapi tidak konsisten.
- **Daftar pos tujuan yang berlaku.** Bagian alokasi memakai enam nama tetap,
  sedangkan bagian pinjaman memakai nama lain. Perlu dipastikan apakah keduanya
  daftar yang sama atau memang terpisah.

## Langkah berikutnya

Setelah membaca dokumen ini, lanjutkan ke
[DOMAIN_MODEL.md](../02-architecture/DOMAIN_MODEL.md) untuk melihat bagaimana
struktur di atas diterjemahkan menjadi entitas dan rumus, atau ke
[PRD](../01-product/prd-saldough-1.0.md) untuk melihat kebutuhan produknya.
