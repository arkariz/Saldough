# Navigasi lewat registri rute bertipe

## 1. Metadata

- **Decision ID:** ADR-004
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Saldough butuh navigasi antar fitur yang saling terkait erat. Layar siklus
bulanan membuka rincian baris, rincian buku jam, rincian siklus tagihan kartu,
dan rincian pos tujuan. Sebagian besar perpindahan itu membawa argumen, misalnya
identitas siklus atau identitas kartu.

Repositori referensi arsitektur, `new-health-duel`, memakai `go_router` langsung
dengan konstanta string di kelas `AppRoutes`, ditambah fungsi pembentuk jalur
seperti `duelPath(String id)`. Argumen dikirim sebagai bagian jalur.

Pemilik meminta paket internal `navigation` dipakai. Paket itu menyediakan
lapisan yang tidak bergantung pada vendor router: `RouteKey<TInput>`,
`RouteInput`, `RouteNode`, `FeatureRouteModule`, dan `RouteRegistry`.
`go_router` tetap dipakai, tetapi dijembatani di lapisan aplikasi lewat
`RouteNode.toGoRoute()`.

Paket `state_management` mengirim efek navigasi memakai `keyId` bertipe
`String`, bukan objek `RouteKey`. Ini sengaja, supaya paket state tidak
bergantung pada paket navigasi. Konsekuensinya, ada satu titik di mana keamanan
tipe hilang dan harus dijaga dengan konvensi.

## 3. Keputusan

Saldough memakai `package:navigation` versi 1.1.1 di atas `go_router`.

Setiap fitur mendeklarasikan kunci rutenya dalam satu berkas
`<fitur>_route_keys.dart`, dan modul rutenya dalam
`<fitur>_route_module.dart`. Seluruh modul dikumpulkan oleh satu
`RouteRegistry` di lapisan aplikasi, lalu diubah menjadi daftar `GoRoute`.

Argumen rute dikirim sebagai objek `RouteInput` bertipe lewat `extra`, bukan
sebagai bagian jalur.

Aturan impor antar fitur bersifat mengikat: fitur lain hanya boleh mengimpor
`<fitur>_route_keys.dart`. Hanya `<fitur>_route_module.dart` yang boleh
mengimpor widget halamannya. Aturan ini menjaga fitur tetap terpisah, karena
mengimpor kunci rute tidak menarik seluruh pohon widget fitur lain.

Navigasi yang dipicu logika dikirim sebagai efek dari bloc, bukan dipanggil
langsung dari widget.

## 4. Opsi yang dipertimbangkan

- **Opsi A — `go_router` langsung dengan konstanta string, seperti
  `new-health-duel`**
- **Opsi B — `package:navigation` di atas `go_router` (Dipilih)**
- **Opsi C — `Navigator` bawaan Flutter**

## 5. Analisis konsekuensi

### Opsi A — `go_router` langsung dengan konstanta string

Paling sedikit lapisan dan paling mudah dipahami. Persis seperti repositori
referensi arsitektur, sehingga menyalin polanya tidak butuh penyesuaian.

Tetapi argumen rute menjadi string tanpa tipe, dan fitur yang saling
menavigasi harus mengimpor konstanta dari berkas global bersama. Pemilik juga
secara eksplisit meminta paket `navigation` dipakai. Menolaknya berarti satu
lagi paket internal menganggur, setelah `api_network` dan `dio_network` sudah
ditunda.

### Opsi B — `package:navigation` di atas `go_router` (Dipilih)

Argumen rute bertipe lewat `RouteInput`, sehingga salah kirim argumen ketahuan
saat kompilasi, bukan saat runtime. Setiap fitur memiliki modul rutenya sendiri,
sehingga menambah fitur tidak menyentuh berkas rute global selain satu baris
pendaftaran.

Paket ini juga membawa `DevMenuScreen`, layar navigasi cepat yang hanya muncul
pada mode debug. Untuk aplikasi dengan banyak layar dalam seperti Saldough, ini
mempercepat pengujian manual secara nyata.

Kelemahannya ada tiga. Pertama, satu lapisan tambahan yang harus dipahami.
Kedua, jalur rute berbentuk `/<keyId>`, misalnya `/cycle.detail`, sehingga
tautan dalam tidak bisa membawa argumen kecuali `defaultInput` didaftarkan.
Ketiga, efek navigasi memakai `keyId` bertipe `String`, sehingga keamanan tipe
terputus tepat di titik itu.

### Opsi C — `Navigator` bawaan Flutter

Tanpa dependensi tambahan, tetapi menuntut penanganan tumpukan halaman secara
manual dan tidak punya jalur menuju tautan dalam. Tidak sepadan untuk aplikasi
dengan sebanyak ini layar.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Argumen rute bertipe, sehingga kesalahan tertangkap saat kompilasi.
- Menambah fitur cukup menambah satu modul rute dan satu baris pendaftaran.
- Menguji layar dalam lewat menu pengembang pada mode debug.

### Yang menjadi lebih sulit

- Satu lapisan abstraksi tambahan di atas `go_router`.
- Tautan dalam berargumen butuh `defaultInput` terdaftar pada simpulnya.
- Titik `keyId` bertipe `String` pada efek navigasi harus dijaga konvensi.

### Risiko yang diterima

- Salah ketik `keyId` di efek navigasi baru ketahuan saat runtime. Ditangani
  dengan aturan selalu memakai konstanta kunci rute, misalnya
  `CycleRouteKeys.detail.id`, tidak pernah string harfiah.
- Dokumentasi paket `navigation` menyebut `TypedNavigateGoEffect` dan
  `AppNavService` yang tidak ada di kode. Nama sebenarnya adalah
  `NavigateGoEffect`, `NavigatePushEffect`, `NavigateReplaceEffect`, dan
  `NavigatePopEffect`. Implementasi mengikuti kode.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Kunci rute memakai format `<fitur>.<layar>`, misalnya `cycle.detail` dan
  `card.statement`.
- Setiap simpul rute yang bisa dibuka dari tautan dalam wajib mendaftarkan
  `defaultInput`. Tanpa itu, membuka rute tanpa `extra` melempar `StateError`.
- Penangan efek navigasi didaftarkan sekali saat aplikasi dimulai, mengikuti
  pola `registerNavEffectHandlers(globalEffectRegistry, router: router)`.
- Ketergantungan lingkup fitur diambil sebelum `ScopeWidget` disisipkan.
  Di dalam pembangun simpul rute, panggil `ScopeProvider.of(context)` lebih dulu
  lalu berikan hasilnya ke `create`, karena `ScopeProvider` belum ada di pohon
  saat `create` dijalankan.

### Antipola yang harus dihindari

- Mengimpor berkas halaman fitur lain. Impor hanya kunci rutenya.
- Menulis `keyId` sebagai string harfiah di efek navigasi.
- Memanggil `context.go` atau `context.push` langsung untuk alur yang dipicu
  logika bloc.
- Mengirim argumen lewat jalur atau parameter kueri. Pakai `RouteInput`.

## 8. Kriteria peninjauan ulang

- Tautan dalam dari luar aplikasi menjadi kebutuhan, sehingga jalur `/<keyId>`
  tidak lagi memadai.
- Navigasi bercabang dengan bilah bawah dibutuhkan, karena paket ini belum
  memakai `StatefulShellRoute` di mana pun.
- Paket `navigation` tidak lagi dipelihara.

## 9. Artefak terkait

### Dokumentasi

- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian struktur fitur.
- [ADR-0003](0003-effect-bloc-state-management.md) untuk efek navigasi.

### Rujukan kode

- `advance-mobile-platform/fondation/navigation/lib/`
- `advance-mobile-platform/app_example/lib/core/navigation/app_route_registry.dart`
- `advance-mobile-platform/app_example/lib/core/navigation/route_node_go_router_ext.dart`

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
