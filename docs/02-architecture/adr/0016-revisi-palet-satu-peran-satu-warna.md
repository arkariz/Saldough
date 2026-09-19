# Revisi palet ADR-015: satu peran, satu warna

## 1. Metadata

- **Decision ID:** ADR-016
- **Tanggal:** 2026-09-19
- **Fase roadmap:** Fase 2
- **Status:** Accepted
- **Cakupan:** Global untuk subtree `PixelTheme` (layar Saldough 2.0). Palet
  Saldough 1.0 (`AppColorsExtension.light`/`dark`, ADR-0006) TIDAK berubah.
- **Merevisi:** tabel "Palet" dan "Rekonsiliasi nominal pengeluaran" di
  [ADR-015](0015-adopsi-bahasa-visual-pixel-kas.md). Bagian lain ADR-015
  (tipografi, elevasi, ikon, bentuk) tetap berlaku.

## 2. Konteks

Setelah layar Transaksi (T-2.5) dibangun mengikuti rujukan visual dan dilihat
di emulator, pemilik menilai komposisi warnanya berantakan dan jenis
transaksi kurang terbedakan. Audit menemukan empat penyebab, semuanya dari
palet ADR-015 dan cara pemakaiannya, bukan dari rujukan visual itu sendiri:

1. **Warna bermakna sama tampil dalam dua nuansa.** Token `income`
   (`#006948`) dan `expense` (`#BA1A1A`) ADR-015 sengaja gelap supaya lolos
   4,5:1 sebagai teks. Ketika dipakai sebagai bidang (garis aksen, kotak
   ikon, bilah), hasilnya hijau tua dan merah tua yang berdekatan luminansinya
   dan pastelnya jadi sage/pink yang mirip. Perbaikan lokal di layar Transaksi
   (palet terang terpisah) menyelesaikan pembedaan di kartu, tapi
   meninggalkan dua hijau dan dua merah di layar yang sama.
2. **`accent` `#A73A00` terbaca coklat kusam.** ADR-015 menyatukan tombol
   utama dan CATAT ke satu `accent` gelap demi kontras 6,46:1. Di samping
   hijau/merah yang cerah, ia menjadi satu-satunya warna redup di layar.
3. **`transfer` sengaja netral (`#3D4A42`), sama dengan `textMuted`.** Akibatnya
   transfer nyaris tak punya identitas visual dibanding dua jenis lainnya.
4. **Slot turunan tidak ikut diganti.** `PixelTheme` mewarisi
   `incomeOnLight`/`overBudgetOnLight` dari palet lama, sehingga
   `AppMoneyText` di layar baru memakai hijau lama dan **oranye-coklat
   `#A84F05` untuk angka negatif**.

Tambahan: `pending` (`#8D4B00`, hue ~26°) hampir berhimpit dengan `accent`
(hue ~18°), dan `textMuted` (`#3D4A42`) abu kehijauan dingin di atas krem
hangat, sedangkan `DESIGN.md` pemilik menyebut abu hangat `#57534E`.

## 3. Keputusan

### Prinsip

**Satu peran, satu warna; makna uang tidak dipinjam untuk hal lain.**

| Peran | Warna | Dipakai untuk | Tidak dipakai untuk |
|---|---|---|---|
| Aksi | terracotta | tombol utama, CATAT, kursor, tab aktif | makna uang (ADR-013) |
| Uang masuk | hijau | income, saldo positif | aksi/pilihan |
| Uang keluar | merah | expense, over budget, saldo negatif | aksi/pilihan |
| Mutasi | biru | transfer antar dompet | — |
| Status | amber | pending, mendekati batas anggaran | jenis transaksi |
| Netral | krem hangat, arang | latar, kartu, teks, garis tepi | — |

Hijau dan merah tidak pernah menandai pilihan/aksi (mis. tab aktif). Terracotta
tidak pernah menandai nominal.

### Kontrak slot: teks-aman vs isian

Setiap warna makna uang punya DUA tingkat, karena satu nilai tidak bisa
sekaligus lolos 4,5:1 sebagai teks dan cukup cerah sebagai bidang:

- **`income` / `expense` / `transfer` / `pending` / `accent`** — TEKS-AMAN
  (>= 4,5:1 terhadap kartu dan latar). Dipakai untuk teks, ikon Material
  kecil, dan isian lencana yang memuat teks kontras di atasnya.
- **`incomeFill` / `expenseFill` / `transferFill`** (slot baru) — bidang
  besar: garis aksen kartu, kotak ikon, bilah segmen, titik status. Cukup
  >= 3:1 (WCAG 1.4.11, komponen non-teks).

`incomeOnLight`/`expenseOnLight`/`overBudgetOnLight` di palet pixel diisi sama
dengan slot teks-aman, supaya `AppMoneyText` tidak lagi jatuh ke nilai
ADR-0006.

### Nilai

Mode terang (kontras terhadap kartu `#FFFFFF` / latar `#FFF8F5`):

| Slot | Hex | Kartu | Latar | Hue |
|---|---|---|---|---|
| `income` (teks) | `#15803D` | 5,02 | 4,78 | 142° |
| `incomeFill` | `#16A34A` | 3,30 | 3,14 | 142° |
| `expense` / `overBudget` (teks) | `#B91C1C` | 6,47 | 6,16 | 0° |
| `expenseFill` | `#DC2626` | 4,83 | 4,60 | 0° |
| `transfer` (teks) | `#1D4ED8` | 6,70 | 6,38 | 224° |
| `transferFill` | `#2563EB` | 5,17 | 4,92 | 221° |
| `pending` | `#A16207` | 4,92 | 4,69 | 35° |
| `accent` | `#C2410C` | 5,18 | 4,93 | 17° |
| `onAccent` | `#FFFFFF` | 5,18 di atas `accent` | | |
| `textMuted` | `#57534E` | 7,63 | 7,27 | 33° |

`incomeOnLight`, `expenseOnLight`, `overBudgetOnLight` = nilai teks-aman di
atas. `background`, `cardBackground`, `edge`, `textPrimary` tidak berubah.

Mode gelap (kontras terhadap kartu `#1F1C18` / latar `#14120F`) — pada mode
gelap nilai teks-aman dan isian sama:

| Slot | Hex | Kartu | Latar |
|---|---|---|---|
| `income`, `incomeFill` | `#22C55E` | 7,45 | 8,21 |
| `expense`, `overBudget`, `expenseFill` | `#F87171` | 6,13 | 6,76 |
| `transfer`, `transferFill` | `#60A5FA` | 6,67 | 7,35 |
| `pending` | `#F59E0B` | 7,90 | 8,71 |
| `accent` | `#E95100` (tetap) | 4,56 | 5,02 |
| `textMuted` | `#A8A29E` | 6,73 | 7,41 |

### Jarak hue sebagai syarat

Tiga warna jenis transaksi harus berjarak >= 60° satu sama lain (hijau 142°,
merah 0°, biru ~221°: jarak terkecil 79°). Diuji otomatis di
`app_colors_extension_test.dart` supaya perubahan warna di masa depan tidak
diam-diam mengembalikan masalah "kurang kontras". Biru dipilih untuk transfer
(bukan amber) karena amber hanya ~35° dari merah dan pasangan merah/hijau saja
rawan bagi buta warna.

## 4. Konsekuensi

- Seluruh layar di bawah `PixelTheme` (CATAT, Transaksi, dan layar Fase 2+
  berikutnya) berganti warna otomatis; tidak ada warna harfiah di widget.
  Palet lokal `TransactionKindPalette` (hex tertanam di fitur `transaction`)
  dihapus, digantikan pemetaan tipis ke token.
- Layar Saldough 1.0 tidak terpengaruh (`light`/`dark` tidak disentuh; ada
  tiga slot baru di sana, diisi sama dengan `income`/`expense`/`transfer`
  masing-masing).
- **Menyimpang dari ADR-015 atas keputusan pemilik:** transfer tidak lagi
  netral (alasan asli ADR-013/015: tidak menyaingi income/expense). Kini
  dibedakan lewat hue yang jauh dari keduanya; biayanya, transfer jadi
  "peristiwa berwarna" yang ikut menarik mata.
- `accent` (hue 17°) tetap dekat dengan `expense` (0°). Dijaga lewat aturan
  peran di atas: `accent` hanya untuk aksi, tidak pernah untuk nominal.
- Ikon pixel-art membawa warna tertanam yang tidak bisa ditint lewat token;
  diselaraskan per keluarga hue lewat pemetaan warna di §6.1 (bukan digambar
  ulang).
- **Belum diputuskan:** `AppSegmentedProgressBar` (ambang 70%/100%) tetap
  memakai slot `income`/`pending`/`overBudget` versi teks-aman; bisa dipindah
  ke slot `…Fill` saat layar Anggaran dibangun.

## 5. Alternatif yang ditolak

- **Tombol utama hijau (seperti mockup).** Membuat hijau berarti ganda —
  aksi dan uang masuk — persis antipola ADR-013. Ditolak.
- **Tetap `accent` `#A73A00`.** Kontras 6,46:1 memang aman, tapi terbaca
  coklat kusam di samping warna semantik yang cerah. `#C2410C` masih 5,18:1.
- **Transfer tetap netral (ADR-015).** Pembeda hanya lewat ikon dan lencana
  abu; ditolak pemilik karena jenisnya tetap kurang terlihat.
- **Palet lokal per fitur.** Sudah dicoba di T-2.5 dan menghasilkan dua
  nuansa untuk makna yang sama di satu layar.

## 6. Tambahan (2026-09-19): ikon dan struktur token

Setelah §3 diterapkan, pemilik mengizinkan penggantian menyeluruh bila perlu.
Pengukuran menunjukkan dua hal yang ikut menyebabkan kesan berantakan dan
tidak tersentuh token:

### 6.1 Warna tertanam di ikon pixel-art

23 ikon di `assets/icons/` membawa 59 warna hex dari palet Tailwind campuran:
abu slate kebiruan, emerald, sky, teal, pink, dan sebagainya. Warna itu
tertanam di SVG, jadi tidak ikut token dan tidak bisa ditint.

Keputusan: **selaraskan per keluarga hue**, bukan menggambar ulang.

| Keluarga | Sebelum | Sesudah |
|---|---|---|
| Garis luar | `#1E1E1E` | `#1E1B19` (sama dengan `edge`) |
| Netral | slate `#F8FAFC…#334155` | stone hangat `#FFFFFF…#44403C` (selaras `textMuted` `#57534E`) |
| Hijau | emerald `#34D399…#064E3B` | rampa `income`: `#4ADE80 / #22C55E / #16A34A / #15803D / #14532D` |
| Merah | `#EF4444` | `#DC2626` (= `expenseFill`) |
| Biru | sky `#BAE6FD…#0284C7` dan teal `#CCFBF1…#0F766E` | satu rampa `transfer`: `#DBEAFE…#1E3A8A` (= `transferFill` `#2563EB`) |
| Celengan | pink `#FBCFE8…#831843` | terracotta `#FED7AA…#5C1F0A` (keluarga `accent`) |

Kuning, emas, coklat, dan oranye (bahan dompet, koin, atap) sengaja
dibiarkan: keluarga hangat itu sudah selaras dengan terracotta dan krem.
Hanya `assets/icons/` yang diubah; berkas asli pemilik di
`docs/stitch_pixel_finance_tracker/` tidak disentuh, sehingga perubahan ini
bisa dibalik lewat git. Pemetaannya ada di `tool/recolor_icons.py` supaya ikon
baru yang dikonversi kemudian (ADR-015 §7) diselaraskan dengan cara yang sama:

```bash
python tool/recolor_icons.py assets/icons assets/icons
```

### 6.2 Struktur token

- `AppColorsExtension.pixelLight`/`pixelDark` kini **konstruktor eksplisit**,
  bukan `light.copyWith(...)`. Dengan `copyWith`, slot yang lupa diisi diwarisi
  diam-diam dari palet lama, dan itulah cara `AppMoneyText` sempat memakai
  oranye-coklat untuk angka negatif. Sekarang slot baru wajib diisi untuk
  palet pixel saat kompilasi. Slot milik layar lama (`investment`, `rollUp`,
  `needsReview`) diisi padanan keluarga hue ADR-016.
- Tingkat permukaan (`surfaceLow`, `surfaceMid`, `surfaceHigh`) dan pewarna
  `tinted(fill, strength)` dipindah dari fitur `transaction` ke ekstensi
  `AppColorsSurfaces` di `core/theme`. Widget tidak boleh menulis
  `Color.alphaBlend(...)` sendiri lagi.
- **Tidak dilakukan:** mengganti `AppColorsExtension` dengan kelas baru.
  Kelas itu masih dibaca lima berkas fitur lama dan 13 berkas lain lewat
  widget bersama, sedangkan CLAUDE.md dan ADR-014 mewajibkan fitur lama tidak
  disentuh sampai cutover Fase 3. Penggantian total kelas itu masuk daftar
  Fase 3, bersama penghapusan `light`/`dark`.
