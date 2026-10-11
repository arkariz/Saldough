# Pengumuman pembaruan: Play In-App Updates fleksibel, keadaan Shorebird, dan catatan di dalam kode

## 1. Metadata

- **Decision ID:** ADR-039
- **Tanggal:** 2026-10-11
- **Fase roadmap:** Fase 20
- **Status:** Proposed
- **Cakupan:** Fitur: pengumuman pembaruan
  ([APP_UPDATE.md](../../01-product/features/APP_UPDATE.md))

## 2. Konteks

Tanukonomy diperbarui lewat dua jalan: rilis baru di Play Store (closed
testing, build `0.5.0+6` saat ini) dan tambalan Shorebird (`shorebird.yaml`,
`auto_update` bawaan menyala sejak T-8.7). Keduanya terjadi diam-diam:
Play memperbarui di latar hanya bila syaratnya terpenuhi, dan tambalan
Shorebird baru berjalan pada pembukaan berikutnya. Pengguna tidak tahu ada
versi baru, tidak tahu apa yang berubah, dan Akun belum menampilkan versi.

Batasan: inti aplikasi wajib luring (NFR-REL-001), akun opsional, tidak ada
server milik sendiri, Shorebird menambal kode Dart tetapi tidak membawa
perubahan aset, iOS belum dirilis, dan setiap data baru yang keluar
perangkat harus dicek terhadap formulir Keamanan Data.

## 3. Keputusan

Tanukonomy mengumumkan pembaruan dari dua sumber di balik satu port, tanpa
server baru:

1. **Port `AppUpdateSource`** (nama final di tangan engineer) dengan dua
   adaptor: **Play In-App Updates** mode fleksibel (Android, paket
   `in_app_update` atau setara) dan **Shorebird** (`shorebird_code_push`,
   hanya membaca keadaan: tambalan berjalan dan tambalan berikutnya yang
   sudah terunduh). Versi build dibaca lewat `package_info_plus`.
   `auto_update` Shorebird tidak diubah.
2. **Satu keadaan gabungan** (`none`, `storeAvailable`, `storeDownloading`,
   `storeDownloaded`, `patchReady`) dengan prioritas toko di atas tambalan,
   dibaca Beranda dan Akun. Kegagalan adaptor apa pun dipetakan ke `none`
   (`Either<Failure, T>` lewat `RepositoryGuard`, lalu diabaikan di UI).
3. **Catatan "Apa yang baru" ditulis di teks i18n** (slang, dikompilasi
   jadi kode Dart) per (build, tambalan), bukan aset atau server, sehingga
   ikut terbawa tambalan Shorebird dan terbaca luring.
4. **Preferensi lokal** menyimpan versi terakhir yang dilihat, penundaan,
   tambalan yang sudah diumumkan, dan waktu pengecekan terakhir. Bukan
   entitas domain.
5. **Pemasangan versi Play hanya atas ketukan pengguna**, tidak pernah
   otomatis dari aplikasi; tidak ada pembaruan paksa di R1.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Firebase Remote Config** berisi versi terbaru dan catatan
  rilis, lalu membuka Play Store.
- **Opsi B — Play In-App Updates mode langsung (immediate)** untuk setiap
  versi baru.
- **Opsi C — Play In-App Updates fleksibel + keadaan Shorebird + catatan
  di i18n (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Firebase Remote Config

Bisa mengatur versi minimum dan mengubah catatan tanpa rilis, juga untuk
iOS. Tetapi menambah SDK dan panggilan jaringan baru, harus dijaga
konsisten dengan apa yang benar-benar ada di Play (bisa mengumumkan versi
yang belum sampai ke pengguna karena peluncuran bertahap), dan tetap
melempar pengguna ke Play Store. Cocok untuk R2 (versi minimum), bukan
sumber utama.

### Opsi B — Mode langsung

Paling pasti membuat pengguna ke versi terbaru, tetapi layar penuh yang
memblokir bertentangan dengan prinsip "lembut, bukan menghakimi" dan bisa
memotong pengguna yang sedang mencatat di toko. Hanya layak untuk perbaikan
kritis, dan itu butuh sinyal versi minimum (Opsi A).

### Opsi C — Fleksibel + Shorebird + i18n (Dipilih)

Sumber kebenaran untuk "ada versi baru" adalah Play sendiri (tidak pernah
mengumumkan build yang belum bisa diunduh pengguna itu) dan Shorebird
sendiri. Tanpa server baru. Kelemahan: Android saja; tidak berfungsi untuk
build yang tidak dipasang dari Play (debug, APK langsung) sehingga harus
diuji lewat jalur tes Play; catatan butuh rilis/tambalan untuk diubah; dan
isi tambalan berikutnya tidak bisa diumumkan sebelum berjalan.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Penguji tahu ada versi baru dan memasangnya dari dalam aplikasi.
- Laporan bug bisa dicocokkan ke build dan tambalan (Akun, Analytics,
  Crashlytics).
- Catatan rilis untuk pengguna dan email penguji bisa disusun dari sumber
  yang sama.

### Yang menjadi lebih sulit

- Setiap rilis dan tambalan yang terasa pengguna butuh catatan id/en di
  i18n sebelum `shorebird release`/`shorebird patch`.
- Uji alur Play butuh build rilis yang dipasang dari jalur tes Play.

### Risiko yang diterima

- Dua dependensi baru (`in_app_update` komunitas, `shorebird_code_push`
  resmi) dan `package_info_plus`.
- Pengguna yang selalu menekan Nanti tetap di versi lama sampai Play
  memperbaruinya sendiri.

## 7. Catatan implementasi

- Letak: port dan adaptor di zona yang boleh dibaca `app/` dan fitur Akun
  (mis. `core/foundation/app_update/`); banner dan lembar di fitur sendiri
  (mis. `features/app_update/`), dipasang ke slot `notice` Beranda oleh
  akar komposisi di `lib/app/` bersama `CaptureInboxBanner`. Jaga
  `test/architecture/import_boundaries_test.dart`.
- Adaptor Play dan Shorebird harus bisa diganti palsu di uji; semua aturan
  B-1–B-13 APP_UPDATE.md diuji tanpa perangkat.
- Pengecekan berjalan sesudah Beranda tampil; tidak menunda pembukaan.
- Jangan memuat catatan dari `assets/` saat runtime; aset tidak ikut
  tambalan Shorebird.
- Verifikasi API persis `shorebird_code_push` (membaca tambalan berjalan dan
  berikutnya) dan perilaku `completeFlexibleUpdate` saat aplikasi di latar
  sebelum menulis adaptor.

## 8. Kriteria peninjauan ulang

- Aplikasi dirilis di iOS (App Store tidak punya In-App Updates).
- Ada perbaikan kritis data yang harus memaksa pengguna pindah versi
  (butuh versi minimum, Opsi A).
- Sinkronisasi ke server dibangun dan versi skema data antarperangkat harus
  cocok.
- Pengukuran §3 APP_UPDATE.md menunjukkan <50% pengguna aktif di versi
  terbaru sesudah 7 hari meski banner berjalan.
