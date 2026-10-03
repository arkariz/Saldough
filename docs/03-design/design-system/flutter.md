# Implementasi di Flutter

Sistem ini menggantikan bahasa visual pixel (ADR-015, ADR-016, ADR-020) dan `PixelTheme` (ADR-031). Strukturnya tetap: satu tema global di `MaterialApp`, token sebagai `ThemeExtension`.

## Token

- Warna: satu `ThemeExtension` (`AppColors`) dengan nama token persis seperti di sini (`bg`, `surface`, `surface2`, `ink`, `ink2`, `brand`, `brandSoft`, `positive`, `warningFill`, `catOrangeBg`, ...), nilai terang dan gelap.
- `ColorScheme` diisi dari token: `primary` = `brand`, `onPrimary` = `on-brand`, `surface` = `surface`, `surfaceContainerHighest` = `surface-2`, `outline` = `line-strong`, `outlineVariant` = `line`, `error` = `danger`, `inverseSurface` = `inverse-surface`.
- Tipografi: `TextTheme` dari skala Teks (`headline` → `headlineSmall`, `title` → `titleLarge`, `body-strong` → `titleMedium`, `body` → `bodyLarge`, `body-sm` → `bodyMedium`, `label` → `labelLarge`, `label-sm` → `labelMedium`, `caption` → `bodySmall`). Skala Angka sebagai `ThemeExtension` sendiri (`AppNumberStyles`) dengan `FontFeature.tabularFigures()`.
- Jarak, sudut, ukuran: konstanta `AppSpacing`, `AppRadius`, `AppSize` dengan nama token.

## Aset

- Huruf: hanya `PlusJakartaSans-Variable.ttf`. Hapus `SpaceGrotesk-Variable.ttf` dan `SpaceMono-Bold.ttf` dari `pubspec.yaml`.
- Ikon: ikon piksel di `assets/icons/` tetap dipakai (lewat `flutter_svg`, 32px) untuk kategori, dompet, dan freelance. Paket `material_symbols_icons` (Rounded, bobot 400) untuk navigasi dan tindakan.
- Ilustrasi maskot tetap di `assets/illustration/`, ditampilkan dengan `FilterQuality.none`.

## Widget lama ke baru

| Sekarang | Jadi | Catatan |
|---|---|---|
| `AppHardCard`, `AppHeroCard`, `AppCard` | `AppCard` | Satu permukaan rata bersudut piksel (`PixelCornerBorder`), tanpa bingkai dan bayangan |
| `AppSegmentedProgressBar` | `AppProgressBar` | Bar kotak 6px berjarak 2px dengan penanda waktu, warna dari status |
| `AppSegmented` | `AppSegmentedControl` | Track `surface-2`, segmen terpilih `surface` |
| `AppQuickChip` | `AppChip` | Pill, terpilih `brand-soft` + ikon centang |
| `AppSectionLabel` | `AppSectionHeader` | `title` huruf biasa, bukan monospace kapital |
| `AppMoneyText` | `AppMoneyText` | Gaya Angka + aturan tanda dan warna di README |
| `CategoryIcon`, `AppIcon` | `AppIconTile` | Ikon piksel di tile netral; Material Symbols di tile berwarna untuk kategori tanpa ikon piksel |
| `kind_surfaces` | dihapus | Baris tidak lagi diberi latar berwarna per jenis |
| `pixel_bob`, `pixel_pop`, `pixel_sparkle`, `stepped_curve` | dihapus | Kecuali animasi maskot di keadaan kosong |
| Dua FAB (suara + CATAT) | `AppNavBar` dengan tombol Catat di tengah | Suara pindah ke dalam sheet Catat |
| (baru) | `PixelCornerBorder` | `OutlinedBorder` dengan path sudut tangga dua langkah (`pixel-step`); dipakai `AppCard`, tombol, chip, tile |
| (baru) | `AppHeroCard` | Kartu saldo terakota dengan kepala tanuki |

## Urutan pengerjaan yang disarankan

1. Token, tema, huruf, ikon. Layar lama langsung tampak lebih tenang karena bingkai, monospace, dan kapital hilang.
2. Komponen dasar: kartu, baris, tombol, chip, kontrol segmen, progress bar, tile ikon.
3. Navigasi bawah dan sheet Catat.
4. Layar satu per satu: Beranda, Riwayat, Anggaran, Dompet, lalu halaman turunan.
5. Sapuan teks i18n mengikuti glosarium di bagian Menulis.
