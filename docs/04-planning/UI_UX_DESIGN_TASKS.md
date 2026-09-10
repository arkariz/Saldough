# Tugas desain UI/UX

Dokumen ini melacak pekerjaan desain visual Saldough, terpisah dari
[TASK_LIST.md](TASK_LIST.md) yang melacak pekerjaan kode. Keduanya memetakan
ke requirement PRD yang sama, tapi desain selesai lebih dulu — sejalan
dengan preferensi pemilik "dokumentasi dan desain lebih dulu, kode menyusul".

Setiap tugas desain diberi identitas `D-<fase>.<nomor>`, memakai nomor fase
yang sama dengan [ROADMAP.md](ROADMAP.md), supaya satu fitur mudah dilacak
dari desain sampai kode. Desain tidak punya Fase 0 (gerbang dependensi) atau
Fase 7 (sinkronisasi) sendiri — keduanya tidak punya permukaan visual baru
di MVP.

## Tautan Design Canvas

**Inti Siklus Bulanan** (D-1.1, D-2.1, D-2.2, D-2.3):
[Saldough — Siklus Bulanan](https://claude.ai/code/artifact/0c0d80a5-90a5-4f02-b5e6-bf8fa76d07d6) —
7 artboard: lembar token & komponen, dashboard (gelap+terang), tambah/sunting
baris (gelap+terang), alur rollover (gelap+terang). Bisa diklik-edit
langsung di canvas.

## Cara memakai dokumen ini

Aturan pencentangan sama ketatnya dengan `TASK_LIST.md`: sebuah kotak hanya
dicentang kalau artboard-nya benar-benar ada di Design Canvas yang
diterbitkan, bukan baru direncanakan.

| Penanda | Arti |
|---|---|
| `- [ ]` | Belum dimulai |
| `- [~]` | Dalam Design Canvas yang sedang dikerjakan |
| `- [x]` | Selesai, ada di Design Canvas yang sudah diterbitkan |

Setiap tugas desain wajib bisa dilacak balik ke requirement PRD. Elemen
visual yang tidak punya rujukan requirement berarti desainnya mengarang
fitur yang belum diputuskan — itu masalah, bukan kreativitas yang sah di
dokumen ini.

## Ringkasan progres

Terakhir diperbarui: 10 September 2026.

| Fase | Tugas desain | Selesai | Status |
|---|---|---|---|
| 1 — Sistem desain | 1 | 1 | Selesai |
| 2 — Siklus bulanan | 4 | 3 | 3 dari 4 selesai |
| 3 — Pemasukan dan timesheet | 3 | 0 | Belum dimulai |
| 4 — Roll-up | 3 | 0 | Belum dimulai |
| 5 — Investasi | 2 | 0 | Belum dimulai |
| 6 — Seed | 1 | 0 | Belum dimulai |
| **Total** | **14** | **4** | |

## Fase 1: Sistem desain

- [x] **D-1.1** Lembar token dan komponen: palet warna semantik
      (`income`, `expense`, `overBudget`, `investment`, `rollUp`,
      `needsReview`, plus slot netral dan `muted`), skala tipografi Syne/DM
      Sans, skala jarak dan sudut, contoh `AppCard`, `AppButton`, `AppChip`,
      dan `AppMoneyText`. Gelap dan terang berdampingan.
      Memenuhi [ADR-0006](../02-architecture/adr/0006-design-token-semantic-color-mapping.md).
      ⚠ Satu nilai diturunkan, bukan dikutip langsung dari ADR: `muted`
      terang (`#94A3B8`) tidak disebutkan eksplisit di ADR-0006 (yang
      eksplisit hanya `muted` gelap `#4A6070`). Dipilih konsisten dengan
      keluarga warna `sub` terang, bukan angka sembarang — tinjau saat
      implementasi.

## Fase 2: Siklus bulanan

- [x] **D-2.1** Dashboard siklus bulanan: daftar baris pemasukan dengan
      total, daftar baris anggaran dengan total, sisa (varian positif
      ditunjukkan dengan data nyata September 2026; varian `overBudget`
      negatif belum digambar terpisah — lihat catatan di bawah), badge
      tetap/insidental, badge `rollUp` dengan asal angkanya, badge
      `needsReview`, plus banner ringkasan "N baris perlu ditinjau"
      (FR-TPL-002).
      Memenuhi FR-CYCLE-001.
      ⚠ Varian sisa negatif (`overBudget`) tidak digambar sebagai artboard
      terpisah ronde ini — token warnanya sudah ada di Artboard 0 (lembar
      token), tapi belum diterapkan ke hero dashboard dalam konteks negatif.
      Susulkan di ronde berikutnya kalau diperlukan sebelum implementasi.
- [x] **D-2.2** Tambah/sunting baris pemasukan dan baris anggaran manual,
      toggle tetap/insidental, tampilan baris roll-up yang tidak bisa
      disunting langsung beserta penjelasannya.
      Memenuhi FR-CYCLE-002.
- [x] **D-2.3** Alur rollover: konfirmasi membuat bulan baru dari template,
      ringkasan "N baris perlu ditinjau", cara menandai satu baris selesai
      ditinjau.
      Memenuhi FR-TPL-001, FR-TPL-002, FR-TPL-003.
- [ ] **D-2.4** Kelola template: daftar baris tetap yang dipakai rollover,
      persentase alokasi investasi bawaan.
      Memenuhi FR-TPL-004.

## Fase 3: Pemasukan dan timesheet

- [ ] **D-3.1** Kelola sumber pemasukan (gaji tetap, freelance per jam,
      sekali jalan) dan aturan potongan (persentase atau nominal tetap).
      Memenuhi FR-INC-001, FR-INC-002, FR-INC-003.
- [ ] **D-3.2** Catat jam kerja dalam satu langkah, dengan penanda hari buku
      baru.
      Memenuhi FR-TIME-001, FR-TIME-002.
- [ ] **D-3.3** Tutup buku jam: rincian gaji kotor → potongan → gaji bersih,
      dan riwayat buku jam terdahulu.
      Memenuhi FR-TIME-003, FR-TIME-004.

## Fase 4: Roll-up

- [ ] **D-4.1** Daftar belanja mingguan dan bulanan, harga timpaan, ringkasan
      roll-up (total sebulan dan pengali minggu).
      Memenuhi FR-GROC-001, FR-GROC-002, FR-GROC-003.
- [ ] **D-4.2** Kelola kartu kredit dan catat transaksi dalam satu langkah.
      Memenuhi FR-CARD-001, FR-CARD-002.
- [ ] **D-4.3** Siklus tagihan kartu (daftar transaksi dan total) dan alur
      konfirmasi langganan berulang.
      Memenuhi FR-CARD-003, FR-CARD-004, FR-CARD-005.

## Fase 5: Investasi

- [ ] **D-5.1** Kelola pos tujuan, alokasi persentase per pos, dan validator
      total persentase.
      Memenuhi FR-INV-001, FR-INV-002, FR-INV-003.
- [ ] **D-5.2** Pencatatan pinjaman antar pos dan riwayat pergerakan saldo
      tiap pos.
      Memenuhi FR-INV-004, FR-INV-005.

## Fase 6: Seed

- [ ] **D-6.1** Layar impor data seed: progres pemuatan dan konfirmasi saat
      aplikasi pertama dibuka.
      Memenuhi FR-SEED-001.

## Catatan pengerjaan

**10 September 2026** — Dokumen dibuat mencakup seluruh cakupan desain MVP,
atas permintaan pemilik. Eksekusi dimulai dari inti Siklus Bulanan
(D-1.1, D-2.1, D-2.2, D-2.3) sebagai satu Design Canvas, gelap dan terang
berdampingan, diterbitkan dan bisa disimpan (tautan di atas). Sisanya
sengaja belum dikerjakan — menunggu ronde berikutnya.

Data pada mockup memakai angka nyata siklus September 2026 dari
[MANUAL_PROCESS_ANALYSIS.md](../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
(pemasukan Rp15.839.563, anggaran Rp13.382.490, sisa Rp2.457.073, roll-up
belanja 576.600×4+762.100=3.068.500), bukan data contoh yang dikarang.
Baris "Kos agustus - september" sengaja ditandai `needsReview` di dashboard
dan muncul lagi sebagai "Kos oktober - november" yang sudah ditinjau di
alur rollover — mendramatisasi langsung nyeri utama produk (label stale
yang terbawa tiga bulan di data historis).

Mockup bersifat statis (belum interaktif/clickable) — asumsi yang diambil
karena cakupan permintaan tidak menyebutkan prototipe berfungsi. Dua
catatan untuk ronde berikutnya tercantum di D-1.1 dan D-2.1 di atas
(derivasi `muted` terang, dan varian sisa negatif yang belum digambar).

**10 September 2026 (lanjutan)** — Pemeriksaan berkas kerja sebelum
penerbitan menemukan beberapa berkas tema terang memakai warna yang
tidak cocok dengan tabel hex ADR-0006 (token `--surface`/`--card`
tertukar di `EditRowLight.dc.html` dan `RolloverLight.dc.html`; teks
badge `needsReview`/`investment` memakai hex literal yang lebih gelap
dari token aslinya di beberapa tempat, termasuk di lembar token
`TokenSheet.dc.html` sendiri). Semua sudah diperbaiki agar memakai hex
ADR-0006 apa adanya, canvas diseed ulang dan diterbitkan ulang ke
tautan yang sama (Version 2).

⚠ Catatan untuk ronde implementasi: hex `needsReview` (`#F59E0B`) dan
`investment` (`#D4A020`) di tema terang kemungkinan kontrasnya tipis
untuk teks kecil di atas kartu putih/hampir putih (ditemukan saat
pemeriksaan, belum divalidasi dengan alat kontras). Draf sebelumnya
memakai hex lebih gelap yang tidak ada di ADR-0006 sebagai perbaikan
sementara — itu dibalik ke hex asli supaya token tetap sama persis
dengan ADR-0006, tapi keputusan akhir (tambah varian teks khusus di
ADR-0006, atau terima kontrasnya) perlu keputusan pemilik saat
implementasi.
