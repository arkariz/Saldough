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

## Penemuan fitur (Fase 21, T-21.0)

Rupa dua langkah onboarding wajib (tanggal gajian, pengingat) dengan baris
informasi Catat dari notifikasi di penutup, widget Kotak masuk
notifikasi (satu widget, banyak keadaan, termasuk Nyalakan dan Kelola
aplikasi & pola) dan kartu pengingat di Beranda (gambar pilihan pemilik),
Mulai cepat, status di Akun, kepala periode dapat
diketuk, dan tawaran gajian. Spek di
[design-system/patterns.md](design-system/patterns.md) bagian "Penemuan
fitur"; komponen `OnboardingStep`, `FeatureNudge`, `InboxCard`,
`PaydayOffer`, dan `PeriodHeader` (diubah) di `design-system/components/`.
Papan di prototipe 12 layar: `OnbLangkah` (awal periode),
`OnbPeriode25EnGelap`, `OnbPengingat`, `OnbPengingatNyala`,
`OnbPengingatIzinEnGelap`, `OnbPenutup`, `OnbPenutupEnGelap`,
`OnbPenutupIos`; `BerandaTombol`, `BerandaTombolIzin`, `BerandaNotifAktif`,
`BerandaNotifAktifKosong`, `BerandaNotifMati` (satu widget Kotak masuk
notifikasi dengan lima keadaan), `BerandaTombolSatu` (iOS),
`BerandaTombolUrutan`, `TombolPermanen` (+ `EnGelap`, spesimen keadaan); `MulaiCepat`, `MulaiCepatTanpaAplikasi`,
`MulaiCepatIzinEnGelap`; `KotakMasuk` (tautan Kelola, Ajari pola) dan
`KotakMasukKosong`; `AkunStatusIzin`, `AkunStatusKeadaan` (+ `EnGelap`).
Papan di prototipe Rencana dan Rutin (nama salinan sama dengan nama
artefak): `BulanIniTawaran` (+ `Gelap`), `RutinPengingat`,
`RutinPengingatIzin`, `RincianRutinPengingat`, `RincianRutinPengingatIzin`,
`BerandaTombolMenunggu`. Selisih dan pertanyaan untuk PO di entri T-21.0
`TASK_LIST.md`.

## Analisis keuangan (Fase 19)

Layar Riwayat › Analisis dan Rincian kategori
([FINANCIAL_ANALYSIS](../01-product/features/FINANCIAL_ANALYSIS.md)), dari
artefak Tanukonomy Halaman Baru; disalin 15 Okt 2026 bersama komponen design
system DonutChart, LegendRow, TrendChart, SubTabs, dan PeriodStepper
(`bundle.css`, `patterns.md`, `writing.md`, dan `flutter.md` ikut diperbarui).

| Salinan | Isi |
|---|---|
| `Riwayat.dc.html` | A1 sub-tab Daftar \| Analisis, PeriodStepper, ringkasan Pemasukan/Pengeluaran |
| `Analisis.dc.html` | A2 Analisis September (contoh §10); berkas utama, varian di bawah memanggilnya dengan properti |
| `AnalisisOktober`, `AnalisisTrenAgustus` | Periode berjalan s.d. tanggal 10; kolom tren Agustus terpilih |
| `AnalisisPeralihan` (+`EnGelap`) | D3 periode peralihan 1 – 24 Okt, tanpa pembanding dan sorotan |
| `AnalisisPilihMakan`, `AnalisisPilihTanpaKategori` | Kategori terpilih di donat; Tanpa kategori memilih "Beri kategori" |
| `AnalisisDompet`, `AnalisisSembunyi` | Satu dompet (Transfer masuk/keluar); nominal disembunyikan |
| `AnalisisKosong`, `AnalisisSatuBulan`, `AnalisisTanpaPengeluaran`, `AnalisisMemuat`, `AnalisisGalat` | A4 keadaan |
| `AnalisisEnGelap` | Contoh en dan gelap |
| `RincianKategori.dc.html` (+`Agustus`, `Arsip`, `Baru`, `EnGelap`) | A3 Rincian kategori Makan; kolom tren terpilih, diarsipkan + tersembunyi, baru bulan ini |
| `RincianTransaksi.dc.html` | Tujuan baris transaksi di Rincian kategori |
| `BerandaRutin.dc.html` | D4 kartu Arus: pasangan Pemasukan/Pengeluaran sebagai pintu (`tk-card__door`) |
| `KilasBalik.dc.html` | A5 lembar kilas balik dengan tautan "Lihat rincian September" |

Rupa Fase 20 (UpdateCard, ReleaseNotes) ikut masuk `bundle.css` tetapi
komponen dan prototipenya belum disalin ke sini.

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
