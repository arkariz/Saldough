# SubTabs

Segmen di dalam satu tab: berpindah antarbagian yang setara, tepat di bawah bar atas.

**Dipakai untuk:** Rencana (Bulan ini, Anggaran, Rutin) dan Riwayat (Daftar, Analisis).

**Aturan**
- Dua atau tiga segmen, lebar sama. Label satu kata.
- Segmen aktif: teks `ink` dengan garis `brand` 40×4px di bawahnya. Segmen lain `ink-2`.
- Garis `line` 1px di bawah seluruh baris. Latar `bg`, menempel di bawah bar atas.
- Ini navigasi, bukan penyaring: isi di bawahnya berganti seluruhnya. Untuk pilihan yang mengubah isi satu kartu, pakai SegmentedControl.
- Segmen terakhir yang dibuka diingat per perangkat bila dokumen fiturnya memintanya (Riwayat).
- Peran aksesibilitas: `navigation` dengan `aria-current="page"` pada segmen aktif.

**Disediakan pemakai:** label segmen, segmen aktif, handler pindah.
