# PeriodStepper

Melihat ke belakang satu periode keuangan sekali langkah: ‹ periode ›. Dipakai di Riwayat (Daftar dan Analisis).

**Aturan**
- Dua tombol ikon 48px (`chevron_left`, `chevron_right`) mengapit label di tengah. Label `body-strong`: nama bulan dan tahun bila awal bulan keuangan tanggal 1 ("September 2026"), selain itu rentangnya ("25 Agt – 24 Sep").
- Baris kedua opsional (`tk-stepper__sub`): penanda periode peralihan (PeriodHeader `tk-period__tag`) atau rentang tanggal.
- Panah maju nonaktif (`opacity-disabled`) di periode berjalan. Analisis tidak membuat perkiraan, jadi tidak ada periode masa depan.
- Sengaja **berbeda** dari chip bulan di Rencana › Bulan ini. Chip Rencana memilih bulan berjalan dan dua bulan ke depan, dengan bulan perkiraan berbingkai putus. Panah di sini hanya ke belakang. Bentuk yang berbeda menjaga arah waktu tetap jelas: Riwayat melihat ke belakang, Rencana ke depan.
- Label aksesibilitas tombol: "Periode sebelumnya", "Periode berikutnya".

**Disediakan pemakai:** label periode, baris kedua opsional, apakah bisa maju, handler mundur dan maju.
