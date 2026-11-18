# Aset, tabungan, dan investasi: kekayaan dalam satu buku

**Tanggal:** 17 November 2026.
**Status:** Spek produk, keputusan pemilik 17 Nov 2026 (§2). ADR-047
(penyesuaian saldo, Fase 29) Accepted; kode berjalan. Urutan kerjanya Fase 29
B-99 › Fase 30 B-96 › Fase 31 B-97 › Fase 32 B-98 + B-100 › Fase 33 B-101
(§13), di bawah branch induk `claude/aset-kekayaan`; kekayaan bersih (B-59)
menunggu utang-piutang (B-48).
**Sumber:** dokumen "Product & Business Requirements: Financial Assets &
Wealth Management" dari pemilik (konsep tiga lapisan), divalidasi PO terhadap
aturan domain dan keputusan yang sudah ada, lalu dirapikan bersama pemilik.
**Berkaitan:** [FREEMIUM_PAYWALL.md](FREEMIUM_PAYWALL.md) §6.4, §7, §9, §10
(Gratis/Plus, pemicu paywall), KT-P3 (Dompet tanpa batas);
[ADR-024](../../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md),
[ADR-025](../../02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md)
(satu mata uang), [ADR-012](../../02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md)
(saldo dompet di-cache), [ADR-038](../../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md)
(periode lampau tidak dipotong ulang),
[EXPORT_BACKUP.md](EXPORT_BACKUP.md) (`BackupRegistry`, kolom ekspor),
[FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md) (6 periode gratis), KT-W1 di
TASK_LIST.

Dokumen ini merancang perilaku, aturan, dan teks. Keputusan teknis (entitas,
penyimpanan, cara menghitung riwayat) ditulis engineer sebagai ADR domain
sebelum kode, satu ADR per fase (§13). Rupa dari ui-ux-designer.

## 1. Tujuan

Tanukonomy sudah menjawab "di mana uangku" (Dompet), "apa yang terjadi"
(CATAT, Riwayat), dan "ke mana direncanakan" (Anggaran, Rencana). Dokumen ini
menambah **"seberapa jauh kekayaanku berkembang"** tanpa mengubah batas produk:
aplikasi tetap **mencatat**, tidak membeli, menjual, atau menyarankan
investasi, dan tidak tersambung ke broker.

Tiga hal yang ditambah: **tujuan tabungan**, **investasi dengan nilai yang
dicatat manual**, dan **gambaran aset** yang menjumlahkannya tanpa menghitung
dua kali. Satu perbaikan fondasi ikut: **penyesuaian saldo** (KT-W1), supaya
riwayat kekayaan bisa dipercaya.

## 2. Keputusan pemilik (17 Nov 2026)

| # | Keputusan |
|---|---|
| 1 | **Tidak ada tab kelima.** Gambaran aset tinggal di tab **Dompet**, yang diperluas. |
| 2 | **Tabungan = dompet yang terhubung ke tujuan.** Kemajuan dibaca dari saldo dompet itu (uang yang benar-benar ada). Satu tujuan boleh terhubung ke banyak dompet; satu dompet hanya untuk satu tujuan. **Tidak ada alokasi virtual**, jadi tidak ada "tersisih" atau "saldo bebas". |
| 3 | Gugur (tidak ada alokasi yang bisa melebihi saldo). |
| 4 | **Gratis**: membuat tujuan, menghubungkan dompet, melihat kemajuan; mencatat investasi, nilai perolehan, nilai pasar manual, histori valuasi, untung/rugi, komposisi, total aset. **Plus**: perkiraan tanggal tercapai, peringatan meleset (lewat Penjaga), riwayat kekayaan di luar 6 periode, kekayaan bersih dengan utang (B-59). |
| 4a | **Batas gratis: 2 tujuan tabungan aktif dan 2 investasi aktif.** Plus tanpa batas. |
| 4b | Yang dihitung "aktif": tujuan berstatus **Active**; tujuan **Completed** dan **Archived** tidak. Investasi dihitung **per instrumen** (BBCA dan TLKM = 2). |
| 4c | Sesudah Plus berakhir dan jumlah aktif melebihi 2: yang ada **tetap bisa dilihat dan diedit**, tidak ada yang diarsipkan otomatis, dan **tidak bisa membuat yang baru** sampai jumlah aktif di bawah batas (sejalan FREEMIUM §10). |
| 4d | Paywall muncul saat mencoba membuat tujuan atau investasi ketiga (pemicu P11 dan P12, §10). "Nanti saja" selalu ada; yang sudah ada tidak terhambat. |
| 5 | **Dividen dan kupon = pemasukan** (kategori Investasi). |
| 6 | **Untung terwujud bukan pemasukan.** Penjualan dicatat seperti perpindahan dari investasi ke dompet; untung atau ruginya tampil terpisah di Investasi. |
| 7 | **Biaya broker dan pajak** menjadi bagian dari nilai perolehan (saat beli) dan hasil bersih (saat jual), bukan pengeluaran terpisah. |
| 8 | Sebelum utang-piutang (B-48) ada, angka teratas bernama **Total aset**. Nama **Kekayaan bersih** baru dipakai sesudah utang tercatat. |
| 9 | **KT-W1 = B**: mengubah saldo dompet mencatat selisihnya sebagai **Penyesuaian saldo** bertanggal hari ini (§6). Saldo periode lampau tidak bergeser. |
| 10 | Nilai investasi yang lebih dari **30 hari** belum diperbarui ditandai ("Diperbarui 32 hari lalu"), tidak ditampilkan seolah harga terkini. |
| 11 | **Dompet tidak punya jenis ("ikon murni").** Bank/Tunai/E-wallet/Tabungan/Kartu hanya ikon tampilan, tanpa kemampuan. Lencana jenis dari ikon dihapus. Peran *dompet tabungan* hanya berasal dari tautan ke tujuan; dompet berikon celengan tanpa tujuan adalah dompet harian. |
| 12 | **Harga investasi tanpa API berbayar lewat Google Sheet milik pengguna** (B-101, §5.4): aplikasi membuatkan Sheet privat berisi kode dan `GOOGLEFINANCE`, pengguna menyetujui nilai yang diambil. Bukan scraping, bukan API pihak ketiga. |
| 13 | Penyesuaian saldo **bisa dihapus**, nominalnya **tidak bisa disunting**. |
| 14 | **Setiap tujuan punya tepat satu dompet sendiri yang dibuat otomatis** (17 Nov 2026), dengan kolom opsional "Sudah terkumpul" sebagai saldo awalnya; tidak ada menautkan dompet yang sudah ada. Dompet itu tampil di bagian Tujuan, bukan di grid dompet, dan tetap bisa dipilih di CATAT **hanya untuk transfer** (pemasukan dan pengeluaran ke dompet tujuan ditolak). Menghapus tujuan menghapus dompet dan semua catatannya. Menggantikan "satu tujuan banyak dompet" di keputusan 2 (ADR-048 §8). |
| 15 | **Hero tab Dompet dan Beranda menjadi Total aset berlapis** (17 Nov 2026): Dana operasional, Tabungan, Investasi, dengan rincian per dompet, tujuan, dan instrumen tetap ada; dikerjakan di Fase 30 (ADR-050). Lapis uang sehari-hari bernama **Dompet** / **Wallets** (keputusan pemilik, bukan "Dana operasional"); tab Dompet berisi hero Total aset, kartu Sebaran aset per lapis, dan segmen Dompet | Tabungan. |

Perbandingan dengan dokumen sumber, supaya tidak dibuka ulang: mata uang per
aset dihapus (ADR-025: satu mata uang per aplikasi); klasifikasi aset tidak
bisa dipindah-pindah pengguna (emas selalu Investasi, deposito dicatat sebagai
dompet); navigasi sumber ("Dompet / CATAT / Anggaran") sudah basi dan
diganti keputusan 1; "Dana Operasional" menjadi **dompet harian**.

## 3. Istilah (daftarkan di PROJECT_GLOSSARY dan writing.md saat dikerjakan)

| Istilah | Arti |
|---|---|
| **Tujuan tabungan** | Rencana mengumpulkan sejumlah uang, mis. "Dana darurat Rp20 jt". Rencana, bukan pemesanan uang (aturan 5): tidak mengubah saldo dompet mana pun. |
| **Dompet tabungan** | Dompet yang terhubung ke sebuah tujuan. Sisanya **dompet harian**. |
| **Instrumen** | Satu kepemilikan investasi: saham, reksa dana, obligasi, emas, lainnya. |
| **Nilai perolehan** | Uang yang dikeluarkan untuk memperolehnya, termasuk biaya dan pajak. |
| **Nilai pasar** | Nilai terakhir yang dicatat pengguna, dengan tanggalnya. |
| **Untung/rugi belum terwujud** | Nilai pasar dikurangi nilai perolehan, untuk yang belum dijual. |
| **Untung/rugi terwujud** | Hasil bersih penjualan dikurangi bagian nilai perolehan yang dijual. |
| **Total aset** | Dompet harian + dompet tabungan + nilai pasar investasi. |
| **Penyesuaian saldo** | Selisih saat pengguna mengoreksi saldo dompet. Bukan pemasukan, bukan pengeluaran. |

Kata "saldo" hanya untuk isi dompet; nilai investasi tidak disebut saldo.
Rumus untung/rugi memakai satu istilah per konsep supaya "untung" tidak
bercampur dengan pemasukan.

## 4. Tujuan tabungan (B-96, menggantikan B-47)

### 4.1 Alur

1. Di tab Dompet › bagian Tujuan: **Buat tujuan**. Isi: nama, target nominal,
   ikon, target tanggal (opsional), deskripsi (opsional).
2. **Hubungkan dompet** (satu atau lebih; dompet yang sudah terhubung ke tujuan
   lain tidak muncul). Pengguna bisa membuat dompet baru dari sini.
3. Mengumpulkan uang memakai alur yang **sudah ada**: transfer ke dompet
   tabungan lewat CATAT. Tidak ada jenis catatan baru untuk menabung.
4. Kemajuan: **terkumpul = jumlah saldo dompet tertaut**, target, persen,
   kekurangan, dan riwayat (transfer masuk dan keluar dompet tertaut).
5. **Mengambil dana** = transfer keluar atau pengeluaran dari dompet tabungan,
   seperti biasa. Kemajuan turun mengikuti saldo. Tidak ada pemasukan baru dan
   net worth tidak berubah.
6. **Tercapai:** saldo terhubung ≥ target mengubah status menjadi
   **Completed**, dengan umpan balik singkat (selaras GAMIFICATION). Tujuan
   tetap menerima dana; pengguna boleh menaikkan target, menyelesaikan, atau
   mengarsipkan.

Rumus: `kemajuan = jumlah saldo dompet tertaut / target × 100%`, ditulis dengan
`int` sen, pembulatan hanya saat ditampilkan.

### 4.2 Aturan

- **T-1** Menghubungkan, memutus, atau menghapus tujuan **tidak mengubah saldo**.
  Memutus dompet menjadikannya dompet harian lagi.
- **T-2** Saldo awal dompet yang dihubungkan **seluruhnya dihitung** ke
  kemajuan (tidak ada "mulai dari nol saat dihubungkan").
- **T-3** Satu dompet maksimal satu tujuan. Satu tujuan banyak dompet.
- **T-4** Status: Active, Completed, Archived. Batas gratis 2 hanya menghitung
  Active (keputusan 4a–4b). Mengaktifkan kembali tujuan yang diarsipkan
  mengikuti batas yang sama.
- **T-5** Dompet tabungan tetap ikut Riwayat, anggaran (bila dipakai belanja),
  dan Analisis seperti dompet lain. Tidak ada saldo terpisah.
- **T-6** Target tanggal hanya penanda. **Perkiraan tanggal tercapai** (Plus,
  dikerjakan T-30.7, ADR-048 §3.6) punya dua baris berlabel perkiraan:
  **dengan laju sekarang** (rata-rata uang masuk bersih ke dompet milik tujuan
  dalam paling banyak 3 periode keuangan lengkap sejak tujuan dibuat;
  penyesuaian saldo tidak dihitung) dan **bila uang nganggur ikut ditabung**
  (laju itu ditambah rata-rata uang nganggur, pengandaian per tujuan). Tanpa
  periode lengkap atau laju ≤ 0: "Belum bisa diperkirakan". Bila perkiraan
  melewati target tanggal, rincian menampilkan "Perkiraan melewati target
  tanggal"; **peringatan meleset** aktif lewat Penjaga menunggu B-44. Gratis
  melihat baris terkunci yang membuka paywall `goal_estimate`. Tidak ada janji
  pasti.
- **T-7** Plus berakhir: tujuan tetap tampil dan kemajuannya terus mengikuti
  saldo; hanya perkiraan dan peringatan berhenti (FREEMIUM §10).

### 4.3 Kasus tepi

| Kasus | Perilaku |
|---|---|
| Saldo dompet tertaut negatif | Kemajuan dihitung apa adanya (bisa 0 atau negatif ditampilkan 0%); tidak disembunyikan. |
| Dompet tertaut dinonaktifkan | Tetap terhitung; kartu menyebut dompet itu nonaktif. |
| Target diubah menjadi lebih kecil dari terkumpul | Langsung Completed. |
| Dua tujuan menginginkan dompet yang sama | Tidak bisa (T-3); pesan menyarankan membuat dompet baru. |
| Mata uang | Satu per aplikasi (ADR-025); tidak ada kolom mata uang. |

## 5. Investasi (B-97)

### 5.1 Bentuk

Investasi adalah **instrumen** yang nilainya berubah, bukan dompet. Instrumen
punya: nama, jenis (saham, reksa dana, obligasi, emas, lainnya), jumlah
(satuan sesuai jenis, KT-A2), nilai perolehan, nilai pasar dengan tanggal
valuasi, dan histori valuasi. Satu instrumen = satu baris, tanpa hitungan per
lot.

### 5.2 Cara mencatat (dua pintu)

1. **Tambah kepemilikan yang sudah ada:** pengguna yang sudah punya saham atau
   emas memasukkan jumlah dan nilai perolehan **tanpa menyentuh dompet**.
   Tanpa ini fitur tidak berguna bagi pengguna yang sudah berinvestasi.
2. **Beli dan jual dari dompet:** uang keluar dari dompet menjadi nilai
   perolehan (beli), atau hasil bersih masuk ke dompet (jual). Dicatat lewat
   **CATAT** (aturan 8), sebagai jenis catatan baru yang berperilaku seperti
   transfer antara dompet dan instrumen: **bukan pemasukan dan bukan
   pengeluaran**, tidak masuk Arus, Analisis, atau anggaran (aturan 7).
   Letaknya di alur CATAT dirancang designer; pengecualian aturan 8 ditulis
   di ADR.

Catatan lain: **dividen dan kupon** dicatat sebagai pemasukan biasa dengan
kategori Investasi dan boleh ditautkan ke instrumennya; **jatuh tempo**
instrumen dicatat sebagai jual.

### 5.3 Hitungan

| Nilai | Rumus |
|---|---|
| Nilai perolehan | Jumlah yang dikeluarkan termasuk biaya dan pajak (keputusan 7) |
| Nilai pasar | Nilai terakhir yang dicatat pengguna |
| Untung/rugi belum terwujud | Nilai pasar − nilai perolehan (bagian yang masih dipegang) |
| Persentase | Untung/rugi belum terwujud ÷ nilai perolehan |
| Untung/rugi terwujud | Hasil bersih jual − bagian nilai perolehan yang dijual |
| Bagian nilai perolehan yang dijual | Biaya rata-rata × jumlah yang dijual (KT-A1) |

Untung/rugi terwujud dan belum terwujud **tidak pernah** dihitung sebagai
pemasukan atau pengeluaran dan tidak masuk Arus (keputusan 6).

### 5.4 Valuasi manual dan kesegaran

- Pengguna memperbarui nilai pasar dari layar instrumen; setiap pembaruan
  masuk histori valuasi (tanggal dan nilai).
- **Kesegaran (keputusan 10):** nilai ≥ 30 hari ditandai "Diperbarui 32 hari
  lalu" dan diberi warna perhatian netral. Total aset tetap memakai nilai
  terakhir, dengan satu baris catatan bila ada instrumen yang kedaluwarsa.
- Pengingat memperbarui nilai **tidak** dikerjakan di fase ini (menambah
  tekanan; dibahas bila ada data pemakaian).
- Harga otomatis dari vendor **tidak ada**. Redistribusi data harga BEI
  memerlukan lisensi data IDX, dan sumber gratis pihak ketiga (Yahoo Finance,
  Invezgo, Stockbit lewat perantara, scraper `logammulia.com`, Bareksa) syarat
  komersialnya tidak jelas atau melarang.
- **Perbarui massal** (B-97): satu layar berisi semua instrumen untuk mengisi
  nilai baru sekaligus.
- **Ambil dari Google Sheet** (B-101, keputusan 12): pengguna yang masuk dengan
  Google memberi izin `drive.file` (hanya berkas buatan aplikasi). Aplikasi
  membuat Sheet privat di Drive pengguna berisi kode instrumen dan
  `GOOGLEFINANCE(kode;"price")`, tanpa jumlah atau nominal kepemilikan. Tombol
  "Ambil harga" membaca nilainya lewat Sheets API dan membuka Perbarui massal
  sebagai pratinjau; nilai baru disimpan hanya sesudah pengguna menyetujui.
  Tanpa server Tanukonomy, dan aplikasi tidak mendistribusikan ulang harga.
  Reksa dana dan emas yang tidak tercakup bisa diisi pengguna sendiri di
  Sheet. Data GOOGLEFINANCE bisa tertunda dan hanya untuk informasi, jadi
  penanda kesegaran tetap memakai tanggal valuasi. Spike dulu (T-33.0).

### 5.5 Batas gratis

2 investasi aktif per instrumen; ke-3 memicu P12. Instrumen yang sudah dijual
seluruhnya berstatus **Selesai** dan tidak dihitung. Plus tanpa batas.

### 5.6 Kasus tepi

| Kasus | Perilaku |
|---|---|
| Nilai pasar belum pernah diperbarui | Memakai nilai perolehan, ditandai "Belum pernah diperbarui". |
| Jual lebih dari yang dimiliki | Ditolak dengan pesan jelas; tidak ada posisi negatif. |
| Jual sebagian | Biaya rata-rata tetap; nilai perolehan sisa dikurangi proporsional. |
| Dompet pembelian dinonaktifkan | Boleh membeli dari dompet aktif lain saja. |
| Saham dengan satuan lot | Satuan mengikuti jenis (KT-A2); 1 lot saham = 100 lembar dijelaskan di formulir. |
| Mata uang | Satu per aplikasi; aset berdenominasi asing dicatat nilainya dalam mata uang aplikasi oleh pengguna. |

## 6. Penyesuaian saldo (B-99, KT-W1 = B)

Sejak `0.11.0+17`, mengubah saldo dompet menggeser `initialBalance` diam-diam
dan membuat saldo periode lampau ikut berubah. Itu merusak riwayat kekayaan,
kemajuan tabungan, dan janji ADR-038. Perilaku baru:

1. Di Ubah dompet, kolom saldo tetap berarti **saldo sekarang**. Bila diubah,
   aplikasi mencatat **satu catatan Penyesuaian saldo** sebesar selisihnya,
   **bertanggal hari ini**. `initialBalance` tidak digeser.
2. **Bukan pemasukan, bukan pengeluaran:** bernilai 0 di Arus, tidak masuk
   Analisis atau anggaran, dan tampil sebagai jenis tersendiri di Riwayat dan
   ekspor ("Penyesuaian").
3. Saldo hari-hari sebelumnya **tidak berubah**; selisih muncul mulai tanggal
   penyesuaian, dan jejaknya terlihat di Riwayat.
4. **Saldo awal** hanya diatur saat membuat dompet.
5. Ini pengecualian ketiga aturan 8 (setelah catat otomatis dan kemunculan
   rutin tetap): dicatat dari layar Ubah dompet, bukan dari CATAT. Teksnya
   ditulis di ADR.
6. Kasus yang ditemukan di KT-W1 ikut diperbaiki: saldo negatif dan saldo
   berpecahan sen tidak boleh tampil sebagai kolom kosong.
7. Penyesuaian harus bisa disaring dari Riwayat supaya tidak ramai.
7a. **Semua pembaca Arus mengecualikan Penyesuaian saldo:** kartu Arus Beranda,
   Analisis, Rencana, Daftar Riwayat, dan **Buku Periode dan Kartu Periode**
   (Pemasukan, Pengeluaran, dan Selisih periode tidak memuatnya; uji
   kecocokan total buku tetap berlaku). Karena tanggalnya hari ini, penyesuaian
   **tidak mengubah buku yang sudah ditutup**, berbeda dari perilaku lama yang
   menggeser saldo periode lampau.
7b. Penyesuaian **bisa dihapus** dari detailnya (saldo kembali seperti sebelum
   penyesuaian), tetapi **nominalnya tidak bisa disunting** (keputusan 13).
8. Perilaku yang sudah terkirim di `0.11.0+17` tidak dimigrasi; data lama
   tetap apa adanya, hanya perilaku ke depan yang berubah.

Penyesuaian ikut `BackupRegistry`, kolom Jenis di ekspor, dan hitung ulang
saldo (ADR-012).

## 7. Gambaran aset di tab Dompet (B-98)

- Kartu atas **Total aset** = dompet harian + dompet tabungan + nilai pasar
  investasi, dengan sebaran tiga bagian (memperluas "Sebaran saldo" yang sudah
  ada). Tiga bagian **tidak saling menumpuk**: dompet tabungan adalah dompet,
  bukan tambahan di atas dompet (aturan "satu gambaran, tanpa hitung ganda").
- Bagian bawahnya: daftar dompet (seperti sekarang, dompet tabungan diberi
  penanda tujuannya), **Tujuan**, dan **Investasi**; masing-masing dapat dibuka.
- Perubahan nilai antar periode (Total aset sekarang vs awal periode) dipecah
  menjadi: dari transaksi, dari perubahan nilai investasi, dan dari penyesuaian
  saldo. Perubahan nilai investasi **tidak** ditulis sebagai pemasukan.
- Bila ada instrumen kedaluwarsa (keputusan 10), satu baris catatan di bawah
  Total aset.
- Nominal ikut "Sembunyikan nominal".

## 8. Riwayat kekayaan (B-100)

- Grafik Total aset per periode keuangan. **Gratis: 6 periode terakhir**
  (selaras Analisis); **Plus: seluruh riwayat**.
- Nilai pada tanggal tertentu dihitung dari saldo dompet pada tanggal itu
  (transaksi dan penyesuaian) ditambah nilai investasi pada tanggal itu
  (valuasi terakhir ≤ tanggal itu, jumlah kepemilikan pada tanggal itu). Cara
  teknisnya di ADR.
- **Prasyarat:** B-99. Tanpa penyesuaian saldo, grafik berubah mundur saat
  pengguna mengoreksi saldo.
- Titik yang nilai investasinya kedaluwarsa diberi penanda, bukan disembunyikan.
- Tidak ada proyeksi atau janji imbal hasil.

## 9. Kekayaan bersih (B-59, nanti)

Total aset dikurangi utang dan kewajiban. Hanya sesudah B-48 (utang-piutang)
ada; memakai nama **Kekayaan bersih** dan tetap Plus (FREEMIUM §7). Sebelum itu
yang ditampilkan adalah Total aset.

## 10. Gratis dan Plus, pemicu paywall

| Fitur | Gratis | Plus |
|---|---|---|
| Tujuan tabungan: buat, hubungkan dompet, kemajuan, riwayat | 2 Active | Tanpa batas |
| Perkiraan tanggal tercapai, peringatan meleset | | Ya |
| Investasi: instrumen, nilai perolehan, valuasi manual, histori, untung/rugi, komposisi | 2 Active | Tanpa batas |
| Total aset dan gambaran di tab Dompet | Ya | Ya |
| Riwayat kekayaan | 6 periode | Seluruhnya |
| Kekayaan bersih dengan utang | | Ya |
| Penyesuaian saldo, ekspor, cadangan | Ya (tanpa batas) | Ya |

| # | Pemicu | Contoh kalimat | Pilar |
|---|---|---|---|
| P11 | Mencoba membuat tujuan tabungan ke-3 | "Kamu sudah punya 2 tujuan aktif. Dengan Plus, tujuan berapa pun, plus perkiraan kapan tercapai." Tombol Nanti saja. | ④ |
| P12 | Mencoba mencatat investasi ke-3 | "Kamu sudah mencatat 2 investasi aktif. Dengan Plus, instrumen berapa pun." Tombol Nanti saja. | ④ |

Ke-3 yang ditolak **tidak hilang**: formulir yang sudah diisi disimpan sebagai
draf sampai pengguna menyelesaikan atau menghapusnya. Batas 2 adalah
hipotesis yang disetel lewat Remote Config (FREEMIUM §15). Dompet tetap tanpa
batas (KT-P3).

## 11. Teks (draf, mengikuti writing.md)

Ruang nama `assets.*`. Contoh: `assets.total` Total aset · `assets.goal.title`
Tujuan · `assets.goal.create` Buat tujuan · `assets.goal.link` Hubungkan dompet
· `assets.goal.progress` {saved} dari {target} ({percent}) ·
`assets.invest.title` Investasi · `assets.invest.staleValue` Diperbarui {n}
hari lalu · `assets.invest.neverUpdated` Belum pernah diperbarui ·
`assets.adjust.title` Penyesuaian saldo · `assets.adjust.note` Selisih
Rp{amount} dicatat sebagai penyesuaian saldo hari ini. Kata "mencatat, bukan
melakukan": tombol memakai "Catat pembelian" dan "Catat penjualan", tidak
"Beli" atau "Jual".

## 12. Analitik

Mengikuti ADR-023: tanpa nominal, nama instrumen, atau nama tujuan.
`goal_created` (`collected`: `initial`/`empty`), `goal_completed`, `instrument_added`
(`type`, `via`: `existing`/`buy`), `valuation_updated`,
`wealth_overview_viewed`, `wealth_history_viewed` (`periods_bucket`),
`balance_adjusted` (tanpa nominal), `paywall_shown` untuk P11 dan P12.

## 12a. Hubungan dengan Buku Periode (Fase 27) dan Buku Stempel (Fase 28)

Dua fitur gamifikasi dan rapor di branch `claude/buku-periode-fase-27`
([BUKU_PERIODE.md](BUKU_PERIODE.md), [GAMIFICATION.md](GAMIFICATION.md), ADR-045,
ADR-046) memakai titik sambung yang disiapkan untuk domain ini. Penyelarasannya:

- **Penyedia halaman Buku Periode (ADR-045):** buku adalah Plus, tetapi halaman
  yang bisa ditambah dari domain ini memuat data gratis. Calon halaman:
  **Tujuan tabungan** (B-96) dan **Total aset** (B-98). Dipilih saat butir itu
  dikerjakan; nominal di Kartu Periode tetap mengikuti BP-16 (hanya fakta yang
  dipilih pengguna, nominal opsional dan bawaan mati), jadi Total aset tidak
  masuk kartu bagikan kecuali pemilik memutuskan.
- **Syarat tonggak baru (GAMIFICATION §catalog, "jenis syarat baru"):**
  "**tujuan tercapai**" (status Completed, B-96) dan "**investasi pertama
  dicatat**" (B-97) adalah satu fakta baru masing-masing. Tonggak tidak menilai
  besar tabungan atau untung investasi, tanpa nominal, tanpa streak, sejalan
  non-tujuan GAMIFICATION. "Sisih tabungan teratur" atau "untung" **tidak**
  menjadi tonggak.
- **Arus periode:** Penyesuaian saldo dikecualikan (§6 butir 7a). Buku yang
  sudah ditutup tidak berubah.
- **Nomor:** Fase 27 dan 28 sudah dipakai; butir kekayaan memakai B-96–B-100 dan
  belum diberi nomor fase. PRD §7.15 (bukan §7.14, yang dipakai Buku Periode).

## 13. Urutan kerja (belum dijadwalkan; tiap butir ADR domain dulu)

| Urut | Butir | Isi | Catatan |
|---|---|---|---|
| 1 | **B-99** | Penyesuaian saldo (KT-W1 = B) | Memperbaiki perilaku yang sudah terkirim; prasyarat riwayat kekayaan; ADR domain menyentuh aturan 8 |
| 2 | **B-96** | Tujuan tabungan (menggantikan B-47) | Memakai dompet dan transfer yang ada; batas gratis 2; perkiraan dan peringatan Plus |
| 3 | **B-97** | Investasi: instrumen, beli/jual lewat CATAT, valuasi manual | Jenis catatan baru, `BackupRegistry`, ekspor; batas gratis 2 |
| 4 | **B-98** | Gambaran aset (Total aset) di tab Dompet | Butuh B-96 dan B-97 supaya ada isi |
| 5 | **B-100** | Riwayat kekayaan | Butuh B-99; 6 periode gratis, seluruhnya Plus |
| 6 | **B-101** | Ambil nilai dari Google Sheet pengguna | Fase 33, butuh B-97; spike dulu; Gratis/Plus di KT-A4 |
| 7 | **B-59** | Kekayaan bersih | Butuh B-48 (utang-piutang) |

Setiap fase menambah entitas yang wajib didaftarkan di `BackupRegistry`, kolom
di ekspor, uji bolak-balik cadangan, dan peristiwa analitik §12.

## 14. Di luar cakupan

- Trading, rekomendasi jual atau beli, nasihat investasi, dan proyeksi imbal
  hasil.
- Koneksi ke broker atau bank, dan harga pasar dari vendor. Sumber tak resmi
  seperti Yahoo Finance, paket `yahoo_finance`, dan scraping **tidak dipakai**.
  Satu-satunya jalan otomatis adalah Sheet milik pengguna (B-101), dipicu dan
  disetujui pengguna.
- Alokasi virtual lintas dompet dan konsep "saldo bebas" (ditinggalkan di
  keputusan 2).
- Pajak investasi dan risiko tingkat lanjut.
- Portofolio bersama (menunggu B-7 dan B-60).
- Mata uang per aset (ADR-025).

## 15. Keputusan terbuka (KT-A1–KT-A4), untuk ADR dan pemilik

| # | Pertanyaan | Rekomendasi PO |
|---|---|---|
| KT-A1 (dijawab 17 Nov 2026) | Cara menghitung biaya yang dijual | **Rata-rata tertimbang** |
| KT-A2 (dijawab 17 Nov 2026) | Satuan jumlah per jenis | Saham **lot** (1 lot = 100 lembar), reksa dana **unit**, emas **gram**, obligasi **nominal**, lainnya **unit** |
| KT-A4 (terbuka) | Ambil nilai dari Google Sheet (B-101): Gratis atau Plus? | Ditanyakan sebelum ADR-051 |
| KT-A3 (sudah dijawab, tercatat) | KT-W1 | **B** (keputusan 9) |

## 16. Risiko

| Risiko | Mitigasi |
|---|---|
| Hitung ganda tabungan dan dompet | Tabungan **adalah** dompet (keputusan 2); Total aset tiga bagian terpisah |
| Pengguna menganggap kenaikan nilai investasi sebagai uang tunai | Nilai investasi tidak disebut saldo, tidak masuk Arus, dan dipisah dari dompet |
| Nilai kedaluwarsa tampil seperti harga terkini | Penanda 30 hari (keputusan 10) |
| Batas gratis 2 terasa sempit untuk portofolio saham | Disengaja sebagai pendorong Plus; angka disetel lewat Remote Config; dipantau lewat P12 |
| Banyak baris "Penyesuaian" di Riwayat | Bisa disaring (§6 butir 7) |
| Istilah investasi menakutkan pemula | Teks sederhana, satuan jelas, tanpa istilah akuntansi |
