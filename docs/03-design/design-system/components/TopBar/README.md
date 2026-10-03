# TopBar

Bar atas halaman: judul besar di halaman tab, tombol kembali dan judul `title` di halaman turunan.

**Varian**
- Tab: judul `headline` rata kiri, paling banyak dua tombol ikon di kanan (cari, filter, profil, sembunyikan nominal).
- Turunan (`--sub`): kembali, judul `title`, menu `more_vert` untuk tindakan jarang (Sunting, Arsipkan, Hapus).

**Aturan**
- Judul adalah nama layar, bukan label langkah seperti "Catat // Transaksi".
- Tanpa garis bawah; saat isi digulir, bar mendapat latar `surface` dan `shadow-bar`.
- Tindakan utama halaman turunan tidak ditaruh di sini, tetapi menempel di bawah layar.

**Disediakan pemakai:** judul, tombol ikon beserta label aksesibilitasnya, handler kembali.
