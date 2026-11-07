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

## Ikon clay tambahan (31 Okt 2026, KT-DS5)

33 ikon baru digambar mengikuti resep di bawah, sehingga seluruh ikon benda
sudah clay (total 43 aset di `assets/icons_clay/`). Pemetaan `IconKey` ke
aset ada di `ClayIcons.forIcon`; pratinjau semuanya (terang dan gelap) di
[reference/icons-clay-sheet.html](reference/icons-clay-sheet.html). Gambar
dibuat dari kode, belum ditinjau perancang: perlakukan sebagai draf yang
bisa diganti per berkas tanpa mengubah kode.

| Kelompok | Aset |
|---|---|
| Dompet | `bank_wallet`, `cash_wallet`, `ewallet_wallet`, `piggy_savings`, `card_wallet` |
| Jenis transaksi | `income_arrow`, `expense_arrow` (transfer memakai `leaf_send`) |
| Kategori | `bowl_food`, `house_household`, `receipt_bills`, `tray_other`, `cap_education`, `bolt_electricity`, `shield_emergency`, `pump_fuel`, `basket_groceries`, `heart_health`, `wifi_internet`, `chart_investment`, `paw_pets`, `bag_shopping`, `family_people`, `heart_donation`, `star_bonus`, `gift_box` |
| Freelance dan status | `clipboard_worklog`, `clock_hourly`, `doc_invoice`, `check_completed`, `hourglass_pending`, `coin_paid`, `warning_overbudget`, `tray_empty` |

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

## Keputusan pemilik (30 Okt 2026)

- **KT-DS5: ikon clay menggantikan semuanya.** Ikon piksel `assets/icons/`
  (ADR-034) untuk kategori, dompet, transfer, dan Freelance diganti ikon
  clay. Acuan hanya menggambar 10; sisanya (kategori bawaan, dompet, dll.)
  perlu ilustrasi baru dengan resep di atas. Daftar ikon yang harus dibuat
  disusun saat T-25.6 dikerjakan, dari `lib/` dan `assets/icons/`.
- **KT-DS6: tile datar, hanya tombol Catat yang bertimbul.** Tile ikon
  memakai latar nada tipis + garis rambut 1px (seperti `DsIconTile` sekarang);
  kedalaman datang dari ikon clay. Tombol Catat di navigasi bawah tetap
  bulat 52px bergradasi dengan daun timbul, satu-satunya elemen bertimbul
  per layar. Kilap, bayangan dalam, dan gradasi tile di tabel "Resep gaya"
  **tidak dipakai** untuk tile; hanya untuk ikon dan tombol Catat.
- **KT-DS7: ikon tetap, tile ikut tema.** Warna ikon clay tertanam di SVG
  dan tidak berganti per preset atau mode. Warna latar tile diambil dari
  token kategori (`categories.*.container`) per mode, sehingga mode gelap
  tidak menyilaukan. Pemetaan warna hijau per preset (`ColorMapper`) ditunda
  sampai bentrok di preset pink terlihat mengganggu.
- **KT-DS8: "Scan Struk" tetap, "Kirim Daun" diganti arti.** Scan Struk
  adalah fitur yang direncanakan (tidak tampil sebelum fiturnya ada).
  "Kirim Daun" menjadi "Catat Transfer" sesuai glosarium ("mencatat, bukan
  melakukan"); ikon daunnya hanya gambar daun tanpa makna kirim, jadi
  dapat dipertahankan, atau digambar ulang bila terasa kurang mewakili
  transfer.

## Ikon peluncur (6 Nov 2026)

Ikon aplikasi memakai maskot `tanuki_mascot.svg` (versi acuan dengan
bayangan, tanpa urat daun yang terbaca seperti angka "7" di ukuran kecil)
dan koin daun `tier_coin.svg` di kanan bawah, di atas latar gradasi matcha
`#d9f5dd` → `primaryFixed` `#bdefc4` → `#94c99e` (direntangkan pada area tampak
72/108 dp, cahaya tengah tipis) dengan kilap di tepi atas.
Pengganti maskot piksel di latar terakota (ADR-015).

| Berkas (`assets/icon/`) | Dipakai untuk |
|---|---|
| `background.png` | Latar ikon adaptif Android |
| `foreground.png` | Latar depan adaptif, maskot di dalam lingkaran aman 66/108 dp (`adaptive_icon_foreground_inset: 0`) |
| `monochrome.png` | Ikon bertema Android 13+ (siluet, hanya alfa) |
| `icon.png` | Ikon Android lawas dan iOS (alfa dibuang) |
| `play_store_512.png` | Ikon resolusi tinggi listing Play, diunggah manual di Play Console |

Sumbernya SVG di `assets/icon/src/`, ditulis dan dirender oleh
`scripts/launcher_icon/build_launcher_icon.py` (macOS, QuickLook), lalu
`dart run flutter_launcher_icons`. Ubah rupa di skrip, bukan di SVG hasil.
QuickLook selalu meratakan ke latar putih, jadi berkas transparan
(`foreground`, `monochrome`, splash) dirender `render.py` dua kali, di atas
putih dan hitam, lalu alfanya dihitung dari selisihnya; jangan merender
berkas transparan langsung dengan `qlmanage`.
Selesai menjalankan generator, kembalikan `ios/Runner.xcodeproj/project.pbxproj`
bila ia mengganti `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`
menjadi `AppIcon` (bug generator; nilainya harus `YES`).

## Splash dan intro pembuka (6 Nov 2026)

Splash native Android (`flutter_native_splash`) menampilkan tanuki clay
**tanpa daun dan koin** di tengah latar `#DCF3E0` (gelap `#111412`), kotak
viewBox maskot 180 dp. Frame pertama `StartupIntro`
(`lib/app/startup/startup_intro.dart`) menggambar tubuh yang sama di posisi
dan ukuran yang sama, lalu memutar animasi "Daun mendarat" (dipilih pemilik
dari empat contoh): diam 120 ms sesudah frame pertama, daun melayang jatuh
ke kepala (150–950 ms), tubuh memantul saat daun mendarat (760–1100 ms),
koin daun meletup di kanan bawah (950–1400 ms), lalu memudar ke aplikasi
(1550–1900 ms). Aplikasi dibangun di bawahnya sejak awal; ketuk untuk
melompat ke akhir; dilewati saat gerak dikurangi dan saat boot ulang
sesudah pemulihan. `MainActivity` melepas splash Android 12+ tanpa animasi
keluar bawaan, karena pemudaran ikonnya membuat tanuki pucat sesaat.

| Berkas | Dipakai untuk |
|---|---|
| `assets/icon/splash.png` | Splash pra-Android 12 (720 px, dianggap 4x) |
| `assets/icon/splash_android12.png` | Ikon splash Android 12+ (kanvas 288 dp, latar ikon = latar splash supaya tidak ada lingkaran putih) |
| `assets/illustration/splash_tanuki_body.svg`, `splash_tanuki_leaf.svg` | Lapisan intro Flutter (viewBox 54) |
| `assets/icons_clay/tier_coin.svg` | Koin intro |

Semua dibangun `scripts/launcher_icon/build_splash.py`, lalu
`dart run flutter_native_splash:create`. Bayangan dibuang di gambar native
dan Flutter karena `flutter_svg` tidak mendukung `feDropShadow`; ukuran dan
warna di skrip harus sama dengan konstanta `StartupIntro`. Splash iOS belum
ada (B-12).

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
