# Checkbox

Memilih beberapa dari beberapa: tiap butir bebas dicentang atau tidak, dan semuanya disimpan bersama oleh satu tombol. Dipakai di lembar Awal bulan keuangan untuk memilih anggaran rutin yang ikut pindah.

**Kapan Checkbox, kapan Switch**
- Checkbox: pilihan di dalam form atau lembar yang baru berlaku saat disimpan, terutama daftar butir sejenis ("anggaran mana yang ikut").
- Switch: setelan yang langsung berlaku dan berdiri sendiri ("Sembunyikan nominal").

**Aturan**
- Kotak 24px bersudut piksel kecil di awal baris (`tk-row--check`, bungkus `tk-list--check`). Kosong: `surface` dengan garis dalam `line-strong` 2px (3:1). Tercentang: isi `brand`, ikon `check` `on-brand`.
- Seluruh baris (`<label>`) adalah target sentuh, minimal 56px.
- Judul baris = nama butir. Subjudul = akibatnya dalam keadaan sekarang, berganti saat dicentang atau tidak ("Berjalan sampai 24 Okt, berikutnya mulai 25 Okt" / "Tetap mulai tanggal 1"). Subjudul boleh membungkus.
- Daftar diberi judul bagian dan satu kalimat penjelas di atasnya. Bila butirnya dua atau lebih, tautan "Pilih semua" (atau "Kosongkan" bila semua tercentang) di kanan judul bagian.
- Peran aksesibilitas: `checkbox` bawaan; nama = judul baris.

**Disediakan pemakai:** butir (nama, akibat dicentang, akibat tidak), keadaan centang, handler ganti.
