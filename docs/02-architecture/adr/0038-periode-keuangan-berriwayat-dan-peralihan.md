# Periode keuangan berriwayat, periode peralihan, dan atribusi periode

## 1. Metadata

- **Decision ID:** ADR-038
- **Tanggal:** 2026-10-10
- **Fase roadmap:** Fase 18
- **Status:** Accepted (pemilik, 2026-10-10)
- **Cakupan:** Global: `core/financial_month`, fitur `budget`, `plan`, `home`,
  `transaction` (dan Analisis, Fase 19)

## 2. Konteks

ADR-035 §3.6 menyimpan awal bulan keuangan sebagai satu angka 1–28
(`settings/financial_month_start`). ADR-036 §3.1 memberi anggaran rutin
patokan tanggal sendiri, dengan akhir periode yang selalu diturunkan
(`BudgetPeriod.endFrom`). Rencana memasukkan anggaran ke periode yang memuat
tanggal mulainya (`PlanBudgetSource.budgetsStartingIn`) dan menghitung isi
periode menurut `Transaction.date` (`monthPlan`).

Pembahasan pemilik 10 Okt 2026
([FINANCIAL_PERIOD.md](../../01-product/features/FINANCIAL_PERIOD.md) §6)
menemukan bahwa mengubah awal bulan keuangan di tengah periode:

- memotong ulang semua periode lampau, sehingga kilas balik, snapshot
  perkiraan, dan Analisis bulan lalu berubah angka;
- menggeser anggaran rutin yang sudah lahir ke periode lain (uang nganggur
  naik palsu sebesar nominal anggaran) dan membuat pergeseran itu permanen;
- tidak bisa ditambal dengan memindah patokan anggaran, karena akhir
  periode anggaran tidak bisa dipendekkan atau diperpanjang (celah tanpa
  pos).

Selain itu gajian yang maju beberapa hari (akhir pekan, libur) membuat satu
periode bergaji dua kali, dan pengguna yang gajian akhir bulan tidak punya
pilihan yang tepat.

## 3. Keputusan

Tanukonomy menyimpan awal bulan keuangan sebagai **riwayat berlaku-sejak**,
membentuk **satu periode peralihan** saat diubah, memberi anggaran **akhir
periode opsional**, dan menghitung isi periode memakai **tanggal periode**
transaksi.

1. **Riwayat.** `FinancialMonthSchedule` = daftar terurut `(effectiveFrom:
   DateTime, startDay: FinancialMonthStart)`, `FinancialMonthStart` ∈
   {1–28, `lastDay`}. Disimpan di `settings/financial_month_schedule` dengan
   `schemaVersion`. Preferensi lama dimigrasi menjadi satu entri
   `effectiveFrom` = tanggal minimum. Periode yang sudah selesai tidak pernah
   berubah.
2. **Periode peralihan.** Mengubah `startDay` pada hari `T` dengan periode
   berjalan `[a, b)` menambah entri `effectiveFrom = c`, dengan `c` batas
   baru yang paling dekat ke `b` dan `> a` (seri: yang lebih akhir).
   `[a, c)` adalah periode peralihan (13–46 hari). Fungsi murni
   `financialPeriodOf(date, schedule)` mengembalikan `FinancialPeriod(start,
   end, isTransition)`.
3. **`Budget.endDate`** opsional; null berarti `period.endFrom(startDate)`.
   Hanya diisi untuk menyelaraskan anggaran rutin ke periode peralihan.
   `BudgetSchedule` menerima patokan `lastDay`. Ini merevisi ADR-036 §3.1
   ("anggaran bulanan hanya bisa diulang bila mulai tanggal 1–28") dengan
   tambahan `lastDay`.
4. **Memindah anggaran rutin** adalah use case di fitur `budget`
   (`AlignRecurringBudgets`), dipanggil dari alur ubah awal bulan hanya untuk
   anggaran yang dipilih pengguna: anggaran periode berjalan mendapat
   `endDate = c`, patokan templat menjadi `startDay` baru. Tautan pos yang
   tanggalnya ≥ `c` dipindah ke pos `templateItemId` sama di periode
   berikutnya saat lahir (ADR-036 §3.4). Saldo tidak berubah (aturan 5).
5. **Tanggal periode.** `periodDateOf(Transaction t)` =
   `t.recurrence.occurrenceDate` bila `t.recurrence != null` dan
   `|t.date − occurrenceDate| ≤ 7 hari`, selain itu `t.date`. Dipakai untuk
   keanggotaan periode di `monthPlan`, Beranda (arus), Analisis, dan
   penyaring periode Riwayat. Saldo, `projectCashflow` harian, dan partisi
   penyimpanan `transaction/YYYY-MM` (ADR-012) tetap memakai `date`.
   **Revisi 10 Okt 2026 (temuan T-18.1, keputusan pemilik opsi a):** KT-1
   juga memakai `periodDateOf`. Pengeluaran atau transfer tertaut kemunculan
   rutin (selisih ≤ 7 hari) terhitung di pos anggaran yang periodenya
   mencakup tanggal periodenya, baik saat dihitung terpakainya
   (`countsTowardBudgetItem`) maupun saat ditawarkan dan divalidasi di CATAT.
   Ini menyelaraskan hitungan dengan penyelesai pos ADR-036 §3.4, yang sudah
   memakai tanggal kemunculan. Transaksi tanpa tautan rutin tetap memakai
   `date`. Hitungan terpakai sebuah anggaran membaca paling banyak satu
   dokumen bulan tetangga (transaksi sampai 7 hari sebelum periodenya).
6. **Beranda** memakai periode keuangan berjalan untuk arus (merevisi
   ADR-035 §3.6 "tidak berlaku untuk Beranda").

## 4. Opsi yang dipertimbangkan

- **Opsi A — Hitung ulang langsung, tanpa riwayat** (perilaku sekarang).
- **Opsi B — Kunci pengaturan selama ada anggaran rutin aktif.**
- **Opsi C — Tanggal mulai dan selesai bebas per periode.**
- **Opsi D — Riwayat, satu periode peralihan, `Budget.endDate`, tanggal
  periode (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Hitung ulang langsung

Paling murah. Menghasilkan masalah P1–P7 di FINANCIAL_PERIOD §6, termasuk
uang nganggur yang salah sebesar nominal anggaran rutin dan pergeseran
permanen. Ditolak.

### Opsi B — Kunci pengaturan

Murah dan aman untuk data, tetapi menyulitkan pengguna yang paling butuh
fitur ini (sudah punya anggaran rutin lalu sadar gajiannya tanggal 25).
Ditolak oleh pemilik.

### Opsi C — Tanggal mulai dan selesai bebas

Periode bisa bolong, tumpang-tindih, atau berubah panjang, padahal rutin
bulanan, kelahiran anggaran, horizon perkiraan, dan pembanding Analisis
mengandalkan satu periode ≈ satu bulan. Ditolak (keputusan pemilik #1).

### Opsi D — Dipilih

Periode lampau stabil, anggaran rutin bisa diselaraskan tanpa celah, gajian
maju tidak menggandakan pemasukan. Kelemahannya: satu entitas pengaturan
berriwayat, satu field baru di `Budget`, dan satu aturan atribusi yang harus
dipakai seragam di empat tempat. Periode peralihan tetap tidak sepanjang
sebulan; ditangani dengan label dan pengecualian (FINANCIAL_PERIOD P-8–P-10).

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Pengguna bisa mengubah awal bulan kapan saja tanpa merusak rencana.
- Beranda, Rencana, dan Analisis menyebut angka bulan yang sama.
- Gajian akhir bulan dan gajian maju tertangani.

### Yang menjadi lebih sulit

- Setiap kode yang bertanya "periode mana" harus lewat
  `financialPeriodOf` dan `periodDateOf`, bukan `DateTime(y, m, startDay)`.
- Periode tidak lagi selalu sebulan; kode yang mengandaikan panjang tetap
  harus memeriksa `isTransition`.

### Risiko yang diterima

- Periode peralihan tanpa gajian menampilkan uang nganggur negatif (tanpa
  peringatan).
- Transaksi tertaut kemunculan dengan selisih > 7 hari dihitung menurut
  `date`.
- Membaca satu periode bisa menyentuh dua dokumen bulan penyimpanan
  ditambah tetangganya (±7 hari atribusi).

## 7. Catatan implementasi

- **Verifikasi dulu** perilaku gajian maju di kode sekarang (T-18.1) sebelum
  mengubah `monthPlan`.
- `financialPeriodOf` dan `periodDateOf` fungsi murni di `core/` dan
  `shared/transaction/`; `core/` tidak mengimpor fitur (ADR-030).
- `ActiveFinancialMonth` menyiarkan jadwal, bukan angka.
- Uji wajib: contoh A–D FINANCIAL_PERIOD §5; batas 13–46 hari untuk semua
  pasangan tanggal 2026–2028; migrasi preferensi lama; tidak ada celah atau
  tumpang-tindih anggaran rutin sesudah dipindah; saldo tidak berubah.
- Antipola: menulis ulang `startDate` anggaran yang sudah lahir; menyimpan
  periode yang dihitung.

## 8. Kriteria peninjauan ulang

- Pengguna nyata butuh periode mingguan atau dua-mingguan.
- Lebih dari satu perubahan awal bulan per pengguna per kuartal (tanda
  pengaturan tidak dipahami).
- Batas atribusi 7 hari terbukti terlalu sempit atau terlalu lebar.

## 9. Artefak terkait

### Dokumentasi

- [FINANCIAL_PERIOD.md](../../01-product/features/FINANCIAL_PERIOD.md)
- [FINANCIAL_ANALYSIS.md](../../01-product/features/FINANCIAL_ANALYSIS.md)
- ADR-035 §3.6, ADR-036 §3.1 dan §3.4 (direvisi sebagian)

### Rujukan kode

- `lib/core/financial_month/`
- `lib/shared/recurring/domain/month_plan.dart`
- `lib/features/budget/domain/entities/budget_schedule.dart`
- `lib/features/budget/data/adapters/plan_budget_source_impl.dart`
- `lib/features/plan/data/month_review_repository_impl.dart`

---

**Penulis keputusan:** agen (product-owner), atas keputusan pemilik 10 Okt 2026
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-10-10
**Status implementasi:** Belum dimulai
