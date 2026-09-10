# Token desain dan pemetaan warna semantik

## 1. Metadata

- **Decision ID:** ADR-006
- **Tanggal:** 2026-09-09, direvisi 2026-09-10
- **Fase roadmap:** Fase 1
- **Status:** Accepted (revisi)
- **Cakupan:** Global

> **Catatan revisi (2026-09-10):** Versi pertama ADR ini memilih palet dan
> tipografi "dark sports-tech" langsung dari `new-health-duel` (hijau neon,
> Syne/DM Sans). Pemilik melihat hasilnya di Design Canvas dan menilainya
> **jelek** untuk konteks keuangan, lalu secara eksplisit meminta dua hal
> dipisah: pola teknis kode theming boleh tetap diambil dari
> `new-health-duel`, tapi bahasa visualnya harus diriset ulang dari nol.
> Riset (tren fintech 2026: satu aksen kuat, nada tenang) disampaikan lewat
> `AskUserQuestion` dengan rekomendasi "Ledger Tenang" — pemilik menolaknya
> dan memilih sendiri arah yang berlawanan: **gaya komik/meme, garis tegas,
> agak kasar, chaos**. Arah itu dicoba di satu canvas percobaan, disetujui,
> lalu diterapkan ke seluruh 14 layar MVP. Bagian 2 dan 3 di bawah ini
> menggantikan versi pertama; pola teknis (struktur folder, mekanisme
> `ThemeExtension`, aturan mode gelap) tidak berubah dan tetap diambil dari
> `new-health-duel`.

## 2. Konteks

Pemilik meminta `new-health-duel` dipakai sebagai acuan **pola teknis**
theming Flutter saja, bukan lagi acuan visual. Proyek itu punya lapisan tema
yang tertata di `lib/core/theme/`, terdiri dari berkas token (`AppSpacing`,
`AppRadius`, `AppDurations`), sebuah `ThemeExtension` bernama
`AppColorsExtension`, dan `AppTheme` yang menyusun `ThemeData` terang dan
gelap. Mekanisme ini netral terhadap domain dan netral terhadap palet —
inilah bagian yang benar-benar dipakai ulang.

Sepuluh slot warna semantik di `AppColorsExtension` milik mereka sebagian
terikat domain adu langkah: `opponent` untuk lawan, `gold` untuk juara. Slot
itu tidak punya arti di aplikasi keuangan dan tidak dipertahankan.

Saldough butuh slot yang tidak ada di sana. Baris anggaran punya tiga status
yang harus terbaca sekilas: nominalnya diketik manual, nominalnya dihitung
dari sumber lain, atau baris itu hasil rollover yang belum ditinjau. Status
ketiga adalah jawaban langsung atas nyeri utama pemilik.

Bahasa visualnya sendiri — warna, tipografi, tekstur, motif — **bukan** dari
`new-health-duel` dan bukan dari riset fintech generik. Itu adalah keputusan
gaya pemilik secara langsung, diverifikasi lewat satu canvas percobaan
sebelum diterapkan ke seluruh aplikasi. Saldough adalah aplikasi pribadi satu
pengguna, bukan produk komersial yang perlu membangun kepercayaan visual
massal, sehingga preferensi pribadi ini sah sebagai keputusan desain, bukan
sesuatu yang perlu diperdebatkan ulang.

## 3. Keputusan

Saldough mengadopsi struktur lapisan tema `new-health-duel` apa adanya untuk
**pola teknisnya**, dan mengganti **bahasa visualnya** total dengan gaya
komik/meme yang dipilih pemilik — bukan memetakan ulang palet mereka,
merancang sistem baru dari nol.

Yang diambil tanpa perubahan dari `new-health-duel` (pola teknis):

- Susunan folder `core/theme/` dengan barrel, `tokens/`, dan `extensions/`.
- Token sebagai `abstract final class` berkonstruktor privat, dengan komentar
  penggunaan di tiap nilai.
- Skala jarak berbasis 4 piksel: 4, 8, 16, 24, 32, 48, 64.
- Skala sudut dua tingkat, yaitu `double` mentah ditambah getter `BorderRadius`.
- `ThemeExtension` berpasangan dengan ekstensi `BuildContext`, lengkap dengan
  nilai cadangan aman kalau ekstensi tidak ditemukan.
- Aturan mode gelap: batas rambut (di Saldough: garis tepi tebal `edge`)
  menggantikan bayangan lembut — bedanya, gaya komik memakai bayangan keras
  offset (*hard offset shadow*, bukan blur) sebagai elemen gaya yang
  disengaja, bukan bayangan lembut material standar.
- Palet dasar dan tangga latar bertingkat.

Yang diganti total (bahasa visual, murni keputusan pemilik):

- **Palet warna.** Bukan dark sports-tech neon, bukan "Ledger Tenang" hasil
  riset — palet pop-art datar kontras tegas. Lihat tabel di bawah.
- **Tipografi.** Bukan Syne/DM Sans — tiga peran huruf terpisah: Archivo
  Black untuk angka, Space Grotesk untuk teks, Bangers untuk label/badge
  berteriak.
- **Motif dekoratif.** Garis tepi tebal hitam/krem di semua panel, bayangan
  keras offset, tekstur halftone (titik-titik) dekoratif, badge berotasi
  ringan ala stiker, balon kata komik untuk penjelasan `rollUp`.

Slot warna semantik (nama slot dipertahankan dari struktur `new-health-duel`,
nilainya baru sepenuhnya):

| Slot Saldough | Gelap | Terang | Dipakai untuk |
|---|---|---|---|
| `income` | `#3DDC68` | `#1E9E46` | Nominal masuk, sisa positif |
| `expense` | `#FF4D6A` | `#E13553` | Nominal keluar |
| `overBudget` | `#FF8C3D` | `#F07B12` | Sisa negatif |
| `investment` | `#FFD23F` | `#D99B00` | Pos tujuan dan alokasi |
| `rollUp` | `#5B9CFF` | `#2D6FE0` | Baris yang nominalnya dihitung dari sumber lain |
| `needsReview` | `#FFE14D` | `#FFD400` | Baris rollover yang belum dikonfirmasi |

`needsReview` dipakai sebagai warna isian badge (bukan hanya teks), sehingga
butuh warna teks-di-atasnya tersendiri: `onNeedsReview` = `#14120F` (gelap)
dan `#161310` (terang) — teks gelap di atas kuning tetap terbaca di kedua
mode.

Slot netral, diturunkan dari palet komik yang sudah diverifikasi di Design
Canvas (`--bg`, `--card`, `--ink`, `--sub`, `--edge`):

| Slot | Gelap | Terang | Dipakai untuk |
|---|---|---|---|
| `background` | `#0E0D0B` | `#F2E9D8` | Dasar layar (kertas koran hangat, bukan putih pucat di mode terang) |
| `cardBackground` | `#1C1A17` | `#FFFFFF` | Dasar panel/kartu |
| `edge` | `#F2E9D8` | `#161310` | Garis tepi tebal komik (`border: 2.5–3px solid`) |
| `textPrimary` | `#F2E9D8` | `#161310` | Teks utama |
| `textMuted` | `#B9AF9E` | `#5B5346` | Teks sekunder/keterangan |
| `divider` | `rgba(edge, .18)` | `rgba(edge, .14)` | Pemisah baris di dalam satu panel — dipakai jarang, gaya komik lebih mengandalkan garis tepi tebal daripada garis pembagi tipis |
| `shimmerBase` | `#1C1A17` | `#EFE6D2` | Dasar skeleton loading |
| `shimmerHighlight` | `#29271F` | `#FFFFFF` | Kilau skeleton loading |

Tidak ada lagi kekurangan yang perlu diperbaiki dari sisi struktur (elevasi,
`muted`, widget bersama) — ketiganya sudah benar sejak versi pertama ADR ini
dan tetap dipertahankan:

- `AppElevation` sebagai berkas token tersendiri.
- Slot teks `muted` (sekarang `textMuted`) untuk hierarki teks tiga tingkat.
- `AppCard`, `AppButton`, `AppChip`, dan `AppMoneyText` sejak fase fondasi.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Menyalin persis palet `new-health-duel`** *(dipilih di versi
  pertama ADR ini, sekarang ditolak)*
- **Opsi B — Riset UX fintech, satu aksen kuat, nada tenang ("Ledger
  Tenang")** *(diusulkan lewat `AskUserQuestion`, ditolak pemilik)*
- **Opsi C — Gaya komik/meme sesuai pilihan eksplisit pemilik (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Menyalin persis palet `new-health-duel` (ditolak)

Paling konsisten dengan repositori acuan dan paling cepat. Tapi pemilik
menilai hasilnya jelek begitu dilihat di Design Canvas nyata — keputusan
desain yang sah untuk aplikasi pribadi, apa pun alasan teknisnya. Slot
`opponent`/`gold` juga tidak punya arti di domain keuangan dan slot yang
dibutuhkan (`rollUp`, `needsReview`) tetap tidak ada.

### Opsi B — Riset UX fintech, "Ledger Tenang" (diusulkan, ditolak)

Selaras dengan tren fintech 2026 (satu aksen kuat, nada tenang, angka padat
tapi terbaca) dan akan lebih mudah dipertahankan kalau aplikasi ini pernah
dipakai lebih dari satu orang. Disampaikan lewat `AskUserQuestion` dengan
rekomendasi eksplisit.

Pemilik menolaknya secara langsung dan memilih arah yang justru
berkebalikan. Opsi ini tidak dipaksakan karena Saldough adalah aplikasi
pribadi satu pengguna — preferensi pemilik menang atas rekomendasi riset
generik.

### Opsi C — Gaya komik/meme (Dipilih)

Cocok dengan permintaan eksplisit pemilik, sudah divalidasi lewat satu
canvas percobaan sebelum diterapkan penuh (bukan tebakan satu arah tanpa
konfirmasi), dan "chaos" dibatasi ke elemen dekoratif (stiker, rotasi,
tekstur) sementara baris data/angka tetap rapi dalam grid — maximalist
direction yang tetap dieksekusi rapi, bukan benar-benar berantakan.

Kelemahannya: bertentangan dengan konvensi fintech mainstream (nada tenang,
satu aksen). Diterima karena Saldough bukan produk yang perlu membangun
kepercayaan massal — dipakai satu orang yang memang menyukainya.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Status baris anggaran terbaca dari warnanya tanpa membuka detail.
- Nama slot warna mencerminkan domain, sehingga kode lebih mudah dibaca.
- Widget bersama sejak awal mencegah pengulangan dekorasi kartu.
- Desain terasa personal dan menyenangkan dipakai setiap hari — inilah
  tujuan eksplisit pemilik saat memilih gaya ini.

### Yang menjadi lebih sulit

- Pemetaan slot harus dijaga konsisten. Memakai `income` untuk hal selain
  pemasukan akan merusak keterbacaannya.
- Enam slot semantik plus `onNeedsReview` menuntut pemeriksaan kontras di
  kedua mode — kuning (`needsReview`/`investment`) di atas terang perlu
  perhatian ekstra.
- Motif dekoratif (bayangan keras, rotasi, halftone) harus dibatasi ke
  elemen non-data supaya baris angka tetap terbaca cepat.

### Risiko yang diterima

- Gaya ini bertentangan dengan konvensi fintech arus utama. Diterima penuh
  atas preferensi pemilik untuk aplikasi pribadi.
- Huruf diambil saat runtime lewat `google_fonts` (Archivo Black, Space
  Grotesk) kecuali Bangers yang juga tersedia di Google Fonts. Tampilan
  pertama tanpa koneksi memakai huruf cadangan. Diterima, tetapi setiap gaya
  teks wajib mendeklarasikan tumpukan huruf cadangan yang nyata.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Palet terang lengkap didefinisikan di `:root` konseptual, yaitu nilai
  bawaan kelas token (field `static const` di `AppColorsExtension.light`).
  Mode gelap (`AppColorsExtension.dark`) hanya menimpa nilai yang berbeda.
- Warna tidak pernah ditulis harfiah di dalam widget. Selalu lewat
  `context.appColors` atau `Theme.of(context).colorScheme`.
- Jarak, sudut, dan durasi tidak pernah ditulis sebagai angka harfiah. Selalu
  lewat `AppSpacing`, `AppRadius`, dan `AppDurations`.
- Nominal ditampilkan lewat `AppMoneyText`, yang menerapkan pembulatan
  setengah ke atas dan memilih slot warna berdasarkan tanda nilainya.
- Angka uang selalu huruf Archivo Black dengan
  `fontVariations`/`fontFeatures` tabular (angka sejajar kolom). Label/badge
  pendek boleh Bangers. Teks body selalu Space Grotesk.
- Garis tepi tebal (2.5–3px) dan bayangan keras offset adalah motif,
  bukan opsional — jangan diam-diam diganti bayangan `Material` standar
  (`elevation` bawaan) di mode terang maupun gelap.

### Pola yang diikuti

- `AppColorsExtension` mengimplementasikan `copyWith` dan `lerp` untuk
  seluruh slot, supaya transisi tema mulus.
- Ekstensi `BuildContext` memakai nilai cadangan, mengikuti pola
  `Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light`,
  sehingga tidak pernah melempar.

### Antipola yang harus dihindari

- Mempertahankan nama slot `opponent` atau `gold`.
- Memakai bayangan lembut `Material` standar alih-alih bayangan keras
  offset — ini membuat panel terlihat seperti aplikasi Material generik,
  bukan gaya komik.
- Memakai `expense` untuk sisa negatif. Sisa negatif memakai `overBudget`.
- Menyalin warna/tipografi `new-health-duel` apa adanya — bagian itu sudah
  diganti total, bukan dipetakan ulang.

## 8. Kriteria peninjauan ulang

- Aplikasi dipakai lebih dari satu orang, sehingga preferensi visual perlu
  dinegosiasikan ulang.
- Pemeriksaan kontras menunjukkan slot tertentu (terutama kuning di atas
  terang) gagal memenuhi ambang keterbacaan.
- Laporan dan grafik masuk cakupan, sehingga dibutuhkan palet kategorikal
  untuk visualisasi data.

## 9. Artefak terkait

### Dokumentasi

- PRD bagian 10 untuk prinsip antarmuka.
- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian struktur
  core.
- [UI_UX_DESIGN_TASKS.md](../../04-planning/UI_UX_DESIGN_TASKS.md) untuk
  riwayat pivot gaya komik dan canvas percobaan yang memverifikasinya.

### Rujukan kode

- `new-health-duel/health_duel/lib/core/theme/` — **pola teknis saja**
  (struktur folder, mekanisme `ThemeExtension`), bukan lagi acuan nilai.
- Design Canvas komik (`Main.dc.html`/`AppLight.dc.html`) — sumber nilai hex
  dan font-family yang dipakai tabel di atas, diverifikasi visual sebelum
  dikodekan.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09, direvisi 2026-09-10
**Status implementasi:** Disetujui, diimplementasikan di Fase 1
