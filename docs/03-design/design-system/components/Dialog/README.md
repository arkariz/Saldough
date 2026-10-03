# Dialog

Konfirmasi untuk tindakan permanen yang tidak bisa diurungkan.

**Aturan**
- Hanya untuk yang permanen: hapus dompet, hapus akun, hapus anggaran beserta pos. Tindakan yang bisa dibalik memakai snackbar "Urungkan".
- Judul berupa pertanyaan yang menyebut bendanya ("Hapus dompet BCA?"). Isi menyebut akibatnya dalam satu atau dua kalimat.
- Tombol `text` "Batal" di kiri, tindakan di kanan dengan kata kerja yang sama dengan judul ("Hapus dompet", nada `danger`).
- Di atas `scrim`, `radius-xl`, lebar 312px.

**Disediakan pemakai:** judul, isi, label tindakan, handler.
