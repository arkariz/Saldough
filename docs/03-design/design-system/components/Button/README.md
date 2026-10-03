# Button

Tombol untuk satu tindakan yang jelas; tombol utama `brand` paling banyak satu per layar.

**Varian**
- `primary`: tindakan yang menjadi tujuan layar ("Simpan pengeluaran", "Catat diterima").
- `secondary`: tindakan pendamping ("Tambah dompet" di keadaan berisi, "Abaikan").
- `text`: tindakan ringan atau navigasi ("Lihat semua", "Batal").
- `danger`: tindakan permanen di dialog konfirmasi ("Hapus dompet").
- `sm` (36px, area sentuh tetap 48px) untuk tombol di dalam kartu; `block` untuk tombol yang menempel di bawah layar.
- `iconbtn` (48px) untuk ikon saja; wajib `aria-label`.

**Aturan**
- Teks: kata kerja + benda, huruf kapital hanya di awal. Tanpa ikon kecuali ikonnya menambah makna (+ untuk tambah).
- Tombol nonaktif disertai alasan di dekatnya ("Isi nominal dulu").
- Saat menyimpan, ganti teks dengan ikon `progress_activity` berputar dan kunci tombol; jangan menutup layar sebelum berhasil.

**Disediakan pemakai:** teks, varian, ukuran, handler, status nonaktif/memuat.
