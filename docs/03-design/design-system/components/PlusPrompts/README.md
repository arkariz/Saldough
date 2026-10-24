# PlusPrompts

Tiga kartu yang menawarkan Plus pada saat nilainya terasa, tanpa memotong pencatatan: **kartu konteks** (D-5), **Contoh Penjaga** (D-6), dan **rekap nilai** (D-7). Semuanya kartu biasa di layar tempatnya muncul, tidak pernah lembar.

**Kartu konteks** (`tk-ctx`)
- Tile kecil `brand-soft`, label pemicu (`P1 · …`, hanya di dokumentasi; di aplikasi tanpa label kode), **satu kalimat** dengan angka milik pengguna, dua tombol rata kanan: "Nanti saja" (teks) dan satu tombol `primary` kecil ("Lihat Plus", atau tindakan gratis seperti "Cadangkan sekarang").
- Tampil sesudah tindakan berhasil, paling banyak satu per layar, tidak pernah di dalam CATAT. Ditutup dengan "Nanti saja" dan tidak muncul lagi pada pemicu yang sama untuk sementara (aturan frekuensi di PlusPaywall).
- P8 (belum dicadangkan): tombolnya jalan gratis, Plus hanya disebut di kalimat.

**Contoh Penjaga** (kartu Beranda + notifikasi lokal)
- Peringatan sungguhan, satu kali per periode untuk Gratis, berlabel **Contoh Penjaga** (`tk-badge--plus-trial`). Isi: kalimat peringatan tebal + satu baris angka, tombol "Lihat anggaran Makan" (`secondary`) dan "Tutup".
- Notifikasi lokal memakai kata yang sama, dengan label di baris sumber.
- Sesudah dilihat, bisa disusul kartu konteks P3 ("Peringatan ini datang 9 hari sebelum anggaran Makan habis. Plus memberi tahu tiap kali ada yang seperti ini.").

**Rekap nilai** (`tk-recap`, H-3 uji coba)
- Kepala: tile + "Plus berakhir 24 Nov" + "Sejak 1 Nov, Tanuki sudah:". Daftar angka besar (`tabular`) + kalimat. Hanya hal yang benar-benar terjadi: baris tanpa kejadian tidak ditulis; tanpa satu pun kejadian, kartu tidak tampil sama sekali.
- Aksi: "Nanti saja" dan "Lihat Plus".
- Kata kerja tetap "mencatat, bukan melakukan": "tagihan rutin tercatat sendiri", bukan "dibayar".

**Aturan**
- Nada netral, tanpa tanda seru, tanpa hitung mundur detik, tanpa kata "hemat" atau "ketinggalan".
- Angka selalu dari pemakaian lokal; tidak ada angka rekaan.
- Aksesibilitas: setiap kartu `role="region"` dengan label.

**Disediakan pemakai:** kalimat dan angka, tindakan utama, handler tutup.
