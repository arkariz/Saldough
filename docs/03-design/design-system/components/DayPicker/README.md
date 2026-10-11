# DayPicker

Lembar Awal bulan keuangan: memilih tanggal mulai (1–28 atau hari terakhir bulan), melihat akibatnya, lalu menyimpan.

**Anatomi (urutan dari atas)**
1. Sheet form: pegangan, tombol tutup, judul "Awal bulan keuangan", bantuan "Biasanya tanggal gajian." (`body-sm` `ink-2`).
2. Kisi tanggal `tk-daygrid`: tujuh kolom, 1–28 dalam empat baris, lalu "Hari terakhir bulan" selebar baris (`tk-day--wide`). Kotak `surface-2` bersudut piksel; terpilih `brand-soft` dengan garis dalam `brand` 2px dan teks `brand-ink`. Saat dibuka, yang terpilih adalah tanggal yang aktif.
3. Pratinjau, hanya bila tanggal terpilih berbeda dari yang aktif: `tk-inset` berisi judul `body-strong` ("Mulai tanggal 1"), kalimat periode peralihan, garis waktu `tk-ptl`, lalu "Periode sebelumnya tidak berubah." `ink-2`.
4. Garis waktu `tk-ptl`: tiga ruas selebar jumlah harinya. Periode sebelumnya dan berikutnya `line-strong`, periode peralihan `ink`: hanya ruas tengah yang menonjol karena hanya ia yang berubah. Di bawahnya hanya dua tanggal batas. Garis waktu menggambarkan kalimat di atasnya, tidak menambah informasi.
5. Bagian "Anggaran rutin", hanya bila ada anggaran rutin yang patokannya sama dengan awal lama: judul `body-strong`, kalimat penjelas `body-sm` `ink-2` ("Yang dicentang ikut mulai tanggal 25. Yang tidak, tetap mulai tanggal 1."), lalu satu baris Checkbox per anggaran, bawaan tercentang. Subjudul tiap baris menyebut akibatnya: "Berjalan sampai 24 Okt, berikutnya mulai 25 Okt" atau "Tetap mulai tanggal 1". Dua anggaran atau lebih: tautan "Pilih semua" / "Kosongkan" di kanan judul. Daftar panjang ikut tergulir di dalam lembar; tidak ada lembar kedua. Bukan Switch: ini pilihan banyak-dari-banyak yang baru berlaku saat disimpan.
6. Tindakan menempel di bawah: "Batal" (`text`) dan "Simpan" (`primary`). Simpan nonaktif selama tanggal terpilih sama dengan yang aktif.

**Aturan**
- Tanggal 29–31 tidak ditawarkan; "Hari terakhir bulan" yang menggantikannya.
- Target sentuh tiap tanggal adalah sel kisi penuh: 48px tinggi, sekitar 46px lebar di 360dp. Kotak yang terlihat lebih kecil supaya kisi tetap lega.
- Tanpa warna peringatan di pratinjau. Periode peralihan adalah akibat yang dijelaskan, bukan bahaya.
- Lembar yang sama dibuka dari kepala Bulan ini (PeriodHeader) dan dari Akun.

**Disediakan pemakai:** tanggal aktif, tanggal terpilih, teks pratinjau, panjang tiga ruas dan dua tanggal batas, daftar anggaran rutin, handler simpan dan batal.
