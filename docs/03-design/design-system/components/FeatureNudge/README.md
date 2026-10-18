# FeatureNudge

Baris tombol permanen (Fase 21, P-1–P-6): mengajak menyalakan Catat dari notifikasi (Android) dan pengingat rutin selama fiturnya belum efektif. Satu kartu `tk-list` dengan satu baris per fitur.

**Anatomi baris** (`tk-row tk-row--compact tk-row--wrap`)
- Tile `brandsoft` 40px berisi ikon `notifications` (Catat dari notifikasi) atau `alarm` (Pengingat rutin).
- Judul = nama fitur seperti di Akun ("Catat dari notifikasi", "Pengingat rutin"), boleh membungkus. Keadaan Izinkan menambah baris kedua "Izin belum diberikan" `body-sm` `ink-2`.
- Satu tombol `tk-btn--secondary tk-btn--sm` di kanan: "Nyalakan", atau "Izinkan" bila izin sistem hilang (P-2). Nama aksesibel memuat nama fitur ("Nyalakan: Catat dari notifikasi").

**Aturan**
- Tanpa tombol tutup, tunda, atau "Nanti"; baris hilang begitu fitur efektif dan muncul lagi bila tidak efektif (P-1).
- Hanya satu kartu, tidak pernah kartu besar, tidak menggeser yang di atasnya (P-4, P-6). Urutan Beranda: kartu pembaruan › kartu Menunggu dicatat dan kotak masuk › baris tombol.
- Pengingat: ketukan meminta izin sistem lalu menyalakan. Catat dari notifikasi: membuka alur setelannya.
- iOS: baris Catat dari notifikasi tidak ada; baris pengingat tetap.
- Warna netral: tidak memakai warna peringatan, juga untuk Izinkan.
- Di segmen Rutin: satu baris pengingat di bawah kartu sisa tagihan. Di rincian rutin: lihat bagian di bawah.

**Catatan di sakelar per rutin** (`tk-rownote`): di bawah baris sakelar "Ingatkan", satu kalimat "Pengingat belum menyala untuk semua rutin." (`body-sm` `ink-2`) + tombol `secondary` `sm` Nyalakan atau Izinkan. Sakelar per rutin tetap tampil menyala; catatan menjelaskan mengapa pengingat belum datang. Sakelar Ingatkan hanya ada pada rutin yang dibayar sendiri.

**Disediakan pemakai:** keadaan tiap fitur (efektif, mati, izin), handler.
