# Anggaran rutin, perkiraan ke depan, dan tinjau awal bulan (R2)

## 1. Metadata

- **Decision ID:** ADR-036
- **Tanggal:** 2026-10-04
- **Fase roadmap:** Fase 16 (Rencana R2)
- **Status:** Accepted (disetujui pemilik 4 Okt 2026)
- **Cakupan:** `lib/features/budget/` (template berjadwal, kelahiran
  periode, dialog lingkup), `lib/shared/recurring/` (tautan rutin ke pos,
  perkiraan multi-bulan, wawasan), `lib/features/plan/` (pemilih bulan,
  bulan depan, banner siapkan dana, tinjau awal bulan),
  `lib/features/recurring/` (tautan pos, notifikasi siapkan dana),
  `lib/features/home/` lewat slot shell
- **Bergantung pada:** ADR-008, ADR-011, ADR-017, ADR-021, ADR-023, ADR-030,
  ADR-035
- **Merinci:** ADR-035 §3.9 (anggaran rutin) dan §3.8 (siapkan dana di R2).
  ADR-035 tetap berlaku; bila berbeda dalam hal R2, ADR ini yang berlaku.
- **Desain produk:** [RECURRING_AND_FORECAST.md](../../01-product/features/RECURRING_AND_FORECAST.md)
  J4–J6, §7.4, §7A E3/E9, §7B W1/W7–W10, §8.5–8.6, §12 R2;
  [PLAN_TAB_LAYOUT.md](../../01-product/features/PLAN_TAB_LAYOUT.md) §4.1,
  §4.3–4.4, banner dan tinjau awal bulan

## 2. Konteks

R1 (Fase 15) menutup lingkaran rutin dan bulan berjalan. Dua lubang
sengaja dibiarkan (RECURRING_AND_FORECAST §12):

- **Anggaran harus dibuat ulang tiap bulan** dari template. Pemilik
  menyalin blok bulan di spreadsheet; aplikasi belum menggantikannya.
- **Perkiraan berhenti di akhir bulan berjalan**, karena tanpa anggaran
  rutin bulan depan tampak tanpa belanja, dan angka yang terlalu bagus
  merusak kepercayaan.

ADR-035 §3.9 hanya menyiapkan bentuk domainnya. ADR ini memutuskan
perilakunya. Keputusan pemilik 4 Okt 2026: periode berikutnya mengikuti
tanggal awal anggarannya sendiri, horizon tetap +2 bulan, dan R2
dikerjakan sebelum Fase 14 dengan bahasa visual yang ada (layarnya ikut
disapu Fase 14).

## 3. Keputusan

### 3.1 Anggaran rutin = template berjadwal

Tetap satu konsep template (KT-R4):

| Entitas | Field baru | Keterangan |
|---|---|---|
| `BudgetTemplate` | `schedule?: BudgetSchedule` | `walletId`, `period` (`weekly`/`monthly`), `anchorDate`, `isActive` |
| `Budget` | `templateId?` | Template yang melahirkannya |
| `BudgetItem` | `templateItemId?` | Kunci pos yang stabil antarperiode |

Semua field opsional: dokumen lama terbaca tanpa migrasi (`schemaVersion`
naik, nilai kosong = tidak rutin). Pos template memakai id-nya sendiri
sebagai `templateItemId`; pos anggaran yang lahir mendapat id baru (aturan
DOMAIN_MODEL "Template anggaran" tetap) dan `templateItemId` = id pos
template.

**Menyalakan Ulangi tiap periode** di formulir anggaran membuat template
dari anggaran itu (nama, pos, dompet, periode, `anchorDate` = tanggal awal
anggaran), lalu mengisi `templateId` dan `templateItemId`. Template ini
tampil di layar Template dengan keterangan "Ulangi tiap bulan · BCA".
Template tanpa `schedule` berperilaku persis seperti sekarang.

**Awal periode berikutnya mengikuti tanggal awal anggarannya**
(keputusan pemilik). Anggaran bulanan hanya bisa diulang bila mulai
tanggal 1–28 (seperti bulan keuangan, ADR-035 §3.6), sehingga periode ke-n
selalu `anchorDate + n bulan` dan akhir periode (`BudgetPeriod.endFrom`) tepat
di awal periode berikutnya, tanpa penjepitan. Untuk tanggal 29–31 sakelar
Ulangi dimatikan dengan penjelasan. Formulir anggaran
bulanan baru mengisi tanggal awal bawaan dengan awal bulan keuangan
(ADR-035 §3.6), sehingga pengguna yang gajian tanggal 25 mendapat 25 tanpa
aturan tambahan.

### 3.2 Kelahiran periode

- Fungsi murni `dueBirths(templates, budgets, today)`: untuk tiap template
  dengan `schedule.isActive`, periode yang mencakup `today`; lahir bila
  belum ada `Budget` dengan `templateId` itu dan `startDate` yang sama.
- **Hanya periode berjalan**, tanpa mengisi periode yang terlewat (ADR-035
  §3.9, RECURRING_AND_FORECAST §15). Periode sebelum `anchorDate` tidak
  pernah lahir.
- Dijalankan saat aplikasi dibuka dan saat tanggal berganti (`ActiveDay`,
  T-15.17), oleh host di shell, bukan pekerjaan latar. Idempoten: dua kali
  jalan tidak membuat dua anggaran.
- Anggaran yang lahir tidak menyentuh saldo (invarian 14, aturan 5).

### 3.3 Menyunting anggaran rutin

Berlaku hanya untuk anggaran yang `templateId`-nya punya `schedule` dan
periodenya berjalan atau akan datang. **Anggaran periode lalu tidak pernah
menanyakan lingkup dan tidak pernah mengubah template.**

| Perubahan | Pilihan | Bawaan |
|---|---|---|
| Tambah pos | Hanya periode ini / Periode ini dan berikutnya | Hanya periode ini (ADR-008: baris baru insidental) |
| Ubah nominal atau nama pos bertemplate | sama | Periode ini dan berikutnya |
| Hapus pos bertemplate | sama | Hanya periode ini |
| Ubah nama anggaran atau dompet | sama | Periode ini dan berikutnya |
| Matikan Ulangi | — | `schedule.isActive = false`; periode berjalan tetap ada |

"Berikutnya" berarti template; periode yang belum lahir mengikutinya,
periode yang sudah lahir tidak berubah selain yang sedang disunting.
Menyunting template di layar Template hanya memengaruhi periode yang belum
lahir. Menghapus template berjadwal = berhenti melahirkan; anggaran yang
sudah lahir tetap ada dengan `templateId` yatim.

### 3.4 Tautan rutin ke pos

- `RecurringRule.budgetItemKey` = `templateItemId`. Hanya untuk rutin
  **pengeluaran** dan pos dari anggaran rutin **berdompet sama** (KT-1:
  hanya pengeluaran dari dompet anggaran yang terhitung). Anggaran tanpa
  template tidak bisa ditautkan karena posnya tidak stabil antarperiode.
- Kemunculan diselesaikan ke pos dengan `templateItemId` itu di anggaran
  yang periodenya mencakup tanggal kemunculan. Mencatat kemunculan tertaut
  (satu ketuk, Ubah dulu, Catat semua, aksi notifikasi) mengisi
  `budgetItemId` pos itu. Bila periodenya belum lahir, transaksi tercatat
  tanpa pos.
- **E9:** sesudah rutin pengeluaran baru disimpan, bila ada pos anggaran
  rutin berdompet sama dengan nama yang sama (tanpa beda huruf besar dan
  spasi) atau nominal rencana yang sama, snackbar menawarkan "Tautkan ke
  pos Kos di Bulanan". Tautan juga bisa dipasang atau dilepas di rincian
  rutin. Tidak pernah otomatis.
- **Hitungan (invarian 17):**
  - `monthPlan`: rutin tertaut tidak masuk tagihan rutin; posnya masuk
    anggaran dengan rencana `max(rencana pos, Σ kemunculan tertaut di
    periode itu)`.
  - `projectCashflow`: `keluar_pos = max(sisa_pos, Σ kemunculan tertaut
    belum tercatat)`, kemunculan diletakkan di tanggalnya, selisihnya
    dibagi rata ke sisa hari periode (§7.4). Pos yang tertautnya melebihi
    sisa diberi tanda peringatan.

### 3.5 Perkiraan ke depan

- **Horizon tetap: bulan keuangan berjalan + 2** (keputusan pemilik;
  pengaturan sampai 12 bulan KT-R8 masuk antrean).
- `projectCashflow` menerima rentang bulan keuangan mana pun. Saldo awal
  bulan depan = perkiraan akhir bulan sebelumnya (berantai, tanpa
  pembulatan antara).
- Isi bulan depan:
  - semua kemunculan rutin di rentang itu (belum ada yang tercatat);
  - anggaran rutin: **periode virtual** dari jadwal template dengan sisa =
    rencana penuh, dibagi rata per hari periode, hanya hari yang jatuh di
    rentang itu;
  - anggaran tanpa template: hanya sisa periodenya yang masih berjalan;
  - di luar rencana (rata-rata §7.5) bila nyala;
  - freelance belum dibayar sebagai "belum pasti" (KT-R6).
- `monthPlan` bulan depan memakai sumber yang sama (anggaran = periode
  virtual yang mulai di rentang itu, pola R1 "periode jatuh di bulan itu").
- Tampilan mengikuti PLAN_TAB_LAYOUT §4.3–4.4: chip bulan berjalan + 2
  dengan akhir bulan ringkas, chip bulan depan berbingkai putus-putus, chip
  negatif berikon peringatan; bulan depan berlencana "PERKIRAAN", tanpa
  bilah tercatat, tanpa garis hari ini, semua nominal `≈`.
- Port `PlanBudgetSource` diperluas: baris anggaran per rentang, termasuk
  periode virtual. Fitur `plan` tetap tidak mengimpor `budget` (ADR-030).

### 3.6 Siapkan dana (W1, E3)

- Fungsi murni `fundingWarnings(today, projection per dompet, rules)`: untuk
  kemunculan rutin **autodebet** pengeluaran atau transfer pada H−3 sampai
  H0, bila perkiraan saldo dompetnya pada awal hari itu kurang dari
  nominalnya. Kekurangan = nominal − saldo perkiraan.
- **Banner** di Bulan ini (PLAN_TAB_LAYOUT §4.1 blok 0, paling banyak satu,
  yang tanggalnya paling dekat, "+n lainnya") dan wawasan prioritas 1 di
  Beranda. Kalimatnya menyarankan tindakan di luar aplikasi ("Siapkan dana
  di BCA sebelum 10 Okt"), tidak pernah "transfer sekarang".
- **Notifikasi:** satu per kemunculan, H−1 pukul 09.00, lewat penjadwal
  pengingat yang ada (ADR-035 §3.8; saluran `recurring_reminders`, id stabil
  dari `fund|ruleId|tanggal`). Hanya bila pengingat global nyala. Dihitung
  saat jadwal disusun ulang, jadi berubah bila saldo atau rutin berubah.

### 3.7 Tinjau awal bulan (J4) dan wawasan bulanan

- **Kartu "Oktober dimulai"** di Beranda dan di atas pemilih bulan,
  sejak awal bulan keuangan sampai selesai, ditutup, atau akhir hari ke-7.
  "Nanti" melipatnya jadi satu baris "Tinjau rencana Oktober (1/3) ›".
- **Tiga langkah**, semuanya bisa dilewati: anggaran yang baru lahir
  [Sesuai / Ubah]; rutin bernominal kira-kira [Sesuai / Ubah perkiraan];
  kilas balik bulan lalu [Lihat]. Tidak pernah memblokir pencatatan.
- **Penyimpanan:** `plan` / `month_review`, satu dokumen untuk bulan
  keuangan berjalan: `{monthStart, doneSteps, completed, dismissed}`.
  Bulan baru menimpanya.
- **W10 kilas balik:** rencana vs nyata bulan lalu per baris (pemasukan,
  tiap rutin, tiap anggaran, di luar rencana), dihitung ulang dari buku
  besar dengan `monthPlan` bulan lalu. Tidak disimpan.
- **W9 akurasi:** butuh perkiraan yang dibuat **sebelum** bulan berjalan.
  Saat bulan keuangan pertama kali dibuka, perkiraan akhir bulannya (semua
  dompet, setelan di luar rencana saat itu) disimpan di `plan` /
  `forecast_snapshots` (3 bulan terakhir). Selisih = perkiraan − saldo
  nyata akhir bulan (dihitung dari buku besar); baris W10 dengan selisih
  terbesar disebut. Tampil hanya bila ada snapshot bulan lalu. Angka ini
  tidak dikirim ke mana pun.
- **W7 bebas cicilan:** rutin `count` atau `untilDate` dengan kemunculan
  terakhir dalam 12 bulan: "Mulai Jul 2027 ruang bebas +Rp2.914.000/bln" di
  rincian rutin dan satu baris di Bulan ini (yang paling dekat).
- **W8 porsi terikat:** `(rutin keluar + anggaran) ÷ pemasukan terencana`,
  dibulatkan ke persen terdekat saat ditampilkan, dibandingkan bulan lalu.
  Hanya bila pemasukan terencana > 0. Teks netral, bukan peringatan.

### 3.8 Analitik dan tur

- Peristiwa tanpa nominal (ADR-023): `budget_repeat_toggled{on}`,
  `budget_period_born`, `budget_edit_scope{scope}`,
  `recurring_budget_linked{source: suggestion|detail}`,
  `plan_viewed{month_offset}`, `funding_warning_shown`,
  `month_review_completed{steps_done}`.
- Tur (ADR-021): `budgetRepeat` (sakelar Ulangi), `planMonthPicker`
  (pemilih bulan).

### 3.9 Invarian baru (diuji)

18. Kelahiran periode idempoten dan tidak pernah mengisi periode terlewat.
19. Menyunting anggaran periode lalu tidak pernah mengubah template.
20. Perkiraan bulan depan berantai: saldo awal = perkiraan akhir bulan
    sebelumnya, persis dalam sen.
21. Kemunculan rutin tertaut pos terhitung sekali, di pos (lanjutan
    invarian 17), di `monthPlan` maupun `projectCashflow`.

## 4. Opsi yang dipertimbangkan

| Opsi | Isi | Keputusan |
|---|---|---|
| A | Template berjadwal (ADR-035 §3.9) | **Dipilih** |
| B | Entitas `RecurringBudget` terpisah | Ditolak: dua konsep untuk satu kebutuhan (KT-R4), layar Template menjadi membingungkan |
| C | Menyalin anggaran bulan lalu saat bulan baru dibuka, tanpa template | Ditolak: tidak ada kunci pos stabil untuk tautan rutin dan dialog lingkup |
| D | Periode virtual disimpan sebagai anggaran sungguhan ke depan | Ditolak: anggaran yang belum terjadi tampil di daftar dan harus dihapus saat rencana berubah |

## 5. Konsekuensi

- Layar Template mendapat keterangan berjadwal; formulir anggaran mendapat
  sakelar dan dialog lingkup. Dua-duanya akan disapu ulang di Fase 14.
- `PlanBudgetSource` dan `projectCashflow` berubah bentuk; uji R1b yang
  memakai satu bulan tetap harus lulus tanpa diubah angkanya.
- Penyimpanan baru: `plan/month_review`, `plan/forecast_snapshots`. Tidak
  ada data keluar perangkat; formulir Keamanan Data tidak berubah.
- Perkiraan bulan depan bisa meleset jauh untuk pengguna tanpa anggaran
  rutin. Kartu bulan depan menyebut sumbernya di lembar "Dari mana angka
  ini", dan W9 membuat selisihnya terlihat.

## 6. Yang tidak diputuskan di sini

- Horizon yang bisa diatur sampai 12 bulan (KT-R8): antrean.
- "Coba rencana" (pengeluaran khayalan): di luar R2.
- Otomasi R3 (catat otomatis, belum terlihat H+2, rutin menganggur):
  B-28.
