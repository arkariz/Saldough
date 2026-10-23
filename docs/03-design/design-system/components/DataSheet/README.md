# DataSheet

Lembar bawah untuk **ekspor ke spreadsheet** dan **cadangkan sekarang** (Fase 22, EXPORT_BACKUP §5–6). Sheet varian Form, isinya tersusun dari komponen yang ada ditambah FileCard dan ringkasan.

**Bentuk**
- Sheet: pegangan, kepala (tombol tutup kiri, judul `title` di tengah, spacer 48px kanan supaya judul benar-benar di tengah), isi, kaki.
- Isi disusun dalam `tk-dsheet` (jarak 16px). Label kelompok `body-sm` tebal ("Format").
- **Format**: SegmentedControl "Excel (.xlsx)" (bawaan) | "CSV", dengan satu baris bantuan di bawahnya yang berganti sesuai pilihan (`tk-field__help`).
- **Tanpa pilihan rentang**: ekspor selalu berisi seluruh data saat ini (keputusan pemilik 22 Okt 2026). Yang butuh sebagian menyaringnya di spreadsheet.
- **Ringkasan** (`tk-dsheet__sum`, latar `surface-2`): ikon + "142 transaksi, 3 Jun – 22 Okt 2026". Tanpa nominal, jadi tidak terpengaruh Sembunyikan nominal. Satu catatan di bawahnya menjelaskan isi ("Berisi seluruh transaksimu dan saldo dompet saat ini. Saring sendiri bagian yang kamu perlukan di spreadsheet."). Belum ada transaksi: ikon `event_busy`, teks biasa "Belum ada transaksi untuk diekspor.", tanpa catatan, tombol Ekspor nonaktif.
- Cadangkan: ringkasan isi ("142 transaksi, 4 dompet, sejak 3 Jun 2026"), dua kolom **Ikut** / **Tidak ikut** (centang `positive`, silang `ink-3`, masing-masing paling banyak empat butir), satu kalimat anjuran menyimpan di luar ponsel, tombol Cadangkan.
- Kaki: satu tombol `primary` lebar penuh.

**Keadaan**
- Awal, Kosong (belum ada transaksi; hanya ekspor), Proses, Siap. Dibatalkan (hanya cadangkan): kembali ke Siap dengan satu kalimat "Belum tersimpan…".
- **Proses**: blok `tk-dsheet__busy` dengan pemutar di dalamnya, satu kalimat catatan (ekspor), dan tombol teks "Batal" sebagai kaki. Tidak ada bar persentase: lama proses tidak terprediksi. Lembar tidak bisa ditutup dengan geser selama proses; tombol tutup sama dengan Batal.
- **Siap**: tile besar `brand-soft` dengan centang, judul "Berkas siap" / "Cadangan siap", FileCard (ikon berkas, nama, "Excel · 142 transaksi"), lalu dua tombol: **Simpan ke…** (`primary`) dan **Bagikan** (`secondary`). Keduanya membuka lembar sistem; membatalkannya mengembalikan ke Siap tanpa mengubah apa pun, dan status "Cadangan terakhir" hanya berubah bila berkas tersimpan.

**FileCard** (`tk-file`): ikon berkas di tile kecil, nama berkas `body-sm` tebal (boleh membungkus di mana saja), keterangan `label` `ink-2`. Nama berkas: `tanukonomy-ekspor-2026-10-22.xlsx` (tanggal = hari ekspor), `tanukonomy-cadangan-2026-10-22.<ekstensi>` (ekstensi diputuskan ADR T-22.1; prototipe memakai `.tkbak` sebagai anggapan).

**Aturan**
- Dibuka hanya dari Akun › Data kamu (ekspor, cadangkan); ekspor tidak punya pintu lain. Jangan menumpuk di atas sheet lain.
- Tanpa ajakan Plus; ekspor dan cadangan tidak pernah di balik paywall.
- Teks mengikuti `writing.md`: berkas berisi salinan catatan, tidak ada yang dikirim ke Tanukonomy.
- Aksesibilitas: `role="dialog"` `aria-modal`, kontrol format `role="radiogroup"` dengan `aria-checked`, ringkasan dan blok proses `role="status"`.

**Disediakan pemakai:** jenis (ekspor atau cadangkan), format, jumlah dan tanggal pertama dan terakhir, nama berkas, handler.
