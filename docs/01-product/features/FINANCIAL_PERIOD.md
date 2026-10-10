# Periode keuangan: awal bulan yang mengikuti gajian

**Tanggal:** 10 Oktober 2026.
**Status:** Diputuskan pemilik 10 Okt 2026 (§12). Keputusan arsitekturnya
di [ADR-038](../../02-architecture/adr/0038-periode-keuangan-berriwayat-dan-peralihan.md)
(Accepted 10 Okt 2026); tugasnya Fase 18 di TASK_LIST.
**Berkaitan:** [ADR-035](../../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md)
§3.6 (bulan keuangan 1–28, sudah ada), [ADR-036](../../02-architecture/adr/0036-anggaran-rutin-dan-perkiraan-ke-depan.md)
§3.1–3.4 (patokan anggaran rutin), [PLAN_TAB_LAYOUT.md](PLAN_TAB_LAYOUT.md)
§4 (segmen Bulan ini), [FINANCIAL_ANALYSIS.md](FINANCIAL_ANALYSIS.md)
(Analisis memakai periode yang sama).

Dokumen ini merancang perilaku, alur, dan aturan. Rupa visual mengikuti
komponen yang ada; yang belum ada ditandai "perlu rupa dari pemilik".

## 1. Ringkasan keputusan

1. **Satu titik atur: tanggal mulai.** Periode selesai sehari sebelum
   tanggal mulai berikutnya. Tanggal selesai tidak bisa diatur bebas (bisa
   bolong, tumpang-tindih, atau panjangnya berubah-ubah).
2. **Mudah ditemukan dan terkait gajian.** Rentang periode di kepala Bulan
   ini bisa diketuk untuk mengaturnya; aplikasi menawarkannya saat pengguna
   membuat rutin pemasukan bulanan; pengaturan di Akun tetap ada.
3. **Pilihan "Hari terakhir bulan"** di samping tanggal 1–28.
4. **Gajian yang maju atau mundur beberapa hari tetap masuk periodenya.**
   Transaksi yang tertaut kemunculan rutin dihitung ke periode menurut
   tanggal kemunculannya (maksimal selisih 7 hari), setelah perilaku
   sekarang diverifikasi.
5. **Mengubah tanggal mulai tidak pernah memotong ulang periode lampau**
   (5a). Perubahan disimpan sebagai riwayat "berlaku sejak".
6. **Satu periode peralihan** (5b): periode berjalan dipendekkan atau
   diperpanjang ke batas baru terdekat dengan akhir lamanya.
7. **Anggaran rutin yang ikut tanggal lama ditawarkan ikut pindah** (5c);
   anggaran berjalan diregangkan atau dipendekkan ke periode peralihan.
8. **Periode peralihan diberi label dan tidak memicu peringatan palsu** (5d).
9. **Kartu Arus Beranda ikut bulan keuangan** (revisi FR-HOME-001), supaya
   Beranda, Rencana, dan Analisis menyebut angka yang sama.
10. Periode mingguan atau dua-mingguan tidak dibahas sekarang (keputusan
    pemilik: dilewati).

## 2. Masalah dan bukti

- Bulan keuangan 1–28 sudah ada sejak R1b, tetapi hanya di **Akun → Awal
  bulan keuangan**. Pemilik sendiri mengira periodenya masih tetap
  (10 Okt 2026). Pengaturan yang tidak ditemukan sama dengan tidak ada.
- Gajian tanggal 30/31 atau akhir bulan tidak bisa dipilih; yang paling
  dekat tanggal 28, meleset 2–3 hari.
- Gajian yang maju karena akhir pekan atau libur (25 jatuh Minggu, cair
  Jumat 23) membuat satu periode tampak bergaji dua kali dan periode
  berikutnya tanpa gaji, karena periode ditentukan tanggal transaksi
  (`month_plan.dart`).
- Mengubah tanggal mulai di tengah periode sekarang langsung memotong ulang
  semua periode dan menggeser anggaran rutin keluar dari periodenya. Rincian
  masalah P1–P7 di §6.

## 3. Alur pengguna

### F1. Mengatur dari Bulan ini

1. Rencana › Bulan ini → ketuk rentang periode di kepala ("25 Sep – 24 Okt"
   atau "Oktober").
2. Lembar **Awal bulan keuangan**: daftar "Tanggal 1" … "Tanggal 28",
   "Hari terakhir bulan"; terpilih yang aktif. Satu kalimat bantuan:
   "Biasanya tanggal gajian."
3. Pilih tanggal → bila berbeda dari yang aktif, lanjut ke F3.

Pengaturan di Akun membuka lembar yang sama.

### F2. Ditawarkan saat membuat rutin gajian

1. Pengguna menyimpan rutin **pemasukan** tiap bulan bertanggal D (mis. Gaji
   tiap tanggal 25), dan awal bulan keuangan masih bawaan (tanggal 1, belum
   pernah diubah) serta D ≠ 1.
2. Snackbar: "Mulai bulan keuanganmu tiap tanggal 25?" [Atur].
3. Atur → F3 dengan tanggal 25 terpilih. Diabaikan → tidak ditawarkan lagi
   untuk rutin yang sama.

Tidak pernah ditawarkan bila pengguna sudah pernah mengubah awal bulan
keuangan sendiri.

### F3. Pratinjau perubahan dan anggaran rutin

1. Lembar konfirmasi menyebut akibatnya sebelum disimpan:
   > Mulai tanggal 1
   > Periode ini jadi 25 Sep – 31 Okt (37 hari), lalu 1 – 30 Nov.
   > Periode sebelumnya tidak berubah.
2. Bila ada anggaran rutin yang patokannya sama dengan awal bulan keuangan
   lama, lembar yang sama menampilkan satu pilihan per anggaran, bawaan
   menyala:
   > [●] Anggaran Bulanan juga mulai tanggal 1
   Anggaran berpatokan lain (mis. kartu kredit tanggal 15) tidak ditampilkan
   dan tidak berubah.
3. [Simpan] → riwayat perubahan tersimpan, anggaran terpilih dipindah
   (aturan P-7), Rencana dan Beranda segar.
4. Kartu tinjau awal bulan muncul sekali untuk periode peralihan dengan
   penjelasan (aturan P-9), termasuk langkah "anggaran rutin sesuai?" untuk
   meninjau nominal anggaran yang diregangkan.

[Batal] tidak mengubah apa pun.

### Cabang

| Keadaan | Perilaku |
|---|---|
| Memilih tanggal yang sama dengan yang aktif | Lembar tertutup, tidak ada perubahan |
| Diubah lagi sebelum periode peralihan selesai | Periode peralihan dihitung ulang dari periode berjalan saat ini; riwayat menyimpan entri terakhir saja untuk tanggal berlaku yang sama |
| Belum ada transaksi sama sekali | Tanpa periode peralihan: periode baru berlaku sejak periode berjalan dimulai (tidak ada yang perlu dijaga) |
| Tanpa anggaran rutin | Langkah 2 F3 tidak tampil |
| Anggaran rutin dipilih tidak ikut | Anggaran itu tetap di tanggal lamanya; lembar menulis satu kalimat: "Anggaran Bulanan tetap mulai tanggal 25." |

## 4. Aturan

- **P-1 Batas periode.** Tanggal mulai `s` ∈ {1, …, 28, hari terakhir}.
  Periode berisi `awal ≤ tanggal < awal berikutnya`. Untuk "hari terakhir",
  awal tiap periode adalah hari terakhir bulan itu (31 Okt, 30 Nov, 31 Des,
  28/29 Feb).
- **P-2 Riwayat.** Pengaturan disimpan sebagai daftar `(berlakuSejak,
  tanggalMulai)`. Periode yang **sudah selesai** tidak pernah dipotong ulang.
  Pengaturan lama (satu angka) dimigrasi menjadi satu entri yang berlaku
  sejak awal.
- **P-3 Periode peralihan.** Saat tanggal mulai diubah pada hari `T` dengan
  periode berjalan `[a, b)`: pilih batas baru `c` (tanggal bertanggal mulai
  baru) yang paling dekat dengan `b` dan lebih besar dari `a`; bila dua
  kandidat sama dekat, pilih yang lebih akhir.
  - Bila `c > T`: periode berjalan menjadi `[a, c)` (periode peralihan),
    lalu periode baru mulai `c`.
  - Bila `c ≤ T`: `[a, c)` menjadi periode peralihan yang sudah selesai, dan
    periode berjalan `[c, batas baru berikutnya)`.
  - Panjang periode peralihan selalu antara 13 dan 46 hari.
- **P-4 Atribusi periode transaksi.** Untuk menghitung isi periode (Beranda,
  Rencana, Analisis, penyaring periode Riwayat), tanggal periode sebuah
  transaksi adalah `recurrence.occurrenceDate` bila transaksi tertaut
  kemunculan rutin **dan** selisihnya dengan `date` ≤ 7 hari; selain itu
  `date`. Saldo, perkiraan saldo harian, dan urutan Riwayat tetap memakai
  `date`. Ini selaras dengan ADR-036 §3.4 yang sudah menyelesaikan pos
  anggaran menurut tanggal kemunculan.
- **P-5 Rencana memasukkan anggaran** ke periode yang memuat tanggal
  mulainya (perilaku sekarang, `budgetsStartingIn`), tidak berubah.
- **P-6 Anggaran rutin tidak ikut otomatis.** Patokan anggaran rutin tetap
  milik anggarannya (ADR-036 §3.1). Hanya yang dipilih di F3 yang dipindah.
- **P-7 Memindah anggaran rutin.** Untuk anggaran rutin terpilih:
  - Anggaran periode berjalan mendapat `endDate` = akhir periode peralihan
    (diregangkan atau dipendekkan), nominal tiap pos tetap.
  - Patokan templatnya menjadi tanggal mulai baru; periode berikutnya lahir
    di awal periode baru, tanpa celah dan tanpa tumpang-tindih.
  - Bila dipendekkan dan sudah ada transaksi tertaut pos yang tanggalnya
    jatuh sesudah akhir baru, tautannya dipindah ke pos bertemplat sama di
    periode berikutnya saat periode itu lahir; sampai lahir, transaksi itu
    tanpa pos. Saldo tidak berubah.
- **P-8 Periode peralihan di Rencana.** Berlabel "Periode peralihan · 37
  hari". Bila uang nganggurnya negatif karena rentang ini tanpa gajian,
  tidak ada ikon atau warna peringatan; gantinya satu kalimat "Rentang ini
  tidak memuat gajian." Peringatan berbasis saldo (W1 siapkan dana, titik
  terendah negatif) tetap berlaku.
- **P-9 Tinjau dan akurasi.** Kartu tinjau awal bulan tampil sekali untuk
  periode peralihan dengan kalimat "Awal bulan keuanganmu kini tanggal 1.
  Periode ini 25 Sep – 31 Okt." Akurasi perkiraan (W9) tidak dihitung untuk
  periode peralihan.
- **P-10 Pembanding.** Periode peralihan tidak dipakai sebagai pembanding
  rata-rata di Analisis (FINANCIAL_ANALYSIS B-6) dan kilas balik W10 menyebut
  panjangnya.
- **P-11 Beranda.** Kartu Arus memakai periode keuangan berjalan. Judulnya
  nama bulan bila tanggal mulai 1, selain itu rentangnya ("Arus 25 Sep –
  24 Okt").

## 5. Contoh

Gajian tiap tanggal 25. Anggaran rutin "Bulanan" Rp3.068.500 berpatokan
25, dompet BCA.

**A. Dari 25 ke 1, diubah 10 Okt.** Periode berjalan `[25 Sep, 25 Okt)`.
Kandidat batas baru: 1 Okt (24 hari dari 25 Okt) dan 1 Nov (7 hari) → `c` =
1 Nov > 10 Okt. Periode peralihan **25 Sep – 31 Okt (37 hari)**, memuat satu
gajian (25 Sep). Anggaran Bulanan berjalan diregangkan ke 31 Okt, berikutnya
lahir 1 Nov. Periode September 25 Agt – 24 Sep tidak berubah.

**B. Dari 1 ke 25, diubah 10 Okt.** Periode berjalan `[1 Okt, 1 Nov)`.
Kandidat: 25 Okt (7 hari dari 1 Nov) dan 25 Nov (24 hari) → `c` = 25 Okt >
10 Okt. Periode peralihan **1 – 24 Okt (24 hari)**, tanpa gajian → uang
nganggur negatif tanpa peringatan, dengan kalimat P-8. Periode berikutnya
25 Okt – 24 Nov memuat gaji 25 Okt.

**C. Dari 1 ke 25, diubah 28 Okt.** Periode berjalan `[1 Okt, 1 Nov)`, `c` =
25 Okt ≤ 28 Okt. Periode peralihan **1 – 24 Okt** sudah selesai; periode
berjalan **25 Okt – 24 Nov**. Pengeluaran 25–28 Okt yang tertaut pos Bulanan
lama dipindah ke pos Bulanan periode 25 Okt bila anggarannya ikut pindah
(P-7).

**D. Gaji maju (P-4).** Tanggal mulai 25, rutin Gaji tiap 25. Kemunculan
25 Okt 2026 (Minggu) dicatat sebagai transaksi bertanggal Jumat 23 Okt dan
tertaut kemunculan 25 Okt. Selisih 2 hari ≤ 7 → dihitung ke periode 25 Okt –
24 Nov. Saldo BCA sudah naik sejak 23 Okt.

## 6. Masalah yang dicegah (dari pembahasan 10 Okt 2026)

| # | Tanpa aturan ini | Dicegah oleh |
|---|---|---|
| P1 | Anggaran yang sudah lahir terhitung ke periode lain; uang nganggur naik palsu Rp3.068.500 | P-3, P-7 |
| P2 | Anggaran rutin bergeser dari periode setiap bulan, permanen | P-7 |
| P3 | Celah 25–31 Okt tanpa pos; pengeluaran jatuh ke "di luar rencana" | P-7 (`endDate`) |
| P4 | Kilas balik dan Analisis bulan lalu berubah angka | P-2 |
| P5 | Peringatan uang nganggur negatif yang menyesatkan | P-8 |
| P6 | Tinjau awal bulan muncul tanpa penjelasan | P-9 |
| P7 | Pembanding rata-rata tercemar periode beda panjang | P-10 |

## 7. Kata dan kalimat (id / en)

| Kunci | id | en |
|---|---|---|
| `plan.financialMonthLastDay` | Hari terakhir bulan | Last day of the month |
| `plan.financialMonthHint` | Biasanya tanggal gajian. | Usually your payday. |
| `plan.financialMonthOffer` | Mulai bulan keuanganmu tiap tanggal {day}? | Start your financial month on day {day}? |
| `plan.financialMonthOfferAction` | Atur | Set |
| `plan.financialMonthPreviewTitle` | Mulai tanggal {day} | Start on day {day} |
| `plan.financialMonthPreviewTransition` | Periode ini jadi {range} ({days} hari), lalu {next}. | This period becomes {range} ({days} days), then {next}. |
| `plan.financialMonthPreviewPast` | Periode sebelumnya tidak berubah. | Earlier periods stay the same. |
| `plan.financialMonthMoveBudget` | {budget} juga mulai tanggal {day} | {budget} also starts on day {day} |
| `plan.financialMonthKeepBudget` | {budget} tetap mulai tanggal {day}. | {budget} still starts on day {day}. |
| `plan.transitionLabel` | Periode peralihan · {days} hari | Transition period · {days} days |
| `plan.transitionNoPayday` | Rentang ini tidak memuat gajian. | This range has no payday. |
| `plan.transitionReview` | Awal bulan keuanganmu kini tanggal {day}. Periode ini {range}. | Your financial month now starts on day {day}. This period is {range}. |
| `home.flowRangeTitle` | Arus {range} | Flow {range} |

## 8. Dampak ke domain dan kode

- `core/financial_month/`: preferensi menjadi riwayat (P-2) dengan migrasi;
  `financialMonthOf` menerima riwayat; nilai "hari terakhir"; fungsi
  periode peralihan (P-3).
- `Budget.endDate` opsional (null = `period.endFrom(startDate)`), dan
  patokan templat berjadwal boleh "hari terakhir" (ADR-038, merevisi
  ADR-036 §3.1).
- Satu fungsi atribusi periode (P-4) dipakai `monthPlan`, Beranda, Analisis,
  dan penyaring periode Riwayat.
- `month_review` dan `forecast_snapshots` tetap berkunci `monthStart`;
  periode peralihan cukup ditandai.
- Analitik: `financial_month_changed{source: plan|account|offer,
  day, moved_budgets}` tanpa nominal.
- Fase 18 di TASK_LIST.

## 9. Perlu rupa dari pemilik

1. Kepala Bulan ini dengan rentang yang bisa diketuk.
2. Lembar pratinjau F3 (rentang peralihan + sakelar per anggaran).
3. Label "Periode peralihan" di Rencana, Beranda, dan Analisis.

Sampai rupanya ada, engineer menyusun dari `AppListRow`, `AppSwitchRow`, dan
`AppBadge` yang ada.

## 10. Kasus tepi

| Kasus | Perilaku |
|---|---|
| Tanggal mulai 31 tidak ada di bulan itu | Hanya "hari terakhir"; tanggal 29–31 tidak ditawarkan |
| "Hari terakhir" dan Februari | Periode 31 Jan – 27 Feb, lalu 28 Feb – 30 Mar (tahun biasa) |
| Transaksi tertaut kemunculan, selisih 10 hari | Dihitung menurut `date` (di luar batas 7 hari) |
| Rutin mingguan tertaut | P-4 berlaku sama |
| Anggaran mingguan | Tidak ditawarkan pindah; tidak terpengaruh |
| Anggaran bulanan bukan rutin | Tidak ditawarkan pindah; tetap di periode tanggal mulainya |

## 11. Yang sengaja tidak dikerjakan

- Tanggal selesai bebas, periode lebih dari atau kurang dari sebulan selain
  periode peralihan.
- Periode mingguan atau dua-mingguan (dilewati pemilik 10 Okt 2026).
- Periode mengikuti tanggal gaji yang tercatat secara otomatis (periode
  "bergerak"). P-4 sudah menangani gajian yang maju beberapa hari.
- Nominal anggaran diprorata untuk periode peralihan; pengguna meninjaunya
  di kartu tinjau.

## 12. Keputusan pemilik (10 Okt 2026)

| # | Keputusan |
|---|---|
| 1 | Hanya tanggal mulai yang diatur |
| 2 | Pintu di kepala Bulan ini, tawaran saat rutin gajian, Akun tetap |
| 3 | Tambah "Hari terakhir bulan" |
| 4 | Atribusi periode menurut tanggal kemunculan rutin, setelah verifikasi |
| 5a–5d | Riwayat tanpa potong ulang, satu periode peralihan, tawarkan pindah anggaran rutin dengan `Budget.endDate`, label peralihan tanpa peringatan palsu |
| 6 | Kartu Arus Beranda ikut bulan keuangan |
| 7 | Periode mingguan: dilewati |
