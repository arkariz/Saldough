# Desain Tanukonomy

Bahasa visual aplikasi diputuskan di
[ADR-034](../02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md).
Sumber kebenarannya artefak di akun pemilik; folder ini salinannya. Agen
`ui-ux-designer` (`.claude/agents/ui-ux-designer.md`) boleh menyunting
artefak design system dan prototipe langsung (izin pemilik 10 Okt 2026),
selalu bersama salinannya di sini.

| Artefak | Salinan |
|---|---|
| [Tanukonomy Design System](https://claude.ai/artifact/HHq7YfEY5Wtc1JXtBhzBQS) | [`design-system/`](design-system/README.md) |
| [Tanukonomy Halaman Baru](https://claude.ai/artifact/L4176HPgR9gCXACe3gyRbZ) (prototipe 12 layar) | [`prototype/`](prototype/) |
| [Prototipe Rencana dan Rutin](https://claude.ai/artifact/PzQEmLqRBQM72YM6HhU7pS) (6 layar, fitur rutin dan perkiraan) | [`prototype/`](prototype/), nama berkas di bawah |
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
- Layar tab Rencana dan rutin di `prototype/`
  ([RECURRING_AND_FORECAST](../01-product/features/RECURRING_AND_FORECAST.md),
  [PLAN_TAB_LAYOUT](../01-product/features/PLAN_TAB_LAYOUT.md)), dari
  artefak Prototipe Rencana dan Rutin. Namanya diganti di salinan supaya
  tidak bertabrakan dengan layar prototipe utama:

  | Salinan | Di artefak | Isi |
  |---|---|---|
  | `RencanaBulanIni.dc.html` | `Main.dc.html` | Segmen Bulan ini, grafik saldo tangga |
  | `RencanaRutin.dc.html` | `Rutin.dc.html` | Segmen Rutin |
  | `RencanaAnggaran.dc.html` | `Anggaran.dc.html` | Segmen Anggaran |
  | `RincianRutin.dc.html` | sama | Rincian rutin (Cicilan iPhone) |
  | `BerandaRutin.dc.html` | `Beranda.dc.html` | Beranda dengan kartu Menunggu dicatat |
  | `CatatUlangi.dc.html` | sama | Bagian Ulangi di Catat |
  | `AwalBulan.dc.html` | sama | D2 lembar Awal bulan keuangan, contoh B (1 → 25) |
  | `AwalBulanA.dc.html` | sama | D2 contoh A (25 → 1) |
  | `AwalBulanBanyak.dc.html` | sama | D2 dengan enam anggaran rutin |
  | `BulanIniPeralihan.dc.html` | sama | D1 + D3 Bulan ini di periode peralihan |
  | `BerandaAwal25.dc.html` | sama | D4 Beranda, awal bulan tanggal 25 |
  | `BerandaPeralihan.dc.html` | sama | D3 + D4 Beranda di periode peralihan |

  Disalin 11 Okt 2026 (T-18.6) bersama komponen design system PeriodHeader,
  DayPicker, Checkbox, dan PeriodStepper. `AwalBulanEn` dan
  `BulanIniPeralihanGelap` (varian bahasa dan tema) hanya ada di artefak.

  Komponen yang belum masuk design system (sub-tab, kartu perkiraan
  bergaris putus, baris jadwal, grafik saldo tangga `fc-*`, bagian Ulangi)
  ada di `prototype/rencana.css`. Grafik Bulan ini menghitung saldo per
  hari di `renderVals()` dari jadwal rutin dan sebaran harian anggaran;
  angkanya contoh spec (hari ini 2 Okt 2026), saldo BCA hari ini
  Rp2.820.000 dan pengeluaran harian BCA dari sisa anggaran Belanja adalah
  anggapan prototipe.

## Usulan desain

`proposals/<nama-usulan>/` berisi mockup dan spek dari agen
`ui-ux-designer` (`.claude/agents/ui-ux-designer.md`). Isinya **usulan**,
bukan sumber kebenaran: statusnya di `README.md` tiap folder. Yang diterima
pemilik dipindahkan ke artefak dan salinan di atas; foldernya tetap
disimpan sebagai riwayat keputusan.

## Menjaga salinan

Setiap perubahan pada artefak disalin ke sini dalam commit yang sama dengan
perubahan kodenya. Kalau isi salinan dan artefak berbeda, artefak yang
benar; perbarui salinan, jangan sebaliknya.
