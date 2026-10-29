# Design system v2 (Tanukonomy Matcha) dan preset tema

## 1. Metadata

- **Decision ID:** ADR-043
- **Tanggal:** 2026-10-29
- **Fase roadmap:** Fase 24 (lihat TASK_LIST)
- **Status:** Proposed. Fondasi dibangun atas permintaan pemilik 29 Okt
  2026; pemasangan ke aplikasi menunggu keputusan pemilik.
- **Cakupan:** `lib/core/design_system/`, `assets/fonts/SpaceMono-Bold.ttf`,
  `docs/03-design/design-system-v2/`
- **Bergantung pada:** ADR-031 (tema global lewat `MaterialApp`)
- **Akan menggantikan:** ADR-034 (bahasa visual buku catatan piksel) saat
  rombak UI dipasang. Sampai saat itu ADR-034 tetap berlaku untuk aplikasi.

## 2. Konteks

Pemilik akan merombak seluruh UI. Spek pertama (Autumn Kyoto Ledger, amber
dan terakota, tiga huruf) diganti pemilik pada hari yang sama dengan spek
**Tanukonomy**
([spec.md](../../03-design/design-system-v2/spec.md)) beserta referensi
komponen layar Beranda
([reference/home.html](../../03-design/design-system-v2/reference/home.html)).

Isi spek baru:

- hijau matcha hutan `#1F4B2C` di atas kanvas kabut hangat dan kartu putih;
- Plus Jakarta Sans;
- garis rambut 1px, tanpa bayangan dekoratif;
- sudut 8px untuk kontrol, 16px untuk kartu, pil untuk badge.

Referensinya menambah aksen piksel lewat Space Mono Bold (label kapital,
nominal baris, saldo hero) dan kartu saldo hijau hutan.

Ini bertentangan dengan ADR-034 dalam tiga hal: monospace dilarang, sudut
memakai piksel, dan kartu rata tanpa bingkai.

Pemilik juga ingin **preset tema** yang mudah ditambah developer dan bisa
dipilih pengguna.

Batasan pemilik untuk tahap ini: design system lama tidak disentuh, dan
widget komponen baru dibuat setelah pemilik memintanya.

## 3. Keputusan

### 3.1 Design system v2 berdiri sendiri

- **Kode:** `lib/core/design_system/` (barrel `design_system.dart`), prefiks
  `Ds`, berdampingan dengan `lib/core/theme/` lama.
- **Dokumen:** `docs/03-design/design-system-v2/` (spek, referensi
  komponen, `components.md`, `tokens.json`).
- **Tanpa adaptor ke `AppColors` lama.** Saat rombak UI, layar dipindahkan
  ke token baru, lalu design system lama dihapus. Jangan mencampur token
  lama dan baru di satu widget.

### 3.2 Token

- **Warna:** `DsColorScheme` (`ThemeExtension`) berisi:
  - peran Material 3 dari frontmatter spek;
  - peran semantik: permukaan, teks, garis, tindakan, kartu hero, nada
    badge;
  - peran keuangan (`income`, `warning`, `info` beserta wadahnya), efek,
    dan 10 pasangan kategori.

  Merek memakai peran semantik (`actionPrimary`, `income`, `heroSurface` =
  `#1F4B2C`), bukan `ColorScheme.primary`.
- **Tipografi:** `DsTypography` mengikuti skala Plus Jakarta Sans dari spek,
  ditambah gaya `pixel*` Space Mono Bold dari referensi dan `amount*`
  berangka tabular. Huruf dibundel lokal.
- **Bentuk, jarak, elevasi, gerak:** `DsRadius`/`DsShapes`, `DsSpacing`,
  `DsElevation` (`canvas`, `card`, `overlay`), dan `DsMotion` (150ms).
- **Tema:** `DsTheme.build(preset, brightness)` menghasilkan `ThemeData`
  lengkap, berisi ekstensi dan tema komponen bawaan Material. Hasilnya
  di-cache.

### 3.3 Preset tema

- Preset (`DsThemePreset`) berisi `id` tetap dan palet warna terang serta
  gelap. Huruf, sudut, jarak, dan elevasi berlaku global.
- Registri ada di `DsThemePresets.all`; `fallback` dipakai untuk id yang
  tidak dikenal.
- Menambah preset cukup satu berkas dan satu baris registri. Uji
  `ds_theme_presets_test.dart` memeriksa kontras dan kelengkapan setiap
  preset.
- Rilis pertama hanya berisi preset `matcha`. Palet gelapnya diturunkan
  sendiri, karena spek hanya memberi mode terang.

### 3.4 Komponen

[components.md](../../03-design/design-system-v2/components.md) memetakan
komponen referensi ke token, beserta varian dan selisihnya. Widget-nya ada
di `lib/core/design_system/components/` (T-24.2) dan hanya menerima teks
yang sudah diformat dan diterjemahkan pemanggil. Teks dan fitur referensi yang bertentangan dengan aturan produk
("Kirim Daun", "Isi Saldo", gamifikasi) tidak ikut diadopsi.

### 3.5 Preferensi pengguna (saat pemasangan)

Pilihan preset dan mode (Terang/Gelap/Ikuti sistem):

- disimpan lokal dan dianggap milik perangkat, jadi dikecualikan dari
  cadangan;
- dipilih di Akun › Tampilan;
- pemilih preset baru tampil kalau preset ada dua atau lebih.

## 4. Konsekuensi

- Selama masa transisi aplikasi membawa dua design system. Hurufnya tetap
  Plus Jakarta Sans ditambah Space Mono Bold (+~90 KB).
- Selisih disengaja dari spek dan keputusan KT-DS1–KT-DS4 (29 Okt 2026)
  dicatat di README design system v2.
- Skill `tanukonomy-ui`, `docs/03-design/design-system/`, dan aturan visual
  di `.claude/CLAUDE.md` masih menggambarkan ADR-034. Semuanya diperbarui
  saat pemasangan.

## 5. Alternatif yang ditolak

- **Mengganti isi `AppColors` lama dengan nilai baru.** Nama 52 token lama
  tidak memetakan peran spek, dan pemilik meminta design system lama tidak
  disentuh.
- **Preset paket penuh (warna, huruf, dan bentuk).** Setiap preset bisa
  menambah aset huruf dan pekerjaan uji visual.
- **Autumn Kyoto Ledger.** Spek ini sempat dibangun, lalu diganti pemilik
  dengan spek Tanukonomy pada hari yang sama.
