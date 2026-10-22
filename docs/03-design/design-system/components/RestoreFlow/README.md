# RestoreFlow

Halaman pulihkan dari cadangan dan kembalikan data sebelum pemulihan (Fase 22, EXPORT_BACKUP §7). Bukan sheet: halaman turunan penuh, karena menggantikan seluruh data dan perlu dibaca tenang.

**Urutan**
1. **Pratinjau** (halaman turunan: kembali, judul, isi, kaki menempel). Pemilih berkas sistem dibuka sebelum halaman ini.
2. **Peringatan penggantian** (Dialog).
3. **Proses** (ProgressSteps, tanpa tombol kembali).
4. **Selesai** atau **Galat**.

**Pratinjau**
- Kartu dua kolom (`tk-vs`): kiri **Cadangan** + tanggal besar, kanan **Di ponsel ini** + "Sekarang"; di bawahnya empat baris `body-sm`: jumlah transaksi, jumlah dompet, "Sejak …", mata uang. Kembalikan data: kiri **Cadangan pengaman** + tanggalnya.
- Satu banner bila cadangan lebih lama dari data sekarang (teks sama dengan peringatan, supaya terbaca sebelum langkah merusak).
- Bagian **Yang akan berubah**: baris ikon hanya bila ada: mata uang berbeda ("Mata uang akan menjadi USD"), draf dari notifikasi yang tidak ikut ("3 draf …").
- Satu kalimat `ink-2`: bahasa dan tampilan tidak berubah.
- Kaki: "Lanjut" (`primary`) dan "Batal" (teks). Tidak ada tombol berbahaya di halaman ini; yang berbahaya ada di dialog.
- Onboarding: tanpa kolom kanan, tanpa banner, tanpa dialog; tombol "Pulihkan data".

**Dialog**: judul pertanyaan "Ganti semua data di ponsel ini?", isi menyebut cadangan pengaman, bila cadangan lebih lama satu kalimat tambahan (`ink`), tombol "Batal" dan **Ganti data** (`danger`).

**ProgressSteps** (`tk-steps`, di `tk-list`): empat langkah (cadangan pengaman, ganti data, hitung ulang saldo, jadwalkan ulang pengingat), tiga di onboarding. Selesai: centang `positive`; berjalan: pemutar `brand`, teks tebal; menunggu: lingkaran kosong `ink-3`. Di bawahnya: "Proses ini tidak bisa dibatalkan. Kalau aplikasi tertutup di tengah jalan, datamu tetap utuh." Tidak ada tombol keluar dan tidak ada bar persentase.

**Selesai**: maskot, judul "Data dipulihkan dari cadangan 12 Okt 2026.", satu kalimat izin bila cadangan memuat Catat dari notifikasi atau pengingat menyala ("Izin notifikasi perlu diberikan lagi di ponsel ini. Kamu bisa menyalakannya dari Beranda."), kaki "Ke Beranda" (onboarding: "Lanjut").

**Galat** (EmptyState): tile `brand-soft` dengan ikon, judul pendek, kalimat dari §9, kaki satu tindakan + "Tutup". **Setiap galat menyebut "Datamu tidak berubah."** Tiga jenis: berkas tidak bisa dipakai (rusak atau bukan cadangan), cadangan dari versi lebih baru (tindakan "Perbarui aplikasi" ke Versi aplikasi), ruang penyimpanan tidak cukup. Tanpa kode galat. Warna `danger` tidak dipakai: tidak ada yang rusak.

**Aturan**
- Pemulihan mengganti seluruh data tanpa penggabungan; tidak ada pilihan sebagian.
- Nada tenang: tanpa kata "bahaya", "hapus", atau tanda seru. Satu-satunya warna peringatan adalah tombol Ganti data.
- Aksesibilitas: daftar langkah `aria-live="polite"`; fokus dialog masuk ke "Batal".

**Disediakan pemakai:** ringkasan cadangan, ringkasan data sekarang, daftar perubahan, langkah dan tahap berjalan, jenis galat.
