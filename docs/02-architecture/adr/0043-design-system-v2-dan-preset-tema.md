# Design system v2 (Tanukonomy Matcha) dan preset tema

## 1. Metadata

- **Decision ID:** ADR-043
- **Tanggal:** 2026-10-29
- **Fase roadmap:** Fase 25 (lihat TASK_LIST)
- **Status:** Proposed. Fondasi dibangun 29 Okt 2026; dipasang ke aplikasi
  dan Beranda dirombak 30 Okt 2026 (irisan vertikal); layar lain menyusul.
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

### 3.1 Design system v2 berdiri sendiri, dengan jembatan sementara

- **Kode:** `lib/core/design_system/` (barrel `design_system.dart`), prefiks
  `Ds`, berdampingan dengan `lib/core/theme/` lama.
- **Dokumen:** `docs/03-design/design-system-v2/` (spek, referensi
  komponen, `components.md`, `motion.md`, `icons.md`, `tokens.json`).
- **Jembatan (direvisi 30 Okt 2026).** Rancangan awal menolak adaptor.
  Saat tema dipasang ke aplikasi ternyata 128 berkas layar lama membaca
  `context.appColors` (jatuh ke token terang bila ekstensinya tidak ada,
  sehingga mode gelap rusak diam-diam) dan 105 membaca `textTheme`.
  `AppThemeBridge` (`lib/core/design_system/legacy/`) membangun tema lama
  lewat `PixelTheme.forColors` dari warna preset aktif, lalu menambahkan
  ekstensi Ds di atasnya. Layar lama tampil sama (dengan warna preset),
  layar baru memakai `context.ds`. **Jembatan dihapus saat semua layar
  dirombak (T-25.4).** Jangan mencampur token lama dan baru di satu widget
  baru.
- **Pemasangan:** `AppearanceThemeBuilder` (`lib/app/theme/`) membangun
  tema terang/gelap dan mode dari `ActiveAppearance` untuk `MaterialApp`
  dan layar boot ulang.

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
di `lib/core/design_system/components/` (T-25.2) dan hanya menerima teks
yang sudah diformat dan diterjemahkan pemanggil. Teks dan fitur referensi yang bertentangan dengan aturan produk
("Kirim Daun", "Isi Saldo", gamifikasi) tidak ikut diadopsi.

### 3.5 Preferensi pengguna

Pilihan preset dan mode (Terang/Gelap/Ikuti sistem) disimpan lokal di
`settings_appearance`, dianggap milik perangkat (dikecualikan dari
cadangan), dan dipilih di Akun › Tampilan (baris Mode dan Warna aplikasi).
Preset yang tak dikenal lagi jatuh ke `DsThemePresets.fallback`. Baris
preset tampil bila ada dua preset atau lebih (sekarang `matcha` dan `pink`).

### 3.6 Carousel status Beranda (30 Okt 2026)

Tiga banner Beranda (`NotificationInboxCard`, `RecurringPendingCard`,
`ReminderNudgeCard`) punya **mode ringkas**: dengan parameter `board`
(`DsStatusBoard`), widget tidak menggambar apa pun dan hanya melapor satu
`DsStatusSlideData` lewat `DsStatusReport`. Beranda merender slide itu
sebagai slide di **satu carousel** (`DsStatusCarousel`) di bawah aksi cepat
(31 Okt 2026; sebelumnya carousel sendiri di atas kartu saldo), diikuti slide
wawasan (anggaran nyata, rutin dan hadiah tiruan). Tinggi carousel mengikuti
slide aktif (`DsCarousel.adaptiveHeight`). Kartu mood menjadi pil di sapaan
dan banner misi menjadi lencana di tile Misi Hemat, supaya Beranda tidak
berlapis strip tipis. Logika data tetap di fitur masing-masing;
Beranda tidak mengimpor fitur lain (ADR-030); papan dimiliki cangkang.
Slide hanya membuka layar tujuan, tanpa aksi mencatat (aturan 8):
mencatat rutin lewat segmen Rutin, tangkapan lewat kotak masuk/CATAT.
Pengumuman pembaruan aplikasi (`AppUpdateBanner`, fitur `app_update`) ikut
pola yang sama sejak 31 Okt 2026: slide `app_update` berlatar kuning dan
paling depan (`order` -3), dengan tombol × (`dismissLabel`/`onDismiss`) untuk
Nanti dan ikon berputar (`busy`) saat mengunduh; kartu biru penuh di atas
sapaan dihapus. Lembar "Apa yang baru" tetap dibuka `WhatsNewHost` (tanpa
tampilan) dan kini memakai token v2.
Target tur `homeStatus` membungkus seluruh carousel. Tanpa `board`,
ketiga widget tetap kartu penuh (dipakai segmen Rutin dan Riwayat).

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
