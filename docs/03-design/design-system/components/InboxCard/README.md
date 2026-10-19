# InboxCard

Kartu kotak masuk notifikasi di Beranda (Fase 21, P-8; gambar pilihan pemilik 19 Okt 2026). Menggantikan banner "3 transaksi dari notifikasi menunggu dicek" pada pengguna Android; di iOS banner lama tetap.

**Anatomi** (`tk-card tk-inbox`, latar `warning-soft`)
- Kepala (`tk-inbox__head`): tile `amber` ikon `inbox`, judul "Kotak masuk notifikasi" + "{n} transaksi dari notifikasi menunggu dicek.", tombol `on-soft` `sm` "Cek".
- Pratinjau (`tk-inbox__item`, `surface`): paling banyak dua tangkapan: tile aplikasi, judul (satu baris, dipotong), baris kedua (aplikasi · jam, atau "Nominal belum terbaca"), nominal di kanan. Tangkapan yang tak dikenali/tak terbaca berbingkai putus-putus tipis dan menawarkan tombol `secondary` `sm` **Ajari pola** (P-8b).
- Kaki: tautan "Kelola aplikasi & pola" rata kanan (P-8a).

**Aturan**
- Pratinjau hanya membaca: ketuk membuka kotak masuk; tidak ada tombol Simpan di Beranda (pencatatan lewat Cek / CATAT, aturan 8).
- Tanpa tulisan "Disinkronkan otomatis": aplikasi tidak menyinkronkan ke server.
- Di layar Kotak masuk notifikasi, tautan "Kelola aplikasi & pola" ada di bawah segmen, juga saat kosong; Ajari pola ada di baris tangkapan tak terbaca di sebelah Isi nominal.

**Disediakan pemakai:** daftar tangkapan, jumlah, handler cek, kelola, ajari pola.
