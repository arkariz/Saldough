# Freemium dan paywall: Gratis untuk mencatat, Plus agar Tanuki bekerja untukmu

**Tanggal:** 18 Oktober 2026 (revisi 2, hari yang sama).
**Status:** **Diputuskan pemilik 18 Okt 2026** (semua KT-P1–P11, §15).
Belum ada kode. Uji coba berlaku sampai akhir periode keuangan pertama
yang penuh (KT-P2, §8).
Keputusan teknisnya ditulis sebagai ADR baru sebelum implementasi (PRD §13
"Arsitektur fitur online yang direncanakan", T-8.4). Antrean: B-41.
**Revisi 2:** pemilik menilai Plus versi pertama kalah nilai dari versi
gratis yang sudah mulus. Plus dirancang ulang dari "gratis plus sedikit"
menjadi kelas pekerjaan yang lain (§2), dengan fitur Plus baru (§6) dan
peta fitur mendatang (§7).
**Berkaitan:** [PRD 2.0](../prd-saldough-2.0.md) §5 (proposisi nilai dan
prinsip produk), §6 "Di luar MVP" (pemindaian struk, asisten AI, laporan
tahunan, utang, akun bersama), §8.3 NFR-REL-001 dan §8.5 NFR-SEC-001;
[ADR-023](../../02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md)
(akun opsional, Analytics); [ADR-024](../../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)
(data milik perangkat); [ADR-027](../../02-architecture/adr/0027-catat-cerdas-interpreter-yang-bisa-diganti.md)
dan [ADR-032](../../02-architecture/adr/0032-catat-dari-notifikasi.md)
(Catat Cerdas, Gemini); [VOICE_INPUT_RESEARCH.md](VOICE_INPUT_RESEARCH.md)
§9 (biaya Gemini); [FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md) (Analisis
R1/R2); [RECURRING_AND_FORECAST.md](RECURRING_AND_FORECAST.md) (rutin,
perkiraan, katalog wawasan §7B, R3).

Dokumen ini merancang **pembagian fitur, fitur Plus, mekanisme konversi,
dan harga**. Rupa diserahkan ke design system dan prototipe pemilik (skill
`tanukonomy-ui`).

## 1. Ringkasan rekomendasi

1. **Gratis = buku catatan. Plus = juru catat pribadi.** Di versi gratis,
   kamu yang mencatat dan kamu yang membaca. Di Plus, **Tanuki bekerja
   untukmu**: ia mencatat dari foto dan notifikasi, berjaga dan memberi tahu
   sebelum masalah terjadi, menjawab pertanyaan tentang uangmu, membantu
   merencanakan "bagaimana kalau", dan menyusun laporan yang siap dipakai.
   Kalimat ini cocok dengan maskot (tanuki juru catat) dan dengan definisi
   produk: Plus tetap *mencatat*, tidak pernah *melakukan*.
2. **Enam pilar Plus** (§5): Tanuki Mencatat, Tanuki Berjaga, Tanya Tanuki,
   Tanuki Merencanakan, Tanuki Melapor, Tanuki Menyimpan. Tiap pilar adalah
   pekerjaan yang **tidak bisa** dilakukan versi gratis dengan tangan, bukan
   versi gratis yang sedikit lebih cepat.
3. **Gratis tetap mulus untuk inti.** CATAT, Riwayat, Dompet, Anggaran,
   Rutin, Rencana bulan ini, Analisis 6 periode, dan ekspor data gratis
   tanpa batas. Yang dikurangi dari versi gratis hanya hal yang memang
   berupa otomasi (§4.3).
4. **Model "cicip", bukan kunci mati.** Setiap pilar Plus punya jatah kecil
   gratis per periode keuangan: 1 peringatan Penjaga, 3 pertanyaan Tanya
   Tanuki, 5 catat dari foto, ringkasan rapor. Pengguna gratis terus
   merasakan rasanya, sehingga tahu persis apa yang dibeli.
5. **Uji coba terbalik tanpa kartu sampai akhir periode keuangan pertama
   yang penuh** (14–45 hari), dirancang supaya setiap pilar punya satu
   "momen ajaib" terjadwal di dalamnya (§8).
6. **Harga (hipotesis):** Rp25.000/bulan, Rp179.000/tahun; **Harga Pendiri**
   Rp129.000/tahun yang terkunci selama tetap berlangganan, untuk pembeli
   90 hari pertama. Tanpa paket seumur hidup karena pilar AI punya biaya
   berjalan (§11).
7. **Tanpa iklan di paket mana pun**, dan **ekspor serta cadangan manual
   gratis** sebelum paywall pertama tayang (§12.1).

## 2. Kenapa versi pertama terasa kurang premium

Isi Plus revisi 1 dan masalahnya:

| Isi Plus revisi 1 | Kenapa lemah |
|---|---|
| Notifikasi tercatat otomatis | Versi gratis sudah mengisi draf; Plus hanya menghemat satu ketukan "Simpan" |
| Analisis lebih dari 6 periode, tren 12 bulan | Baru terasa setelah 7 bulan; bagi pengguna baru tidak ada bedanya |
| Perkiraan 12 bulan | Versi gratis sudah memberi +2 bulan; selisihnya kuantitas, bukan kualitas |
| Template dan proyek freelance lebih banyak | Batas jumlah; terasa sebagai rintangan, bukan hadiah |
| Kosmetik | Bagus sebagai bonus, tidak cukup sebagai alasan |

Polanya sama: **Plus = Gratis + sedikit**. Pengguna yang sudah puas dengan
versi gratis tidak punya pekerjaan baru yang ingin diselesaikan. Paket yang
terasa premium menjual **pekerjaan yang berbeda jenisnya**:

- Gratis menjawab "**apa yang sudah terjadi**". Plus menjawab "**apa yang
  akan terjadi, apa artinya, dan apa yang sebaiknya kuperhatikan**".
- Gratis menunggu kamu membuka aplikasi. Plus **datang padamu** saat ada yang
  perlu diketahui.
- Gratis memberi angka. Plus memberi **jawaban dan dokumen siap pakai**
  (rapor, rekap SPT, invoice).

## 3. Inventaris fitur yang ada dan yang direncanakan

Ringkas dari PRD §7, TASK_LIST, dan antrean B-n per 18 Okt 2026.

| # | Fitur | Keadaan | Biaya marginal |
|---|---|---|---|
| F1 | CATAT (pemasukan, pengeluaran, transfer, kalkulator, tautan pos) | Ada | 0 |
| F2 | Riwayat dan pencarian | Ada | 0 |
| F3 | Dompet | Ada | 0 |
| F4 | Anggaran, pos, arsip, penyaring; template | Ada | 0 |
| F5 | Freelance (proyek, worklog, pajak per proyek, pembayaran) | Ada | 0 |
| F6 | Beranda | Ada | 0 |
| F7 | Kategori bawaan yang bisa diubah | Ada | 0 |
| F8 | Catat pakai suara (STT sistem + parser aturan) | Ada | 0 |
| F9 | Tafsir cerdas Gemini (fallback suara dan notifikasi) | Ada | ≈ US$0,0003 per panggilan |
| F10 | Catat dari notifikasi (Android), tinjau semua dan tingkat otomatis | Ada | 0 (+F9) |
| F11 | Rutin, kemunculan, pengingat, total langganan, kenaikan harga | Ada | 0 |
| F12 | Rencana Bulan ini, uang nganggur, perkiraan +2 bulan | Ada | 0 |
| F13 | Periode keuangan pilihan sendiri | Ada | 0 |
| F14 | Analisis R1 (6 periode, dibanding biasanya, tren) | Ada | 0 |
| F15 | Akun opsional, mata uang, bahasa, mode gelap, sembunyikan nominal | Ada | 0 |
| F16 | Analisis R2 tahun dan tren saldo (B-38); horizon 12 bulan (B-30) | Direncanakan | 0 |
| F16b | Otomasi rutin R3: catat otomatis nominal tetap, belum terlihat, kenaikan harga, rutin menganggur, "sepertinya rutin" | **Ada** (Fase 17), menjadi **Plus** (KT-P11) | 0 |
| F17 | Sinkronisasi antar perangkat (B-7) | Direncanakan, besar | Server |
| F18 | Ekspor/impor, cadangan, kunci aplikasi, widget | **Belum ada** | 0 |
| F19 | Pemindaian struk, asisten AI, laporan tahunan, utang, akun bersama | **Di luar MVP** (PRD §6), kandidat Plus | Gemini untuk yang AI |

Pengamatan: hampir semua yang sudah ada berbiaya nol dan sudah bagus.
Karena itu nilai Plus harus datang dari **fitur baru** (F19 dan §6), bukan
dari mengunci F1–F15.

## 4. Prinsip pembagian

### 4.1 Lima uji, berurutan

1. **Menguncinya membuat versi gratis gagal memenuhi janjinya?** Kalau ya,
   gratis. Janjinya: tahu di mana uangmu, apa yang terjadi, dan ke mana
   direncanakan pergi, dengan hambatan mencatat rendah (prinsip 1–3 dan 5).
2. **Data milik pengguna?** Melihat, mencari, dan membawa pergi datanya
   sendiri selalu gratis.
3. **Keamanan atau aksesibilitas?** Gratis.
4. **Tanuki melakukan pekerjaan yang tidak bisa dilakukan pengguna dengan
   tangan, atau bekerja saat pengguna tidak membuka aplikasi?** Plus.
5. **Menghasilkan jawaban atau dokumen, bukan sekadar angka?** Plus.

### 4.2 Yang tidak dipakai sebagai tuas

Batas jumlah transaksi, batas dompet (dompet adalah proposisi nilai #1 dan
persona memang punya banyak; batas kecil membuat total saldo di Beranda
salah), iklan, dan mengunci data saat Plus berakhir.

### 4.3 Penyetelan ulang versi gratis

Versi gratis yang terlalu murah hati di bagian **otomasi** membuat Plus
kehilangan inti ceritanya. Tiga penyesuaian, semuanya hanya menyentuh
otomasi dan bukan pencatatan:

- **Catat dari notifikasi gratis untuk 1 aplikasi sumber** (misalnya bank
  utama), tetap dengan draf terisi dan tinjau semua. Plus: semua aplikasi,
  tingkat otomatis, pola sendiri. Persona umumnya punya 2–4 aplikasi bank
  dan dompet digital, jadi batas ini terasa tanpa mematahkan fitur
  (KT-P8).
- **Tafsir cerdas gratis 30 per periode** (suara + notifikasi digabung),
  lalu jatuh ke parser aturan tanpa ada yang gagal.
- **Otomasi rutin R3 menjadi Plus** (KT-P11): catat otomatis rutin
  bernominal tetap, belum terlihat, kenaikan harga dari notifikasi, rutin
  menganggur, dan saran "sepertinya rutin". Versi gratis tetap punya rutin
  dasar R1/R2: rutin tanpa batas, pengingat, kartu Menunggu, catat satu
  ketuk, total langganan, dan peringatan kenaikan nominal saat mencatat
  (T-15.6). Deteksi R3 ikut jatah cicip Penjaga (§6.2).

## 5. Pembagian Gratis dan Plus

| Area | Gratis | Plus |
|---|---|---|
| **Mencatat inti** | CATAT lengkap, kalkulator, kategori sendiri, suara dengan parser aturan, Riwayat, Dompet, Beranda, tanpa batas | — (sama) |
| **Anggaran, Rutin, Rencana** | Tanpa batas: anggaran, pos, 1 template, rutin dan pengingat, kartu Menunggu, catat satu ketuk, total langganan, Bulan ini, uang nganggur, perkiraan +2 bulan | Template tanpa batas; **Otomasi rutin R3** (Fase 17): catat otomatis rutin bernominal tetap, label belum terlihat di notifikasi, kenaikan harga dari notifikasi, rutin menganggur, saran "sepertinya rutin" |
| **Analisis** | 6 periode terakhir (seluruh R1) | Riwayat penuh, tren 12 bulan, tampilan tahun, tren saldo |
| **① Tanuki Mencatat** | Notifikasi 1 aplikasi (tinjau semua); 30 tafsir cerdas; **cicip 5 catat dari foto** per periode | **Catat dari foto** (struk, bukti transfer, tangkapan layar QRIS/e-wallet) tanpa kuota; notifikasi semua aplikasi + tingkat otomatis + pola sendiri; rutin tercatat otomatis (R3); tafsir tanpa kuota |
| **② Tanuki Berjaga** | **Cicip 1 peringatan** per periode | **Penjaga**: prediksi anggaran habis, uang nganggur menipis, pengeluaran tak biasa, tagihan besar minggu depan, langganan naik/menganggur; **Ringkasan Senin** |
| **③ Tanya Tanuki** | **Cicip 3 pertanyaan** per periode | Tanya jawab bahasa sehari-hari tentang uangmu sendiri, ketik atau suara |
| **④ Tanuki Merencanakan** | — | **Bagaimana kalau** (simulasi), **Target** dengan perkiraan tanggal tercapai, perkiraan 12 bulan |
| **⑤ Tanuki Melapor** | Rapor bulanan ringkas (angka, bisa dibagikan) | **Rapor bulanan bercerita**, **Rapor Tahunan**, **Rekap SPT tahunan**, ekspor laporan PDF/Excel; Freelance Pro (invoice, status tagihan, penghasilan per klien) |
| **⑥ Tanuki Menyimpan** | Ekspor CSV, cadangkan dan pulihkan manual ke berkas | Cadangan otomatis harian ke Google Drive pengguna; kelak sinkronisasi antar perangkat |
| **Keamanan dan dasar** | Kunci aplikasi, sembunyikan nominal, mode gelap, bahasa, mata uang | — (sama) |
| **Widget** | Widget tombol Catat | Widget ringkasan (sisa anggaran, uang nganggur, Menunggu) |
| **Kosmetik** | Tema bawaan | Tema tambahan, kostum tanuki, ikon aplikasi alternatif, lencana Pendiri |
| **Iklan** | Tidak ada | Tidak ada |

Jatah cicip disimpan di Remote Config (sudah dipakai Fase 20), jadi bisa
disetel tanpa rilis.

## 6. Fitur Plus baru, rinci

Format tiap fitur: apa yang didapat pengguna, kenapa premium, cara kerja
singkat, kepatuhan terhadap aturan proyek, biaya, dan ketergantungan.

### 6.1 Catat dari foto (pilar ①)

- **Yang didapat:** foto struk belanja atau tangkapan layar bukti transfer,
  QRIS, atau e-wallet → CATAT terbuka terisi (nominal, tanggal, toko sebagai
  catatan, kategori ditebak, dompet dari pola tangkapan layar). Bisa dibuka
  dari tombol Catat, dari lembar bagi Android ("Bagikan ke Tanukonomy"), dan
  dari galeri.
- **Kenapa premium:** di Indonesia bukti transfer dan QRIS adalah kejadian
  harian, dan aplikasi pencatat manual hampir tidak ada yang menanganinya
  dengan baik. Ini menghapus pekerjaan yang paling malas dilakukan:
  menyalin angka dari layar lain.
- **Cara kerja:** gambar dikirim ke Gemini (multimodal) lewat Firebase AI
  Logic yang sudah ada, keluarannya masuk ke penyusun draf `shared/capture/`
  yang sama dengan suara. Resolver tetap hanya memilih dompet dan kategori
  yang ada; bagian ragu dikosongkan.
- **Aturan:** draf **selalu membuka CATAT** (aturan 8). Pengguna diberi tahu
  sekali bahwa gambar dikirim untuk dibaca dan tidak disimpan (NFR-SEC-001);
  gambar tidak disimpan di perangkat sesudah draf jadi.
- **Biaya:** ≈ US$0,0015 per foto [E dari harga `gemini-3.5-flash-lite`
  di VOICE_INPUT_RESEARCH §9: ~2.000 token masuk, ~300 keluar].
- **Ketergantungan:** kecil, karena interpreter, resolver, dan draf sudah
  ada. Struk berisi banyak barang cukup dibaca totalnya di R1; rincian
  per barang dan patungan menyusul (§7).

### 6.2 Penjaga dan Ringkasan Senin (pilar ②)

- **Yang didapat:** notifikasi lokal hanya saat ada yang layak diketahui,
  dengan nada netral katalog wawasan RECURRING_AND_FORECAST §7B:
  - "Dengan laju sekarang, anggaran Makan habis sekitar 22 Okt, 9 hari
    sebelum periode berakhir."
  - "Uang nganggur diperkirakan minus Rp350.000 di pekan terakhir periode
    ini, sesudah cicilan dan listrik."
  - "Pengeluaran Transportasi pekan ini 3× biasanya."
  - "Pekan depan ada 3 tagihan rutin, total Rp2,1 jt."
  - Deteksi R3 (kenaikan harga dari notifikasi, rutin menganggur, belum
    terlihat, "sepertinya rutin"), yang di Plus tampil di segmen Rutin dan
    juga dikirim sebagai notifikasi. Di versi gratis, satu deteksi R3 boleh
    menjadi "Contoh Penjaga" periode itu.
  - **Ringkasan Senin:** satu notifikasi tiap Senin pagi berisi pekan lalu
    (masuk, keluar, kategori teratas) dan pekan ini (tagihan, sisa
    anggaran).
- **Kenapa premium:** versi gratis menunggu dibuka; Penjaga **datang lebih
  dulu**, sebelum anggaran jebol, bukan sesudahnya. Ini rasa "ada yang
  mengawasi untukku" yang tidak bisa ditiru dengan membuka aplikasi lebih
  sering.
- **Cara kerja:** dihitung **di perangkat** dari data yang sudah ada
  (`monthPlan`, `projectCashflow`, Analisis, rutin), dijadwalkan dengan
  `flutter_local_notifications` yang sudah dipakai. Batas: maksimal satu
  peringatan per hari dan bisa diatur per jenis.
- **Aturan:** tanpa skor, tanpa streak, tanpa menghakimi (KT-R13, nada §7B).
- **Biaya:** 0. Tanpa jaringan.
- **Cicip gratis:** satu peringatan per periode, diberi label "Contoh
  Penjaga", supaya pengguna gratis tahu apa yang mereka lewatkan.

### 6.3 Tanya Tanuki (pilar ③)

- **Yang didapat:** kotak tanya (atau suara, tekan lama tombol Catat) untuk
  pertanyaan sehari-hari:
  - "Berapa habis buat kopi 3 bulan terakhir?"
  - "Bulan ini aku lebih boros di mana dibanding biasanya?"
  - "Kalau beli HP 5 juta tanggal 1, uang nganggurku cukup sampai gajian?"
  - "Klien mana yang paling lama bayarnya?"

  Jawaban berupa kalimat pendek, angka, dan tautan ke layar yang
  membuktikannya (Analisis tersaring, Rencana, rincian proyek).
- **Kenapa premium:** mengubah data yang dicatat berbulan-bulan menjadi
  jawaban dalam satu kalimat. Ini "asisten keuangan berbasis AI" di PRD §6,
  dibangun di atas prinsip proyek.
- **Cara kerja, prinsip "Tanuki tidak pernah menghitung":** Gemini hanya
  **menerjemahkan pertanyaan** menjadi kueri terstruktur (jenis, kategori,
  dompet, periode, kata kunci catatan, atau skenario). Kueri divalidasi
  resolver seperti draf CATAT, lalu **angkanya dihitung di perangkat**
  dengan fungsi domain yang sudah teruji, dan kalimat jawabannya disusun
  dari templat lokal. Pertanyaan yang tidak bisa dipetakan dijawab jujur
  ("Aku belum bisa menjawab itu") dengan saran pertanyaan yang bisa.
  Akibatnya: angka selalu tepat (aturan 1 dan preferensi "ketepatan angka"),
  dan yang dikirim ke Gemini hanya **teks pertanyaan dan daftar nama
  kategori/dompet**, tanpa nominal atau transaksi.
- **Aturan:** hanya tentang data pengguna sendiri. Tidak memberi saran
  produk investasi atau pinjaman.
- **Biaya:** ≈ US$0,001 per pertanyaan [E: ~1.500 token masuk, ~200
  keluar]. Batas wajar 300 per bulan.
- **Ketergantungan:** sedang. Butuh katalog kueri yang didukung (mulai
  dari 10–15 bentuk pertanyaan paling umum) dan uji pemetaannya.

### 6.4 Bagaimana kalau, dan Target (pilar ④)

- **Bagaimana kalau:** pengguna menambah kejadian khayalan ke perkiraan
  ("cicilan motor Rp1,2 jt × 24 mulai Des", "beli laptop Rp12 jt Feb",
  "gaji naik 10% Jan", "berhenti kerja Mar") dan melihat uang nganggur
  12 bulan ke depan **dengan dan tanpa** skenario itu, berdampingan.
  Skenario bisa disimpan, dibandingkan, dan dibuang. Tidak pernah menjadi
  transaksi atau rutin sungguhan kecuali pengguna memilih "Jadikan rutin".
- **Target:** "Dana darurat Rp15 jt", "Liburan Rp6 jt Juni". Aplikasi
  memperkirakan tanggal tercapai dari uang nganggur rata-rata, dan
  memberi tahu bila meleset. Target adalah **rencana**, bukan pemesanan
  uang (sejalan aturan 5): tidak mengubah saldo dompet mana pun; kemajuan
  dibaca dari saldo dompet yang ditandai untuk target itu atau dari
  pencatatan sisihkan yang berupa transfer.
- **Kenapa premium:** keputusan besar (cicilan, resign, beli barang mahal)
  adalah saat orang paling butuh kepastian dan paling mau membayar.
- **Cara kerja:** di atas `projectCashflow` yang sudah ada (ADR-035/036).
  Target butuh entitas baru → ADR (Target tidak ada sejak pivot; 1.0 punya
  `shared/goal` yang sudah dihapus). **Masuk produk (KT-P10)**, B-47.
- **Biaya:** 0.

### 6.5 Rapor, Rekap SPT, dan Freelance Pro (pilar ⑤)

- **Rapor bulanan bercerita:** di akhir tiap periode, Tanuki menyusun satu
  halaman: tiga hal yang menonjol, perbandingan dengan biasanya, rutin yang
  berubah, kemajuan target. Kalimat dari templat lokal (tanpa mengirim
  data). Versi gratis: kartu angka ringkas.
- **Rapor Tahunan ("Tahun Tanuki-mu"):** rangkuman setahun dalam kartu
  geser bergaya piksel yang bisa dibagikan tanpa nominal (persentase dan
  peringkat saja), tayang Desember. Kartu yang dibagikan membawa nama
  aplikasi, jadi ini juga saluran pertumbuhan.
- **Rekap SPT tahunan:** satu dokumen (PDF + CSV) yang membantu mengisi SPT
  orang pribadi: penghasilan per sumber (gaji dan freelance per klien,
  beserta potongan pajak per proyek yang sudah tercatat), saldo tiap dompet
  di 31 Desember sebagai daftar harta kas, dan utang tercatat (bila §7
  utang-piutang sudah ada). Tayang Januari, sebelum batas lapor SPT orang
  pribadi 31 Maret. Ini **rekap catatan**, bukan pelaporan pajak, dan
  aplikasi tidak menghitung pajak terutang.
- **Freelance Pro:** buat invoice PDF dari worklog (nama klien, jam, tarif,
  pajak) dan bagikan lewat lembar bagi; status tagihan *terkirim*, *jatuh
  tempo*, *lewat jatuh tempo* (menjawab pertanyaan terbuka PRD §13 tentang
  status ketiga dan ikon `icon_freelance_overdue_payment` yang sudah ada);
  pengingat tagih; penghasilan per klien dan tarif efektif per jam.
  Pembayaran tetap dicatat lewat CATAT (aturan 6 dan 8): invoice adalah
  dokumen, tidak menyentuh saldo.
- **Ekspor laporan PDF/Excel** dari Analisis periode atau tahun mana pun.
- **Kenapa premium:** menghasilkan dokumen yang langsung dipakai di luar
  aplikasi. Pekerja lepas punya alasan bisnis untuk membayar.
- **Biaya:** 0.

### 6.6 Cadangan otomatis (pilar ⑥)

Cadangan harian terenkripsi ke folder data aplikasi di Google Drive milik
pengguna (bukan server Tanukonomy), dengan pemulihan saat pasang ulang atau
ganti ponsel. Pemulihan mengikuti ADR-024 §3.3 (data diganti dengan
peringatan, tanpa penggabungan). Biaya server 0. Sinkronisasi sungguhan
antar perangkat (B-7) menyusul di §7.

## 7. Fitur mendatang untuk Plus

Diurutkan menurut nilai bagi pengguna Plus dibanding usahanya. "Gratis
dasar" berarti bagian dasarnya masuk versi gratis supaya janji produk
tetap utuh.

| Fitur | Untuk siapa | Pembagian | Usaha | Catatan |
|---|---|---|---|---|
| **Utang-piutang** ("Teman pinjam Rp500rb", kasbon, paylater) | Semua | Gratis dasar (catat dan lihat), Plus: pengingat tagih dengan pesan siap kirim, jadwal cicilan dan sisa pokok | L | **Masuk produk (KT-P10)**, B-48. Butuh ADR domain: piutang bukan saldo dompet. Cocok dengan maskot yang membawa buku utang-piutang (ONBOARDING_ART_BRIEF) |
| **Patungan dari struk** | Anak muda, kantor | Plus | M | Sesudah catat dari foto dan utang-piutang: pilih barang per orang → piutang tercatat |
| **Dompet Bersama / Plus Keluarga** | Pasangan, keluarga kecil | Tingkat kedua "Plus Keluarga" (2–5 orang) | L | Butuh sinkronisasi (B-7). Persona PRD memang menyebut keluarga kecil |
| **Sinkronisasi antar perangkat** | Semua | Plus | L | B-7, ADR sendiri, wajib ADR-024 §3.3 |
| **Kartu kredit dan paylater sebagai dompet tagihan** (jatuh tempo, tagihan berjalan) | Pemakai kartu | Gratis dasar, Plus: peringatan jatuh tempo masuk Penjaga | M | Di luar MVP (PRD §6), model sudah menampung |
| **Kekayaan bersih** (aset manual: emas, reksa dana, kendaraan; dikurangi utang) | Profesional muda | Plus | M | Nilai dicatat manual, bukan tersambung ke broker (tetap "mencatat") |
| **Tanya Tanuki R2**: kueri gabungan dan perbandingan antar tahun | Pengguna lama | Plus | M | Sesudah R1 terukur |
| **Rapor kuartal untuk freelance** (penghasilan, klien, jam) | Pekerja lepas | Plus | S | Dari data Freelance Pro |
| **Catat dari email** (struk e-commerce, tagihan) | Semua | Plus | L | Izin Gmail sensitif, kebijakan Google ketat; dipertimbangkan paling akhir |
| **Gemma lokal** (B-15) untuk tafsir tanpa internet | Peduli privasi | Plus | L | Menurunkan biaya Gemini dan menjadi nilai jual privasi |

Yang sengaja tidak masuk: sinkronisasi bank dan pembayaran (bertentangan
dengan definisi produk), saran investasi, skor kredit, dan gamifikasi
streak (KT-R13).

## 8. Uji coba terbalik sampai akhir periode keuangan, dengan momen terjadwal

Semua pengguna baru mendapat Plus tanpa kartu **sampai akhir periode
keuangan pertamanya yang penuh** (KT-P2, diputuskan 18 Okt 2026), supaya
uji coba mengikuti satu siklus gajian utuh: gajian masuk, tagihan rutin
jatuh tempo, anggaran berjalan sampai habis periode.

### 8.1 Aturan panjang uji coba

- Uji coba berakhir di **hari terakhir periode keuangan yang sedang
  berjalan** bila sisa periode itu **minimal 14 hari**; bila kurang, di hari
  terakhir **periode berikutnya**. Panjangnya 14 sampai sekitar 45 hari.
  Contoh, periode mulai tanggal 25: pasang 1 Nov → berakhir 24 Nov (24
  hari); pasang 15 Nov → berakhir 24 Des (40 hari).
- Periode memakai `financialPeriodOf` (ADR-038). Bila pengguna belum
  memilih tanggal mulai periode, dipakai bawaan aplikasi; onboarding dan
  layar hadiah menawarkan "Kapan kamu gajian?" lebih dulu, supaya uji coba
  langsung mengikuti siklus yang benar.
- **Tanggal berakhir dihitung sekali saat uji coba mulai dan disimpan.**
  Mengubah periode keuangan sesudahnya (termasuk periode peralihan 13–46
  hari) tidak memajukan atau memundurkan uji coba.
- Layar hadiah menyebut tanggalnya, bukan jumlah hari: "Plus aktif sampai
  24 Nov, akhir periode pertamamu."

### 8.2 Momen terjadwal

Supaya akhir uji coba terasa sebagai kehilangan nyata, setiap pilar harus
**benar-benar terjadi** di dalamnya, bukan hanya tersedia. Hari dihitung
dari awal uji coba; "H-n" dihitung mundur dari hari berakhir.

| Kapan | Momen | Pilar |
|---|---|---|
| Hari 0 (akhir onboarding) | Layar hadiah dengan tanggal berakhir. Ajakan pertama: "Coba foto struk atau bukti transfer terakhirmu." | ① |
| Hari 0–2 | Bila catat notifikasi diaktifkan: semua aplikasi sumber dan tawaran tingkat otomatis sesudah 3 tinjauan; rutin bernominal tetap ditawari Catat otomatis | ① |
| Hari 2–4 | Kartu Beranda dengan tiga contoh pertanyaan dari kategori yang sudah dipakai: "Tanya Tanuki: berapa habis buat Makan pekan ini?" | ③ |
| Hari 3–7 | Peringatan Penjaga pertama begitu ada sinyal nyata (anggaran, tagihan pekan depan, deteksi R3) | ② |
| Tiap Senin | Ringkasan Senin (2–6 kali selama uji coba) | ② |
| Hari 5–10 | Ajakan "Bagaimana kalau" saat membuka perkiraan di Rencana, atau membuat Target | ④ |
| Tagihan rutin pertama yang jatuh tempo | Tercatat otomatis bila disetel; muncul di daftar Tercatat otomatis | ① |
| **H-3** | **Rekap nilai:** "Sejak 1 Nov: 14 catatan dari foto dan notifikasi, 3 tagihan rutin tercatat sendiri, 4 peringatan Penjaga, 6 pertanyaan terjawab." Angka dari pemakaian lokal | semua |
| **Hari pertama periode berikutnya** | **Rapor bulanan bercerita** untuk periode uji coba (sesudah B-49 ada), dibuka sebagai momen Plus terakhir; sesudah ditutup, **layar turun ke Gratis**: yang tetap, yang berubah (dengan angka pemakaiannya), dan tawaran **Harga Pendiri** 48 jam. "Lanjut dengan Gratis" sama jelasnya | ⑤ |

Plus tetap aktif sampai rapor periode itu dibuka atau paling lama 1 hari
sesudah periode berakhir, supaya rapor pertama tidak terpotong. Sebelum
B-49 tersedia, layar turun tampil di hari pertama periode berikutnya tanpa
rapor.

Momen yang tidak pernah terjadi (misalnya Penjaga diam karena data belum
cukup) tidak disebut di rekap. Rekap hanya memuat yang benar-benar
dikerjakan Tanuki.

### 8.3 Kenapa model ini

- **Reverse trial:** uji coba Play Billing butuh metode bayar dan
  berlangganan otomatis, hambatan bagi aplikasi baru. Menurut ringkasan
  laporan RevenueCat 2026, median konversi uji coba ke berbayar hari ke-35
  adalah 10,7% untuk aplikasi yang wajib bayar di depan dan 2,1% untuk
  freemium. Reverse trial mencoba mengambil sebagian keunggulan pertama
  (pengguna merasakan produk penuh) tanpa menutup pintu masuk.
- **Sampai akhir periode:** nilai aplikasi keuangan terasa per siklus
  gajian. Uji coba yang berhenti di tengah periode memotong momen paling
  kuat (tagihan tercatat sendiri, anggaran yang diselamatkan Penjaga, rapor
  periode). Ringkasan pihak kedua atas data RevenueCat juga menyebut uji
  coba 17–32 hari berkonversi lebih baik daripada uji coba di bawah 4 hari;
  anggap sebagai arah.
- **Biaya panjang yang berbeda-beda:** perbandingan konversi harus dibaca
  per panjang uji coba (peristiwa `trial_started{days}`), bukan rata-rata
  saja.

Penyalahgunaan (pasang ulang untuk mengulang uji coba): diterima untuk
skala sekarang; bila berarti, kaitkan ke akun atau Play Integrity.

## 9. Paywall kontekstual

Aturan umum: paywall hanya muncul **sesudah** pengguna berhasil melakukan
sesuatu, tidak pernah di tengah CATAT; maksimal sekali sehari dan tiga kali
per periode; sesudah tiga kali "Nanti saja" pada pemicu yang sama, pemicu
itu diam 30 hari; selalu memakai angka milik pengguna; nada mengikuti
`docs/03-design/design-system/writing.md`.

| # | Pemicu | Contoh kalimat | Pilar |
|---|---|---|---|
| P1 | Jatah cicip catat dari foto habis | "5 foto bulan ini sudah jadi catatan. Dengan Plus, foto berapa pun." | ① |
| P2 | Memilih aplikasi sumber notifikasi kedua | "Bank utamamu sudah tercatat dari notifikasi. Tambah GoPay dan aplikasi lain dengan Plus." | ① |
| P3 | Sesudah "Contoh Penjaga" bulanan | "Peringatan ini datang 9 hari sebelum anggaran Makan habis. Plus memberi tahu tiap kali ada yang seperti ini." | ② |
| P4 | Jatah Tanya Tanuki habis, atau pertanyaan ke-4 diketik | Pertanyaannya tetap tersimpan: "Simpan pertanyaan ini dan jawab sekarang dengan Plus." | ③ |
| P5 | Membuka perkiraan Rencana dan menggeser melewati +2 bulan | "Lihat 12 bulan ke depan, dan coba bagaimana kalau ada cicilan baru." | ④ |
| P6 | Akhir periode: rapor ringkas tampil | Rapor bercerita di belakangnya diburamkan, memakai data asli | ⑤ |
| P7 | Proyek freelance: pembayaran sudah lewat 14 hari dari worklog terakhir | "Klien A belum membayar 21 hari. Buat invoice dan pantau jatuh temponya dengan Plus." | ⑤ |
| P8 | 30 hari atau 200 transaksi tanpa cadangan | "200 catatanmu hanya ada di ponsel ini. Cadangkan sekarang (gratis), atau biarkan Plus mencadangkan tiap hari." | ⑥ |
| P9 | Desember dan Januari | "Tahun Tanuki-mu sudah siap" dan "Rekap SPT 2026-mu sudah bisa disusun" | ⑤ |
| P10 | Layar Akun | Baris tetap "Tanukonomy Plus" | — |

Isi layar paywall: judul sesuai pemicu, enam pilar dengan pilar pemicu di
atas, Tahunan terpilih bawaan ("setara Rp14.900/bulan"), Bulanan di
bawahnya, "Pulihkan pembelian", dan kalimat "Semua catatanmu tetap milikmu,
berlangganan atau tidak."

## 10. Saat Plus berakhir

Prinsip: tidak ada data yang dikunci atau dihapus, tidak ada pencatatan
yang terhalang. "Yang sudah ada tetap ada; pekerjaan baru oleh Tanuki
berhenti."

| Fitur | Sesudah turun |
|---|---|
| Notifikasi semua aplikasi, tingkat otomatis | Kembali ke 1 aplikasi pilihan pengguna dan tinjau semua; transaksi yang sudah tercatat tetap ada; pola buatan sendiri tetap dipakai |
| Catat dari foto, Tanya Tanuki, Penjaga | Kembali ke jatah cicip |
| Skenario dan Target | Tetap bisa dilihat; tidak diperbarui dan tidak bisa dibuat yang baru |
| Rapor, Rekap SPT, invoice yang sudah dibuat | Tetap bisa dibuka dan dibagikan |
| Status tagihan freelance | Tetap tampil; pembayaran tetap dicatat lewat CATAT |
| Analisis di luar 6 periode | Tampilannya terkunci; Riwayat tetap penuh |
| Cadangan otomatis | Berhenti; cadangan lama tetap bisa dipulihkan; cadangan manual tersedia |
| Otomasi rutin R3 | Rutin yang disetel Catat otomatis kembali menunggu konfirmasi satu ketuk (setelannya disimpan untuk bila berlangganan lagi); transaksi yang sudah tercatat otomatis tetap ada dan daftar Tercatat otomatis tetap bisa dibuka; label belum terlihat, kenaikan harga dari notifikasi, rutin menganggur, dan saran rutin berhenti tampil |
| Kosmetik | Kembali ke bawaan; pilihan disimpan |

## 11. Harga

### 11.1 Acuan pesaing (toko luar negeri; harga Indonesia perlu dicek di Play Store)

| Aplikasi | Model | Harga |
|---|---|---|
| Spendee | Gratis 1 dompet + 1 anggaran; Plus; Premium (sinkron bank) | Plus US$1,99/bln atau US$14,99/thn; Premium US$5,99/bln atau US$35,99/thn |
| Wallet (BudgetBakers) | Gratis terbatas; Premium | Sekitar US$4,49/bln, US$26,99/thn (sumber berbeda-beda) |
| Money Lover | Gratis terbatas + iklan; Premium seumur hidup | US$19,99 seumur hidup (toko AS) |
| YNAB | Berbayar penuh | US$109/thn |
| Monarch | Berbayar penuh | US$99,99/thn (Core) |

Pencatat manual di pasar berkembang berada di kisaran US$15–27/tahun. Plus
revisi 2 membawa pekerjaan yang biasanya hanya ada di aplikasi berharga
lebih tinggi (asisten, perkiraan skenario, pemindaian), sehingga layak
sedikit di atas kisaran itu.

### 11.2 Usulan

| Paket | Harga | Catatan |
|---|---|---|
| Bulanan | **Rp25.000** | |
| Tahunan | **Rp179.000** (≈ Rp14.900/bln, hemat 40%) | Terpilih bawaan |
| Harga Pendiri | **Rp129.000/tahun**, terkunci selama tetap berlangganan | Untuk pembeli 90 hari pertama sesudah rilis publik, dan penawaran 48 jam sesudah uji coba berakhir. Mengganti paket seumur hidup |
| Penguji closed testing | Plus gratis 12 bulan, lalu Harga Pendiri | Terima kasih, dan sumber ulasan pertama (KT-P5) |

**Tanpa paket seumur hidup:** pilar ①③ memakai Gemini, jadi pembeli seumur
hidup akan menjadi biaya tanpa batas waktu. Harga Pendiri yang terkunci
memberi rasa "untung karena datang lebih awal" tanpa risiko itu.

### 11.3 Biaya per pengguna Plus

Perkiraan [E] dari harga `gemini-3.5-flash-lite` (US$0,30 per 1 juta token
masuk, US$2,50 per 1 juta keluar, VOICE_INPUT_RESEARCH §9):

| Pemakaian bulanan | Pemakai biasa | Pemakai berat (batas wajar) |
|---|---|---|
| Tafsir cerdas | 40 × US$0,0003 | 1.000 × US$0,0003 |
| Catat dari foto | 20 × US$0,0015 | 150 × US$0,0015 |
| Tanya Tanuki | 15 × US$0,001 | 300 × US$0,001 |
| **Total** | **≈ US$0,06** | **≈ US$0,8** |

Pendapatan bersih Tahunan sesudah biaya layanan Play 15%: Rp179.000 × 0,85
÷ 12 ≈ Rp12.700/bulan; Harga Pendiri ≈ Rp9.100/bulan. Pemakai biasa jauh
aman. Pemakai berat (≈ US$0,8 ≈ Rp13.000 pada kurs ±Rp16.500) **melebihi**
pendapatan bersih Harga Pendiri dan hampir menyamai Tahunan, karena itu
batas wajar perlu ada (tidak ditampilkan kecuali tersentuh) dan biaya
nyata per pengguna diukur sejak peluncuran Plus (C4). Penjaga,
skenario, rapor, dan cadangan Drive berbiaya 0.

## 12. Mekanisme teknis (garis besar untuk ADR)

### 12.1 Prasyarat gratis

Ekspor CSV dan cadangkan/pulihkan manual ke berkas, serta kunci aplikasi,
dikerjakan **sebelum** paywall pertama. Tidak etis memungut bayaran dari
aplikasi yang datanya belum bisa dibawa pergi.

### 12.2 Pembelian dan hak

- Google Play Billing lewat **RevenueCat** (`purchases_flutter`), usulan
  utama: verifikasi kuitansi di server tanpa backend sendiri, ID anonim
  cocok dengan akun opsional, siap iOS. Alternatif `in_app_purchase` +
  Cloud Functions (butuh Blaze, T-11.8). KT-P6.
- Data ke penyedia billing dicatat di `docs/03-release/PLAY_DATA_SAFETY.md`.

### 12.3 Struktur kode (ADR-030)

- `core/foundation/entitlement/`: port `Entitlements` (aliran `PlanState`:
  gratis, uji coba sampai X, Plus sampai Y), enum `PlusFeature`, jatah cicip
  dan batas dari Remote Config dengan nilai bawaan lokal. `core` tidak
  mengimpor fitur.
- `features/premium/`: paywall, layar hadiah uji coba, rekap nilai, layar
  turun, adaptor billing; dibuka lewat `PremiumRouteKeys.paywall` dengan
  `PaywallTrigger`.
- Fitur Plus baru di tempatnya masing-masing: catat dari foto di
  `features/photo_capture/` (pola sama dengan `voice_capture`, berlanjut ke
  `RecordRouteKeys.sheet`); Penjaga di `features/guardian/` membaca port
  rencana dan analisis; Tanya Tanuki di `features/ask/` dengan pemeta kueri
  di `shared/capture/` (interpreter yang sama, keluaran berbeda).
- Hak diperiksa di presentasi atau use case otomasi, **tidak pernah** di
  `RecordTransaction`. Pencatatan manual tidak punya cabang hak.
- Luring: hak terakhir disimpan lokal dengan tanggal berakhir, tenggang
  3 hari. Tanpa koneksi, pengguna Plus tetap Plus (NFR-REL-001); fitur yang
  butuh Gemini memberi tahu bahwa ia butuh internet, seperti suara.
- `test/architecture/import_boundaries_test.dart` diperluas untuk modul
  baru.

### 12.4 Privasi fitur AI

| Fitur | Yang dikirim ke Gemini | Yang tidak pernah dikirim |
|---|---|---|
| Tafsir cerdas (ada) | Teks ucapan atau notifikasi yang disamarkan | Saldo, nomor rekening |
| Catat dari foto | Gambar yang dipilih pengguna | Riwayat, saldo |
| Tanya Tanuki | Teks pertanyaan, nama kategori dan dompet | Nominal, transaksi, catatan |
| Rapor, Penjaga, skenario | Tidak ada (lokal) | — |

Semua fitur yang mengirim memberi tahu sekali saat pertama dipakai dan
dicatat di kebijakan privasi situs (B-20).

### 12.5 Pengukuran

Peristiwa Analytics: `trial_started`, `trial_moment{pillar}`,
`trial_value_recap_shown`, `trial_ended{outcome}`,
`paywall_viewed{trigger}`, `paywall_dismissed{trigger}`,
`purchase_completed{plan}`, `plus_feature_used{feature}`,
`taste_quota_exhausted{feature}`.

| Ukuran | Target awal (hipotesis) |
|---|---|
| Pengguna uji coba yang mengalami ≥3 dari 6 pilar | ≥ 50% |
| Uji coba → berbayar dalam 30 hari | 5–8% |
| Konversi per pemasang hari ke-60 | 3–5% (median freemium 2,1%, ringkasan RevenueCat 2026) |
| Porsi Tahunan dari pembelian | ≥ 60% |
| Pilar yang paling sering dipakai pembeli 30 hari sebelum membeli | Diukur, untuk menentukan urutan pilar di paywall |
| Retensi D30 versi gratis | Turun ≤ 2 poin dibanding sebelum paywall |

"Pilar yang dialami" adalah ukuran terdepan: bila pengguna yang mengalami
≥3 pilar jauh lebih sering membeli, prioritas berikutnya adalah membuat
momen §8 lebih sering terjadi, bukan menambah fitur.

## 13. Peta kerja Plus dan urutannya (jawaban KT-P9)

Disetujui pemilik 18 Okt 2026 (KT-P9). Butir `B-n` ada di antrean TASK_LIST
dan di [ROADMAP](../../04-planning/ROADMAP.md) bagian "Jalur Plus". Ukuran
usaha: **S** muat 1–2 sesi agen, **M** satu fase kecil (3–6 tugas), **L**
satu fase penuh dengan ADR.

### 13.1 Kriteria urutan

1. **Kepercayaan sebelum menagih.** Data harus bisa dibawa pergi dan
   dikunci sebelum ada tombol bayar.
2. **Plus baru dijual setelah layak.** Paywall tidak tayang hanya dengan
   gerbang fitur lama; itu persis kelemahan revisi 1. Minimal tiga pilar
   harus terasa selama uji coba.
3. **Mesin yang sudah ada lebih dulu.** Fitur yang memakai ulang
   `projectCashflow`, Analisis, rutin, pengingat lokal, dan `shared/capture`
   berisiko rendah dan cepat.
4. **Biaya nol dan tanpa data keluar lebih dulu.** Fitur lokal tidak perlu
   mengubah Keamanan Data, kebijakan privasi, atau menunggu Blaze.
5. **Aturan uang yang baru butuh ADR dulu.** Target dan utang-piutang
   menyentuh invarian saldo (aturan 5 dan 7), jadi didokumentasikan sebelum
   kode, sesudah Plus berjalan.
6. **Fitur AI yang paling berisiko mutu paling akhir di antara pilar.**
7. **Tanggal musiman tidak bisa digeser.** Rapor Tahunan butuh setahun
   data; bagi hampir semua pengguna, tahun penuh pertama adalah 2027, jadi
   sasarannya Desember 2027 dan Januari 2028, bukan 2026.

### 13.2 Daftar kerja berurutan

| Urut | Butir | Isi | Memakai ulang | Baru | Usaha | Kenapa di sini |
|---|---|---|---|---|---|---|
| **A. Kepercayaan (gratis)** | | | | | | |
| A1 | B-42 | Ekspor CSV; cadangkan dan pulihkan manual ke berkas | Repositori Hive (`hive_storage`), lembar bagi Android | Format cadangan berversi, pemulihan sesuai ADR-024 §3.3 | M | Prasyarat etis paywall, dan sekaligus menghapus risiko terbesar pengguna hari ini (data hilang bersama ponsel). Juga dasar A1→E3 (cadangan otomatis memakai format yang sama) |
| A2 | B-43 | Kunci aplikasi (sidik jari/PIN) | Akun, preferensi | `local_auth` | S | Gratis dan kecil; dicari pengguna aplikasi keuangan sebelum mereka mau memasukkan data |
| **B. Fondasi Plus** | | | | | | |
| B1 | B-41 | ADR monetisasi; billing (RevenueCat), `Entitlements`, layar paywall, jatah dari Remote Config, peristiwa Analytics | Remote Config, Analytics, kunci rute | `features/premium/`, `core/foundation/entitlement/` | M | Semua pilar butuh tempat untuk memeriksa hak dan menghitung jatah cicip. Dibangun dulu, **belum dijual**: Plus dinyalakan hanya untuk penguji |
| B2 | B-41, B-30 | Gerbang fitur yang sudah ada: notifikasi 1 aplikasi, kuota tafsir 30, Analisis > 6 periode, template ke-2, proyek freelance ke-3, otomasi rutin R3 (KT-P11); perkiraan 12 bulan | Semua sudah ada | Hanya pemeriksaan hak | S | Murah, dan memberi data pertama berapa sering batas tersentuh |
| **C. Tiga pilar pertama → peluncuran Plus** | | | | | | |
| C1 | B-44 | **Penjaga + Ringkasan Senin** (②) | `monthPlan`, `projectCashflow`, Analisis, deteksi R3 Fase 17, `flutter_local_notifications` | Mesin aturan peringatan, penjadwal, setelan per jenis | M | **Dibangun pertama.** Biaya 0, tanpa data keluar, mesin sudah ada, dan paling langsung terasa "Tanuki bekerja untukku". Cicip gratisnya juga menaikkan retensi pengguna gratis, ukuran keberhasilan utama PRD §3. Pertanyaan ADR: hitung di latar (`workmanager`) atau dijadwalkan saat aplikasi dibuka |
| C2 | B-45 | **Catat dari foto** (①) | Interpreter Gemini, resolver, penyusun draf `shared/capture/`, `RecordRouteKeys.sheet` | Sumber bukti gambar, pemilih gambar, terima bagi dari aplikasi lain, prompt multimodal | M | Kedua. Momen ajaib hari 0 uji coba dan dipakai tiap hari. Ditaruh sesudah C1 karena butuh Blaze (T-11.8) dan pembaruan Keamanan Data/kebijakan privasi |
| C3 | B-46 | **Bagaimana kalau** (④) | `projectCashflow`, horizon 12 bulan dari B2 | Kejadian khayalan, simpan dan bandingkan skenario | M | Ketiga. Biaya 0; menjawab momen keputusan besar (cicilan, resign) yang paling mudah dijual. Melengkapi syarat "tiga pilar terasa" |
| C4 | B-41 | Reverse trial, momen terjadwal, rekap nilai, layar turun, pemicu paywall P1–P5 dan P8 | Tur spotlight (ADR-021), Analytics | Penjadwal momen, rekap pemakaian lokal | S–M | **Peluncuran Plus (M1).** Ditaruh terakhir supaya rekap hari ke-11 punya isi nyata dari C1–C3 |
| **D. Domain baru (KT-P10)** | | | | | | |
| D1 | B-47 | ADR + **Target** (④): entitas, perkiraan tanggal tercapai, kemajuan dari dompet yang ditandai atau transfer sisihkan, peringatan meleset lewat Penjaga | `projectCashflow`, Penjaga, Rencana | Entitas `Goal`, layar Target, hubungan ke dompet | M–L | Sesudah peluncuran karena menyentuh aturan 5 (rencana, bukan pemesanan uang) dan butuh ADR. Memperkuat pilar ④ dan memberi Penjaga sinyal baru |
| D2 | B-48 | ADR + **Utang-piutang**: dasar gratis (catat pinjam/pinjamkan, sisa, lunas), Plus: pengingat tagih dengan pesan siap kirim, jadwal cicilan | CATAT, dompet, pengingat lokal | Entitas utang/piutang, aturan saldo dan Analisis | L | Paling dalam menyentuh buku besar: meminjamkan uang mengurangi saldo dompet tapi **bukan pengeluaran**, dibayar kembali menambah saldo tapi **bukan pemasukan** (sejalan aturan 7). Bagian dasarnya memperbaiki versi gratis; prasyarat patungan (G1) dan bagian utang Rekap SPT (F2) |
| **E. Melengkapi pilar ③⑤⑥** | | | | | | |
| E1 | B-49 | **Rapor bulanan bercerita** + ekspor laporan PDF/Excel (⑤) | Analisis R1, katalog wawasan §7B | Templat kalimat, pembuat PDF (`pdf`) | M | Biaya 0; membangun mesin PDF yang dipakai E2, F1, F2 |
| E2 | B-50 | **Freelance Pro** (⑤): invoice PDF dari worklog, status jatuh tempo dan lewat jatuh tempo, pengingat tagih, penghasilan per klien | Freelance, ADR-019, PDF dari E1 | Tanggal jatuh tempo, status ketiga | M | Segmen yang paling mudah membenarkan harga; menjawab pertanyaan terbuka PRD §13 tentang status lewat jatuh tempo |
| E3 | B-51 | **Cadangan otomatis Google Drive** (⑥) | Format cadangan A1, Google Sign-In (ADR-023) | Lingkup Drive folder data aplikasi, penjadwal harian | M | Pilar ketenangan yang paling mudah dijual saat orang ganti ponsel. Sesudah A1 karena formatnya sama. Klasifikasi lingkup OAuth Drive perlu dicek di verifikasi Google |
| E4 | B-52 | **Tanya Tanuki R1** (③) | Interpreter Gemini, resolver, Analisis, Rencana, Target, utang-piutang | Katalog 10–15 bentuk kueri, pemeta pertanyaan ke kueri, templat jawaban | L | Terakhir di antara pilar karena paling berisiko mutu dan paling bernilai bila sudah bisa menjawab tentang Target dan utang (D1–D2). Saat ini dijual lewat cicip dulu |
| **F. Musim laporan (sasaran Des 2027 – Mar 2028)** | | | | | | |
| F1 | B-53 | **Rapor Tahunan** (⑤), kartu geser yang bisa dibagikan tanpa nominal | Analisis, mesin rapor E1 | Kartu bagikan bergaya piksel | M | Butuh setahun data; momen konversi dan pertumbuhan Desember |
| F2 | B-54 | **Rekap SPT** (⑤): penghasilan per sumber, potongan pajak freelance, saldo dompet 31 Des, utang | Freelance, utang-piutang D2, PDF E1 | Dokumen rekap | M | Januari, sebelum batas SPT orang pribadi 31 Maret |
| **Kapan saja (paralel)** | | | | | | |
| K1 | B-56 | Kosmetik Plus: tema, kostum tanuki, ikon aplikasi alternatif | Token ADR-034 | Aset dari pemilik | S kode + aset | Tidak menghalangi apa pun; masuk begitu aset siap. Bagus untuk peluncuran C4 bila ada |
| K2 | B-55 | Widget: tombol Catat (gratis), ringkasan (Plus) | Beranda, Rencana | `home_widget`, kode native | M | Widget Catat gratis bisa lebih dulu karena menaikkan kebiasaan mencatat |

### 13.3 Kenapa Penjaga pertama, bukan Catat dari foto atau Tanya Tanuki

- **Catat dari foto** paling "wah", tapi bergantung pada Blaze, pembaruan
  Keamanan Data, dan kebijakan privasi (B-20). Penjaga bisa mulai hari ini.
- **Tanya Tanuki** paling "AI", tapi mutu pemahaman pertanyaan belum
  terbukti; bila mengecewakan di peluncuran, kesan pertama Plus ikut rusak.
- **Penjaga** mengubah sifat aplikasi dari pasif menjadi proaktif tanpa
  biaya dan tanpa data keluar, dan langsung bisa diukur: apakah pengguna
  yang menerima peringatan kembali mencatat lebih sering.

### 13.4 Fase usulan

| Fase usulan | Isi | Hasil |
|---|---|---|
| Fase 21 | A1–A2 | Data bisa dibawa pergi dan dikunci (gratis). Terjadwal: A1 menjadi **Fase 22** ([EXPORT_BACKUP.md](EXPORT_BACKUP.md)) karena Fase 21 dipakai Penemuan fitur |
| Fase 22 | B1–B2 + C1 | Fondasi Plus dan Penjaga, Plus hanya untuk penguji |
| Fase 23 | C2–C4 | Catat dari foto, Bagaimana kalau, reverse trial: **Plus dijual** |
| Fase 24 | D1–D2 | Target dan utang-piutang |
| Fase 25 | E1–E3 | Rapor bulanan, Freelance Pro, cadangan otomatis |
| Fase 26 | E4 | Tanya Tanuki R1 |
| Musiman | F1–F2 | Rapor Tahunan dan Rekap SPT |

Nomor fase hanya usulan; fase baru dijadwalkan saat pemilik menaikkan
butirnya ke Now (aturan ROADMAP).

### 13.5 Sesudahnya (fitur mendatang)

| Butir | Isi | Syarat |
|---|---|---|
| B-57 | Patungan dari struk | B-45 dan B-48 |
| B-58 | Kartu kredit dan paylater sebagai dompet tagihan (gratis dasar, peringatan jatuh tempo di Penjaga) | ADR; PRD §6 |
| B-59 | Kekayaan bersih (aset dicatat manual dikurangi utang) | B-48 |
| B-60 | Dompet Bersama dan Plus Keluarga | Sinkronisasi B-7 |
| B-7 | Sinkronisasi antar perangkat (Plus) | ADR sendiri, KT-2 |
| B-61 | Rapor kuartal freelance; Tanya Tanuki R2 (kueri gabungan, antar tahun) | B-50, B-52 terukur |
| B-15 | Gemma lokal untuk tafsir tanpa internet (menekan biaya Gemini) | Biaya Gemini nyata dari B-45/B-52 |
| B-62 | Catat dari email (struk e-commerce, tagihan) | Kebijakan izin Gmail; paling akhir |

## 14. Risiko

| Risiko | Mitigasi |
|---|---|
| Penguji kecewa "dulu gratis" (notifikasi jadi 1 aplikasi, otomasi R3 jadi Plus) | Penguji dapat Plus 12 bulan; pembatasan hanya pada otomasi |
| Mutu Tanya Tanuki mengecewakan (salah paham pertanyaan) | Angka selalu dihitung lokal; pertanyaan yang tak terpetakan dijawab jujur; mulai dari katalog pertanyaan sempit; tayang paling akhir di antara pilar (E4) |
| Penjaga terasa mengganggu | Maksimal satu per hari, diatur per jenis, hanya saat ada sinyal nyata |
| Pembacaan foto salah | Draf selalu membuka CATAT; bagian ragu dikosongkan |
| Biaya Gemini membengkak | Batas wajar, Remote Config, dan Gemma lokal (B-15) sebagai jalan keluar |
| Rekap SPT dianggap nasihat pajak | Disebut rekap catatan; tidak menghitung pajak terutang; isi hanya data yang dicatat pengguna |
| Catat dari notifikasi hanya Android | Di iOS kelak, pengait utama: foto, Penjaga, Tanya Tanuki, rapor |
| Plus terlalu banyak untuk dirawat satu pengembang | Urutan §13; setiap pilar dibangun di atas mesin yang sudah ada; ukur pilar mana yang menjual sebelum menambah |

## 15. Keputusan pemilik (semua diputuskan 18 Okt 2026)

| KT | Keputusan |
|---|---|
| KT-P1 | Nama paket **Tanukonomy Plus** |
| KT-P2 | Uji coba terbalik **sampai akhir periode keuangan pertama yang penuh** (minimal 14 hari), aturannya di §8.1 |
| KT-P3 | **Dompet tanpa batas** di versi gratis |
| KT-P4 | Harga §11.2: Rp25.000/bulan, Rp179.000/tahun, Harga Pendiri Rp129.000/tahun terkunci; **tanpa paket seumur hidup** |
| KT-P5 | Penguji closed testing mendapat **Plus 12 bulan**, lalu Harga Pendiri |
| KT-P6 | Billing lewat **RevenueCat** (`purchases_flutter`) |
| KT-P7 | Ekspor dan cadangan manual serta kunci aplikasi (B-42/B-43) dikerjakan **sebelum rilis publik** |
| KT-P8 | Catat dari notifikasi gratis **1 aplikasi sumber** (§4.3) |
| KT-P9 | Peta kerja dan urutan §13: **Penjaga dibangun pertama**; Plus dijual sesudah Penjaga, Catat dari foto, dan Bagaimana kalau |
| KT-P10 | **Target dan utang-piutang masuk produk** (§7); ADR domain di B-47 dan B-48 |
| KT-P11 | **Seluruh otomasi rutin R3** (Fase 17, ADR-037) dan tingkat otomatis catat dari notifikasi menjadi **Plus**; gratis tetap punya rutin dasar R1/R2 (§4.3) |

Keputusan teknis (struktur kode, penyimpanan hak, perhitungan tanggal
berakhir uji coba, gerbang R3) ditulis di ADR monetisasi sebelum kode
(B-41). Angka harga, jatah cicip, dan batas wajar tetap hipotesis yang
disetel lewat Remote Config dan eksperimen harga Play sesudah ada data.

## 16. Sumber

- Spendee: [halaman Premium](https://www.spendee.com/premium).
- Wallet by BudgetBakers: [dukungan BudgetBakers](https://support.budgetbakers.com/hc/en-us/articles/7151349344018),
  [ulasan Finder](https://www.finder.com/uk/budgeting/wallet-budgetbakers-review).
- Money Lover: [App Store Vietnam](https://apps.apple.com/vn/app/money-lover-s%E1%BB%95-thu-chi/id486312413?l=vi),
  [App Store](https://apps.apple.com/dz/app/money-lover-money-manager/id486312413).
- Monefy: [ulasan Gerald](https://joingerald.com/learn/financial-wellness/monefy-expense-tracker-review).
- YNAB dan Monarch: [perbandingan harga 2026](https://getfinny.app/blog/ynab-vs-monarch-money-2026).
- Tolok ukur langganan: [RevenueCat State of Subscription Apps 2026](https://www.revenuecat.com/state-of-subscription-apps),
  [RevenueCat: tren dan tolok ukur 2026](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026),
  [Airbridge: hard vs soft paywall](https://www.airbridge.io/blog/hard-vs-soft-paywalls).
  Angka 10,7% dan 2,1% berasal dari ringkasan pihak kedua atas laporan
  RevenueCat 2026 (situs RevenueCat tidak bisa dibuka saat riset); anggap
  sebagai arah, bukan angka pasti.
- Harga Gemini dan perkiraan biaya: [VOICE_INPUT_RESEARCH.md](VOICE_INPUT_RESEARCH.md) §9.
  Perkiraan token per foto dan per pertanyaan di §11.3 adalah perkiraan
  [E] yang perlu diukur di spike.
