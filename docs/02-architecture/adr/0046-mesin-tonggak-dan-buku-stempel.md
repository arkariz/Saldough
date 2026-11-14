# Mesin tonggak dan Buku Stempel: letak kode, katalog, evaluasi, dan penyimpanan

## 1. Metadata

- **Decision ID:** ADR-046
- **Tanggal:** 2026-11-14
- **Fase roadmap:** Fase 28 (lihat TASK_LIST), dari B-94
- **Status:** Proposed (KT-G1–G7 disetujui pemilik 14 Nov 2026, tanpa uji A/B;
  jadi Accepted setelah verifikasi perangkat T-28.8)
- **Cakupan:** fitur baru `features/milestone`, `lib/app/milestone/` (akar
  komposisi: penyedia fakta), `features/data_portability` (`BackupRegistry`),
  `features/account` (baris Buku Stempel dan sakelar, lewat akar komposisi)
- **Bergantung pada:** ADR-024, ADR-030, ADR-040
- **Rancangan produk:** [GAMIFICATION.md](../../01-product/features/GAMIFICATION.md) (G-1–G-11)
- **Dipakai oleh:** ADR-045 (stempel periode di sampul Buku Periode; fakta "periode tertutup")

## 2. Konteks

Delapan stempel R1 dihitung dari fakta yang sudah ada di aplikasi (dompet,
transaksi, periode, rutin, kotak masuk, cadangan, anggaran, freelance).
GAMIFICATION §12 menyerahkan enam keputusan teknis ke engineer. Batasan: G-1–G-11,
tanpa data keuangan keluar perangkat, inti tetap luring dan tidak melambat, bisa
diuji tanpa perangkat (fakta dan jam diganti palsu).

## 3. Keputusan (usulan)

### 3.1 Letak kode

`features/milestone` memiliki katalog, mesin evaluasi, penyimpanan, dan nanti
perayaan serta Buku Stempel. Ia **tidak mengimpor fitur lain**. Fakta dibaca lewat
satu port `MilestoneFactsSource` (domain) yang diimplementasi di
`lib/app/milestone/`, yang boleh memanggil model baca fitur lain (ADR-030).
Fitur Akun menyisipkan baris Buku Stempel lewat akar komposisi, seperti baris
Versi aplikasi (ADR-039).

### 3.2 Katalog: di kode, saklar dari jarak jauh

Definisi tonggak (id, kelompok, jenis syarat, fakta) ada **di kode** dan ikut rilis;
syarat adalah logika, bukan data yang boleh salah jaringan. Hanya satu hal dari
Remote Config: `stamps_enabled` (saklar mati) dan daftar id yang dimatikan
(`stamps_disabled_ids`). Tanpa uji A/B (keputusan pemilik). Tonggak yang
dimatikan tidak diraih lagi, tetapi yang sudah diraih tidak dicabut (G-1).

### 3.3 Bentuk syarat

Tiga jenis, semuanya dikurangi ke satu fakta bernama (`MilestoneFact`):
`firstTime` (fakta jadi benar pertama kali), `closedPeriod` (ada satu periode
tertutup yang memenuhi syarat isi), `queueCleared` (antrean turun ke nol lewat
keputusan pengguna). Penyedia fakta yang menghitung (dari data yang ada), mesin
hanya membaca himpunan fakta yang benar. Jenis baru = satu fakta + satu baris
katalog (§9 GAMIFICATION).

### 3.4 Evaluasi

`EvaluateMilestones` (use case): baca fakta → hitung tonggak baru dengan fungsi
murni → simpan buku catatan. Idempoten: mengulang tidak menambah apa pun (G-3,
G-5). Pemicu: aplikasi dibuka dan sesudah tindakan yang bersangkutan selesai
(sinyal `LedgerChanges` dan peristiwa tindakan), di belakang pembukaan, tanpa
menunda tindakan; kegagalan membaca fakta atau menyimpan tidak sampai ke
pengguna dan diulang pada evaluasi berikutnya.

### 3.5 Penyimpanan dan cadangan

Satu dokumen Hive `milestone_ledger` (`schemaVersion: 1`): stempel diraih
(`id`, `earnedAt`, `seen`, `quiet`), `seeded`, `introShown`, dan
`celebrationEnabled` (G-8). Didaftarkan di `BackupRegistry` sebagai `include`
(G-10). Jenis hadiah baru menambah field baru yang opsional, tanpa migrasi.

### 3.6 Slot hadiah

Hadiah dibaca dari daftar diraih oleh lapisan masing-masing (stempel di R1;
barang Kamar Tanuki dan bagikan di R2/R3). Mesin tidak mengenal hadiah.

### 3.7 Pengguna lama (G-6)

Pada evaluasi pertama (`seeded == false`), semua tonggak yang sudah memenuhi syarat
diraih **diam-diam** (`quiet: true`, tanpa perayaan) dan `seeded` menjadi benar.
`introShown` tetap salah sampai banner pengenalan tampil sekali (T-28.4).

## 4. Alternatif yang ditolak

- Katalog penuh dari Remote Config: syarat adalah logika, dan catatan lewat
  Remote Config butuh penanganan keandalan (ADR-039).
- Mesin mengimpor fitur sumber fakta: melanggar ADR-030; diganti port.
- Menghitung ulang diraih dari data tiap kali: stempel bisa hilang bila data
  diubah, melanggar G-1.

## 5. Konsekuensi

- Satu fitur baru dan satu kunci Hive baru.
- Fase 27 membaca fakta "periode tertutup" lewat port yang sama.
- Teks, ikon, dan layar (T-28.4–T-28.7) menyusul di fase yang sama.
