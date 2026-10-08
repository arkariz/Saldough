# Desain Tanukonomy

Bahasa visual aplikasi diputuskan di
[ADR-034](../02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md).
Sumber kebenarannya dua artefak di akun pemilik; folder ini salinannya.

| Artefak | Salinan |
|---|---|
| [Tanukonomy Design System](https://claude.ai/artifact/HHq7YfEY5Wtc1JXtBhzBQS) | [`design-system/`](design-system/README.md) |
| [Tanukonomy Halaman Baru](https://claude.ai/artifact/L4176HPgR9gCXACe3gyRbZ) (prototipe 12 layar) | [`prototype/`](prototype/) |
| [Prototipe Rencana dan Rutin](https://claude.ai/artifact/PzQEmLqRBQM72YM6HhU7pS) (6 layar, fitur rutin dan perkiraan) | [`prototype-rencana/`](prototype-rencana/) |
| [Sampel Beranda](https://claude.ai/artifact/UHo61QLURngZRqFLPNd7Ko) (riwayat review) | tidak disalin |

## Untuk agen yang membuat atau mengubah UI

Pakai skill `tanukonomy-ui` (`.claude/skills/tanukonomy-ui/`). Ringkasnya:

1. Baca design system dari artefak dengan alat Artifact:
   `{"action": "read", "url": "https://claude.ai/artifact/HHq7YfEY5Wtc1JXtBhzBQS", "path": "project/README.md"}`,
   lalu `project/tokens.json` dan `project/components/<Komponen>/README.md`
   yang dibutuhkan. Artefak tidak terjangkau (sesi di luar akun pemilik,
   tanpa alat Artifact)? Baca salinan di `design-system/`.
2. Buka layar padanannya di prototipe (`prototype/<Layar>.dc.html`, atau
   artefaknya) sebelum menulis widget.
3. Ikuti `design-system/flutter.md` untuk nama token dan widget.

## Isi folder

- `design-system/README.md` — aturan pemakaian (brand book).
- `design-system/writing.md`, `patterns.md`, `flutter.md` — menulis, pola
  layar, implementasi Flutter.
- `design-system/tokens.json` — token terang dan gelap.
- `design-system/components/<Komponen>/` — panduan dan pratinjau HTML;
  `components/bundle.css` adalah gaya acuannya.
- `design-system/assets/` — catatan aset. Berkasnya sendiri ada di repo:
  ikon piksel `assets/icons/`, ilustrasi `assets/illustration/`.
- `prototype/*.dc.html` — layar prototipe (format kanvas Design; markup
  HTML biasa dengan kelas `tk-*` dari `bundle.css` dan variabel di
  `tokens.css`). `Main.dc.html` adalah Beranda.
- `prototype-rencana/*.dc.html` — tab Rencana dan rutin
  ([RECURRING_AND_FORECAST](../01-product/features/RECURRING_AND_FORECAST.md),
  [PLAN_TAB_LAYOUT](../01-product/features/PLAN_TAB_LAYOUT.md)).
  `Main.dc.html` adalah segmen Bulan ini, lalu `Rutin`, `Anggaran`,
  `RincianRutin`, `Beranda` (kartu Menunggu dicatat), dan `CatatUlangi`
  (bagian Ulangi di Catat). `tokens.css` sama dengan milik `prototype/`.
  Komponen yang belum masuk design system (sub-tab, kartu perkiraan
  bergaris putus, baris jadwal, grafik saldo tangga `fc-*`, bagian Ulangi)
  ada di `rencana.css`. Grafik Bulan ini menghitung saldo per hari di
  `renderVals()` dari jadwal rutin dan sebaran harian anggaran; angkanya
  contoh spec (hari ini 2 Okt 2026), saldo BCA hari ini Rp2.820.000 dan
  pengeluaran harian BCA dari sisa anggaran Belanja adalah anggapan
  prototipe.

## Menjaga salinan

Setiap perubahan pada artefak disalin ke sini dalam commit yang sama dengan
perubahan kodenya. Kalau isi salinan dan artefak berbeda, artefak yang
benar; perbarui salinan, jangan sebaliknya.
