# IconTile

Persegi membulat berwarna yang membawa ikon kategori, dompet, atau sumber notifikasi.

**Dua varian**
- Piksel (`tk-tile--px`): ikon piksel Tanukonomy 32px di tile `surface-2`. Untuk semua kategori dan dompet yang punya ikon piksel.
- Garis (`tk-tile--<warna>`): Material Symbols di tile berwarna `cat-*`. Untuk kategori yang belum punya ikon piksel dan untuk kategori buatan pengguna.

**Aturan**
- Ukuran `size-tile` (40px) di baris, 32px di chip dan baris padat, 48px di kepala rincian.
- Warna dari pasangan `cat-*-bg` + `cat-*` sesuai tabel di README; transfer memakai `info-soft` + `info`.
- Kategori buatan pengguna memilih salah satu dari 10 warna; ikon dipilih dari daftar Material Symbols yang disediakan.
- Sumber notifikasi (aplikasi bank, e-wallet): `--app` dengan inisial dua sampai tiga huruf. Jangan menggambar ulang logo bank.
- Hanya tile yang berwarna; teks dan latar baris tetap netral.

**Disediakan pemakai:** ikon, warna kategori atau jenis dompet.
