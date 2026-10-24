# PlusAccount

Status Plus di Akun (D-9), hadiah uji coba (D-1), layar turun ke Gratis (D-8), dan lembar berhasil berlangganan (D-10).

**Status di Akun** (`tk-plusst`)
- Bagian "Plus" tepat di bawah kartu akun: kartu status (tile `brand-soft`, judul "Tanukonomy Plus" + lencana, satu baris keadaan, satu tombol bila ada), lalu daftar: "Kelola di Play Store" (bila berlangganan lewat Play) dan "Pulihkan pembelian".
- Enam keadaan: **Gratis** ("Gratis. Lihat apa yang bisa dikerjakan Tanuki untukmu." + "Lihat Plus"), **Uji coba** (lencana berbingkai, "Plus aktif sampai 24 Nov. Tanpa kartu, tanpa langganan otomatis."), **Aktif diperpanjang** ("Tahunan, diperpanjang 22 Okt 2027"), **Aktif akan berakhir** ("…tidak diperpanjang" + "Lanjutkan Plus"), **Masa tenggang pembayaran** (kartu `warning-soft`, "Pembayaran belum berhasil. Plus tetap aktif sampai 25 Okt." + "Perbarui pembayaran"), **Dari program penguji** ("Plus dari program penguji sampai 22 Okt 2027", tanpa Kelola).
- Warna peringatan hanya untuk masa tenggang, selalu bersama teks.

**Hadiah uji coba** (kerangka onboarding `tk-onb`, akhir onboarding)
- Maskot, "Plus aktif sampai 24 Nov, akhir periode pertamamu." (tanggal, bukan jumlah hari), "Tanpa kartu, tanpa langganan otomatis.", tiga manfaat sesuai pilihan onboarding (`tk-row` dengan tile), satu kalimat "Sesudah itu kamu tetap mencatat gratis.", tombol "Mulai mencatat".
- Awal bulan keuangan belum diatur: lebih dulu "Biasanya gajian tanggal berapa?" dengan kisi tanggal onboarding dan satu baris pratinjau "Plus aktif sampai 24 Nov" yang berubah sesuai tanggal terpilih (aturan KT-P2: sisa ≥ 14 hari memakai periode berjalan, selain itu periode berikutnya). Tombol "Pakai tanggal 25".
- Tanpa "Lewati" (langkah wajib, seperti langkah onboarding Fase 21).

**Turun ke Gratis** (halaman penuh, hari pertama periode berikutnya, sesudah rapor bila ada)
- Judul "Uji coba Plus selesai", satu kalimat yang menenangkan, bagian **Yang tetap** (centang `positive`: semua catatan, rapor yang sudah dibuka, pencatatan inti) dan **Yang berubah** (ikon netral, dengan **angka pemakaian pengguna**: "3 aplikasi menjadi 1", "4 rutin kembali ke konfirmasi satu ketuk"; hanya baris yang berlaku).
- Kartu penawaran `tk-deal` (`brand-soft`): "Penawaran sampai 26 Nov, 21.00", harga perkenalan besar, "untuk tahun pertama, lalu Rp179.000 per tahun.", kalimat perpanjangan otomatis dan cara membatalkan. Tanpa penawaran (sudah lewat atau sudah dipakai): kartu tidak ada dan tombol utama menjadi "Lihat Plus".
- Kaki menempel dengan dua tombol sama besar: "Lanjutkan dengan Plus" (`primary`) dan **"Lanjut dengan Gratis"** (`secondary`).

**Berhasil berlangganan** (sheet kecil): tile, "Plus aktif", "Paket Tahunan, diperpanjang 22 Okt 2027. Tanuki mulai bekerja untukmu.", satu langkah pertama ("Coba foto struk atau bukti transfer terakhirmu.") dengan tombol "Coba foto struk" dan "Nanti saja".

**Aturan**
- Tidak ada data yang dikunci atau dihapus saat turun; ditulis eksplisit di layar.
- Tanpa hitung mundur detik; penawaran selalu menyebut tanggal dan jam.
- "Mencatat, bukan melakukan": "Tercatat otomatis", bukan "Dibayar otomatis".

**Disediakan pemakai:** status langganan, tanggal berakhir, angka pemakaian, penawaran aktif.
