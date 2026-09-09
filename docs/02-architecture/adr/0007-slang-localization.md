# Terjemahan antarmuka dengan slang

## 1. Metadata

- **Decision ID:** ADR-007
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 1
- **Status:** Accepted
- **Cakupan:** Global

## 2. Konteks

Pemilik meminta slang dipakai untuk terjemahan teks antarmuka, dengan bahasa
Indonesia sebagai bahasa dasar dan bahasa Inggris sebagai tambahan.

Tidak ada satu pun repositori acuan yang bisa disalin polanya. `new-health-duel`
tidak punya terjemahan sama sekali: seluruh teksnya ditulis harfiah di dalam
widget, dan `MaterialApp.router` di sana tidak menyetel `localizationsDelegates`
maupun `supportedLocales`. Paket `intl` memang ada di sana, tetapi hanya dipakai
untuk memformat angka dan tanggal, bukan menerjemahkan.

`flutter-architecture-studi` juga tidak memakai terjemahan runtime. Teksnya
disimpan sebagai konstanta bahasa Indonesia di kelas `<fitur>_text.dart`, dan
`easy_localization` yang tercantum di pubspec hanya dipakai karena mengekspor
ulang pemformat dari `intl`.

Jadi penyiapan slang di Saldough adalah pekerjaan baru, bukan penyalinan.

Ada satu kebutuhan domain yang memengaruhi keputusan ini. Sebagian besar teks
Saldough menyertakan nominal rupiah dan tanggal. Pemformatannya tidak boleh
diserahkan ke berkas terjemahan, karena aturan pembulatan uang bersifat mengikat
dan sudah ditetapkan di [DOMAIN_MODEL.md](../DOMAIN_MODEL.md).

## 3. Keputusan

Saldough memakai slang dengan bahasa dasar `id` dan bahasa tambahan `en`.

Berkas terjemahan disimpan di `assets/i18n/`, satu berkas JSON per bahasa,
dengan namespace mengikuti nama fitur. Kode yang dihasilkan diakses lewat
`t.<namespace>.<kunci>`.

Seluruh teks yang terlihat pengguna berasal dari berkas terjemahan. Tidak ada
teks harfiah di dalam widget.

Pemformatan uang dan tanggal **tidak** ditangani slang. Keduanya ditangani
ekstensi pemformat tersendiri di `core/utils/formatters/`, dan hasilnya
disisipkan ke terjemahan sebagai parameter. Pemisahan ini menjaga aturan
pembulatan tetap berada di satu tempat, dan mencegah berkas terjemahan
menentukan perilaku uang.

Bahasa Indonesia adalah sumber kebenaran. Kunci baru ditambahkan lebih dulu di
`id`, lalu diterjemahkan ke `en`.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Konstanta teks per fitur, seperti `flutter-architecture-studi`**
- **Opsi B — `flutter_localizations` dengan berkas ARB bawaan Flutter**
- **Opsi C — slang (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Konstanta teks per fitur

Paling sederhana dan tanpa pembangkitan kode. Cocok untuk aplikasi satu bahasa,
dan itulah sebabnya `flutter-architecture-studi` memakainya.

Tetapi opsi ini tidak mendukung bahasa kedua tanpa perombakan menyeluruh, dan
pemilik meminta dua bahasa. Menunda dukungan bahasa berarti menyentuh ulang
setiap widget nanti.

### Opsi B — `flutter_localizations` dengan berkas ARB

Bawaan Flutter, tanpa dependensi pihak ketiga, dan sudah dikenal luas.

Tetapi aksesnya lewat `AppLocalizations.of(context)!` yang bisa null dan
menuntut `context`, sehingga teks tidak bisa diambil dari luar pohon widget.
Format ARB juga bertele-tele, dan kunci yang hilang di satu bahasa baru
ketahuan saat runtime.

### Opsi C — slang (Dipilih)

Akses lewat `t.cycle.title` bersifat statis dan tidak butuh `context`, sehingga
teks bisa dipakai di mana pun termasuk saat menyusun pesan efek dari bloc. Ini
cocok dengan keputusan di [ADR-0003](0003-effect-bloc-state-management.md), di
mana pesan snackbar dan dialog disusun di lapisan bloc.

Keunggulan terpentingnya, kunci yang hilang di salah satu bahasa menjadi galat
saat pembangunan, bukan saat runtime. Untuk proyek dua bahasa yang dikelola satu
orang, ini yang menjaga terjemahan tetap sinkron.

Kelemahannya, slang menambah langkah pembangkitan kode yang harus dijalankan
ulang setiap kali berkas terjemahan berubah, dan berkas hasilnya cukup besar.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Kunci terjemahan yang hilang tertangkap saat pembangunan.
- Teks bisa diakses dari bloc tanpa `context`.
- Menambah bahasa ketiga nanti cukup menambah satu berkas.

### Yang menjadi lebih sulit

- Setiap perubahan teks menuntut pembangkitan ulang kode.
- Dua berkas terjemahan harus dijaga sinkron saat menambah kunci.

### Risiko yang diterima

- Terjemahan Inggris bisa tertinggal kualitasnya, karena pemilik berbahasa
  Indonesia. Diterima; bahasa Inggris bersifat pelengkap dan bahasa Indonesia
  adalah sumber kebenaran.
- Pembangkitan kode menambah waktu pembangunan. Diterima karena jumlah teksnya
  sedang.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Namespace terjemahan mengikuti nama fitur: `cycle`, `income`, `worklog`,
  `grocery`, `card`, `investment`, ditambah `common` untuk teks bersama.
- Nominal disisipkan sebagai parameter yang sudah diformat, bukan diformat di
  dalam berkas terjemahan. Contoh kunci: `"remainderLabel": "Sisa $amount"`.
- Bentuk jamak dan gender memakai fitur bawaan slang, bukan penggabungan string
  manual.
- Berkas terjemahan tidak memuat nama merchant, nama pos tujuan, atau label
  baris. Semua itu adalah data milik pengguna, bukan teks antarmuka.

### Pola yang diikuti

- Pemformat uang dan tanggal berada di `core/utils/formatters/`, memakai `intl`,
  mengikuti pola ekstensi di `new-health-duel/lib/core/utils/extensions/`.
- Pemformat uang menerapkan pembulatan setengah ke atas dari satuan sen ke
  rupiah, sesuai [DOMAIN_MODEL.md](../DOMAIN_MODEL.md).

### Antipola yang harus dihindari

- Menulis teks harfiah di dalam widget.
- Memformat uang atau tanggal di dalam berkas terjemahan.
- Menyusun kalimat dengan menggabungkan beberapa kunci terjemahan, karena urutan
  kata berbeda antar bahasa.
- Menerjemahkan data milik pengguna.

## 8. Kriteria peninjauan ulang

- Bahasa ketiga dibutuhkan, sehingga beban penyelarasan meningkat.
- Aplikasi diterbitkan ke publik, sehingga kualitas terjemahan Inggris menjadi
  penting.
- slang tidak lagi dipelihara.

## 9. Artefak terkait

### Dokumentasi

- PRD NFR-UX-004.
- [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) bagian aturan representasi uang.
- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) bagian struktur core.

### Rujukan kode

- `new-health-duel/health_duel/lib/core/utils/extensions/` sebagai acuan pola
  pemformat.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
