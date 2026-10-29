# Design system baru "Autumn Kyoto Ledger" dan preset tema

## 1. Metadata

- **Decision ID:** ADR-043
- **Tanggal:** 2026-10-29
- **Fase roadmap:** Fase 24 (lihat TASK_LIST)
- **Status:** Proposed (fondasi dibangun atas permintaan pemilik 29 Okt 2026;
  pemasangan ke aplikasi menunggu keputusan pemilik)
- **Cakupan:** `lib/core/design_system/`, `assets/fonts/`,
  `docs/03-design/design-system-kyoto/`
- **Bergantung pada:** ADR-031 (tema global lewat `MaterialApp`)
- **Akan menggantikan:** ADR-034 (bahasa visual buku catatan piksel) saat
  rombak UI dipasang. Sampai itu, ADR-034 tetap berlaku untuk aplikasi.

## 2. Konteks

Pemilik akan merombak seluruh UI dengan spek **Autumn Kyoto Ledger**
([salinan](../../03-design/design-system-kyoto/spec-autumn-kyoto-ledger.md)):
palet amber, terakota, dan biskuit hangat; tiga huruf (Epilogue, Source Sans
3, JetBrains Mono); sudut lengkung 2–8px; bingkai hairline dan bayangan lembut
bertingkat. Ini bertentangan langsung dengan ADR-034 (satu huruf, tanpa
monospace, sudut piksel, kartu rata tanpa bingkai). Pemilik juga ingin
**preset tema** yang mudah ditambah developer dan bisa dipilih pengguna.

Batasan pemilik untuk tahap ini: design system lama tidak disentuh, dan
komponen/widget belum dibuat sampai pemilik mengirim referensinya.

## 3. Keputusan

### 3.1 Design system baru berdiri sendiri

Design system baru di `lib/core/design_system/` (barrel `design_system.dart`)
dengan prefiks `Ds`, berdampingan dengan `lib/core/theme/` lama. Dokumennya di
`docs/03-design/design-system-kyoto/`. Tidak ada adaptor ke `AppColors` lama:
saat rombak UI, layar dipindah ke token baru lalu design system lama dihapus.
Jangan mencampur token lama dan baru di satu widget.

### 3.2 Token

- **Warna:** `DsColorScheme` (`ThemeExtension`), field = peran spek dalam
  camelCase, ditambah peran komponen dari prosa spek (`actionPrimary`,
  `actionSecondary`, `surfaceFloating`, `focusRing`, ...), peran keuangan yang
  tidak ada di spek (`income`, `warning`, `info` beserta wadahnya), efek
  (`shadow`, `scrim`), dan 10 pasangan kategori. `toMaterial()` mengisi
  `ColorScheme`.
- **Tipografi:** `DsTypography` persis skala spek, plus `amount*` JetBrains
  Mono angka tabular. Huruf dibundel lokal (variabel, OFL), tidak diunduh saat
  runtime.
- **Bentuk, jarak, elevasi, gerak:** `DsRadius`/`DsShapes`, `DsSpacing`,
  `DsElevation` tier 0–3, `DsMotion` persis spek.
- **Tema:** `DsTheme.build(preset, brightness)` menghasilkan `ThemeData`
  lengkap (ekstensi + tema komponen Material bawaan), di-cache.

### 3.3 Preset tema

- Preset (`DsThemePreset`) = `id` tetap + palet warna terang dan gelap. Huruf,
  sudut, jarak, dan elevasi global, supaya preset baru tidak menambah aset
  atau pekerjaan uji visual.
- Registri `DsThemePresets.all`; `fallback` untuk id tak dikenal.
- Menambah preset = satu berkas + satu baris registri; uji
  `ds_theme_presets_test.dart` memeriksa kontras dan kelengkapan setiap
  preset otomatis.
- Rilis pertama hanya preset `autumn_kyoto`. Palet gelapnya diturunkan
  (spek hanya terang).

### 3.4 Preferensi pengguna (saat pemasangan)

Pilihan preset dan mode (Terang/Gelap/Ikuti sistem) disimpan lokal, milik
perangkat (dikecualikan dari cadangan), dipilih di Akun › Tampilan. Pemilih
preset hanya tampil bila preset ≥ 2. Belum dikerjakan di tahap ini.

## 4. Konsekuensi

- Aplikasi sementara membawa dua design system dan empat huruf (+~1 MB aset)
  sampai rombak UI selesai.
- Selisih disengaja dari spek dan keputusan terbuka (KT-DS1–KT-DS3) dicatat
  di README design system baru dan TASK_LIST.
- Skill `tanukonomy-ui`, `docs/03-design/design-system/`, dan aturan visual
  di `.claude/CLAUDE.md` masih menggambarkan ADR-034; diperbarui saat
  pemasangan.

## 5. Alternatif yang ditolak

- **Mengganti isi `AppColors` lama dengan nilai Kyoto.** Cepat, tetapi nama
  52 token lama tidak memetakan peran spek, dan pemilik meminta design system
  lama tidak disentuh.
- **Preset paket penuh (warna + huruf + bentuk).** Lebih fleksibel, tetapi
  setiap preset bisa menambah aset huruf dan uji visual.
