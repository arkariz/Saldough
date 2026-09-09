# Strategi dependensi paket internal

## 1. Metadata

- **Decision ID:** ADR-001
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 0
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Saldough harus memakai paket internal dari monorepo
`arkariz/advance-mobile-platform`, yaitu `state_management`, `navigation`,
`failures`, `models`, `api_storage`, `hive_storage`, dan `di`. Saldough adalah
repositori terpisah, sehingga paket-paket itu harus dikonsumsi sebagai
dependensi eksternal.

Tiga fakta dari pemeriksaan repositori membentuk konteks keputusan ini.

Pertama, setiap `pubspec.yaml` di dalam monorepo menunjuk URL SSH GitLab privat
`git@gitlab.bankcapital.co.id:mobile-services/mobile-platform.git`. URL itu tidak
bisa diakses dari lingkungan pengembangan Saldough.

Kedua, salinan publik tersedia di `https://github.com/arkariz/advance-mobile-platform`
dan bisa dibaca tanpa autentikasi. Repositori itu punya tag git lengkap per
paket dengan format `<nama>-v<versi>`, dan versinya cocok dengan yang tercatat di
`app_example`.

Ketiga, dan ini yang paling berisiko, **setiap pubspec paket menyatakan
`resolution: workspace`**. Deklarasi itu menandai paket sebagai anggota pub
workspace. Paket semacam ini dirancang untuk di-resolve bersama pubspec akar
monorepo, bukan berdiri sendiri sebagai dependensi git dari repositori luar.
Apakah `pub` menerima atau menolaknya belum bisa dipastikan tanpa menjalankan
`flutter pub get`, dan Flutter SDK belum terpasang saat keputusan ini diambil.

## 3. Keputusan

Saldough mengonsumsi paket internal sebagai dependensi git dari
`https://github.com/arkariz/advance-mobile-platform`, dipin ke tag versi per
paket.

Karena risiko `resolution: workspace` belum terbukti aman, resolusi dependensi
dijadikan **gerbang Fase 0**. Tidak ada pekerjaan fase berikutnya yang dimulai
sebelum `flutter pub get` berhasil.

Kalau resolusi gagal, jalur pemulihan yang disetujui pemilik adalah mendorong
branch kompatibilitas di `advance-mobile-platform` pada branch
`claude/saldough-flutter-finance-app-06ufsv`, yang melepas baris
`resolution: workspace` pada paket yang dipakai. Saldough lalu dipin ke commit
SHA branch itu. Branch `main` monorepo tidak disentuh.

Versi yang dipakai, terverifikasi lewat `git ls-remote --tags` pada
9 September 2026:

| Paket | Tag | Dipakai untuk |
|---|---|---|
| `state_management` | `state_management-v2.2.0` | Bloc, state, dan efek |
| `navigation` | `navigation-v1.1.1` | Registri rute bertipe |
| `failures` | `failures-v2.0.2` | Hierarki kesalahan |
| `models` | `models-v1.1.3` | Struktur data bersama |
| `api_storage` | `api_storage-v1.1.0` | Kontrak penyimpanan |
| `hive_storage` | `hive_storage-v1.1.1` | Implementasi Hive |
| `di` | `di-v1.1.2` | Injeksi dependensi |
| `dependencies` | `dependencies-v1.4.0` | Penguncian versi pihak ketiga |
| `linter` | `linter-v1.0.2` | Aturan lint bersama |
| `memory_storage` | `memory_storage-v1.1.1` | Test double, dev dependency |

Paket `api_network` dan `dio_network` **tidak dipakai** pada MVP, karena tidak
ada backend. Keduanya baru masuk pada tahap sinkronisasi.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Dependensi path ke folder sibling**
- **Opsi B — Menyalin kode paket ke dalam Saldough**
- **Opsi C — Dependensi git ke GitHub publik, dipin per tag (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Dependensi path ke folder sibling

Saldough merujuk `../advance-mobile-platform` lewat `path:`. Paling cepat
disiapkan dan otomatis lolos dari masalah `resolution: workspace`, karena pub
memperlakukan paket sebagai bagian dari checkout lokal.

Kelemahannya berat. Saldough tidak lagi berdiri sendiri: siapa pun yang
mengklonnya harus juga mengklon monorepo di posisi folder yang tepat. Integrasi
berkelanjutan menjadi rumit, dan versi paket tidak terkunci sehingga perubahan
di monorepo bisa merusak Saldough tanpa jejak.

### Opsi B — Menyalin kode paket ke dalam Saldough

Menyalin kode sumber paket ke `lib/core/` menghapus seluruh masalah resolusi.
Saldough sepenuhnya mandiri dan bisa dibangun siapa saja.

Namun ini membuang alasan utama memakai paket internal. Perbaikan bug di
monorepo tidak mengalir ke Saldough, dan dua salinan kode yang sama akan
menyimpang seiring waktu. Pemilik secara eksplisit meminta paket internal
dipakai, bukan ditiru.

### Opsi C — Dependensi git ke GitHub publik, dipin per tag (Dipilih)

Saldough berdiri sendiri, versi paket terkunci pada tag sehingga pembangunan
bisa diulang, dan perbaikan di monorepo bisa diambil dengan menaikkan tag secara
sadar. Pendekatan ini juga sejalan dengan cara `new-health-duel` mengonsumsi
paket intinya, sehingga konvensinya konsisten antar proyek.

Kelemahannya adalah risiko `resolution: workspace` yang belum terbukti, dan
ketergantungan pada repositori GitHub tetap publik. Risiko pertama ditangani
lewat gerbang Fase 0 beserta jalur pemulihannya. Risiko kedua diterima, karena
kedua repositori dimiliki orang yang sama.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Saldough bisa diklon dan dibangun tanpa menyiapkan repositori lain.
- Versi paket terlihat jelas di `pubspec.yaml` dan terkunci.
- Perbaikan di monorepo bisa diambil dengan satu perubahan tag.

### Yang menjadi lebih sulit

- Menaikkan versi paket butuh tag baru di monorepo terlebih dahulu.
- Mengembangkan paket dan aplikasi bersamaan butuh `dependency_overrides`
  sementara.

### Risiko yang diterima

- Resolusi bisa gagal karena `resolution: workspace`. Ditangani sebagai gerbang
  Fase 0 dengan jalur pemulihan yang sudah disetujui.
- Dokumentasi di monorepo diketahui tidak sinkron dengan kodenya di beberapa
  tempat. Implementasi harus mengikuti kode, bukan README.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Ganti URL SSH GitLab menjadi `https://github.com/arkariz/advance-mobile-platform`
  di seluruh dependensi.
- Jangan menyalin `resolution: workspace` ke `pubspec.yaml` Saldough. Deklarasi
  itu hanya berlaku untuk anggota workspace.
- Pin setiap paket ke tag, bukan ke branch, kecuali jalur pemulihan dipakai.

### Antipola yang harus dihindari

- Mengubah `main` di `advance-mobile-platform`. Kalau perlu perubahan, pakai
  branch `claude/saldough-flutter-finance-app-06ufsv`.
- Memakai `any` sebagai batasan versi paket internal.
- Mengikuti README paket. Beberapa README menunjukkan API yang sudah tidak ada,
  misalnya `HiveStorageInitializer` dan konstruktor publik
  `HiveKeyValueStorage(box:)`, yang di versi 1.1.1 sudah diganti
  `HiveKeyValueStorage.initialize(boxName:)`.

### Kalau jalur pemulihan dipakai

1. Catat pesan galat `flutter pub get` apa adanya di `TASK_LIST.md`.
2. Di `advance-mobile-platform`, pada branch
   `claude/saldough-flutter-finance-app-06ufsv`, hapus baris
   `resolution: workspace` hanya pada paket yang dikonsumsi Saldough.
3. Dorong branch itu, lalu pin dependensi Saldough ke commit SHA-nya.
4. Perbarui ADR ini dengan hasil sebenarnya, dan ganti tabel tag di atas menjadi
   tabel SHA.

## 8. Kriteria peninjauan ulang

- `flutter pub get` gagal, sehingga jalur pemulihan harus dijalankan.
- Monorepo dipindahkan atau dijadikan privat.
- Tahap sinkronisasi dimulai, sehingga `api_network` dan `dio_network` perlu
  ditambahkan.
- Paket internal mulai diterbitkan ke pub.dev, sehingga dependensi git tidak
  lagi diperlukan.

## 9. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) memuat `pubspec.yaml`
  lengkap.
- [TASK_LIST.md](../../04-planning/TASK_LIST.md) Fase 0 memuat langkah
  verifikasinya.
- PRD bagian 11 mencatat risiko ini.

### Rujukan kode

- `advance-mobile-platform/app_example/pubspec.yaml` sebagai acuan bentuk
  deklarasi dependensi.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, verifikasi menunggu Fase 0
