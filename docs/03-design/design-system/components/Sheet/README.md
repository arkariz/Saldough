# Sheet

Panel yang naik dari bawah untuk form, pemilih, dan tindakan lanjutan.

**Varian**
- Pemilih (dompet, kategori, tanggal): judul di tengah, tombol tutup di kiri, daftar baris dengan centang pada yang terpilih.
- Form (Catat, tambah dompet, tambah pos): tinggi penuh, tombol simpan menempel di bawah.
- Tindakan (ketuk pos anggaran): daftar tindakan pendek.

**Aturan**
- Pegangan 36×4px di atas; geser ke bawah atau ketuk `scrim` untuk menutup, kecuali form yang sudah diisi (tanya dulu dengan dialog).
- `radius-xl` di sudut atas, `shadow-float`.
- Jangan menumpuk sheet di atas sheet lebih dari satu tingkat.

**Disediakan pemakai:** judul, isi, handler tutup.
