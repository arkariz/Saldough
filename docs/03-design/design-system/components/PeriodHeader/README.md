# PeriodHeader

Nama periode keuangan yang sedang dilihat, sekaligus pintu ke lembar Awal bulan keuangan. Penanda periode peralihan ikut di sini.

**Isi**
- Awal bulan keuangan tanggal 1: nama bulan ("Oktober").
- Awal selain 1: rentang ("25 Sep – 24 Okt"), en "25 Sep – 24 Oct".
- Periode peralihan: rentang, lalu penanda `tk-period__tag` "Periode peralihan · 37 hari" dengan ikon `calendar_today` 16px. Di en label lebih panjang ("Transition period · 37 days"), jadi penanda turun ke baris sendiri bila tidak muat.

**Aturan**
- Tombol `tk-period__btn`: gaya `title`, ikon `expand_more` `ink-2` di kanan sebagai tanda bisa diketuk, target 48px, sudut piksel kecil. Mengetuk membuka lembar Awal bulan keuangan (DayPicker).
- Penanda peralihan **netral**: `ink-2`, tanpa latar, tanpa ikon atau warna peringatan. Ia keterangan, bukan status. Bukan Badge (lebih dari tiga kata).
- Kalimat penjelas di bawahnya (`tk-period__note`, `body-sm` `ink-2`) hanya bila dokumen fitur memintanya. Contoh: "Rentang ini tidak memuat gajian." di kartu uang nganggur. Juga tanpa warna peringatan.
- Penanda yang sama dipakai di Rencana › Bulan ini, kepala kartu Arus di Beranda, dan kepala Analisis (di bawah PeriodStepper, sebagai `tk-stepper__sub`).
- Judul kartu Arus di Beranda selalu "Arus {periode}": "Arus Oktober" bila mulai tanggal 1, "Arus 25 Sep – 24 Okt" bila tidak (diputuskan pemilik 10 Okt 2026, seragam untuk semua awal bulan).
- Di Beranda dan Analisis, nama periode bukan tombol: pintu pengaturan hanya di Bulan ini dan Akun.

**Disediakan pemakai:** label periode, panjang hari bila peralihan, handler ketuk.
