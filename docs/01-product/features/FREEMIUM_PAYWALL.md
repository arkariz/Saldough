# Freemium dan paywall: apa yang gratis, apa yang Plus, dan kenapa orang membayar

**Tanggal:** 18 Oktober 2026.
**Status:** Usulan, menunggu keputusan pemilik (§12). Belum ada kode.
Keputusan teknisnya nanti ditulis sebagai ADR baru sebelum implementasi
(PRD §13 "Arsitektur fitur online yang direncanakan", T-8.4). Antrean: B-41.
**Berkaitan:** [PRD 2.0](../prd-saldough-2.0.md) §5 (proposisi nilai dan
prinsip produk), §8.3 NFR-REL-001 dan §8.5 NFR-SEC-001 (pencatatan inti
wajib penuh tanpa koneksi; panggilan jaringan untuk verifikasi pembelian
diizinkan); [ADR-023](../../02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md)
(akun opsional, Analytics); [ADR-024](../../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)
(data milik perangkat); [ADR-027](../../02-architecture/adr/0027-catat-cerdas-interpreter-yang-bisa-diganti.md)
dan [ADR-032](../../02-architecture/adr/0032-catat-dari-notifikasi.md)
(Catat Cerdas, Gemini); [VOICE_INPUT_RESEARCH.md](VOICE_INPUT_RESEARCH.md)
§9 (biaya Gemini); [FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md) (Analisis
R1/R2); [RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md) (rutin,
perkiraan, R3).

Dokumen ini merancang **pembagian fitur, mekanisme konversi, dan harga**.
Rupa paywall diserahkan ke design system dan prototipe pemilik (skill
`tanukonomy-ui`); di sini hanya isi dan perilakunya.

## 1. Ringkasan rekomendasi

1. **Satu paket berbayar, "Tanukonomy Plus"** (nama menunggu KT-P1), bukan
   dua tingkat. Aplikasi masih kecil; satu pilihan lebih mudah dijual dan
   dirawat.
2. **Mencatat dan melihat datamu sendiri gratis selamanya, tanpa batas.**
   CATAT, Riwayat, Dompet, Anggaran, Rutin, dan ekspor data tidak pernah
   dikunci atau dibatasi jumlahnya. Ini yang membuat orang memasang dan
   bertahan; paywall di sini merusak kepercayaan dan prinsip 5 ("hambatan
   mencatat tetap rendah").
3. **Plus menjual tiga hal: lebih sedikit kerja, lebih jauh melihat, dan
   lebih tenang.**
   - *Lebih sedikit kerja*: Catat Cerdas otomatis (notifikasi tercatat
     sendiri, tafsir Gemini tanpa kuota ketat, otomasi rutin R3).
   - *Lebih jauh melihat*: Analisis seluruh riwayat, tren 12 bulan,
     tampilan tahun, perkiraan sampai 12 bulan, Rapor Tahunan.
   - *Lebih tenang*: cadangan otomatis (dan kelak sinkronisasi antar
     perangkat).
   Ditambah kosmetik bertema tanuki sebagai bonus yang murah dibuat.
4. **Pengait utama: uji coba terbalik (*reverse trial*) 14 hari tanpa kartu.**
   Semua pengguna baru langsung memakai Plus sesudah onboarding, lalu turun
   ke Gratis. Yang hilang terasa nyata ("12 catatan bulan ini kini perlu
   kamu tinjau sendiri"), bukan janji abstrak.
5. **Paywall kontekstual, bukan dinding.** Muncul di titik ketika pengguna
   baru saja merasakan manfaatnya (§6), maksimal sekali sehari, tidak
   pernah di tengah alur CATAT.
6. **Tanpa iklan sama sekali**, di paket mana pun. SDK iklan mengirim data
   pemakaian ke pihak ketiga, bertentangan dengan NFR-SEC-001 dan citra
   "data milik perangkat".
7. **Harga awal (hipotesis untuk diuji):** Rp19.000/bulan, Rp129.000/tahun,
   dan "Pendiri" seumur hidup Rp299.000 yang dijual terbatas (§8).
8. **Prasyarat sebelum paywall pertama tayang:** ekspor CSV dan cadangan
   manual ke berkas **gratis** (§9.1). Tidak etis memungut bayaran dari
   aplikasi yang datanya belum bisa dibawa pergi.

## 2. Inventaris fitur yang ada dan yang direncanakan

Diambil dari PRD §7, TASK_LIST, dan antrean B-n per 18 Okt 2026.

| # | Fitur | Keadaan | Biaya marginal per pengguna | Sifat nilainya |
|---|---|---|---|---|
| F1 | CATAT (pemasukan, pengeluaran, transfer, kalkulator, tautan pos) | Ada | 0 | Inti, kebiasaan harian |
| F2 | Riwayat dan pencarian | Ada | 0 | Inti, data pengguna |
| F3 | Dompet | Ada | 0 | Inti, proposisi nilai #1 |
| F4 | Anggaran, pos, arsip, penyaring | Ada | 0 | Inti, prinsip 3 |
| F5 | Template anggaran | Ada | 0 | Kemudahan, pengguna mahir |
| F6 | Freelance (proyek, worklog, pembayaran) | Ada | 0 | Pembeda, ceruk pekerja lepas |
| F7 | Beranda (saldo, arus, ringkasan) | Ada | 0 | Inti |
| F8 | Kategori bawaan yang bisa diubah | Ada | 0 | Inti |
| F9 | Catat pakai suara (STT sistem + parser aturan) | Ada | 0 | Kemudahan |
| F10 | Tafsir cerdas Gemini (fallback suara dan notifikasi) | Ada | ≈ US$0,0003 per panggilan (VOICE_INPUT_RESEARCH §9: ~US$4 per 15.000) | Kemudahan, "ajaib" |
| F11 | Catat dari notifikasi (Android), tinjau semua | Ada | 0 (Gemini terpisah, F10) | Kemudahan, pengait kuat |
| F12 | Tingkat otomatis 2/3 dan pola buatan sendiri | Ada | 0 | Otomasi, pengguna mahir |
| F13 | Rutin, kemunculan, pengingat, total langganan, kenaikan harga | Ada | 0 | Kebiasaan, retensi |
| F14 | Rencana Bulan ini, uang nganggur, perkiraan +2 bulan | Ada | 0 | Pandangan ke depan |
| F15 | Periode keuangan pilihan sendiri | Ada | 0 | Inti (memengaruhi semua angka) |
| F16 | Analisis R1 (ke mana uang pergi, dibanding biasanya, tren, per dompet) | Ada | 0 | Wawasan |
| F17 | Akun opsional, mata uang, bahasa, mode gelap, sembunyikan nominal | Ada | 0 | Dasar, privasi |
| F18 | Analisis R2: tahun, tren total saldo (B-38) | Direncanakan | 0 | Wawasan mendalam |
| F19 | Horizon perkiraan sampai 12 bulan (B-30) | Direncanakan | 0 | Pandangan ke depan |
| F20 | R3 Otomasi rutin: catat otomatis per rutin, saran pola, rutin menganggur (B-28) | Direncanakan | 0 | Otomasi |
| F21 | Sinkronisasi antar perangkat (B-7) | Direncanakan, besar | Server: penyimpanan dan baca/tulis Firestore | Ketenangan |
| F22 | Ekspor/impor data | **Belum ada**, di luar MVP (PRD §6) | 0 | Kepemilikan data |
| F23 | Cadangan otomatis | **Belum ada** | 0 bila ke Google Drive milik pengguna | Ketenangan |
| F24 | Kunci aplikasi (sidik jari/PIN) | **Belum ada** | 0 | Keamanan |
| F25 | Widget layar utama | **Belum ada** | 0 | Kebiasaan |
| F26 | Tema warna, kostum tanuki, ikon aplikasi alternatif | **Belum ada** | 0 (biaya aset sekali) | Kosmetik, identitas merek |
| F27 | Rapor bulanan/tahunan yang bisa dibagikan | **Belum ada** | 0 | Wawasan, viral |

Dua pengamatan dari tabel:

- **Hampir semua fitur berbiaya marginal nol.** Satu-satunya biaya
  berjalan yang nyata hari ini adalah Gemini, dan itu pun sangat murah.
  Artinya paywall tidak perlu dibenarkan dengan "biaya server"; ia harus
  dibenarkan dengan **nilai**. Kuota Gemini (§4.3) dipakai sebagai bingkai
  nilai, bukan pelindung biaya.
- **Belum ada cadangan maupun ekspor.** Data hidup hanya di satu ponsel.
  Ini risiko terbesar bagi pengguna (ganti/hilang ponsel = catatan hilang)
  dan sekaligus alasan membayar yang paling umum di kategori ini (Monefy
  dan Spendee menjual sinkronisasi/cadangan). Lihat §9.1.

## 3. Prinsip pembagian

Setiap fitur diuji dengan lima pertanyaan, berurutan:

1. **Apakah menguncinya membuat aplikasi gratis gagal memenuhi janjinya
   sendiri?** Kalau ya, gratis. Janjinya: tahu di mana uangmu, apa yang
   terjadi, dan ke mana direncanakan pergi (prinsip 1–3), dengan hambatan
   mencatat rendah (prinsip 5).
2. **Apakah ini data milik pengguna?** Melihat, mencari, dan membawa pergi
   datanya sendiri selalu gratis. Plus boleh menjual *cara baru membaca*
   data (tren panjang, tampilan tahun), bukan akses ke data itu.
3. **Apakah ini keamanan atau aksesibilitas?** Gratis (kunci aplikasi, mode
   gelap, sembunyikan nominal, bahasa).
4. **Apakah ini menghemat kerja yang tetap bisa dilakukan manual?** Kandidat
   Plus. Pengguna gratis tetap bisa mencapai hasil yang sama dengan tangan;
   Plus membuatnya terjadi sendiri. Ini cocok dengan sifat aplikasi:
   otomatisasi selalu lewat `RecordTransaction` (aturan 8), jadi tidak ada
   jalur pencatatan khusus berbayar.
5. **Apakah ini kedalaman yang hanya dibutuhkan setelah berbulan-bulan
   memakai?** Kandidat Plus. Nilainya tumbuh bersama riwayat, sehingga
   pengguna yang paling setia adalah yang paling mau membayar.

Yang sengaja **tidak** dipakai sebagai tuas:

- **Batas jumlah transaksi.** Menghukum kebiasaan yang ingin dibangun.
- **Batas dompet.** Spendee (1 dompet), Wallet (3 akun), dan Money Lover
  membatasi ini, tapi di Tanukonomy dompet adalah proposisi nilai #1 dan
  persona sasaran memang punya beberapa rekening, dompet digital, dan tunai.
  Batas 1–3 membuat Beranda menampilkan total saldo yang salah, sehingga
  versi gratis berbohong. Alternatif batas longgar ada di KT-P3.
- **Iklan.** Lihat §1 butir 6.
- **Mengunci data saat Plus berakhir.** Lihat §7.

## 4. Pembagian Gratis dan Plus

### 4.1 Tabel pembagian

| Area | Gratis (selamanya) | Plus |
|---|---|---|
| **Mencatat** (F1, F8, F9) | CATAT lengkap, kalkulator, kategori sendiri, suara dengan parser aturan, tanpa batas | — (sama) |
| **Riwayat dan Dompet** (F2, F3, F7) | Tanpa batas, pencarian, Beranda lengkap | — (sama) |
| **Anggaran** (F4, F5) | Anggaran dan pos tanpa batas; **1 template** | Template tanpa batas |
| **Rutin** (F13, F20) | Rutin tanpa batas, pengingat, kartu Menunggu, total langganan, deteksi kenaikan harga, catat satu ketuk | **Otomasi R3**: catat otomatis per rutin bernominal tetap, saran pola rutin dari riwayat, peringatan rutin menganggur |
| **Rencana** (F14, F15, F19) | Bulan ini, uang nganggur, perkiraan +2 bulan, periode keuangan | **Perkiraan sampai 12 bulan**, peringatan dini "uang nganggur menipis di bulan X" |
| **Catat dari notifikasi** (F11, F12) | Semua aplikasi sumber, pola bawaan, tingkat **tinjau semua** (kotak masuk + pengingat) | **Tingkat otomatis** (dicatat langsung bila lengkap/yakin), **pola buatan sendiri** |
| **Tafsir cerdas** (F10) | **30 tafsir per bulan** (suara + notifikasi digabung), lalu jatuh ke parser aturan | **Tanpa kuota** (batas wajar 1.000/bulan, tidak ditampilkan) |
| **Analisis** (F16, F18) | **6 periode terakhir**: seluruh Analisis R1, termasuk "dibanding biasanya" dan tren enam bulan | **Seluruh riwayat**, tren 12 bulan, tampilan tahun, tren total saldo (B-38) |
| **Freelance** (F6) | **2 proyek aktif** (proyek selesai/arsip tidak dihitung) | Proyek aktif tanpa batas |
| **Rapor** (F27, baru) | Rapor bulanan ringkas (bisa dibagikan, bertanda Tanukonomy) | **Rapor Tahunan** lengkap ("Tahun Tanuki-mu"), rapor bulanan rinci |
| **Data** (F22, F23, F21) | **Ekspor CSV, cadangan dan pulihkan manual ke berkas** | **Cadangan otomatis** harian ke Google Drive pengguna; kelak **sinkronisasi antar perangkat** |
| **Keamanan dan dasar** (F17, F24) | Kunci aplikasi, sembunyikan nominal, mode gelap, bahasa, mata uang | — (sama) |
| **Widget** (F25, baru) | Widget **tombol Catat** | Widget ringkasan (saldo, sisa anggaran, menunggu) |
| **Kosmetik** (F26, baru) | Tema bawaan terang/gelap | Tema warna tambahan, kostum tanuki, ikon aplikasi alternatif |
| **Iklan** | Tidak ada | Tidak ada |

### 4.2 Kenapa garisnya di sana

- **Rutin tetap gratis penuh**, otomasinya yang Plus. Pengingat rutin adalah
  mesin kebiasaan (orang kembali ke aplikasi tiap tagihan jatuh tempo);
  membatasinya menurunkan retensi, sumber semua konversi.
- **Notifikasi gratis di tingkat tinjau semua.** Pengguna gratis tetap
  merasakan sihirnya (notifikasi bank berubah jadi draf CATAT terisi),
  sehingga mereka tahu persis apa yang dibeli: menghilangkan satu ketukan
  "Simpan" per transaksi, puluhan kali sebulan. Ini pengait paling kuat
  karena manfaatnya terhitung (§6, P1).
- **Analisis 6 periode gratis** sama dengan jangkauan R1 yang sudah
  dipakai penguji (tren enam bulan, pembanding rata-rata 3 bulan, aturan
  B-6), jadi tidak ada yang dicabut. Plus menjual yang belum ada: riwayat
  lebih dari 6 periode, tren 12 bulan, dan tampilan tahun (R2). Pemicunya
  datang terlambat (bulan ke-7), tapi saat itu pengguna sudah terikat dan
  riwayatnya paling berharga. Daftar Riwayat sendiri tetap penuh; yang Plus
  hanya tampilan analisisnya.
- **Freelance 2 proyek aktif.** Pembeda produk tetap terlihat di versi
  gratis (karyawan dengan satu sampingan cukup), sementara pekerja lepas
  sungguhan dengan banyak klien adalah segmen yang paling mudah membenarkan
  biaya Rp19.000 terhadap penghasilannya.
- **1 template anggaran gratis** supaya pengguna mengerti fiturnya; yang
  menyusun banyak anggaran berulang adalah pengguna mahir.

### 4.3 Kuota tafsir cerdas

- Dihitung per periode keuangan (bukan bulan kalender), satu tafsir = satu
  panggilan Gemini yang berhasil. Tafsir oleh pola dan parser aturan tidak
  dihitung, jadi kebanyakan pengguna gratis tidak akan pernah menyentuh
  batasnya bila pola bawaannya bagus.
- Saat kuota habis: tidak ada yang gagal. Suara tetap mengisi draf dengan
  parser aturan, notifikasi yang tidak cocok pola masuk kotak masuk tanpa
  tafsir. Pesan netral sekali per periode: "Tafsir cerdas bulan ini sudah
  terpakai 30. Catatan tetap jalan; bagian yang ragu dikosongkan seperti
  biasa."
- Angka 30 dan 1.000 dibaca dari Remote Config (sudah dipakai Fase 20),
  sehingga bisa disetel tanpa rilis.
- Biaya terburuk pengguna Plus yang menghabiskan 1.000 tafsir:
  ≈ US$0,27/bulan (VOICE_INPUT_RESEARCH §9). Aman terhadap harga mana pun
  di §8.

## 5. Uji coba terbalik (reverse trial)

### 5.1 Alur

| Kapan | Yang terjadi |
|---|---|
| Akhir onboarding | Layar hadiah, bukan tagihan: "Plus aktif 14 hari, gratis. Tanpa kartu, tanpa langganan otomatis." Satu tombol "Mulai". Daftar 3 hal yang Plus lakukan, dipersonalisasi dari pilihan onboarding (mis. bila mengaktifkan catat notifikasi: "Catatan dari notifikasi bank tercatat sendiri"). |
| Hari 0–14 | Semua fitur Plus aktif. Tur spotlight (ADR-021) menyorot fitur Plus saat pertama tampil, dengan lencana kecil "Plus". Catat notifikasi menawarkan tingkat otomatis begitu pengguna menyelesaikan 3 tinjauan. |
| Hari 11 | Satu notifikasi lokal dan kartu di Beranda: **rekap nilai**, bukan hitung mundur. "3 hari lagi Plus-mu selesai. Selama ini: 23 catatan tercatat otomatis, 9 tafsir cerdas, tren 4 bulan dibuka." Angka dihitung dari pemakaian lokal. |
| Hari 14 | Layar turun ke Gratis: apa yang tetap (semua catatan, semua data), apa yang berubah (dengan angka pemakaiannya), dan penawaran perkenalan **48 jam**: tahun pertama Rp99.000. Tombol kedua "Lanjut dengan Gratis" sama jelasnya. |
| Sesudahnya | Hanya paywall kontekstual (§6). Penawaran perkenalan muncul sekali lagi di akhir periode keuangan berikutnya, lalu tidak lagi. |

### 5.2 Kenapa reverse trial, bukan uji coba Play biasa

- Uji coba Play Billing butuh kartu atau metode bayar dan berlangganan
  otomatis. Di Indonesia banyak pengguna tidak punya kartu kredit di akun
  Play (pulsa dan dompet digital memang tersedia, tapi tetap ada hambatan),
  dan "berlangganan otomatis" menakutkan untuk aplikasi baru yang belum
  dipercaya.
- Freemium biasa membuat pengguna tidak pernah merasakan fitur Plus. Ringkasan
  laporan RevenueCat 2026 menyebut median konversi uji coba ke berbayar
  hari ke-35 10,7% untuk *hard paywall* dan 2,1% untuk freemium. Reverse
  trial berusaha mengambil sebagian keunggulan hard paywall (pengguna
  merasakan produk penuh) tanpa mengunci pintu masuk.
- Rasa kehilangan lebih kuat dari janji. Pengguna yang sudah 14 hari
  melihat notifikasi banknya tercatat sendiri akan merasakan kembali ke
  tinjau manual sebagai kemunduran nyata.

### 5.3 Panjang uji coba

14 hari dipilih karena cukup untuk melihat dua sampai tiga siklus belanja
mingguan dan satu sampai dua tagihan rutin, tetapi berakhir sebelum
pengguna melupakan aplikasinya. Alternatif yang lebih selaras dengan Fase 18:
**sampai akhir periode keuangan pertama yang penuh** (minimal 14 hari),
supaya Analisis sempat menampilkan satu periode utuh. Lebih kuat tapi
panjangnya tidak seragam (14–45 hari). Pilihan di KT-P2.

### 5.4 Penyalahgunaan

Uji coba disimpan lokal dan di Firebase Auth bila pengguna masuk. Pasang
ulang aplikasi bisa mengulang uji coba bagi yang tidak masuk akun. Untuk
skala sekarang, terima risiko ini: orang yang rela memasang ulang dan
kehilangan data tiap 14 hari bukan pembeli. Bila kelak berarti, kaitkan ke
Play Integrity atau wajibkan masuk akun untuk uji coba kedua.

## 6. Paywall kontekstual: titik pengait

Aturan umum:

- Paywall hanya muncul **sesudah** pengguna berhasil melakukan sesuatu,
  tidak pernah menghalangi tindakan mencatat. CATAT, simpan, dan sunting
  transaksi bebas paywall selamanya.
- Maksimal satu paywall kontekstual per hari dan tiga per periode keuangan;
  sesudah "Nanti saja" tiga kali pada pemicu yang sama, pemicu itu diam
  30 hari.
- Selalu tampilkan **angka milik pengguna** (berapa catatan, berapa bulan),
  bukan klaim umum.
- Nada mengikuti glosarium `docs/03-design/design-system/writing.md`:
  netral, menjelaskan manfaat, tanpa menghakimi, tanpa urgensi palsu.
  Kosakata tetap "mencatat", bukan "melakukan".

| # | Pemicu | Saat | Contoh kalimat (id) | Kekuatan |
|---|---|---|---|---|
| P1 | Pengguna gratis menyimpan tinjauan notifikasi ke-10 dalam satu periode | Sesudah simpan, kartu kecil di kotak masuk | "10 catatan dari notifikasi bulan ini kamu tinjau satu per satu. Dengan Plus, yang lengkap tercatat sendiri; kamu tinggal cek di daftar Tercatat otomatis." | Sangat kuat: manfaat terhitung, berulang |
| P2 | Menggeser Analisis ke periode ke-7 ke belakang, atau membuka tren 12 bulan | Halaman periode itu tampil dengan grafik **data asli** pengguna yang diburamkan | "Kamu sudah mencatat 9 bulan. Lihat semuanya dengan Plus." | Kuat: data milik sendiri yang terlihat tapi belum terbaca |
| P3 | Tafsir cerdas tersisa 5 | Sekali, di lembar suara/kotak masuk | "Tafsir cerdas tinggal 5 bulan ini." | Sedang |
| P4 | Membuat proyek freelance aktif ke-3 | Saat menekan Simpan; proyek tetap tersimpan sebagai **Arsip** bila menolak | "Proyek aktif ke-3 butuh Plus. Simpan sebagai arsip dulu, atau aktifkan Plus." | Kuat untuk pekerja lepas |
| P5 | Menggeser perkiraan Rencana melewati +2 bulan | Kolom ketiga berupa kartu terkunci | "Lihat sampai 12 bulan ke depan." | Sedang |
| P6 | Rutin bernominal tetap dicatat satu ketuk 3 bulan berturut-turut | Di rincian rutin | "Netflix sudah 3 bulan kamu catat dengan nominal yang sama. Plus bisa mencatatnya otomatis tiap tanggal 12." | Kuat, butuh R3 |
| P7 | 30 hari pemakaian atau 200 transaksi, belum pernah mencadangkan | Kartu Beranda, sekali | "200 catatanmu hanya ada di ponsel ini. Cadangkan sekarang (gratis), atau biarkan Plus mencadangkan tiap hari." | Kuat dan jujur; jalur gratis ada |
| P8 | Desember / akhir tahun keuangan | Kartu Beranda + notifikasi lokal | "Tahun Tanuki-mu sudah siap." Tiga kartu pertama gratis, sisanya Plus | Musiman, viral bila dibagikan |
| P9 | Membuka layar Akun | Baris tetap "Tanukonomy Plus" | — | Pasif, untuk yang sudah mau |

Rupa paywall (satu layar): judul berbasis pemicu, 3 manfaat teratas yang
diurutkan menurut pemicunya, pilihan **Tahunan** terpilih bawaan dengan
"setara Rp10.750/bulan", Bulanan di bawahnya, tautan "Pulihkan pembelian",
dan kalimat "Semua catatanmu tetap milikmu, berlangganan atau tidak."

## 7. Saat Plus berakhir (turun ke Gratis)

Prinsip: **tidak ada data yang dikunci, tidak ada yang dihapus, tidak ada
pencatatan yang terhalang.**

| Fitur | Perilaku sesudah turun |
|---|---|
| Tingkat otomatis notifikasi | Kembali ke tinjau semua. Transaksi yang sudah tercatat otomatis tetap ada. |
| Pola buatan sendiri | Tetap tersimpan dan **tetap dipakai** untuk mencocokkan; hanya membuat pola baru yang butuh Plus. (Mematikannya akan terasa seperti menghukum.) |
| Otomasi rutin R3 | Rutin kembali menunggu konfirmasi satu ketuk. |
| Proyek freelance aktif ke-3 dst. | Tetap aktif dan bisa dicatat (worklog, pembayaran diterima lewat CATAT); hanya **membuat** proyek aktif baru yang terhalang sampai di bawah batas. Aturan 6 dan 8 tidak pernah terhalang paywall. |
| Template ke-2 dst. | Tetap ada dan bisa dipakai; membuat template baru butuh Plus. |
| Analisis lebih dari 6 periode, tren 12 bulan, tahun | Terkunci tampilannya; Riwayat tetap penuh. |
| Cadangan otomatis | Berhenti; cadangan lama di Drive tetap bisa dipulihkan. Cadangan manual tetap tersedia. |
| Kosmetik | Kembali ke tema bawaan; pilihan disimpan bila berlangganan lagi. |

Aturan "yang sudah ada tetap berjalan, yang baru butuh Plus" lebih mudah
dijelaskan dan menghindari ulasan bintang satu "data saya dikunci".

## 8. Harga

### 8.1 Acuan pesaing (harga dolar, toko AS; harga Indonesia perlu dicek langsung di Play Store)

| Aplikasi | Model | Harga |
|---|---|---|
| Spendee | Gratis 1 dompet + 1 anggaran; Plus; Premium (sinkron bank) | Plus US$1,99/bln atau US$14,99/thn; Premium US$5,99/bln atau US$35,99/thn; uji coba 7 hari |
| Wallet (BudgetBakers) | Gratis terbatas (3 akun di Android); Premium | Sekitar US$4,49/bln, US$26,99/thn (sumber berbeda-beda) |
| Money Lover | Gratis terbatas dompet/anggaran + iklan; Premium seumur hidup; Linked Wallet bulanan terpisah | Seumur hidup US$19,99 (toko AS), 599.000đ (Vietnam) |
| Monefy | Gratis 1 akun; Pro sekali bayar (sinkron, multi-mata uang, tanpa iklan) | Bervariasi per toko |
| YNAB | Berbayar penuh, uji coba 34 hari | US$109/thn, US$14,99/bln |
| Monarch | Berbayar penuh, uji coba 7 hari | US$99,99/thn (Core) |

Pola yang terlihat: aplikasi pencatat manual di pasar berkembang berada di
kisaran US$15–27/tahun, sering dengan pilihan seumur hidup; harga
US$100/tahun hanya untuk aplikasi yang tersambung bank di pasar AS.

### 8.2 Usulan

| Paket | Harga | Catatan |
|---|---|---|
| Bulanan | **Rp19.000** | Pintu masuk; harga "kopi susu sekali" |
| Tahunan | **Rp129.000** (≈ Rp10.750/bln, hemat 43%) | Dipilih bawaan di paywall; tujuan utama |
| Perkenalan tahun pertama | **Rp99.000** | Hanya 48 jam sesudah uji coba berakhir dan sekali lagi di periode berikutnya |
| Pendiri (seumur hidup) | **Rp299.000** | Dijual terbatas, mis. 90 hari pertama rilis publik atau 500 pembeli pertama. Pasar Indonesia akrab dengan "sekali bayar" (Money Lover, Monefy). Dibatasi karena bertentangan dengan biaya sinkronisasi kelak |

Ini hipotesis. Uji dengan eksperimen harga Play Console begitu ada volume;
yang diukur adalah pendapatan per pemasang, bukan konversi saja.

### 8.3 Penguji closed testing

Penguji yang sudah ikut sejak closed testing diberi **Pendiri gratis**
(atau Plus 12 bulan, KT-P5) sebagai terima kasih, lewat kode promo Play.
Mereka sumber ulasan pertama di rilis publik.

## 9. Mekanisme teknis (garis besar untuk ADR)

### 9.1 Prasyarat gratis: ekspor dan cadangan manual

Sebelum paywall pertama: **Ekspor CSV** (transaksi, dompet, kategori) dan
**Cadangkan ke berkas / Pulihkan dari berkas** (salinan basis data lokal,
dibagikan lewat lembar bagi Android). Ini memenuhi ADR-024 (data milik
perangkat) secara bermartabat dan membuat jalur gratis P7 jujur. Pulihkan
mengikuti ADR-024 §3.3: data diganti dengan peringatan, tanpa penggabungan.

### 9.2 Pembelian dan hak (entitlement)

- **Google Play Billing lewat RevenueCat (`purchases_flutter`)**, usulan
  utama: verifikasi kuitansi di server tanpa backend sendiri, ID pengguna
  anonim cocok dengan akun opsional (ADR-023), paywall dan eksperimen bisa
  diatur dari dasbor, dan siap untuk iOS. Gratis sampai ambang pendapatan
  tertentu (cek ketentuan terbaru sebelum ADR). Alternatif: paket resmi
  `in_app_purchase` + verifikasi di Cloud Functions (butuh Blaze, T-11.8,
  dan kode server yang harus dirawat).
- Pemulihan pembelian lewat akun Play, tidak wajib masuk akun Tanukonomy.
- NFR-SEC-001 sudah mengizinkan panggilan untuk verifikasi pembelian. Data
  yang dikirim ke penyedia billing (ID pembelian, ID pengguna anonim) wajib
  dicatat di `docs/03-release/PLAY_DATA_SAFETY.md`.

### 9.3 Struktur kode (mengikuti ADR-030)

- `core/foundation/entitlement/`: port `Entitlements` (aliran
  `PlanState`: gratis, uji coba sampai tanggal X, Plus sampai tanggal Y),
  enum `PlusFeature`, dan batas (`freelanceActiveProjects`,
  `smartInterpretationsPerPeriod`, `analysisPeriodsBack`, `budgetTemplates`)
  yang dibaca dari Remote Config dengan nilai bawaan lokal. `core` tidak
  mengimpor fitur.
- `features/premium/`: paywall, layar hadiah uji coba, layar turun,
  adaptor RevenueCat. Dibuka lewat `PremiumRouteKeys.paywall` dengan
  parameter `PaywallTrigger` (P1–P9), sehingga fitur lain tidak mengimpor
  isinya.
- Fitur memeriksa hak lewat port, di lapisan presentasi atau use case
  otomasi, **tidak pernah** di `RecordTransaction` itu sendiri. Pencatatan
  manual tidak punya cabang hak sama sekali.
- **Luring:** hak terakhir disimpan lokal dengan tanggal berakhirnya, plus
  tenggang 3 hari bila tidak bisa memeriksa. Tanpa koneksi, pengguna Plus
  tetap Plus (NFR-REL-001).
- Kuota tafsir dihitung di klien per periode keuangan. Cukup untuk awal
  karena biayanya kecil dan App Check sudah melindungi Gemini.
- `test/architecture/import_boundaries_test.dart` diperluas untuk
  `features/premium/`.

### 9.4 Pengukuran

Peristiwa Analytics (ADR-023 sudah ada): `trial_started`,
`trial_value_recap_shown`, `trial_ended{outcome}`, `paywall_viewed{trigger}`,
`paywall_dismissed{trigger}`, `purchase_started{plan}`,
`purchase_completed{plan}`, `plus_feature_used{feature}`,
`smart_quota_exhausted`. Ukuran utama:

| Ukuran | Target awal (hipotesis) |
|---|---|
| Pengguna onboarding yang memulai uji coba | ≥ 90% (otomatis) |
| Uji coba → berbayar dalam 30 hari | 4–6% |
| Konversi per pemasang hari ke-60 | 2–4% (median freemium 2,1%, ringkasan RevenueCat 2026) |
| Porsi Tahunan dari pembelian | ≥ 60% |
| Paywall per pengguna per minggu | ≤ 1 (pengaman terhadap rasa diganggu) |
| Retensi D30 Gratis tidak turun dibanding sebelum paywall | ≤ 2 poin turun |

Pemicu yang konversinya rendah dibuang; batas dan kuota disetel lewat
Remote Config, bukan rilis.

## 10. Urutan peluncuran

| Tahap | Isi | Kenapa urutannya begini |
|---|---|---|
| **M0 Prasyarat** | ADR monetisasi; Firebase Blaze (T-11.8); ekspor CSV + cadangan/pulihkan manual (gratis); kunci aplikasi (gratis) | Kepercayaan dulu; tanpa ini paywall terasa memeras |
| **M1 Plus pertama** | Billing + entitlement; reverse trial; tingkat otomatis notifikasi + pola sendiri; kuota tafsir; Analisis >6 periode dan tren 12 bulan; perkiraan 12 bulan (B-30); template dan batas freelance; paywall P1–P5, P9; 1–2 tema kosmetik | Semua fitur ini **sudah ada** atau kecil; hanya perlu digerbang. Bisa tayang bersama rilis publik |
| **M2 Ketenangan dan otomasi** | Cadangan otomatis Google Drive; R3 otomasi rutin (B-28, P6); Analisis R2 tahun dan tren saldo (B-38); widget ringkasan; pemicu P7 | Menambah nilai Plus bagi yang sudah membayar, menekan churn tahunan |
| **M3 Musiman** | Rapor Tahunan (P8), target Desember 2026 bila sempat, atau akhir 2027 | Momen berbagi dan konversi alami |
| **M4 Sinkronisasi** | B-7, Plus atau tingkat lebih tinggi; pelanggan lama dipertahankan di harga lamanya | Proyek terbesar, butuh ADR sendiri |

## 11. Risiko

| Risiko | Mitigasi |
|---|---|
| Ulasan "dulu gratis sekarang bayar" dari penguji | Semua yang dipakai penguji tetap gratis kecuali otomasi; penguji dapat Pendiri gratis (§8.3) |
| Pengguna gratis merasa diganggu | Batas frekuensi §6, tidak ada paywall di CATAT, ukuran "paywall per minggu" |
| Konversi rendah di pasar Indonesia | Tahunan murah, pilihan seumur hidup terbatas, metode bayar Play lokal (pulsa, dompet digital) |
| Catat dari notifikasi hanya Android | Di iOS kelak, pengait utama bergeser ke Analisis, cadangan, dan rapor |
| Kebijakan Play tentang izin akses notifikasi dan fitur berbayar | Izin dan alasan penggunaannya sama untuk Gratis dan Plus; yang berbayar hanya tingkat otomatisnya |
| Hak Plus salah terbaca luring dan mengunci pengguna yang sudah bayar | Tenggang 3 hari, dan kegagalan baca hak tidak pernah memblokir pencatatan |

## 12. Keputusan pemilik yang dibutuhkan

- **KT-P1** Nama paket: "Tanukonomy Plus", "Premium", atau nama bertema
  tanuki lain?
- **KT-P2** Panjang uji coba terbalik: tetap 14 hari, atau sampai akhir
  periode keuangan pertama yang penuh (§5.3)?
- **KT-P3** Dompet tanpa batas di Gratis (usulan), atau batas longgar
  (mis. 6 dompet aktif) sebagai tuas tambahan?
- **KT-P4** Harga §8.2 dan apakah paket Pendiri seumur hidup dijual.
- **KT-P5** Hadiah penguji closed testing: Pendiri gratis atau Plus 12 bulan.
- **KT-P6** Penyedia billing: RevenueCat (usulan) atau `in_app_purchase`
  + Cloud Functions.
- **KT-P7** Apakah ekspor CSV dan cadangan manual (M0) dikerjakan sebelum
  rilis publik, meskipun paywall belum siap?

## 13. Sumber

- Spendee: [halaman Premium](https://www.spendee.com/premium) (Plus
  US$1,99/US$14,99, Premium US$5,99/US$35,99, uji coba 7 hari, gratis 1
  dompet tunai dan 1 anggaran).
- Wallet by BudgetBakers: [dukungan BudgetBakers](https://support.budgetbakers.com/hc/en-us/articles/7151349344018),
  [ulasan Finder](https://www.finder.com/uk/budgeting/wallet-budgetbakers-review),
  [ulasan TechRadar](https://www.techradar.com/reviews/wallet-finance-management).
- Money Lover: [App Store Vietnam](https://apps.apple.com/vn/app/money-lover-s%E1%BB%95-thu-chi/id486312413?l=vi),
  [App Store](https://apps.apple.com/dz/app/money-lover-money-manager/id486312413),
  [catatan uji coba Premium](https://note.moneylover.me/your-passport-to-premium-dive-into-14-days-of-exclusive-benefits/).
- Monefy: [ulasan Gerald](https://joingerald.com/learn/financial-wellness/monefy-expense-tracker-review),
  [harga IAP](https://apppricinglab.com/iap/apple/1212024409).
- YNAB dan Monarch: [perbandingan harga 2026](https://getfinny.app/blog/ynab-vs-monarch-money-2026),
  [Costbench](https://costbench.com/compare/ynab-vs-monarch-money/).
- Tolok ukur langganan: [RevenueCat State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps),
  [RevenueCat: tren dan tolok ukur 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026),
  [RevenueCat: hard paywall vs freemium](https://www.revenuecat.com/blog/growth/hard-paywall-vs-freemium),
  [Airbridge: hard vs soft paywall](https://www.airbridge.io/blog/hard-vs-soft-paywalls),
  [Adapty: strategi monetisasi freemium](https://adapty.io/blog/freemium-app-monetization-strategies/).
  Angka 10,7% vs 2,1% berasal dari ringkasan pihak kedua atas laporan
  RevenueCat 2026; halaman RevenueCat tidak bisa dibuka langsung saat riset,
  jadi perlakukan sebagai arah, bukan angka pasti.
- Harga minimum Play Indonesia: [Android Developers Blog, 2015](https://android-developers.googleblog.com/2015/11/minimum-purchase-price-for-apps-and-in.html)
  (Rp3.000; data lama, cek Play Console).
