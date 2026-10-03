# Amount

Tampilan nominal uang dengan aturan tanda, warna, dan ukuran yang sama di seluruh aplikasi.

**Aturan tanda dan warna**
- Pengeluaran: `−Rp45.000` (minus U+2212), warna `ink`.
- Pemasukan: `+Rp8.500.000`, warna `positive`.
- Transfer: `Rp300.000` tanpa tanda, warna `ink-2`.
- Saldo dan sisa: tanpa tanda; negatif ditulis `−Rp36.000` dan diberi badge, bukan hanya warna.
- Disembunyikan (tombol mata di Beranda): `Rp•••••` di semua nominal sekaligus.

**Ukuran:** `amount-display` (Catat), `amount-hero` (satu angka utama layar, "Rp" diperkecil di depan), `amount-lg` (kartu), `amount` (baris), `amount-sm` (pendukung). Semua memakai angka tabular.

**Disediakan pemakai:** nilai dalam sen (`int`), jenis (pengeluaran, pemasukan, transfer, saldo), ukuran. Format mata uang dari setelan aplikasi.
