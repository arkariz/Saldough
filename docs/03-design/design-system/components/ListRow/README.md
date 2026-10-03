# ListRow

Baris daftar: transaksi, dompet, pos anggaran, baris form, dan baris setelan.

**Anatomi:** awal (tile ikon 40px atau ikon 24px) → isi (judul `body-strong`, subjudul `body-sm` `ink-2`) → akhir (nominal, badge, chevron, atau switch). Tinggi minimal 64px, 56px untuk varian `--compact`.

**Varian**
- Transaksi: judul = catatan atau nama kategori; subjudul = "Dompet · jam"; akhir = nominal bertanda. Transfer: "BCA → Tunai".
- Perlu tindakan: badge "Perlu dicek" di bawah nominal. Jangan mewarnai latar baris.
- Baris form (Catat, form dompet): label `tk-row__label` di atas nilai, chevron di akhir.
- Setelan: ikon 24px, judul, subjudul opsional, switch atau chevron. Bungkus dengan `tk-list--icon` agar garis pemisah sejajar teks.

**Aturan**
- Baris di dalam `tk-list` (kartu tanpa padding); pemisah `line` menjorok sejajar awal teks.
- Seluruh baris adalah satu target sentuh. Tekan: latar `surface-2`.
- Judul satu baris dengan elipsis; nominal tidak pernah terpotong.

**Disediakan pemakai:** ikon/tile, judul, subjudul, isi akhir, handler.
