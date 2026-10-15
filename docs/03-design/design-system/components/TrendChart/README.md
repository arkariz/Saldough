# TrendChart

Tren enam periode keuangan: pemasukan, pengeluaran, dan selisih per periode (Analisis), atau satu besaran dengan garis rata-rata (Rincian kategori). Kolom terpilih ditandai dan dirinci di panel angka di bawahnya.

**Bentuk**
- Enam slot tetap, rata kanan: periode terpilih yang sedang dilihat selalu di kanan. Periode sebelum pencatatan pertama **tidak digambar** (slotnya kosong, tanpa label), bukan nol.
- Tiap periode sepasang kolom dari kotak 6px berjarak 2px, sebahasa dengan bar anggaran. Pemasukan `positive` di kiri, pengeluaran `ink` di kanan, lebar 10px, jarak 2px. Versi satu besaran: satu kolom 14px `ink-2`.
- Kolom tumbuh dari garis dasar `ink-3`. Garis bantu `line` pada kelipatan rapi, labelnya nominal ringkas di kanan ("15 jt"). Ringkas hanya di grafik.
- Di bawah tiap kolom: label periode (`label-sm`), selisih ringkas bertanda ("+3,2 jt", "−630 rb") `ink-2`, tanpa merah. Baris keterangan `ink-3` di bawahnya (boleh dua baris) untuk periode yang belum biasa: **periode berjalan** "s.d. 10 Okt" dan **periode peralihan** "24 hari". Periode yang sedang berjalan juga peralihan: tulis "s.d. {tanggal}".
- **Periode berjalan: selisih tanpa tanda + atau −** ("5,9 jt"), di kolom maupun di panel, supaya kolom yang baru berjalan tidak terbaca sebagai hemat atau defisit.
- Periode terpilih: pita `surface-2` setinggi grafik dan label tebal `ink`.
- Tinggi 186px (area kolom 108px, area label 70px). Lebar acuan 296px: area kolom 260px, label sumbu 36px.

**Garis rata-rata (versi satu besaran, Rincian kategori)**
- Garis putus-putus `ink-2` 1,5px (4/3) selebar area kolom, setinggi rata-rata bulan pembanding. Label `caption` "rata-rata 3 bulan" di kiri, tepat di atas garis, berlatar `surface`.
- Putus-putus di sini berarti **garis acuan**, bukan perkiraan; Analisis tetap tanpa kolom atau bingkai perkiraan.
- Tanpa bulan pembanding ("baru bulan ini"): tanpa garis.

**Interaksi dan panel angka**
- Ketuk kolom = memilih kolom itu (`aria-pressed`). Tidak berpindah periode.
- Panel (`tk-readout`) di bawah grafik: nama periode (ditambah " · s.d. 10 Okt" bila berjalan), lalu
  - Analisis: Pemasukan, Pengeluaran, Selisih dengan nominal penuh;
  - Rincian kategori: satu baris "Rp1.245.000 · Rp295.000 di atas rata-rata" (atau "di bawah rata-rata"; tanpa pembanding untuk kategori baru, periode berjalan, dan periode peralihan).
- Bila kolom terpilih bukan periode yang sedang dilihat, panel mendapat tautan "Lihat analisis {periode}" yang memindah Analisis ke periode itu.

**Aturan**
- Tanpa `≈` dan tanpa periode masa depan. Kurang dari dua periode: grafik tidak tampil.
- Terbaca tanpa warna: urutan kiri-kanan tetap dan legenda memakai kata. Label tombol kolom lengkap: "September 2026, pemasukan Rp14.615.438, pengeluaran Rp11.420.700, selisih +Rp3.194.738".
- Nominal tersembunyi: kolom dan garis tetap tampil, label sumbu dan selisih "•••", nominal panel `Rp•••••`.

**Disediakan pemakai:** periode (label, nilai, keterangan, berjalan atau tidak), indeks terpilih, indeks periode yang dilihat, rata-rata opsional, handler pilih dan pindah.
