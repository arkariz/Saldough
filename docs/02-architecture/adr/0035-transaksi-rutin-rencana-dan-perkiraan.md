# Transaksi rutin, tab Rencana, uang nganggur, dan perkiraan arus kas

## 1. Metadata

- **Decision ID:** ADR-035
- **Tanggal:** 2026-10-02
- **Fase roadmap:** Fase 15 (Rencana dan rutin, R1a + R1b); R2 dirinci di [ADR-036](0036-anggaran-rutin-dan-perkiraan-ke-depan.md) (Fase 16); R3 di antrean
- **Status:** Accepted (disetujui pemilik 2 Okt 2026)
- **Cakupan:** entitas baru `RecurringRule` (`lib/shared/recurring/`),
  `Transaction` (`lib/shared/transaction/`), fitur baru
  `lib/features/recurring/` dan `lib/features/plan/`, `lib/features/budget/`
  (jadi segmen), `lib/app/shell/`, `lib/core/presentation/widgets/`,
  preferensi di `lib/core/`, notifikasi lokal (Android dan iOS)
- **Bergantung pada:** ADR-008 (opsi C ditolak), ADR-011, ADR-012, ADR-015,
  ADR-016, ADR-020, ADR-021, ADR-023, ADR-025, ADR-030, ADR-032, ADR-033
- **Mengubah:** aturan 8 (CATAT satu-satunya jalur pembuatan transaksi
  manual) mendapat pengecualian kedua; PRD §6 "Transaksi berulang otomatis"
  di luar MVP; navigasi bawah PRD §10 (tab Anggaran → Rencana)
- **Desain produk:** [RECURRING_AND_FORECAST.md](../../01-product/features/RECURRING_AND_FORECAST.md),
  [PLAN_TAB_LAYOUT.md](../../01-product/features/PLAN_TAB_LAYOUT.md),
  [RECURRING_COMPETITIVE_ANALYSIS.md](../../01-product/features/RECURRING_COMPETITIVE_ANALYSIS.md)

## 2. Konteks

Pemilik meminta transaksi rutin (pemasukan, pengeluaran, transfer), anggaran
rutin, gambaran keuangan awal bulan, dan perkiraan bulan-bulan ke depan.
Spreadsheet lamanya menghitung "Sisa = total pemasukan − total anggaran" tiap
awal bulan (MANUAL_PROCESS_ANALYSIS), dan pemilik ingin memantau "uang
nganggur": pemasukan terencana dikurangi semua pengeluaran terencana.

Batasan yang mengikat:

- **Mencatat, bukan melakukan.** Aplikasi tidak membayar dan tidak terhubung
  ke bank, jadi jadwal tidak boleh diam-diam menjadi transaksi.
- **ADR-008 sudah menolak "berulang otomatis penuh tanpa peninjauan".**
  Nominal listrik dan kos berubah, dan angka lama akan diterima diam-diam.
- **Angka harus tepat** (aturan 1, `int` sen). Perkiraan tidak boleh
  menghitung hal yang sama dua kali, misalnya rutin Kos dan pos anggaran Kos.
- **Lokal-first, tanpa pekerjaan latar.** Seluruh pemrosesan Dart berjalan
  saat aplikasi hidup (pola ADR-032).
- **Catat dari notifikasi (ADR-032) sudah bisa mencatat transaksi yang sama.**
  Tanpa pencocokan, rutin dan notifikasi akan menghasilkan catatan ganda.
- **Tab bawah tinggal empat dan tidak muat untuk tab kelima** (T-8.8).

Seluruh keputusan produk (KT-R1–R14, KT-L1–L7) diputuskan pemilik 2 Okt
2026; daftarnya ada di §14 dan §11 kedua dokumen desain.

## 3. Keputusan

Tanukonomy menambah **transaksi rutin** sebagai rencana yang dijadwalkan dan
ditinjau, tab **Rencana** dengan tiga segmen, serta **uang nganggur** dan
**perkiraan saldo** yang dihitung, tidak disimpan.

### 3.1 `RecurringRule`: entitas rencana baru

`RecurringRule` di `lib/shared/recurring/` (dipakai Beranda, Rencana, CATAT,
dan penangkap notifikasi). Field:

| Field | Tipe | Keterangan |
|---|---|---|
| `id` | `String` | |
| `kind` | `income` / `expense` / `transfer` | Sama dengan jenis transaksi |
| `amount` | `int` | Sen, positif |
| `amountMode` | `fixed` / `estimated` | `estimated`: nominal dikonfirmasi tiap kali dicatat; perkiraannya = nominal tercatat terakhir |
| `walletId` / `fromWalletId`, `toWalletId` | `String` | Seperti transaksi |
| `categoryId` | `String?` | Pemasukan dan pengeluaran saja |
| `note` | `String` | |
| `schedule` | `frequency` (`weekly`/`monthly`/`yearly`), `interval` (≥1), `anchorDate`, `anchorDay` | `anchorDay` disimpan terpisah supaya patokan 31 kembali ke 31 sesudah Februari |
| `end` | `none` / `untilDate` / `count` | `count` menghitung kemunculan di jadwal apa pun statusnya |
| `paymentMode` | `autoDebit` / `manual` / `null` | Pengeluaran dan transfer; `null` diperlakukan `manual` |
| `remindDaysBefore` | `int` | Bawaan 1; hanya untuk `manual` |
| `autoRecord` | `bool` | R3; hanya sah bila `amountMode = fixed` |
| `skippedDates` | `Set<DateTime>` | Satu-satunya status kemunculan yang disimpan |
| `isPaused` | `bool` | |
| `budgetItemKey` | `String?` | R2: `templateItemId` pos anggaran rutin |

Disimpan di `recurring` / `all` (satu dokumen, pola ADR-012: lajunya rendah).

**Kemunculan dihitung, tidak disimpan.** Penjepitan tanggal sama dengan
`BudgetPeriod.endFrom` (`lib/features/budget/domain/entities/budget_period.dart`),
dan dipindah ke fungsi bersama kalau dipakai dua tempat.

### 3.2 Tautan kemunculan di `Transaction`

Ketiga jenis `Transaction` mendapat field opsional
`recurrence: RecurrenceLink? {ruleId, occurrenceDate, linkedBy: user|auto}`,
mirip `freelancePaymentId`. Data lama tetap terbaca karena field ini kosong.

Status kemunculan **diturunkan**:

- tercatat ⇔ ada transaksi dengan `recurrence` itu;
- dilewati ⇔ tanggalnya ada di `skippedDates`;
- menunggu ⇔ sudah tiba, bukan dua di atas, dan merupakan kemunculan
  terbaru yang sudah tiba;
- terlewat ⇔ seperti menunggu, tetapi bukan yang terbaru.

Menghapus transaksinya mengembalikan kemunculan ke menunggu. Cukup membaca
dokumen bulan berjalan dan bulan sebelumnya (ADR-012).

### 3.3 Satu jalur tulis, dengan pengecualian kedua untuk aturan 8

Catat satu ketuk, catat semua, aksi Catat dari notifikasi, dan (R3) catat
otomatis memanggil **`RecordTransaction`** yang sama dengan CATAT, lalu
memancarkan `LedgerChanges` (ADR-030 §3.4). Tidak ada jalur simpan lain.

Aturan 8 kini punya dua pengecualian tanpa formulir:

1. Catat dari notifikasi tingkat 2/3 (ADR-032 §3.5).
2. **Kemunculan rutin bernominal tetap yang dikonfirmasi pengguna dengan satu
   ketuk** (KT-R5).

Keduanya memakai use case yang sama. Semua yang perlu ditinjau, termasuk
nominal kira-kira, selalu membuka CATAT.

Menautkan (`linkedBy: auto`) hanya menulis `recurrence` ke transaksi yang
sudah ada dan tidak mengubah saldo. Karena itu menautkan boleh otomatis
untuk kecocokan persis sejak R1a (KT-R11), sedangkan mencatat otomatis tetap
pilihan per rutin di R3.

### 3.4 Pencocokan

`matchOccurrences` adalah fungsi murni. Sebuah transaksi cocok dengan satu
kemunculan bila:

- jenis dan dompetnya sama;
- nominalnya persis (rutin `fixed`) atau dalam ±10% (rutin `estimated`);
- tanggalnya dalam ±3 hari;
- transaksi itu belum tertaut ke rutin lain; dan
- **hanya ada satu kandidat.**

Bila ada dua kandidat, nominalnya berbeda, atau dompetnya berbeda, aplikasi
bertanya dan tidak menebak.

Hasilnya:

- tautan otomatis untuk transaksi yang dicatat dari notifikasi;
- label "Cocok dengan rutin …" pada draf di kotak masuk notifikasi, yang
  melengkapi kategori, catatan, dan pos dari rutin;
- saran "Sudah tercatat? Tautkan" untuk transaksi dari jalur lain.

Tautan otomatis masuk log `recurring` / `match_log` (retensi 7 hari, pola
ADR-032 §3.6) dengan aksi Lepaskan.

### 3.5 Hitungan murni, tanpa entitas tersimpan

Di `lib/shared/recurring/domain/`:

| Fungsi | Isi | Rilis |
|---|---|---|
| `occurrencesOf(rule, range)` | Tanggal kemunculan | R1a |
| `monthPlan(month, …)` | Uang nganggur rencana dan sisa (RECURRING_AND_FORECAST §7.2, §7.2a) | R1b |
| `projectCashflow(today, wallet?, …)` | Saldo harian, akhir bulan, paling tipis (§7.3–7.5) | R1b |
| `insightsFor(today, …)` | W1–W10 (§7B) | bertahap |

Semua nominal `int` sen. Pembagian harian menaruh sisa pembagian di hari
terakhir supaya jumlahnya persis. Kasus uji wajib §7.7 berlaku. Contoh §7.6
dan §7.2a harus menghasilkan:

- uang nganggur rencana 3.052.500;
- sisa 2.995.500;
- akhir Oktober 10.921.000;
- paling tipis 561.000 pada 24 Oktober.

**Uang nganggur bukan saldo.** Ia arus satu bulan keuangan:

```
uang nganggur rencana = pemasukan terencana − rutin keluar − anggaran
sisa uang nganggur    = uang nganggur rencana
                      − belanja di luar rencana yang sudah tercatat (dan selisih lain §7.2a)
```

Transfer, termasuk ke Tabungan, tidak dihitung (aturan 7, KT-R14). Pos
anggaran dengan rutin tertaut tidak dihitung ganda:
`keluar_pos = max(sisa_pos, rutin tertaut yang belum tercatat)`.

### 3.6 Bulan keuangan bisa diatur

Preferensi `settings` / `financial_month_start` berisi tanggal 1–28
(bawaan 1). Polanya sama dengan `CurrencyPreferenceRepository`
(`lib/core/currency/`): repository di `core/`, dibaca saat aplikasi mulai,
diubah dari layar Akun.

Berlaku untuk:

- Rencana: uang nganggur, perkiraan, pemilih bulan;
- kartu bulan baru;
- kelahiran anggaran rutin (R2).

**Tidak** berlaku untuk arus bulan berjalan di Beranda (FR-HOME-001), yang
tetap memakai bulan kalender. Tanggal 29–31 tidak ditawarkan supaya setiap
bulan punya tanggal mulai.

### 3.7 Tab Rencana dan navigasi

- **Shell.** Tab ke-2 menjadi `PlanPage` (`lib/features/plan/`) dengan label
  `appShell.planTabLabel` dan ikon `icon_nav_budget`.
- **Sub-tab.** Komponen baru `AppSubTabs` (`lib/core/presentation/widgets/`).
  Pindah segmen hanya lewat ketukan, tanpa geser; tiap segmen punya posisi
  gulir sendiri.
- **Segmen per rilis.**
  - R1a: Anggaran (`BudgetListPage` tanpa app bar sendiri; penyaring status
    jadi chip) dan Rutin (`lib/features/recurring/`).
  - R1b: Bulan ini (`lib/features/plan/`).
- **Membuka tab beserta segmennya.** Beranda dan aksi notifikasi perlu
  membuka "tab Rencana, segmen X". Shell mendapat cara membuka tab plus
  segmen, dengan memperluas `ShellStartAction` dan indeks tab di
  `lib/app/shell/app_shell_page.dart`. Pemakai di luar shell memakai kunci
  rute (ADR-030), bukan mengimpor fitur Rencana.
- **Rincian rutin** adalah rute penuh `RecurringRouteKeys.detail`.
- **Membuat dan mengubah rutin** memakai CATAT mode jadwal lewat
  `RecordRouteKeys.sheet`, dengan parameter jadwal. Tidak ada formulir rutin
  terpisah.

### 3.8 Notifikasi lokal (R1a)

- **Dependensi.** Ditambah `flutter_local_notifications` dan `timezone`.
  Satu jalur untuk Android dan iOS, penjadwalan **inexact** sehingga tidak
  perlu izin exact alarm.
- **Izin.** `POST_NOTIFICATIONS` (Android 13+) sudah dideklarasikan untuk
  catat dari notifikasi. Izin diminta saat pengguna pertama kali menyalakan
  pengingat, bukan saat aplikasi dibuka.
- **Isi.**
  - Pukul 08.00 waktu perangkat, H−`remindDaysBefore` untuk rutin
    `manual`: "Kos Rp1.900.000 jatuh tempo besok".
  - Pada hari jatuh tempo, satu notifikasi ringkas untuk semua yang
    menunggu.
  - Rutin `autoDebit` tidak diingatkan; peringatan "siapkan dana" baru di
    R2.
- **Penjadwalan.** Jadwal disusun ulang setiap aplikasi dibuka dan setiap
  rutin berubah, untuk kemunculan dalam 35 hari ke depan. Id notifikasi
  diturunkan dari `(ruleId, occurrenceDate)` sehingga penyusunan ulang tidak
  menggandakan.
- **Aksi Catat** (nominal tetap) **membuka aplikasi** lewat payload, lalu
  mencatat satu ketuk dengan snackbar Batalkan. Tidak ada isolate latar dan
  tidak ada penulisan saat aplikasi tertutup.
- **Saluran Android sendiri** (`recurring_reminders`), terpisah dari
  `CaptureReminders.kt`. Teksnya dikirim dalam bahasa aplikasi (ADR-028).
- **Sakelar.** Pengingat bisa dimatikan per rutin dan untuk seluruh
  aplikasi di layar Akun.

### 3.9 Anggaran rutin (R2, dicatat di sini supaya domain R1 tidak menutup jalannya)

- `BudgetTemplate.schedule?` berisi `walletId`, `period`, `anchorDate`, dan
  `isActive`.
- `Budget.templateId?` dan `BudgetItem.templateItemId?`.
- Periode baru lahir saat aplikasi dibuka, hanya untuk periode berjalan,
  tanpa mengisi periode yang terlewat. Template tetap satu konsep (KT-R4).

### 3.10 Invarian baru (diuji)

14. Transaksi rutin dan anggaran rutin tidak menyentuh saldo.
15. Satu kemunculan menghasilkan paling banyak satu transaksi.
16. Transfer rutin tidak mengubah perkiraan saldo total.
17. Pos anggaran dengan rutin tertaut tidak dihitung ganda di perkiraan.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Rutin mencatat sendiri pada tanggalnya** (Money Lover, Money
  Manager)
- **Opsi B — Rutin sebagai transaksi masa depan yang tersimpan**
- **Opsi C — Rutin sebagai rencana; kemunculan dihitung, ditinjau, dan
  ditautkan (Dipilih)**

Untuk notifikasi:

- **N1 — Kotlin native (AlarmManager) memperluas `CaptureReminders`**
- **N2 — WorkManager / pekerjaan latar**
- **N3 — `flutter_local_notifications`, jadwal disusun ulang saat aplikasi
  hidup (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A — Mencatat sendiri pada tanggalnya

Paling sedikit interaksi, tetapi ini persis kegagalan yang ditolak ADR-008:
nominal basi tercatat diam-diam dan saldo tersimpan menyimpang dari
kenyataan. Opsi ini juga bertabrakan dengan catat dari notifikasi, yang
mencatat kejadian yang sama.

### Opsi B — Transaksi masa depan yang tersimpan

Gampang ditampilkan di Riwayat, tetapi membuat dua sumber kebenaran untuk
status. Setiap perubahan jadwal harus menulis ulang banyak dokumen bulan,
dan transaksi yang belum terjadi masuk ke buku besar. Saldo tersimpan juga
harus membedakan transaksi nyata dari transaksi masa depan, sehingga
invarian 2 makin rumit.

### Opsi C — Rencana yang ditinjau dan ditautkan (Dipilih)

Status hanya ada di satu tempat, yaitu tautan di transaksi dan
`skippedDates`. Buku besar tetap berisi kejadian nyata saja. Pencocokan
mengubah catat dari notifikasi dari sumber catatan ganda menjadi bukti yang
mengonfirmasi rutin.

Kelemahannya, membaca status butuh dokumen dua bulan, dan pencocokan bisa
keliru. Risiko keliru ditekan dengan syarat satu kandidat, log, dan aksi
Lepaskan.

### N1 — Kotlin native

Bisa memakai ulang kode `CaptureReminders`, tetapi tidak ada iOS, dan
penjadwalan, saluran, serta aksi harus ditulis dua kali kelak.

### N2 — Pekerjaan latar

Bisa menghitung ulang tanpa membuka aplikasi, tetapi menuntut DI di isolate
latar dan melanggar pola "Dart memproses saat aplikasi hidup". Ini
berlebihan untuk pengingat yang jadwalnya sudah diketahui jauh hari.

### N3 — Plugin, disusun ulang saat hidup (Dipilih)

Satu jalur untuk Android dan iOS, dan jadwal yang sudah diketahui cukup
didaftarkan di muka. Kelemahannya:

- ada dependensi baru, sehingga formulir Keamanan Data perlu dicek ulang
  walau tidak ada data yang keluar dari perangkat;
- jadwal hanya diperbarui saat aplikasi dibuka, sehingga pengguna yang tidak
  membuka aplikasi lebih dari 35 hari berhenti mendapat pengingat. Ini
  diterima.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Mencatat yang rutin: nol ketuk bila tercocok dari notifikasi, satu ketuk
  dari kartu atau notifikasi.
- Menjawab "berapa uang nganggur bulan ini" dan "aman sampai gajian" tanpa
  spreadsheet.
- Menambah wawasan baru (W1–W10) tanpa mengubah penyimpanan, karena
  semuanya fungsi murni.

### Yang menjadi lebih sulit

- `Transaction` punya satu field opsional lagi, dan uji serialisasi ketiga
  jenis harus menutupnya.
- Navigasi shell perlu konsep segmen.
- Ada dependensi dan izin notifikasi baru, ditambah pengujian di perangkat
  Android dan iOS.
- Bulan keuangan yang bisa diatur membuat "bulan" punya dua arti: kalender
  di Beranda dan Riwayat, serta bulan keuangan di Rencana. Antarmuka harus
  selalu menyebut rentangnya bila tidak mulai tanggal 1 (misalnya "25 Okt –
  24 Nov").

### Risiko yang diterima

- Pencocokan otomatis bisa keliru. Ditangani dengan syarat satu kandidat,
  log 7 hari, dan aksi Lepaskan; diukur lewat tautan yang dilepas.
- Notifikasi bisa terlambat karena penjadwalan inexact. Diterima, karena
  pengingat H−1 tidak butuh ketepatan menit.
- Perkiraan bisa meleset. Ditangani dengan tampilan `≈`, rincian "Dari mana
  angka ini", dan (R2) akurasi bulan lalu.

## 7. Catatan implementasi

- **Batas fitur.** Tetap mengikuti ADR-030/033 dan dijaga oleh
  `test/architecture/import_boundaries_test.dart`:
  - `shared/recurring` tidak mengimpor fitur apa pun;
  - `features/recurring` dan `features/plan` membuka CATAT hanya lewat
    `RecordRouteKeys.sheet`;
  - penangkap notifikasi memakai `matchOccurrences` dari `shared/recurring`.
- **Status.** Jangan menyimpan status kemunculan selain `skippedDates`.
  Jangan menyimpan hasil `monthPlan` atau `projectCashflow`.
- **Saldo.** Jangan menulis saldo dari jalur rutin. Semua tulisan lewat
  `RecordTransaction`.
- **Rumus dan uji.**
  - Uji rumus memakai angka contoh §7.6/§7.2a sebagai kasus wajib, ditambah
    di `.claude/AGENT_CONTEXT.md` bagian "Kasus uji wajib".
  - Uji widget di 360dp dengan skala teks 1,3 untuk `AppSubTabs` (label en
    "THIS MONTH / BUDGETS / RECURRING").
- **Teks.** Teks antarmuka ada di slang:
  - kunci baru `plan.*`, `recurring.*`, dan `reminders.*`;
  - **kata "saldo" hanya untuk isi dompet**;
  - tidak boleh memakai "Bayar", "Dibayar otomatis", atau "Transfer
    sekarang".
- **Analitik** (ADR-023). Peristiwa tanpa nominal:
  `recurring_created{source}`, `occurrence_recorded{method}`,
  `occurrence_skipped`, `occurrence_linked{by}`,
  `occurrence_unlinked`, `plan_viewed{segment, month_offset}`.
- **Tur** (ADR-021). Kunci baru: `planTabs`, `recurringPending`,
  `recordRepeat` di R1a; `planUnplanned` dan `planForecast` di R1b.

## 8. Kriteria peninjauan ulang

- Lebih dari 5% tautan otomatis dilepas pengguna → perketat aturan §3.4,
  atau matikan tautan otomatis.
- Pengingat tidak tampil andal di iOS atau di Android dengan penghemat baterai
  agresif → pertimbangkan N1/N2 untuk platform itu.
- Kurang dari 80% kemunculan diurus dalam 3 hari (RECURRING_AND_FORECAST §13)
  → tinjau ulang kartu, notifikasi, dan catat otomatis (R3).
- Pemilik meminta rutin selain mingguan, bulanan, dan tahunan (misalnya hari
  kerja terakhir) → perluas `schedule`.
- Membaca dua dokumen bulan untuk status terasa lambat → indeks tautan
  terpisah.

## 9. Artefak terkait

### Dokumentasi

- [RECURRING_AND_FORECAST.md](../../01-product/features/RECURRING_AND_FORECAST.md):
  perilaku, rumus §7, penjagaan kesalahan §7A, wawasan §7B, keputusan §14
- [PLAN_TAB_LAYOUT.md](../../01-product/features/PLAN_TAB_LAYOUT.md):
  tata letak tiga segmen, §4.9 aturan "angka dan label pendek"
- [RECURRING_COMPETITIVE_ANALYSIS.md](../../01-product/features/RECURRING_COMPETITIVE_ANALYSIS.md)
- [PRD 2.0](../../01-product/prd-saldough-2.0.md) §7.8 (FR-RUT, FR-PLN,
  FR-BUD-008), [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) bagian "Transaksi
  rutin", [TASK_LIST.md](../../04-planning/TASK_LIST.md) Fase 15
- Prototipe interaktif tab Rencana (artifact pemilik, 2 Okt 2026)

### Rujukan kode

- `lib/features/budget/domain/entities/budget_period.dart` (penjepitan
  tanggal)
- `lib/shared/transaction/domain/transaction.dart`,
  `lib/shared/transaction/data/transaction_model.dart`
- `lib/app/shell/app_shell_page.dart` (`ShellStartAction`, indeks tab)
- `lib/features/budget/presentation/pages/budget_list_page.dart`,
  `lib/features/budget/presentation/widgets/budget_filter_bar.dart`
- `lib/core/currency/currency_preference_repository_impl.dart` (pola
  preferensi)
- `android/.../notificationcapture/CaptureReminders.kt` (saluran
  notifikasi yang sudah ada)

---

**Penulis keputusan:** agen (Claude), atas permintaan pemilik
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-10-02
**Status implementasi:** kode R1a dan R1b selesai 2 Okt 2026 (T-15.1–15.8, T-15.10–15.13); menunggu verifikasi perangkat T-15.9 dan T-15.14
