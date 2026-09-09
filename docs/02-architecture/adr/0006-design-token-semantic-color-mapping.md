# Token desain dan pemetaan warna semantik

## 1. Metadata

- **Decision ID:** ADR-006
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Pemilik meminta `new-health-duel` dipakai sebagai acuan tema. Proyek itu punya
lapisan tema yang tertata di `lib/core/theme/`, terdiri dari berkas token
(`AppSpacing`, `AppRadius`, `AppDurations`), sebuah `ThemeExtension` bernama
`AppColorsExtension`, dan `AppTheme` yang menyusun `ThemeData` terang dan gelap.

Bahasa visualnya adalah dark sports-tech: latar hampir hitam kebiruan
(`#080C10`), satu aksen hijau neon (`#00E5A0`), jingga sebagai warna lawan
(`#FF6B35`), kartu berbatas rambut tanpa bayangan, sudut membulat besar, dan
pasangan huruf Syne untuk angka dengan DM Sans untuk teks.

Sepuluh slot warna semantik di `AppColorsExtension` sebagian terikat domain
adu langkah: `opponent` untuk lawan, `gold` untuk juara. Slot itu tidak punya
arti di aplikasi keuangan.

Sebaliknya, Saldough butuh slot yang tidak ada di sana. Baris anggaran punya
tiga status yang harus terbaca sekilas: nominalnya diketik manual, nominalnya
dihitung dari sumber lain, atau baris itu hasil rollover yang belum ditinjau.
Status ketiga adalah jawaban langsung atas nyeri utama pemilik.

Pemeriksaan juga menemukan tiga kekurangan di lapisan tema `new-health-duel`
yang sebaiknya tidak ikut disalin. Tidak ada berkas token elevasi, sehingga
nilainya ditulis harfiah di dalam `ThemeData`. Warna paling redup di mockup,
`#4A6070`, tidak pernah dipindahkan ke Dart, sehingga hierarki teks kehilangan
tingkat ketiga. Dan tidak ada widget kartu bersama, sehingga
`Container(decoration: BoxDecoration(...))` yang sama diulang di sekitar delapan
berkas.

## 3. Keputusan

Saldough mengadopsi struktur lapisan tema `new-health-duel` apa adanya, dan
memetakan ulang slot warna semantiknya ke konteks keuangan.

Yang diambil tanpa perubahan:

- Susunan folder `core/theme/` dengan barrel, `tokens/`, dan `extensions/`.
- Token sebagai `abstract final class` berkonstruktor privat, dengan komentar
  penggunaan di tiap nilai.
- Skala jarak berbasis 4 piksel: 4, 8, 16, 24, 32, 48, 64.
- Skala sudut dua tingkat, yaitu `double` mentah ditambah getter `BorderRadius`.
- `ThemeExtension` berpasangan dengan ekstensi `BuildContext`, lengkap dengan
  nilai cadangan aman kalau ekstensi tidak ditemukan.
- Pasangan huruf Syne untuk tampilan dan angka, DM Sans untuk teks.
- Aturan mode gelap: batas rambut menggantikan bayangan.
- Palet dasar dan tangga latar empat tingkat.

Slot warna semantik dipetakan ulang menjadi:

| Slot Saldough | Gelap | Terang | Dipakai untuk |
|---|---|---|---|
| `income` | `#00E5A0` | `#00A87A` | Nominal masuk, sisa positif |
| `expense` | `#FF4D6A` | `#D92D4E` | Nominal keluar |
| `overBudget` | `#FF6B35` | `#E85A24` | Sisa negatif |
| `investment` | `#FFC94A` | `#D4A020` | Pos tujuan dan alokasi |
| `rollUp` | `#38B6FF` | `#0E89C4` | Baris yang nominalnya dihitung dari sumber lain |
| `needsReview` | `#FBBF24` | `#F59E0B` | Baris rollover yang belum dikonfirmasi |

Slot netral tetap dipertahankan: `cardBackground`, `subtleBackground`,
`divider`, `shimmerBase`, dan `shimmerHighlight`.

Tiga kekurangan yang ditemukan diperbaiki sejak awal:

- Menambah `AppElevation` sebagai berkas token tersendiri.
- Menambah slot teks `muted` bernilai `#4A6070` pada mode gelap, sehingga
  hierarki teks punya tiga tingkat.
- Membuat `AppCard`, `AppButton`, `AppChip`, dan `AppMoneyText` sejak fase
  fondasi, sebelum pengulangan sempat muncul.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Menyalin persis termasuk paletnya**
- **Opsi B — Mengambil strukturnya, memetakan ulang warna semantiknya (Dipilih)**
- **Opsi C — Merancang sistem desain baru untuk konteks keuangan**

## 5. Analisis konsekuensi

### Opsi A — Menyalin persis termasuk paletnya

Paling konsisten dengan repositori acuan dan paling cepat. Tidak ada keputusan
desain yang perlu diambil.

Tetapi slot `opponent` dan `gold` tidak punya arti di aplikasi keuangan, dan
membiarkannya berarti kode Saldough memakai nama yang menyesatkan sepanjang
umur proyek. Slot yang benar-benar dibutuhkan, terutama `rollUp` dan
`needsReview`, tetap tidak ada.

### Opsi B — Mengambil strukturnya, memetakan ulang warna semantiknya (Dipilih)

Struktur token, mekanisme `ThemeExtension`, pasangan huruf, dan aturan mode
gelap adalah bagian yang benar-benar bernilai untuk dipakai ulang, dan semuanya
netral terhadap domain. Yang terikat domain hanya nama slotnya, dan itu murah
diganti.

Pemetaannya juga wajar secara visual. Hijau neon sudah berarti positif, jadi
cocok untuk pemasukan. Jingga sudah berarti keadaan yang menuntut perhatian,
jadi cocok untuk lewat anggaran. Emas sudah berarti sesuatu yang dikumpulkan,
jadi cocok untuk investasi.

Kelemahannya, nuansa energi olahraga terbawa ke konteks keuangan. Ini diterima
karena aplikasi dipakai satu orang yang memang menyukainya, dan karena hijau
neon di atas latar gelap tetap terbaca dengan baik untuk angka.

### Opsi C — Merancang sistem desain baru

Menghasilkan palet yang paling sesuai konteks keuangan, misalnya biru-hijau
dalam dengan aksen emas.

Tetapi butuh waktu desain yang tidak sepadan untuk aplikasi satu pengguna, dan
menghilangkan alasan menjadikan `new-health-duel` sebagai acuan tema. Nilai
utama acuan itu justru ada pada strukturnya, bukan pada paletnya.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Status baris anggaran terbaca dari warnanya tanpa membuka detail.
- Nama slot warna mencerminkan domain, sehingga kode lebih mudah dibaca.
- Widget bersama sejak awal mencegah pengulangan dekorasi kartu.

### Yang menjadi lebih sulit

- Pemetaan slot harus dijaga konsisten. Memakai `income` untuk hal selain
  pemasukan akan merusak keterbacaannya.
- Enam slot semantik menuntut pemeriksaan kontras di kedua mode.

### Risiko yang diterima

- Nuansa energi olahraga terbawa ke konteks keuangan. Diterima atas preferensi
  pemilik.
- Huruf diambil saat runtime lewat `google_fonts`, sehingga tampilan pertama
  tanpa koneksi memakai huruf cadangan. Diterima, tetapi setiap gaya teks wajib
  mendeklarasikan tumpukan huruf cadangan yang nyata.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Palet terang lengkap didefinisikan di `:root` konseptual, yaitu nilai bawaan
  kelas token. Mode gelap hanya menimpa nilai yang berbeda.
- Warna tidak pernah ditulis harfiah di dalam widget. Selalu lewat
  `context.appColors` atau `Theme.of(context).colorScheme`.
- Jarak, sudut, dan durasi tidak pernah ditulis sebagai angka harfiah. Selalu
  lewat `AppSpacing`, `AppRadius`, dan `AppDurations`.
- Nominal ditampilkan lewat `AppMoneyText`, yang menerapkan pembulatan setengah
  ke atas dan memilih slot warna berdasarkan tanda nilainya.

### Pola yang diikuti

- `AppColorsExtension` mengimplementasikan `copyWith` dan `lerp` untuk seluruh
  slot, supaya transisi tema mulus.
- Ekstensi `BuildContext` memakai nilai cadangan, mengikuti pola
  `Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light`,
  sehingga tidak pernah melempar.

### Antipola yang harus dihindari

- Mempertahankan nama slot `opponent` atau `gold`.
- Menambahkan bayangan pada kartu di mode gelap. Pemisahan berasal dari batas
  rambut dan tangga nilai latar.
- Memakai `expense` untuk sisa negatif. Sisa negatif memakai `overBudget`.

## 8. Kriteria peninjauan ulang

- Aplikasi dipakai lebih dari satu orang, sehingga preferensi visual perlu
  dinegosiasikan.
- Pemeriksaan kontras menunjukkan slot tertentu gagal memenuhi ambang
  keterbacaan.
- Laporan dan grafik masuk cakupan, sehingga dibutuhkan palet kategorikal untuk
  visualisasi data.

## 9. Artefak terkait

### Dokumentasi

- PRD bagian 10 untuk prinsip antarmuka.
- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian struktur core.

### Rujukan kode

- `new-health-duel/health_duel/lib/core/theme/`
- `new-health-duel/health-duel-mockup.html` untuk nilai warna aslinya.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
