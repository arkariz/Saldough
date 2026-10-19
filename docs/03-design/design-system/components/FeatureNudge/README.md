# FeatureNudge

Kartu tombol permanen untuk **pengingat rutin** (Fase 21, P-1; v3 20 Okt 2026). Catat dari notifikasi tidak lagi punya kartu sendiri: pintunya ada di InboxCard. Kelas `tk-nudge`.

**Anatomi** (`tk-card tk-nudge`): tile `brandsoft` 40px ikon `alarm` → judul `body-strong` + satu baris `body-sm` `ink-2` (boleh membungkus) → tombol `secondary` `sm` di kanan.

**Keadaan**: mati = "Nyalakan pengingat rutin" / "Diingatkan sebelum tagihan jatuh tempo." / "Nyalakan"; izin hilang = "Pengingat rutin" / "Izin belum diberikan" / "Izinkan". Hilang begitu efektif.

**Aturan**
- Tanpa tombol tutup, tunda, atau "Nanti" (P-1). Pengingat meminta izin sistem saat diketuk lalu menyalakan sakelar.
- Urutan Beranda (P-6): kartu pembaruan › Menunggu dicatat dan InboxCard › kartu pengingat. Tanpa warna peringatan, juga untuk Izinkan.
- Segmen Rutin: kartu yang sama di bawah kartu sisa tagihan. Rincian rutin: catatan sakelar di bawah.

**Catatan di sakelar per rutin** (`tk-rownote`): di bawah baris sakelar "Ingatkan", satu kalimat "Pengingat belum menyala untuk semua rutin." + tombol `secondary` `sm` Nyalakan atau Izinkan. Sakelar tampil menyala; catatan menjelaskan mengapa pengingat belum datang. Sakelar hanya ada pada rutin yang dibayar sendiri.

**Disediakan pemakai:** keadaan, handler.
