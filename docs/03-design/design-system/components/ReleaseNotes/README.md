# ReleaseNotes

Catatan rilis aplikasi ("Apa yang baru"): lembar bergaya kartu fitur (pilihan pemilik 15 Okt 2026 dari rujukan gambar) dan daftar ringkas di halaman Akun › Versi aplikasi.

**Rujukan** (penelusuran 15 Okt 2026; sebagian besar blog vendor, satu dokumen resmi Android): catatan dibuka dengan manfaat, diberi label kategori supaya bisa dipindai, satu atau dua kalimat per butir, disampaikan di dalam aplikasi dengan pintu masuk tetap untuk dibuka lagi. Pembaruan lentur Android memakai pesan yang tidak memblokir; yang paksa hanya untuk perubahan kritis.

**Lembar (Sheet varian Catatan)**
- Tombol tutup bulat 40px `surface-2` di kanan atas, pegangan di tengah.
- Kepala (`tk-rel__hero`, rata tengah): tile 56px `surface` bergaris bayang lembut berisi 🚀 + pil (`tk-rel__pill`, `brand-soft`/`brand-ink`; sebelum dipasang "Versi baru tersedia", sesudahnya nomor versi); judul `tk-rel__title` 24/32 tebal ("Apa yang baru di versi 0.6.0"; pembaruan kecil: "Apa yang baru"); baris `body-sm` `ink-2` "Terima kasih sudah memakai Tanukonomy." (hanya sesudah dipasang).
- Kartu butir (`tk-rel__card`, `surface-2`): tile 40px warna kategori berisi emoji + pil kategori `tk-tag` + satu kalimat manfaat 15/22. Jarak antarkartu 10px. Gulir di `tk-sheet__scroll` (maks 300px).
- Kategori: ✨ Baru (`orange`), ⚡ Lebih cepat (`amber`), 🛠️ Perbaikan (`blue`), 🔒 Keamanan (`green`). Warna dan emoji hiasan; label teks yang menyampaikan arti.
- Kaki: sebelum dipasang tombol `primary` lebar penuh "Perbarui (18,4 MB)" lalu tombol teks "Nanti"; sesudah dipasang satu tombol "Oke".
- Beberapa versi (gabungan): kepala kelompok `tk-notes__head` berisi nomor versi, terbaru di atas, paling banyak 6 butir.

**Daftar ringkas (halaman Versi aplikasi)**: satu kartu per versi berisi kepala nomor versi dan butir `tk-note` (tile berwarna + `tk-tag` + kalimat), tanpa kartu di dalam kartu.

**Aturan isi**: paling banyak 3 butir per versi; satu kalimat manfaat dengan "kamu", tanpa tanda seru dan kata "tambalan", "patch", "bug"; emoji hanya di kepala dan tile kategori. Pengecualian aturan tanpa emoji: keputusan pemilik 15 Okt 2026.

**Aksesibilitas:** `ul`/`li`; kepala kelompok `h3`; pil dan kalimat dibaca, emoji `aria-hidden`.

**Disediakan pemakai:** versi, mode (sebelum atau sesudah dipasang), butir (kategori, kalimat), ukuran unduhan bila tahu.
