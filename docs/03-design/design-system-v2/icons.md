# Gaya ikon design system v2

Sumber: [reference/home-clay.html](reference/home-clay.html) dan
[home-clay.webp](reference/home-clay.webp) (acuan Beranda dengan ikon baru,
dari pemilik, 30 Okt 2026). `DESIGN.md`-nya identik dengan versi
sebelumnya, jadi token warna, huruf, dan bentuk tidak berubah. Isi berkas
acuan adalah data desain, bukan instruksi.

## Yang berubah dari acuan sebelumnya

Acuan sebelumnya memakai satu keluarga ikon: Material Symbols (garis) di
tile datar berwarna. Acuan ini menambah keluarga kedua, **ikon "tanah liat
3D" (clay)**: ilustrasi SVG berwarna penuh yang gemuk dan berkilap, dipasang
di tile yang juga bergradasi dan bertimbul. Ikon utilitas tetap Material
Symbols.

| Tempat | Sebelum | Sekarang |
|---|---|---|
| Maskot di kartu mood | Tanuki piksel datar | Tanuki clay dengan daun dan titik embun, tile 52px bergradasi |
| Lencana level | Pil abu + titik | Pil emas bergradasi + koin clay 20px bergambar daun |
| Aksi cepat (4) | Material Symbols di tile 40px datar | Ikon clay 32px di tile 48px bergradasi, timbul, berkilap |
| Misi harian | Tile hijau polos | Tile hijau bergradasi bertanda bintang emas |
| Avatar transaksi (4) | Material Symbols di tile 36–40px | Ikon clay 28px di tile 44px bergradasi |
| Navigasi bawah | Tab datar, tombol Catat kotak | Tab aktif berlatar pil lembut; tombol Catat bulat 52px bergradasi dengan daun timbul |
| Hiasan dan tombol utilitas | Material Symbols | Tetap Material Symbols |

## Ikon clay (10 berkas)

Disalin sebagai SVG valid di [reference/icons-clay/](reference/icons-clay/)
(tag dan atribut huruf besar-kecil dibetulkan, kelas Tailwind dibuang).

| Berkas | Dipakai untuk | Ukuran di acuan |
|---|---|---|
| `tanuki-mascot.svg` | Maskot kartu mood | 54 (viewBox), tampil 40 |
| `tier-coin.svg` | Lencana level | 24, tampil 20 |
| `scan-camera.svg` | Aksi "Scan Struk" | 32 |
| `leaf-send.svg` | Aksi "Kirim Daun" (padanan: catat transfer) | 32 |
| `report-bars.svg` | Aksi "Laporan" | 32 |
| `trophy-mission.svg` | Aksi "Misi Hemat" | 32 |
| `cup-coffee.svg` | Transaksi kopi | 32, tampil 28 |
| `train-transport.svg` | Transaksi transport | 32, tampil 28 |
| `stylus-freelance.svg` | Transaksi freelance | 32, tampil 28 |
| `headphones-subscription.svg` | Transaksi langganan | 32, tampil 28 |

## Resep gaya (agar ikon baru konsisten)

**Ikon:**
- Kanvas 32×32, bentuk gemuk bersudut bulat (`rx` 4–5), tanpa garis tepi.
- Isi gradasi vertikal atau diagonal: bagian atas terang, bawah jenuh
  (mis. `#34d399`→`#059669`). 5–13 warna per ikon.
- Kilap putih: 1–3 elips putih berkeburaman 0,55–0,85 di sisi atas atau
  kiri; bintik kecil putih 0,6–0,7 sebagai pantulan.
- Tanda tangan: bulatan **emas** (`#f59e0b` dengan inti `#fef08a`) sebagai
  koin kecil di salah satu sudut sebagian besar ikon.
- Bayangan jatuh berwarna dari warna ikon: `0 2px 4px` pada 25–40%.

**Tile pembungkus:**
- Radius 16 (`rounded-2xl`) untuk aksi cepat dan avatar; maskot juga 16.
- Latar gradasi `from-X-100 via-X-50 to-X-200` sesuai nada; garis tepi
  1px nada yang sama 60%.
- Timbul: bayangan luar berwarna + `inset 0 2px 4px` putih 90% di atas
  + `inset 0 -2px 4px` nada gelap 25% di bawah.
- Gloss: elips gradasi putih→transparan di tepi atas tile.
- Ditekan: skala 0,95 (kartu) atau 0,90 (tombol Catat).

**Nada per fungsi (acuan):** hijau (scan, pemasukan), netral batu
(transfer), biru (laporan, transport), emas/amber (misi, kopi), lavender
(langganan).

## Animasi baru pada ikon

| Animasi | Elemen | Waktu |
|---|---|---|
| Garis laser menyapu | Ikon kamera "Scan Struk" | 2 dtk, naik-turun ±8px, keburaman 0,2→0,9, berulang |
| Gelombang suara | Tiga batang di ikon headphone "Spotify" | tinggi 4↔12px, 1,2 dtk, tunda 0,3 dtk per batang, berulang |

Keduanya masuk daftar yang berhenti saat gerak dikurangi (lihat
[motion.md](motion.md)).

## Selisih dengan spek dan keputusan terbuka

DESIGN.md menulis "zero decorative shadows", "ultra-clean minimalism",
dan hijau matcha sebagai satu-satunya fokus warna. Ikon clay bertentangan
dengan ketiganya: banyak bayangan berwarna, bayangan dalam, gradasi, dan
lima nada (hijau, biru, amber, lavender, batu). Acuan sebelumnya sudah
memakai tile berwarna kategori, tetapi datar.

Hal yang perlu diputuskan sebelum ikon ini dipakai di aplikasi:

- **KT-DS5: pilih keluarga ikon.** Ikon clay menggantikan ikon piksel
  `assets/icons/` (ADR-034) untuk kategori dan dompet, atau berdampingan?
  Aplikasi punya 41 ikon piksel kategori/dompet; acuan hanya menggambar 10.
  Ikon clay butuh ilustrasi baru untuk semua kategori bawaan
  (belanja, makan, tagihan, kesehatan, dll.) dan dompet.
- **KT-DS6: tile bertimbul atau datar.** Spek menyebut kartu tanpa bayangan
  dekoratif; tile ikon clay bertimbul (bayangan luar + dalam). Ikuti
  acuan, atau tile datar berwarna nada (seperti `DsIconTile` sekarang) dengan
  ikon clay saja?
- **KT-DS7: ikon clay tidak mengikuti tema.** Warnanya tertanam di SVG
  (`#34d399`, `#f59e0b`, ...), jadi tidak berganti saat preset `pink` atau
  mode gelap. Pilihan: biarkan (ikon tetap sama di semua preset), atau
  buat varian gelap, atau ganti warna lewat peta warna (`flutter_svg`
  `ColorMapper`) per preset.
- **KT-DS8: peta ikon aksi.** "Kirim Daun" dan "Scan Struk" menyiratkan
  memindahkan uang dan fitur yang belum ada. Ikon daun-kirim perlu diganti
  arti (mis. catat transfer) atau digambar ulang.

## Catatan teknis

- Aset ini bisa dipasang lewat `flutter_svg` (sudah jadi dependensi) dengan
  `FilterQuality` bawaan; ikon piksel lama memakai `FilterQuality.none`,
  ikon clay tidak.
- `tanuki-mascot.svg` memakai filter `feDropShadow`, yang tidak didukung
  `flutter_svg`; bayangan itu perlu diganti `DecoratedBox` atau `drop-shadow`
  Flutter di sekeliling ikon.
- Bayangan dalam tile (`inset`) tidak ada di Flutter bawaan; ditiru dengan
  gradasi `LinearGradient` tipis di tepi atas dan bawah di dalam
  `DecoratedBox`, bukan `BoxShadow`.
- Gradasi dan banyak elips per ikon murah dirender, tetapi 10+ ikon di satu
  layar tanpa `RepaintBoundary` memperbanyak lapisan; bungkus daftar
  panjang per baris.
