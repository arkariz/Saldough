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

Resolusi memang gagal — lihat "Hasil sebenarnya" di bawah. Jalur pemulihan
yang dijalankan **bukan** melepas `resolution: workspace` seperti diduga di
bagian ini saat ADR ditulis, melainkan mendorong branch kompatibilitas di
`advance-mobile-platform` pada branch
`claude/saldough-flutter-finance-app-06ufsv` yang menyamakan URL paket
internal (GitLab privat → GitHub publik) di blok `dependencies:` setiap
paket, sambil **membiarkan `resolution: workspace` apa adanya** — baris itu
tetap diperlukan untuk pengelolaan monorepo lewat melos, bukan sumber
kegagalan yang sebenarnya. Branch `main` monorepo tidak disentuh.

### Hasil sebenarnya (10 September 2026)

`flutter pub get` gagal pada percobaan pertama, bukan karena
`resolution: workspace`, melainkan karena **setiap paket internal
mereferensikan paket sibling-nya lewat URL SSH GitLab privat di blok
`dependencies:`-nya sendiri** — bukan cuma di level Saldough. Pesan galat
asli:

```
Because every version of memory_storage from git depends on api_storage from git git@gitlab.bankcapital.co.id:mobile-services/mobile-platform.git at api_storage-v1.1.0 in infrastructure/storage/api_storage and saldough depends on api_storage from git https://github.com/arkariz/advance-mobile-platform at api_storage-v1.1.0 in infrastructure/storage/api_storage, memory_storage from git is forbidden.
```

Perbaikan dilakukan dalam dua commit di branch kompatibilitas:

1. **`275181ec7d43d423d5293ab676445a4e43a736ee`** — ganti URL
   `git@gitlab.bankcapital.co.id:mobile-services/mobile-platform.git` jadi
   `https://github.com/arkariz/advance-mobile-platform` di blok
   `dependencies:` setiap paket yang terkena (`api_storage`, `hive_storage`,
   `memory_storage`, `models`, `state_management`, plus beberapa
   `dev_dependencies:` yang tidak relevan untuk resolusi tapi diseragamkan
   juga). `resolution: workspace` tidak disentuh.
2. **`9b96fb4353f913270f72518198e598e900d6646c`** — commit pertama belum
   cukup: tag `api_storage-v1.1.0` yang dipakai `hive_storage` dan
   `memory_storage` untuk merujuk `api_storage` masih menunjuk commit LAMA
   (sebelum commit 1), yang isinya masih mereferensikan `failures` lewat
   GitLab. Jadi `hive_storage`/`memory_storage` dipin ulang ke commit 1
   (`275181e...`) lewat `ref:` SHA, bukan tag, khusus untuk rujukan
   `api_storage`-nya.

`failures` dan `dependencies` (sebagai paket) **tidak pernah rusak**: kedua
paket itu tidak punya dependensi internal apa pun di blok `dependencies:`
regulernya (cuma dependensi pihak ketiga atau tidak ada sama sekali), jadi
tag aslinya tetap valid dan tidak perlu dipindah. Begitu juga `di`,
`navigation`, dan `linter` — GitLab di paket-paket itu hanya muncul di
`dev_dependencies:` (tidak ditarik pub untuk dependensi transitif), jadi
tidak pernah memengaruhi resolusi Saldough sama sekali.

Dengan perbaikan ini, `flutter pub get` **berhasil** sungguhan lewat jaringan
nyata ke GitHub (bukan simulasi lokal): "Got dependencies!" tanpa galat, dan
`flutter analyze` (dengan `include: package:linter/analysis_options.yaml`)
melaporkan "No issues found!".

Tabel tag diganti tabel pin aktual di bawah, per paket.

| Paket | Pin yang dipakai Saldough | Kenapa |
|---|---|---|
| `state_management` | SHA `275181e` | Rujukan internalnya ke `dependencies` butuh URL terbaru |
| `navigation` | Tag `navigation-v1.1.1` | Tidak punya dependensi internal, tag asli valid |
| `failures` | Tag `failures-v2.0.2` | Tidak punya dependensi internal, tag asli valid |
| `models` | SHA `275181e` | Rujukan internalnya ke `dependencies` butuh URL terbaru |
| `api_storage` | SHA `275181e` | Rujukan internalnya ke `failures` butuh URL terbaru |
| `hive_storage` | SHA `9b96fb4` | Butuh commit 1 (URL) **dan** commit 2 (ref `api_storage` ke SHA, bukan tag lama) |
| `di` | Tag `di-v1.1.2` | Tidak punya dependensi internal, tag asli valid |
| `dependencies` | Tag `dependencies-v1.4.0` | Tidak punya dependensi internal sama sekali |
| `linter` | Tag `linter-v1.0.2` | Tidak punya dependensi internal, tag asli valid |
| `memory_storage` | SHA `9b96fb4` | Sama seperti `hive_storage` — rujukan ke `api_storage` |

SHA lengkap: `275181ec7d43d423d5293ab676445a4e43a736ee` (commit 1, perbaikan
URL) dan `9b96fb4353f913270f72518198e598e900d6646c` (commit 2, perbaikan
ref `api_storage` di `hive_storage`/`memory_storage`).

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

**Catatan 10 September 2026:** langkah 2 di bawah ini SALAH DIDUGA saat ADR
ditulis — lihat "Hasil sebenarnya" di bagian 3 untuk apa yang benar-benar
dikerjakan (ganti URL GitLab→GitHub per paket, **bukan** hapus
`resolution: workspace`). Daftar ini dibiarkan apa adanya sebagai jejak,
tidak diedit diam-diam.

1. Catat pesan galat `flutter pub get` apa adanya di `TASK_LIST.md`.
2. ~~Di `advance-mobile-platform`, pada branch
   `claude/saldough-flutter-finance-app-06ufsv`, hapus baris
   `resolution: workspace` hanya pada paket yang dikonsumsi Saldough.~~
   Ternyata tidak perlu — akar masalahnya bukan baris itu.
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
**Status implementasi:** Diverifikasi 10 September 2026 — `flutter pub get`
dan `flutter analyze` berhasil bersih setelah jalur pemulihan dijalankan
(lihat "Hasil sebenarnya" di bagian 3).
