# PlusLocked

Kartu terkunci di atas data yang diburamkan: untuk dua batas Gratis yang berupa data, bukan baris: **Analisis lebih dari 6 periode** dan **perkiraan lewat 2 bulan**. Untuk fitur berupa baris atau tombol, pakai PlusBadge.

**Bentuk**
- Isi yang dikunci tetap data asli, diburamkan (`tk-blur`, blur 5px, `aria-hidden`, tidak dapat difokus), supaya pengguna melihat apa yang ada di baliknya.
- Kartu terkunci (`tk-lock`) menempel di tengah area buram (`tk-blurwrap`): lencana Plus, judul yang menyebut batasnya, satu kalimat yang menyebut **yang tetap gratis**, tombol `primary` "Lihat Plus" (paywall dengan `pemicu` yang sesuai) dan tombol `secondary` jalan gratis.
- Analisis: pengatur periode tetap di atas dan bisa dipakai; periode ke-7 dan lebih lama menampilkan donat buram dan kartu. Jalan gratis: "Kembali ke periode terbaru". Riwayat tidak pernah diburamkan.
- Perkiraan: dua bulan pertama tampil jelas dalam kartu biasa; bulan ke-3 dan seterusnya buram dengan kartu. Jalan gratis: "Lihat 2 bulan ke depan".

**Aturan**
- Pesan di kartu sama dengan pesan paywall untuk pemicu itu (`analisis`, `perkiraan`), supaya tidak ada dua versi teks.
- Hanya data yang membaca angka pengguna yang diburamkan; tidak ada data yang dihapus atau disembunyikan permanen.
- Aksesibilitas: kartu `role="region"` berlabel judulnya; isi buram dilewati pembaca layar.

**Disediakan pemakai:** data yang diburamkan, judul, kalimat jalan gratis, tindakan gratis, pemicu paywall.
