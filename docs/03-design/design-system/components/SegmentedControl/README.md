# SegmentedControl

Pilihan satu dari dua sampai empat opsi yang saling meniadakan, langsung mengubah isi di bawahnya.

**Dipakai untuk:** jenis transaksi di Catat (Pengeluaran, Pemasukan, Transfer), status anggaran (Aktif, Selesai, Nonaktif), kotak masuk (Perlu dicek, Tercatat otomatis).

**Aturan**
- Track `surface-2`, segmen terpilih `surface-raised` dengan `shadow-raised` dan teks `ink`. Segmen lain `ink-2`.
- Jumlah item boleh ditampilkan setelah label (`tk-seg__count`).
- Label maksimal dua kata; di lebar 360dp tiga segmen masih muat untuk "Pengeluaran".
- Jangan dipakai untuk filter yang bisa dipilih banyak; pakai Chip.
- Peran aksesibilitas: `radiogroup` dan `radio`.

**Disediakan pemakai:** opsi, opsi terpilih, handler ganti.
