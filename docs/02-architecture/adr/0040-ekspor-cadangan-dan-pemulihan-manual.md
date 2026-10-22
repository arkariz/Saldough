# Ekspor ke spreadsheet, cadangan, dan pemulihan manual

## 1. Metadata

- **Decision ID:** ADR-040
- **Tanggal:** 2026-10-22
- **Fase roadmap:** Fase 22 (T-22.1)
- **Status:** Proposed (menunggu persetujuan pemilik; fondasi T-22.1 tidak
  ditulis sebelum Accepted)
- **Cakupan:** Fitur baru `data_portability` (`lib/features/data_portability/`),
  glue akar komposisi (`lib/app/data_portability/`, `lib/main.dart`,
  `lib/app/di/root_module.dart`), baris di layar Akun dan tautan di onboarding

## 2. Konteks

[EXPORT_BACKUP.md](../../01-product/features/EXPORT_BACKUP.md) menetapkan
perilaku (aturan E-1–E-6, C-1–C-5, R-1–R-10), memutuskan KT-E1–KT-E5, dan
menyerahkan tujuh hal teknis ke engineer (§10): format berkas cadangan,
versi dan migrasi, checksum, penggantian atomik di atas `hive_storage`, tempat
cadangan pengaman, pustaka xlsx, dan cara menyimpan berkas. Dokumen itu juga
mengikat tujuh batasan yang harus dipenuhi ADR ini (tanpa server, atomik dan
terbukti oleh uji gangguan, nominal `int` sen, berversi dan dipakai ulang B-51,
uji bolak-balik, uji ekspor terhadap Arus, berhenti bila tidak terpenuhi).

Keadaan kode yang relevan (diperiksa 22 Okt 2026 di `origin/main`):

- **Satu box Hive, satu string per kunci.** `HiveKeyValueStorage.initialize(boxName:
  'saldough_kv')` (`root_module.dart`). Tiap repositori menyimpan satu dokumen
  JSON `{schemaVersion, ...}` di kunci `<namespace>_<name>` (`StorageKey.value`).
  Tata letak aslinya di [ADR-012](0012-tata-letak-penyimpanan-buku-besar.md);
  sejak itu bertambah banyak kunci (Fase 11–21).
- **Port `KeyValueStorage` sangat sempit**: `read`, `write`, `remove`,
  `contains`, `clear`. **Tidak ada daftar kunci, tidak ada penulisan banyak
  kunci sekaligus, tidak ada transaksi.** Port berada di paket pinned
  `advance-mobile-platform` (ADR-001), jadi tidak diubah dari sini.
- **Box yang sama juga memuat data milik perangkat** yang menurut R-9 tidak
  boleh berubah saat pemulihan (bahasa, sembunyikan nominal, progres tur,
  ingatan pembaruan, segmen Riwayat). Karena itu `clear()` tidak boleh dipakai.
- **Ada kunci dinamis**: partisi transaksi `transaction_YYYY-MM` (didaftar di
  `transaction__index`) dan ikon sumber `source_icon_<id>` (dirujuk
  `Transaction.sourceIconId`).
- **Bootstrap memuat banyak state global dalam memori sebelum `runApp`**
  (`main.dart`): `AmountVisibility`, `ActiveFinancialMonth`, `ActiveCategories`,
  `ActiveCurrency`, `SourceIcons`, kontainer GetIt, dan `GoRouter`. Membangun
  ulang pohon widget saja tidak membuang state ini.
- Dependensi transitif yang sudah terkunci di `pubspec.lock`: `archive` 4.3.0,
  `crypto` 3.0.7, `share_plus` 13.3.1, `path_provider` 2.1.6. **Belum ada**
  pustaka xlsx maupun pemilih berkas (`file_picker`).

## 3. Keputusan

Saldough menyalin **dokumen penyimpanan apa adanya** ke satu berkas berversi
untuk cadangan, dan menerapkannya kembali lewat **jurnal tulis-dulu dengan
roll-forward** yang dijalankan oleh jalur bootstrap yang sama dengan pemulihan
dari gangguan. Ekspor ke spreadsheet dibuat terpisah dari data mentah: dibaca
lewat repositori, nama diselesaikan, lalu ditulis ke xlsx atau CSV.

### 3.1 Struktur kode

| Tempat | Isi |
|---|---|
| `lib/features/data_portability/domain/` | Entitas ringkasan dan baris ekspor, port (`ExportDataSource`, `FileTransfer`), use case `ExportTransactions`, `CreateBackup`, `InspectBackup`, `StageRestore`, aturan validasi |
| `lib/features/data_portability/data/` | Penulis xlsx dan CSV, kodek amplop cadangan, `BackupScope`, jurnal pemulihan, adaptor `FileTransfer` (`file_picker` + `share_plus`) |
| `lib/features/data_portability/presentation/` | Lembar ekspor, cadangkan, pulihkan; bloc; baris Akun yang dipasang akar komposisi |
| `lib/app/data_portability/` | `BackupRegistry` (daftar kunci), adaptor `ExportDataSource` ke repositori fitur lain, `AppReboot`, penyisipan baris Akun dan tautan onboarding |

Fitur ini tidak diimpor Akun maupun onboarding: baris dan tautannya disisipkan
akar komposisi, sama dengan pola `accountVersionEntry` (ADR-039) dan
`enableReminders` di onboarding. Batas impor ADR-030 tidak dilonggarkan;
`import_boundaries_test.dart` tetap harus lulus.

### 3.2 Format berkas cadangan

- **Ekstensi `.tkbak`**, tipe MIME `application/octet-stream`. Pemilih berkas
  Android tidak bisa menyaring ekstensi khusus, jadi pemilih menerima semua
  berkas dan aplikasi memeriksa isinya, bukan namanya.
- **Isi: `gzip(utf8(JSON))`.** `gzip` dari `dart:io` (tanpa dependensi),
  mengecilkan ukuran kira-kira satu per sepuluh, dan membawa CRC bawaan.
- **Amplop JSON versi 1:**

```json
{
  "format": "tanukonomy-backup",
  "formatVersion": 1,
  "createdAt": "2026-10-22T09:12:00+07:00",
  "app": { "version": "0.8.0", "build": 14 },
  "summary": { "transactions": 142, "wallets": 4, "firstDate": "2026-06-03", "currency": "IDR" },
  "docs": { "wallet_all": "<string persis seperti tersimpan>", "transaction_2026-10": "..." },
  "sha256": "<hex>"
}
```

- **`docs` menyalin string tersimpan per kunci, tanpa dipetakan ke entitas.**
  Akibatnya nominal tetap `int` sen persis seperti di penyimpanan (batasan 3),
  tidak ada kode pemetaan per entitas yang bisa lupa satu field, dan versi
  skema lama dimigrasi oleh pembaca masing-masing repositori yang memang sudah
  menangani `schemaVersion` untuk basis pengguna yang terpasang (batasan 4).
- **`sha256`** dihitung atas byte: untuk tiap kunci terurut naik,
  `utf8(kunci) 0x00 utf8(nilai) 0x00`. Tidak bergantung pada format JSON.
- **`summary`** hanya untuk pratinjau murah dan daftar B-51. **Pratinjau di
  alur pulihkan dihitung dari `docs`**, bukan dipercaya dari `summary`.
- **Versi:** `formatVersion` lebih tinggi dari yang dikenal → tolak (R-2).
  Selain itu `schemaVersion` tiap dokumen lebih tinggi dari yang didukung
  `BackupRegistry` → tolak dengan pesan yang sama. Versi lebih rendah diterima
  apa adanya; repositori memigrasinya saat dibaca.
- **Tanpa sandi di R1** (KT-E2). Amplop tidak menyediakan tempat sandi di
  versi 1; cadangan terenkripsi B-51 menaikkan `formatVersion`.

### 3.3 Daftar isi cadangan: `BackupRegistry` dan `BackupScope`

`BackupRegistry` (`lib/app/data_portability/`) mendaftarkan **tiap kunci
penyimpanan** dengan salah satu status: `include` (bersama
`supportedSchema`), atau `exclude` (bersama alasan). `BackupScope.collect(storage)`
mengubahnya menjadi peta `kunci → string` dengan menambah kunci dinamis:

- partisi `transaction_YYYY-MM` dari `transaction__index`, ditambah **sondase
  `contains`** untuk setiap bulan antara bulan pertama dan terakhir di indeks
  (port tidak punya daftar kunci, jadi lubang indeks tidak akan terlihat
  tanpanya);
- `source_icon_<id>` untuk setiap `sourceIconId` yang dirujuk transaksi.

`BackupScope.collect` dipakai **tiga kali**: untuk cadangan, untuk salinan
pengaman, dan untuk menentukan kunci lama yang harus dihapus saat penggantian.
Satu fungsi memastikan ketiganya selalu sepaham.

**Uji kelengkapan** (`backup_registry_completeness_test.dart`): memindai
`lib/` untuk setiap deklarasi `StorageKey(namespace:..., name:...)` dan gagal
bila ada kunci yang belum diklasifikasi. Fitur berikutnya yang menyimpan data
tidak bisa lolos tanpa memutuskan ikut atau tidaknya ke cadangan.

Klasifikasi (rekomendasi, lihat §3.9 untuk yang butuh keputusan):

| Status | Kunci |
|---|---|
| **Ikut** (data) | `wallet_all`, `transaction__index`, `transaction_*`, `source_icon_*`, `budget_all`, `budget_template_all`, `category_all`, `category__migration`, `freelance_projects`, `freelance_worklog`, `freelance_payments`, `recurring_all`, `recurring_auto_record_log`, `recurring_match_log`, `recurring_suggestion_dismissed`, `plan_month_review`, `plan_forecast_snapshots` |
| **Ikut** (setelan keuangan) | `settings_financial_month_schedule`, `settings_financial_month_start` (lama, dibaca untuk migrasi), `settings_financial_month_offer`, `settings_currency`, `settings_recurring_reminders`, `settings_notification_capture`, `capture_notification_patterns` |
| **Tidak ikut** (milik perangkat atau sementara) | `settings_language`, `settings_hideAmounts`, `settings_history_segment`, `tutorial_progress`, `app_update_memory`, `app_update_notes`, `capture_inbox`, `capture_processed_ids`, `capture_auto_recorded`, `settings_last_backup` (baru, §3.5) |

`category__migration` ikut supaya migrasi kategori lama tidak berjalan lagi
sesudah pemulihan. `settings_financial_month_start` ikut karena pengguna yang
belum termigrasi hanya punya kunci itu.

### 3.4 Pemulihan atomik: jurnal tulis-dulu dengan roll-forward

Port tidak punya transaksi, jadi atomisitas dibangun di atas satu jaminan yang
dimiliki Hive: **satu penulisan satu kunci sampai utuh atau tidak sama sekali**
(Hive menulis frame ber-CRC dan membuang frame terakhir yang terpotong saat
box dibuka). Asumsi ini diuji, bukan dipercaya (§7).

**Box kedua `saldough_restore`**, dibuka lewat
`HiveKeyValueStorage.initialize(boxName: 'saldough_restore')` (adaptor yang
sama, tanpa kode baru). Isinya: `safety/<kunci>` (salinan data lama),
`incoming/<kunci>` (isi cadangan yang akan diterapkan), `meta` dan `journal`.

Tahap pemulihan dari Akun:

1. **Periksa seluruhnya di memori** tanpa menulis apa pun: dekompresi, amplop,
   `formatVersion`, `sha256`, `schemaVersion` per dokumen, **keutuhan
   rujukan** (R-3): indeks ↔ partisi, transaksi ↔ dompet/kategori/ikon sumber,
   rutin ↔ dompet, pembayaran dan worklog ↔ proyek. Gagal → galat §9 EXPORT_BACKUP,
   data tidak tersentuh.
2. **Stage ke `saldough_restore`**: tulis `safety/*` (hasil `BackupScope.collect`
   pada data sekarang) dan `incoming/*`. **Penulisan inilah pemeriksaan ruang
   penyimpanan**: bila penuh, penulisan gagal sebelum data hidup disentuh;
   box dikosongkan, pengguna melihat `errorSpace`.
3. Tulis `journal = {id, state: "staged"}`, lalu **balik ke `applying`**.
   Hanya sampai di sini data hidup masih utuh lama.
4. **`AppReboot`** (§3.7) menjalankan ulang bootstrap. Jalur pemulihan
   bootstrap membaca jurnal dan **menerapkan** (langkah 5).
5. Terapkan, idempoten: `remove` setiap kunci hasil `collect` lama yang tidak ada
   di `incoming`, lalu `write` setiap `incoming`. Kunci di luar cakupan (bahasa,
   tur, dan lain-lain) tidak pernah disentuh (R-9).
6. Tandai `state: "applied"`. Sesudah kontainer DI siap, **finalisasi**:
   `recomputeWalletBalances` (R-6), lalu `state: "done"`; hapus `incoming/*`
   dan perbarui `meta` (tanggal dan kedaluwarsa cadangan pengaman, R-5).

**Pemulihan dari gangguan** memakai kode yang sama, karena pembacaan jurnal
terjadi di setiap bootstrap:

| Jurnal saat aplikasi dibuka | Tindakan | Hasil |
|---|---|---|
| tidak ada | normal | |
| `staged` | buang `saldough_restore`, jurnal dihapus | data lama utuh |
| `applying` | ulangi langkah 5, lalu 6 | data cadangan utuh |
| `applied` | finalisasi saja | data cadangan utuh |

Tidak ada keadaan yang menghasilkan data campuran: sebelum `applying` hanya
data lama ada; sesudahnya penerapan selalu diselesaikan maju. **Karena
pemulihan normal tidak menerapkan data sendiri melainkan hanya menetapkan
jurnal lalu reboot, jalur pemulihan gangguan terlatih setiap kali pengguna
memulihkan.**

**Saat onboarding:** alur yang sama, tanpa langkah `safety` (belum ada data).

**Kembalikan data sebelum pemulihan (R-5)** memakai mesin yang sama dengan
`incoming` diambil dari `safety/*`; hasilnya menghasilkan salinan pengaman baru
dari data saat itu (R-5: "alur dan aturan yang sama"). Satu salinan saja:
penggantian berikutnya menimpanya. `meta.createdAt` dicek saat bootstrap;
salinan lebih tua dari 30 hari (KT-E4) dihapus.

### 3.5 Status "Cadangan terakhir"

Kunci baru `settings_last_backup` (`{schemaVersion, at}`), milik perangkat
(tidak ikut cadangan: ia mencatat aksi di perangkat ini, bukan data keuangan).
Diperbarui hanya bila penyimpanan terkonfirmasi, bukan dibatalkan (EXPORT_BACKUP §6.1): hasil
`saveFile` bukan `null`, atau `Share` melapor `success`. Bila penyedia berbagi
melapor `unavailable` (tidak diketahui), status **tidak** diperbarui dan lembar
menampilkan "Berkas dibagikan" tanpa mengklaim tersimpan. Perilaku di Android
nyata diverifikasi di T-22.3 (§8).

### 3.6 Ekspor ke spreadsheet

- **Tanpa pilihan rentang** (keputusan pemilik 22 Okt): berkas selalu seluruh
  data saat ini.
- **Sumber data lewat port** `ExportDataSource` yang diimplementasikan
  `lib/app/data_portability/` di atas repositori transaksi, dompet, kategori,
  anggaran, rutin, dan freelance. Fitur tidak mengimpor fitur lain (ADR-030),
  mengikuti pola `PlanBudgetSource` di Rencana.
- **Kolom** mengikuti EXPORT_BACKUP §5.2. **Awal periode** memakai
  `periodDateOf` dan `FinancialMonthSchedule` dari `core/financial_month/`
  (aturan gajian maju ≤ 7 hari). **Arus** dihitung di satu fungsi murni
  (`flowOf`: pemasukan `+`, pengeluaran `−`, transfer `0`, aturan 7).
- **Nominal tanpa `double`.** Satuan utama ditulis dari sen dengan aritmetika
  bilangan bulat (`sen ~/ 100` dan `sen % 100`) menjadi teks desimal persis, lalu
  ditulis sebagai angka (`<v>` OOXML menerima teks angka) atau teks CSV. Digit
  desimal mengikuti mata uang (ADR-025); tidak ada pembulatan floating point.
- **xlsx** berisi dua lembar (Transaksi, Dompet). Kolom tanggal berupa sel
  tanggal berformat `yyyy-mm-dd` supaya penyaring dan pivot Excel/Sheets
  bekerja; CSV tetap teks `YYYY-MM-DD`.
- **CSV** UTF-8 dengan BOM, koma, kutip RFC 4180, titik desimal (E-3).
- **Pembuatan di isolate** (`Isolate.run`) untuk gzip, sha256, JSON, dan xlsx
  agar UI tidak tersendat (E-6). Hive tidak bisa dibagi antar isolate, jadi
  dokumen dibaca di isolate utama, dikirim ke isolate kerja. **Batal** bersifat
  kooperatif antar tahap (baca → bangun → simpan); hasil yang selesai setelah
  batal dibuang.

#### Pustaka xlsx: `archive` + penulis OOXML sendiri

Yang dibutuhkan hanya **menulis** dua lembar bertipe sederhana. Saldough
menulis penulis xlsx minimal (`[Content_Types].xml`, `workbook.xml`, dua
`sheet*.xml` dengan `inlineStr`, `styles.xml` untuk format tanggal dan judul
tebal) di atas `archive` (ZIP; sudah terkunci transitif). Tidak ada kebutuhan
membaca xlsx.

### 3.7 Setelah penggantian: `AppReboot`

`AppReboot` menjalankan ulang bootstrap `main()` di dalam proses:
`rootGetIt.reset()`, `registerAll`, pemuatan ulang state global (daftar di
bawah), jalur pemulihan jurnal (§3.4), lalu `runApp` dengan kunci baru. Kotak
Hive tetap terbuka (`Hive.openBox` mengembalikan box yang sama). Selama
penerapan, layar kecil "Memulihkan data…" dipasang lebih dulu. Daftar state
yang dimuat ulang diperiksa uji pemindai (`static final ValueNotifier` di
`lib/` harus terdaftar di `AppReboot` atau dinyatakan bebas data): saat ini
`AmountVisibility`, `ActiveFinancialMonth`, `ActiveCategories`, `ActiveCurrency`,
`SourceIcons`. Pengingat lokal dijadwalkan ulang oleh jalur mulai biasa dari
setelan hasil pemulihan; izin sistem tidak diminta otomatis (EXPORT_BACKUP §7.1).

`main()` dipecah menjadi `bootstrapApp()` yang bisa dipanggil ulang, tanpa
mengubah perilaku peluncuran biasa.

### 3.8 Menyimpan, membagikan, dan memilih berkas

Satu port `FileTransfer` dengan tiga operasi (`saveAs`, `share`, `pickBackup`),
adaptor di `data/` memakai:

- **`file_picker`** untuk `Simpan ke…` (Storage Access Framework di Android,
  pemilih dokumen di iOS) dan untuk memilih berkas pulihkan. **Dependensi baru.**
  Versinya dipin saat T-22.2/T-22.3 dikerjakan.
- **`share_plus`** untuk `Bagikan` (sudah transitif; menjadi langsung).
- **`path_provider`** untuk berkas sementara di direktori cache (sudah transitif).

Tidak ada izin penyimpanan baru: SAF dan pemilih dokumen iOS tidak
memerlukannya. Berkas sementara di cache dihapus setelah dibagikan dan disapu
tiap bootstrap, karena isinya data keuangan. Port ini menjaga `file_picker` dan
`share_plus` bisa diganti dan diuji dengan palsu.

### 3.9 Keputusan yang diminta dari pemilik

EXPORT_BACKUP §6.2 menyuruh bertanya bila ada data yang tidak jelas ikut atau
tidak. Kunci berikut tidak tercantum di tabel itu; rekomendasinya sudah dipakai
di §3.3:

| # | Kunci | Rekomendasi | Alasan |
|---|---|---|---|
| P-1 | `capture_auto_recorded` | **Tidak ikut** | Log pencatatan otomatis dari notifikasi untuk jendela batal; sementara dan terkait kotak masuk yang tidak ikut |
| P-2 | `settings_financial_month_offer` | **Ikut** | Mengingat tawaran tanggal gajian sudah ditolak; tanpanya tawaran muncul lagi |
| P-3 | `plan_forecast_snapshots` | **Ikut** | Saldo akhir bulan lampau tidak bisa dihitung ulang dari data sekarang |
| P-4 | `source_icon_*` | **Ikut** | Bagian dari transaksi (`sourceIconId`); tanpanya ikon sumber hilang |

Selain itu pemilik diminta menyetujui **dependensi langsung baru:**
`file_picker` (baru) dan promosi `archive`, `crypto`, `share_plus`,
`path_provider` dari transitif menjadi langsung.

## 4. Opsi yang dipertimbangkan

Penggantian atomik:

- **Opsi A — Tulis langsung ke box hidup, urutan hati-hati**
- **Opsi B — Box sementara lalu tukar berkas box**
- **Opsi C — Jurnal tulis-dulu dengan roll-forward (Dipilih)**

Isi cadangan:

- **Opsi D — Serialisasi ulang entitas ke JSON cadangan**
- **Opsi E — Salin dokumen tersimpan apa adanya (Dipilih)**

Pustaka xlsx:

- **Opsi F — Paket `excel`**
- **Opsi G — `syncfusion_flutter_xlsio`**
- **Opsi H — `archive` + penulis OOXML minimal (Dipilih)**

Menyimpan berkas:

- **Opsi I — `file_picker` + `share_plus` (Dipilih)**
- **Opsi J — Kode native (Kotlin SAF dan iOS) lewat platform channel**

## 5. Analisis konsekuensi

### Opsi A — Tulis langsung ke box hidup

Paling sederhana: hapus kunci lama, tulis kunci baru. **Ditolak.** Port tidak
punya transaksi, jadi aplikasi yang ditutup di tengah meninggalkan campuran dua
set data (transaksi baru dengan dompet lama), persis yang dilarang R-4. Tidak ada
cara memulihkannya karena tidak ada catatan niat.

### Opsi B — Box sementara lalu tukar berkas box

Tulis semuanya ke box baru, lalu ganti berkas `.hive`. Terdengar atomik, tetapi
bergantung pada operasi berkas di direktori internal Hive saat box terbuka,
yang berbeda antar platform dan tidak dijamin oleh `hive_ce`. Juga menyentuh
data milik perangkat (bahasa, tur) di box yang sama. **Ditolak:** menukar berkas
box adalah operasi rapuh pada struktur yang bukan milik kita.

### Opsi C — Jurnal tulis-dulu dengan roll-forward (Dipilih)

Menerapkan pola klasik log tulis-dulu di atas satu-satunya jaminan yang ada
(satu penulisan satu kunci utuh). Data lama dan baru sama-sama tersimpan di box
kedua sebelum data hidup disentuh; jurnal satu kunci menentukan di sisi mana
pemulihan jatuh. Semua kegagalan menjadi salah satu dari dua hasil yang bersih.
Penerapan idempoten, jadi diulang aman.

Kelemahan jujur: lebih banyak komponen (box kedua, jurnal, finalisasi, reboot);
sementara memerlukan sekitar dua kali ukuran data di penyimpanan; dan seluruh
rancangan bertumpu pada asumsi Hive tentang kunci tunggal yang harus dibuktikan
uji. Biaya itu diterima karena risikonya adalah kehilangan data keuangan.

### Opsi D — Serialisasi ulang entitas

Cadangan memuat entitas yang dipetakan (`Wallet`, `Transaction`, ...). Bentuknya
bersih dan terbaca, tetapi menduplikasi pemetaan tiap repositori dan **setiap
field baru harus ditambahkan di dua tempat**; satu yang terlupa = data hilang
diam-diam pada pemulihan. Ditolak karena risiko itu.

### Opsi E — Salin dokumen tersimpan apa adanya (Dipilih)

Pemulihan menulis kembali string yang sama, sehingga apa yang dibaca aplikasi
persis yang sebelumnya tersimpan. Field baru otomatis ikut. Kelemahannya:
cadangan hanya setia pada tata letak penyimpanan, bukan skema domain
publik, dan perubahan **tata letak** (kunci yang diganti nama atau dipecah)
perlu migrasi di tingkat amplop. Diterima; `formatVersion` dan registri
menyediakan tempat untuk itu, dan uji kelengkapan mencegah kunci terlupa.

### Opsi F — Paket `excel`

Siap pakai, bisa membaca dan menulis. Namun ia mesin spreadsheet umum
sementara kita hanya menulis dua lembar sederhana; menambah dependensi
transitif yang tidak dipakai, dan diketahui boros memori pada berkas besar.
Dipertahankan sebagai **cadangan**: bila penulis OOXML sendiri melebihi sekitar
300 baris atau gagal dibuka di Excel/Sheets pada T-22.2, beralih ke paket ini.

### Opsi G — `syncfusion_flutter_xlsio`

Berfitur lengkap tetapi lisensinya komunitas bersyarat; tidak cocok untuk
aplikasi yang kelak berbayar (Plus). **Ditolak.**

### Opsi H — `archive` + penulis OOXML minimal (Dipilih)

Kontrol penuh atas tipe sel (angka sebagai angka, tanggal sebagai tanggal) dan
nol dependensi baru. Biayanya: kita memelihara penulis kecil dan wajib
mengujinya di Excel dan Google Sheets (QA #10). OOXML tulis-saja yang minimal
terdokumentasi baik dan stabil.

### Opsi I — `file_picker` + `share_plus` (Dipilih)

Menutup KT-E3 (Simpan ke… dan Bagikan) tanpa kode native. `share_plus` sudah
terkunci. Kelemahan: `file_picker` dependensi baru dengan permukaan platform
yang luas, dan hasil `Share` tidak selalu bisa memastikan berkas tersimpan
(§3.5). Dibungkus port `FileTransfer` agar penggantian murah.

### Opsi J — Kode native lewat platform channel

Kontrol penuh tanpa dependensi, tetapi menulis dan memelihara kode SAF Android dan
UIDocumentPicker sendiri, dua bahasa, untuk fitur yang bukan inti. **Ditolak.**

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Menambah data baru ke cadangan = menambah satu baris registri; uji
  kelengkapan memaksa keputusan itu diambil.
- Cadangan otomatis B-51 memakai amplop dan `BackupScope` yang sama, hanya
  menambah pengangkutan dan enkripsi.
- Jalur pemulihan gangguan dan pemulihan biasa adalah satu kode, jadi
  pengujian yang satu menguji yang lain.

### Yang menjadi lebih sulit

- `main()` harus dipecah agar bootstrap bisa dijalankan ulang; ada daftar
  state global yang harus dijaga lengkap.
- Setiap fitur baru yang menyimpan data wajib mengklasifikasikan kuncinya.
- Pemulihan memakai ruang sementara sekitar dua kali ukuran data.

### Risiko yang diterima

- **Asumsi Hive tentang penulisan satu kunci.** Diuji dengan penyisipan galat
  di setiap langkah, tetapi uji unit tidak mematikan proses sungguhan;
  diverifikasi lagi manual di T-22.7 (#4).
- **Lubang indeks partisi di luar rentang bulan** tidak terdeteksi sondase.
  Kecil: `_index` diperbarui dalam operasi yang sama dengan partisinya
  (ADR-012 §7).
- **Cadangan tidak terenkripsi.** Berkas berisi catatan keuangan terbaca setelah
  `gunzip`. Diterima di R1 (KT-E2) dan dikatakan di teks lembar cadangan.
- **Status "Cadangan terakhir" bisa tidak diperbarui** saat penyedia berbagi
  tidak melapor; dipilih gagal-aman, bukan klaim palsu.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Pemulihan **tidak memakai `clear()`**; hanya kunci hasil `BackupScope` yang
  disentuh.
- Penerapan harus idempoten; **tidak boleh** ada langkah yang gagal bila
  dijalankan dua kali.
- Saldo dompet **tidak dipercaya dari cadangan**; `recomputeWalletBalances`
  dijalankan di finalisasi sebelum `done`.
- Tidak ada pemulihan sebagian atau penggabungan (ADR-024 §3.3).
- Teks notifikasi dan kotak masuk tangkapan tidak ikut cadangan.
- Tidak ada data keluar perangkat kecuali lewat lembar simpan atau bagikan yang
  dipilih pengguna; tidak ada panggilan jaringan di fitur ini.
- Nominal tetap `int` sen di cadangan; konversi ke satuan utama hanya di ekspor.

### Uji yang diwajibkan (memenuhi batasan EXPORT_BACKUP §10)

1. **Gangguan di tengah penggantian:** pembungkus `KeyValueStorage` yang
   melempar galat pada penulisan ke-N, dijalankan untuk **setiap N** dari 0
   sampai jumlah penulisan; sesudah bootstrap ulang hasilnya harus data lama
   utuh atau data cadangan utuh, tidak pernah campuran. Ditambah uji untuk
   tiap keadaan jurnal.
2. **Bolak-balik:** isi semua repositori dari fixture lengkap (transfer, pos
   anggaran, gajian maju, pembayaran freelance, kategori terarsip, periode
   peralihan, ikon sumber), cadangkan, pulihkan ke penyimpanan kosong, bandingkan
   seluruh dokumen **dan** nilai turunan (saldo, Arus, Rencana, Analisis, Rutin).
3. **Ekspor:** jumlah Arus per Awal periode sama dengan Arus aplikasi untuk
   periode yang sama, termasuk periode peralihan dan gajian maju; catatan
   berisi koma, kutip, dan baris baru; berkas xlsx dibuka di Excel dan Google
   Sheets.
4. **Penolakan:** berkas rusak, bukan cadangan, `formatVersion` lebih baru,
   `schemaVersion` dokumen lebih baru, rujukan tidak utuh, dan ruang penuh;
   dalam semua kasus data tidak berubah.
5. **Kelengkapan registri** (§3.3) dan **kelengkapan state global** `AppReboot`
   (§3.7).
6. `import_boundaries_test.dart` tetap lulus.

### Urutan kerja

T-22.1 sesudah Accepted: `BackupRegistry`, `BackupScope`, amplop, jurnal dan
pemulihan, `AppReboot`, `FileTransfer`, semuanya dengan uji (1)–(2), (4)–(6).
Lalu T-22.2 (ekspor, uji 3), T-22.3, T-22.4. Pemecahan `main()` dikerjakan
lebih dulu dengan uji yang membuktikan peluncuran biasa tidak berubah.

### Berkas dan paket yang terlibat

`lib/main.dart`, `lib/app/di/root_module.dart`, `lib/app/shell/account_version_entry.dart`
(pola baris Akun), `lib/shared/transaction/source_icons.dart`,
`lib/core/financial_month/`, `pubspec.yaml` (dependensi langsung baru),
`docs/03-release/PLAY_DATA_SAFETY.md` (dicek di T-22.6: berkas hanya
meninggalkan perangkat atas aksi pengguna).

### Kompatibilitas ke depan: akun, cadangan otomatis, sinkronisasi

ADR ini hanya menyiapkan yang murah dan tidak menyiapkan yang belum punya
rancangan.

**Cadangan otomatis ke Google Drive (B-51, Plus): hanya pengangkut baru.**
Amplop, `BackupScope`, registri, dan `StageRestore` dipakai ulang tanpa
perubahan. `StageRestore` menerima byte, jadi sumber berkas (pemilih berkas
atau unduhan Drive) cukup berupa adaptor baru di belakang `FileTransfer`.
`summary` ada agar daftar cadangan bisa ditampilkan tanpa membuka isinya.
Enkripsi menaikkan `formatVersion` (§3.2). Batasan untuk B-51:

- Cadangan otomatis **hanya membuat** cadangan. Pemulihan selalu atas ketukan
  pengguna, karena memicu `AppReboot` (§3.7).
- Penjadwal harian, lingkup OAuth Drive, enkripsi, dan rotasi adalah milik B-51.

**Akun:** tidak berubah. Akun tetap opsional dan data lokal milik perangkat
(ADR-024). Untuk B-51 akun hanya kunci akses ke Drive lewat Google Sign-In,
bukan pemilik data.

**Sinkronisasi (B-7): tidak disiapkan, sengaja.** Yang berguna darinya hanya
dua: registri kunci (daftar awal data yang kelak disinkronkan, dijaga uji
kelengkapan) dan aturan ADR-024 §3.3 (ganti akun = data diganti, tanpa
penggabungan) yang sudah dipenuhi mesin pemulihan. Sisanya tidak bisa dipakai
ulang: cadangan menyalin dokumen utuh, sedangkan sinkronisasi butuh perubahan
per transaksi dan resolusi konflik di atas penyimpanan yang kini satu dokumen
per bulan tanpa penanda perubahan. ADR B-7 menentukan lapisan datanya sendiri.

Dua risiko yang dicatat untuk saat B-7 dikerjakan:

1. **Cadangan lama harus tetap terbaca.** Bila tata letak penyimpanan berubah,
   `formatVersion` dan registri naik dan pemulihan cadangan lama wajib lolos;
   perlu uji kompatibilitas mundur.
2. **Sinkronisasi latar vs pemulihan.** Penerapan jurnal (§3.4) tidak boleh
   tertimpa penulisan sinkronisasi; sinkronisasi dijeda selama ada jurnal
   `applying` atau `applied`. Belum ada pelakunya, jadi belum ada mekanismenya.

## 8. Kriteria peninjauan ulang

- Uji gangguan T-22.7 #4 menunjukkan data campuran sekali pun: tinjau ulang
  seluruh §3.4.
- Hive berubah perilaku penulisan satu kunci (pembaruan `hive_ce`) atau
  penyimpanan berpindah dari Hive.
- Penulis OOXML sendiri gagal dibuka di Excel atau Sheets, atau melewati
  sekitar 300 baris: beralih ke paket `excel` (Opsi F).
- Hasil `Share` di Android tidak bisa membedakan simpan dan batal pada
  perangkat uji: tinjau aturan §3.5.
- B-51 (cadangan otomatis, terenkripsi) dimulai: naikkan `formatVersion` dan
  tentukan tempat sandi.
- Ukuran data pengguna membuat salinan pengaman dua kali ukuran data terasa
  berat.

## 9. Artefak terkait

### Dokumentasi

- [EXPORT_BACKUP.md](../../01-product/features/EXPORT_BACKUP.md): perilaku,
  aturan, teks, batasan §10.
- [ADR-001](0001-internal-package-dependency-strategy.md): paket internal
  `api_storage`/`hive_storage` yang di-pin.
- [ADR-002](0002-local-first-hive-document-storage.md): satu dokumen JSON
  berversi per kunci.
- [ADR-012](0012-tata-letak-penyimpanan-buku-besar.md): tata letak kunci,
  partisi bulanan, saldo di-cache dan `recomputeWalletBalances`.
- [ADR-024](0024-kepemilikan-data-lokal-dan-akun.md) §3.3: pemulihan mengganti
  tanpa penggabungan.
- [ADR-025](0025-satu-mata-uang-per-aplikasi.md): nominal `int` sen.
- [ADR-030](0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md): batas
  impor antarfitur dan akar komposisi.
- [ADR-039](0039-pengumuman-pembaruan-play-shorebird-dan-catatan.md): pola
  baris Akun yang disisipkan akar komposisi.
- [FINANCIAL_PERIOD.md](../../01-product/features/FINANCIAL_PERIOD.md):
  `periodDateOf` untuk kolom Awal periode.

### Rujukan kode

- `lib/main.dart`, `lib/app/di/root_module.dart` (bootstrap dan penyimpanan)
- `lib/shared/transaction/data/transaction_repository_impl.dart`
  (`recomputeWalletBalances`, partisi)
- `lib/shared/transaction/data/source_icon_repository_impl.dart` (`source_icon_<id>`)
- `lib/core/financial_month/` (jadwal dan `periodDateOf`)

---

**Penulis keputusan:** flutter-engineer (agen), usulan untuk pemilik
**Ditinjau oleh:** (menunggu pemilik)
**Tanggal disetujui:** (menunggu)
**Status implementasi:** Belum dimulai; fondasi T-22.1 menunggu Accepted
