# PlusBadge

Penanda fitur Tanukonomy Plus: satu pola untuk semua fitur yang dibatasi di Gratis.

**Bentuk**
- `AppBadge` varian `plus` (`tk-badge--plus`): latar `brand-soft`, teks `brand-ink`, ikon `workspace_premium` 14px, kata "Plus".
- Letak: di ujung kanan baris (sebelum panah atau sakelar) atau di sisi kanan label tombol. Tidak dipakai di judul layar atau di dalam CATAT.

**Perilaku**
- **Gratis:** lencana tampil. Baris atau tombol tetap tampil normal (tidak diredupkan, tidak diberi gembok) dan bisa diketuk: membuka paywall dengan pesan sesuai fiturnya (properti `pemicu`: notifikasi, otomatis, template, proyek, perkiraan, analisis).
- **Berlangganan:** lencana hilang; baris bekerja seperti fitur lain.
- Fitur lama yang sudah ada tetap dapat dipakai; hanya pembuatan baru dan otomasi yang berhenti, dan pesan paywall menyebutnya.

**Aturan**
- Hanya untuk fitur yang memang dibatasi; fitur gratis tidak pernah diberi lencana.
- Satu lencana per baris atau tombol.
- Aksesibilitas: lencana bagian dari label baris ("Catat otomatis, Plus").

**Tidak tercakup:** data yang diburamkan (Analisis di luar 6 periode, perkiraan lewat 2 bulan) memakai kartu di atas grafik, belum dirancang.

**Disediakan pemakai:** fitur yang dibatasi, status langganan, pemicu paywall.
