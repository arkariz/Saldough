# Otomasi rutin: deteksi, catat otomatis, dan saran (R3)

## 1. Metadata

- **Decision ID:** ADR-037
- **Tanggal:** 2026-10-04
- **Fase roadmap:** Fase 17 (Rencana R3)
- **Status:** Proposed (menunggu pemilik, lihat §6)
- **Cakupan:** `lib/shared/recurring/` (status kemunculan, deteksi, saran),
  `lib/features/recurring/` (kartu Menunggu, rincian, pengaturan rutin),
  `lib/features/notification_capture/` (kenaikan harga dari notifikasi),
  `lib/shared/capture/` (rutin lewat suara)
- **Bergantung pada:** ADR-027, ADR-029, ADR-032, ADR-035, ADR-036
- **Merinci:** ADR-035 §3 untuk R3. ADR-035 dan ADR-036 tetap berlaku.
- **Desain produk:** [RECURRING_AND_FORECAST.md](../../01-product/features/RECURRING_AND_FORECAST.md)
  §3 prinsip 2, §7A E1/E3/E8, §7B W3/W6, §12 R3, KT-R7

## 2. Konteks

R1 dan R2 membuat rutin tercatat dengan satu ketuk atau tautan otomatis dari
notifikasi, tetapi pengguna masih harus (a) mengetuk Catat untuk tiap rutin
tetap, (b) menyadari sendiri autodebet yang tidak terlihat, langganan yang
sudah berhenti, dan harga yang naik, serta (c) membuat rutin secara manual.
R3 menurunkan hambatan ini sampai nyaris nol tanpa melanggar prinsip
"tinjau dulu, otomatis kalau diminta".

Kuota agen terbatas, jadi R3 dipecah menjadi milestone kecil yang masing-
masing bisa dirilis sendiri, urut dari risiko terendah (hanya menampilkan)
ke tertinggi (menulis transaksi tanpa ketukan).

## 3. Keputusan (usulan)

### 3.1 R3a: deteksi tanpa menulis

- **E3 belum terlihat (H+2).** Kemunculan rutin **autodebet** yang dua hari
  sesudah tanggalnya belum tercatat atau tertaut berstatus turunan
  `unseen` (tidak disimpan, diturunkan dari `occurrenceStatusesOf` seperti
  status lain). Kartu Menunggu memberi label "Belum terlihat di notifikasi"
  dengan aksi **Catat / Belum terjadi / Lewati**. "Belum terjadi" menunda
  label 2 hari lagi (disimpan di `RecurringRule.snoozedUntil?` per
  kemunculan, satu tanggal). Rutin bayar sendiri tidak terkena: H+0 sudah
  muncul di Menunggu.
- **W6 rutin menganggur.** Rutin yang dua kemunculan terakhirnya
  berturut-turut dilewati atau `unseen` mendapat kartu "Masih berlangganan
  Spotify?" di segmen Rutin dengan **Akhiri / Jeda / Biarkan**. "Biarkan"
  menyembunyikan kartu sampai pola itu terulang dari awal (disimpan
  `idleDismissedAt?`).

### 3.2 R3b: catat otomatis per rutin

- Sakelar **Catat otomatis** di "Atur lebih lanjut", hanya untuk nominal
  **tetap** (kira-kira tidak pernah, §12 "di luar cakupan"). Bawaan mati.
- Berjalan **saat aplikasi dibuka** dan saat `ActiveDay` berganti, di host
  yang sama polanya dengan `RecurringBudgetHost`: kemunculan berstatus
  menunggu pada atau sebelum hari ini dicatat lewat `RecordTransaction`
  (satu jalur tulis), lalu `LedgerChanges` dipancarkan sekali.
- **Ragu = tidak dicatat**: bila ada transaksi dari notifikasi yang bisa
  cocok (±3 hari) atau kemunculan sudah tertaut, tidak ada yang dicatat.
  Autodebet menunggu H+1 supaya notifikasi bank sempat masuk lebih dulu.
- Setiap catatan otomatis masuk log **Tercatat otomatis** (pola
  `RecurrenceMatchLog`) dengan aksi **Batalkan** yang menghapus transaksi
  lewat use case hapus biasa.

### 3.3 R3c: saran

- **Kenaikan harga dari notifikasi (W3).** Saat transaksi dari notifikasi
  hampir cocok dengan rutin tetap (dompet, jenis, tanggal ±3 hari) tetapi
  nominalnya naik ≥5% **dan** ≥Rp5.000, rutin tidak ditautkan otomatis;
  kartu "Netflix naik jadi Rp79.000" menawarkan **Perbarui rutin / Biarkan**
  dan menautkan transaksinya.
- **"Sepertinya rutin".** Dari riwayat: pengeluaran atau pemasukan dengan
  dompet, nominal, dan catatan (dinormalkan) sama di **3 bulan berturut-
  turut**, tanggal ±3 hari, yang belum ditautkan ke rutin mana pun. Kartu di
  segmen Rutin: **Jadikan rutin** (membuka CATAT mode jadwal terisi) /
  **Bukan rutin** (disimpan, tidak ditawarkan lagi). Dihitung saat segmen
  Rutin dibuka, paling banyak 3 saran.

### 3.4 R3d: suara dan kartu gabungan (ditunda, butuh keputusan)

- **Rutin lewat suara.** Ucapan "tiap bulan"/"tiap tanggal 5" menyalakan
  Ulangi di draf CATAT (paket bahasa ADR-029). Murah bila parser waktu
  sudah ada; dikerjakan sesudah R3a–c.
- **KT-R7** (satu kartu menunggu gabungan rutin + kotak masuk notifikasi)
  menunggu keputusan pemilik dan Fase 14, karena tata letaknya berubah.

### 3.5 Analitik

Tanpa nominal: `occurrence_unseen_shown`, `recurring_idle_action{action}`,
`auto_record_toggled{on}`, `auto_recorded{count}`, `auto_record_undone`,
`price_increase_action{action}`, `recurring_suggestion_action{action}`.

## 4. Opsi yang dipertimbangkan

- **Catat otomatis di latar (WorkManager).** Ditolak: ADR-032 memproses
  saat aplikasi hidup; pekerjaan latar menambah izin dan kasus gagal.
- **Saran dari 2 bulan.** Ditolak sebagai bawaan: 2 kali terlalu sering
  kebetulan (belanja rutin di warung yang sama). 3 bulan lebih jarang salah.

## 5. Konsekuensi

- Skema `RecurringRule` naik sekali (field `autoRecord`, `snoozedUntil?`,
  `idleDismissedAt?`); dokumen lama terbaca dengan bawaan.
- Penyimpanan baru: `recurring/auto_record_log`,
  `recurring/suggestion_dismissed`.
- Invarian baru: catat otomatis tidak pernah mencatat kemunculan yang sudah
  tercatat/tertaut (invarian 15 tetap), dan tidak pernah untuk nominal
  kira-kira.

## 6. Yang perlu diputuskan pemilik

1. Urutan dan cakupan milestone (R3a → R3b → R3c, R3d ditunda)?
2. Catat otomatis: bawaan mati, autodebet menunggu H+1 — setuju?
3. Ambang "sepertinya rutin": 3 bulan berturut-turut?
4. KT-R7 digabung sesudah Fase 14, atau dibatalkan?
