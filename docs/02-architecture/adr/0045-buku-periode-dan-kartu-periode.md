# Buku Periode dan Kartu Periode: gerbang, sumber angka, penyedia halaman, dan ingatan

## 1. Metadata

- **Decision ID:** ADR-045
- **Tanggal:** 2026-11-14
- **Fase roadmap:** Fase 27 (lihat TASK_LIST), dari B-95
- **Status:** Proposed (arah dan KT-BP1, 3–14 disetujui pemilik 14 Nov 2026; jadi
  Accepted setelah verifikasi perangkat T-27.11)
- **Cakupan:** fitur baru `features/period_book` (buku, ritual, Rak) dan
  `features/period_card` (Kartu Periode), `lib/app/` (akar komposisi),
  `core/design_system` (widget bersama), `core/foundation/entitlement`
  (`PlusFeature`), `features/data_portability` (`BackupRegistry`),
  `features/home` (slot), `features/analysis` (Riwayat, segmen ketiga)
- **Bergantung pada:** ADR-030, ADR-038, ADR-040, ADR-041, ADR-043; mesin tonggak B-94
- **Rancangan produk:** [BUKU_PERIODE.md](../../01-product/features/BUKU_PERIODE.md) (BP-1–BP-21),
  rupa di [HANDOFF.md](../../03-design/proposals/kartu-periode/HANDOFF.md)

## 2. Konteks

Buku Periode (Plus) dan Kartu Periode (semua pengguna) butuh angka periode,
gerbang hak, ingatan kecil, dan layar baru di tiga tempat yang dimiliki fitur
lain (Beranda, Riwayat, Akun). BUKU_PERIODE §12 menyerahkan tujuh keputusan
teknis ke engineer. Batasan yang berlaku untuk semuanya: BP-1–BP-14, tanpa data
keuangan keluar perangkat, inti tetap luring dan tidak melambat (buku dihitung
saat dibuka, bukan di jalur pembukaan aplikasi), bisa diuji tanpa perangkat,
angka sama persis dengan Analisis.

## 3. Keputusan (usulan)

### 3.1 Gerbang Plus

- `PlusFeature.periodBook` baru. Layar buku (ritual, sampul, rapor) dibungkus
  pola `PlusLocked` yang ada, **dan** rute buku memeriksa hak sendiri (BP-10:
  jangan hanya di UI).
- Aturan hak buku: Plus atau uji coba aktif → boleh. Plus berakhir → hanya buku
  yang `openedAt != null` (ingatan §3.5); yang lain terkunci. Masa tenggang dan
  uji coba mengikuti ADR-041 dan BP-11.
- **Kartu Periode tidak digerbang** (BP-15): tidak ada `PlusFeature` untuk kartu.
  Varian dan kartu geser (R2) menambah fitur Plus tersendiri nanti.

### 3.2 Sumber angka

Model baca buku **tidak punya aturan hitung sendiri**. Ia memanggil model baca
yang sudah ada (Arus Beranda, Analisis, Rencana) lewat port di `lib/app/`,
dengan `financialPeriodOf` dan `periodDateOf` untuk keanggotaan periode. Uang
`int` sen. Uji kecocokan total terhadap Arus Beranda dan Analisis memakai data
uji emas (B-3, B-15); angka contoh prototipe D6 diabaikan.

### 3.3 Penyedia halaman

`PeriodBookPageProvider` (antarmuka domain di `period_book`): menerima
`PeriodRef` dan mengembalikan `Option<BookPage>` (kosong = halaman dilewati).
Lima penyedia R1 (Arus, Kategori, Dibanding biasanya, Rutin dan rencana, Kata
Tanuki) didaftarkan **di akar komposisi** (`lib/app/period_book/`), bukan diimpor
`period_book` dari fitur sumbernya (ADR-030). Penyedia baru (Target, Penjaga,
Freelance, Rapor Tahunan) hanya menambah entri daftar.

### 3.4 Templat kalimat

Mesin templat lokal di `period_book/domain` (Dart murni): kunci i18n `book.*`
dengan isian bernama dan bentuk jamak; tanpa Gemini (BP-8). Dijaga
`translations_test.dart` dan glosarium (istilah terlarang, tanpa kata yang
menilai belanja, BP-7).

### 3.5 Ingatan dan pencadangan

Satu kotak Hive `period_book_memory` berisi: `opened{periodId → openedAt}`,
`ritualSteps{periodId → langkah selesai}`, `cardDismissed{periodId}`,
`cardFacts{fakta yang dinyalakan terakhir}`, dan sakelar BP-14. Tidak ada snapshot
angka (BP-4). **Didaftarkan di `BackupRegistry`** sebagai `include`
(`supportedSchema: 1`); uji kelengkapan registri dijalankan.

### 3.6 Fakta "periode tertutup"

Fakta bersama yang dipakai mesin B-94 (stempel Periode rapi dan Rutin tak
terlewat) dan buku: periode berakhir dengan ≥3 transaksi (BP-2/BP-3). Stempel
**diraih otomatis** oleh mesin B-94; "cap" di sampul hanya gerak, bukan sumber
stempel. Mesin B-94 tidak mengimpor `period_book`; fakta dibaca lewat port.

### 3.7 Slot Beranda

Satu slot "kartu akhir periode" di bawah kartu saldo, di atas Arus. Prioritas
tetap: banner pembaruan ▸ lembar Apa yang baru ▸ banner kotak masuk ▸ kartu ini;
bila yang lebih tinggi tampil, kartu tidak dirender (BP-13). Isi (kartu mini
Gratis atau buku mini Plus) dipilih `lib/app/` dari hak §3.1. Rak Buku menjadi
**segmen ketiga Riwayat** (KT-BP5) lewat penyedia segmen di akar komposisi.

### 3.8 Kartu Periode: model dan perender

- `PeriodCardModel` hanya berisi `noteCount`, `routines(done, skipped)`,
  `stamp`, `topBuiltinCategory(percent)` dan tiga nominal opsional. **Tidak ada
  field** untuk nama dompet, saldo, pedagang, nominal per transaksi, atau catatan
  (BP-16); kategori buatan pengguna dipetakan ke "kategori buatanmu" sebelum
  masuk model. Kilap dan rak stempel (versi permainan) **bukan bagian model**;
  hanya efek layar.
- Gambar 4:5 dirender di perangkat: `RepaintBoundary.toImage(pixelRatio: 1080/252)`,
  tanpa kilap dan gerak, lalu dibagikan lewat `Share.shareXFiles`. Tanpa jaringan
  dan tanpa unggahan (BP-17). Tautan teks bagikan memuat
  `utm_source=period_card` (BP-18); Firebase membacanya tanpa data baru, dan
  Keamanan Data diperiksa di T-27.10.

### 3.9 Gerak versi permainan

Semua gerak lewat `DsMotion.reduced(context)`; tanpa `Ticker` bila rute tidak
tampil (`TickerMode`); animasi berulang hanya skala, keburaman, geser. Kilap dan
konfeti **diukur di Android kelas bawah** sebelum rilis (T-27.11); bila terlalu
berat, turunkan jumlah partikel atau matikan kilap, bukan gerak dasar.
Perayaan dipicu tindakan pengguna boleh tampil (BP-13 revisi 14 Nov 2026) dan
mengikuti sakelar perayaan (G-8).

### 3.10 Aset pose Tanuki

Empat pose (biasa, senang, menulis, tenang) dibuat sebagai aset baru (T-27.9).
Sampai siap, widget memakai `tanuki_mascot`, `tanuki_sleeping`, `note_pencil`
dengan gerak di atasnya; nama berkas pose tetap supaya penggantian tidak mengubah
kode.

## 4. Alternatif yang ditolak

- **Menyimpan snapshot angka per buku:** menambah data dan berisiko selisih
  dengan Analisis; ditolak (BP-4, KT-BP4).
- **Gerbang Kartu Periode di Plus:** mematikan jalur pertumbuhan (KT-BP2).
- **Fitur buku mengimpor fitur sumber angka langsung:** melanggar ADR-030;
  diganti port dan penyedia halaman di `lib/app/`.

## 5. Konsekuensi

- Dua fitur baru dan satu kotak Hive baru; `BackupRegistry` bertambah satu entri.
- Riwayat menjadi tiga segmen; tur dan teks id/en perlu penyesuaian.
- Revisi BP-13 dan GAMIFICATION G-4 sudah dikerjakan (T-27.1).

## 6. Gerbang Accepted

Verifikasi perangkat T-27.11: kecocokan total, gerbang BP-10 di rute, Gerak
dikurangi, kinerja kilap dan konfeti di Android kelas bawah, 360dp, terang/gelap
dan satu preset lain.
