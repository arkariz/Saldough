# PixelTheme jadi tema global aplikasi

## 1. Metadata

- **Decision ID:** ADR-031
- **Tanggal:** 2026-10-01
- **Fase roadmap:** Fase 8 (tindak lanjut pasca-MVP), T-8.10
- **Status:** Accepted (keputusan pemilik 1 Okt 2026); isi temanya diganti [ADR-034](0034-bahasa-visual-buku-catatan-piksel.md), mekanisme tema global tetap
- **Cakupan:** Global — `lib/app/app.dart`, `lib/core/theme/`, setiap titik
  yang sekarang memasang `PixelTheme(child: …)`
- **Mengubah:** cakupan [ADR-015](0015-adopsi-bahasa-visual-pixel-kas.md) dan
  [ADR-016](0016-revisi-palet-satu-peran-satu-warna.md) — dari "subtree
  `PixelTheme`" menjadi tema `MaterialApp`; alasan "tema pemanggil ditangkap"
  di [ADR-030](0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md)
  §3.3 butir 4 tidak lagi wajib (lihat §3.5)
- **Menghapus:** sisa terakhir [ADR-0006](0006-design-token-semantic-color-mapping.md)
  di kode (`AppTheme`, palet `AppColorsExtension.light`/`dark`, gaya
  `shout`/Bangers), yang sudah berstatus Superseded sejak ADR-013

## 2. Konteks

Bahasa visual pixel (ADR-015) masuk di Fase 2 sebagai pembungkus
`PixelTheme(child: …)`, bukan tema global, karena layar Saldough 1.0
(`cycle`, `card`, `investment`, `grocery`, `income`) masih ada dan harus
tetap memakai `AppTheme` (ADR-0006). Komentar `pixel_theme.dart` menyebutnya
sementara: "`AppTheme`… tetap tema global… sampai T-3.4/T-3.5 cutover".

Cutover Fase 3 sudah selesai; kode 1.0 sudah dihapus. Keadaan per 1 Okt 2026:

| # | Temuan | Bukti |
|---|---|---|
| P1 | `PixelTheme` dipasang ulang di **12 tempat**: shell, lapisan spotlight, enam modul rute (account, budget, freelance, record, transaction, wallet), dan empat halaman yang membuka rutenya sendiri (onboarding, kategori, template anggaran, proyek freelance). Setiap pintu masuk baru wajib ingat memasangnya; kalau lupa, layar itu diam-diam tampil dengan gaya 1.0. | `grep 'PixelTheme('` |
| P2 | `AppTheme` hanya dipakai sebagai `theme`/`darkTheme` `MaterialApp` dan di dua berkas uji. | `lib/app/app.dart:50` |
| P3 | Permukaan di luar subtree `PixelTheme` tetap bergaya 1.0: snackbar yang tidak memberi warna sendiri (mis. "tutorial direset" di `tutorial_info_button.dart`) dan menu pengembang di `app.dart`. | `ScaffoldMessenger` akar ada di atas `PixelTheme` |
| P4 | `AppTheme` memakai `google_fonts` (Archivo Black, Space Grotesk, Bangers) yang **mengunduh huruf saat peluncuran pertama** — panggilan jaringan yang tidak perlu, padahal huruf ADR-015 sudah dibundel lokal (`pubspec.yaml`, bagian `fonts:`). | `app_theme.dart` |
| P5 | `AppChip` — satu-satunya pemakai `AppTheme.shout` — tidak dipakai di mana pun. | `grep 'AppChip('` |
| P6 | `context.appColors` jatuh ke palet 1.0 `AppColorsExtension.light` kalau ekstensi tidak terpasang, jadi uji widget tanpa `PixelTheme` diam-diam menguji palet yang tidak dipakai aplikasi. | `app_colors_extension.dart:309` |
| P7 | `pushRoute` (ADR-030) dan lembar `go_router` harus menangkap tema pemanggil hanya karena tema pixel tidak ada di akar. | `route_navigation.dart` |

## 3. Keputusan

### 3.1 Satu tema di `MaterialApp`

`ThemeData` yang kini dibangun `PixelTheme._build` menjadi `theme` dan
`darkTheme` `MaterialApp.router`. Mode terang/gelap tetap mengikuti sistem
(perilaku sekarang: `PixelTheme` membaca `Theme.of(context).brightness`
dari `AppTheme`, yang dipilih `MaterialApp` menurut sistem).

`PixelTheme` berhenti menjadi widget dan menjadi penyusun tema:
`abstract final class PixelTheme { static ThemeData get light; static ThemeData get dark; }`.
Nama dipertahankan karena ADR-015/016 dan komentar kode sudah
memakainya. `PixelTypography` dan `kMinLabelSize` tetap di berkas yang sama.

### 3.2 Pembungkus dihapus

Ke-12 `PixelTheme(child: …)` dihapus. Tidak ada lagi `Theme(data: …)` yang
membungkus satu fitur atau satu rute; penimpaan tema lokal tetap boleh untuk
satu komponen (mis. warna satu tombol), bukan untuk seluruh layar.

### 3.3 Sisa ADR-0006 dihapus

- `AppTheme` (`lib/core/theme/app_theme.dart`) dihapus.
- Palet `AppColorsExtension.light`/`dark` dihapus; `pixelLight`/`pixelDark`
  tetap namanya. Cadangan `context.appColors` menjadi `pixelLight`.
- `AppChip` (tidak terpakai) dan gaya `shout`/Bangers dihapus.
- Dependensi `google_fonts` dihapus dari `pubspec.yaml`. Aplikasi tidak lagi
  mengunduh huruf; semua huruf berasal dari aset bundel.

### 3.4 Uji

- `pixel_theme_test` diganti: tema `SaldoughApp` membawa `pixelLight`/
  `pixelDark` sesuai kecerahan, dan rute yang dibuka tanpa pembungkus apa pun
  (lewat `pushRoute` dan `go_router`) memakai palet pixel.
- Uji widget yang membangun `MaterialApp` sendiri memakai `PixelTheme.light`
  bila warnanya penting; yang tidak memasang tema tetap mendapat palet pixel
  lewat cadangan `context.appColors`.

### 3.5 Tema pemanggil di rute

`capturedThemes` di `pushRoute` (ADR-030 §3.3 butir 4) dibiarkan: tidak
merugikan dan tetap benar bila kelak ada penimpaan tema lokal. Alasannya di
komentar kode diganti — bukan lagi "tanpanya lembar memakai tema global,
bukan `PixelTheme`". Lembar `go_router` (`_ModalSheetPage`) kini otomatis
benar karena tema global sudah pixel.

## 4. Opsi yang dipertimbangkan

| Opsi | Keterangan | Hasil |
|---|---|---|
| A. Biarkan dua tema | Tanpa kerja; P1, P3, P4, P6 tetap ada. | Ditolak |
| B. Isi `AppTheme` dengan tema pixel | Satu tema, nama lama. Nama `AppTheme` sudah melekat pada ADR-0006 (komik) di dokumen. | Ditolak |
| C. `PixelTheme` jadi penyusun tema global | Satu tema, nama sesuai ADR-015/016. | **Dipilih** |

## 5. Konsekuensi

**Positif:** satu sumber tema; layar baru tidak perlu ingat pembungkus;
snackbar dan menu pengembang ikut gaya pixel; satu panggilan jaringan
(unduhan huruf) dan satu dependensi hilang; uji widget menguji palet yang
sungguh dipakai.

**Yang berubah di layar:** snackbar tanpa warna sendiri dan menu pengembang
(hanya debug) berganti gaya. Layar lain tidak berubah, karena semuanya sudah
di bawah `PixelTheme`.

**Risiko:** layar yang selama ini kebetulan bergantung pada nilai `AppTheme`
(mis. `colorScheme.primary` hijau `income` 1.0, sekarang aksen pixel).
Mitigasi: cari pemakaian `colorScheme.` dan `Theme.of(context).` di luar
subtree yang dulu dibungkus, lalu cek di HP mode terang dan gelap.

## 6. Verifikasi

- `flutter analyze` bersih, seluruh uji lulus.
- Tidak ada lagi `PixelTheme(`, `AppTheme`, `GoogleFonts`, `AppColorsExtension.light`/`.dark` di `lib/`.
- Cek di HP, terang dan gelap: onboarding, Beranda, CATAT, lembar suara,
  rincian dompet, Akun → Kategori, template anggaran, proyek freelance,
  snackbar "tutorial direset", pemilih tanggal.
