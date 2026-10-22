# Ekspor ke spreadsheet, cadangkan dan pulihkan manual

**Tanggal:** 22 Oktober 2026.
**Status:** KT-E1–KT-E5 diputuskan pemilik 22 Okt 2026 sesuai rekomendasi
(§11). Menunggu rupa (T-22.0) dan ADR engineer (T-22.1). Tugasnya Fase 22 di
TASK_LIST (dari B-42).
**Berkaitan:** [FREEMIUM_PAYWALL.md](FREEMIUM_PAYWALL.md) §1 butir 7, §6.6,
§12.1, KT-P7 (gratis, sebelum rilis publik, dasar cadangan otomatis B-51);
[ADR-024](../../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)
(data milik perangkat, pemulihan mengganti tanpa penggabungan);
[ADR-012](../../02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md)
(tata letak penyimpanan, saldo dompet di-cache);
[ADR-025](../../02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md)
(satu mata uang, nominal `int` sen);
[FINANCIAL_PERIOD.md](FINANCIAL_PERIOD.md) (periode keuangan, `periodDateOf`);
[FEATURE_DISCOVERY.md](FEATURE_DISCOVERY.md) (onboarding dan izin Fase 21).

Dokumen ini merancang perilaku, alur, aturan, dan teks. **Cara teknisnya
tidak diputuskan di sini:** format berkas cadangan, cara menulisnya secara
atomik, pustaka spreadsheet, dan cara menyimpan berkas di Android ditulis
engineer sebagai ADR di T-22.1, dengan batasan di §10. Rupa mengikuti
komponen yang sudah ada; yang belum ada ditandai "perlu rupa dari
ui-ux-designer".

## 1. Masalah

Semua catatan pengguna hanya ada di satu ponsel (ADR-024, sinkronisasi belum
ada). Hari ini:

- **Ponsel hilang, rusak, atau diganti = semua catatan hilang.** Tidak ada
  jalan memindahkan data ke ponsel baru. Ini risiko terbesar pengguna hari
  ini, dan penguji closed testing sudah menyimpan data berbulan-bulan.
- **Data tidak bisa dibawa pergi.** Pengguna yang ingin mengolah sendiri di
  Excel/Google Sheets, menyerahkan ke akuntan, atau pindah aplikasi tidak
  punya caranya. FREEMIUM §12.1: tidak etis memungut bayaran dari aplikasi
  yang datanya belum bisa dibawa pergi.

Dua kebutuhan berbeda, dua fitur:

| | Ekspor ke spreadsheet | Cadangan |
|---|---|---|
| Untuk | Dibaca dan diolah manusia | Dipulihkan oleh Tanukonomy |
| Isi | Transaksi (dan dompet), nama yang bisa dibaca | Seluruh data dan setelan keuangan, apa adanya |
| Bisa dibaca kembali oleh aplikasi | Tidak (impor di luar cakupan) | Ya |
| Format | `.xlsx` dan `.csv` | Satu berkas cadangan berversi |

## 2. Keputusan yang sudah ada (dari FREEMIUM_PAYWALL, tidak dibuka lagi)

1. Ekspor dan cadangan manual **gratis tanpa batas**, untuk semua pengguna,
   tanpa akun.
2. Dikerjakan **sebelum rilis publik** (KT-P7).
3. Pemulihan **mengganti** data di perangkat, **tanpa penggabungan**
   (ADR-024 §3.3, juga dipakai cadangan otomatis B-51).
4. Format cadangan dipakai ulang oleh cadangan otomatis Google Drive (B-51,
   Plus). Karena itu formatnya **berversi** sejak hari pertama.

Catatan penomoran: FREEMIUM §13.4 mengusulkan A1–A2 sebagai Fase 21. Fase 21
sudah dipakai Penemuan fitur, jadi ekspor dan cadangan (A1) dijadwalkan
sebagai **Fase 22**. Kunci aplikasi (A2, B-43) tetap di antrean, tidak ikut
fase ini.

## 3. Prinsip

1. **Mencatat, bukan melakukan.** Ekspor dan cadangan hanya menyalin catatan
   ke berkas. Tidak ada yang dikirim ke server Tanukonomy; berkas disimpan di
   tempat yang dipilih pengguna.
2. **Angka di berkas sama dengan angka di aplikasi.** Total di spreadsheet
   per periode harus sama dengan kartu Arus dan Analisis untuk periode yang
   sama. Aturan 7 (transfer bukan pemasukan/pengeluaran) berlaku di berkas.
3. **Pemulihan tidak pernah menghilangkan data tanpa jalan kembali.** Data
   lama selalu disalin ke cadangan pengaman sebelum diganti (R-5).
4. **Semua atau tidak sama sekali.** Pemulihan yang gagal di tengah
   meninggalkan data lama utuh.
5. **Bahasa jujur.** Teks menyebut di mana berkas disimpan dan apa yang tidak
   ikut, tanpa menakut-nakuti.

## 4. Tempat

| Pintu | Isi |
|---|---|
| **Akun › Data kamu** (utama) | Tiga baris: **Ekspor ke spreadsheet**, **Cadangkan sekarang** (dengan status "Cadangan terakhir: 12 Okt 2026" atau "Belum pernah dicadangkan"), **Pulihkan dari cadangan**. Teks bagian diubah (§9). |
| **Riwayat** (pintasan) | Menu ⋮ di kepala Riwayat: **Ekspor periode ini**. Membuka lembar ekspor dengan rentang = periode yang sedang dilihat. |
| **Onboarding** (ganti ponsel) | Tautan **Sudah punya cadangan? Pulihkan** di slide pertama (§7.3). |

Penemuan: baris Akun cukup untuk R1. Pengingat lembut untuk mencadangkan
(FREEMIUM P8 menjadi pemicu paywall nanti) **tidak** dikerjakan di fase ini;
status "Cadangan terakhir" di Akun adalah satu-satunya isyarat (KT-E5).

## 5. Ekspor ke spreadsheet

### 5.1 Alur

1. Pengguna membuka **Ekspor ke spreadsheet** (Akun) atau **Ekspor periode
   ini** (Riwayat).
2. Lembar ekspor:
   - **Rentang**: Periode ini · Periode lalu · Tahun ini · Semua · Pilih
     rentang (dua tanggal). Periode mengikuti periode keuangan pengguna;
     "Tahun ini" = 1 Januari s.d. hari ini menurut tanggal transaksi.
   - **Format**: **Excel (.xlsx)** terpilih bawaan · CSV (KT-E1).
   - Ringkasan sebelum ekspor: "142 transaksi, 1 Sep – 22 Okt 2026".
3. **Ekspor** → lembar sistem untuk menyimpan atau membagikan (Simpan ke
   Berkas/Drive, kirim ke aplikasi lain) (KT-E3).
4. Selesai: pesan singkat "Berkas siap: tanukonomy-transaksi-2026-09-01_2026-10-22.xlsx".

Rentang tanpa transaksi: tombol Ekspor nonaktif, teks "Tidak ada transaksi
di rentang ini."

### 5.2 Isi: lembar **Transaksi** (xlsx) / berkas transaksi (csv)

Satu baris per transaksi, terurut tanggal naik. Judul kolom mengikuti bahasa
aplikasi; kolom ID selalu ada di ujung agar baris bisa ditelusuri.

| Kolom | Isi | Aturan |
|---|---|---|
| Tanggal | `YYYY-MM-DD` | `date` transaksi |
| Awal periode | `YYYY-MM-DD` | Tanggal awal periode keuangan tempat transaksi dihitung, lewat `periodDateOf` (gajian maju ≤ 7 hari ikut periode kemunculannya, FINANCIAL_PERIOD). Dipakai untuk pivot per periode; bisa berbeda dari Tanggal, sengaja. |
| Jenis | Pemasukan / Pengeluaran / Transfer | |
| Nominal | Angka positif dalam satuan utama, tanpa pemisah ribuan | Dari `int` sen; desimal hanya bila mata uangnya berdesimal (ADR-025). Di xlsx bertipe angka. |
| Arus | Pemasukan `+Nominal`, Pengeluaran `−Nominal`, Transfer `0` | Jumlah kolom ini per periode = Arus di aplikasi (aturan 7). |
| Mata uang | Kode, mis. `IDR` | |
| Dompet | Nama dompet | Transfer: dompet asal |
| Dompet tujuan | Nama dompet | Hanya transfer |
| Kategori | Nama kategori | Kosong untuk transfer dan tanpa kategori; kategori terarsip tetap ditulis namanya |
| Catatan | Teks catatan | |
| Anggaran / Pos anggaran | Nama | Bila tertaut pos |
| Rutin | Nama rutin | Bila tertaut kemunculan rutin |
| Proyek freelance | Nama proyek | Bila pemasukan dari pembayaran freelance |
| ID | ID transaksi | |

Lembar **Dompet** (hanya xlsx): Nama, Saldo awal, Saldo sekarang. Saldo
sekarang = saldo di aplikasi saat ekspor, tidak dibatasi rentang.

**Contoh** (periode mulai tanggal 25, IDR):

| Tanggal | Awal periode | Jenis | Nominal | Arus | Dompet | Dompet tujuan | Kategori | Catatan | Rutin |
|---|---|---|---|---|---|---|---|---|---|
| 2026-09-23 | 2026-09-25 | Pemasukan | 8500000 | 8500000 | BCA | | Gaji | Gaji Sep | Gaji bulanan |
| 2026-09-26 | 2026-09-25 | Transfer | 1000000 | 0 | BCA | GoPay | | Isi GoPay | |
| 2026-09-26 | 2026-09-25 | Pengeluaran | 45000 | -45000 | GoPay | | Makan | Nasi padang | |

Baris pertama: gaji dicatat 23 Sep untuk kemunculan 25 Sep (maju 2 hari), jadi
dihitung ke periode 25 Sep – 24 Okt, sama seperti di Rencana dan Analisis.
Jumlah Arus periode itu = 8.455.000, sama dengan kartu Arus.

### 5.3 Aturan ekspor

- **E-1** Nominal tidak terpengaruh "Sembunyikan nominal" (itu hanya
  tampilan); lembar ekspor tidak menampilkan nominal bila sedang
  disembunyikan, tetapi berkasnya tetap berisi angka sebenarnya.
- **E-2** Nama dompet, kategori, anggaran, dan rutin ditulis sesuai nama
  **saat ekspor**.
- **E-3** CSV: UTF-8 dengan BOM, pemisah koma, kutip ganda sesuai RFC 4180,
  angka dengan titik desimal. Alasan disediakan xlsx sebagai bawaan: Excel
  berlokal Indonesia memakai titik koma sebagai pemisah daftar, sehingga CSV
  berkoma sering terbuka sebagai satu kolom; xlsx terbuka benar di Excel dan
  Google Sheets tanpa pengaturan.
- **E-4** Tidak ada data yang keluar perangkat selain lewat lembar
  simpan/bagikan yang dipilih pengguna.
- **E-5** Ekspor berjalan luring.
- **E-6** Data besar (mis. 10.000 transaksi): tampil indikator proses dan
  bisa dibatalkan; aplikasi tetap bisa dipakai sesudahnya.

## 6. Cadangkan sekarang

### 6.1 Alur

1. **Akun › Cadangkan sekarang.**
2. Lembar: apa yang ikut dan yang tidak (ringkas, §6.2), "142 transaksi,
   4 dompet, sejak 3 Jun 2026", tombol **Cadangkan**.
3. Berkas dibuat, lalu lembar sistem simpan/bagikan (KT-E3). Nama berkas:
   `tanukonomy-cadangan-2026-10-22.<ekstensi dari ADR>`.
4. Hanya bila penyimpanan **berhasil** (bukan dibatalkan): "Cadangan
   terakhir" diperbarui. Bila pengguna membatalkan lembar sistem, status
   tidak berubah.

Teks lembar mengingatkan satu kali, tanpa menakut-nakuti: "Simpan di tempat
di luar ponsel ini, misalnya Google Drive, supaya tetap aman kalau ponsel
hilang."

### 6.2 Isi cadangan

| Ikut | Tidak ikut |
|---|---|
| Dompet, seluruh transaksi semua bulan | Teks notifikasi dan kotak masuk tangkapan (privasi, ADR-032 menyimpannya paling lama 7 hari) |
| Anggaran dan pos, template anggaran | Izin sistem (notifikasi, akses notifikasi) |
| Kategori (termasuk terarsip dan alias) | Akun dan status masuk |
| Freelance: proyek, worklog, pembayaran | Langganan Plus (dipulihkan dari toko, nanti) |
| Rutin, tautan kemunculan, catatan tinjau Rencana, log catat otomatis | Bahasa, Sembunyikan nominal, progres tur, ingatan pembaruan, segmen terakhir Riwayat (milik perangkat) |
| Jadwal periode keuangan (seluruh riwayat berlaku-sejak) | |
| Mata uang aplikasi | |
| Setelan pengingat (sakelar global dan per rutin) | |
| Aplikasi sumber dan pola Catat dari notifikasi (bukan isi notifikasi) | |

Daftar persis disusun engineer dari repositori yang ada (T-22.1); bila ada
data yang tidak jelas masuk kolom mana, berhenti dan tanya PO.

### 6.3 Aturan cadangan

- **C-1** Satu berkas berisi semuanya, dengan versi format, versi aplikasi,
  waktu dibuat, jumlah per jenis data, dan pemeriksa keutuhan (checksum).
- **C-2** Tanpa sandi di R1 (KT-E2). Teks menyebut bahwa berkas berisi
  catatan keuangan dan perlu disimpan di tempat yang aman.
- **C-3** Bisa dibuat tanpa akun dan tanpa koneksi.
- **C-4** Membuat cadangan tidak mengubah data apa pun.
- **C-5** Format yang sama dipakai cadangan otomatis B-51 (Plus) kelak.

## 7. Pulihkan dari cadangan

### 7.1 Alur (dari Akun)

1. **Akun › Pulihkan dari cadangan** → pemilih berkas sistem.
2. Aplikasi memeriksa berkas (R-1–R-3). Gagal → pesan sesuai §9, data tidak
   tersentuh.
3. **Pratinjau**: "Cadangan 12 Okt 2026 · 138 transaksi · 4 dompet · sejak
   3 Jun 2026 · IDR" dibandingkan dengan data di ponsel ini sekarang ("142
   transaksi · 4 dompet").
4. **Peringatan penggantian** (ADR-024 §3.3): "Semua data di ponsel ini akan
   diganti dengan isi cadangan. Data yang sekarang disimpan dulu sebagai
   cadangan pengaman." Tombol **Ganti data** (berbahaya) dan **Batal**.
   Bila cadangan lebih lama dari data sekarang (jumlah transaksi lebih
   sedikit atau tanggal cadangan lebih lama dari transaksi terakhir),
   tambahkan satu baris: "Cadangan ini lebih lama dari data di ponsel ini;
   catatan sesudah 12 Okt 2026 akan hilang dari ponsel ini."
5. Proses: cadangan pengaman dibuat (R-5) → data diganti secara atomik (R-4)
   → saldo dompet dihitung ulang (R-6) → pengingat dijadwalkan ulang.
6. Selesai: "Data dipulihkan dari cadangan 12 Okt 2026." lalu ke Beranda.
   Bila cadangan memuat Catat dari notifikasi atau pengingat yang menyala,
   izinnya diminta ulang lewat pintu Fase 21 (baris Beranda menjadi
   **Izinkan**), tidak otomatis.

### 7.2 Aturan pulihkan

- **R-1** Berkas bukan cadangan Tanukonomy, rusak, atau checksum tidak cocok:
  tolak, data tidak tersentuh.
- **R-2** Versi format **lebih baru** dari yang dikenal aplikasi: tolak dengan
  "Cadangan ini dibuat oleh versi Tanukonomy yang lebih baru. Perbarui
  aplikasi lalu coba lagi." Versi **lebih lama**: dimigrasi lalu dipulihkan.
- **R-3** Isi tidak konsisten (mis. transaksi merujuk dompet yang tidak ada):
  tolak sebagai rusak. Tidak ada pemulihan sebagian.
- **R-4** **Semua atau tidak sama sekali.** Aplikasi ditutup, baterai habis,
  atau galat di tengah: saat dibuka lagi data lama utuh, atau data cadangan
  utuh, tidak pernah campuran.
- **R-5** **Cadangan pengaman.** Sebelum mengganti, data sekarang disimpan
  di penyimpanan aplikasi. Akun menampilkan baris **Kembalikan data sebelum
  pemulihan** (dengan tanggal) sampai pemulihan berikutnya atau 30 hari
  (KT-E4). Mengembalikannya memakai alur dan aturan yang sama. Hanya satu
  cadangan pengaman yang disimpan.
- **R-6** Saldo dompet dihitung ulang dari saldo awal dan transaksi
  (`recomputeWalletBalances`, ADR-012), bukan dipercaya dari berkas.
- **R-7** Mata uang ikut cadangan. Bila berbeda dari mata uang sekarang,
  pratinjau menyebutnya ("Mata uang akan menjadi USD"); nominal tidak
  dikonversi (ADR-025).
- **R-8** Tanpa penggabungan, tanpa pilih sebagian (ADR-024 §3.3).
- **R-9** Bahasa, tampilan, dan progres tur di perangkat ini tidak berubah.
- **R-10** Kotak masuk tangkapan yang belum ditinjau di ponsel ini ikut
  terganti; bila ada, pratinjau menyebut jumlahnya ("3 draf dari notifikasi
  yang belum ditinjau tidak ikut").

### 7.3 Pulihkan saat onboarding (ganti ponsel)

- Slide pertama onboarding memuat tautan **Sudah punya cadangan? Pulihkan**.
- Urutan: pilih bahasa (agar teks terbaca) → pilih berkas → pratinjau →
  pulihkan. Tanpa peringatan penggantian karena belum ada data; cadangan
  pengaman tidak dibuat.
- Sesudah berhasil: langkah mata uang dan awal periode **dilewati** (diambil
  dari cadangan). Langkah pengingat (Fase 21) tetap tampil hanya bila
  cadangan memuat pengingat menyala, untuk meminta izin sistem di perangkat
  ini; selain itu langsung ke Beranda. Onboarding dianggap selesai.
- Gagal: kembali ke onboarding biasa dengan pesan §9.

## 8. Kasus tepi

| Kasus | Perilaku |
|---|---|
| Cadangan dari ponsel lain dengan akun lain | Dipulihkan; akun tidak terkait data (ADR-024). |
| Data sangat besar | Indikator proses, tidak bisa dibatalkan setelah penggantian dimulai (R-4). |
| Ruang penyimpanan penuh | Tolak sebelum mengganti, data lama utuh. |
| Pengguna memulihkan cadangan yang sama dua kali | Boleh; hasilnya sama. |
| Sedang ada tur spotlight | Ekspor/cadangan tidak memulai tur. |
| iOS | Berlaku sama; lembar simpan/bagikan iOS. Bagian Catat dari notifikasi di cadangan diabaikan saat dipulihkan di iOS. |
| Plus (kelak) | Ekspor dan cadangan manual tetap gratis, tidak pernah di balik paywall (FREEMIUM §10). |

## 9. Teks (kunci i18n, id; en menyusul)

Ruang nama `dataPortability.*`; teks akhir disetujui PO, mengikuti
`writing.md`.

| Kunci | Isi (draf) |
|---|---|
| `account.dataBody` (diubah) | Semua catatanmu tersimpan di ponsel ini. Cadangkan ke tempat lain supaya tetap aman, atau ekspor ke spreadsheet. |
| `dataPortability.exportTitle` | Ekspor ke spreadsheet |
| `dataPortability.exportRange` | Rentang |
| `dataPortability.exportSummary` | {n} transaksi, {range} |
| `dataPortability.exportEmpty` | Tidak ada transaksi di rentang ini. |
| `dataPortability.exportDone` | Berkas siap: {file} |
| `dataPortability.backupTitle` | Cadangkan sekarang |
| `dataPortability.backupLast` / `backupNever` | Cadangan terakhir: {date} / Belum pernah dicadangkan |
| `dataPortability.backupHint` | Simpan di tempat di luar ponsel ini, misalnya Google Drive, supaya tetap aman kalau ponsel hilang. Berkas ini berisi catatan keuanganmu. |
| `dataPortability.restoreTitle` | Pulihkan dari cadangan |
| `dataPortability.restoreWarning` | Semua data di ponsel ini akan diganti dengan isi cadangan. Data yang sekarang disimpan dulu sebagai cadangan pengaman. |
| `dataPortability.restoreOlder` | Cadangan ini lebih lama dari data di ponsel ini; catatan sesudah {date} akan hilang dari ponsel ini. |
| `dataPortability.restoreConfirm` | Ganti data |
| `dataPortability.restoreDone` | Data dipulihkan dari cadangan {date}. |
| `dataPortability.errorInvalid` | Berkas ini bukan cadangan Tanukonomy atau sudah rusak. Datamu tidak berubah. |
| `dataPortability.errorNewer` | Cadangan ini dibuat oleh versi Tanukonomy yang lebih baru. Perbarui aplikasi lalu coba lagi. |
| `dataPortability.errorSpace` | Ruang penyimpanan tidak cukup. Datamu tidak berubah. |
| `dataPortability.undoRestore` | Kembalikan data sebelum pemulihan ({date}) |
| `onboarding.restoreLink` | Sudah punya cadangan? Pulihkan |

## 10. Batasan untuk ADR engineer (T-22.1)

Engineer memilih dan menulis di ADR: format dan ekstensi berkas cadangan,
struktur versi dan migrasi, checksum, cara penggantian atomik di atas
`hive_storage`, tempat cadangan pengaman, pustaka xlsx, dan cara menyimpan
berkas (Storage Access Framework / lembar bagi). Batasannya:

1. Tidak ada server Tanukonomy; tidak ada data keluar selain lewat pilihan
   pengguna.
2. Penggantian atomik (R-4) dibuktikan dengan uji, termasuk gangguan di
   tengah.
3. Nominal tetap `int` sen di cadangan; konversi ke satuan utama hanya di
   ekspor.
4. Format bisa dibaca versi aplikasi berikutnya (migrasi), dan dipakai ulang
   B-51.
5. Uji bolak-balik: cadangkan → pulihkan di aplikasi kosong → seluruh layar
   (saldo, Arus, Rencana, Analisis, Rutin) identik.
6. Uji ekspor: jumlah kolom Arus per Awal periode = Arus aplikasi untuk
   periode yang sama, termasuk periode peralihan dan gajian maju.
7. Bila sebuah batasan tidak bisa dipenuhi, berhenti dan lapor ke PO.

## 11. Keputusan pemilik (KT-E1–KT-E5, 22 Okt 2026)

Semua diputuskan sesuai rekomendasi PO.

| # | Pertanyaan | Keputusan |
|---|---|---|
| KT-E1 | Format ekspor | **xlsx (bawaan) dan CSV.** xlsx terbuka benar di Excel lokal Indonesia; CSV untuk aplikasi lain. |
| KT-E2 | Sandi pada berkas cadangan | **Tanpa sandi di R1.** Sandi yang lupa = cadangan tidak bisa dipakai, dan berkas disimpan di tempat pilihan pengguna. Sandi opsional masuk antrean (bersama B-51 yang memang terenkripsi). |
| KT-E3 | Cara menyimpan berkas | **Lembar sistem dengan dua pilihan: Simpan ke… (pemilih lokasi, termasuk Drive) dan Bagikan.** |
| KT-E4 | Cadangan pengaman sebelum pemulihan disimpan berapa lama | **Sampai pemulihan berikutnya, paling lama 30 hari.** |
| KT-E5 | Pengingat untuk mencadangkan | **Tidak di fase ini;** cukup status "Cadangan terakhir" di Akun. Pengingat lembut bisa jadi B-n sesudah ada data pemakaian, terpisah dari pemicu paywall P8. |

## 12. Analitik

Mengikuti ADR-023: tanpa nominal, nama, atau isi data.

| Peristiwa | Parameter |
|---|---|
| `export_created` | `format` (`xlsx`/`csv`), `range` (`period`/`last_period`/`year`/`all`/`custom`), `rows_bucket` (`<100`/`<1000`/`<10000`/`10000+`), `surface` (`account`/`history`) |
| `backup_created` | `rows_bucket`, `saved` (`true`/`false`) |
| `restore_started` / `restore_completed` / `restore_failed` | `surface` (`account`/`onboarding`/`undo`), `reason` untuk gagal (`invalid`/`newer`/`inconsistent`/`space`/`other`) |

## 13. Ukuran keberhasilan (indikatif)

- Persentase pengguna aktif dengan cadangan dalam 30 hari terakhir.
- Pemulihan yang berhasil dibanding yang dimulai (target: tidak ada
  `restore_failed` dengan `other`).
- Tidak ada laporan data campuran atau hilang sesudah pemulihan.

## 14. Tidak dikerjakan di fase ini

- Impor dari CSV atau dari aplikasi lain.
- Cadangan otomatis (B-51, Plus) dan sinkronisasi (B-7).
- Ekspor laporan PDF atau ringkasan Analisis (B-49, Plus).
- Penggabungan data atau pemulihan sebagian.
- Sandi cadangan (antrean, KT-E2).
- Pengingat untuk mencadangkan (KT-E5).
