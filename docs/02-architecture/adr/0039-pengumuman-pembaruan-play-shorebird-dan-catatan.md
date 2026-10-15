# Pengumuman pembaruan: Play In-App Update, Shorebird, dan catatan Apa yang baru

## 1. Metadata

- **Decision ID:** ADR-039
- **Tanggal:** 2026-10-15
- **Fase roadmap:** Fase 20 (T-20.1)
- **Status:** Accepted (pemilik, 2026-10-15)
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
  (paling sering sekali per jam; bila hasil terakhir gagal atau belum pasti, diulang pada pemicu berikutnya sesudah 1 menit), dan saat Akun dibuka. Selalu tanpa
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
   `release_notes/<build>-<patch>.json` (`0` bila rilis toko). Pemilik
   menyetujui lewat tinjauan PR sebelum rilis atau tambalan diterbitkan
   (KT-U5). Berkas `release_notes/id.md`/`en.md` lama diganti. Bentuknya
   (butir **dikelompokkan per kategori**, keputusan pemilik 15 Okt 2026):

   ```json
   {
     "version": "0.6.0",
     "groups": [
       { "category": "new", "notes": [
         { "id": "Bulan keuangan kini bisa dimulai di tanggal gajianmu.",
           "en": "Your financial month can now start on payday." } ] },
       { "category": "fixed", "notes": [
         { "id": "…", "en": "…" }, { "id": "…", "en": "…" } ] }
     ]
   }
   ```

   - `version` = nama versi (`0.6.0`) untuk judul dan kepala kelompok;
     build dan nomor pembaruan kecil hanya dari nama berkas.
   - `category` salah satu: `new` (Baru ✨), `faster` (Lebih cepat ⚡),
     `fixed` (Perbaikan 🛠️), `security` (Keamanan 🔒). Label di i18n
     (`appUpdate.category.*`), emoji dipetakan di aplikasi, bukan di data.
     Kategori yang tak dikenal aplikasi (mis. dari versi yang lebih baru)
     tidak dibuang: butirnya tampil sebagai kelompok tanpa label dan emoji.
   - Urutan kelompok dan butir = urutan tampil; penulis menaruh yang paling
     penting bagi pengguna di atas. Satu kategori satu kelompok.
   - Pakai bila: `new` ada kemampuan atau layar baru yang terlihat;
     `faster` hanya bila ada ukuran sebelum dan sesudah; `fixed` sesuatu
     yang salah kini benar, dari sisi yang dirasakan pengguna; `security`
     hanya perubahan perlindungan data atau akses yang bisa disebut
     konkret (bukan "diperkuat").
   - **Catatan wajib untuk setiap build yang dipublikasikan** (rilis toko
     maupun pembaruan kecil), keputusan pemilik 15 Okt 2026: CI berhenti
     sebelum build bila berkasnya tidak ada atau tanpa butir. Aplikasi tetap
     menoleransi entri yang tak ada (tanpa lembar, B-11), sebagai pengaman.
   - Total paling banyak 3 butir per berkas (B-11), 6 di lembar gabungan.
   - Tampilan: label kategori (emoji + nama) sekali per kelompok, butir di
     bawahnya. Lembar tanpa penutup maskot atau kalimat terima kasih
     (keputusan pemilik 15 Okt 2026).
   - CI memeriksa sebelum build (T-20.6): JSON sah, `id` dan `en` tak
     kosong, kategori dikenal dan tidak ganda, total ≤ 3, `version` sama
     dengan `pubspec.yaml` untuk build itu, dan teks id tanpa tanda seru,
     "Anda", "patch", "tambalan", "bug".
2. **Penyaji = Remote Config, satu parameter per entri**:
   `whats_new_<build>_<patch>` bernilai JSON entri itu. Satu parameter per
   entri, bukan satu peta riwayat, supaya (a) skrip CI tidak perlu membaca-
   lalu-menimpa riwayat (balapan dua rilis), (b) tiap nilai kecil dan jauh di
   bawah batas ukuran nilai parameter (batas persisnya diverifikasi di
   T-20.6; bila ternyata < ±700 karakter, entri dipecah per bahasa
   `…_id`/`…_en`). `scripts/update_release_note.js` diubah: menulis semua
   entri `release_notes/*.json` (idempoten) dan **tidak lagi menimpa**
   parameter lama.
3. **Urutan di CI dan bila build gagal.** Langkah Remote Config dijalankan
   **sebelum** langkah `release`/`patch`. Hari ini ia sesudahnya: pengguna
   yang sudah memuat tambalan bisa membuka aplikasi sebelum catatannya
   terbit, lalu dianggap "tanpa catatan" dan lembarnya hilang selamanya.
   Akibat dari urutan baru, catatan bisa terbit untuk rilis yang akhirnya
   gagal. Itu ditangani tiga lapis:
   1. **Sinkronisasi dengan penghapusan:** skrip menyamakan semua parameter
      `whats_new_*` dengan isi `release_notes/` (menambah, menimpa, dan
      menghapus kunci tanpa berkas). Catatan yatim hilang pada eksekusi
      berikutnya. Berkas catatan rilis yang gagal dihapus atau diganti
      namanya di PR perbaikan.
   2. **Pembersihan saat gagal:** langkah `if: failure()` menghapus entri
      milik eksekusi itu sebisanya (tidak boleh membuat eksekusi gagal
      kedua; kegagalannya ditutup oleh lapis 1).
   3. **Aplikasi hanya memakai entri yang nomornya sudah berjalan atau
      terlewati** (build/tambalan ≤ yang berjalan) dan hanya menyalin entri
      itu ke penyimpanan lokal. Entri yatim bernomor lebih besar tidak
      tampil dan tidak tersimpan. Sisa risiko: catatan yatim bernomor
      **lebih kecil** dari rilis berikutnya (build 7 gagal, rilis jadi build
      8, pengguna lompat 6→8) hanya tertutup lapis 1 dan 2; karena itu
      pemeriksaan "berkas catatan cocok dengan versi di `pubspec.yaml`" masuk
      CI (T-20.6).
   Nomor pembaruan kecil dimasukkan operator sebagai input workflow
   (`patch_number`), karena catatan harus terbit sebelum `shorebird patch`
   memberi nomornya; pelaksanaan dan langkahnya di
   [RELEASE_NOTES.md](../../03-release/RELEASE_NOTES.md).
   Nomor tambalan Shorebird tidak terpakai bila tambalan gagal, jadi
   percobaan ulang memakai nomor yang sama dan menimpa entri dari berkas.
   Supaya penerbitan catatan itu sendiri andal: skrip mengulang bila
   penerbitan template bentrok (ETag berubah, maksimal 3 kali), lalu
   **membaca balik** template dan memastikan setiap entri ada dengan isi
   yang sama; bila tidak, pipeline berhenti **sebelum** rilis atau tambalan
   diunggah.
4. **Di aplikasi:** `firebase_remote_config` dengan nilai bawaan kosong.
   Nilai yang berhasil dibaca **disalin ke penyimpanan lokal**
   (`app_update/notes`) sehingga daftar di Akun tetap utuh luring dan
   sesudah entri dihapus dari server. Supaya Remote Config **andal**:
   1. *Ambil dini, bukan menunggu banner.* `fetchAndActivate` dijalankan
      setiap aplikasi dibuka dan kembali ke depan (tanpa `await` di jalur
      pembukaan), dengan `minimumFetchInterval` 30 menit (di bawah batas
      throttle klien 5 ambil/jam). Karena CI menerbitkan catatan **sebelum**
      rilis (butir 3), perangkat sudah memegang entri build baru jauh sebelum
      Play menawarkannya (peninjauan dan peluncuran Play makan jam-jaman).
   2. *Perubahan langsung.* Selama aplikasi terbuka, `onConfigUpdated`
      mengaktifkan entri baru tanpa menunggu interval.
   3. *Rantai cadangan.* Nilai aktif SDK → salinan lokal → tanpa data. Data
      yang sudah pernah didapat tidak hilang karena luring.
   4. *Batas tunggu.* Banner versi baru menunggu pengambilan paling lama
      2 detik **hanya bila** entri build yang ditawarkan Play belum ada;
      lewat itu banner tampil tanpa chip versi dan chip menyusul. Beranda
      dan pencatatan tidak pernah menunggu (B-13).
   5. *Terukur.* Parameter `has_version` (true/false) pada
      `update_banner_shown` (T-20.5): kalau persentase `false` tinggi,
      keandalannya perlu ditinjau.
5. **Gagal = tunda, bukan lewati.** Catatan yang belum didapat menunda
   lembar dan versi terakhir dilihat belum dimajukan (§11); entri yang
   memang tidak ada baru dianggap "tanpa catatan" bila server sudah dibaca
   berhasil dan kuncinya tidak ada.
6. Bahasa: aplikasi memilih `id` atau `en` sesuai bahasa aktif saat
   ditampilkan, dengan `en` sebagai cadangan.
7. **Chip versi di banner "Versi baru tersedia".** Play hanya memberi nomor
   build yang tersedia, bukan nama versinya. Aplikasi mencari entri
   `whats_new_<build tersedia>_0` dan membaca **hanya kolom `version`**
   (butir catatan tetap baru dibaca setelah terpasang). Entri hanya dicari
   untuk build yang sudah dikonfirmasi Play, jadi catatan yatim dari rilis
   yang gagal tidak pernah tampil. Entri belum ada = banner tanpa chip.

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
  mengisi slot `updateNotice` Beranda (di atas kartu saldo) dengan
  banner pembaruan dan pemicu lembar; banner kotak masuk tetap di slot
  `notice` di bawah saldo dan keduanya bisa tampil bersamaan (B-2, diubah
  pemilik 15 Okt 2026). Akun membuka layar lewat kunci
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
