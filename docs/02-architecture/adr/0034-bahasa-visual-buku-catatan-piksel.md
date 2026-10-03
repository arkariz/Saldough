# Bahasa visual baru: buku catatan dengan aksen piksel

## 1. Metadata

- **Decision ID:** ADR-034
- **Tanggal:** 2026-10-03
- **Fase roadmap:** Fase 14 (bahasa visual baru)
- **Status:** Accepted (keputusan pemilik 3 Okt 2026, setelah tiga putaran
  review sampel)
- **Cakupan:** Global — `lib/core/theme/`, `lib/core/presentation/`, semua
  layar fitur, `assets/fonts/`, `pubspec.yaml`
- **Menggantikan:** [ADR-015](0015-adopsi-bahasa-visual-pixel-kas.md),
  [ADR-016](0016-revisi-palet-satu-peran-satu-warna.md),
  [ADR-020](0020-hierarki-penekanan-bahasa-visual-pixel.md)
- **Mengubah:** [ADR-031](0031-pixeltheme-jadi-tema-global.md) — mekanismenya
  tetap (satu tema global di `MaterialApp`), isinya diganti oleh sistem ini
- **Sumber kebenaran desain:** dua artefak di akun pemilik (§3.1), dengan
  salinan di [`docs/03-design/`](../../03-design/README.md)

## 2. Konteks

Pemilik menilai tampilan aplikasi berantakan, tidak enak dibaca, dan tata
letaknya jelek (3 Okt 2026). Pembacaan tangkapan layar dan tema menemukan
penyebabnya:

- Tiga keluarga huruf, ditambah label monospace kapital di hampir setiap
  kartu ("TOTAL KAS AKTIF", "DOMPET SUMBER DANA").
- Bingkai hitam 2–3px dan bayangan keras di setiap kartu, kartu di dalam
  kartu, dan latar berwarna per jenis transaksi.
- Merah untuk semua pengeluaran (mayoritas isi Riwayat), dan warna aksi
  oranye-merah yang nyaris sama dengan merah pengeluaran.
- Informasi diulang (banner "Aturan Kas", baris saldo sebelum→sesudah, dan
  ringkasan di bawah formulir Catat menyatakan hal yang sama).
- Istilah tidak konsisten: kas, log, netto, mutasi, kantong, inventaris.
- Dua FAB bertumpuk (suara dan CATAT).

Prosesnya bertahap lewat sampel satu layar (Beranda):

1. Versi polos tanpa piksel: pemilik suka, tetapi terasa generik dan
   nuansa pikselnya hilang.
2. Dua takaran piksel (ringan dan sedang): pemilik memilih **sedang tanpa
   huruf piksel**.
3. Sampel layar Catat dengan gaya itu, lalu diterapkan ke semua layar
   prototipe.

## 3. Keputusan

### 3.1 Sumber kebenaran

| Artefak | Isi |
|---|---|
| [Tanukonomy Design System](https://claude.ai/artifact/HHq7YfEY5Wtc1JXtBhzBQS) | Token (warna terang/gelap, tipografi, jarak, sudut, ukuran), 20 komponen dengan pratinjau, panduan menulis, pola layar, catatan Flutter, aset (logo, ilustrasi, 41 ikon piksel) |
| [Tanukonomy Halaman Baru](https://claude.ai/artifact/L4176HPgR9gCXACe3gyRbZ) | Prototipe 12 layar yang bisa diklik (Beranda, Riwayat, Anggaran, Dompet, Catat, Catat pakai suara, Kotak masuk, Rincian anggaran, Freelance, Akun, Beranda pertama kali, mode gelap) |
| [Sampel Beranda](https://claude.ai/artifact/UHo61QLURngZRqFLPNd7Ko) | Riwayat review: tampilan lama, polos, piksel ringan, piksel sedang, dan sampel Catat |

Artefak itu privat milik pemilik. Agen yang berjalan di akun pemilik
membacanya dengan alat Artifact (`action: "read"`, `path:
"project/README.md"`). Salinan di `docs/03-design/` dipakai bila artefak
tidak terjangkau dan wajib diperbarui setiap kali artefak berubah.
Kalau keduanya berbeda, artefak yang benar.

### 3.2 Prinsip

1. Satu layar menjawab satu pertanyaan; satu angka utama per layar.
2. Warna berarti sesuatu: netral untuk hal biasa, terakota (`brand`) untuk
   tindakan, hijau/kuning/merah hanya untuk status dan selalu bersama teks.
   Pengeluaran berwarna tinta biasa, bukan merah.
3. Kelompokkan dengan ruang dan permukaan, bukan bingkai.
4. Satu istilah satu makna (glosarium di `writing.md`).
5. Tindakan utama di bawah, target sentuh minimal 48dp.

### 3.3 Fondasi

- **Huruf:** hanya Plus Jakarta Sans (sudah dibundel). Space Grotesk dan
  Space Mono dihapus. Angka tabular. Tanpa kapital semua, tanpa monospace,
  **tanpa huruf piksel**.
- **Warna:** terakota dari ikon aplikasi (`brand` `#A94F33` terang,
  `#EE8A63` gelap), netral hangat, status `positive`/`warning`/`danger`,
  pasangan warna kategori untuk tile. Semua pasangan teks lolos 4,5:1 di
  kedua tema (dihitung, bukan diperkirakan).
- **Aksen piksel (takaran "sedang"):**
  - sudut bertangga dua langkah di semua permukaan (`pixel-step` 4px untuk
    kartu, `pixel-step-sm` 2px untuk kontrol kecil);
  - ikon piksel milik Tanukonomy (`assets/icons/`, 32px) untuk *benda*:
    kategori, dompet, transfer, freelance;
  - bar anggaran tersusun dari kotak 6px;
  - kartu saldo terakota dengan kepala tanuki di Beranda;
  - tombol Catat kotak dengan bayangan piksel keras.
- **Ikon antarmuka:** Material Symbols Rounded untuk navigasi dan tindakan.
- **Navigasi:** empat tab (Beranda, Riwayat, Anggaran, Dompet) dengan
  tombol Catat di tengah. Catat pakai suara pindah ke dalam sheet Catat
  (tombol mikrofon; tekan lama tombol Catat). FAB kedua dihapus.

### 3.4 Yang tidak berubah

Domain, rute, bloc, dan aturan "mencatat, bukan melakukan". Tur spotlight
(ADR-021) tetap; targetnya menyesuaikan widget baru. Ilustrasi tanuki
tetap.

## 4. Konsekuensi

- Seluruh layar ditulis ulang tampilannya; perilaku dan uji domain tidak
  disentuh. Uji widget yang memeriksa warna atau widget lama ikut diganti.
- `pubspec.yaml` mendapat `material_symbols_icons`; dua berkas huruf dihapus.
- Ikon piksel belum lengkap: Keluarga, Donasi, Bonus, Hadiah, Lainnya, dan
  akun memakai Material Symbols di tile berwarna sampai artwork pemilik ada
  (B-22). Garis tepi gelap ikon piksel butuh varian mode gelap (B-23).
- Tangkapan layar situs `tanukonomy-web` perlu dirender ulang setelah
  implementasi (B-4).
- Usulan baru yang ikut di prototipe dan disetujui bersama desainnya:
  tombol sembunyikan nominal, penanda waktu di bar anggaran, bar sebaran
  saldo per dompet, daftar langkah Beranda pertama kali, Freelance dibuka
  dari kartu Beranda.

## 5. Alternatif yang ditolak

- **Mempertahankan ADR-015 dan merapikan saja:** sumber keluhan ada di
  fondasinya (huruf, bingkai, warna), bukan di detail.
- **Tanpa piksel sama sekali:** pemilik menilai generik.
- **Piksel ringan / huruf piksel:** huruf piksel ditolak pemilik; takaran
  ringan kurang membedakan dari aplikasi lain.
