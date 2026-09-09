# Penyimpanan lokal berbasis dokumen dengan Hive

## 1. Metadata

- **Decision ID:** ADR-002
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

MVP Saldough tidak punya backend. Seluruh data tersimpan di perangkat, dan
aplikasi harus berfungsi penuh tanpa koneksi. Sinkronisasi ke Firebase atau
Google Drive direncanakan pada tahap berikutnya, sehingga model penyimpanan hari
ini tidak boleh menutup jalan ke sana.

Paket internal menyediakan `api_storage` sebagai kontrak dan `hive_storage`
sebagai implementasinya. Keduanya menyediakan penyimpanan kunci-nilai berbasis
string, bukan basis data relasional. `StoredValue<T>` membungkus baca dan tulis
satu nilai dengan serialisasi JSON.

Bentuk data Saldough perlu diperiksa sebelum memilih. Data keuangan pemilik
secara alami berbentuk dokumen: satu blok tabel per bulan, satu daftar belanja,
satu blok transaksi per siklus tagihan. Tidak ada relasi banyak-ke-banyak, dan
tidak ada kueri gabungan yang rumit. Volumenya juga kecil. Data historis
sepuluh bulan menghasilkan sekitar sepuluh dokumen siklus, masing-masing berisi
belasan sampai dua puluhan baris, ditambah beberapa ratus transaksi kartu dan
catatan jam kerja.

Kebutuhan yang harus dilayani sekarang hanya membuka satu bulan, menyunting
isinya, dan menghitung nilai turunan. Laporan tren tahunan berada di luar MVP.

## 3. Keputusan

Saldough menyimpan data sebagai dokumen JSON di Hive, lewat `package:api_storage`
dan `package:hive_storage`.

Satu siklus bulanan disimpan sebagai satu dokumen dengan kunci berisi
identitasnya, misalnya `cycle_2026-09`. Data lintas bulan seperti sumber
pemasukan, pos tujuan, kartu, dan rencana belanja disimpan sebagai dokumen
tersendiri. Daftar bervolume lebih besar seperti catatan jam kerja dan transaksi
kartu disimpan per periode induknya, bukan sebagai satu dokumen raksasa.

Seluruh akses data melewati antarmuka repository yang didefinisikan di lapisan
domain. Tidak ada satu pun kelas di luar lapisan data yang boleh mengetahui
bahwa Hive dipakai.

Agregasi lintas bulan dilakukan di memori. Dengan volume yang ada, memuat
seluruh dokumen siklus dan menjumlahkannya jauh lebih murah daripada biaya
memelihara basis data relasional.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Drift atau SQLite**
- **Opsi B — Hive lewat paket internal, satu dokumen per agregat (Dipilih)**
- **Opsi C — Berkas JSON biasa di direktori dokumen aplikasi**

## 5. Analisis konsekuensi

### Opsi A — Drift atau SQLite

Relasional penuh. Kueri agregat lintas bulan menjadi murah, migrasi skema punya
alur yang mapan, dan aplikasi siap untuk laporan tahunan tanpa perubahan
arsitektur.

Namun opsi ini menyimpang dari paket penyimpanan internal yang diminta pemilik.
Ia juga menambah pembangkitan kode Drift, menuntut migrasi skema ditulis manual
sejak awal, dan memaksa model domain yang berbentuk dokumen dipecah menjadi
tabel lalu disusun ulang saat dibaca. Untuk sepuluh dokumen per tahun, biaya itu
tidak sebanding.

### Opsi B — Hive lewat paket internal, satu dokumen per agregat (Dipilih)

Memakai paket yang memang diminta, dan bentuk penyimpanannya sama dengan bentuk
domainnya. Satu siklus bulanan dibaca dan ditulis sebagai satu kesatuan, persis
seperti satu blok tabel di spreadsheet. Serialisasi JSON juga memudahkan langkah
sinkronisasi nanti, karena dokumen JSON bisa langsung dipetakan ke dokumen
Firestore atau berkas di Drive.

Kelemahannya nyata dan diterima. Kueri lintas bulan harus memuat seluruh dokumen
ke memori. Tidak ada indeks, tidak ada kueri parsial, dan tidak ada jaminan
transaksional antar dokumen. Batas kenyamanan pendekatan ini kira-kira beberapa
ribu transaksi; di atas itu, memuat semuanya mulai terasa.

### Opsi C — Berkas JSON biasa di direktori dokumen aplikasi

Paling sederhana dan tanpa dependensi tambahan. Tetapi harus menangani sendiri
penulisan atomik, penguncian, dan pemulihan berkas rusak. Hive sudah
menyelesaikan semua itu, dan paket internal sudah membungkusnya.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Membaca dan menyimpan satu bulan sebagai satu kesatuan.
- Memetakan dokumen ke penyimpanan awan pada tahap sinkronisasi.
- Menguji lapisan data memakai `memory_storage` tanpa menyentuh berkas.

### Yang menjadi lebih sulit

- Kueri agregat lintas bulan harus ditulis sebagai kode Dart di memori.
- Perubahan bentuk dokumen menuntut migrasi yang ditulis sendiri.
- Tidak ada penulisan transaksional yang mencakup beberapa dokumen sekaligus.

### Risiko yang diterima

- Kinerja menurun kalau volume data tumbuh jauh melampaui perkiraan. Ditangani
  dengan menyembunyikan penyimpanan di balik antarmuka repository, sehingga
  penggantian ke Drift tidak menyentuh domain maupun presentasi.
- Dokumen yang gagal ditulis sebagian bisa membuat siklus tidak konsisten.
  Ditangani dengan menulis satu agregat dalam satu operasi.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Antarmuka repository didefinisikan di `domain/repositories/`, implementasinya
  di `data/repositories/`. Domain tidak mengimpor Hive maupun `api_storage`.
- Setiap dokumen menyertakan field `schemaVersion` bertipe `int`, supaya migrasi
  bisa dikenali. Ini memenuhi NFR-REL-003.
- Kunci penyimpanan memakai `StorageKey(namespace:, name:)` supaya penamaannya
  konsisten, misalnya namespace `cycle` dengan nama `2026-09`.
- Nominal diserialisasi sebagai bilangan bulat satuan sen, sesuai
  [ADR-0008](0008-monthly-cycle-template-and-rollup.md) dan
  [DOMAIN_MODEL.md](../DOMAIN_MODEL.md). Jangan pernah menulis nominal sebagai
  `double` ke JSON.

### Pola yang diikuti

- Inisialisasi memakai `HiveKeyValueStorage.initialize(boxName:)`. Konstruktor
  publiknya privat pada versi 1.1.1, dan `HiveStorageInitializer` yang disebut
  README sudah tidak ada.
- Data sensitif, kalau nanti ada, memakai `HiveSecureStorage.initialize()`.
  Pada MVP tidak ada kredensial yang disimpan.

### Antipola yang harus dihindari

- Menyimpan seluruh riwayat sebagai satu dokumen besar.
- Membocorkan tipe Hive ke tanda tangan fungsi di luar lapisan data.
- Membaca seluruh dokumen hanya untuk menampilkan satu bulan.

## 8. Kriteria peninjauan ulang

- Jumlah transaksi melewati beberapa ribu, atau memuat riwayat terasa lambat.
- Laporan tren tahunan masuk cakupan, sehingga kueri agregat menjadi rutin.
- Tahap sinkronisasi menuntut penyelesaian konflik pada tingkat baris, bukan
  tingkat dokumen.

## 9. Artefak terkait

### Dokumentasi

- [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) untuk bentuk agregat.
- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) untuk letak lapisan.
- PRD NFR-REL-001 sampai NFR-REL-003.

### Rujukan kode

- `advance-mobile-platform/infrastructure/storage/api_storage`
- `advance-mobile-platform/infrastructure/storage/hive_storage`
- `advance-mobile-platform/app_example/lib/core/storage/app_storage.dart`

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
