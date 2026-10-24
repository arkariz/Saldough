# PlusPaywall

Lembar paywall Tanukonomy Plus (D-3), dengan PlanCard dan PillarGrid. Rupa dari dokumen rencana paywall (23 Okt 2026), diselaraskan dengan FREEMIUM_PAYWALL §9.

**Bentuk**
- Lembar hampir penuh (`tk-pw`, 32px dari atas, sudut atas `radius-xl`) di atas layar pemicu yang diredupkan; bukan layar penuh, supaya terasa sementara. Tombol tutup di kiri atas.
- Badan menggulir: tile tema, judul sesuai pemicu (`title` 20px, rata tengah), satu kalimat, PillarGrid, PlanCards, satu baris jaminan ("Semua catatanmu tetap milikmu, berlangganan atau tidak."), tautan "Pulihkan pembelian".
- **PillarGrid** (`tk-pillars`): enam pilar sebagai kisi 2 kolom (ikon + kata kerja: Mencatat, Berjaga, Menjawab, Merencanakan, Melapor, Menyimpan) di bawah label "Tanuki bekerja untukmu". Pilar pemicu diberi `is-lead` (`brand-soft`, bingkai `brand` 2px) dan satu kalimat penjelasnya muncul di bawah kisi. Pilar lain tanpa penjelasan: kisi tetap pendek supaya harga terlihat tanpa menggulir jauh.
- **PlanCard** (`tk-plan`): kartu pilihan seperti radio (`role="radiogroup"`): lingkaran, nama paket, keterangan, harga di kanan dengan satuan di bawahnya. Terpilih: `brand-soft` + bingkai `brand`. Tahunan terpilih bawaan, keterangannya "setara Rp14.900/bulan" (tulis "setara", bukan "hemat"). Bulanan: "Bisa dibatalkan kapan saja".
- Kaki menempel (`tk-pw__foot`, `shadow-bar`): tombol beli `primary` ("Berlangganan Tahunan"/"Berlangganan Bulanan"), **"Nanti saja" `secondary` selebar dan setinggi tombol beli** (sama mudah dijangkau), dan satu kalimat kecil wajib: harga per periode, perpanjangan otomatis, cara membatalkan di Play Store.

**Penawaran** (offering RevenueCat): `biasa` (di atas), `pendiri` (90 hari pertama: lencana "Harga Pendiri" di Tahunan, harga coret Rp179.000, "Terkunci selagi berlangganan · sampai 21 Jan 2027"), `pasca` (48 jam sesudah uji coba: lencana "Harga perkenalan", "Tahun pertama, lalu Rp179.000/tahun · sampai 26 Nov, 21.00"). Penawaran selalu menyebut tanggal dan jam berakhirnya; tanpa hitung mundur detik.

**Keadaan**
- Memuat harga: kotak harga diganti skeleton, tombol beli "Berlangganan" nonaktif.
- Harga gagal dimuat (luring): kartu "Harga belum bisa dimuat" + "Coba lagi"; tombol beli nonaktif; "Nanti saja" tetap.
- Memproses: tombol beli berisi pemutar "Memproses…", paket nonaktif.
- Pembayaran tertunda: banner info di bawah hero "Pembayaran tertunda. Plus aktif begitu disetujui."; tombol "Menunggu persetujuan" nonaktif.
- Galat: banner `danger` "Pembayaran belum berhasil. Cek metode bayarmu di Play Store, lalu coba lagi."; tombol "Coba lagi". Tetap Gratis.
- Dibatalkan di lembar Play: kembali ke keadaan awal tanpa pesan.
- Berhasil: lembar singkat PlusAccount › Berhasil.

**Pemicu P1–P10** (judul dan satu kalimat dari §9; pilar pemicu di-`is-lead`): P1 tafsir habis (①), P2 aplikasi notifikasi kedua (①), P3 sesudah Contoh Penjaga (②), P4 jatah tanya habis (③), P5 perkiraan lewat +2 bulan (④), P6 rapor (⑤), P7 pembayaran freelance 14 hari (⑤), P8 tanpa cadangan (⑥), P9 Desember/Januari (⑤), P10 Akun (tanpa pilar utama, judul "Tanukonomy Plus").

**Aturan**
- Harga selalu string dari toko (`pricePerMonthString` untuk "setara"); angka di prototipe adalah contoh. Aplikasi tidak mengetik "Rp".
- Tanpa tanda seru, tanpa urgensi palsu, tanpa kata "hemat", "premium", atau "upgrade".
- Paywall tidak pernah muncul di dalam CATAT; paling banyak sekali sehari dan tiga kali per periode; sesudah tiga "Nanti saja" pada pemicu yang sama, diam 30 hari.
- Aksesibilitas: `role="dialog"` `aria-modal`, paket `radiogroup`, blok pembayaran `role="status"`.

**Disediakan pemakai:** pemicu, penawaran, string harga dari toko, tanggal berakhir penawaran, keadaan pembelian.
