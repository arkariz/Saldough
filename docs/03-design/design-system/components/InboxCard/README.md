# InboxCard

Satu widget "Kotak masuk notifikasi" di Beranda untuk Android (Fase 21; v3, 20 Okt 2026: menggabungkan kartu Catat dari notifikasi ke dalamnya). Tidak pernah hilang; isinya berubah menurut keadaan (P-7, P-8). Di iOS banner lama tetap.

**Anatomi** (`tk-card tk-inbox`)
- Kepala (`tk-inbox__head`): tile ikon `inbox`, judul "Kotak masuk notifikasi", baris kedua (keadaan), dan di kanan paling banyak satu tombol `sm`.
- Pratinjau (hanya keadaan Aktif dengan tangkapan): `tk-inbox__item`, paling banyak dua tangkapan (tile aplikasi, judul satu baris dipotong, baris kedua, nominal). Tangkapan tak dikenali/tak terbaca berbingkai putus-putus tipis dengan tombol `secondary` `sm` **Ajari pola**.
- Kaki (`tk-inbox__foot`, hanya keadaan Aktif): "{n} aplikasi aktif" (`body-sm` `ink-2`) di kiri dan tautan **Kelola aplikasi & pola** di kanan.

**Keadaan**
| Keadaan | Latar | Baris kedua | Kanan | Ketukan membuka |
|---|---|---|---|---|
| Belum disetel | `surface` (tenang) | Catat otomatis dari notifikasi bank dan e-wallet. | `primary` "Nyalakan" | Mulai cepat |
| Izin hilang | `surface` | Izin belum diberikan | `primary` "Izinkan" | Setelan sistem |
| Sakelar mati | `surface` | Mati | `primary` "Nyalakan" | Setelan |
| Aktif, tidak ada yang menunggu | `surface` | {n} aplikasi aktif | (tautan Kelola di kaki) | Layar setelan penuh |
| Aktif, ada yang menunggu | `warning-soft` | {n} transaksi dari notifikasi menunggu dicek. | `on-soft` "Cek" + pratinjau + kaki | Kotak masuk |

**Aturan**
- Latar `warning-soft` hanya bila ada tangkapan yang perlu dicek; keadaan setelan memakai `surface` supaya tidak terbaca sebagai peringatan. Tombol `primary` hanya pada keadaan Nyalakan/Izinkan.
- Tanpa tutup atau tunda. Hanya Android (P-3).
- Pratinjau hanya membaca: tidak ada tombol Simpan di Beranda (pencatatan lewat Cek / CATAT, aturan 8). Tanpa "Disinkronkan otomatis" (tidak ada sinkronisasi ke server).
- Di layar Kotak masuk notifikasi, tautan "Kelola aplikasi & pola" ada di bawah segmen, juga saat kosong; Ajari pola ada di baris tangkapan tak terbaca di sebelah Isi nominal.

**Disediakan pemakai:** keadaan, jumlah aplikasi dan tangkapan, handler.
