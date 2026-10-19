# FeatureNudge

Kartu pintu di Beranda (Fase 21, P-1–P-8; rupa mengikuti gambar pilihan pemilik 19 Okt 2026). Satu kartu per fitur: Catat dari notifikasi (Android, tidak pernah hilang) dan Pengingat rutin (hilang begitu efektif). Kelas `tk-nudge`.

**Anatomi** (`tk-card tk-nudge`): tile `brandsoft` 40px (ikon `notifications` atau `alarm`) → judul `body-strong` + satu baris `body-sm` `ink-2`, boleh membungkus → di kanan satu tombol `sm` atau tanda `chevron_right` bila kartu itu sendiri pintunya. Kartu bertumpuk jarak 12px.

**Keadaan Catat dari notifikasi** (P-7)
| Keadaan | Judul | Baris kedua | Kanan | Ketukan membuka |
|---|---|---|---|---|
| Belum pernah disetel | Nyalakan catat dari notifikasi | Catat otomatis dari notifikasi bank dan e-wallet. | tombol `primary` "Nyalakan" | Mulai cepat |
| Aktif | Catat dari notifikasi | {n} aplikasi aktif | `chevron_right` | Layar setelan penuh |
| Izin hilang | Catat dari notifikasi | Izin belum diberikan | `primary` "Izinkan" | Setelan sistem |
| Sakelar mati | Catat dari notifikasi | Mati | `primary` "Nyalakan" | Setelan |

**Keadaan Pengingat rutin**: mati = judul "Nyalakan pengingat rutin", baris kedua "Diingatkan sebelum tagihan jatuh tempo.", tombol `secondary` "Nyalakan"; izin hilang = "Pengingat rutin" / "Izin belum diberikan" / "Izinkan". Hilang begitu efektif.

**Aturan**
- Tanpa tombol tutup, tunda, atau "Nanti" pada kedua kartu (P-1). Catat dari notifikasi tidak hilang sama sekali, hanya berubah isi (P-7).
- Tombol `primary` hanya pada Catat dari notifikasi (tindakan yang paling bernilai); pengingat `secondary`. Di Beranda satu-satunya tombol `brand` terisi lain adalah Catat di navigasi.
- Urutan Beranda (P-6): kartu pembaruan › kartu Menunggu dicatat dan kartu kotak masuk (InboxCard) › kartu pintu. Gambar rujukan menaruh kartu pintu lebih dulu; spek P-6 yang dipakai.
- Tanpa warna peringatan, juga untuk Izinkan. iOS: kartu Catat dari notifikasi tidak ada.
- Segmen Rutin: kartu pengingat yang sama di bawah kartu sisa tagihan. Rincian rutin: lihat catatan sakelar di bawah.

**Catatan di sakelar per rutin** (`tk-rownote`): di bawah baris sakelar "Ingatkan", satu kalimat "Pengingat belum menyala untuk semua rutin." + tombol `secondary` `sm` Nyalakan atau Izinkan. Sakelar tampil menyala; catatan menjelaskan mengapa pengingat belum datang. Sakelar hanya ada pada rutin yang dibayar sendiri.

**Disediakan pemakai:** keadaan tiap fitur, jumlah aplikasi, handler.
