# PlusLocked

Lencana Plus (D-2) dan kartu fitur terkunci (D-4): cara layar gratis menunjukkan batas tanpa menutup jalan.

**Lencana Plus** (`tk-badge--plus`, ikon `workspace_premium`)
- **Gratis:** lencana terisi `brand-soft` di baris atau tombol fitur milik Plus; diketuk membuka paywall atau kartu terkunci.
- **Uji coba:** lencana berbingkai (`tk-badge--plus-trial`): fitur ikut selama uji coba.
- **Plus:** tanpa lencana; fitur Plus tampil seperti fitur lain.
- Lencana tidak dipakai di dalam CATAT dan tidak pernah di fitur gratis.

**Kartu terkunci** (`tk-lock`)
- Lencana Plus, judul yang menyebut fiturnya ("Template kedua ada di Plus"), satu kalimat yang menyebut **yang tetap berjalan** ("Template yang sudah ada tetap tersimpan dan bisa dipakai."), tombol `primary` "Lihat Plus" dan, bila ada jalan gratis, satu tombol `secondary` ("Kembali ke periode terbaru", "Arsipkan salah satu proyek", "Lihat 2 bulan ke depan", "Tetap pakai satu aplikasi").
- Letak: di bawah baris atau daftar yang dibatasi; bukan lembar, tidak menutupi tombol Kembali.
- **Data diburamkan** (`tk-blurwrap` + `tk-blur`): hanya Analisis di luar 6 periode dan perkiraan lewat +2 bulan. Isi buram adalah data asli yang tidak terbaca (blur 5px, `aria-hidden`), kartu terkunci menempel di atasnya. Riwayat tidak pernah diburamkan.

**Enam titik** (rincian di FREEMIUM_PAYWALL §5): Analisis periode ke-7, aplikasi notifikasi kedua (P2), sakelar Catat otomatis (R3), template kedua, proyek aktif ketiga, perkiraan lewat +2 bulan (P5).

**Aturan**
- Tidak ada yang dihapus atau disembunyikan: yang sudah ada tetap tampil dan bisa dipakai; hanya pembuatan baru dan otomasi yang berhenti.
- Jalan gratis selalu ada bila ada (arsip, kembali ke periode terbaru, satu aplikasi).
- Aksesibilitas: kartu `role="region"` berlabel judulnya; isi buram tidak dapat difokus.

**Disediakan pemakai:** fitur yang dibatasi, kalimat jalan gratis, tindakan gratis, tujuan paywall.
