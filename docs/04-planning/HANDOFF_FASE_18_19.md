# Serah terima Fase 18–19: periode keuangan dan Analisis

**Tanggal:** 10 Oktober 2026.
**Untuk:** designer (rupa visual) dan agen `flutter-engineer` (kode).
**Dari:** product owner, atas keputusan pemilik 10 Okt 2026.
**Status:** siap dikerjakan. ADR-038 Accepted.

Dokumen ini hanya peta kerja. Sumber kebenarannya tetap:

| Hal | Berkas |
|---|---|
| Perilaku periode keuangan | [FINANCIAL_PERIOD.md](../01-product/features/FINANCIAL_PERIOD.md) (P-1–P-11, contoh A–D) |
| Perilaku Analisis | [FINANCIAL_ANALYSIS.md](../01-product/features/FINANCIAL_ANALYSIS.md) (B-1–B-16, contoh §10) |
| Model data | [ADR-038](../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md) |
| Kebutuhan | PRD FR-HOME-001, FR-PLN-004/006/007, FR-ANL-001–006; US-25–US-29 |
| Tugas dan verifikasi | [TASK_LIST.md](TASK_LIST.md) Fase 18 (T-18.1–18.9) dan Fase 19 (T-19.1–19.7) |
| Bahasa visual | [ADR-034](../02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md), design system dan prototipe pemilik (tabel Pencarian cepat `.claude/CLAUDE.md`), salinan di `docs/03-design/` |

Bila dokumen ini berbeda dari sumber di atas, sumber yang menang; laporkan
selisihnya ke product owner.

## 0. Ringkasan

**Periode keuangan (Fase 18).** "Bulan" di aplikasi dimulai di tanggal
gajian pengguna (1–28 atau hari terakhir bulan). Mengubahnya tidak pernah
mengubah bulan-bulan lalu; periode berjalan menjadi satu **periode
peralihan** (13–46 hari); anggaran rutin bisa ikut pindah tanpa celah;
gaji yang cair beberapa hari lebih awal tetap masuk periodenya. Kartu Arus
Beranda ikut periode keuangan.

**Analisis (Fase 19).** Segmen baru **Analisis** di tab Riwayat: ke mana
uang pergi per kategori, dibanding rata-rata periode sebelumnya, tren enam
periode, rincian kategori sampai transaksinya, dan jalan membetulkan
transaksi Tanpa kategori. Hanya membaca, tanpa perkiraan, nada netral.

**Siapa menunggu siapa:**

- **Bisa mulai sekarang, tanpa desain:** T-18.1 → T-18.2 → T-18.3 → T-18.4
  (judul kartu Arus dengan komponen yang ada), lalu T-18.5; T-19.1 → T-19.2;
  T-19.3.
- **Menunggu rupa D1–D3:** T-18.6 (lalu T-18.7), T-18.8.
- **Menunggu rupa A1–A5:** T-19.4, T-19.5, T-19.6.
- **Penutup:** T-18.9 (akhir Fase 18), T-19.7 (akhir Fase 19).

Jalur domain engineer (T-18.1–18.5, T-19.1–19.3) bisa berjalan **sekarang**,
paralel dengan pekerjaan designer. Tugas layar menunggu rupanya (§1.3).

## 1. Untuk designer

### 1.1 Batas pekerjaan

Alur, urutan informasi, keadaan, aturan, dan teks sudah diputuskan. Yang
dibutuhkan darimu adalah **rupa**: bentuk, tata letak, komponen, warna lewat
token, dan grafik. Bila rupa yang kamu pilih menuntut perubahan perilaku
(mis. informasi dipindah ke layar lain, langkah ditambah), tulis sebagai
pertanyaan untuk product owner, jangan diputuskan di prototipe.

### 1.2 Aturan yang mengikat rupa

1. **Nada netral.** Kategori yang "lebih tinggi dari biasanya" tidak memakai
   warna peringatan, ikon peringatan, atau merah. Merah hanya untuk uang
   keluar (ADR-034), bukan status. Tanpa skor, tanpa label "boros".
2. **Peringatan hanya untuk risiko berbasis saldo** (siapkan dana, titik
   terendah negatif). Uang nganggur negatif di periode peralihan **bukan**
   peringatan.
3. **Nyata berbeda dari perkiraan.** Analisis tidak punya angka perkiraan;
   jangan memakai bahasa visual perkiraan (`≈`, bingkai putus-putus) di
   Analisis.
4. **Transfer bukan pemasukan atau pengeluaran.** Di Analisis ia hanya baris
   informasi, tidak pernah bagian dari porsi atau total.
5. **Nominal ringkas** (`Rp11,7 jt`) hanya di grafik dan ruang yang benar-benar
   sempit; daftar memakai nominal penuh (`Rp3.068.500`).
6. **Nominal bisa disembunyikan** (`AmountVisibility`): semua nominal
   tertutup, persen dan bentuk porsi tetap tampil. Rancang keadaan ini.
7. **360dp, id dan en, terang dan gelap.** Label en biasanya lebih panjang
   ("Uncategorized", "Transition period · 37 days").
8. **Satu banner per layar**; teks mengikuti `docs/03-design/design-system/writing.md`.

### 1.3 Yang perlu dirancang

Data contoh untuk mockup supaya angka antarlayar cocok:
FINANCIAL_ANALYSIS §10 (September 2026: pengeluaran Rp11.420.700, Belanja
27%, Makan disorot +Rp295.000) dan FINANCIAL_PERIOD §5 contoh A (periode
peralihan 25 Sep – 31 Okt, 37 hari) dan B (1 – 24 Okt, 24 hari, tanpa
gajian).

| ID | Apa | Letak | Informasi wajib, urut prioritas | Keadaan | Acuan | Dibutuhkan tugas |
|---|---|---|---|---|---|---|
| **D1** | Kepala periode Bulan ini yang bisa diketuk | Rencana › Bulan ini | Nama bulan bila awal tanggal 1, selain itu rentang ("25 Sep – 24 Okt"); tanda bisa diketuk | normal, periode peralihan | `prototype/RencanaBulanIni.dc.html` | T-18.6 |
| **D2** | Lembar **Awal bulan keuangan** + pratinjau perubahan | Lembar dari D1 dan dari Akun | (1) daftar Tanggal 1…28 + Hari terakhir bulan, terpilih yang aktif, bantuan "Biasanya tanggal gajian." (2) pratinjau: "Mulai tanggal 1", "Periode ini jadi 25 Sep – 31 Okt (37 hari), lalu 1 – 30 Nov.", "Periode sebelumnya tidak berubah." (3) satu sakelar per anggaran rutin: "Anggaran Bulanan juga mulai tanggal 1" (bawaan menyala) (4) Simpan / Batal | tanpa anggaran rutin, beberapa anggaran rutin, sakelar dimatikan ("Anggaran Bulanan tetap mulai tanggal 25.") | FINANCIAL_PERIOD F1, F3, §7 | T-18.6 |
| **D3** | Penanda **periode peralihan** | Kepala Bulan ini, kartu uang nganggur, kartu Arus Beranda, kepala Analisis | "Periode peralihan · 37 hari"; di kartu uang nganggur bila negatif: kalimat "Rentang ini tidak memuat gajian." tanpa warna atau ikon peringatan | peralihan berjalan, peralihan lampau di Analisis | FINANCIAL_PERIOD P-8, P-11 | T-18.4, T-18.8, T-19.4 |
| **D4** | Kartu Arus Beranda sebagai pintu | Beranda | Judul "Arus Oktober" atau "Arus 25 Sep – 24 Okt"; seluruh kartu (atau tautan) membuka Analisis | awal 1, awal ≠ 1, peralihan | prototipe Beranda | T-18.4, T-19.6 |
| **A1** | Segmen `Daftar \| Analisis` | Kepala tab Riwayat | Dua segmen; segmen terakhir diingat | — | `prototype/Riwayat.dc.html`; pola sub-tab Rencana (`AppSubTabs`, KT-L7) | T-19.4 |
| **A2** | Layar **Analisis** satu periode | Riwayat › Analisis | (1) periode + pemilih ‹ › (tidak melewati periode berjalan), penyaring dompet, pilihan Pengeluaran/Pemasukan (2) total + pembanding "dibanding rata-rata 3 bulan" (3) 0–3 sorotan: "Makan Rp295.000 lebih tinggi dari rata-rata 3 bulan" (4) daftar kategori: ikon, nama, nominal, persen, pembanding; lima teratas, "Lainnya (3 kategori)" bisa dibuka, "Tanpa kategori" + **Beri kategori** paling bawah (5) baris info transfer "Dipindahkan antardompet Rp1.000.000 · tidak mengurangi total uangmu" (6) tren enam periode: pemasukan, pengeluaran, selisih (bisa negatif), periode terpilih ditandai, bisa diketuk | lihat A4 | FINANCIAL_ANALYSIS §8, §12 | T-19.4 |
| **A3** | **Rincian kategori** | Dari baris kategori atau sorotan | (1) nama, periode, total, persen dari total jenisnya (2) pembanding (3) tren enam periode kategori ini (4) paling banyak 20 transaksi + **Lihat semua transaksi**; penanda "diarsipkan" bila kategori diarsipkan | kategori "baru bulan ini" (tanpa persen pembanding) | FINANCIAL_ANALYSIS §8 | T-19.5 |
| **A4** | Keadaan Analisis | A2 | belum ada transaksi ("Belum ada yang bisa dianalisis" + Catat transaksi); periode tanpa pengeluaran; baru satu bulan data (tanpa pembanding, tanpa tren); memuat; galat; nominal disembunyikan; periode peralihan (tanpa pembanding dan sorotan, berlabel D3); satu dompet terpilih (baris "Transfer masuk" dan "Transfer keluar") | — | FINANCIAL_ANALYSIS §7 Cabang | T-19.4 |
| **A5** | Tautan "Lihat rincian September" | Lembar kilas balik di kartu tinjau awal bulan | satu tautan di ujung lembar | — | `month_review_card.dart` (lembar W10) | T-19.6 |

Tidak perlu dirancang: snackbar tawaran "Mulai bulan keuanganmu tiap tanggal
25? [Atur]" (pola snackbar yang ada).

**Pertanyaan rupa yang terbuka untukmu:**

1. Bentuk porsi kategori: bilah di tiap baris, satu bilah bertumpuk, cincin,
   atau lainnya. Syarat: terbaca tanpa warna (ada persen), 360dp, sembilan
   kategori dengan satu di bawah 1%.
2. Bentuk tren enam periode dengan tiga besaran, selisih bisa negatif, dan
   periode peralihan yang panjangnya beda.
3. Apakah pemilih periode Analisis (‹ ›, ke belakang) perlu terlihat
   sekeluarga dengan chip bulan Rencana (ke depan) tanpa membingungkan
   arahnya.

### 1.4 Cara menyerahkan

1. Perbarui artefak design system dan prototipe pemilik (komponen baru di
   design system, layar di prototipe; Analisis boleh prototipe baru).
2. Tulis di catatan serah terima: ID mana yang selesai (D1…A5), layar atau
   komponen yang berubah, dan selisih dari §1.3 bila ada.
3. Engineer menyalin perubahan ke `docs/03-design/` lewat skill
   `tanukonomy-ui` saat mengerjakan tugasnya.

## 2. Untuk flutter-engineer

### 2.1 Sebelum mulai

- Baca `.claude/AGENT_CONTEXT.md`, entri tugas di TASK_LIST (cari ID-nya),
  dan bagian dokumen fitur yang dirujuk tugas itu. Baris "Buka" di tugas
  menyebut berkas yang cukup dibaca.
- Branch per fase: `claude/periode-keuangan-fase-18`, lalu
  `claude/analisis-fase-19` dari Fase 18. Satu commit per tugas.
- Tutup tiap tugas dengan `flutter analyze` tanpa isu dan seluruh uji lulus,
  centang di TASK_LIST, isi hasilnya, naikkan hitungan di Ringkasan progres.

### 2.2 Urutan kerja

| Urutan | Tugas | Isi singkat | Bergantung pada | Desain | Mulai dari |
|---|---|---|---|---|---|
| 1 | T-18.1 | Uji karakterisasi gajian maju dan tautan pos, tanpa mengubah perilaku | — | — | `shared/recurring/domain/month_plan.dart` |
| 2 | T-18.2 | `FinancialMonthSchedule`, `lastDay`, `financialPeriodOf`, migrasi | T-18.1 | — | `core/financial_month/` |
| 3 | T-18.3 | `periodDateOf` di `monthPlan` | T-18.2 | — | `shared/transaction/`, `month_plan.dart` |
| 4 | T-18.4 | Kartu Arus Beranda ikut periode keuangan | T-18.3 | D3, D4 (judul saja; boleh komponen yang ada) | `features/home/` |
| 5 | T-18.5 | `Budget.endDate`, patokan `lastDay`, `AlignRecurringBudgets` | T-18.2 | — | `features/budget/domain/entities/budget_schedule.dart` |
| 6 | T-18.6 | Lembar awal bulan + pratinjau + sakelar anggaran | T-18.2, T-18.5 | D1, D2 (boleh mulai dengan komponen yang ada, catat selisih) | `features/account/presentation/widgets/financial_month_setting.dart` |
| 7 | T-18.7 | Tawaran saat simpan rutin pemasukan bulanan | T-18.6 | — | alur simpan rutin |
| 8 | T-18.8 | Periode peralihan di Rencana | T-18.2 | D3 | `features/plan/presentation/` |
| 9 | T-18.9 | Analitik + verifikasi emulator Fase 18 | semua di atas | — | `core/foundation/analytics/` |
| 10 | T-19.1 | Domain ringkasan periode per kategori | T-18.2, T-18.3 | — | fitur baru, lihat §2.4 |
| 11 | T-19.2 | Pembanding, sorotan, tren | T-19.1 | — | idem |
| 12 | T-19.3 | Penyaring Riwayat Tanpa kategori + rentang periode | T-18.2 | — | `features/transaction/` |
| 13 | T-19.4 | Segmen dan layar Analisis | T-19.1, T-19.2 | **A1, A2, A4 wajib** | skill `tanukonomy-ui` |
| 14 | T-19.5 | Rincian kategori | T-19.3, T-19.4 | **A3 wajib** | idem |
| 15 | T-19.6 | Pintu dari Beranda dan kilas balik | T-18.4, T-19.4 | D4, A5 | `features/home/`, `features/plan/` |
| 16 | T-19.7 | Analitik + verifikasi emulator Fase 19 | semua di atas | — | — |

Tugas 1–3, 5, 10–12 tidak menunggu desain.

### 2.3 Jebakan yang paling mungkin

1. **Periode lampau tidak boleh berubah.** Jangan menghitung periode dengan
   `DateTime(y, m, startDay)`; selalu lewat `financialPeriodOf(date,
   schedule)`.
2. **`periodDateOf` hanya untuk keanggotaan periode** (Beranda, `monthPlan`,
   Analisis, penyaring periode Riwayat). Saldo, perkiraan harian, partisi
   `transaction/YYYY-MM`, dan validasi KT-1 tetap memakai `date`.
3. **Jangan menulis ulang `startDate` anggaran yang sudah lahir.** Pakai
   `endDate`. Anggaran berpatokan lain (mis. 15) tidak disentuh. Naikkan
   `schemaVersion`.
4. **Saldo tidak pernah berubah** oleh perubahan awal bulan atau pemindahan
   anggaran: uji dengan `recomputeWalletBalances()`.
5. **Transfer** tidak masuk total atau persen di Analisis, termasuk yang
   tertaut pos tabungan; di Rencana ia tetap "anggaran terpakai" (B-15).
6. **Pemasukan freelance** dibuat tanpa `categoryId`
   (`receive_freelance_payment.dart`) dan tidak bisa disunting: kelompokkan
   sebagai Freelance, jangan masuk Tanpa kategori.
7. **Beranda tidak boleh membaca enam bulan** (NFR-PERF-002); pintu ke
   Analisis hanya navigasi.
8. **Batas arsitektur** (ADR-030): `core/` tidak mengimpor fitur; Analisis
   membuka Riwayat tersaring lewat kunci rute; layar segar lewat
   `LedgerChanges`; Analisis tidak memancarkannya (B-13).
9. **Teks** lewat i18n dengan kunci di FINANCIAL_PERIOD §7 dan
   FINANCIAL_ANALYSIS §12; tambahkan "Analisis" dan "Tanpa kategori" ke
   glosarium `writing.md` lebih dulu (dijaga
   `test/core/i18n/translations_test.dart`). Nominal lewat
   `AppMoneyText`/`AppMoneyFormatter`.
10. **Uang `int` sen**; persen dibulatkan setengah ke atas hanya saat tampil;
    jumlah persen tidak dipaksa 100.

### 2.4 Usulan tempat kode Analisis

Fitur baru `lib/features/analysis/` (domain fungsi murni, bloc, layar),
dipasang sebagai segmen di `features/transaction` lewat kunci rute. Bila
fungsi ringkasan ternyata dibutuhkan fitur lain (mis. Beranda R2), pindahkan
ke `shared/` mengikuti ambang ADR-0009. Keputusan akhirnya milik engineer;
catat di entri T-19.1.

### 2.5 Data uji emas

| Sumber | Yang harus lulus persis |
|---|---|
| FINANCIAL_PERIOD §5 A | 25→1 pada 10 Okt: peralihan 25 Sep – 31 Okt (37 hari), anggaran Bulanan diregangkan, berikutnya lahir 1 Nov |
| FINANCIAL_PERIOD §5 B | 1→25 pada 10 Okt: peralihan 1 – 24 Okt (24 hari), tanpa gajian, tanpa peringatan |
| FINANCIAL_PERIOD §5 C | 1→25 pada 28 Okt: periode berjalan 25 Okt – 24 Nov, tautan pos 25–28 Okt dipindah |
| FINANCIAL_PERIOD §5 D | Gaji 23 Okt tertaut kemunculan 25 Okt masuk periode 25 Okt |
| FINANCIAL_PERIOD P-3 | Panjang peralihan 13–46 hari untuk semua pasangan tanggal 2026–2028 |
| FINANCIAL_ANALYSIS §10 | Pengeluaran Rp11.420.700; pemasukan Rp14.615.438; selisih Rp3.194.738; persen tampil 27/26/17/11/7/12/1; Lainnya 12% (bukan 13%); Makan disorot +Rp295.000, Belanja tidak; bulan berjalan +Rp180.000 |
| FINANCIAL_ANALYSIS B-15 | Contoh §10 + transfer Tabungan Rp1.000.000 tertaut pos: total Analisis = rutin tercatat + anggaran terpakai tanpa transfer + di luar rencana |

### 2.6 Berhenti dan lapor ke product owner bila

- Hasil T-18.1 bertentangan dengan FINANCIAL_PERIOD P-4 (mis. validasi KT-1
  menolak tautan pos menurut tanggal kemunculan).
- Rekonsiliasi B-15 tidak bisa cocok dengan `monthPlan` tanpa mengubah
  definisi Rencana.
- Desain yang diterima menuntut perilaku yang tidak ada di dokumen fitur.
- Layar butuh pola yang belum ada di design system (ADR-034): susun dari
  komponen yang ada, lalu laporkan.

### 2.7 Selesai kalau

- **Fase 18:** contoh A–D lulus persis; tidak ada celah atau tumpang-tindih
  anggaran rutin sesudah dipindah; saldo tidak berubah; Beranda dan Rencana
  menyebut angka periode yang sama; verifikasi emulator T-18.9 tercatat.
- **Fase 19:** contoh §10 lulus persis dalam sen; total Analisis = kartu Arus
  Beranda dan cocok dengan Rencana (B-15); keadaan A4 teruji di kedua bahasa
  dan 360dp; Beranda tidak melambat; verifikasi emulator T-19.7 tercatat.

## 3. Titik temu designer dan engineer

| Kapan | Apa |
|---|---|
| Sekarang | Engineer mengerjakan jalur domain (T-18.1–18.5, T-19.1–19.3; T-18.4 dengan komponen yang ada). Designer mengerjakan D1–D4 lebih dulu, lalu A1–A5. |
| D1–D4 selesai | Engineer menyelesaikan T-18.6, T-18.8 dan menyelaraskan judul T-18.4 dengan rupa. |
| A1–A5 selesai | Engineer mengerjakan T-19.4–T-19.6. |
| Selisih rupa vs perilaku | Diputuskan product owner, dicatat di dokumen fitur, bukan di kode atau prototipe saja. |
