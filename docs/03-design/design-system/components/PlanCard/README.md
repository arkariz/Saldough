# PlanCard

Kartu pilihan paket di paywall Tanukonomy Plus. Dipakai dua kartu bersusun di lembar paywall (Tahunan dan Bulanan).

**Bentuk**
- Seperti radio: lingkaran di kiri, nama paket (`body-strong`), keterangan satu baris (`body-sm` `ink-2`), harga di kanan dengan satuan kecil di bawahnya ("/tahun", "/bulan").
- Tidak terpilih: latar `surface-2`. Terpilih: `brand-soft` dengan bingkai `brand` 2px dan lingkaran terisi. Sudut piksel.
- Kelompok `role="radiogroup"`, tiap kartu `role="radio"` dengan `aria-checked`. Tahunan terpilih bawaan.

**Aturan**
- Harga selalu string dari toko (Play Billing lewat RevenueCat); angka di prototipe hanya contoh. Aplikasi tidak mengetik "Rp".
- Keterangan Tahunan: "setara Rp14.900/bulan" (kata "hemat" terlarang). Keterangan Bulanan: "Bisa dibatalkan kapan saja".

**Paywall (lembar)**: ikon dan judul "Tanukonomy Plus" + "Tanuki bekerja untukmu.", tiga manfaat (`tk-row` dengan tile), dua PlanCard, tombol beli `primary` ("Berlangganan Tahunan"), **"Nanti saja" `secondary` sama besar dengan tombol beli**, dan satu kalimat wajib: harga per periode, perpanjangan otomatis, cara membatalkan di Play Store. Di atas layar pemicu yang diredupkan. Tidak pernah muncul di dalam CATAT.

**Disediakan pemakai:** string harga dan satuan, paket terpilih, handler beli.
