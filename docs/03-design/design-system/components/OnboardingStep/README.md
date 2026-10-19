# OnboardingStep

Langkah wajib di onboarding (Fase 21, revisi 19 Okt 2026): awal periode keuangan dan pengingat rutin. Catat dari notifikasi bukan langkah (hanya satu baris informasi di penutup). Kerangkanya sama dengan langkah bahasa dan mata uang yang ada: latar titik, judul di kartu, pilihan di bawahnya, tombol di dasar layar.

**Anatomi** (`tk-onb`)
- Bar atas (`tk-onb__top`): "Tanukonomy" `label-sm` `ink-2` di kiri, tombol teks "Kembali" di kanan (kembali ke langkah sebelumnya boleh; tidak ada Lewati).
- Isi (`tk-onb__body`) menggulir: satu kartu berisi (opsional) ilustrasi 120–150px (`tk-onb__art`, `FilterQuality.none`), judul `tk-onb__title` 24/32, kalimat `tk-onb__text`. Langkah tanggal memakai dua kartu: judul, lalu kisi tanggal DayPicker (7 kolom, bawaan tanggal 1 terpilih) dengan "Hari terakhir bulan" selebar penuh.
- Kaki (`tk-onb__foot`): tombol di dasar layar.

**Langkah tanggal**: satu tombol `primary` "Pakai tanggal {d}" (mengikuti pilihan; "Pakai hari terakhir bulan" untuk hari terakhir). Tanggal 1 sudah terpilih tetapi tetap harus dikonfirmasi.

**Langkah pengingat** (dua pilihan, keduanya jawaban):
- Awal: "Nyalakan" `primary` + "Tidak sekarang" `secondary`, sama lebar dan sama tinggi. "Tidak sekarang" sengaja bukan tombol teks supaya tidak terbaca sebagai Lewati. Tanpa tombol Lanjut.
- Sesudah menjawab atau kembali dari izin sistem: baris status di dasar kartu (`tk-onb__status`: "Pengingat rutin" + Badge Nyala / Mati / Izin belum diberikan) dan satu tombol `primary` "Lanjut". Nyala = badge `positive`; izin ditolak = `warning` dengan teks.
- Memakai ilustrasi yang sudah ada (`onboarding_4`).

**Penutup**: layar akhir yang ada (ilustrasi, judul, kalimat, tombol) ditambah daftar ringkasan dua baris (tanggal gajian, pengingat; ikon + nama + nilai/Badge) dan, hanya di Android, satu baris informasi "Bisa catat otomatis dari notifikasi bank. Nyalakan dari Beranda." (`tk-onb__info`: ikon `notifications` + `body-sm` `ink-2`, tanpa chevron, tidak dapat diketuk, tidak meminta apa pun).

**Aturan**: tanpa Lewati dan tanpa tutup; tanpa streak, tanpa hitungan, tanpa "ketinggalan"; di iOS baris informasi notifikasi tidak ada; mode tinjau dari Akun menampilkan pilihan saat ini dan boleh ditutup (belum dirancang terpisah, memakai kerangka yang sama dengan tombol "Tutup").

**Disediakan pemakai:** langkah, judul, isi, ilustrasi opsional, keadaan jawaban, handler.
