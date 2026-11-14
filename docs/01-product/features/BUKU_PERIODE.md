# Buku Periode: satu periode, satu buku, ditutup dan diceritakan Tanuki

**Tanggal:** 12 November 2026.
**Status:** Draf, menunggu keputusan pemilik (§16). Keputusan pemilik 12 Nov
2026: **seluruh Buku Periode hanya untuk Plus.** Belum dijadwalkan ke fase
(antrean B-95; menggeser B-49).
**Berkaitan:** [FREEMIUM_PAYWALL.md](FREEMIUM_PAYWALL.md) §6.5, §16, §16.4
(revisi pembagian gratis dan Plus), [GAMIFICATION.md](GAMIFICATION.md)
(mesin tonggak B-94, stempel), [FINANCIAL_PERIOD.md](FINANCIAL_PERIOD.md)
(periode keuangan), [FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md) (Analisis
dan kilas balik), [APP_UPDATE.md](APP_UPDATE.md) (pola banner dan lembar yang
menunggu), [ADR-041](../../02-architecture/adr/0041-monetisasi-hak-plus-dan-uji-coba.md)
(hak Plus).

Dokumen ini merancang perilaku, aturan, dan teks. Cara teknisnya diputuskan
engineer (§13). Rupa visual belum ada dan ditandai "perlu rupa dari
ui-ux-designer".

## 1. Ringkasan keputusan (usulan)

1. **Satu periode keuangan = satu buku.** Saat periode berakhir, bukunya
   siap: ajakan **Tutup buku** (ritual dua menit yang boleh dilewati),
   lalu **rapor** yang diceritakan Tanuki, lalu tersimpan di **Rak Buku**.
   Ini menyatukan tiga ide: tutup buku periode, Tanuki yang bereaksi, dan
   rapor bulanan bercerita (B-49).
2. **Buku Plus, kecuali satu Kartu Periode gratis** (keputusan pemilik 12
   Nov 2026): ritual, rapor, Tanuki sebagai narator, dan Rak Buku hanya Plus.
   Semua pengguna, termasuk Gratis, mendapat **satu Kartu Periode** yang bisa
   dibagikan sebagai jalur pertumbuhan (BP-15–BP-20). Kartu itu memuat nama
   aplikasi dan hanya fakta yang dipilih pengguna; **nominal boleh ditampilkan
   dan dibagikan** (keputusan pemilik 12 Nov 2026) bila pengguna
   menyalakannya sendiri, dan di pratinjaunya ada satu ajakan tenang ke Plus. Akibatnya ke keputusan sebelumnya ada di §2.
3. **Yang sudah gratis tetap gratis:** kartu Arus Beranda, Analisis 6 periode,
   dan kilas balik di kartu tinjau awal bulan sudah dikirim dan tidak
   ditarik (KT-BP3).
4. **Tutup buku tidak mengunci data.** Ritual hanya merapikan dan
   merayakan; transaksi periode lampau tetap bisa disunting (BP-5).
5. **Angka selalu dihitung langsung** dari data, sama persis dengan Beranda,
   Analisis, dan Rencana (BP-4). Stempel yang tercetak di sampul permanen.
6. **Tanuki bercerita, tidak menilai.** Kalimat dari templat lokal, tanpa
   mengirim data, tanpa kata yang menghakimi belanja (BP-7, BP-8).
7. **Satuannya buku, jadi mudah tumbuh:** halaman baru (Target, Penjaga,
   Freelance), Rapor Tahunan (satu rak berisi 12 buku), Kamar Tanuki, dan
   bagikan menambah halaman atau lapisan, bukan mengubah yang lama (§11).

## 2. Akibat ke keputusan sebelumnya

"Full Plus" mengubah pembagian di FREEMIUM_PAYWALL. Yang berubah, dan yang
tidak, supaya tidak ada dokumen yang saling bertentangan:

| Yang sebelumnya | Sekarang |
|---|---|
| §6.5: "Versi gratis: kartu angka ringkas" untuk rapor | **Diganti Kartu Periode:** satu kartu tetap yang bisa dibagikan, nominal opsional atas pilihan pengguna (BP-15, BP-16). Tidak ada rapor berhalaman untuk Gratis |
| §5 baris ⑤: Gratis "Rapor bulanan ringkas (angka, bisa dibagikan)" | Gratis: Kartu Periode yang bisa dibagikan + ajakan Plus di pratinjau. Arus, Analisis 6 periode, dan kilas balik tetap gratis |
| §9 P6: "rapor ringkas tampil, rapor bercerita diburamkan" | Kartu Periode di Beranda; sampul buku yang diburamkan (data asli) ada di pratinjau kartu sebagai ajakan Plus |
| §8.2 uji coba: "Rapor bulanan bercerita untuk periode uji coba" sebagai momen Plus terakhir | Tetap, kini berupa **Buku Periode** uji coba (lebih kuat: pengalaman penuh) |
| §16.2: gamifikasi terutama alat retensi versi gratis | Stempel B-94 **tetap gratis** (KT-BP1); bagi pengguna Plus, stempel periode ikut tercetak di sampul buku |
| B-49 "Plus; gratis: rapor ringkas" | B-49 menjadi lapisan R2 di atas B-95 (tipe tanuki, bagikan, PDF/Excel); tidak ada versi gratis |
| §10: "Rapor yang sudah dibuat tetap bisa dibuka dan dibagikan" sesudah Plus berakhir | **Tetap berlaku** (BP-10) |

Konsekuensi yang perlu disadari pemilik:

- **Saluran pertumbuhan tetap ada, dengan satu kartu.** Kartu Periode adalah
  satu-satunya bagian buku yang bisa dibagikan Gratis; bagikan yang lebih kaya
  (varian, kartu geser, tipe tanuki, PDF) tetap Plus (R2). Kartu membawa
  nama aplikasi dan tautan toko yang sama untuk semua orang, tanpa hadiah atau
  referral per pengguna (KT-P18 tetap berlaku).
- **Kartu adalah dua hal sekaligus:** alat tumbuh (dibagikan) dan permukaan
  konversi (ajakan Plus di pratinjau). Keduanya harus tenang agar yang
  dibagikan terasa milik pengguna, bukan iklan.
- **Kartu pertama muncul sesudah ada periode yang berakhir** dengan ≥3
  transaksi, termasuk periode pertama.

## 3. Masalah dan bukti

- **Tidak ada momen penutup.** Periode keuangan berganti diam-diam. Pengguna
  tidak merasakan "satu bulan selesai" dan tidak diajak merapikan transaksi
  tanpa kategori atau rutin yang menunggu padahal Analisis akan lebih tepat.
  Bukti: temuan FR-ANL-005 (Tanpa kategori), keputusan kilas balik di tinjau
  awal bulan, dan riset gamifikasi di laporan bisnis pemilik (FREEMIUM_PAYWALL
  §16). *Asumsi sampai diukur:* belum ada data berapa persen pengguna
  merapikan periode lama.
- **Plus belum punya pengalaman penutup yang berkesan.** Pilar ⑤ Tanuki
  Melapor belum ada; uji coba Plus berakhir tanpa momen puncak.
- **Pesaing memberi laporan bulanan datar** (tabel dan grafik). Ruang yang
  kosong: cerita pendek yang hangat tanpa menghakimi.

## 4. Tujuan, non-tujuan, dan ukuran keberhasilan

**Tujuan**

1. Memberi rasa selesai di akhir tiap periode dan mendorong catatan yang
   lebih rapi tanpa menekan.
2. Membuat uji coba dan langganan Plus punya momen yang berkesan di tiap
   gajian.
3. Menyediakan satu satuan (buku) yang menampung rapor tahunan, halaman
   fitur baru, dan kosmetik.

**Non-tujuan (R1)**

- Tipe tanuki, bagikan, PDF/Excel (R2), Rapor Tahunan dan Kamar Tanuki (R3).
- Rapor oleh AI generatif (R1 memakai templat lokal).
- Menilai belanja, memberi skor, atau membandingkan dengan pengguna lain.
- Mengunci periode atau menghalangi suntingan.
- Notifikasi dorong. Semuanya hanya tampil saat aplikasi dibuka.
- Dokumen resmi. Rapor adalah rekap catatan pribadi, bukan pengganti rekening
  koran atau laporan pajak.

**Ukuran keberhasilan** (ambang adalah usulan sampai ada garis dasar)

| Ukuran | Usulan | Cara mengukur |
|---|---|---|
| Pengguna Plus yang membuka buku periode terakhir dalam 7 hari sesudah periode berakhir | ≥50% | `book_opened{plus: true}` |
| Transaksi tanpa kategori turun sesudah ritual | Pengguna yang menyelesaikan langkah itu tidak meninggalkan transaksi tanpa kategori | `book_ritual_step{step: uncategorized, done: true}` |
| Kartu dibagikan | Sebagian pengguna Gratis membagikan kartu periodenya (ambang usulan sesudah ada garis dasar) | `period_card_shared` per pengguna aktif per periode |
| Kartu mendatangkan pengguna | Pemasangan baru yang membawa penanda sumber `period_card` | Kampanye `utm_source=period_card` di Firebase, tanpa mengenali individu |
| Ajakan Plus di pratinjau mengantar ke Plus | Konversi pratinjau → pembelian dibandingkan P1–P5 yang berbasis batas | `paywall_opened{source: period_card}` → pembelian |
| Kartu tidak mengganggu | <10% menutup dengan "Jangan tampilkan lagi" atau mengeluh | `period_card_dismissed{forever}` dan umpan balik penguji |
| Uji coba berakhir dengan buku dibuka | ≥60% pengguna uji coba membuka bukunya | `book_opened{source: trial}` |

## 5. Pengguna dan skenario

Semua nominal dalam rupiah; periode 25 Okt – 24 Nov 2026. Rani mencatat 12
transaksi: pemasukan gaji Rp8.500.000 dan 11 pengeluaran (kos Rp1.200.000,
internet Rp350.000, makan Rp1.640.000, transport Rp520.000, belanja
Rp780.000, hiburan Rp215.000) dengan total pengeluaran **Rp4.705.000** dan
selisih **Rp3.795.000**. Makan 35%, kos 26%, belanja 17% dari pengeluaran
(persen dibulatkan setengah ke atas, jumlah tidak dipaksa 100%). Tiga
rutin periode itu: kos dan internet dicatat, cicilan Rp2.914.000 dilewati
karena sudah lunas.

**S1 — Rani (Plus), ritual lengkap.** Pada 25 Nov Rani membuka aplikasi.
Kartu di Beranda: "Buku 25 Okt – 24 Nov siap ditutup". Ia mengetuk **Tutup
buku**. Langkah 1: "Semua transaksi sudah berkategori." Langkah 2: "Semua
rutin sudah selesai." Langkah 3: kilas balik rencana dan kenyataan. Ia
mengetuk **Tutup buku**. Tanuki muncul bersama dua stempel periode (Periode
rapi, Rutin tak terlewat), lalu rapor: Arus (pemasukan Rp8.500.000,
pengeluaran Rp4.705.000, selisih Rp3.795.000), Ke mana uang pergi, dan
beberapa kalimat dari Tanuki. Bukunya masuk Rak Buku.

**S2 — Budi (Plus), ada yang tertinggal.** Budi punya 14 transaksi, 2 belum
berkategori. Langkah 1 menampilkan "2 transaksi belum berkategori" dengan
**Beri kategori** (membuka Riwayat tersaring) dan **Lewati**. Ia melewatinya.
Rapor tetap terbuka, dengan satu catatan netral "2 transaksi belum
berkategori, jadi pembagian kategori belum penuh" dan tautan Beri kategori.
Ia memberi kategori seminggu kemudian; angka rapor ikut berubah (BP-4) dan
stempel Periode rapi diraih pada pembukaan berikutnya (GAMIFICATION S5).

**S3 — Dodi (Gratis), Kartu Periode.** Pada 25 Nov Dodi melihat satu kartu di
Beranda: "Kartu periode 25 Okt – 24 Nov siap dibagikan." Ia mengetuk
**Bagikan**, dan pratinjau terbuka: Tanuki, nama periode, dan tiga fakta
yang bisa ia nyalakan atau matikan: "12 catatan", "Rutin beres:
2 tercatat, 1 dilewati", dan stempel "Periode rapi". Fakta "Kategori terbesar"
dan ketiga nominal (Pemasukan, Pengeluaran, Selisih) mati secara bawaan
(KT-BP10). Dodi menyalakan **Selisih**: kartu kini menampilkan "Selisih
Rp3.795.000", dan satu baris kecil mengingatkan "Nominal yang kamu nyalakan
terlihat oleh siapa pun yang menerima gambar." Ia mengetuk **Bagikan kartu**, memilih
aplikasinya di lembar bagikan sistem, dan gambar terkirim bersama teks
"Periode 25 Okt – 24 Nov aku mencatat dengan Tanukonomy" dan tautan toko.
Di bawah pratinjau ada satu baris tenang: "Cerita lengkapnya ada di buku
periode. Buka dengan Plus." dengan sampul buku yang diburamkan. Dodi
mengabaikannya; tidak ada yang berubah. Kartu di Beranda tidak muncul lagi
untuk periode itu. Arus, Analisis, dan kilas balik tetap seperti biasa.

**S4 — Uji coba berakhir.** Mira (Trial) mencapai hari pertama periode
berikutnya. Plus tetap aktif sampai buku periode uji coba dibuka atau paling
lama sehari sesudah periode berakhir. Bukunya dibuka sebagai momen Plus
terakhir; sesudah itu layar turun ke Gratis dengan penawaran 48 jam
(FREEMIUM_PAYWALL §8.2).

**S5 — Plus berakhir.** Tono membuka buku Oktober saat masih Plus.
Langganannya berakhir. Buku Oktober tetap bisa dibuka; buku November yang
belum pernah dibuka terkunci; yang tersisa hanya Kartu Periode (BP-10, BP-15).

**S6 — Periode peralihan.** Periode 25 Sep – 31 Okt (37 hari, peralihan)
mendapat buku berlabel "Periode peralihan · 37 hari". Tanpa halaman
"Dibanding biasanya" (peralihan tidak dibandingkan, FINANCIAL_ANALYSIS).

**S7 — Absen.** Sari tidak membuka aplikasi 70 hari. Ajakan Tutup buku
hanya untuk periode terakhir; dua periode sebelumnya masuk Rak Buku sebagai
"Belum dibuka", bisa dibuka kapan saja. Tidak ada hitungan "2 buku
menunggu" di Beranda.

## 6. Alur pengguna

```mermaid
flowchart TD
  A[Periode berakhir, aplikasi dibuka] --> B{Plus atau uji coba?}
  B -- tidak --> T[Kartu Periode di Beranda, sekali per periode]
  T -- Bagikan --> V[Pratinjau: pilih fakta, nominal opsional]
  V -- Bagikan kartu --> W[Lembar bagikan sistem: gambar + teks + tautan toko]
  V -- Cerita lengkap dengan Plus --> P[Paywall, sumber period_card]
  T -- Nanti --> Z[Tidak tampil lagi untuk periode ini]
  B -- ya --> C[Kartu Beranda: Buku periode siap ditutup]
  C -- Tutup buku --> R[Ritual: tiga langkah, tiap langkah boleh dilewati]
  C -- Buka saja --> K[Rapor]
  R --> K
  C -- Nanti --> S[Tetap di Rak Buku sebagai Belum dibuka]
  K --> H[Rak Buku]
  S --> H
```

1. **Titik masuk:** kartu Beranda di akhir periode, Rak Buku di Riwayat
   (segmen ketiga, KT-BP5), dan notifikasi tidak dipakai.
2. **Ritual (tiga langkah):**
   1. *Tanpa kategori:* jumlahnya dan **Beri kategori** (membuka Riwayat
      tersaring), atau "Semua transaksi sudah berkategori."
   2. *Rutin menunggu:* jumlahnya dan jalan ke segmen Rutin, atau "Semua
      rutin sudah selesai."
   3. *Kilas balik:* rencana dan kenyataan (kilas balik yang sudah ada).
   Penutup: tombol **Tutup buku** dan satu kalimat bahwa data tetap bisa
   diubah. Jumlah ketukan minimal: dua (Tutup buku di kartu, Tutup buku di
   akhir) bila semuanya sudah rapi.
3. **Rapor:** sampul lalu halaman (§7). Dapat digeser; menutup rapor
   kembali ke tempat asal.
4. **Jalan pulang:** menutup ritual di tengah menyimpan langkah yang sudah
   selesai; buku tetap "Siap ditutup" dan bisa dibuka dari Rak Buku.

## 7. Isi buku (kebutuhan informasi)

Halaman bersifat bersyarat: muncul hanya bila datanya ada. Urutan tetap.

| # | Halaman | Isi | Muncul bila |
|---|---|---|---|
| 0 | Sampul | Nama periode (P-11: nama bulan bila mulai tanggal 1, selain itu rentang; peralihan berlabel), Tanuki, stempel yang diraih di periode itu (B-94) | Selalu |
| 1 | Arus periode | Pemasukan, pengeluaran, selisih; transfer tidak dihitung; sama persis dengan Arus Beranda | Selalu |
| 2 | Ke mana uang pergi | Lima kategori pengeluaran teratas: nominal dan persen; Lainnya dan Tanpa kategori; pemasukan freelance tanpa kategori sebagai Freelance | Ada pengeluaran |
| 3 | Dibanding biasanya | Paling banyak tiga sorotan netral (selisih ≥20% dan ≥Rp50.000 terhadap rata-rata tiga periode) | Ada pembanding dan bukan peralihan |
| 4 | Rutin dan rencana | Rutin tercatat dan dilewati; rencana vs kenyataan (kilas balik) | Ada rutin atau anggaran |
| 5 | Kata Tanuki | Dua sampai empat kalimat dari templat lokal (§12) | Selalu |

Halaman 1–3 memakai aturan dan angka Analisis tanpa menghitung ulang.

**Kartu Periode (semua pengguna, BP-15–BP-20)** adalah satu gambar tetap yang
bisa dibagikan, bukan halaman buku. Kebutuhan informasi, tanpa rupa:

1. Nama periode (P-11; peralihan berlabel) dan Tanuki.
2. Fakta yang dipilih pengguna di pratinjau (paling banyak enam, semua
   opsional): jumlah catatan, rutin beres, stempel periode, kategori bawaan
   terbesar dengan persen, dan **nominal** Pemasukan, Pengeluaran, dan
   Selisih (ketiganya bawaan mati; selisih negatif tampil dengan tanda minus,
   tanpa warna peringatan).
3. Nama aplikasi dan tautan toko (satu tautan umum, BP-18).
4. Di pratinjau, bukan di gambar: pilihan fakta, satu baris pengingat bahwa
   nominal yang dinyalakan terlihat penerima, tombol Bagikan kartu, dan satu
   baris ajakan Plus dengan sampul buku diburamkan (BP-19).

Keadaan pratinjau: tanpa fakta dinyalakan (tombol nonaktif), semua fakta
tersedia, dan periode peralihan. Bagi Plus, kartu yang sama menjadi satu
halaman buku dan varian lebih kaya menyusul di R2.
Halaman baru (Target, Penjaga, Freelance, Utang) ditambahkan oleh fitur
masing-masing saat ada (§11).

## 8. Aturan bisnis

| # | Aturan (bisa diuji) |
|---|---|
| BP-1 | Ritual, rapor berhalaman, Tanuki sebagai narator, dan Rak Buku hanya terbuka untuk Plus dan uji coba. **Satu-satunya pengecualian adalah Kartu Periode (BP-15).** Gratis tidak pernah melihat isi halaman buku selain sampul yang diburamkan di pratinjau kartu. |
| BP-2 | Kartu Periode di Beranda: paling banyak **satu kartu per periode**, sesudah periode berakhir, hanya bila periode itu punya ≥3 transaksi (periode pertama ikut). Menutupnya = tidak muncul lagi untuk periode itu. Tidak tampil di Catat, lembar lain, onboarding, atau tur; kalah dari banner pembaruan; tidak ada hitung mundur atau pesan "kamu melewatkan". Bagi Plus, kartu ini digantikan ajakan Tutup buku, dan Kartu Periode tetap ada sebagai satu halaman buku. |
| BP-3 | Buku hanya untuk periode yang **sudah berakhir** dengan ≥1 transaksi. Periode berjalan tidak punya buku. Periode peralihan punya buku berlabel. |
| BP-4 | Semua angka di buku dihitung langsung dari data dengan aturan periode yang sama (`financialPeriodOf`, `periodDateOf`) dan sama persis dengan Arus Beranda, Analisis, dan Rencana (B-3, B-15). Tidak ada snapshot angka. Stempel di sampul permanen (GAMIFICATION G-1). |
| BP-5 | Tutup buku tidak mengunci, tidak mengubah saldo, anggaran, rutin, atau transaksi, dan tidak menghalangi suntingan periode lampau. |
| BP-6 | Setiap langkah ritual boleh dilewati; rapor bisa dibuka tanpa ritual. Meninggalkan langkah tidak menghukum; rapor hanya memberi catatan netral dengan jalan memperbaikinya. |
| BP-7 | Teks tidak pernah menilai belanja: tanpa "boros", "hemat", "terlalu", "kurang", skor, peringkat, atau perbandingan dengan pengguna lain. Sorotan memakai ambang Analisis (≥20% dan ≥Rp50.000, maksimal tiga). |
| BP-8 | Kalimat Tanuki berasal dari templat lokal dengan isian angka; tidak ada data keuangan keluar perangkat dan tidak memakai Gemini di R1. |
| BP-9 | Satu ajakan Tutup buku sekaligus, untuk periode terakhir. Periode lebih lama masuk Rak Buku sebagai "Belum dibuka" dan bisa dibuka kapan saja; tidak ada hitungan "n buku menunggu" di Beranda. |
| BP-10 | Sesudah Plus berakhir, buku yang **pernah dibuka** tetap bisa dibuka (dan dibagikan di R2); buku yang belum dibuka terkunci (sampul diburamkan di pratinjau kartu). Kartu Periode tetap tersedia (BP-15). Ini menepati "rapor yang sudah dibuat tetap bisa dibuka" (FREEMIUM_PAYWALL §10). |
| BP-11 | Uji coba: Plus tetap aktif sampai buku periode uji coba dibuka atau paling lama 1 hari sesudah periode berakhir (FREEMIUM_PAYWALL §8.2). |
| BP-12 | Nominal disembunyikan bila pengguna menyembunyikan nominal; persen dan kalimat tanpa nominal tetap tampil. |
| BP-13 | Ajakan dan rapor tidak tampil di Catat, lembar lain, onboarding, atau tur. **Perayaan tanpa diminta** (muncul sendiri saat aplikasi dibuka) mengikuti GAMIFICATION G-4: satu per pembukaan, dan stempel periode dilipat ke sampul bila ritual atau rapor dibuka pada pembukaan yang sama. **Revisi 14 Nov 2026 (versi permainan):** gerak dan perayaan yang **dipicu tindakan pengguna di dalam layar buku atau kartu** (menyalakan stiker, mencap stempel, menutup buku, membagikan) boleh tampil, karena pengguna sendiri yang memintanya; syaratnya tetap bisa dimatikan lewat sakelar perayaan (G-8) dan dikurangi lewat Gerak dikurangi. Larangan di Catat, lembar lain, onboarding, dan tur tidak berubah. |
| BP-14 | Pengguna Plus bisa mematikan **Ajakan akhir periode**; rapor dan Rak Buku tetap bisa dibuka manual. |
| BP-15 | **Kartu Periode** tersedia untuk semua pengguna (Gratis, Plus, uji coba): satu kartu bertema tetap per periode yang berakhir, hanya satu templat dan satu ukuran. Plus mendapat varian dan kartu geser di R2. |
| BP-16 | Kartu hanya memuat fakta yang **dipilih pengguna** di pratinjau: jumlah catatan, rutin beres, stempel, kategori bawaan terbesar dengan persen, dan **nominal** Pemasukan, Pengeluaran, Selisih periode itu (keputusan pemilik 12 Nov 2026: nominal boleh ditampilkan dan dibagikan). Nominal dan kategori terbesar **mati secara bawaan**. Kartu tidak pernah memuat nama dompet, saldo dompet, nama kategori buatan pengguna (tampil "kategori buatanmu"), nama pedagang, nominal per transaksi, atau catatan transaksi. |
| BP-21 | Pratinjau menampilkan satu baris pengingat bila ada nominal yang dinyalakan: "Nominal yang kamu nyalakan terlihat oleh siapa pun yang menerima gambar." Bila pengguna menyembunyikan nominal di aplikasi (BP-12), sakelar nominal nonaktif dengan keterangan, dan kartu tidak memuat nominal. |
| BP-17 | Gambar kartu dibuat di perangkat dan hanya keluar lewat lembar bagikan sistem atas tindakan pengguna. Tidak ada unggah ke server kita dan tidak ada berbagi otomatis. |
| BP-18 | Kartu dan teks bagikannya membawa nama aplikasi dan **satu tautan toko yang sama untuk semua pengguna**, dengan penanda sumber (`utm_source=period_card`) untuk mengukur pertumbuhan. Tanpa kode atau tautan per pengguna, tanpa hadiah atau referral (KT-P18). |
| BP-19 | Pratinjau kartu memuat satu baris ajakan Plus ("Cerita lengkapnya ada di buku periode") dengan sampul buku yang diburamkan. Maksimal satu ajakan, tidak ada hitung mundur, dan tidak ada hambatan untuk membagikan kartu. |
| BP-20 | Teks kartu mengikuti BP-7 (tidak menilai belanja) dan memakai templat tetap; tanpa kalimat Tanuki bebas. Periode dengan <3 transaksi tidak punya kartu. |

Yang perlu diingat aplikasi: buku mana yang sudah dibuka (id periode,
tanggal), langkah ritual yang selesai, kartu yang sudah ditutup per
periode, dan sakelar BP-14. Bukan data keuangan dan bukan entitas domain
keuangan; penyimpanannya wajib didaftarkan di `BackupRegistry` (CLAUDE.md,
Fase 22).

## 9. Teks: templat Tanuki (id / en)

Lihat §14 untuk kunci. Prinsip templat:

- Satu kalimat satu fakta; maksimal empat kalimat; bahasa "kamu".
- Dipilih dengan aturan tetap dari fakta yang ada: (1) catatan dan arus,
  (2) kategori terbesar, (3) rutin, (4) kerapian.
- Contoh untuk periode Rani: "Periode ini kamu mencatat 12 transaksi.
  Pemasukan Rp8.500.000, pengeluaran Rp4.705.000, sisanya Rp3.795.000."
  "Makan jadi kategori terbesar, 35% dari pengeluaran." "Semua rutin sudah
  beres: 2 tercatat, 1 dilewati." "Semua transaksi punya kategori, jadi
  angkanya tepat."
- Dilarang: "boros", "hemat", "terlalu", "kurang", "sayang", "hati-hati",
  tanda seru, dan kalimat yang menyuruh kebiasaan (writing.md).

## 10. Analitik dan privasi

Peristiwa lewat `AppAnalytics`, kelas baru `PeriodBookEvents`, tanpa
nominal, nama kategori, atau teks pengguna.

| Peristiwa | Parameter | Kapan |
|---|---|---|
| `period_card_shown` | `plus: true\|false` | Kartu Periode tampil di Beranda |
| `period_card_dismissed` | `action: later\|forever` | Kartu ditutup |
| `period_card_opened` | `plus: true\|false` | Pratinjau dibuka |
| `period_card_shared` | `facts: n`, `with_category: true\|false`, `with_amounts: true\|false` (hanya benar/salah, tidak pernah nilai nominal) | Lembar bagikan sistem dibuka dari pratinjau (tidak diketahui apakah selesai terkirim) |
| `book_ritual_started` | — | Ritual dibuka |
| `book_ritual_step` | `step: uncategorized\|recurring\|review`, `action: done\|skipped\|opened_fix` | Langkah selesai atau dilewati |
| `book_opened` | `source: ritual\|card\|shelf\|trial`, `plus: true\|false` | Rapor dibuka |
| `book_shelf_viewed` | — | Rak Buku dibuka |
| `paywall_opened` | `source: period_card` | Paywall dari ajakan di pratinjau kartu (peristiwa yang sudah ada) |

Privasi: buku dihitung dan disimpan di perangkat; templat lokal; tidak ada
data baru keluar. Peristiwa memakai id tetap dan masuk kategori "Aktivitas
aplikasi" yang sudah dideklarasikan
([PLAY_DATA_SAFETY.md](../../03-release/PLAY_DATA_SAFETY.md)); tetap dicek di
tugas verifikasi. R2 (bagikan, PDF): gambar dan berkas bagikan tidak memuat
data di luar yang dipilih pengguna. Nominal di Kartu Periode hanya atas pilihan pengguna dan tidak pernah tercatat di analitik; gambar yang sudah dibagikan berada di luar kendali aplikasi, sehingga pengingat BP-21 wajib ada.

## 11. Titik perluasan

Halaman adalah satuan perluasan: sebuah **penyedia halaman** memberi nol atau
satu halaman bila datanya ada, dengan posisi tetap di katalog.

| Mau menambah | Yang berubah | Yang tidak berubah |
|---|---|---|
| Halaman Target (B-47), Utang (B-48), Penjaga (B-44: peringatan periode ini), Freelance (penghasilan per klien) | Satu penyedia halaman + teks | Alur ritual, Rak Buku, gerbang |
| Tipe tanuki di sampul (R2) | Aturan pemilih tipe dari kebiasaan mencatat, bukan nominal | Angka dan halaman |
| Bagikan, PDF, Excel (R2; B-49) | Perender dan pengekspor | Isi buku |
| Rapor Tahunan (B-53) | Layar rak 12 buku → kartu geser | Buku bulanan |
| Rekap SPT (B-54), rapor kuartal freelance | Penyedia halaman tahunan dan kuartalan | Penyimpanan |
| Kamar Tanuki (B-81) | Membaca stempel dari buku | Penyimpanan stempel |
| Langkah ritual baru | Satu langkah + teks | Aturan BP-6 (boleh dilewati) |

## 12. Diserahkan ke engineer

Keputusan teknis berikut sengaja tidak diputuskan di sini. Engineer menulis
ADR baru (nomor berikutnya, Proposed sampai pemilik menyetujui) sebelum kode:

1. **Gerbang Plus:** `PlusFeature` baru dan pola `PlusLocked` yang ada;
   perilaku Kartu Periode untuk Gratis; pemeriksaan hak bagi buku yang pernah dibuka
   (BP-10) dan masa tenggang Plus (ADR-041).
2. **Sumber angka:** memakai model baca Analisis, Arus Beranda, dan Rencana
   tanpa menyalin aturan periode; kecocokan total (B-3, B-15) diuji.
3. **Penyedia halaman:** bentuknya, cara terdaftar lewat akar komposisi
   (`lib/app/`) tanpa fitur saling mengimpor (ADR-030).
4. **Templat kalimat:** mesin templat dengan isian angka dan bentuk jamak,
   dijaga uji glosarium dan `translations_test.dart`.
5. **Ingatan:** buku dibuka, langkah ritual, kartu ditutup, dan sakelar;
   pendaftaran `BackupRegistry`.
6. **Fakta "periode tertutup":** dipakai bersama mesin tonggak B-94
   (stempel Periode rapi dan Rutin tak terlewat).
7. **Slot Beranda** untuk kartu ajakan Tutup buku dan Kartu Periode, dan urutannya terhadap
   banner pembaruan dan kotak masuk.

Batasan yang wajib dipenuhi pilihan apa pun: aturan BP-1–BP-14, tanpa data
keuangan keluar perangkat, inti tetap luring dan tidak melambat (buku
dihitung saat dibuka, bukan di jalur pembukaan aplikasi), bisa diuji tanpa
perangkat, dan angka sama persis dengan Analisis. Bila sebuah batasan tidak
bisa dipenuhi, berhenti dan lapor ke pemilik.

## 13. Kata dan kalimat (id / en)

Kunci diusulkan di namespace `book.*`; tunduk pada `writing.md` dan
glosarium ("kamu", tanpa tanda seru; istilah terlarang tidak dipakai).

| Kunci | id | en |
|---|---|---|
| `book.card.title` | Buku $period siap ditutup | The $period book is ready to close |
| `book.card.close` | Tutup buku | Close the book |
| `book.card.later` | Nanti | Later |
| `book.share.cardTitle` | Kartu periode $period siap dibagikan | The $period card is ready to share |
| `book.share.action` | Bagikan | Share |
| `book.share.later` | Nanti | Later |
| `book.share.previewTitle` | Kartu periode | Period card |
| `book.share.previewHint` | Pilih yang mau kamu tampilkan. Nominal hanya ikut kalau kamu menyalakannya. | Choose what to show. Amounts only appear if you turn them on. |
| `book.share.factIncome` | Pemasukan $amount | Income $amount |
| `book.share.factExpense` | Pengeluaran $amount | Spending $amount |
| `book.share.factNet` | Selisih $amount | Difference $amount |
| `book.share.amountWarning` | Nominal yang kamu nyalakan terlihat oleh siapa pun yang menerima gambar. | Amounts you turn on are visible to anyone who receives the image. |
| `book.share.amountsHidden` | Nominal sedang disembunyikan di aplikasi. Matikan dulu untuk menampilkannya di kartu. | Amounts are hidden in the app. Turn that off first to show them on the card. |
| `book.share.factRecords` | $count catatan | $count records |
| `book.share.factRecurring` | Rutin beres: $recorded tercatat, $skipped dilewati | Recurring done: $recorded recorded, $skipped skipped |
| `book.share.factStamp` | Stempel: $name | Stamp: $name |
| `book.share.factCategory` | Kategori terbesar: $name $percent% | Biggest category: $name $percent% |
| `book.share.userCategory` | kategori buatanmu | your own category |
| `book.share.send` | Bagikan kartu | Share the card |
| `book.share.text` | Periode $period aku mencatat dengan Tanukonomy. $link | I tracked $period with Tanukonomy. $link |
| `book.share.plusNudge` | Cerita lengkapnya ada di buku periode. Buka dengan Plus. | The full story is in the period book. Open it with Plus. |
| `book.share.plusAction` | Lihat Plus | See Plus |
| `book.ritual.title` | Tutup buku $period | Close the $period book |
| `book.ritual.uncategorized.some` | $count transaksi belum berkategori. Beri kategori supaya ceritanya tepat. | $count transactions have no category. Add one so the story is accurate. |
| `book.ritual.uncategorized.none` | Semua transaksi sudah berkategori. | Every transaction has a category. |
| `book.ritual.recurring.some` | $count rutin masih menunggu. | $count recurring items are still waiting. |
| `book.ritual.recurring.none` | Semua rutin sudah selesai. | Every recurring item is done. |
| `book.ritual.review` | Lihat rencana dan kenyataan periode ini. | See this period's plan and what happened. |
| `book.ritual.fix` | Beri kategori | Add categories |
| `book.ritual.skip` | Lewati | Skip |
| `book.ritual.finish` | Tutup buku | Close the book |
| `book.ritual.note` | Data tetap bisa kamu ubah kapan saja. | You can still change your data anytime. |
| `book.cover.title` | Buku $period | $period book |
| `book.cover.transition` | Periode peralihan · $days hari | Transition period · $days days |
| `book.page.flow` | Arus periode | Period flow |
| `book.page.where` | Ke mana uang pergi | Where the money went |
| `book.page.compare` | Dibanding biasanya | Compared to usual |
| `book.page.recurring` | Rutin dan rencana | Recurring and plans |
| `book.page.tanuki` | Kata Tanuki | Tanuki says |
| `book.note.uncategorized` | $count transaksi belum berkategori, jadi pembagian kategori belum penuh. | $count transactions have no category, so the split is not complete. |
| `book.tanuki.records` | Periode ini kamu mencatat $count transaksi. | This period you recorded $count transactions. |
| `book.tanuki.flow` | Pemasukan $income, pengeluaran $expense, sisanya $net. | Income $income, spending $expense, $net left. |
| `book.tanuki.topCategory` | $name jadi kategori terbesar, $percent% dari pengeluaran. | $name was the biggest category, $percent% of spending. |
| `book.tanuki.recurringClear` | Semua rutin sudah beres: $recorded tercatat, $skipped dilewati. | Every recurring item is done: $recorded recorded, $skipped skipped. |
| `book.tanuki.tidy` | Semua transaksi punya kategori, jadi angkanya tepat. | Every transaction has a category, so the numbers are accurate. |
| `book.shelf.title` | Rak Buku | Book Shelf |
| `book.shelf.empty` | Belum ada buku. Buku pertama siap saat periodemu berakhir. | No books yet. The first one is ready when your period ends. |
| `book.shelf.unopened` | Belum dibuka | Not opened yet |
| `book.shelf.locked` | Dibuka dengan Plus | Opens with Plus |
| `book.setting.label` | Ajakan akhir periode | End-of-period invitation |
| `book.setting.hint` | Tampilkan ajakan menutup buku saat periode berakhir. | Show an invitation to close the book when a period ends. |

Istilah baru masuk glosarium: **Buku Periode**, **Tutup buku**, **Rapor**,
**Rak Buku**.

## 14. Kasus tepi

| Kasus | Perilaku |
|---|---|
| Periode terakhir tanpa transaksi | Tidak ada buku dan tidak ada kartu (BP-3, BP-20). |
| Hanya satu periode di riwayat | Kartu dan buku pertama muncul sesudah periode itu berakhir, bila ≥3 transaksi. |
| Pratinjau tanpa fakta yang dinyalakan | Tombol Bagikan kartu nonaktif; ajakan memilih sedikitnya satu fakta. |
| Nominal disembunyikan di aplikasi | Sakelar nominal di pratinjau nonaktif dengan keterangan; kartu tidak memuat nominal (BP-21). |
| Selisih negatif (pengeluaran lebih besar dari pemasukan) | Tampil dengan tanda minus dan tanpa warna peringatan, sama dengan Arus Beranda; kalimat tidak menilai. |
| Pengguna mematikan nominal lalu menyalakan lagi | Pilihan sakelar tidak diingat antarperiode; bawaan mati tiap kartu baru. |
| Nominal di pratinjau bila mata uang bukan IDR | Memakai `AppMoneyFormatter` dengan mata uang aktif (ADR-025). |
| Kategori terbesar adalah kategori buatan pengguna | Tampil "kategori buatanmu" dengan persen, atau disembunyikan bila pengguna lebih suka (BP-16). |
| Pengguna membagikan lalu mengubah data periode itu | Gambar yang sudah terkirim tidak berubah; membagikan lagi memakai data terbaru. |
| Lembar bagikan dibatalkan | Tidak ada apa pun; peristiwa tetap tercatat sekali per pembukaan lembar. |
| Transaksi periode lampau diedit sesudah buku dibuka | Angka rapor ikut berubah (BP-4); stempel tidak berubah. |
| Tanggal mulai periode diubah sesudah buku dibuat | Buku mengikuti periode yang berlaku saat itu; periode lampau tidak dipotong ulang (ADR-038). |
| Plus berakhir tengah ritual | Ritual selesai bila sudah dibuka; buku baru terkunci dan hanya Kartu Periode (BP-15) yang tersisa. |
| Pemulihan dari cadangan | Buku dibuka dan sakelar ikut dipulihkan; rapor dihitung ulang dari data. |
| Periode sangat pendek atau panjang (peralihan 13–46 hari) | Label rentang; tanpa halaman Dibanding biasanya. |
| Bahasa diganti | Rapor tampil dalam bahasa baru; templat mengikuti. |
| Nominal disembunyikan | Nominal tertutup, persen dan kalimat tanpa nominal tampil (BP-12). |
| Pengguna Gratis memberi kategori sendiri dari Analisis | Tidak berkaitan dengan buku; fitur gratis tetap bekerja. |
| Perangkat dengan layar 360dp | Rapor dapat digeser; teks tidak terpotong (diverifikasi engineer/QA). |
| Pengguna menghapus data aplikasi | Tidak ada buku dibuka; semua periode "Belum dibuka". |

## 15. Fase rilis dan usulan tugas

- **R1 (B-95, Plus):** ritual, sampul + stempel, halaman 1–5, Tanuki dari
  templat, Rak Buku, **Kartu Periode** (pratinjau, bagikan, ajakan Plus),
  gerbang, sakelar, analitik. Kartu Periode bisa dikirim lebih dulu daripada
  buku karena tidak bergantung pada ritual dan rapor (T-n.7a).
- **R2 (B-49 disesuaikan, Plus):** tipe tanuki, bagikan kaya (varian, kartu geser),
  PDF/Excel.
- **R3 (B-53, B-54, B-81):** Rapor Tahunan sebagai rak 12 buku, Rekap SPT,
  Kamar Tanuki, halaman Target dan Utang saat domainnya ada.

Usulan pemecahan R1 (belum masuk TASK_LIST; dijadwalkan sesudah pemilik
menaikkan B-95 ke fase):

| Usulan | Isi | Ukuran | Butuh |
|---|---|---|---|
| T-n.1 | ADR teknis (§12) | S | KT-BP1–KT-BP9 dijawab |
| T-n.2 | Gerbang Plus, fakta "periode tertutup", ingatan + `BackupRegistry` | M | T-n.1, mesin B-94 |
| T-n.3 | Model baca buku (halaman 1–4) dengan uji kecocokan total (B-3, B-15) | M | T-n.1 |
| T-n.4 | Mesin templat Tanuki dan halaman 5 | M | T-n.3 |
| T-n.5 | Ritual dan kartu Beranda (slot, urutan, BP-13) | M | T-n.2, rupa |
| T-n.6 | Rapor dan sampul + stempel | L | T-n.3, rupa |
| T-n.7 | Rak Buku (segmen Riwayat) dan sakelar | M | T-n.2, rupa |
| T-n.7a | **Kartu Periode**: kartu Beranda, pratinjau dengan pilihan fakta, perender gambar di perangkat, lembar bagikan sistem, tautan toko dengan penanda sumber, ajakan Plus | M | T-n.1, rupa dan aset Tanuki |
| T-n.8 | Analitik §10, teks id/en, glosarium | S | T-n.7 |
| T-n.9 | Verifikasi perangkat S1–S7 | S | semua |

Pemetaan ke TASK_LIST (Fase 27, 14 Nov 2026): T-n.1 → T-27.1, T-n.2 → T-27.2,
T-n.3 → T-27.3, T-n.4 → T-27.4, T-n.5 → T-27.5, T-n.6 → T-27.6, T-n.7 →
T-27.7, T-n.7a → T-27.8, T-n.8 → T-27.10, T-n.9 → T-27.11; **T-27.9 baru:**
aset pose Tanuki.

Perlu rupa dari ui-ux-designer: Kartu Periode (rasio gambar, tata letak
dengan nominal opsional, pose Tanuki) dan pratinjaunya, kartu Beranda, lembar ritual,
sampul, halaman rapor, ekspresi Tanuki, dan Rak Buku.

## 16. Pertanyaan untuk pemilik

**Diputuskan pemilik 14 Nov 2026:** seluruh rekomendasi di bawah disetujui
(KT-BP1, 3–14), dengan tambahan: **versi rupa permainan** (bukan tenang;
BP-13 dan GAMIFICATION G-4 direvisi), **Rak Buku segmen ketiga Riwayat**
(KT-BP5), gambar kartu **4:5**, teks penjelas D2 memakai "Nominal mati secara
bawaan dan hanya ikut kalau kamu menyalakannya", stempel **diraih otomatis**
(cap di sampul hanya gerak), kilap dan rak stempel **hanya efek layar** (tidak
masuk model kartu), angka contoh D6 diabaikan, dan **aset pose Tanuki baru
dibuat** (T-27.9; sampai siap, kode memakai aset clay yang ada dengan nama
berkas tetap). Daftar di bawah dibiarkan sebagai catatan alasan.

- **KT-BP1 — Stempel B-94 tetap gratis?** Rekomendasi: **ya.** Stempel adalah
  satu-satunya mekanik retensi untuk pengguna Gratis sesudah rapor ringkas
  dihapus. Bagi Plus, stempel periode ikut tercetak di sampul. Bila stempel
  juga Plus, mesin B-94 tidak lagi melayani pengguna Gratis.
- **KT-BP2 — Kartu Periode untuk Gratis.** Diputuskan pemilik 12 Nov 2026:
  satu kartu yang bisa dibagikan sebagai jalur pertumbuhan. Rekomendasi
  bentuk: satu kartu per periode di Beranda, pratinjau dengan pilihan fakta,
  ajakan Plus satu baris di pratinjau (bukan di Beranda), tanpa hambatan
  untuk membagikan.
- **KT-BP3 — Kilas balik di tinjau awal bulan tetap gratis?** Rekomendasi:
  **ya.** Sudah dikirim ke pengguna; menariknya menjadi kemunduran. Buku
  menambah ritual, Tanuki, dan Rak Buku di atasnya.
- **KT-BP4 — Rapor dihitung langsung atau snapshot.** Rekomendasi:
  **langsung** (BP-4): angka selalu cocok dengan Analisis dan tidak ada data
  baru; yang disimpan hanya penanda "buku dibuka".
- **KT-BP5 — Pintu Rak Buku.** Rekomendasi: **segmen ketiga di Riwayat**
  (Daftar, Analisis, Buku), ditambah kartu Beranda di akhir periode. Akun
  hanya memuat sakelar. Ini mengubah arsitektur informasi.
- **KT-BP6 — Gerbang di paywall.** Rekomendasi: Buku Periode masuk pilar ⑤
  Tanuki Melapor sebagai pelengkap tiga janji (bukan janji baru) dan tidak
  mengubah harga.
- **KT-BP7 — Nama ritual.** Rekomendasi: **"Tutup buku"** dengan kalimat
  "Data tetap bisa kamu ubah kapan saja." Alternatif "Selesaikan periode"
  menghindari kesan mengunci tetapi kurang hangat.
- **KT-BP8 — Tipe tanuki (R2).** Rekomendasi: daftar kecil (Rapi, Pencatat
  Cepat, Perencana, Pengamat) dari cara mencatat, bukan dari nominal;
  keputusan daftar lengkap di R2.
- **KT-BP9 — Buku lama saat fitur dirilis.** Rekomendasi: periode yang
  sudah berakhir muncul di Rak Buku sebagai "Belum dibuka" untuk Plus;
  ajakan Tutup buku hanya untuk periode terakhir (BP-9).
- **KT-BP10 — Fakta bawaan di Kartu Periode.** Nominal boleh dibagikan
  (keputusan pemilik 12 Nov 2026). Rekomendasi: **jumlah catatan, rutin beres,
  dan stempel menyala; kategori terbesar dan ketiga nominal mati**, karena
  pengguna sebaiknya memutuskan sendiri apa yang dibuka ke orang lain dan
  pemasukan (gaji) paling sensitif. Alternatif: nominal menyala bawaan, kartu
  lebih menarik tetapi paling mudah membocorkan tanpa disadari.
- **KT-BP11 — Tautan dan pengukuran.** Rekomendasi: satu tautan Play Store
  umum dengan `referrer=utm_source%3Dperiod_card`, tanpa kode per pengguna.
  Engineer memastikan penanda terbaca Firebase tanpa data baru dan
  melaporkan bila kebijakan privasi atau Keamanan Data perlu diperbarui.
- **KT-BP12 — Kartu untuk Plus.** Rekomendasi: Plus mendapat kartu yang sama
  sebagai satu halaman buku dan, di R2, varian serta kartu geser. Jangan
  menyembunyikan Kartu Periode dari Plus.
- **KT-BP13 — Nominal di tempat lain.** Keputusan ini hanya untuk Kartu Periode.
  Rekomendasi: bagikan stempel (GAMIFICATION G-9), Rapor Tahunan (B-53), dan
  Ringkasan untuk pasangan (B-75) **tetap tanpa nominal** sampai pemilik
  memutuskan lain; Rapor Tahunan bisa mengikuti pola yang sama (nominal opsional)
  bila hasil Kartu Periode baik.
- **KT-BP14 — Pemasukan terpisah dari selisih.** Rekomendasi: tiga sakelar
  terpisah (Pemasukan, Pengeluaran, Selisih), karena membagikan selisih tidak
  membuka gaji dan sebaliknya.

## 17. Yang sengaja tidak dikerjakan

- Kunci atau penutupan buku secara akuntansi.
- Rapor AI generatif dan pengiriman data ke server untuk menyusun cerita.
- Skor, peringkat, perbandingan antarpengguna, atau penilaian belanja.
- Notifikasi dorong tentang buku atau "kamu belum menutup".
- Dokumen yang diklaim resmi.
