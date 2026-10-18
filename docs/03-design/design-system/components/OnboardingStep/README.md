# OnboardingStep

Langkah wajib di onboarding (Fase 21): awal periode keuangan, Catat dari notifikasi (Android), pengingat rutin. Kerangkanya sama dengan langkah bahasa dan mata uang yang ada: latar titik, judul di kartu, pilihan di bawahnya, tombol di dasar layar.

**Anatomi** (`tk-onb`)
- Bar atas (`tk-onb__top`): "Tanukonomy" `label-sm` `ink-2` di kiri, tombol teks "Kembali" di kanan (kembali ke langkah sebelumnya boleh; tidak ada Lewati).
- Isi (`tk-onb__body`) menggulir: satu kartu berisi (opsional) ilustrasi 120–150px (`tk-onb__art`, `FilterQuality.none`), judul `tk-onb__title` 24/32, kalimat `tk-onb__text`. Langkah tanggal memakai dua kartu: judul, lalu kisi tanggal DayPicker (7 kolom, bawaan tanggal 1 terpilih) dengan "Hari terakhir bulan" selebar penuh.
- Kaki (`tk-onb__foot`): tombol di dasar layar.

**Langkah tanggal**: satu tombol `primary` "Pakai tanggal {d}" (mengikuti pilihan; "Pakai hari terakhir bulan" untuk hari terakhir). Tanggal 1 sudah terpilih tetapi tetap harus dikonfirmasi.

**Langkah Catat dari notifikasi dan pengingat** (dua pilihan, keduanya jawaban):
- Awal: "Nyalakan" `primary` + "Tidak sekarang" `secondary`, sama lebar dan sama tinggi. "Tidak sekarang" sengaja bukan tombol teks supaya tidak terbaca sebagai Lewati. Tanpa tombol Lanjut.
- Kembali dari setelan atau sesudah menjawab: baris status di dasar kartu (`tk-onb__status`: nama fitur + Badge Nyala / Mati / Izin belum diberikan) dan satu tombol `primary` "Lanjut". Nyala = badge `positive`; kembali tanpa menyelesaikan = Mati (netral); izin ditolak = `warning` dengan teks.
- Pengingat dan Catat dari notifikasi memakai ilustrasi yang sudah ada (`onboarding_4`, `onboarding_3`); tidak ada ilustrasi baru.

**Penutup**: layar akhir yang ada (ilustrasi, judul, kalimat, tombol) ditambah satu daftar ringkasan tiga baris (ikon + nama + nilai/Badge) di atas tombol "Tambah dompet". Ringkasan satu baris tidak muat di 360dp dan en, jadi tiga baris pendek.

**Aturan**: tanpa Lewati dan tanpa tutup; tanpa streak, tanpa hitungan, tanpa "ketinggalan"; di iOS langkah notifikasi tidak ada; mode tinjau dari Akun menampilkan pilihan saat ini dan boleh ditutup (belum dirancang terpisah, memakai kerangka yang sama dengan tombol "Tutup").

**Disediakan pemakai:** langkah, judul, isi, ilustrasi opsional, keadaan jawaban, handler.
