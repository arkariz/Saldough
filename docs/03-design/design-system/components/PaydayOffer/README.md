# PaydayOffer

Kartu tawaran gajian di kepala Rencana › Bulan ini untuk pengguna lama (Fase 21, §6.2): "Gajian tanggal {d}? Mulai bulan keuangan dari tanggal {d}, supaya Rencana dan Analisis mengikuti gajianmu." Satu-satunya tawaran penemuan fitur yang boleh ditutup.

**Anatomi** (`tk-card tk-offer`)
- Baris atas: tile `brandsoft` `calendar_today` → judul `body-strong` + isi `body-sm` `ink-2` → tombol tutup ikon `close` 48px (`tk-offer__close`, nama "Tutup").
- Kaki: tombol `secondary` `sm` "Atur" rata kanan; membuka lembar Awal bulan keuangan dengan {d} terisi sebagai saran.

**Aturan**
- Tampil di bawah kepala periode, di atas banner saldo. Kartu `surface` biasa, bukan kartu `brand`, supaya tidak terbaca seperti pembaruan.
- Ditutup = tidak muncul lagi. Tidak memaksa dan tidak mengubah apa pun sebelum "Atur" disimpan.
- Pengguna baru sudah memilih tanggal di onboarding sehingga tidak melihatnya.

**Disediakan pemakai:** tanggal saran, handler atur dan tutup.
