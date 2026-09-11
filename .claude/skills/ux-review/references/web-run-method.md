# Metode cadangan: jalankan sebagai Flutter Web + screenshot

Pakai ini HANYA kalau checklist kode (lihat `checklist.md`, terutama
kategori E/F) menyisakan pertanyaan yang benar-benar butuh piksel
sungguhan — kontras warna terukur, teks yang mungkin overflow di lebar
sempit, atau pemilik minta lihat tampilannya langsung. Jangan jalankan ini
sebagai langkah baku tiap review.

Saldough HANYA menyasar Android dan iOS (`.claude/CLAUDE.md`) — platform
`web` TIDAK pernah jadi bagian permanen repo. Prosedur di bawah menambah
platform `web` SEMENTARA, lalu membuangnya lagi di langkah terakhir. Jangan
pernah commit berkas yang dihasilkan `flutter create . --platforms web`.

## Alat yang sudah dikonfirmasi ada di sandbox ini

- Flutter SDK mendukung `web` (`flutter config --list` menampilkan
  `--enable-web`; `flutter build web --release` berhasil pada codebase
  Saldough saat ini — dependensi git termasuk paket internal
  `advance-mobile-platform` tetap resolve untuk target web).
- Binary Chromium headless: `/opt/pw-browsers/chromium` (env
  `PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers` sudah diset).
- Paket `playwright` (versi 1.56.1) terpasang GLOBAL di
  `/opt/node22/lib/node_modules` — TIDAK ada di `node_modules` lokal
  proyek mana pun. Resolve-nya lewat env `NODE_PATH`, jangan `npm install
  playwright` di proyek (boros waktu, browsernya sudah ada, tidak perlu
  download ulang).
- Server statis global: `http-server`, `serve` (lewat `npx` atau
  langsung, keduanya ada di `npm ls -g`).

## Langkah

1. **Tambah platform web sementara** (dari root Saldough):
   ```bash
   flutter create . --platforms web
   ```
   Ini mengubah `.metadata` dan `analysis_options.yaml` (tracked) selain
   menambah `web/`, `.idea/`, `*.iml`, `test/widget_test.dart` (semuanya
   untracked). Simpan daftar ini — dibuang lagi di langkah 5.

2. **Build**:
   ```bash
   flutter build web --release
   ```
   Hasilnya di `build/web/`.

3. **Serve statis** di background, lalu catat port-nya:
   ```bash
   npx http-server build/web -p 8080 &
   ```

4. **Screenshot** dengan `scripts/shoot.js` (lihat isinya untuk opsi
   lengkap — `url` wajib, sisanya opsional):
   ```bash
   NODE_PATH=/opt/node22/lib/node_modules node \
     "$(dirname "$0")/../.claude/skills/ux-review/scripts/shoot.js" \
     --url http://localhost:8080 \
     --out /tmp/saldough-ux/01-dashboard.png \
     --width 390 --height 844 \
     --wait 1500
   ```
   Tab bottom-nav di `MainShellPage` BUKAN route terpisah (state index
   biasa, bukan `go_router`) — untuk memotret tab lain, tambahkan opsi
   `--click x,y` (ambil koordinat dari screenshot sebelumnya dulu, baru
   susulan klik). Layar yang dicapai lewat `context.push` (`/income/list`,
   dst) BISA langsung lewat `--url http://localhost:8080/#/income/list`
   karena itu rute `go_router` sungguhan.
   Setiap screenshot: baca hasilnya dengan tool `Read` (bisa baca gambar),
   JANGAN menebak dari nama berkas saja.

5. **Buang platform web** setelah selesai — WAJIB, supaya repo tetap
   Android/iOS saja:
   ```bash
   git checkout -- .metadata analysis_options.yaml
   rm -rf web .idea *.iml test/widget_test.dart
   ```
   Cek `git status --short` bersih (atau hanya berisi perubahan yang
   memang disengaja di luar eksperimen ini) sebelum lanjut.

## Batasan yang perlu disebut ke pemilik

Render web CanvasKit tidak 100% identik dengan render Android/iOS asli
(font fallback, scrollbar, keyboard numerik tidak tampil di browser
desktop). Cukup untuk menilai layout/kontras/spacing, TIDAK cukup untuk
menilai hal yang benar-benar platform-spesifik (haptic, gesture native,
keyboard bawaan). Sebut keterbatasan ini di laporan kalau metode ini
dipakai.
