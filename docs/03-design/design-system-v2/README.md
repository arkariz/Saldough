# Design system v2 (Tanukonomy Matcha)

**Status:** fondasi selesai 29 Okt 2026, **belum dipasang** ke aplikasi.
Keputusan ada di [ADR-043](../../02-architecture/adr/0043-design-system-v2-dan-preset-tema.md) (Proposed).

Ini design system pengganti untuk rombak UI. Ia berdampingan dengan design
system lama (`../design-system/`, ADR-034) dan tidak mengubahnya. Aplikasi
masih memakai `PixelTheme` sampai pemilik memutuskan pemasangan. Widget
komponennya sudah ada di `lib/core/design_system/components/`, tetapi belum
dipakai layar mana pun.

Spek sebelumnya (Autumn Kyoto Ledger, 29 Okt 2026) diganti pemilik pada hari
yang sama dengan spek ini; isinya masih ada di riwayat git.

| Berkas | Isi |
|---|---|
| [spec.md](spec.md) | Spek pemilik "Tanukonomy" (DESIGN.md dari Stitch), disalin apa adanya |
| [reference/home.html](reference/home.html), [home.png](reference/home.png) | Referensi komponen: layar Beranda dari pemilik |
| [components.md](components.md) | Pemetaan setiap komponen referensi ke token dan widget-nya, beserta varian dan selisihnya |
| [reference/render-light.png](reference/render-light.png), [render-dark.png](reference/render-dark.png) | Layar Beranda dirakit dari widget design system v2 |
| [tokens.json](tokens.json) | Token dalam bentuk data: warna per preset (terang/gelap), tipografi, radius, jarak, elevasi, gerak |
| README.md (ini) | Penerapan di Flutter, cara menambah preset, selisih, keputusan terbuka |

## Kode

Semua kode ada di `lib/core/design_system/` dan diimpor hanya lewat
`package:saldough/core/design_system/design_system.dart`. Nama memakai
prefiks `Ds` supaya tidak bentrok dengan token lama. Jangan mencampur token
lama dan baru di satu widget.

| Berkas | Isi |
|---|---|
| `color/ds_color_scheme.dart` | `DsColorScheme` (`ThemeExtension`), `DsCategoryColors`, `DsColorPair` |
| `typography/ds_fonts.dart` | `DsFonts.sans` Plus Jakarta Sans, `DsFonts.pixel` Space Mono Bold |
| `typography/ds_typography.dart` | `DsTypography` (`ThemeExtension`), `dsTextStyle()` |
| `tokens/ds_radius.dart`, `ds_shapes.dart` | Radius spek; bentuk siap pakai `micro`, `badge`, `control`, `tile`, `card`, `overlay`, `sheet`, `pill`, `circle` |
| `tokens/ds_spacing.dart` | Jarak, margin/gutter per lebar, breakpoint, target sentuh 44 |
| `tokens/ds_elevation.dart` | `DsElevation`: `canvas`, `card`, `overlay` (`DsSurfaceTier` + `decoration()`) |
| `tokens/ds_motion.dart`, `ds_opacity.dart` | Transisi 150ms ease-out, skala tekan; tingkat keburaman |
| `components/` | Widget komponen (lihat [components.md](components.md)) |
| `presets/` | `DsThemePreset`, registri `DsThemePresets`, preset `matcha` |
| `ds_theme.dart` | `DsTheme.build(preset, brightness)` (di-cache), `DsTheme.light/dark`, `context.ds` |

Contoh pemakaian token langsung (untuk layar yang butuh lebih dari
komponen):

```dart
final ds = context.ds;
DecoratedBox(
  decoration: ds.elevation.card.decoration(),
  child: Text('+Rp 1.500.000', style: ds.typography.pixelAmount.copyWith(color: ds.colors.income)),
);
```

## Menambah preset tema

Preset hanya membawa **warna** terang dan gelap. Huruf, sudut, jarak, dan
elevasi berlaku global.

1. Salin `lib/core/design_system/presets/matcha.dart` menjadi
   `presets/<nama>.dart`. Ganti `id` (`snake_case`, jangan diganti setelah
   dirilis), `name`, dan nilai kedua `DsColorScheme`. Semua field wajib
   diisi, jadi kompilator menolak preset yang bolong.
2. Tambahkan preset ke `DsThemePresets.all` dan ekspor berkasnya dari
   `design_system.dart`.
3. Jalankan uji di `test/core/design_system/`.
   `ds_theme_presets_test.dart` otomatis memeriksa setiap preset: id unik,
   kontras pasangan teks dan latar, warna kategori di wadahnya, dan latar
   yang buram.
4. Perbarui bagian `presets` di `tokens.json`.

Spek dari Stitch memakai peran Material 3 yang namanya sama dengan field
`DsColorScheme`. Yang perlu dirancang sendiri hanya peran semantik di
kelompok bawah tabel Warna.

Bagian berikut dikerjakan saat pemasangan (T-24.3): label preset untuk
pengguna (i18n `appearance.presets.<id>`), penyimpanan pilihan preset dan
mode (Terang/Gelap/Ikuti sistem), dan baris pemilihnya di Akun. Pemilih
preset baru tampil kalau preset ada dua atau lebih.

## Preset yang tersedia

| id | Warna utama | Catatan |
|---|---|---|
| `matcha` | hijau hutan `#1F4B2C` | Bawaan; spek pemilik |
| `pink` | pink `#BE185D` (terang), `#F9A8C9` (gelap) | Diturunkan dari `matcha`: peran hijau diganti pink, netral beronce pink tipis, pemasukan tetap hijau |

## Warna

Kelompok pertama berisi peran Material 3 dari frontmatter spek. Kelompok
lain berisi peran semantik dari prosa spek dan dari referensi `home.html`.
Kelompok "Keuangan dan status" serta kategori tidak ada di spek dan
dirancang sendiri.

| Field Dart | Peran | Terang | Gelap |
|---|---|---|---|
| **Peran Material 3 (frontmatter DESIGN.md)** | | | |
| `surface` | Permukaan dasar Material. | `#f9f9f8` | `#111412` |
| `surfaceDim` | Permukaan paling redup. | `#dadad9` | `#111412` |
| `surfaceBright` | Permukaan paling terang. | `#f9f9f8` | `#373a37` |
| `surfaceContainerLowest` | Wadah terendah. | `#ffffff` | `#0c0f0d` |
| `surfaceContainerLow` | Wadah rendah. | `#f3f4f3` | `#191c1a` |
| `surfaceContainer` | Wadah standar Material. | `#eeeeed` | `#1d201e` |
| `surfaceContainerHigh` | Wadah tinggi: segmen meter kosong. | `#e8e8e7` | `#282b28` |
| `surfaceContainerHighest` | Wadah tertinggi. | `#e2e2e2` | `#323633` |
| `onSurface` | Teks Material di atas surface. | `#1a1c1c` | `#e2e3df` |
| `onSurfaceVariant` | Teks Material varian. | `#414941` | `#c1c9bf` |
| `inverseSurface` | Permukaan terbalik: snackbar. | `#2f3130` | `#e2e3df` |
| `inverseOnSurface` | Teks di atas inverseSurface. | `#f1f1f0` | `#2f3130` |
| `outline` | Garis Material yang wajib terlihat (3:1). | `#727971` | `#8b938a` |
| `outlineVariant` | Garis Material varian. | `#c1c9bf` | `#414941` |
| `surfaceTint` | Rona permukaan Material (tidak dipakai untuk elevasi). | `#3c6846` | `#a2d2a9` |
| `primary` | Hijau hutan pekat Material. | `#043417` | `#a2d2a9` |
| `onPrimary` | Teks di atas primary. | `#ffffff` | `#00391a` |
| `primaryContainer` | Hijau matcha hutan (#1F4B2C), nada utama merek. | `#1f4b2c` | `#244f30` |
| `onPrimaryContainer` | Teks di atas primaryContainer. | `#ffffff` | `#bdefc4` |
| `inversePrimary` | Primer di atas inverseSurface. | `#a2d2a9` | `#3c6846` |
| `secondary` | Sage gelap. | `#54615a` | `#bccac0` |
| `onSecondary` | Teks di atas secondary. | `#ffffff` | `#27332c` |
| `secondaryContainer` | Sage lembut. | `#d8e6dc` | `#3d4a42` |
| `onSecondaryContainer` | Teks di atas secondaryContainer. | `#24322b` | `#d8e6dc` |
| `tertiary` | Arang hangat. | `#2f2c25` | `#ccc6bb` |
| `onTertiary` | Teks di atas tertiary. | `#ffffff` | `#333028` |
| `tertiaryContainer` | Wadah tersier. | `#46423a` | `#4a463f` |
| `onTertiaryContainer` | Teks di atas tertiaryContainer. | `#e8e2d7` | `#e8e2d7` |
| `error` | Galat dan tindakan hapus. | `#ba1a1a` | `#ffb4ab` |
| `onError` | Teks di atas error. | `#ffffff` | `#690005` |
| `errorContainer` | Latar banner dan badge galat. | `#ffdad6` | `#93000a` |
| `onErrorContainer` | Teks di atas errorContainer. | `#93000a` | `#ffdad6` |
| `primaryFixed` | Primer tetap (sama di kedua mode). | `#bdefc4` | `#bdefc4` |
| `primaryFixedDim` | Primer tetap redup. | `#a2d2a9` | `#a2d2a9` |
| `onPrimaryFixed` | Teks di atas primaryFixed. | `#00210c` | `#00210c` |
| `onPrimaryFixedVariant` | Teks varian di atas primaryFixed. | `#244f30` | `#244f30` |
| `secondaryFixed` | Sekunder tetap. | `#d8e6dc` | `#d8e6dc` |
| `secondaryFixedDim` | Sekunder tetap redup. | `#bccac0` | `#bccac0` |
| `onSecondaryFixed` | Teks di atas secondaryFixed. | `#121e18` | `#121e18` |
| `onSecondaryFixedVariant` | Teks varian di atas secondaryFixed. | `#3d4a42` | `#3d4a42` |
| `tertiaryFixed` | Tersier tetap. | `#e8e2d7` | `#e8e2d7` |
| `tertiaryFixedDim` | Tersier tetap redup. | `#ccc6bb` | `#ccc6bb` |
| `onTertiaryFixed` | Teks di atas tertiaryFixed. | `#1e1b15` | `#1e1b15` |
| `onTertiaryFixedVariant` | Teks varian di atas tertiaryFixed. | `#4a463f` | `#4a463f` |
| `background` | Latar Material. | `#f9f9f8` | `#111412` |
| `onBackground` | Teks di atas background. | `#1a1c1c` | `#e2e3df` |
| `surfaceVariant` | Permukaan varian Material. | `#e2e2e2` | `#414941` |
| **Permukaan, teks, dan garis (prosa DESIGN.md)** | | | |
| `surfaceCanvas` | Kanvas kabut hangat: latar halaman (tier 0). | `#fafaf9` | `#0f1210` |
| `surfaceCard` | Kartu, baris daftar, kolom input (tier 1). | `#ffffff` | `#171b18` |
| `surfaceOverlay` | Popover, dialog, sheet (tier 2). | `#ffffff` | `#1d221e` |
| `surfaceHover` | Isi tipis saat baris atau kartu ditekan/aktif. | `#f4f6f4` | `#222823` |
| `surfaceSunken` | Wadah cekung: track kontrol segmen, tile ikon netral, tag kategori. | `#f3f4f6` | `#1a1e1b` |
| `textPrimary` | Teks utama dan nominal pengeluaran. | `#111827` | `#eef1ee` |
| `textSecondary` | Teks pendukung: subjudul, keterangan. | `#4b5563` | `#b8c0ba` |
| `textMuted` | Keterangan dan jam di baris transaksi, kaki kartu (KT-DS2). Hanya di kartu dan kanvas; di wadah cekung pakai textSecondary. | `#6b7280` | `#9aa29c` |
| `textTertiary` | Teks tersier: placeholder, simbol mata uang di kolom nominal. Bukan untuk teks wajib baca. | `#9ca3af` | `#858d87` |
| `outlineSubtle` | Garis rambut 1px: bingkai kartu, pemisah baris, kolom input. | `#eaecef` | `#2a302c` |
| `outlineOverlay` | Bingkai popover, dialog, sheet. | `#e2e5e9` | `#333a35` |
| `outlineStrong` | Bingkai checkbox dan tombol sekunder ditekan. | `#d1d5db` | `#4a524c` |
| `outlineFocus` | Cincin fokus 1px dan bingkai aktif. | `#1f4b2c` | `#a2d2a9` |
| **Tindakan** | | | |
| `actionPrimary` | Isi tombol utama dan tombol Catat. | `#1f4b2c` | `#a2d2a9` |
| `actionPrimaryPressed` | Tombol utama ditekan. | `#163720` | `#bdefc4` |
| `onActionPrimary` | Teks dan ikon di atas actionPrimary. | `#ffffff` | `#00210c` |
| `actionSecondary` | Isi tombol sekunder. | `#ffffff` | `#171b18` |
| `actionSecondaryPressed` | Tombol sekunder ditekan. | `#f8f9fa` | `#222823` |
| `onActionSecondary` | Teks tombol sekunder. | `#111827` | `#eef1ee` |
| `actionGhost` | Teks tombol hantu. | `#4b5563` | `#b8c0ba` |
| `actionGhostPressed` | Isi tombol hantu ditekan. | `#f3f4f6` | `#222823` |
| **Kartu saldo hero (code.html)** | | | |
| `heroSurface` | Latar kartu saldo hijau hutan. | `#1f4b2c` | `#1f4b2c` |
| `heroBorder` | Bingkai kartu saldo. | `#1d4a33` | `#2f6b45` |
| `heroGlow` | Cahaya sekitar di sudut kartu saldo (dipakai dengan alfa rendah). | `#10b981` | `#10b981` |
| `onHero` | Teks dan nominal di kartu saldo. | `#ffffff` | `#ffffff` |
| `onHeroMuted` | Label dan keterangan di kartu saldo. | `#b3dfc5` | `#b3dfc5` |
| `heroAccent` | Prefiks mata uang dan ikon aksen di kartu saldo. | `#6ee7b7` | `#6ee7b7` |
| `heroTile` | Kotak statistik di kartu saldo (putih 8%). | `#14ffffff` | `#14ffffff` |
| `heroActionSecondary` | Tombol kedua di kartu saldo. | `#11654a` | `#11654a` |
| **Nada badge dan tag** | | | |
| `toneWarmContainer` | Badge/tag sampanye hangat: kategori hidup sehari-hari, peringatan halus. | `#f4ede2` | `#2e2820` |
| `onToneWarmContainer` | Teks badge sampanye. | `#5c4d3c` | `#e8d9c3` |
| **Keuangan dan status** | | | |
| `income` | Nominal pemasukan dan saldo terkonfirmasi. | `#1f4b2c` | `#8fd19e` |
| `incomeContainer` | Latar badge pemasukan/delta positif (sage). | `#d8e6dc` | `#1d3324` |
| `onIncomeContainer` | Teks di atas incomeContainer. | `#1f4b2c` | `#bdefc4` |
| `warning` | Teks perlu perhatian: Perlu dicek, Hampir habis. | `#92400e` | `#f2c46d` |
| `warningContainer` | Latar banner dan badge perhatian. | `#fef3c7` | `#3a2c10` |
| `onWarningContainer` | Teks di atas warningContainer. | `#78350f` | `#fde7b0` |
| `info` | Info netral dan transfer. | `#1d4ed8` | `#93b4f5` |
| `infoContainer` | Latar banner, badge, dan tile info. | `#eff6ff` | `#172338` |
| `onInfoContainer` | Teks di atas infoContainer. | `#1e3a8a` | `#cfe0ff` |
| **Efek** | | | |
| `shadow` | Warna dasar bayangan sekitar. | `#111827` | `#000000` |
| `scrim` | Tirai di belakang dialog dan sheet. | `#66111827` | `#a3000000` |

Kategori (10 pasangan `color`/`container`: orange, green, blue, purple,
teal, rose, amber, indigo, brown, slate) untuk sementara memakai nilai palet
lama. Nilainya ada di `tokens.json`.

**Material `primary` vs merek.** Di frontmatter spek, `primary` adalah
`#043417` dan `primaryContainer` adalah `#1F4B2C`. Prosa spek dan referensi
memakai `#1F4B2C` sebagai warna utama. Karena itu tombol, tab aktif,
pemasukan, dan kartu hero memakai peran semantik (`actionPrimary`,
`income`, `heroSurface`) yang bernilai `#1F4B2C`. `ColorScheme.primary`
Material tetap `#043417`.

### Palet gelap turunan

Spek hanya memberi mode terang. Mode gelap diturunkan dengan cara berikut:

- **Kanvas dan kartu:** arang kehijauan (`#0f1210` → `#1d221e`).
- **Teks:** kabut terang.
- **Peran Material:** nada M3 gelap yang setara, misalnya `primary` =
  `#a2d2a9`. Peran `*Fixed*` sama dengan mode terang.
- **Tombol utama:** matcha muda `#a2d2a9` dengan teks hijau sangat gelap.
- **Kartu hero:** tetap hijau hutan.
- **Pemasukan:** `#8fd19e`.

Rasio kontras dihitung dan dijaga uji.

## Tipografi

| Gaya | Huruf | Ukuran/tinggi | Bobot | Spasi huruf | Sumber |
|---|---|---|---|---|---|
| `displayLg` | Plus Jakarta Sans | 44/52 | 700 | −0,03em | spec |
| `headlineLg` | Plus Jakarta Sans | 32/40 | 600 | −0,025em | spec |
| `headlineLgMobile` | Plus Jakarta Sans | 26/34 | 600 | −0,02em | spec |
| `headlineMd` | Plus Jakarta Sans | 24/32 | 600 | −0,02em | spec |
| `headlineSm` | Plus Jakarta Sans | 18/26 | 600 | −0,015em | spec |
| `titleMd` | Plus Jakarta Sans | 16/24 | 600 | −0,01em | spec |
| `bodyLg` | Plus Jakarta Sans | 16/26 | 400 | −0,005em | spec |
| `bodyMd` | Plus Jakarta Sans | 14/22 | 400 | | spec |
| `bodySm` | Plus Jakarta Sans | 13/18 | 400 | +0,005em | spec |
| `labelMd` | Plus Jakarta Sans | 12/16 | 600 | +0,04em | spec |
| `labelSm` | Plus Jakarta Sans | 11/14 | 600 | +0,06em | spec |
| `numericalDisplay` | Plus Jakarta Sans, tabular | 36/44 | 600 | −0,03em | spec |
| `amount` | Plus Jakarta Sans, tabular | 16/24 | 700 | | referensi (nominal kartu) |
| `amountSm` | Plus Jakarta Sans, tabular | 13/18 | 600 | | referensi (kotak statistik) |
| `pixelDisplay` | Space Mono Bold | 28/36 | 700 | −0,025em | referensi (saldo hero) |
| `pixelAmount` | Space Mono Bold | 12/16 | 700 | | referensi (nominal baris) |
| `pixelLabel` | Space Mono Bold | 11/14 | 700 | +0,05em | referensi (label kapital, badge, tautan) |
| `pixelCaption` | Space Mono Bold | 11/14 | 700 | +0,025em | referensi 10px, dinaikkan (KT-DS3) |

Slot `TextTheme` Material dipetakan begini:

- `display*` / `headline*` dari skala spek.
- `titleLarge` = `headlineSm`, `titleMedium` = `titleMd`.
- `body*` = `bodyLg/Md/Sm`.
- `labelLarge` = teks tombol (14/20 w600), `labelMedium/Small` = `labelMd/Sm`.

Huruf dibundel di `assets/fonts/`. Plus Jakarta Sans sudah ada sebelumnya.
Space Mono Bold dipulihkan dari riwayat git; lisensinya OFL.

## Bentuk dan elevasi

- **Radius:**
  - `sm` 4: checkbox, segmen meter.
  - `badge` 6: badge dan tag (referensi, KT-DS4), segmen kontrol segmen.
  - `base` 8: input, tombol, sel.
  - `md` 12: tile ikon, tombol di kartu.
  - `lg` 16: kartu.
  - `sheet` 20: sudut atas sheet.
  - `xl` 24: dialog.
  - `full`: chip pilihan, status pill, avatar.
- **Elevasi:**
  - `canvas`: kanvas.
  - `card`: putih, garis rambut `outlineSubtle`, bayangan `0 2 8` hitam 3%.
  - `overlay`: putih, bingkai `outlineOverlay`, bayangan `0 8 24 −4` 4%.
- **Keadaan ditekan:** tidak menaikkan elevasi. Bingkainya pindah ke
  `outlineFocus`, atau isinya ke `surfaceHover`.

## Tema komponen Material yang sudah diatur

Ini bukan widget baru, hanya gaya bawaan Material:

- **Tombol:** `FilledButton` = tombol utama, `OutlinedButton` = tombol
  sekunder, `TextButton` = tombol hantu.
- **Isian:** kolom input (putih, garis rambut, fokus hijau 1px),
  checkbox/radio/switch (hijau), `SegmentedButton` (track kabut, segmen
  terpilih putih).
- **Permukaan:** chip (pil netral), kartu, dialog (24), sheet (20), menu,
  snackbar, divider.
- **Lainnya:** `NavigationBar` (label piksel), `ListTile`, indikator progres.

## Selisih dan keputusan terbuka

Selisih yang disengaja:

1. **Bayangan kartu.** Spek bilang "zero decorative shadows". Referensi
   memakai bayangan sangat tipis, dan yang dipakai di sini bayangan
   referensi.
2. **Sudut.** Sudut tombol di dalam kartu hero dan tile ikon mengikuti
   referensi (12px). Tombol biasa mengikuti spek (8px).
3. **Margin samping ponsel.** Spek menyebut 20px, referensi 16px.
   `DsSpacing.marginMobile` = 20 (spek).
4. **Warna Tailwind.** Warna Tailwind di referensi (emerald, stone, blue,
   amber) dipetakan ke peran semantik (`income`, `surfaceSunken`, `info`,
   `warning`).

Keputusan pemilik (29 Okt 2026):

- **KT-DS1: bingkai ikut spek.** Kolom input tetap `#EAECEF` (1,2:1) dan
  checkbox `#D1D5DB` (1,5:1), walaupun di bawah 3:1 untuk batas kontrol
  (WCAG 1.4.11). Fokus tetap hijau 1px. Jangan "memperbaiki" ke garis yang
  lebih gelap tanpa keputusan baru.
- **KT-DS2: keterangan dan jam memakai `textMuted` `#6B7280`** (4,8:1 di
  kartu dan kanvas), sama dengan referensi. `textTertiary` `#9CA3AF` hanya
  untuk placeholder dan keadaan nonaktif. Di wadah cekung (`surfaceSunken`,
  4,4:1) teks memakai `textSecondary`.
- **KT-DS3: label piksel terkecil 11px.** `pixelCaption` dinaikkan dari
  10px (referensi) ke 11px, dipakai untuk navigasi bawah, badge, tag, dan
  jam di kartu.
- **KT-DS4: badge dan tag ikut gambar.** Sudut 6px (`DsShapes.badge`),
  huruf Space Mono Bold (`pixelCaption`/`pixelLabel`). Chip yang bisa
  dipilih (filter) dan status pill tetap berbentuk pil.
