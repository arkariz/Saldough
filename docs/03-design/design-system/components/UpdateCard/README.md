# UpdateCard

Kartu pembaruan aplikasi di Beranda (`tk-upd`), pilihan pemilik 15 Okt 2026 dari rujukan gambar. Latar `brand` seperti kartu saldo, teks `on-brand`, sudut piksel `pixel-step`.

**Anatomi**
- Baris atas: tile 40px berlatar `on-brand` 20% berisi 🚀 (versi baru tersedia) atau ikon Material (`progress_activity` berputar, `system_update`, `restart_alt`) → judul `body-strong` 700 + pil versi `tk-upd__pill` (`brand-soft` / `brand-ink`, nomor versi tanpa build, mis. "0.6.0") → baris keterangan `body-sm` bila ada → tombol tutup 32px (hanya Versi baru tersedia; artinya "Nanti", tunda 7 hari).
- Kaki (`tk-upd__foot`, garis `on-brand` 30% di atasnya): tautan "Lihat apa yang baru" (`tk-upd__link`, garis bawah hanya pada teksnya) membuka lembar catatan rilis sebelum dipasang; di kanan satu tombol `tk-btn--sm` `--on-soft`. Pembaruan kecil: kaki hanya tombol "Oke" rata kanan (isi catatan belum diketahui sebelum terpasang).

**Keadaan**: Versi baru tersedia (tautan + "Perbarui", tutup), Mengunduh (tanpa kaki, keterangan "Kamu tetap bisa mencatat."), Sudah diunduh (tautan + "Pasang sekarang", tanpa tutup), Pembaruan kecil siap ("Oke").

**Aturan**
- Letak di gambar pilihan pemilik: paling atas Beranda, di atas kartu saldo, dan boleh bersama banner kotak masuk di bawahnya. Ini menyimpang dari "satu banner per layar, di bawah angka utama" dan dari B-2/B-3 dokumen fitur; menunggu keputusan product owner.
- Judul tanpa tanda baca akhir, tanpa tanda seru. Spinner diam saat kurangi gerakan.
- Di lebar 360 dan teks 200% judul dan pil boleh membungkus; kaki tetap satu baris atau menumpuk.

**Disediakan pemakai:** keadaan, nomor versi, handler tutup, perbarui, pasang.
