# Ganti nama aplikasi menjadi Tanukonomy

## 1. Metadata

- **Decision ID:** ADR-022
- **Tanggal:** 2026-09-28
- **Fase roadmap:** Fase 8 (T-8.3)
- **Status:** Accepted (keputusan nama) / **sebagian dilaksanakan** — lihat
  §4 "Status eksekusi"
- **Cakupan:** Global — nama tampilan aplikasi, teks i18n yang menyebut nama
  produk, dan dokumen.
- **Rujukan:** [ASO_NAME_RESEARCH.md](../../03-release/ASO_NAME_RESEARCH.md)

## 2. Konteks

Riset ASO (27 Sep 2026) merekomendasikan **Tallipop** untuk pasar global,
tetapi pemilik memilih **Tanukonomy** — nama yang tidak ada di daftar
penyaringan riset itu sendiri, dipilih belakangan bersama maskot **tanuki
juru catat** (patung tanuki Shigaraki yang secara harfiah membawa buku
catatan utang-piutang, cocok dengan produk yang "mencatat, bukan
melakukan"). Pemeriksaan bentrok nama toko untuk "Tanukonomy" ada di
`ASO_NAME_RESEARCH.md` baris kandidat maskot (§3 tabel maskot): tidak
ditemukan bentrok di pencarian web pada tanggal riset.

Nama paket Dart (`saldough` di `pubspec.yaml`), nama kelas (`SaldoughApp`),
dan seluruh komentar kode yang menyebut "Saldough" sebagai nama proyek
**tidak termasuk cakupan keputusan ini** — mengganti nama paket Dart
menyentuh setiap berkas impor di repositori untuk manfaat yang murni
kosmetik secara internal, dan `PROJECT_GLOSSARY.md`/CLAUDE.md sudah
menyatakan ini boleh tetap.

## 3. Keputusan

Nama produk yang dihadapi pengguna (nama tampilan aplikasi, teks di dalam
aplikasi yang menyebut nama produk, listing toko, dan dokumen produk)
berganti dari **Saldough** menjadi **Tanukonomy**. Identitas teknis
internal (nama paket Dart, nama kelas, komentar kode) tetap "Saldough".

Eksekusi dipecah dua kelompok:

1. **Boleh dilakukan sekarang, sebelum prasyarat legal/bisnis beres** —
   perubahan yang murni kosmetik dan gampang dibatalkan (nama tampilan
   Android/iOS, teks i18n).
2. **Menunggu prasyarat pemilik** — perubahan yang mengikat identitas
   aplikasi di luar repositori (ID aplikasi/bundle identifier, ikon
   final, sapuan penggantian nama di seluruh dokumen produk). Lihat §4.

## 4. Status eksekusi (28 September 2026)

**Sudah dikerjakan** (kelompok 1 — aman diubah kapan pun sebelum rilis
pertama, tidak terikat prasyarat toko):

- `android/app/src/main/AndroidManifest.xml`: `android:label` →
  `"Tanukonomy"`.
- `ios/Runner/Info.plist`: `CFBundleDisplayName` → `"Tanukonomy"`,
  `CFBundleName` → `"tanukonomy"`.
- `assets/i18n/{id,en}.i18n.json`: keempat kemunculan "Saldough" di teks
  yang dibaca pengguna diganti "Tanukonomy" — `app.title`,
  `record.disclaimerMessage`, `transaction.detailManualNote`,
  `freelance.receiveRuleBody`. Slang diregenerasi (`dart run slang`).
- **ID aplikasi** (28 September 2026, atas instruksi eksplisit pemilik):
  `com.saldough.saldough` → **`com.arkarizdev.tanukonomy`** di
  `android/app/build.gradle.kts` (`namespace` dan `applicationId`),
  `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`,
  termasuk target `RunnerTests`), `ios/Runner/Info.plist` sudah konsisten
  lewat `$(PRODUCT_BUNDLE_IDENTIFIER)`, dan direktori paket Kotlin
  dipindah dari `android/app/src/main/kotlin/com/saldough/saldough/` ke
  `android/app/src/main/kotlin/com/arkarizdev/tanukonomy/`
  (`MainActivity.kt` beserta deklarasi `package`-nya ikut disesuaikan).
  ⚠ Ini TIDAK mengesampingkan prasyarat cek merek dagang di bawah — nama
  domain/akun toko yang mendasari `arkarizdev`/`tanukonomy` tetap perlu
  diverifikasi pemilik sendiri; nilainya sudah dikunci di kode atas
  instruksi eksplisit, bukan karena prasyaratnya sudah terbukti selesai.

**BELUM dikerjakan, menunggu pemilik** — lihat
[TASK_LIST.md T-8.3](../../04-planning/TASK_LIST.md) untuk daftar prasyarat
lengkapnya:

- **Cek merek dagang resmi** (DJKI, USPTO, EUIPO, WIPO; kelas 9 dan 36).
  Belum dilakukan — riset ASO hanya mengecek pencarian web publik, BUKAN
  basis data merek dagang resmi.
- **Amankan domain dan nama di Play Console/App Store Connect.** Belum
  dilakukan.
- **Ikon aplikasi Android** — ✅ **selesai 28 September 2026.** Pemilik
  menyerahkan artwork ikon persegi bermaskot tanuki
  (`assets/illustration/app_icon.png`). Ikon peluncur (adaptif + legacy,
  seluruh mipmap) dan splash screen (terang/gelap, termasuk Android 12+)
  dibuat lewat `flutter_launcher_icons`/`flutter_native_splash`
  (konfigurasi di `pubspec.yaml`, sumber turunan di `assets/icon/`).
  **Ikon iOS** (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`) **masih
  menunggu** — artwork yang ada punya latar transparan (dipakai sebagai
  lapisan foreground ikon adaptif Android); iOS mengabaikan kanal alfa dan
  menampilkan area transparan sebagai hitam, jadi butuh versi full-bleed
  tanpa transparansi sebelum dipakai di sana.
- **Sapuan penggantian nama di seluruh dokumen produk** (README, PRD,
  glosarium, dan dokumen `docs/` lain yang menyebut "Saldough" sebagai nama
  produk secara naratif). **Sengaja ditunda** — beberapa dokumen itu
  (`ASO_NAME_RESEARCH.md`, ADR ini) justru perlu tetap menyebut "Saldough"
  sebagai bagian dari catatan sejarah keputusan; sapuan penuh butuh
  peninjauan per berkas, bukan cari-ganti global, dan lebih murah
  dikerjakan sekali setelah nama final benar-benar terkunci oleh hasil cek
  merek dagang (kalau cek merek dagang menggagalkan "Tanukonomy", sapuan
  dokumen ini harus diulang untuk nama ketiga).

## 5. Konsekuensi

- Aplikasi kini tampil sebagai "Tanukonomy" dan berjalan di atas
  `applicationId`/bundle identifier `com.arkarizdev.tanukonomy`, dengan
  ikon peluncur dan splash Android sudah bermaskot tanuki. Ikon iOS masih
  ikon Flutter bawaan — tidak masalah untuk build pengembangan, TAPI
  **jangan rilis ke toko dalam keadaan ini**: ikon iOS harus final sebelum
  rilis pertama, dan trademark/domain/Play Console/App Store Connect tetap
  harus diverifikasi pemilik sebelum rilis pertama walau ID aplikasi sudah
  dikunci di kode (mengubahnya lagi sesudah rilis pertama praktis tidak
  mungkin tanpa kehilangan basis pengguna).
- `PROJECT_GLOSSARY.md` dan `CLAUDE.md` belum diperbarui menyebut
  Tanukonomy sebagai nama tampilan resmi — dicatat sebagai bagian sapuan
  dokumen yang ditunda di §4.

## 6. Kriteria peninjauan ulang

Tinjau ulang ADR ini (atau buat ADR baru yang men-supersede) kalau cek
merek dagang resmi menemukan bentrok untuk "Tanukonomy" di kelas 9/36 —
dalam hal itu kelompok 1 di atas harus di-*revert* atau diarahkan ke nama
pengganti sebelum sapuan dokumen dan ID aplikasi dikerjakan.
