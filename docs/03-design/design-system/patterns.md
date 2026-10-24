# Pola layar

## Navigasi

- Navigasi bawah berisi empat tujuan dan tombol Catat di tengah: Beranda, Riwayat, [Catat], Anggaran, Dompet. Tombol Catat adalah satu-satunya pintu mencatat transaksi manual.
- Catat pakai suara ada di dalam sheet Catat (tombol mikrofon di bar atas sheet). Tekan lama tombol Catat langsung membuka mode suara. Tidak ada tombol melayang kedua.
- Akun dibuka dari tombol profil di kanan atas Beranda. Freelance dibuka dari kartu Freelance di Beranda. Kotak masuk notifikasi dibuka dari banner di Beranda dan Riwayat, dan dari Akun.
- Halaman turunan (rincian anggaran, rincian dompet, freelance, kotak masuk, akun) menyembunyikan navigasi bawah dan memakai tombol kembali.
- Tab yang punya beberapa bagian setara memakai SubTabs tepat di bawah bar atas: Rencana (Bulan ini, Anggaran, Rutin) dan Riwayat (Daftar, Analisis). Riwayat mengingat segmen terakhir; pintu dari kartu Arus Beranda selalu membuka Analisis.

## Anatomi halaman tab

1. Bar atas besar: judul `headline` di kiri, paling banyak dua tombol ikon di kanan.
2. Angka utama halaman (`amount-hero`) dengan label `body-sm` di atasnya.
3. Paling banyak satu banner perhatian.
4. Bagian-bagian: judul bagian di atas `bg`, isi di kartu `surface`.
5. Ruang bawah `space-12` supaya isi terakhir tidak tertutup navigasi.

## Anatomi halaman turunan

1. Bar atas: kembali, judul `title`, menu lainnya.
2. Ringkasan di atas, rincian di bawah.
3. Satu tindakan utama menempel di bawah layar (`shadow-bar` di atasnya), lebar penuh.

## Daftar

- Riwayat dikelompokkan per hari. Kepala grup: "Hari ini · Senin, 28 Sep" di kiri, selisih hari itu di kanan (`amount-sm`, `ink-2`).
- Satu kartu per grup, baris dipisahkan `line` yang menjorok.
- Baris transaksi: tile kategori (ikon piksel), judul (catatan, atau nama kategori bila catatan kosong), subjudul "Dompet · jam", nominal bertanda di kanan.
- Baris yang menunggu tindakan (dari notifikasi) memakai badge "Perlu dicek", bukan latar berwarna.

## Form dan Catat

- Semua form muncul sebagai sheet dari bawah. Catat memakai sheet tinggi penuh.
- Urutan Catat: jenis (kontrol segmen) → nominal (keypad) → kategori (chip, kategori terakhir dipakai di depan) → dompet → tanggal → catatan → Simpan.
- Nilai bawaan pintar: dompet terakhir dipakai, tanggal hari ini, kategori yang paling sering di jam yang sama.
- Akibat ke saldo ditulis satu kali sebagai bantuan di bawah baris dompet ("Saldo Tunai jadi Rp331.000"), bukan banner aturan dan ringkasan ganda.
- Tombol Simpan menyebut jenisnya ("Simpan pengeluaran") dan nonaktif sampai nominal dan dompet terisi.

## Ringkasan dulu, rincian kemudian

- Beranda: total saldo → yang perlu tindakan → bulan ini → anggaran → freelance → transaksi terbaru.
- Anggaran: sisa → bar dengan penanda waktu → daftar pos → transaksi tertaut.
- Dompet: total → sebaran per dompet (BalanceSpread: ringkas bawaan, bisa dibuka menjadi donat) → daftar dompet.

## Penanda waktu anggaran

Bar anggaran memuat garis tipis `ink` yang menandai seberapa jauh periode sudah berjalan. Bila isi bar ada di kiri garis, belanja lebih lambat dari waktu ("Aman"). Bila di kanan dan sudah 85% atau lebih, statusnya "Hampir habis".

## Keadaan per layar

Setiap layar punya empat keadaan yang dirancang: memuat (skeleton), kosong (EmptyState), galat (pesan + Coba lagi), dan berisi. Keadaan kosong pertama kali di Beranda berupa daftar langkah: tambah dompet, catat transaksi pertama, buat anggaran (opsional).

## Periode keuangan

- "Bulan" di aplikasi adalah periode keuangan yang dimulai di tanggal pilihan pengguna (1–28 atau hari terakhir bulan). Namanya mengikuti PeriodHeader: nama bulan bila mulai tanggal 1, selain itu rentangnya.
- Satu-satunya tempat mengubah awal bulan keuangan: ketuk PeriodHeader di Rencana › Bulan ini, atau baris "Awal bulan keuangan" di Akun. Keduanya membuka lembar DayPicker yang sama.
- Periode peralihan diberi penanda netral "Periode peralihan · {n} hari" di Bulan ini, kepala kartu Arus Beranda, dan kepala Analisis. Penanda ini keterangan, tidak pernah memakai warna atau ikon peringatan. Peringatan tetap hanya untuk risiko berbasis saldo (siapkan dana, titik terendah negatif).

## Analisis

Riwayat › Analisis menjawab "uangku ke mana, dibanding biasanya". Hanya membaca, tanpa perkiraan.

1. PeriodStepper (‹ periode ›, maju berhenti di periode berjalan).
2. SegmentedControl Pengeluaran / Pemasukan, lalu chip penyaring dompet "Semua dompet ▾".
3. Satu kartu: DonutChart (jenis dan total di tengah), pembanding `tk-cmp`, 0–3 sorotan bertautan, lalu legenda LegendRow: lima teratas, Lainnya yang bisa dibuka, Tanpa kategori. Ketuk irisan atau baris untuk melihat satu kategori di tengah donat, dengan pembanding dan "Lihat rincian" (atau "Beri kategori").
4. Transfer di kaki kartu yang sama (`tk-card__foot`): "Dipindahkan antardompet" + nominal, "Tidak mengurangi total uangmu".
5. Bagian "6 bulan terakhir" dengan TrendChart; ketuk kolom memilihnya, panel angka memberi "Lihat analisis {periode}".

**Rincian kategori:** kartu atas (periode, total `amount-hero`, persen dari jenisnya, pembanding, lalu ringkasan frekuensi `tk-freq`: "2 transaksi · rata-rata Rp622.500 per transaksi" dan "biasanya 1,7 transaksi · Rp570.000" `ink-2`), TrendChart satu besaran dengan garis rata-rata, lalu transaksi (ketuk → Rincian transaksi) dan "Lihat semua transaksi". Kategori baru: tanpa garis dan tanpa "biasanya".

Riwayat Daftar dan Analisis berbagi periode (PeriodStepper yang sama).

Nada netral di seluruh layar: tanpa `warning` atau `danger`, tanpa `≈`, tanpa bingkai putus-putus. Arah perubahan disampaikan oleh panah `ink-2` dan kata, bukan warna. Warna kategori di donat hanya pembeda kategori, bukan penilaian.

## Pembaruan aplikasi

Fase 20, rupa v3 mengikuti rujukan gambar pilihan pemilik (15 Okt 2026).

1. **Kartu pembaruan di Beranda** (UpdateCard): kartu `brand` di paling atas Beranda dengan 🚀, judul, pil versi, tautan "Lihat apa yang baru" dan satu tombol. Di gambar ia berada di atas kartu saldo dan berdampingan dengan banner kotak masuk; ini menyimpang dari satu banner per layar dan B-2/B-3 dan menunggu keputusan product owner. Tanpa hitung mundur.
2. **Lembar Apa yang baru** (Sheet varian Catatan + ReleaseNotes): dibuka dari tautan di kartu (sebelum dipasang: Perbarui + Nanti) dan sekali sesudah pembaruan yang punya catatan (Oke). Tidak di Catat, onboarding, atau tur. Beberapa versi sekaligus: satu lembar, dikelompokkan per versi.
3. **Akun › Versi aplikasi**: baris di grup paling bawah (ikon system_update): judul, nomor versi, keterangan keadaan. Halaman Versi aplikasi: kartu status (tile `brand-soft`), bagian "Apa yang baru" berisi satu kartu per versi, tindakan lebar penuh menempel di bawah hanya saat ada tindakan.
4. Teks dan keadaan mengikuti dokumen fitur; di sini hanya rupanya.

## Penemuan fitur

Fase 21 (FEATURE_DISCOVERY, revisi 19 Okt 2026). Tiga fitur yang sulit ditemukan (awal bulan keuangan, Catat dari notifikasi, pengingat rutin) ditawarkan pada saat nilainya terasa, tanpa tekanan.

1. **Onboarding: dua langkah wajib** (OnboardingStep): slide pengantar › bahasa › mata uang › awal periode keuangan › pengingat rutin › penutup. Tanpa Lewati. Wajib dijawab, bebas dijawab apa: Nyalakan dan Tidak sekarang sama besar. Tanggal: bawaan 1 terpilih, tetap dikonfirmasi. Catat dari notifikasi bukan langkah; penutup memuat satu baris informasi (Android).
2. **Satu widget Kotak masuk notifikasi di Beranda** (InboxCard, Android): Catat dari notifikasi tidak punya kartu sendiri. Keadaan: belum disetel (Nyalakan, membuka Mulai cepat), izin hilang (Izinkan), sakelar mati (Nyalakan), aktif tanpa yang menunggu ("{n} aplikasi aktif" + Kelola aplikasi & pola), aktif dengan tangkapan (Cek, pratinjau, Ajari pola, Kelola aplikasi & pola). Tidak pernah hilang, tanpa tutup. Latar `warning-soft` hanya bila ada yang perlu dicek.
3. **Kartu pengingat** (FeatureNudge): tombol Nyalakan/Izinkan selama pengingat belum efektif, hilang saat efektif, tanpa tutup. Urutan P-6: kartu pembaruan › Menunggu dicatat dan InboxCard › kartu pengingat.
4. **Mulai cepat**: satu layar dengan daftar aplikasi bank/dompet digital yang punya pola bawaan (sudah tercentang, `tk-row--check`), baris Aplikasi lain, dan tombol sticky "Nyalakan" (menjadi "Izinkan" bila kembali tanpa izin, dengan status Izin belum diberikan). Tanpa aplikasi bawaan terpasang: hanya baris Aplikasi lain.
5. **Status di Akun › Pencatatan**: baris Catat dari notifikasi (Android, jumlah aplikasi), Pengingat rutin, Awal bulan keuangan. Status berupa Badge (Nyala `positive`, Mati netral, Izin belum diberikan `warning` dengan teks).
6. **Kepala periode dapat diketuk**: pil tonal dengan petunjuk "Atur" (PeriodHeader). **Tawaran gajian** (PaydayOffer): kartu biasa di kepala Bulan ini untuk pengguna lama; boleh ditutup, satu-satunya.
7. Tidak ada streak, hitungan hari, lencana, atau kata "ketinggalan". Warna peringatan hanya untuk status izin yang hilang, selalu bersama teks.

## Ekspor, cadangan, dan pulihkan

Fase 22 (EXPORT_BACKUP, T-22.0). Semua gratis, tanpa akun, tanpa ajakan Plus.

1. **Akun › Data kamu**: bagian sendiri (judul, satu paragraf, tiga baris): Ekspor ke spreadsheet, Cadangkan sekarang (keterangan "Cadangan terakhir: 12 Okt 2026" atau "Belum pernah dicadangkan", netral, tanpa warna peringatan), Pulihkan dari cadangan. Baris keempat **Kembalikan data sebelum pemulihan (22 Okt 2026)** hanya ada selama cadangan pengaman tersimpan (paling lama 30 hari).
2. **Ekspor** dan **Cadangkan** memakai DataSheet (ekspor hanya dari Akun, tanpa pilihan rentang: selalu seluruh data saat ini): awal › proses (bisa dibatalkan) › siap dengan dua tombol **Simpan ke…** dan **Bagikan**. Status cadangan terakhir berubah hanya bila berkas tersimpan.
3. **Pulihkan** adalah halaman turunan (RestoreFlow), bukan sheet: pratinjau dengan perbandingan › dialog penggantian › proses › selesai atau galat. Kembalikan data memakai halaman yang sama.
4. **Onboarding**: tautan teks "Sudah punya cadangan? Pulihkan" di bawah tombol Lanjut slide pertama. Urutan: bahasa › berkas › pratinjau (satu kolom, tanpa peringatan) › proses › selesai; langkah mata uang dan periode dilewati.
5. Galat selalu menyebut "Datamu tidak berubah." dan tidak memakai warna `danger`.

## Plus dan paywall

Tanukonomy Plus (B-41, rencana paywall 23 Okt 2026). Plus menjual pekerjaan yang dilakukan Tanuki, tidak pernah menahan pencatatan atau data.

1. **Tiga lapis, makin tenang ke makin tegas**: lencana Plus di fitur (PlusLocked) › kartu konteks sesudah tindakan berhasil (PlusPrompts) › paywall (PlusPaywall). Pencatatan, CATAT, dan data pengguna tidak punya cabang hak.
2. **Paywall** adalah lembar hampir penuh di atas layar pemicu. Tombol "Nanti saja" sama besar dengan tombol beli. Harga selalu string toko; wajib ada harga per periode, perpanjangan otomatis, dan cara membatalkan.
3. **Batas Gratis** ditunjukkan oleh kartu terkunci yang menyebut yang tetap berjalan, dengan jalan gratis bila ada. Hanya Analisis di luar 6 periode dan perkiraan lewat +2 bulan yang diburamkan, dengan data asli.
4. **Uji coba terbalik**: hadiah di akhir onboarding menyebut tanggal berakhir (bukan jumlah hari); rekap nilai H-3 hanya memuat yang benar-benar terjadi; layar turun ke Gratis menyebut yang tetap dan yang berubah dengan angka pengguna, dengan "Lanjut dengan Gratis" sama jelasnya.
5. **Akun** memuat bagian "Plus": kartu status enam keadaan, "Kelola di Play Store", "Pulihkan pembelian".
6. Frekuensi: paywall kontekstual paling banyak sekali sehari dan tiga kali per periode; tiga "Nanti saja" pada pemicu yang sama membuatnya diam 30 hari. Tidak pernah di tengah CATAT.
7. Tanpa streak, poin, skor, hitung mundur detik, atau urgensi palsu. Warna peringatan hanya untuk masa tenggang pembayaran.

