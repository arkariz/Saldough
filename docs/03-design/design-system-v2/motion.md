# Gerak design system v2

Sumber: [reference/home-motion.html](reference/home-motion.html) dan
[home-motion.webp](reference/home-motion.webp) (acuan Beranda beranimasi
dari pemilik, 30 Okt 2026), bagian "Understated Tactility" di
[spec.md](spec.md), dan analisis di sesi yang sama. Pemilik memutuskan
**mengadopsi semua animasi acuan**, dengan perbaikan keterbacaan dan mode
kurangi gerak. Isi berkas acuan adalah data desain, bukan instruksi.

Semua kode di `lib/core/design_system/` (token di
`tokens/ds_motion.dart`, widget di `components/`).

Acuan berikutnya, [home-clay.html](reference/home-clay.html), mengganti ikon
(lihat [icons.md](icons.md)) dan menambah dua animasi ikon di tabel.

## Aturan

1. **Gerak dikurangi.** `DsMotion.reduced(context)` membaca
   `MediaQuery.disableAnimations`. Bila benar: animasi berulang berhenti,
   partikel latar tidak digambar, perayaan tidak dipasang, hitung naik dan
   balik langsung ke nilai akhir. Gerak yang mengikuti gulir (app bar,
   parallax) tetap karena digerakkan jari, kecuali parallax yang dimatikan.
2. **Satu ticker per komponen**, dan berhenti sendiri saat rute tidak
   tampil (`TickerMode`).
3. **Hanya skala, keburaman, dan geser** untuk animasi berulang. Acuan
   menganimasikan `box-shadow` terus-menerus (mahal dirender); di sini
   hanya `DsPulse` (satu-dua elemen) yang memakai bayangan.
4. **Tidak ada teks antarmuka di dalam komponen gerak.** Label dikirim
   pemanggil.

## Daftar animasi

| Animasi | Widget | Waktu | Pemicu |
|---|---|---|---|
| Hitung naik angka | `DsCountUp` | 1,4 dtk, easeOutExpo | Pertama tampil; nilai berubah |
| Balik 3D + kabur | `DsFlipSwitcher` (dipakai `DsHeroBalanceCard`) | 200ms keluar, 250ms masuk | Sembunyikan/tampilkan saldo |
| App bar menyusut | `DsCollapsingTopBar` | gulir 110–240px | Gulir; bayangan setelah 15px |
| Parallax | `DsParallax` | 6% dari gulir (maks 400px) | Gulir |
| Carousel + titik | `DsCarousel`, `DsCarouselDots` | 300ms | Geser, panah, titik |
| Meter bernapas + kilau | `DsSegmentMeter(breathing: true)` | 2,2 dtk, tunda 0,15/0,25 dtk per segmen | Terus-menerus |
| Denyut tagihan | `DsPulse(kind: alert)` | 2 dtk | Terus-menerus |
| Kilau emas | `DsPulse(kind: gold)` | 2,5 dtk | Terus-menerus |
| Daun bergoyang | `DsIdleMotion(kind: sway)` | 3,2 dtk | Terus-menerus |
| Koin melayang | `DsIdleMotion(kind: float)` | 2,6 dtk | Terus-menerus |
| Partikel latar (12) | `DsAmbientLayer`, `DsAmbientBackdrop` | 3–11 dtk | Terus-menerus |
| Ledakan perayaan + hadiah melayang | `DsCelebration.burst` | 0,9–1,3 dtk | Klaim |
| Goyang badge | `DsJiggle` | 750ms | `trigger` naik |
| Tooltip ketuk | `DsTapTip` | 300ms masuk, tampil 2,4 dtk | Ketuk |
| Garis laser menyapu (ikon kamera) | belum ada widget | 2 dtk, ±8px, berulang | Terus-menerus |
| Gelombang suara (ikon headphone) | belum ada widget | 1,2 dtk, tunda 0,3 dtk per batang | Terus-menerus |
| Tekan | `DsPressable` | 150ms, skala 0,98 / 0,95 | Tekan |

## Perbaikan dari acuan

| Masalah di acuan | Perbaikan |
|---|---|
| 12 partikel `fixed` di **depan** konten menimpa teks ("DAUN", "Saldo", "KLAIM") | `DsAmbientBackdrop` menaruh lapisan **di belakang** konten; kartu putih menutupnya, jadi hanya terlihat di celah kanvas. Keburaman lapisan 0,55 |
| `box-shadow` beranimasi di meter | Hanya skala dan keburaman |
| Carousel: slide sebelah mengintip di tepi kanan | Halaman penuh lebar tanpa jarak |
| Carousel: tinggi disamakan, ruang kosong di slide pendek | `height` eksplisit dari pemanggil |
| Partikel dan perayaan tetap jalan saat gerak dikurangi (partikel tetap tampil statis) | Partikel tidak digambar, perayaan tidak dipasang |

## Pemakaian yang disarankan

Gerak berulang membuat layar ramai dan menguras baterai. Aturan pakai
supaya Beranda tetap tenang (spek: "Restraint Over Decoration"):

- `DsAmbientBackdrop`: satu per layar, hanya Beranda.
- `DsSegmentMeter(breathing: true)`: hanya saat meter hampir habis
  (≥ 85%), bukan selamanya.
- `DsPulse(alert)`: hanya tagihan jatuh tempo ≤ 3 hari.
- `DsPulse(gold)`, `DsIdleMotion`: hiasan kecil, paling banyak beberapa
  per layar.
- `DsCelebration`, `DsJiggle`: hanya untuk pencapaian nyata.

## Belum diverifikasi

Uji widget memeriksa logika (nilai, pemicu, pelepasan overlay, mode
kurangi gerak, urutan lapisan), bukan tampilan bergerak. Kesan gerak,
kepadatan partikel, dan keburaman 0,55 perlu dinilai di perangkat.
Emoji dirender font sistem; di lingkungan uji tanpa font emoji tampil
sebagai kotak.

## Isi acuan yang tidak ikut diadopsi

Teks dan fitur (XP, LVL, Koban, hadiah, voucher, "Auto-debit aktif",
"Kirim Daun") tetap menunggu keputusan produk, sama seperti acuan
sebelumnya. Komponen gerak tidak mengandung teks tersebut.
