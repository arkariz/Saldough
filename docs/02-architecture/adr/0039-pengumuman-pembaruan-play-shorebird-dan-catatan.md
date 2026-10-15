# Pengumuman pembaruan: Play In-App Update, Shorebird, dan catatan Apa yang baru

## 1. Metadata

- **Decision ID:** ADR-039
- **Tanggal:** 2026-10-15
- **Fase roadmap:** Fase 20 (T-20.1)
- **Status:** Proposed (menunggu persetujuan pemilik)
- **Cakupan:** Fitur baru `app_update`, slot banner Beranda (`lib/app/shell`),
  layar Akun, pipeline rilis (`.github/workflows/deploy.yaml`,
  `scripts/`, `release_notes/`)

## 2. Konteks

[APP_UPDATE.md](../../01-product/features/APP_UPDATE.md) menetapkan perilaku
(F1–F4, B-1–B-13) dan menyerahkan lima keputusan teknis ke engineer (§13).
Pemilik menjawab KT-U1–KT-U5 sesuai rekomendasi (15 Okt 2026): tanpa paksa,
pembaruan kecil diumumkan sekali, Apa yang baru tampil otomatis sekali,
format "0.6.0 (7), pembaruan 1", agen menyusun catatan dan pemilik menyetujui.

Keadaan repositori saat ini:

- Shorebird aktif (`shorebird.yaml`, `auto_update` bawaan = menyala): mesinnya
  mengunduh tambalan saat aplikasi dibuka dan memakainya pada pembukaan
  berikutnya. Belum ada paket `shorebird_code_push`.
- Firebase (Core, Auth, Analytics, Crashlytics, AI, App Check) sudah ada
  (ADR-023). Belum ada Remote Config, `package_info_plus`, maupun `in_app_update`.
- Pipeline rilis di `main` (`deploy.yaml`, fastlane): `release` ke jalur tes
  internal Play dan `patch` lewat Shorebird, lalu `scripts/update_release_note.js`
  menulis `release_notes/id.md` dan `en.md` ke dua parameter Remote Config
  (`latest_release_note_id`/`_en`), menimpa nilai sebelumnya.
- Tambalan Shorebird hanya mengganti kode Dart, **bukan aset**: catatan untuk
  pembaruan kecil tidak bisa ikut terkemas di dalam aplikasi.

## 3. Keputusan

### 3.1 Versi baru dari Play Store: Play In-App Updates, mode fleksibel

Paket `in_app_update` (Play Core, Android). Alurnya `checkForUpdate` →
`startFlexibleUpdate` (unduh di latar) → stream status → `completeFlexibleUpdate`
(pasang dan mulai ulang). Ini memetakan langsung ke keadaan APP_UPDATE:
`updateAvailability` = tersedia, status `downloading`/`downloaded` = mengunduh
dan sudah diunduh. Mode **langsung** (immediate) tidak dipakai karena
memblokir layar, bertentangan dengan "tidak memaksa" (KT-U1).

- Hanya berfungsi untuk aplikasi yang dipasang dari Play. Sideload, build
  debug, atau pemanggilan yang melempar galat = keadaan `unknown` = diam (B-5).
- Pengecekan: saat Beranda pertama tampil, saat aplikasi kembali ke depan
  (paling sering sekali per 6 jam), dan saat Akun dibuka. Selalu tanpa
  `await` di jalur pembukaan (B-13).
- `completeFlexibleUpdate` hanya dipanggil dari ketukan **Pasang sekarang**
  (B-7).
- Memasang saat notifikasi sedang diproses aman: layanan native hanya
  mengakui antrean sesudah simpanan Dart berhasil (ADR-032), jadi proses yang
  dimatikan memasang ulang tangkapan pada pembukaan berikut. Diverifikasi
  di T-20.8.

Pilihan yang ditolak: membuka halaman Play (keluar aplikasi, tiga ketukan
lebih banyak, tanpa keadaan unduh); `upgrader`/`new_version_plus` (membaca
laman toko lewat web, rapuh, tidak tahu jalur tes tertutup).

### 3.2 Pembaruan kecil: `shorebird_code_push`, baca saja

`auto_update` **tidak diubah** (tetap menyala; mesin tetap mengunduh sendiri).
Paket dipakai hanya untuk membaca keadaan lokal tanpa jaringan:

- tambalan berjalan = `readCurrentPatch()?.number ?? 0`;
- pembaruan kecil siap = `readNextPatch()` bernomor berbeda dari yang
  berjalan dan lebih besar. Nomor lebih kecil = rollback: tanpa banner,
  tanpa lembar, versi terakhir dilihat tidak turun (§11);
- `checkForUpdate()`/`update()` **tidak dipakai** (jaringan tambahan tanpa
  manfaat). `isAvailable` palsu (debug) = diam.

Setelan Shorebird tidak berubah. Konsekuensinya: banner "siap" baru muncul
sesudah mesin selesai mengunduh (pembukaan yang sama atau berikutnya); itu
sesuai F2. B-9 tetap: banner tidak menyebut isinya.

### 3.3 Catatan Apa yang baru: sumber di repo, disajikan lewat Remote Config

**Saran penyimpanan** (empat pilihan dinilai):

| Pilihan | Pembaruan kecil | Luring | Server baru | Catatan |
|---|---|---|---|---|
| Aset di dalam aplikasi | Tidak bisa (tambalan tak mengubah aset) | Ya | Tidak | Hanya cocok untuk versi toko; ditolak karena tidak menutup B-11 |
| **Remote Config + sumber di repo** | **Bisa** | Cache SDK dan salinan lokal | **Tidak (Firebase sudah ada)** | **Dipilih** |
| Berkas JSON statis di situs `tanukonomy-web` | Bisa | Perlu salinan sendiri | Ya (domain baru) | Titik kegagalan dan alamat publik baru |
| Firestore | Bisa | Ya | Ya (skema, aturan keamanan) | Berlebihan untuk teks pendek |

Keputusan:

1. **Sumber kebenaran = repo**, bukan konsol Firebase. Satu berkas per entri:
   `release_notes/<build>-<patch>.json` (`0` bila rilis toko), isi
   `{"id": ["…"], "en": ["…"]}`, 1–3 butir per bahasa (B-11). Pemilik
   menyetujui lewat tinjauan PR sebelum rilis atau tambalan diterbitkan
   (KT-U5). Berkas `release_notes/id.md`/`en.md` lama diganti.
2. **Penyaji = Remote Config, satu parameter per entri**:
   `whats_new_<build>_<patch>` bernilai JSON entri itu. Satu parameter per
   entri, bukan satu peta riwayat, supaya (a) skrip CI tidak perlu membaca-
   lalu-menimpa riwayat (balapan dua rilis), (b) tiap nilai kecil dan jauh di
   bawah batas ukuran nilai parameter (batas persisnya diverifikasi di
   T-20.6; bila ternyata < ±700 karakter, entri dipecah per bahasa
   `…_id`/`…_en`). `scripts/update_release_note.js` diubah: menulis semua
   entri `release_notes/*.json` (idempoten) dan **tidak lagi menimpa**
   parameter lama.
3. **Urutan di CI:** langkah Remote Config dipindah **sebelum** langkah
   `release`/`patch`. Hari ini ia sesudahnya, sehingga ada celah pengguna
   membuka tambalan sebelum catatannya terbit.
4. **Di aplikasi:** `firebase_remote_config` dengan nilai bawaan kosong dan
   `minimumFetchInterval` 1 jam; `fetchAndActivate` dijalankan sesudah
   Beranda tampil, tanpa `await` di jalur pembukaan. Nilai yang berhasil
   dibaca **disalin ke penyimpanan lokal** (`app_update/notes`) sehingga
   daftar di Akun tetap utuh luring dan sesudah entri dihapus dari server.
5. **Gagal = tunda, bukan lewati.** Catatan yang belum didapat menunda
   lembar dan versi terakhir dilihat belum dimajukan (§11); entri yang
   memang tidak ada baru dianggap "tanpa catatan" bila server sudah dibaca
   berhasil dan kuncinya tidak ada.
6. Bahasa: aplikasi memilih `id` atau `en` sesuai bahasa aktif saat
   ditampilkan, dengan `en` sebagai cadangan.

### 3.4 Server atau konfigurasi jarak jauh

Tidak ada server baru. Hanya layanan yang sudah ada: Play Core (bagian
Google Play), Shorebird (sudah berjalan), dan Firebase Remote Config
(proyek Firebase yang sama).

### 3.5 Letak kode dan ingatan aplikasi

Fitur baru `lib/features/app_update/` (`domain/`, `data/`, `presentation/`),
dengan `domain/` murni:

- `domain`: `AppVersion(name, build, patch)`, `UpdateAvailability`
  (`unknown|none|available|downloading|downloaded`), `PatchState`,
  `UpdateAnnouncement` (hasil aturan B-3/B-4/B-6/B-8), `ReleaseNote`,
  `AppUpdateMemory`; aturan sebagai fungsi murni (`pickAnnouncement`,
  `selectNotesToShow`) agar B-3, B-4, B-6, B-8, B-12, rollback, dan lompat
  versi teruji tanpa perangkat.
- Port sumber (`StoreUpdateSource`, `PatchSource`, `InstalledVersionSource`,
  `ReleaseNotesSource`) dengan implementasi `in_app_update`,
  `shorebird_code_push`, `package_info_plus`, `firebase_remote_config`;
  uji memakai `mocktail`.
- `presentation`: `AppUpdateBloc` (state_management), `AppUpdateBanner`,
  `WhatsNewSheet`, rute `AppUpdateRouteKeys.notes` untuk daftar dari Akun.
- Komposisi: `RootModule` memasang bloc; `lib/app/shell/app_shell_page.dart`
  mengisi slot `notice` Beranda dengan penentu prioritas (kotak masuk
  notifikasi > banner pembaruan, B-2/B-3). Akun membuka layar lewat kunci
  rute dan membaca baris versi lewat port kecil milik `account` (ADR-030:
  tanpa impor isi `app_update`).
- **Ingatan aplikasi** di `KeyValueStorage` (pola
  `TutorialProgressRepositoryImpl`), namespace `app_update`: dokumen
  `{schemaVersion, lastSeenBuild, lastSeenPatch, deferredBuild, deferredAt,
  announcedPatches: {build: patch}}` dan salinan catatan. Gagal baca =
  anggap pemasangan pertama (§11). Tidak ikut data keuangan; ikut hilang
  saat data aplikasi dihapus.

## 4. Data yang keluar perangkat (untuk T-20.7)

| Mekanisme | Ke mana | Data | Keadaan |
|---|---|---|---|
| Play In-App Update | Google Play (lewat layanan Play di perangkat) | Pengecekan versi paket oleh Play; tidak ada data dari aplikasi ke pengembang | Baru |
| Shorebird (`readCurrentPatch`/`readNextPatch`) | Tidak ada | Pembacaan lokal | Baru, tanpa jaringan |
| Shorebird mesin (`auto_update`) | Server Shorebird | Menurut dokumentasinya: id aplikasi, versi rilis, nomor tambalan, platform, arsitektur | **Sudah berjalan sejak T-8.7, belum tercatat** di `PLAY_DATA_SAFETY.md` |
| Remote Config | Firebase | Id instalasi Firebase, versi aplikasi, platform, bahasa; mengambil nilai parameter | Baru, tetapi id instalasi sudah dibuat oleh Analytics/Crashlytics |
| Analitik `UpdateEvents` dan `patch_number` | Firebase Analytics, Crashlytics | Jenis banner, tindakan, nomor build/tambalan; tanpa data pribadi atau keuangan | Atribut baru pada data yang sudah dideklarasikan |

Tidak ada data keuangan, teks transaksi, atau identitas pengguna yang keluar.

## 5. Konsekuensi

- Tiga dependensi pub baru (`in_app_update`, `shorebird_code_push`,
  `package_info_plus`) dan satu Firebase (`firebase_remote_config`); versinya
  dipin ke terbaru yang kompatibel dengan `firebase_core ^4.15` dan Flutter
  3.47.5.
- Pipeline rilis berubah: skrip Remote Config, urutan langkah, dan format
  `release_notes/` (T-20.6). Pemilik perlu memastikan akun layanan CI boleh
  menulis Remote Config (sudah dipakai skrip yang ada).
- Pengujian tanpa perangkat: seluruh aturan ada di fungsi murni dan port;
  banner/lembar diuji dengan sumber palsu. Perilaku nyata Play (jalur tes
  tertutup, pemasangan saat notifikasi diproses) hanya bisa dibuktikan di
  T-20.8.
- Risiko diketahui: In-App Updates hanya menawarkan versi yang sudah sampai
  ke perangkat lewat Play (bisa tertinggal beberapa jam dari publikasi);
  banner mengikuti Play, bukan jam publikasi kita.

## 6. Alternatif yang ditolak

- Memaksa pembaruan (mode langsung): bertentangan dengan KT-U1.
- Menonaktifkan `auto_update` Shorebird dan mengunduh manual: kehilangan
  perilaku yang sudah berjalan, menambah jaringan.
- Satu parameter riwayat Remote Config: rawan balapan penimpaan antar rilis
  dan batas ukuran nilai.
- Menyimpan catatan hanya di konsol Firebase: tidak bisa ditinjau/disetujui
  lewat PR dan tidak bisa dipulihkan dari repo.
