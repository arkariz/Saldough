# State management berbasis bloc dengan efek terdaftar

## 1. Metadata

- **Decision ID:** ADR-003
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Pemilik meminta dua hal yang semula tampak bisa digabung: memakai paket internal
`state_management` dari `advance-mobile-platform`, dan mengikuti arsitektur
`flutter-architecture-studi` pada folder `lib/v2`.

Pemeriksaan repositori menunjukkan dua premis itu tidak bisa dipenuhi bersamaan.
Folder `lib/v2` tidak ada; yang ada `lib/app`, dan seluruhnya memakai Riverpod
dengan `@riverpod` Notifier. Paket `state_management` memakai `flutter_bloc`.
Memakai keduanya berarti menjalankan dua mesin state di satu aplikasi.

Pemilik kemudian mengganti referensi arsitektur menjadi `new-health-duel`, yang
memakai bloc. Proyek itu punya sistem efek sendiri bernama EffectBloc di
`lib/core/bloc/`, ditulis lokal di dalam aplikasinya.

Sistem efek itu ternyata sangat mirip dengan yang sudah disediakan
`package:state_management` versi 2.2.0: `UiState<T>`, `UiEffect`,
`EffectRegistry`, dan `EffectListener<B, S>`. Menyalin versi lokal
`new-health-duel` berarti memelihara duplikat dari sesuatu yang sudah ada
sebagai paket.

Aplikasi ini juga punya kebutuhan efek yang nyata: setelah menutup buku jam,
antarmuka harus berpindah halaman dan menampilkan pesan; setelah menyimpan
alokasi yang tidak genap 100 persen, antarmuka harus memperingatkan tanpa
menghalangi penyimpanan.

> **Catatan validasi (2026-09-10):** Referensi arsitektur Saldough kemudian
> berganti lagi, dari `new-health-duel` ke `flutter-architecture-studi-bank`
> (`lib/v2`) — lihat [ADR-0009](0009-core-shared-features-zone-layout.md).
> Repo itu memakai `package:state_management` yang identik (versi tag sama)
> secara produksi, lengkap dengan pola `BlocContext<T>` untuk state internal
> bloc yang tidak dirender (terpisah dari `UiState` yang dirender) — keputusan
> di bawah ini tidak berubah, hanya makin terbukti benar.

## 3. Keputusan

Saldough memakai `package:state_management` versi 2.2.0 sebagai satu-satunya
mesin state. Sistem EffectBloc lokal milik `new-health-duel` tidak disalin.

Setiap state fitur memperluas `UiState<T>`. Aksi sekali jalan dikirim sebagai
`UiEffect`, ditangani lewat `EffectRegistry`, dan dijembatani ke antarmuka oleh
`EffectListener<B, S>`.

Riverpod tidak dipakai di mana pun.

Tiga hal berikut wajib dipahami sebelum menulis bloc pertama, karena menentukan
apakah efek berjalan benar:

- `UiState` mengecualikan `effect` dari `props`, tetapi menyertakannya di
  `operator ==`. Akibatnya `BlocBuilder` tidak membangun ulang hanya karena efek
  berubah, sementara `emit` tetap terpicu.
- Setiap `UiEffect` membawa cap waktu mikrodetik, sehingga dua efek sejenis
  yang dikirim berurutan tetap dianggap berbeda dan keduanya tereksekusi.
- `EffectRegistry.register` menegaskan satu tipe efek hanya boleh didaftarkan
  sekali, dan efek yang belum terdaftar melempar `UnregisteredEffectError`.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Riverpod, mengikuti `flutter-architecture-studi`**
- **Opsi B — Menyalin EffectBloc lokal dari `new-health-duel`**
- **Opsi C — `package:state_management` dari paket internal (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Riverpod, mengikuti `flutter-architecture-studi`

Repositori itu punya pola yang matang: `BaseState` dengan `StateStatus`,
`SideEffect` yang mengeksekusi dirinya sendiri, dan `SideEffectMixin` yang
menangani deduplikasi lewat perbandingan id.

Tetapi memilihnya berarti membuang paket `state_management` dan `navigation`
yang diminta pemilik, lalu menulis ulang kelas dasarnya di dalam Saldough. Dua
paket internal langsung menjadi tidak terpakai. Selain itu, repositori acuannya
memakai paket data dari organisasi GitLab privat yang tidak bisa diakses,
sehingga polanya tidak bisa disalin utuh.

### Opsi B — Menyalin EffectBloc lokal dari `new-health-duel`

Menjaga kemiripan maksimal dengan repositori referensi arsitektur. Kodenya
terbukti jalan di aplikasi nyata.

Namun ini menduplikasi paket internal yang fungsinya sama. Perbaikan bug di
`state_management` tidak akan mengalir ke Saldough, dan dua implementasi konsep
yang sama akan menyimpang. Paket versi 2.2.0 bahkan sudah punya `CallbackEffect`
yang belum ada di salinan lokal.

### Opsi C — `package:state_management` dari paket internal (Dipilih)

Memenuhi permintaan pemilik memakai paket internal, sekaligus mempertahankan
pola arsitektur `new-health-duel` karena konsepnya identik. Perbedaannya hanya
di asal kelas dasarnya, bukan di cara fitur ditulis.

Paket ini juga menyediakan efek siap pakai yang cocok dengan kebutuhan Saldough:
`ShowSnackBarEffect` dengan tingkat keparahan, `ShowDialogEffect` dengan aksi
terkonfigurasi, `CallbackEffect`, serta empat efek navigasi.

Kelemahannya, dokumentasi paket ini diketahui tidak sinkron dengan kodenya.
README menampilkan `NavigateGoEffect(route: 'home')` padahal konstruktor
sebenarnya `NavigateGoEffect({required String keyId, required Object input})`,
dan menampilkan `const AppBlocObserver()` padahal kelas itu tidak `const`.
Implementasi harus mengikuti kode.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Efek navigasi, snackbar, dan dialog tersedia tanpa menulis kelas dasar.
- Perbaikan dan penambahan di paket bisa diambil dengan menaikkan tag.
- Pola fitur tetap sama dengan `new-health-duel`, sehingga referensinya masih
  relevan saat menulis kode.

### Yang menjadi lebih sulit

- Perilaku `UiState` yang memisahkan `props` dan `operator ==` tidak lazim dan
  harus dijelaskan ke siapa pun yang baru masuk.
- Menambah tipe efek baru menuntut pendaftaran di registri, dan lupa
  mendaftarkan baru ketahuan saat runtime.

### Risiko yang diterima

- Bergantung pada paket eksternal untuk mekanisme paling inti aplikasi. Diterima
  karena paket dan aplikasi dimiliki orang yang sama, dan
  [ADR-0001](0001-internal-package-dependency-strategy.md) sudah mengunci
  versinya.
- README paket menyesatkan. Diterima dengan aturan tegas: ikuti kode, bukan
  dokumentasi paket.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Setiap state fitur memperluas `UiState<T>` dan mengimplementasikan `copyWith`
  yang menerima `UiEffect?`.
- Field yang memengaruhi tampilan masuk `props`. `effect` tidak pernah masuk
  `props`.
- Efek navigasi memakai `keyId` bertipe `String`, bukan objek `RouteKey`. Ini
  disengaja oleh paket agar `state_management` tidak bergantung pada
  `navigation`. Ambil nilainya dari konstanta kunci rute fitur, misalnya
  `CycleRouteKeys.detail.id`.
- Efek fitur ditulis sebagai `extension` di berkas `part`, mengikuti pola
  `auth_side_effect.dart` di `app_example`, supaya berkas bloc tetap ringkas.
- Seluruh penangan efek didaftarkan sekali saat aplikasi dimulai, sebelum
  `runApp`.

### Antipola yang harus dihindari

- Memakai Riverpod, Provider, atau GetX di mana pun.
- Menyalin kelas dasar EffectBloc dari `new-health-duel`.
- Memasukkan `effect` ke dalam `props`, karena membuat antarmuka membangun ulang
  tanpa perlu.
- Memanggil navigasi langsung dari widget untuk alur yang dipicu bloc.
  Navigasi yang berasal dari logika berjalan lewat efek.

## 8. Kriteria peninjauan ulang

- Paket `state_management` tidak lagi dipelihara.
- Kebutuhan state melampaui yang bisa dilayani bloc, misalnya kolaborasi
  waktu nyata pada tahap sinkronisasi.
- Pemilik memutuskan menyatukan tumpukan teknologi dengan proyek lain yang
  memakai Riverpod.

## 9. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian struktur fitur.
- [ADR-0004](0004-typed-route-registry-navigation.md) untuk efek navigasi.
- [ADR-0005](0005-either-failure-convention.md) untuk penanganan kesalahan
  di dalam bloc.
- [ADR-0009](0009-core-shared-features-zone-layout.md) untuk struktur folder
  yang divalidasi bersamaan dengan temuan ini.

### Rujukan kode

- `flutter-architecture-studi-bank`, `lib/v2/features/auth/landing/presentation/bloc/`
  — `UiState`/`UiEffect`/`BlocContext` dipakai persis sama di produksi,
  termasuk pola `emit(state.withEffect(...))`.
- `advance-mobile-platform/fondation/state_management/lib/src/base/state/ui_state.dart`
- `advance-mobile-platform/fondation/state_management/lib/src/effect/`
- `advance-mobile-platform/app_example/lib/features/auth/presentation/bloc/`

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
