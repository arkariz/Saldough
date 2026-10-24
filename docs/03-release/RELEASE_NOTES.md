# Catatan rilis "Apa yang baru"

**Berlaku sejak:** 15 Oktober 2026 (Fase 20, T-20.6).
**Keputusan:** [ADR-039](../02-architecture/adr/0039-pengumuman-pembaruan-play-shorebird-dan-catatan.md) §3.3.
**Perilaku di aplikasi:** [APP_UPDATE.md](../01-product/features/APP_UPDATE.md).

Setiap build yang dipublikasikan, rilis Play Store maupun pembaruan kecil
Shorebird, **wajib** punya satu berkas catatan. Berkas yang sama menjadi:
lembar "Apa yang baru" dan daftar di Akun › Versi aplikasi (lewat Firebase
Remote Config), teks "What's new" di Play Console untuk rilis toko, dan bahan
email rilis untuk penguji (skill `release-email`).

## Berkas

`release_notes/<build>-<patch>.json`, `<patch>` = `0` untuk rilis toko, nomor
Shorebird untuk pembaruan kecil. Contoh `release_notes/7-0.json`:

```json
{
  "version": "0.6.0",
  "groups": [
    { "category": "new", "notes": [
      { "id": "Urutan dompet bisa kamu atur dengan menyeretnya.",
        "en": "You can arrange your wallets by dragging them." } ] },
    { "category": "fixed", "notes": [
      { "id": "…", "en": "…" } ] }
  ]
}
```

- `version` = nama versi, sama dengan `pubspec.yaml` (untuk judul dan kepala
  kelompok). Build dan nomor pembaruan kecil hanya dari nama berkas.
- `category`: `new` (Baru), `faster` (Lebih cepat, hanya bila terukur),
  `fixed` (Perbaikan), `security` (Keamanan, hanya yang konkret). Satu
  kelompok per kategori; urutan kelompok dan butir = urutan tampil, yang
  paling penting di atas.
- 1–3 butir per berkas, masing-masing **satu kalimat manfaat** dalam `id`
  dan `en`. Hanya perubahan yang terasa pengguna.
- Gaya `id`: "kamu", tanpa tanda seru, tanpa "Anda", "patch", "tambalan",
  atau "bug". Gaya `en`: tanpa tanda seru. Nama menu dan tombol sesuai
  `assets/i18n/*.json`.

## Siapa menulis dan menyetujui

Agen menyusun draf dari `docs/04-planning/TASK_LIST.md` dan commit sejak
rilis terakhir (bersama email rilis); **pemilik menyetujui lewat tinjauan PR**
sebelum rilis atau pembaruan kecil dipicu (KT-U5). Catatan yang belum
disetujui tidak boleh ada di `main`.

## Langkah rilis toko

1. Naikkan `version:` di `pubspec.yaml` (mis. `0.7.0+9`).
2. Tulis `release_notes/9-0.json` (`version` = `0.7.0`), setujui lewat PR,
   gabungkan ke `main`.
3. Jalankan workflow **Shorebird Pipeline** dengan `action_type = release`.

## Langkah pembaruan kecil

1. Gabungkan perubahan kodenya ke `main`.
2. Tentukan nomor patch berikutnya untuk rilis itu (patch pertama = `1`,
   berikutnya `2`, dst.; nomor Shorebird per rilis). Tulis
   `release_notes/<build>-<nomor>.json` dengan `version` yang sama dengan
   `pubspec.yaml`; setujui lewat PR.
3. Jalankan workflow dengan `action_type = patch` dan `patch_number` =
   nomor itu. Nomor yang keliru membuat catatan tidak ditemukan aplikasi
   (lembar ditunda, bukan salah tampil): cocokkan dengan konsol
   Shorebird (daftar patch rilis itu) bila ragu.

## Yang dilakukan pipeline

`.github/workflows/deploy.yaml`, urutannya:

1. `npm test`: uji skrip catatan (`scripts/release_notes.test.js`).
2. `validate`: berkas build/patch ini wajib ada, sah, dan `version` sama dengan
   `pubspec.yaml`. **Gagal di sini = tidak ada build yang dimulai.**
3. `publish`: menyamakan seluruh parameter `whats_new_<build>_<patch>` di
   Remote Config dengan isi `release_notes/` (menambah, menimpa, menghapus
   yang tanpa berkas), mengulang bila ETag bentrok (maksimal 3 kali), lalu
   **membaca balik** template. Gagal membaca balik = berhenti sebelum rilis.
4. Rilis atau patch lewat fastlane. Untuk rilis toko, teks "What's new" Play
   dibuat dari berkas yang sama oleh `node scripts/release_notes.js
   play-changelog --build <build> --lang id|en`: judul "🚀 Apa yang baru di
   versi X", lalu tiap kategori dengan emoji dan namanya (✨ Baru, ⚡ Lebih
   cepat, 🛠️ Perbaikan, 🔒 Keamanan) dan butirnya bertanda •. Maksimal 500
   karakter per bahasa (batas Play); bila lebih, butir terbawah dibuang dan
   kategori yang kosong ikut hilang.
5. Bila langkah 4 gagal: `cleanup` menghapus entri eksekusi ini dari
   Remote Config (sebisanya). Sisa yang yatim hilang pada `publish`
   eksekusi berikutnya.

Catatan terbit **sebelum** rilis: perangkat sudah memegangnya saat Play
menawarkan versi baru, jadi chip versi di banner dan lembar tidak menunggu
jaringan.

## Pemeriksaan di mesin lokal

```bash
npm test                                   # uji skrip
node scripts/release_notes.js validate --build 7 --patch 0
fvm flutter test test/release              # penjaga berkas (sisi Dart)
```

`publish` dan `cleanup` butuh `FIREBASE_SERVICE_ACCOUNT_KEY` (rahasia CI).

## Daftar periksa rilis berfitur Plus (Fase 24, ADR-041)

Sebelum membangun dan mengunggah build yang memuat gerbang Plus
(T-24.9 sampai T-24.13), pemilik memeriksa:

1. **Penguji bisa masuk akun.** Sebelum Plus dijual, masuk akun = Plus dan
   tanpa akun = Gratis (gerbang mengunci otomasi rutin, sumber notifikasi
   ke-2, tingkat otomatis, Analisis lebih dari 6 periode, template ke-2, dan
   proyek ke-3). Daftarkan tiap penguji sebagai tester OAuth Google (selama
   layar consent belum terverifikasi) atau beri akun email/sandi.
2. **Catatan rilis dan email penguji memberi tahu** bahwa fitur Plus
   memerlukan masuk akun ("masuk akun untuk tetap memakai fitur ini"); tanpa
   itu pengguna yang tidak masuk merasa fiturnya hilang.
3. **Kunci SDK RevenueCat** ada sebagai secret GitHub
   `REVENUECAT_ANDROID_KEY` dan sampai ke **rilis dan patch** Shorebird
   (`android/fastlane/Fastfile`, `.github/workflows/deploy.yaml`; dijaga
   `test/architecture/release_pipeline_test.dart`). Tanpa secret, build
   berjalan tanpa RevenueCat dan Fastlane memberi peringatan.
4. **Akun peninjau Play**: akun email/sandi diberi entitlement promosi
   RevenueCat tanpa tanggal berakhir; kredensial dan instruksinya di kolom
   App access (lihat `PLAY_DATA_SAFETY.md`). Periksa ulang tiap rilis publik.
5. **Penguji closed testing** diberi entitlement promosi 12 bulan per
   `firebaseUid` di dasbor RevenueCat (KT-P5); penguji pembelian memakai akun
   penguji lisensi Play.
6. **Objek di RevenueCat dan Play Console** sesuai ADR-041 §3.5: entitlement
   `plus`; langganan `plus` dengan base plan `monthly`, `yearly`,
   `yearly-founder`; offering `default`, `founder`, `post_trial` yang berisi
   package berindentifier `monthly`, `yearly`, `yearly_founder`,
   `yearly_intro` (lihat ADR).
7. **Remote Config**: `plus_launch_at` **kosong** sampai Plus siap dijual
   (kosong = pra-peluncuran; mengisinya memulai uji coba dan tombol beli);
   `founder_until` = 90 hari sesudah rilis publik.
8. **Keamanan Data dan kebijakan privasi** sudah memuat RevenueCat dan
   riwayat pembelian (`PLAY_DATA_SAFETY.md`, bagian Fase 24) sebelum build
   berfitur ini diunggah.
9. **Build rilis tanpa sakelar uji**: pipeline tidak pernah memberi
   `PLAN_OVERRIDE` (dijaga uji arsitektur).
