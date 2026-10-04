# Rencana Verifikasi — Fase 16 (Rencana R2)

**Dibuat:** 4 Oktober 2026 · **Branch:** `claude/rencana-r2-fase-16`
**Rujukan:** [ADR-036](../02-architecture/adr/0036-anggaran-rutin-dan-perkiraan-ke-depan.md),
[RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md),
[PLAN_TAB_LAYOUT.md](../01-product/features/PLAN_TAB_LAYOUT.md), TASK_LIST Fase 16.

Pola sama dengan [VERIFICATION_PLAN_FASE_15](VERIFICATION_PLAN_FASE_15.md).
Dijalankan di emulator Pixel 7a API 35 (`emulator-5554`) dengan build debug
(`adb install -r`), data lama dipertahankan. Bulan keuangan mulai tanggal 25.
Jam dimajukan lewat `cmd alarm set-time` (`auto_time 0`), lalu dikembalikan.

**Rentang commit:** `cff852e` .. `88f89aa`.

---

## Risiko utama

| # | Risiko | Kenapa penting |
|---|---|---|
| R1 | Periode anggaran rutin lahir dua kali, atau tidak lahir saat bulan berganti | Rencana salah; invarian kelahiran |
| R2 | Rutin tertaut pos terhitung dua kali (tagihan + anggaran) | Uang nganggur dan perkiraan salah (invarian 17/21) |
| R3 | Bulan depan tidak berantai dari akhir bulan ini | Invarian 20 |
| R4 | Siapkan dana: banner dan notifikasi beda angka, atau notifikasi tidak muncul | W1, J3 |
| R5 | Tinjau awal bulan tampil di luar 7 hari, atau tidak bisa ditutup | J4 tidak boleh mengganggu pencatatan |

## Daftar periksa perangkat

| # | Alur | Langkah | Harapan | Hasil |
|---|---|---|---|---|
| V1 | T-16.3 | Anggaran baru, sakelar Ulangi | Mulai bawaan = awal bulan keuangan (25 Sep); teks "Lahir lagi tiap bulan mulai 25 Oktober"; tur `budgetRepeat` | Lulus |
| V2 | T-16.2 | Jam dimajukan ke 25 Okt, buka aplikasi | Periode 25 Okt – 24 Nov lahir sekali; periode lama Selesai | Lulus |
| V3 | T-16.4 | Ubah nominal pos periode berjalan | Dialog "Berlaku untuk"; "Hanya periode ini" → bulan depan tetap Rp300.000 | Lulus; Bulan ini basi → **K3** |
| V4 | T-16.5 | Rincian rutin Listrik › Pos anggaran › Listrik · Harian | Tertaut; Tagihan rutin turun Rp300.000, Anggaran naik Rp300.000 | Lulus; perkiraan turun Rp300.000 → **K1** |
| V5 | T-16.6 | Pemilih bulan, chip bulan depan | Lencana PERKIRAAN, "Awal 25 Nov" = akhir bulan ini; anggaran bulan depan dari template | Lulus |
| V6 | T-16.7 | Rutin autodebet Rp200.000 tgl 27, saldo BCA Rp137.500 | Banner Siapkan dana di Bulan ini; notifikasi H−1 09:00 dengan angka yang sama | Lulus (banner dan notifikasi ≈Rp87.212) |
| V7 | T-16.8 | Hari pertama bulan keuangan | Kartu di Bulan ini (0/3) dan Beranda; Sesuai, Nanti (lipat 1/3), buka lagi, Selesai meninjau + snackbar | Lulus; Beranda tetap tampil → **K2** |
| V8 | T-16.9 | Kilas balik | Lembar rencana vs nyata, teks akurasi dari snapshot | Lulus ("tepat", lihat K9) |

## Hasil

Tiga temuan diperbaiki di branch ini:

- **K1** (T-16.13): rutin tertaut yang kemunculannya sudah tercatat tanpa
  pos (dicatat sebelum ditautkan) hilang dari hitungan pos, jadi perkiraan
  menyebar sisa pos penuh. Sesudah perbaikan perkiraan ≈Rp125.000 dan
  kilas balik menunjukkan Anggaran nyata Rp287.500.
- **K2** (T-16.14): Beranda dan Bulan ini memakai `PlanMonthBloc` terpisah;
  status tinjau kini disiarkan `MonthReviewRepository.changes`.
- **K3** (T-16.15): `BudgetBloc` tidak memancarkan `LedgerChanges`, jadi
  Rencana dan Beranda basi sesudah anggaran diubah.

Temuan kecil yang belum dikerjakan (T-16.16):

- **K4** Rincian anggaran menulis "Rp0 terpakai" untuk pos yang rutin
  tertautnya sudah tercatat tanpa pos, sedangkan Rencana menghitungnya
  terpakai (K1). Dua layar berbeda angka.
- **K5** Angka kira-kira tampil sampai rupiah: "kurang ≈Rp87.212",
  "≈−Rp2.855.533". Bulatkan ke ribuan saat diawali `≈`.
- **K6** Daftar dan rincian anggaran tidak menandai anggaran rutin, dan
  rincian tidak menyebut rutin yang tertaut ke posnya.
- **K7** Baris lipat "Tinjau rencana … (1/3)" terbaca dua kali oleh pembaca
  layar (label `AppTappable` + teks).
- **K8** Chip pemilih bulan panjang untuk bulan keuangan yang tidak mulai
  tanggal 1 ("25 Okt – 24 Nov ≈−2,9 jt"); bulan ketiga perlu digeser.
- **K9** Snapshot W9 dibuat saat bulan pertama kali dibuka sesudah fitur
  terpasang (di sini hari ke-10), jadi bulan pertama tampak "tepat".
  Pertimbangkan hanya menampilkan W9 bila snapshot dibuat dalam 7 hari
  pertama.

Tidak diuji di emulator: tautan lewat saran E9 di CATAT (diuji widget),
W7/W8 (tidak ada pemasukan rutin atau cicilan di data emulator, diuji unit).
