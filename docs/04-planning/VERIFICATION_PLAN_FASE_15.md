# Rencana Verifikasi — Fase 15 (Rencana dan rutin, R1)

**Dibuat:** 4 Oktober 2026 · **Branch:** `claude/rencana-rutin-fase-14`
**Rujukan:** [ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md),
[RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md),
[PLAN_TAB_LAYOUT.md](../01-product/features/PLAN_TAB_LAYOUT.md), TASK_LIST Fase 15.

Pola sama dengan [VERIFICATION_PLAN_FASE_11](VERIFICATION_PLAN_FASE_11.md):
per milestone, terhadap rentang commit-nya. Perangkat utama: Xiaomi
22021211RG (Android 13+, MIUI). Pasang build debug biasa
(`flutter run` atau `adb install -r`), **bukan** `flutter test` tanpa
`--no-uninstall` — itu menghapus data aplikasi.

---

## Milestone R1a — Rutin (T-15.1 s.d. T-15.8, verifikasi T-15.9)

**Rentang commit:** `5c20e36` .. `8c9d7df`.

### Risiko utama

| # | Risiko | Kenapa penting |
|---|---|---|
| R1 | Kemunculan tercatat dua kali (kartu Menunggu, aksi notifikasi, tautan notifikasi) | Saldo salah; invarian 15 |
| R2 | Pencocokan otomatis menautkan transaksi yang salah | Kemunculan tampak lunas padahal belum |
| R3 | Pengingat tidak muncul (MIUI membatasi alarm latar) atau muncul ganda | FR-RUT-004 |
| R4 | Penyusunan ulang jadwal menghapus notifikasi yang sedang tampil | Pengguna kehilangan pengingat dan pengingat catat notifikasi |

### Daftar periksa kode

- [x] Id notifikasi stabil dari `(jenis, ruleId, tanggal)` (`reminderId`,
      FNV-1a 31 bit); uji `reminder_plan_test.dart` tanpa ganda.
- [x] Aksi Catat dari notifikasi lewat `RecordTransaction`; ketukan ganda
      ditolak invarian 15 (snackbar "sudah tercatat").
- [x] Penjadwalan `inexactAllowWhileIdle`, tanpa izin exact alarm; boot
      receiver terdaftar di manifest.
- [ ] **Temuan K1:** `LocalNotificationReminderScheduler.replaceAll` memakai
      `cancelAll()`, yang di Android memanggil
      `NotificationManager.cancelAll()`: semua notifikasi aplikasi yang
      **sedang tampil** ikut hilang, termasuk pengingat rutin pagi itu dan
      pengingat catat notifikasi (`CaptureReminders.kt`). Penyusunan ulang
      terjadi tiap aplikasi kembali ke depan dan tiap buku besar berubah,
      jadi ini sering. Perbaikan: `cancelAllPendingNotifications()` (hanya
      jadwal), tugas T-15.15.

### Daftar periksa perangkat

| # | Alur | Langkah | Harapan |
|---|---|---|---|
| D1 | J1 | Rencana › Rutin kosong → ketuk chip `Kos`, `BPJS`, `Cicilan` | CATAT mode jadwal terisi; tanggal bawaan 1 / 10; Cicilan membuka "Berakhir setelah N kali"; chip jadi centang |
| D2 | J2 | Catat "Netflix 65.000" tanggal hari ini, Ulangi: Tiap bulan | Tombol **Catat & Jadwalkan**; snackbar "Berikutnya …"; transaksi = kemunculan pertama |
| D3 | J2 | Sama dengan tanggal besok | Tombol **Simpan Jadwal**; tidak ada transaksi baru di Riwayat |
| D4 | J2 | Rincian transaksi lama → **Jadikan Rutin** | Transaksi asal tertaut, tidak tercatat dua kali |
| D5 | J3 | Rutin bernominal tetap jatuh tempo hari ini → **Catat** di kartu Menunggu | Tercatat satu ketuk + Batalkan; Batalkan menghapusnya |
| D6 | J3 | Rutin nominal kira-kira → **Catat** | CATAT terbuka, nominal terisi perkiraan |
| D7 | J3 | **Lewati** lalu Batalkan | Kemunculan kembali menunggu |
| D8 | J3, T-15.7 | Notifikasi BRImo/BCA nyata yang cocok dengan rutin (dompet, jenis, nominal, ±3 hari) | Tercocok sendiri, atau kartu menawarkan "Sudah tercatat? Tautkan"; tidak ada transaksi kedua |
| D9 | J7 | Ubah nominal rutin; jeda; hapus | "Berlaku mulai kemunculan berikutnya"; jeda menghilangkan menunggu; hapus menyisakan transaksi di Riwayat |
| D10 | J8 | Rutin bertanggal lampau dua bulan lalu | Satu baris menunggu + "n terlewat" |
| D11 | T-15.8 | Akun › Pengingat rutin nyala | Dialog izin Android 13; sakelar per rutin di rincian |
| D12 | T-15.8 | Rutin bayar sendiri, H−1, jatuh tempo besok; tunggu 09.00 | Notifikasi "besok" muncul; aksi **Catat** membuka aplikasi dan mencatat satu ketuk |
| D13 | K1 | Biarkan notifikasi pengingat tampil, buka aplikasi dari launcher | Notifikasi tetap ada (gagal sebelum T-15.15) |

Untuk D12 tanpa menunggu sehari: buat rutin jatuh tempo besok dengan H−1
sebelum 09.00, atau periksa jadwal lewat
`adb shell dumpsys alarm | grep tanukonomy`.

### Kriteria lulus

D1–D13 sesuai harapan, tidak ada transaksi ganda (R1), temuan dicatat di
bawah, perbaikan sebagai tugas baru.

### Hasil

- 4 Okt 2026: tinjauan kode, temuan K1 (T-15.15). Perangkat: belum.

---

## Milestone R1b — Bulan ini (T-15.10 s.d. T-15.13, verifikasi T-15.14)

**Rentang commit:** `52f4af0` .. `dfade0a`.

### Risiko utama

| # | Risiko | Kenapa penting |
|---|---|---|
| R5 | Uang nganggur atau perkiraan menyimpang dari hitungan manual | Angka inti layar; "ketepatan angka lebih penting" |
| R6 | Bulan keuangan mulai 25 salah memotong rentang (transaksi 24/25) | FR-PLN-004 |
| R7 | Transfer ikut dihitung keluar (KT-R14) | Aturan domain 7 |

### Daftar periksa perangkat

| # | Langkah | Harapan |
|---|---|---|
| E1 | Akun › Bulan keuangan = 25 | Label "25 Okt – 24 Nov" di Bulan ini; Beranda tetap bulan kalender |
| E2 | Hitung manual satu bulan nyata (rumus §7.2, §7.2a): pemasukan rutin − keluar rutin − sisa anggaran | Sama dengan kartu Uang nganggur, sampai rupiah |
| E3 | Lembar ⓘ Uang nganggur | Jumlah baris = angka besar |
| E4 | Transfer ke Tabungan bulan ini | Uang nganggur tidak berkurang |
| E5 | Grafik Saldo dompet ≈, geser; lembar Rincian | Titik terendah dan akhir bulan cocok dengan hitungan manual §7.3 |
| E6 | Lebar 360dp (font besar) | Tidak ada overflow |

### Kriteria lulus

E1–E6 sesuai, selisih nol rupiah pada E2 dan E5.

### Hasil

- Belum.
