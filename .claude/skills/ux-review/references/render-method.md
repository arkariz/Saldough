# Metode cadangan: lihat render sungguhan

Pakai ini HANYA kalau checklist kode (`checklist.md`, terutama kategori E/F)
menyisakan pertanyaan yang butuh piksel sungguhan: teks yang mungkin
terpotong di lebar sempit, perbandingan dengan layar rujukan pemilik, atau
pemilik minta lihat tampilannya langsung. Jangan jalankan ini sebagai
langkah baku tiap review. Kontras warna tidak perlu dicek lewat render,
karena sudah diuji otomatis di `test/core/theme/app_colors_extension_test.dart`.

Saldough menyasar Android dan iOS (`.claude/CLAUDE.md`). Urutan pilihan:

## 1. Emulator Android (utama)

Loop inti Fase 2 sudah diverifikasi dengan cara ini (T-2.10, `emulator-5554`).

1. Cek perangkat: `adb devices`. Kalau kosong, minta pemilik menyalakan
   emulator. Jangan membuat AVD baru sendiri.
2. Jalankan aplikasi (build debug): `flutter run -d emulator-5554` di latar
   belakang, lalu tunggu sampai log menampilkan "Flutter run key commands".
3. Screenshot:
   ```bash
   adb -s emulator-5554 exec-out screencap -p > "$SCRATCH/01-dompet.png"
   ```
   (`$SCRATCH` = direktori scratchpad sesi, bukan repo.) Baca hasilnya
   dengan tool `Read`, jangan menebak dari nama berkas.
4. Navigasi: `adb -s emulator-5554 shell input tap X Y` (koordinat piksel
   perangkat, diambil dari screenshot sebelumnya), `input text`,
   `input keyevent 4` (back). Tab navigasi bawah bukan rute `go_router`,
   jadi harus diketuk, tidak bisa dicapai lewat URL.
5. Lebar sempit: `adb shell wm size 720x1280` dan/atau
   `adb shell wm density 400` untuk mensimulasikan layar kecil. **Wajib**
   dikembalikan dengan `adb shell wm size reset` dan
   `adb shell wm density reset` sesudahnya.
6. Mode gelap: `adb shell cmd uimode night yes` (kembalikan dengan `no`).

⚠ Tombol bulat kecil di kanan bawah pada build debug adalah menu
pengembang (`_WithDebugMenu` di `lib/app.dart`), bukan bagian produk.
Jangan dilaporkan sebagai temuan.

⚠ Data di emulator adalah data uji milik pemilik, disimpan di Hive lokal.
Jangan menghapus dompet/transaksi yang sudah ada. Kalau perlu data uji,
buat dompet baru bernama jelas (mis. "Dompet Uji UX") dan sebutkan di
laporan supaya pemilik bisa menghapusnya.

## 2. iOS Simulator (kalau diminta, atau Android tidak tersedia)

Folder `ios/` ada. Pakai tool simulator Claude Code (`attach` lebih dulu,
lalu build + `launch`, `screenshot`, `inspect`, `tap`) kalau tersedia di
sesi. Kalau tidak tersedia, pakai `flutter run -d <simulator>` dan
`xcrun simctl io booted screenshot "$SCRATCH/x.png"`.

## 3. Flutter Web (pilihan terakhir)

Hanya kalau tidak ada emulator maupun simulator. Platform `web` BUKAN bagian
repo, jadi ditambahkan sementara lalu dibuang lagi:

1. `flutter create . --platforms web`. Ini mengubah `.metadata` dan
   `analysis_options.yaml` (tracked), serta menambah `web/`, `.idea/`,
   `*.iml`, dan `test/widget_test.dart` (untracked).
2. `flutter build web --release`, lalu sajikan `build/web/` dengan server
   statis apa saja dan buka di browser pane bawaan (atau pakai
   `scripts/shoot.js` kalau Playwright tersedia — lihat header skripnya).
3. **Wajib dibuang sesudahnya:**
   ```bash
   git checkout -- .metadata analysis_options.yaml
   rm -rf web .idea *.iml test/widget_test.dart
   ```
   Pastikan `git status --short` bersih sebelum lanjut.

Render web CanvasKit tidak 100% identik dengan Android/iOS (font fallback,
scrollbar, keyboard numerik tidak muncul di desktop). Cukup untuk menilai
tata letak dan spacing, tidak cukup untuk hal yang spesifik platform. Sebut
keterbatasan ini di laporan kalau metode ini dipakai.
