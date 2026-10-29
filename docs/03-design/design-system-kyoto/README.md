# Design system baru: Autumn Kyoto Ledger

**Status:** fondasi selesai 29 Okt 2026, **belum dipasang** ke aplikasi.
Keputusan: [ADR-043](../../02-architecture/adr/0043-design-system-kyoto-dan-preset-tema.md) (Proposed).

Folder ini adalah design system pengganti untuk rombak UI. Ia berdiri
berdampingan dengan design system lama (`../design-system/`, ADR-034) dan
tidak mengubahnya. Aplikasi masih memakai `PixelTheme` sampai pemilik
memutuskan pemasangan. Komponen dan widget belum dibuat; menunggu
referensi pemilik.

| Berkas | Isi |
|---|---|
| [spec-autumn-kyoto-ledger.md](spec-autumn-kyoto-ledger.md) | Spek pemilik, disalin apa adanya |
| [tokens.json](tokens.json) | Token dalam bentuk data: warna per preset (terang/gelap), tipografi, radius, jarak, elevasi, gerak |
| README.md (ini) | Penerapan di Flutter, pemetaan, selisih, cara menambah preset |

## Kode

Semua di `lib/core/design_system/`, diimpor hanya lewat
`package:saldough/core/design_system/design_system.dart`. Prefiks `Ds`
supaya tidak bentrok dengan token lama (`AppColors`, `AppRadius`, ...).
Jangan mencampur token lama dan baru di satu widget.

| Berkas | Isi |
|---|---|
| `color/ds_color_scheme.dart` | `DsColorScheme` (`ThemeExtension`), `DsCategoryColors`, `DsColorPair` |
| `typography/ds_fonts.dart` | `DsFonts.heading` Epilogue, `.body` SourceSans3, `.mono` JetBrainsMono |
| `typography/ds_typography.dart` | `DsTypography` (`ThemeExtension`), `dsTextStyle()` |
| `tokens/ds_radius.dart`, `ds_shapes.dart` | Radius spek dan bentuk siap pakai (`micro`, `control`, `card`, `sheet`, `circle`) |
| `tokens/ds_spacing.dart` | Jarak, margin/gutter per lebar, breakpoint, target sentuh 44 |
| `tokens/ds_elevation.dart` | `DsElevation` tier 0–3 (`DsSurfaceTier`: warna, bingkai, bayangan, `decoration()`) |
| `tokens/ds_motion.dart` | Tekan 100ms, geser 1px |
| `presets/` | `DsThemePreset`, registri `DsThemePresets`, preset `autumnKyoto` |
| `ds_theme.dart` | `DsTheme.build(preset, brightness)` (di-cache), `DsTheme.light/dark`, `context.ds` |

Pemakaian di widget (nanti, saat rombak UI):

```dart
final ds = context.ds;
Container(
  decoration: ds.elevation.tier1.decoration(),
  child: Text('Rp 120.000', style: ds.typography.amountMd.copyWith(color: ds.colors.income)),
);
```

Pemasangan (nanti): `MaterialApp(theme: DsTheme.build(preset, Brightness.light),
darkTheme: DsTheme.build(preset, Brightness.dark), themeMode: ...)`.

## Menambah preset tema

Preset hanya membawa **warna** terang dan gelap. Huruf, sudut, jarak, dan
elevasi berlaku global.

1. Salin `lib/core/design_system/presets/autumn_kyoto.dart` menjadi
   `presets/<nama>.dart`, ganti `id` (`snake_case`, tidak boleh diganti
   setelah dirilis), `name`, dan nilai kedua `DsColorScheme`. Semua field
   wajib, jadi kompilator menolak preset yang bolong.
2. Tambahkan ke `DsThemePresets.all` di `presets/ds_theme_presets.dart`
   dan ekspor berkasnya dari `design_system.dart`.
3. Jalankan `test/core/design_system/`. `ds_theme_presets_test.dart`
   otomatis memeriksa setiap preset: id unik, kontras pasangan teks/latar
   (4,5:1; garis input 3:1), warna kategori di wadahnya, dan latar buram.
4. Perbarui `tokens.json` bagian `presets`.

Kalau spek preset baru datang dalam format seperti spek Kyoto (peran gaya
Material 3), nama perannya sama dengan field `DsColorScheme`; yang perlu
dirancang sendiri hanya peran komponen, peran keuangan, dan kategori.

Label preset untuk pengguna (i18n `appearance.presets.<id>`), penyimpanan
pilihan preset dan mode (Terang/Gelap/Ikuti sistem), dan baris pemilih di
Akun dikerjakan saat pemasangan. Pemilih preset hanya tampil bila preset
≥ 2.

## Warna

Nama field = peran spek dalam camelCase. Kelompok kedua diambil dari prosa
spek (bagian Components dan Elevation); kelompok ketiga tidak ada di spek
tetapi dibutuhkan aplikasi keuangan.

| Field Dart | Peran | Terang | Gelap |
|---|---|---|---|
| **Peran spek (gaya Material 3)** | | | |
| `surface` | Permukaan dasar Material. | `#fff8f5` | `#1a1512` |
| `surfaceDim` | Permukaan paling redup. | `#e5d8ce` | `#16120f` |
| `surfaceBright` | Permukaan paling terang. | `#fff8f5` | `#3d3530` |
| `surfaceContainerLowest` | Wadah terendah. | `#ffffff` | `#110d0a` |
| `surfaceContainerLow` | Wadah cekung: baki buku besar, sumur modul, baris disorot (tier 2). | `#f6f1e8` | `#1f1a16` |
| `surfaceContainer` | Kartu dan panel standar (tier 1). | `#f0eade` | `#241e1a` |
| `surfaceContainerHigh` | Panel mengambang, popover, chip netral, keadaan ditekan tombol tersier. | `#e7dfd1` | `#2e2723` |
| `surfaceContainerHighest` | Wadah tertinggi. | `#ded4c3` | `#39312c` |
| `onSurface` | Teks Material di atas surface. | `#211a15` | `#efe0d6` |
| `onSurfaceVariant` | Teks Material varian. | `#564338` | `#dcc3b5` |
| `inverseSurface` | Permukaan terbalik: snackbar. | `#362f29` | `#efe0d6` |
| `inverseOnSurface` | Teks di atas inverseSurface. | `#fceee4` | `#362f29` |
| `outline` | Garis Material. | `#897267` | `#a48c80` |
| `outlineVariant` | Garis Material varian. | `#ddc1b3` | `#564338` |
| `surfaceTint` | Rona permukaan Material (tidak dipakai untuk elevasi). | `#9b4500` | `#ffb68e` |
| `primary` | Amber gelap untuk teks, ikon, dan tautan berwarna primer (lolos 4,5:1 di kartu). | `#903f00` | `#ffb68e` |
| `onPrimary` | Teks di atas primary. | `#ffffff` | `#532200` |
| `primaryContainer` | Amber biji ek (#b45309), nada utama merek. | `#b45309` | `#763300` |
| `onPrimaryContainer` | Teks di atas primaryContainer. | `#fff1eb` | `#ffdbca` |
| `inversePrimary` | Primer di atas inverseSurface. | `#ffb68e` | `#903f00` |
| `secondary` | Terakota gelap untuk teks dan ikon sekunder. | `#8b4e30` | `#ffb694` |
| `onSecondary` | Teks di atas secondary. | `#ffffff` | `#522510` |
| `secondaryContainer` | Latar chip terakota lembut. | `#f3ded4` | `#5a3220` |
| `onSecondaryContainer` | Teks chip terakota lembut. | `#5a2d18` | `#ffdbcc` |
| `tertiary` | Madu untuk indikator info dan sorotan finansial. | `#7c4c00` | `#fdb967` |
| `onTertiary` | Teks di atas tertiary. | `#ffffff` | `#462a00` |
| `tertiaryContainer` | Wadah tersier. | `#996418` | `#663e00` |
| `onTertiaryContainer` | Teks di atas tertiaryContainer. | `#fff2e7` | `#ffddb9` |
| `error` | Galat dan tindakan hapus. | `#ba1a1a` | `#ffb4ab` |
| `onError` | Teks di atas error. | `#ffffff` | `#690005` |
| `errorContainer` | Latar banner dan badge galat. | `#ffdad6` | `#93000a` |
| `onErrorContainer` | Teks di atas errorContainer. | `#93000a` | `#ffdad6` |
| `primaryFixed` | Primer tetap (sama di kedua mode). | `#ffdbca` | `#ffdbca` |
| `primaryFixedDim` | Primer tetap redup. | `#ffb68e` | `#ffb68e` |
| `onPrimaryFixed` | Teks di atas primaryFixed. | `#331200` | `#331200` |
| `onPrimaryFixedVariant` | Teks varian di atas primaryFixed. | `#763300` | `#763300` |
| `secondaryFixed` | Sekunder tetap. | `#ffdbcc` | `#ffdbcc` |
| `secondaryFixedDim` | Sekunder tetap redup. | `#ffb694` | `#ffb694` |
| `onSecondaryFixed` | Teks di atas secondaryFixed. | `#351000` | `#351000` |
| `onSecondaryFixedVariant` | Teks varian di atas secondaryFixed. | `#6f381b` | `#6f381b` |
| `tertiaryFixed` | Tersier tetap. | `#ffddb9` | `#ffddb9` |
| `tertiaryFixedDim` | Tersier tetap redup. | `#fdb967` | `#fdb967` |
| `onTertiaryFixed` | Teks di atas tertiaryFixed. | `#2b1700` | `#2b1700` |
| `onTertiaryFixedVariant` | Teks varian di atas tertiaryFixed. | `#663e00` | `#663e00` |
| `background` | Latar Material. | `#fff8f5` | `#1a1512` |
| `onBackground` | Teks di atas background. | `#211a15` | `#efe0d6` |
| `surfaceVariant` | Permukaan varian Material. | `#ede0d6` | `#564338` |
| `surfaceCanvas` | Kanvas washi: latar halaman, isi kolom input (tier 0). | `#fbf9f4` | `#16120f` |
| `honeyBiscuit` | Aksen biskuit madu untuk sorotan dekoratif, bukan teks. | `#df9b52` | `#df9b52` |
| `warmSand` | Pasir hangat: bingkai kartu aktif/ditekan (tier 2). | `#d5c5b0` | `#4a4037` |
| `outlineSubtle` | Garis pemisah baris dan bingkai kartu (tier 1). | `#ded5c6` | `#3a322c` |
| `outlineStrong` | Bingkai kolom input, checkbox, dan radio kosong. | `#8a7f74` | `#9a8d81` |
| `textPrimary` | Teks utama dan nominal. | `#2a2421` | `#f1e7dd` |
| `textSecondary` | Teks pendukung: metadata dan label sekunder. | `#5e544c` | `#cdbfb3` |
| `textTertiary` | Teks tersier: keadaan nonaktif dan tag tersier (bukan untuk teks yang wajib terbaca). | `#857a70` | `#9c8f83` |
| **Peran komponen dari prosa spek** | | | |
| `surfaceFloating` | Laci, menu, dan dialog (tier 3). | `#fbf9f4` | `#2e2723` |
| `outlineFloating` | Bingkai tier 3. | `#c4b7a2` | `#4a4037` |
| `actionPrimary` | Isi tombol utama. | `#b45309` | `#e8914d` |
| `actionPrimaryPressed` | Tombol utama ditekan. | `#9a4408` | `#f0a565` |
| `actionPrimaryStroke` | Garis dasar 1px tombol utama ditekan. | `#78350f` | `#9a4408` |
| `onActionPrimary` | Teks dan ikon di atas actionPrimary. | `#fbf9f4` | `#2a1405` |
| `actionSecondary` | Isi tombol sekunder dan checkbox/radio terpilih. | `#b87352` | `#c98a6a` |
| `actionSecondaryPressed` | Tombol sekunder ditekan. | `#a36040` | `#d69c7e` |
| `onActionSecondary` | Teks dan ikon di atas actionSecondary. | `#ffffff` | `#2a140a` |
| `secondaryContainerOutline` | Bingkai chip terakota lembut. | `#e5bcab` | `#8b4e30` |
| `focusRing` | Cincin fokus 2px di luar kolom input. | `#33b87352` | `#40c98a6a` |
| **Tambahan aplikasi keuangan (tidak ada di spek)** | | | |
| `income` | Nominal pemasukan dan status Aman: lumut hangat teredam. | `#4a6b2a` | `#a9c98a` |
| `incomeContainer` | Latar badge dan banner pemasukan/aman. | `#e3ead2` | `#2c3a1e` |
| `onIncomeContainer` | Teks di atas incomeContainer. | `#2f4519` | `#cfe6b5` |
| `warning` | Teks perlu perhatian: Perlu dicek, Hampir habis. | `#7c4c00` | `#fdb967` |
| `warningContainer` | Latar banner dan badge perhatian. | `#ffddb9` | `#3d2a10` |
| `onWarningContainer` | Teks di atas warningContainer. | `#663e00` | `#ffddb9` |
| `info` | Info netral dan transfer. | `#3f5a73` | `#a9c2db` |
| `infoContainer` | Latar banner dan badge info. | `#dfe6ec` | `#22303d` |
| `onInfoContainer` | Teks di atas infoContainer. | `#233648` | `#d3e2f0` |
| **Efek** | | | |
| `shadow` | Warna dasar bayangan (arang kastanye). | `#2a2421` | `#000000` |
| `shadowTint` | Rona terakota bayangan tier 2. | `#b87352` | `#000000` |
| `shadowAccent` | Rona amber bayangan tier 3. | `#b45309` | `#000000` |
| `scrim` | Tirai di belakang dialog dan sheet. | `#7a2a2421` | `#a3000000` |

Kategori (10 pasangan `color`/`container`: orange, green, blue, purple,
teal, rose, amber, indigo, brown, slate) memakai nilai palet lama untuk
sementara; nilainya ada di `tokens.json`.

### Palet gelap turunan

Spek hanya memberi mode terang. Mode gelap diturunkan dengan aturan:
kanvas dan wadah arang hangat (`#16120f` → `#39312c`), teks krem hangat,
peran Material memakai nada M3 gelap yang setara (mis. `primary` =
`inversePrimary` terang `#ffb68e`), peran `*Fixed*` sama dengan terang,
tombol utama amber terang `#e8914d` dengan teks gelap, bayangan hitam dan
bingkai yang membedakan tingkat. Rasio kontras dihitung dan dijaga uji;
contoh: `textPrimary` di kanvas 15,3:1, `textSecondary` 10,4:1, teks tombol
utama 7,2:1.

## Tipografi

| Gaya | Huruf | Ukuran/tinggi | Bobot | Spasi huruf |
|---|---|---|---|---|
| `displayLg` | Epilogue | 56/64 | 700 | −0,03em |
| `displayLgMobile` | Epilogue | 36/44 | 700 | −0,02em |
| `headlineLg` | Epilogue | 32/40 | 600 | −0,02em |
| `headlineLgMobile` | Epilogue | 26/34 | 600 | −0,015em |
| `headlineMd` | Epilogue | 24/32 | 600 | −0,015em |
| `headlineSm` | Epilogue | 20/28 | 600 | −0,01em |
| `bodyLg` | Source Sans 3 | 18/28 | 400 | |
| `bodyMd` | Source Sans 3 | 16/24 | 400 | |
| `bodySm` | Source Sans 3 | 14/22 | 400 | |
| `labelLg` | JetBrains Mono | 14/20 | 500 | +0,02em |
| `labelMd` | JetBrains Mono | 12/18 | 500 | +0,03em |
| `labelSm` | JetBrains Mono | 11/16 | 500 | +0,04em |
| `amountLg` | JetBrains Mono, tabular | 28/36 | 600 | |
| `amountMd` | JetBrains Mono, tabular | 16/24 | 500 | |
| `amountSm` | JetBrains Mono, tabular | 14/20 | 500 | |

Slot `TextTheme` Material: display/headline dari skala Epilogue,
`titleLarge` = `headlineSm`, `titleMedium`/`titleSmall` = isi w600, `body*`
= `bodyLg/Md/Sm`, `label*` = JetBrains Mono. Huruf dibundel di
`assets/fonts/` (berkas variabel, OFL, lisensi di `assets/fonts/licenses/`).

## Bentuk dan elevasi

- Radius: `sm` 2 (badge, checkbox, switch), `base` 4 (input, tombol, chip),
  `md` 6, `lg` 8 (kartu, panel, dialog, menu), `xl` 12 (sudut atas sheet),
  `full` hanya avatar dan titik status.
- Tier 0 kanvas; tier 1 `surfaceContainer` + bingkai `outlineSubtle`; tier 2
  `surfaceContainerLow` + `warmSand`; tier 3 `surfaceFloating` +
  `outlineFloating`. Bayangan terang persis spek (lihat `tokens.json`).

## Tema komponen Material yang sudah diatur

Bukan widget baru, hanya gaya bawaan: `FilledButton` = tombol utama,
`ElevatedButton` = tombol sekunder, `OutlinedButton` = tombol tersier,
`TextButton`, kolom input (kanvas, bingkai `outlineStrong`, fokus amber),
checkbox/radio/switch (terisi terakota), chip (washi netral), kartu (tier
1), dialog/sheet/menu (tier 3), snackbar, divider, `NavigationBar`,
`ListTile`, indikator progres.

## Selisih dari spek dan keputusan terbuka

Selisih disengaja:

1. **Tertiary.** Prosa spek menyebut tertiary `#c4883b`, sedangkan peran
   warnanya `#7c4c00`. Dipakai `#7c4c00` (lolos 4,5:1 sebagai teks);
   `#c4883b` tidak dipakai.
2. **Primary sebagai teks.** Prosa memakai `#b45309` untuk teks amber,
   tetapi di kartu `#f0eade` rasionya 4,2:1. Teks/ikon/tautan amber memakai
   `primary` `#903f00` (6,1:1); `#b45309` untuk isi tombol (`actionPrimary`)
   dan `primaryContainer`.
3. **Hijau pemasukan.** Spek menghindari hijau, tetapi pemasukan perlu
   dibedakan dari amber merek. `income` = lumut hangat teredam `#4a6b2a`.
4. **Tanpa hover.** Aplikasi sentuh; nilai hover spek dipakai untuk keadaan
   ditekan.
5. **Huruf tombol.** Spek tidak menyebut; dipakai Source Sans 3 w600 16px
   (`DsTypography.button`) supaya label tindakan terbaca seperti kalimat.
6. **Label kepala bagian** gaya `[ 01 // METRICS ]` belum diterapkan (urusan
   komponen).

Keputusan terbuka untuk pemilik (dicatat di TASK_LIST):

- **KT-DS1** Teks putih di tombol sekunder `#b87352` hanya 3,74:1 (di bawah
  4,5:1 untuk teks 16px). Pilihan: biarkan sesuai spek, pakai `#a36040`
  (4,9:1) sebagai warna diam, atau teks gelap.
- **KT-DS2** `labelSm` 11px di bawah batas 12px yang dipakai aplikasi
  sekarang. Saat ini mengikuti spek (11px).
- **KT-DS3** `textTertiary` `#857a70` 4,0:1 di kanvas: aman untuk keadaan
  nonaktif, tidak untuk teks yang wajib terbaca (jam, sumber).
