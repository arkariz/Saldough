# Card

Permukaan `surface` rata untuk satu kelompok isi, dengan judul bagian di luarnya.

**Aturan**
- Sudut piksel (`pixel-step`), padding `space-4`, tanpa bingkai, tanpa bayangan. Kartu yang berisi daftar memakai `tk-list` (tanpa padding).
- Judul bagian (`tk-section__title`) duduk di atas kartu, di atas `bg`, dengan tautan opsional di kanan ("Lihat semua", "Riwayat").
- Jangan menaruh kartu di dalam kartu. Pengelompokan di dalam kartu memakai jarak dan `tk-divider`.
- Ringkasan angka bergaya buku kas: label di kiri, nominal rata kanan, garis pemisah sebelum baris hasil (Selisih, Sisa).
- Seluruh kartu boleh jadi target sentuh bila membuka satu tujuan.

**Disediakan pemakai:** isi, judul bagian, tautan opsional.
