# Product Requirements Document: Saldough 1.0

## 1. Ringkasan

Saldough adalah aplikasi Flutter untuk Android dan iOS yang menggantikan sistem
pencatatan keuangan berbasis empat Google Spreadsheet yang saat ini dikelola
manual oleh pemiliknya.

| | |
|---|---|
| **Nama produk** | Saldough |
| **Platform** | Android dan iOS |
| **Versi dokumen** | 1.0 |
| **Status** | Draf, menunggu implementasi |
| **Pemilik** | muhammadrisky1401@gmail.com |
| **Terakhir diperbarui** | 9 September 2026 |

> **Catatan status implementasi (9 September 2026):** Belum ada kode yang
> ditulis. Seluruh acceptance criteria masih kosong (`- [ ]`). Sebuah kriteria
> baru boleh dicentang kalau benar-benar sudah selesai dan terverifikasi.
> Implementasi sebagian tetap dibiarkan kosong disertai catatan singkat yang
> menjelaskan kekurangannya.

Seluruh kebutuhan dalam dokumen ini diturunkan dari
[analisis proses manual](../00-foundation/MANUAL_PROCESS_ANALYSIS.md).
Rumus dan entitas yang dirujuk didefinisikan di
[model domain](../02-architecture/DOMAIN_MODEL.md).

## 2. Pernyataan masalah

Pemilik mengelola keuangan pribadinya lewat empat spreadsheet yang saling
mereferensi, tetapi tidak satu pun referensi itu otomatis. Setiap bulan ia harus
mengulang rangkaian pekerjaan tangan yang sama.

Tiga spreadsheet satelit masing-masing menghasilkan satu angka: total jam kerja
freelance, total belanja bulanan, dan total tagihan kartu kredit per siklus.
Ketiga angka itu harus dijumlah manual lalu diketik ulang menjadi satu baris di
spreadsheet utama. Di spreadsheet utama sendiri, blok bulan baru dibuat dengan
menyalin blok bulan sebelumnya, lalu menyunting baris satu per satu.

Penyalinan manual ini terbukti meleset. Tiga blok bulan berturut-turut sama-sama
berlabel `Kos agustus - september` meski mewakili tiga bulan berbeda, karena
label lama tidak ikut diperbarui saat blok disalin.

Akibatnya pencatatan memakan waktu, rawan salah ketik, dan sulit dipakai untuk
melihat tren. Semua data hanya bisa diakses dari laptop, padahal pengeluaran
terjadi di jalan.

## 3. Tujuan dan ukuran keberhasilan

### Tujuan produk

Saldough harus memindahkan seluruh sistem spreadsheet ke aplikasi tanpa
kehilangan satu pun perilaku yang dipakai pemilik hari ini, sambil menghapus
setiap titik salin manual.

- Menghapus seluruh penyalinan angka antar dokumen.
- Menghitung otomatis semua nilai yang saat ini dihitung tangan.
- Menjaga hasil hitung sama persis dengan spreadsheet, sampai ke rupiah
  terakhir.
- Menyediakan pencatatan yang bisa dilakukan dari ponsel saat transaksi terjadi.

### Ukuran keberhasilan MVP

| Ukuran | Target |
|---|---|
| Titik salin manual antar dokumen | 0, turun dari 3 |
| Selisih hasil hitung terhadap spreadsheet untuk data historis | Rp0 |
| Waktu menutup satu bulan | Di bawah 5 menit |
| Waktu mencatat satu transaksi kartu | Di bawah 15 detik |
| Spreadsheet yang masih perlu dibuka rutin | 0 |

## 4. Pengguna sasaran

### Persona utama

Pemilik tunggal, seorang pengembang perangkat lunak dengan penghasilan dari dua
sumber: gaji tetap bulanan dan pekerjaan freelance dibayar per jam. Ia sudah
disiplin mencatat, sudah punya sistem yang bekerja, dan tidak membutuhkan
edukasi soal penganggaran. Yang ia butuhkan adalah penghapusan kerja berulang.

Konsekuensi penting: aplikasi tidak boleh memaksakan model penganggaran baru.
Aplikasi harus mengikuti model yang sudah ia pakai.

### Persona sekunder

Pasangan pemilik, yang penghasilannya sudah dicatat sebagai salah satu sumber
pemasukan. Pada MVP ia belum menjadi pengguna aplikasi. Kebutuhan rumah tangga
dua pengguna ditunda sampai tahap sinkronisasi.

### Kasus penggunaan utama

- Menutup bulan: meninjau baris tetap, menyesuaikan yang berubah, lalu membagi
  sisa ke pos investasi.
- Mencatat jam kerja freelance harian dari ponsel.
- Mencatat transaksi kartu kredit segera setelah terjadi.
- Menyusun ulang daftar belanja saat harga berubah.
- Melihat sisa bulan berjalan kapan saja untuk memutuskan pengeluaran.

## 5. Proposisi nilai

Saldough adalah spreadsheet pemilik yang sudah tahu cara menghitung dirinya
sendiri. Struktur, istilah, dan alur kerjanya sengaja dibuat sama, sehingga
tidak ada yang perlu dipelajari ulang. Yang hilang hanya pekerjaan tangannya.

## 6. Cakupan MVP

### Termasuk dalam MVP

- Siklus bulanan lengkap: pemasukan, anggaran, sisa, dan alokasi investasi.
- Template dan rollover ke bulan berikutnya.
- Sumber pemasukan tetap, freelance per jam, dan sekali jalan.
- Timesheet dengan periode tagihan berbasis penanda buku baru.
- Aturan potongan berupa persentase dan nominal tetap.
- Rencana belanja mingguan dan bulanan dengan roll-up otomatis.
- Kartu kredit dengan siklus tagihan, transaksi, dan langganan berulang.
- Pos tujuan bersaldo, alokasi persentase, dan pinjaman antar pos.
- Impor data historis November 2025 sampai September 2026 sebagai seed.
- Penyimpanan lokal di perangkat.
- Antarmuka bahasa Indonesia dan Inggris.

### Di luar MVP

- Sinkronisasi ke Firebase atau Google Drive.
- Rumah tangga dengan dua pengguna yang saling melihat.
- Impor otomatis dari surel, SMS, atau rekening bank.
- Laporan tahunan dan grafik tren.
- Ekspor kembali ke format spreadsheet.
- Pengingat dan notifikasi.
- Dukungan lebih dari satu mata uang.

## 7. Kebutuhan fungsional

Setiap kebutuhan punya identitas yang dirujuk oleh
[daftar tugas](../04-planning/TASK_LIST.md) dan ADR terkait.

### 7.1 Siklus bulanan

Siklus bulanan adalah layar utama aplikasi dan padanan langsung satu blok tabel
di spreadsheet.

**FR-CYCLE-001 — Menampilkan siklus bulan berjalan**

- [ ] Menampilkan daftar baris pemasukan beserta totalnya.
- [ ] Menampilkan daftar baris anggaran beserta totalnya.
- [ ] Menampilkan sisa sebagai selisih total pemasukan dan total anggaran.
- [ ] Menampilkan sisa negatif dengan warna `overBudget` dan label lewat
      anggaran, bukan sebagai kesalahan.
- [ ] Membedakan baris tetap dan baris insidental secara visual.
- [ ] Menandai baris roll-up dengan warna `rollUp` beserta asal angkanya.

**FR-CYCLE-002 — Menyunting baris**

- [ ] Menambah, menyunting, dan menghapus baris pemasukan.
- [ ] Menambah, menyunting, dan menghapus baris anggaran manual.
- [ ] Menandai sebuah baris sebagai tetap atau insidental.
- [ ] Menolak penyuntingan nominal pada baris roll-up disertai penjelasan asal
      angkanya.

**FR-CYCLE-003 — Berpindah antar bulan**

- [ ] Membuka siklus bulan mana pun yang sudah ada.
- [ ] Menandai siklus yang sudah ditutup agar tidak tersunting tanpa sengaja.

**FR-CYCLE-004 — Ketepatan hitung**

- [ ] Menyimpan seluruh nominal sebagai bilangan bulat satuan sen.
- [ ] Membulatkan ke rupiah hanya saat menampilkan, dengan pembulatan setengah
      ke atas.
- [ ] Menghasilkan angka yang sama persis dengan spreadsheet untuk seluruh data
      historis.

### 7.2 Template dan rollover

Kebutuhan ini menjawab nyeri penyalinan blok bulan yang menyebabkan label lama
tertinggal.

**FR-TPL-001 — Membuat siklus baru dari template**

- [ ] Membuat siklus bulan berikutnya dalam satu tindakan.
- [ ] Menyalin hanya baris bertanda tetap.
- [ ] Tidak membawa baris insidental dari bulan sebelumnya.

**FR-TPL-002 — Meninjau baris tetap**

- [ ] Menandai setiap baris hasil rollover sebagai perlu ditinjau.
- [ ] Menampilkan penanda perlu ditinjau dengan warna `needsReview`.
- [ ] Menghapus penanda saat pemilik mengonfirmasi baris tersebut.
- [ ] Menampilkan berapa baris yang belum ditinjau di ringkasan siklus.

**FR-TPL-003 — Menghitung ulang baris roll-up**

- [ ] Tidak menyalin nominal baris roll-up dari bulan sebelumnya.
- [ ] Menghitung ulang nominalnya dari sumber di siklus baru.

**FR-TPL-004 — Mengelola template**

- [ ] Menyunting daftar baris tetap yang dipakai rollover.
- [ ] Menyimpan persentase alokasi investasi bawaan.

### 7.3 Sumber pemasukan

**FR-INC-001 — Mengelola sumber pemasukan**

- [ ] Membuat sumber bertipe gaji tetap, freelance per jam, atau sekali jalan.
- [ ] Menyimpan nominal tetap untuk sumber bertipe gaji tetap.
- [ ] Menyimpan tarif per jam untuk sumber bertipe freelance.

**FR-INC-002 — Menghubungkan sumber ke baris pemasukan**

- [ ] Menautkan baris pemasukan ke sebuah sumber.
- [ ] Mengisi nominal baris otomatis dari hasil hitung sumbernya.

**FR-INC-003 — Aturan potongan**

- [ ] Menyimpan potongan berupa persentase atau nominal tetap.
- [ ] Menghitung potongan persentase dari gaji kotor, bukan dari nilai berjalan.
- [ ] Menampilkan rincian gaji kotor, tiap potongan, dan gaji bersih.
- [ ] Menghasilkan gaji bersih yang sama persis dengan spreadsheet untuk tujuh
      bulan yang punya data.

### 7.4 Timesheet freelance

**FR-TIME-001 — Mencatat jam kerja**

- [ ] Mencatat tanggal dan jumlah jam dalam satu layar singkat.
- [ ] Menandai sebuah entri sebagai hari buku baru.
- [ ] Menyunting dan menghapus entri.

**FR-TIME-002 — Buku jam**

- [ ] Mengelompokkan entri ke dalam periode berdasarkan penanda hari buku baru.
- [ ] Tidak memotong periode berdasarkan bulan kalender.
- [ ] Menampilkan total jam tiap periode.
- [ ] Menampilkan tanggal awal dan akhir tiap periode.

**FR-TIME-003 — Menutup buku dan menghitung gaji**

- [ ] Menutup buku jam yang sedang berjalan.
- [ ] Menghitung gaji kotor dari total jam dikali tarif.
- [ ] Menerapkan aturan potongan untuk mendapat gaji bersih.
- [ ] Menyuntikkan gaji bersih ke baris pemasukan di siklus yang dipilih.

**FR-TIME-004 — Melihat riwayat**

- [ ] Menampilkan daftar buku jam terdahulu beserta total jam dan gajinya.

### 7.5 Rencana belanja

**FR-GROC-001 — Mengelola daftar**

- [ ] Mengelola daftar mingguan dan daftar bulanan secara terpisah.
- [ ] Menambah, menyunting, dan menghapus item.
- [ ] Menyimpan nama, jumlah, dan harga satuan tiap item.

**FR-GROC-002 — Harga timpaan**

- [ ] Menghitung harga item sebagai jumlah dikali harga satuan secara bawaan.
- [ ] Mengizinkan penimpaan harga dengan angka manual.
- [ ] Menandai item yang harganya ditimpa.

**FR-GROC-003 — Roll-up belanja**

- [ ] Menghitung total sebulan sebagai subtotal mingguan dikali pengali minggu
      ditambah subtotal bulanan.
- [ ] Mengizinkan pengubahan pengali minggu, dengan nilai bawaan empat.
- [ ] Menyuntikkan total sebulan sebagai satu baris anggaran secara otomatis.
- [ ] Memperbarui baris anggaran saat daftar belanja berubah.

### 7.6 Kartu kredit

**FR-CARD-001 — Mengelola kartu**

- [ ] Membuat lebih dari satu kartu.
- [ ] Menyimpan tanggal cetak tagihan tiap kartu.

**FR-CARD-002 — Mencatat transaksi**

- [ ] Mencatat tanggal, merchant, nominal, dan catatan.
- [ ] Menyimpan catatan pada field terpisah dari nama merchant.
- [ ] Memasukkan transaksi ke siklus tagihan yang sesuai secara otomatis.

**FR-CARD-003 — Siklus tagihan**

- [ ] Mengelompokkan transaksi per siklus tagihan.
- [ ] Menampilkan total tiap siklus.
- [ ] Menutup siklus dan membuka siklus berikutnya.

**FR-CARD-004 — Langganan berulang**

- [ ] Menyimpan template langganan berisi merchant, nominal, dan tanggal.
- [ ] Menyiapkan transaksi langganan saat siklus baru dibuka.
- [ ] Meminta konfirmasi sebelum transaksi langganan dihitung, karena nominalnya
      bisa berubah.
- [ ] Menonaktifkan langganan tanpa menghapus riwayatnya.

**FR-CARD-005 — Roll-up kartu**

- [ ] Menyuntikkan total siklus sebagai satu baris anggaran secara otomatis.
- [ ] Memperbarui baris anggaran saat transaksi berubah.

### 7.7 Investasi dan pos tujuan

**FR-INV-001 — Mengelola pos tujuan**

- [ ] Membuat, menyunting, dan menonaktifkan pos tujuan. Daftar pos terbuka —
      tidak dibatasi enam nama bawaan (ANAK, RUMAH, PENSIUN, SEKOLAH, KYOTO,
      SAHAM), pemilik bisa menambah pos baru kapan saja.
- [ ] Menyimpan saldo awal tiap pos.
- [ ] Memakai satu daftar pos yang sama untuk alokasi maupun pinjaman — tidak
      ada daftar pos kedua yang terpisah untuk pinjaman.

**FR-INV-002 — Alokasi persentase**

- [ ] Menyimpan persentase tiap pos untuk sebuah siklus.
- [ ] Menghitung budget investasi sebagai sisa ditambah return deposit.
- [ ] Menghitung nominal tiap pos dari budget dikali persentasenya.

**FR-INV-003 — Validasi alokasi**

- [ ] Menampilkan jumlah seluruh persentase.
- [ ] Memperingatkan kalau jumlahnya bukan 0 dan bukan 100.
- [ ] Mengizinkan jumlah 0 sebagai tanda bulan belum dialokasikan.

**FR-INV-004 — Pinjaman antar pos**

- [ ] Mencatat pinjaman dengan pos asal, pos tujuan, dan pokok.
- [ ] Mencatat pengembalian dengan nominal yang boleh berbeda dari pokok.
- [ ] Memperbarui saldo kedua pos.

**FR-INV-005 — Saldo pos**

- [ ] Menghitung saldo pos dari saldo awal, alokasi, dan pinjaman.
- [ ] Menampilkan riwayat pergerakan tiap pos.

### 7.8 Impor data historis

**FR-SEED-001 — Seed awal**

⚠ **Bukan fitur aplikasi.** Ini operasi SEKALI PAKAI yang dijalankan
pengembang di luar jalur produksi — tanpa layar, tanpa tombol, tidak ikut
ter-*build* ke rilis yang dipakai pemilik sehari-hari (lihat catatan revisi
9 September 2026 di bawah). Cakupannya juga hanya data yang BENAR-BENAR
dimiliki pemilik saat operasi ini dijalankan, bukan rentang tanggal yang
diasumsikan tetap (Nov 2025–Sep 2026 di versi PRD sebelumnya adalah
perkiraan awal, bukan jaminan; tiap jenis data di bawah boleh tercakup
sebagian atau tidak sama sekali kalau pemilik tidak punya datanya).

- [ ] Menulis langsung ke penyimpanan lokal dari data yang disediakan
      pemilik, sekali jalan, sebelum aplikasi dipakai sehari-hari.
- [ ] Memuat siklus bulanan beserta baris pemasukan dan anggarannya, untuk
      bagian yang datanya disediakan.
- [ ] Memuat riwayat jam kerja dan buku jamnya, untuk bagian yang datanya
      disediakan.
- [ ] Memuat riwayat transaksi kartu kredit per siklus, untuk bagian yang
      datanya disediakan.
- [ ] Memuat pos tujuan beserta saldo awalnya, untuk bagian yang datanya
      disediakan.
- [ ] Menghasilkan angka yang sama persis dengan spreadsheet asli untuk
      seluruh bagian yang diimpor.

> **Catatan revisi (11 September 2026):** requirement ini semula
> menyiratkan proses impor di dalam aplikasi (lihat D-6.1 lama, layar
> "Impor Seed" dengan checklist progres) untuk rentang tanggal tetap
> November 2025–September 2026. Pemilik secara eksplisit meminta
> sebaliknya: operasi sekali pakai tanpa UI dan tanpa versi produksi,
> cakupan data mengikuti apa yang benar-benar pemilik punya — bukan
> diasumsikan penuh. Lihat ADR-0009 (catatan revisi Fase 6) untuk detail
> implementasi.

## 8. Kebutuhan non-fungsional

### 8.1 Ketepatan

**NFR-ACC-001** Seluruh nominal disimpan sebagai bilangan bulat satuan sen, dan
pembulatan hanya terjadi saat menampilkan. Aturan ini wajib karena pajak 2,5%
menghasilkan pecahan setengah rupiah, dan pembulatan yang terlalu dini meleset
satu rupiah dari catatan pemilik.

**NFR-ACC-002** Setiap rumus domain punya uji unit dengan angka nyata dari
spreadsheet sebagai kasus uji.

### 8.2 Kinerja

**NFR-PERF-001** Layar siklus bulanan tampil di bawah satu detik pada perangkat
kelas menengah.

**NFR-PERF-002** Perubahan sumber roll-up terlihat pada baris anggaran tanpa
perlu memuat ulang layar.

### 8.3 Keandalan

**NFR-REL-001** Aplikasi berfungsi penuh tanpa koneksi internet. Seluruh data
MVP tersimpan di perangkat.

**NFR-REL-002** Data bertahan setelah aplikasi ditutup, diperbarui, dan
perangkat dimulai ulang.

**NFR-REL-003** Skema penyimpanan menyertakan nomor versi supaya migrasi bisa
dilakukan tanpa kehilangan data.

### 8.4 Kegunaan

**NFR-UX-001** Mencatat satu transaksi kartu atau satu entri jam kerja selesai
dalam satu layar.

**NFR-UX-002** Istilah antarmuka mengikuti istilah yang sudah dipakai pemilik di
spreadsheet, sesuai [glosarium](../00-foundation/PROJECT_GLOSSARY.md).

**NFR-UX-003** Antarmuka mendukung tema terang dan gelap, mengikuti pengaturan
sistem.

**NFR-UX-004** Seluruh teks antarmuka berasal dari berkas terjemahan, tersedia
dalam bahasa Indonesia dan Inggris.

### 8.5 Keamanan

**NFR-SEC-001** Data keuangan tersimpan di penyimpanan aplikasi dan tidak
dikirim ke mana pun pada MVP.

### 8.6 Dukungan platform

**NFR-PLAT-001** Android dan iOS, dengan Flutter versi stabil dan Dart minimal
3.11.4 sesuai kebutuhan paket internal.

## 9. Arsitektur tingkat tinggi

Rincian lengkapnya ada di
[ARCHITECTURE_OVERVIEW.md](../02-architecture/ARCHITECTURE_OVERVIEW.md).

- **Aplikasi:** Flutter, Clean Architecture tiga zona (`core`/`shared`/`features`),
  mengikuti struktur `flutter-architecture-studi-bank` (`lib/v2`).
- **State:** pola bloc dengan efek sekali jalan dari `package:state_management`.
- **Penyimpanan:** Hive lewat `package:api_storage` dan `package:hive_storage`.
- **Navigasi:** registri rute bertipe dari `package:navigation` di atas
  `go_router`.
- **Kesalahan:** `Either<Failure, T>` dari fpdart (`package:dependencies`),
  dengan mixin `RepositoryGuard`.
- **Terjemahan:** slang dengan bahasa dasar Indonesia dan tambahan Inggris.
- **Tema:** tetap dari `new-health-duel`, dipetakan ulang ke konteks keuangan.
- **Backend:** tidak ada pada MVP.

## 10. Prinsip antarmuka

Sistem token desain diambil dari `new-health-duel`, dengan slot warna semantik
dipetakan ulang ke konteks keuangan. Rinciannya ada di
[ADR-0006](../02-architecture/adr/0006-design-token-semantic-color-mapping.md).

| Peran | Slot | Dipakai untuk |
|---|---|---|
| Pemasukan | `income` | Nominal masuk, sisa positif |
| Pengeluaran | `expense` | Nominal keluar |
| Lewat anggaran | `overBudget` | Sisa negatif |
| Investasi | `investment` | Pos tujuan dan alokasi |
| Roll-up | `rollUp` | Baris yang nominalnya dihitung dari sumber lain |
| Perlu ditinjau | `needsReview` | Baris hasil rollover yang belum dikonfirmasi |

Prinsipnya: angka adalah elemen utama tiap layar, dan status baris terbaca dari
warnanya tanpa perlu membuka detail.

## 11. Risiko dan mitigasi

| Risiko | Dampak | Kemungkinan | Mitigasi |
|---|---|---|---|
| Paket internal gagal di-resolve karena menyatakan `resolution: workspace` | Tinggi | Sedang | Diuji lebih dulu sebagai gerbang di Fase 0. Kalau gagal, dorong branch kompatibilitas di `advance-mobile-platform`. Lihat [ADR-0001](../02-architecture/adr/0001-internal-package-dependency-strategy.md). |
| Hasil hitung meleset dari spreadsheet | Tinggi | Rendah | Aritmatika integer sen, ditambah uji unit memakai angka nyata. |
| Batas siklus tagihan kartu tidak konsisten | Rendah | Sedang | Siklus bisa disunting manual, tidak semata mengikuti tanggal cetak. |
| Hive kurang memadai saat data tumbuh | Sedang | Rendah | Akses data lewat antarmuka repository sehingga mesin penyimpanan bisa diganti tanpa menyentuh domain. Lihat [ADR-0002](../02-architecture/adr/0002-local-first-hive-document-storage.md). |
| Cakupan MVP terlalu besar untuk sekali jalan | Sedang | Sedang | Dipecah menjadi fase bernomor di [ROADMAP](../04-planning/ROADMAP.md), tiap fase menghasilkan aplikasi yang tetap berjalan. |

## 12. Pengembangan setelah MVP

- **Tahap 2 — Sinkronisasi.** Firebase atau Google Drive, dengan penyelesaian
  konflik.
- **Tahap 3 — Rumah tangga.** Dua pengguna saling melihat, dengan kepemilikan
  per transaksi.
- **Tahap 4 — Laporan.** Tren tahunan, perbandingan antar bulan, grafik per
  kategori.
- **Tahap 5 — Otomasi masukan.** Membaca transaksi kartu dari surel atau
  notifikasi.

## 13. Pertanyaan terbuka

Seluruh pertanyaan dari versi dokumen sebelumnya sudah terjawab pemilik pada
10 September 2026 — lihat [DOMAIN_MODEL.md bagian "Nilai seed
terkonfirmasi"](../02-architecture/DOMAIN_MODEL.md#nilai-seed-terkonfirmasi)
untuk nilainya (tarif per jam Rp72.500, tanggal cetak tagihan kartu 15, saldo
awal pos 0, dan keputusan bahwa `GoalLoan` hanya merujuk `Goal` terdaftar
dengan daftar yang terbuka). Tidak ada pertanyaan terbuka lagi pada MVP.

## 14. Lampiran

- [Analisis proses manual](../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
- [Glosarium proyek](../00-foundation/PROJECT_GLOSSARY.md)
- [Model domain](../02-architecture/DOMAIN_MODEL.md)
- [Gambaran arsitektur](../02-architecture/ARCHITECTURE_OVERVIEW.md)
- [User stories](user-stories.md)
- [Daftar tugas](../04-planning/TASK_LIST.md)
