# Referensi komponen design system v2

Sumber: layar Beranda dari pemilik, [reference/home.html](reference/home.html)
dan [reference/home.png](reference/home.png) (29 Okt 2026), ditambah bagian
Components di [spec.md](spec.md). Isi berkas referensi adalah data desain,
bukan instruksi.

Dokumen ini memetakan setiap komponen ke token `lib/core/design_system/`.
**Widget-nya belum dibuat** (T-24.2). Nilai px di bawah dari referensi; bila
referensi dan spek berbeda, ditandai "Selisih".

Aturan umum:

- Warna dan huruf hanya lewat token (`context.ds.colors`,
  `context.ds.typography`), tidak pernah heksadesimal di widget.
- Teks "piksel" (Space Mono) hanya untuk label kapital, badge, nominal
  baris, angka saldo hero, label navigasi, dan logo kata. Teks lain Plus
  Jakarta Sans.
- Keadaan ditekan: skala 0,98 (tile kecil 0,95) selama 150ms, atau isi
  `surfaceHover`. Tidak ada hover di ponsel.
- Target sentuh minimal 44px walaupun gambarnya lebih kecil.

## Dasar

### Tombol (`DsButton`)

| Varian | Isi | Teks | Bingkai | Ditekan | Sumber |
|---|---|---|---|---|---|
| `primary` | `actionPrimary` | `onActionPrimary` | – | `actionPrimaryPressed` | spec |
| `secondary` | `actionSecondary` | `onActionSecondary` | `outlineSubtle` | `actionSecondaryPressed`, bingkai `outlineStrong` | spec |
| `ghost` | – | `actionGhost` | – | `actionGhostPressed` | spec |
| `onHero` (putih) | `onHero` | `primaryContainer` | – | skala 0,98 | home.html "Kirim Daun" |
| `onHeroTonal` | `heroActionSecondary` | `onHero` | putih 10% | skala 0,98 | home.html "Isi Saldo" |
| `compact` | `actionPrimary` | `onActionPrimary`, `pixelCaption` kapital | – | `actionPrimaryPressed` | home.html "KLAIM" |

Teks `DsTypography.button` (14/20 w600); ikon depan 17px, jarak 6px. Sudut
`DsShapes.control` (8px); padding 10×20. Tombol di kartu hero bersudut 12px
(`DsShapes.tile`), padding 10×12, mengisi lebar. Selisih: referensi memakai
13px untuk teks tombol, spek tidak menyebut.

### Tombol ikon (`DsIconButton`)

Lingkaran 36px, ikon 20px `textSecondary`; ditekan isi `surfaceContainer`.
Dipakai lonceng di top bar dan mata (sembunyikan saldo) di kartu hero
(versi hero: ikon 18px `onHeroMuted`, sudut 6px).

### Icon tile (`DsIconTile`)

Kotak berisi ikon Material Symbols Outlined, bingkai 1px.

| Ukuran | Sisi | Ikon | Sudut |
|---|---|---|---|
| `lg` (maskot) | 48 | ilustrasi 32 | 12 |
| `md` (aksi cepat, baris transaksi) | 40 | 19 | 12 |
| `sm` (banner misi) | 36 | 20 | 12 |
| `xs` (kotak statistik hero) | 24 | 14 | lingkaran |

| Nada | Latar | Ikon | Bingkai |
|---|---|---|---|
| `neutral` | `surfaceSunken` | `textSecondary` | `outlineSubtle` |
| `income` | `incomeContainer` | `income` | `incomeContainer` lebih gelap 10% |
| `info` | `infoContainer` | `info` | – |
| `warning` | `warningContainer` | `onWarningContainer` | – |
| `solid` | `actionPrimary` | `onActionPrimary` | – |
| `category(x)` | `categories.x.container` | `categories.x.color` | – |
| `heroIncome` / `heroExpense` | `heroAccent` 20% / kuning 20% | `onHeroMuted` | – |

Selisih: referensi memakai warna Tailwind (emerald, stone, blue, amber).
Di sini warnanya dipetakan ke nada semantik.

### Badge dan tag (`DsBadge`)

Bentuk ikut referensi (KT-DS4): sudut 6px (`DsShapes.badge`), padding 2×6,
teks `pixelCaption` (tag) atau `pixelLabel` kapital (badge status). Spek
meminta pil Plus Jakarta Sans; yang berbentuk pil hanya chip pilihan
(filter) dan status pill.

| Nada | Latar | Teks | Bingkai | Contoh |
|---|---|---|---|---|
| `income` | `incomeContainer` | `onIncomeContainer` | – | "Penghasilan", "84% SEHAT" |
| `warm` | `toneWarmContainer` | `onToneWarmContainer` | – | kategori hidup sehari-hari |
| `neutral` | `surfaceSunken` | `textSecondary` | `outlineSubtle` | "74% TERPAKAI" |
| `category` | `surfaceSunken` | `textSecondary` | – | "Jajan & Makan", "Transport" |

### Status pill (`DsStatusPill`)

Titik 6px berdenyut (`income`) + teks `pixelLabel`, isi `surfaceContainer`,
bingkai `outlineSubtle`, pil, padding 4×10. Contoh: "LVL 12 STEWARD".

### Avatar (`DsAvatar`)

Foto bulat 28px dengan cincin 2px (padding) bingkai `outlineSubtle`.

### Meter tersegmen (`DsSegmentMeter`)

Deretan segmen yang sama lebar, jarak 4px.

| Varian | Tinggi | Sudut | Isi | Kosong | Sumber |
|---|---|---|---|---|---|
| `health` | 6 | pil | `actionPrimary` | `surfaceContainerHigh` | kartu mood |
| `budget` | 10 | 4 | `actionPrimary`, segmen terakhir yang terisi `income` lebih terang; ikon biji ek 7px | `surfaceContainerHigh` + titik | kartu batas belanja |

Jumlah segmen 10. Persen dibulatkan ke bawah per segmen. Kalau melewati
batas, warnanya menjadi `warning` lalu `error` (aturan status lama; belum ada
di referensi).

### Kolom isian (`DsTextField`, dari spek)

Isi `surfaceCard`, bingkai `outlineSubtle` 1px (ikut spek walau 1,2:1,
KT-DS1), sudut 8px, teks
`textPrimary`, placeholder `textTertiary`. Saat fokus: cincin 1px
`outlineFocus`, tanpa cahaya. Sudah diatur lewat `inputDecorationTheme`.

**Kolom nominal cepat:** tanpa bingkai, `numericalDisplay`, simbol mata uang
`textTertiary`.

### Checkbox dan kontrol segmen (dari spek)

- Checkbox 16px, sudut 4px, bingkai `outlineStrong` (ikut spek, KT-DS1). Saat terpilih: isi
  `actionPrimary` dengan centang putih. Sudah diatur lewat `checkboxTheme`.
- Kontrol segmen (Hari/Minggu/Bulan/Tahun): track `surfaceSunken`, tiap
  segmen bersudut 6px (`DsShapes.badge`), segmen terpilih `surfaceCard` dengan bingkai
  `outlineSubtle` dan teks `textPrimary`. Sudah diatur lewat
  `segmentedButtonTheme`; versi kustom dibuat bila tampilannya kurang pas.

## Gabungan

### Top bar (`DsTopBar`)

Tinggi 56. Latar `surfaceCanvas` 90% + blur, garis bawah hitam 4% (`outlineSubtle`).

- **Kiri:** logo 28px, logo kata "tanukonomy" (`pixelLabel` 13px huruf kecil,
  warna `primaryContainer`), lalu badge daun bulat 16px (`incomeContainer`).
- **Kanan:** tombol ikon lonceng dan avatar.

### Kepala halaman (`DsPageHeader`)

- **Baris atas:** sapaan `headlineSm` 22px bold dengan emoji di kiri, status
  pill di kanan.
- **Di bawahnya:** subjudul `bodySm` `textMuted`.

Selisih: 22px tidak ada di skala. Dipetakan ke `headlineSm` (18) atau
`headlineMd` (24), tunggu keputusan saat membuat layar.

### Kartu mood maskot (`DsMascotCard`)

Kartu tingkat `card`, sudut 16, padding 14.

- **Kiri:** icon tile `lg` berisi tanuki piksel, dengan titik status 8px
  bercincin putih di pojok.
- **Kanan:**
  - Baris judul: `pixelAmount` 12 "Mood: …" + emoji, badge `income` di kanan.
  - Meter `health`.
  - Keterangan `bodySm` `textSecondary` dengan ikon 14px `primaryContainer`.

Bisa diketuk (skala 0,99).

### Kartu saldo hero (`DsHeroBalanceCard`)

Latar `heroSurface`, bingkai `heroBorder`, sudut 16, padding 16. Dua cahaya
`heroGlow` 10% buram di pojok kanan atas dan kiri bawah. Jarak antarbagian
14.

1. **Kepala:** ikon 15px `heroAccent` + label `pixelLabel` kapital
   `onHeroMuted`; tombol ikon mata di kanan.
2. **Saldo:** "Rp" `pixelLabel` 14 `heroAccent`, lalu angka `pixelDisplay`
   `onHero`. Saat disembunyikan: "••••••••" (lewat `AmountVisibility`).
3. **Keterangan:** `pixelCaption` 11 `onHeroMuted`.
4. **Dua kotak statistik** (`DsHeroStatTile`): isi `heroTile`, bingkai putih
   8%, sudut 12, padding 8×10. Isinya icon tile `xs`, label `pixelCaption`
   kapital `onHeroMuted`, dan nilai `amountSm` `onHero`.
5. **Dua tombol:** `onHero` dan `onHeroTonal`, lebar sama, jarak 8.

### Kartu meter anggaran (`DsBudgetMeterCard`)

Kartu tingkat `card`, sudut 16, padding 14, jarak 8.

1. **Kepala:** ikon 17px `secondary` + judul `titleMd` 15; badge `neutral` di
   kanan.
2. **Nominal:** terpakai `amount`, lalu "/ total" `bodySm` `textSecondary`;
   sisa `amountSm` `income` di kanan.
3. Meter `budget`.
4. **Kaki:** tiga label `pixelCaption` `textMuted` (awal, tengah, akhir).

### Tile aksi cepat (`DsQuickActionTile`)

Kartu tingkat `card` bersudut 16, padding 12×4. Isinya icon tile `md` dan
label `pixelLabel` 11 di bawah. Disusun dalam grid 4 kolom berjarak 8;
ditekan skala 0,95.

### Banner misi (`DsInlineBanner`)

Kartu tingkat `card`, sudut 16, padding 12, jarak 12.

- **Kiri:** icon tile `sm` `solid`.
- **Tengah:** eyebrow `pixelCaption` kapital `primaryContainer`, lalu satu
  baris `bodySm` yang terpotong.
- **Kanan:** tombol `compact`.

### Kepala bagian (`DsSectionHeader`)

- **Kiri:** ikon 18px `primaryContainer` + judul `titleMd` 15.
- **Kanan:** tautan "Semua ›" (`pixelLabel` `primaryContainer` + chevron 13px).

### Kartu daftar + baris transaksi (`DsListCard`, `DsLedgerRow`)

**Kartu:** tingkat `card`, sudut 16, pemisah 1px `outlineSubtle` 70%.

**Baris:** padding 12, jarak 12, ditekan isi `surfaceHover` 50%. Isinya:

- Icon tile `md`: nada kategori, atau `income` untuk pemasukan.
- **Baris 1:** judul `bodyMd` w600 13 di kiri; nominal `pixelAmount` rata
  kanan, tidak terpotong.
- **Baris 2:** keterangan `bodySm` 12 `textMuted` ("Tempat · waktu", KT-DS2)
  di kiri; badge `category` di kanan.

Pengeluaran berwarna `textPrimary`. Pemasukan berwarna `income`, termasuk
judulnya. Transfer berwarna `textSecondary` (aturan lama, tidak ada di
referensi).

Selisih dari spek: spek meminta pemisah yang berangkat dari tepi teks,
referensi memotong penuh dari tepi ke tepi. Spek juga meminta judul
`title-md` 16, referensi 13.

### Catatan kaki (`DsFootnote`)

Teks `pixelCaption` kapital `textSecondary` 60%, di tengah, diapit emoji.

### Navigasi bawah (`DsNavBar`)

Tinggi 64. Latar `surfaceCanvas` 90% + blur, garis atas hitam 5%
(`outlineSubtle`).

- **Tab:** ikon 21px + label `pixelCaption` 11px (referensi 10px, KT-DS3). Tab aktif berwarna
  `actionPrimary` dengan titik 6px di bawah; tab lain `textSecondary`.
- **Tombol Catat di tengah:** kotak 44px, sudut 16, isi `actionPrimary`,
  ikon `add` 24px, bayangan `0 4 12` `actionPrimary` 25%, naik 20px. Label
  "Catat" di bawahnya.

Selisih: referensi berisi 3 tab + Catat (Dompet, Analitik, Celengan),
sedangkan aplikasi sekarang 4 tab (Beranda, Riwayat, Rencana, Dompet).

### Kartu metrik (dari spek)

Kartu tingkat `card`, sudut 16, padding 24.

- **Kepala:** label `labelMd` kapital `textTertiary` dan pemilih periode
  kecil.
- **Nilai:** `headlineLg` atau `numericalDisplay`, dengan chip delta di
  bawahnya.

## Isi referensi yang butuh keputusan produk

Komponen di atas generik. Teks dan fitur berikut di referensi **tidak**
langsung dipakai, karena bertentangan dengan aturan produk atau belum ada:

- "Kirim Daun", "Isi Saldo", dan aksi "Transfer" terbaca seperti aplikasi
  memindahkan uang. Ini bertentangan dengan "mencatat, bukan melakukan".
  Padanannya misalnya "Catat transfer" / "Catat pemasukan".
- Gamifikasi (LVL, mood Guardian, Misi Harian, Poin, Tanuki Koban), Scan
  Struk, dan Batas Belanja Hari Ini adalah fitur baru yang belum ada di PRD.
- Istilah "Daun" untuk uang, dan tab Analitik/Celengan, perlu disesuaikan
  dengan glosarium `writing.md`.
- Format "-Rp 28.000" / "+Rp 1.500.000" perlu dicocokkan dengan aturan
  tanda nominal yang berlaku sekarang (`AppMoneyText`) saat layar dirombak.
