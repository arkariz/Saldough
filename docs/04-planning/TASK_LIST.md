# Daftar tugas dan progres

Dokumen ini adalah daftar kerja Saldough beserta status penyelesaiannya.
Perbarui kotak centang di sini setiap kali sebuah tugas selesai.

Untuk alasan di balik urutan fase, lihat [ROADMAP.md](ROADMAP.md). Untuk
pekerjaan desain visual, lihat
[UI_UX_DESIGN_TASKS.md](done/UI_UX_DESIGN_TASKS.md). Perbaikan hasil review UX
27 Sep 2026 (UX dan UI) punya daftar kerja sendiri di
[UX_REVIEW_FIXES.md](done/UX_REVIEW_FIXES.md) — **baca juga saat mengecek
progres**; ringkasannya ada di tabel di bawah. Daftar kerja Saldough 1.0
beserta seluruh catatan pengerjaannya diarsipkan di
[TASK_LIST-1.0.md](../99-archive/TASK_LIST-1.0.md).

## Cara memakai dokumen ini

Setiap tugas punya identitas `T-<fase>.<nomor>` dan diakhiri baris
`Memenuhi FR-xxx.` yang menautkannya ke
[PRD 2.0](../01-product/prd-saldough-2.0.md). Tanda `⚠` menandai jebakan yang
sudah diketahui — baca sebelum mengerjakan tugasnya, bukan sesudah.

Kotak dicentang hanya kalau pekerjaannya benar-benar selesai **dan**
terverifikasi. Pekerjaan sebagian tetap kosong disertai catatan `⚠ Sebagian`.

### Menambah tugas baru (improvement atau fitur)

1. **Belum dijadwalkan?** Tambahkan satu baris ke tabel
   [Antrean](#antrean-belum-dijadwalkan) dengan nomor `B-<n>` berikutnya.
   Cukup satu kalimat, penanggung jawab (agen atau pemilik), dan tautan
   sumbernya.
2. **Siap dikerjakan?** Pindahkan ke fase yang sedang berjalan (sekarang
   Fase 8, tindak lanjut pasca-MVP) sebagai `- [ ] **T-8.<n>**` dengan nomor
   berikutnya, pakai templat di bawah, lalu hapus baris `B-<n>`-nya dan tulis
   `(dari B-<n>)` di tugas barunya. Kelompok besar yang berdiri sendiri
   (mis. sinkronisasi) membuka fase baru, `## Fase 10`, dan satu baris di
   [ROADMAP.md](ROADMAP.md).
3. **Selesai?** Centang, isi hasilnya (apa yang diverifikasi dan bagaimana),
   perbarui tabel **Ringkasan progres** dan tanggalnya, dan kalau perlu
   `.claude/CLAUDE.md` bagian "Status".
4. **Menyentuh kebutuhan produk?** Tambahkan barisnya ke tabel
   [Cakupan requirement](#cakupan-requirement). Keputusan arsitektur baru
   ditulis sebagai ADR (nomor berikutnya di `docs/02-architecture/adr/`,
   daftarnya di [docs/README.md](../README.md)).
5. **Butuh keputusan pemilik?** Tulis di
   [Keputusan terbuka](#keputusan-terbuka) sebagai `KT-<n>`, jangan menebak
   di kode.

Templat tugas:

```markdown
- [ ] **T-8.<n>** <Judul satu baris> (dari B-<n> / tanggal / sumber).
      <Konteks: apa yang salah atau dibutuhkan, dan mengapa sekarang.>
      ⚠ <Jebakan yang sudah diketahui, kalau ada.>
      Verifikasi: <uji atau pemeriksaan yang membuktikan selesai>.
      Memenuhi FR-xxx.   <!-- atau "Di luar PRD: <alasan>" -->
```

## Ringkasan progres

Terakhir diperbarui: 1 Oktober 2026 (911 uji lulus, 95 berkas uji, 39.746 baris sesudah Fase 13; 901 uji lulus sesudah M4 berjalan; sebelumnya 867 uji lulus, 88 berkas uji, 34.516 baris Dart di `lib/` tanpa `.g.dart`).

| Fase | Tugas | Selesai | Status |
|---|---|---|---|
| 0 — Dokumen Saldough 2.0 | 14 | 14 | Selesai |
| 1 — Domain inti: dompet dan transaksi | 9 | 9 | Selesai |
| 2 — Layar inti: CATAT, Transaksi, Dompet | 12 | 12 | Selesai |
| 3 — Cutover | 9 | 9 | Selesai |
| 4 — Anggaran | 11 | 11 | Selesai |
| 5 — Freelance | 9 | 9 | Selesai |
| 6 — Beranda | 6 | 6 | Selesai |
| 7 — Template dan poles | 6 | 6 | Selesai (T-7.7 deprecated) |
| **Total MVP** | **76** | **76** | |
| 8 — Tindak lanjut pasca-MVP | 12 | 11 | Berjalan -- T-8.12 (fokus CATAT tidak melompat) selesai 1 Okt 2026; T-8.11 (dialog dan pemilih tanggal pixel, dari B-18) selesai 1 Okt 2026; T-8.10 (`PixelTheme` jadi tema global, ADR-031) selesai 1 Okt 2026; T-8.3 (ganti nama) sisa pekerjaan kode/dokumen setelah prasyarat pemilik selesai; T-8.4 (identitas/Analytics/Crashlytics, ADR-023) selesai; T-8.5 (akun lebih matang, ADR-024), T-8.6 (mata uang, ADR-025), dan T-8.8 (label navigasi 360dp, chip nominal i18n) selesai; T-8.7 (persiapan rilis Android; closed testing sudah dipublikasikan pemilik) dan T-8.9 (hapus `example_note`) selesai; sisa T-8.3 hanya sapuan nama di dokumen dan ikon iOS |
| 9 — Onboarding, info, dan tur spotlight ([ONBOARDING_PLAN.md](../01-product/features/ONBOARDING_PLAN.md)) | 11 | 11 | Selesai 28 Sep 2026 |
| 11 — Catat Cerdas: kategori, suara, dan notifikasi ([VOICE_INPUT_RESEARCH.md](../01-product/features/VOICE_INPUT_RESEARCH.md), [ADR-032](../02-architecture/adr/0032-catat-dari-notifikasi.md)) | 24 | 15 | Berjalan -- T-11.9 benchmark teks selesai 1 Okt 2026 (Gemini dipertahankan; T-11.23/11.24 diperbaiki, T-11.22 gerbang kaskade "jenis tanpa kata arah" selesai: kasus sulit 73% → 90%), transkrip suara nyata belum; M4 catat dari notifikasi (T-11.17–11.21, ADR-032) dimulai 1 Okt 2026; T-11.16 (bahasa bawaan onboarding tersimpan, dari B-17), T-11.1–11.4, T-11.7 (Firebase AI, menunggu setelan Console), T-11.10, T-11.15 (temuan verifikasi kode M2/M3), T-11.14 (tanya bahasa ucapan untuk pengguna lama), dan T-11.11–11.13 (paket bahasa id/en, tanggal pasti, angka polos IDR, penyusun draf; ADR-029) selesai (verifikasi M1 lulus sesudah perbaikan); T-11.5 kode sudah di-commit tapi belum dicentang (ucapan nyata belum diuji); berikutnya T-11.6/11.7 |
| 12 — Rapikan batas arsitektur ([ADR-030](../02-architecture/adr/0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md)) | 6 | 6 | Selesai 1 Okt 2026 -- batas zona, kunci rute, sinyal buku besar, dan uji batas impor |
| 13 — Pecah fitur `record` ([ADR-033](../02-architecture/adr/0033-pecah-fitur-record.md)) | 6 | 6 | Selesai 1 Okt 2026 -- perbaikan penangkap notifikasi, `shared/capture`, fitur `notification_capture` dan `voice_capture`; `record` 11.249 → 2.945 baris |
| 14 — Bahasa visual baru ([ADR-034](../02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md), [docs/03-design](../03-design/README.md)) | 12 | 0 | Direncanakan 3 Okt 2026 -- desain disetujui pemilik lewat sampel; mulai dari T-14.1 |
| 15 — Rencana dan rutin, R1 ([ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md), Accepted) | 15 | 12 | Berjalan sejak 2 Okt 2026 -- ADR-035 disetujui pemilik; R1a T-15.1–15.9, R1b T-15.10–15.14, perbaikan T-15.15 |
| UX/UI — perbaikan hasil review ([UX_REVIEW_FIXES.md](done/UX_REVIEW_FIXES.md)), di luar MVP | 22 | 22 | Selesai; UX-1 dikerjakan bersama T-9.6 |
| Situs web — landing, `/beta`, dokumen hukum (repo `arkariz/tanukonomy-web`, daftar tugas di `docs/TASKS.md` repo itu) | 6 | 6 | Selesai 28 Sep 2026; P-1 s.d. P-6 menunggu pemilik (domain, email kontak, tinjau dokumen hukum, Google Group dan closed testing, Cloudflare Pages) |
| Persiapan Play Console — draf jawaban [PLAY_DATA_SAFETY.md](../03-release/PLAY_DATA_SAFETY.md) (Keamanan Data) dan [PLAY_STORE_LISTING.md](../03-release/PLAY_STORE_LISTING.md) (setelan toko, ASO) | 2 | 2 | Draf selesai (Keamanan Data 28 Sep, listing 29 Sep 2026); isi formulir persis sebelum build berfitur ini diunggah, jangan sebelum itu. Keputusan pemilik di §1 listing masih terbuka |
| Antrean (`B-n`, belum dijadwalkan) | 20 | 0 | Lihat [Antrean](#antrean-belum-dijadwalkan); nomor `B-n` tidak dipakai ulang |

## Keputusan terbuka

Hal yang butuh keputusan pemilik sebelum dikerjakan. Hapus entri begitu
diputuskan, dan catat keputusannya di tugas atau ADR yang mengerjakannya.

- **KT-2** Nasib data lokal saat pengguna **keluar** dari akun yang sudah
  terikat sinkronisasi: tetap di perangkat, atau ditawarkan untuk dihapus?
  Baru relevan saat sinkronisasi didesain —
  [ADR-024](../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md)
  §3.3 poin 4. (Ganti akun sudah diputuskan: data diganti dengan peringatan,
  tanpa penggabungan.)

KT-3 (cara migrasi label kategori lama, temuan F1 verifikasi M1) diputuskan
30 Sep 2026: dibiarkan apa adanya karena belum ada pengguna dengan data
lama — dicatat di ADR-026 §3.4.

KT-1 (ringkasan anggaran memindai seluruh riwayat transaksi) diputuskan
27 Sep 2026 dan dikerjakan di T-8.1.

## Fase 0: Dokumen Saldough 2.0

Tidak ada kode aplikasi di fase ini. Urutannya meniru urutan penulisan Saldough
1.0: istilah dulu, lalu produk, lalu domain, lalu keputusan arsitektur, baru
rencana kerja.

- [x] **T-0.1** Tandai keadaan repositori sebelum pivot, pindahkan dokumen
      perencanaan 1.0 ke `docs/99-archive/`, dan tulis indeks arsipnya.
      Tag `pre-pivot-1.0` di-push pemilik dari mesinnya sendiri, sebab relay
      git lingkungan agen ini hanya mengizinkan pembaruan `refs/heads/*`. Tag
      sudah terkonfirmasi ada di remote dan menunjuk commit `13c7939`, persis
      seperti dicatat di [indeks arsip](../99-archive/README.md).
- [x] **T-0.2** Tulis ulang `PROJECT_GLOSSARY.md` dengan istilah baru, sekalian
      betulkan drift `Failure` yang usang sejak ADR-0005 dibalik.
- [x] **T-0.3** Tulis `prd-saldough-2.0.md` mengikuti kerangka §1–§14 versi 1.0.
- [x] **T-0.4** Tulis ulang `user-stories.md`.
- [x] **T-0.5** Tulis ulang `DOMAIN_MODEL.md` dengan sembilan entitas, rumus, dan
      invariannya.
- [x] **T-0.6** Tulis ADR-011 sampai ADR-014.
- [x] **T-0.7** Tandai ADR-0006 dan ADR-0008 digantikan; beri ADR-0002 catatan
      perluasan.
- [x] **T-0.8** Sunting terarah `ARCHITECTURE_OVERVIEW.md`.
- [x] **T-0.9** Tulis ulang `ROADMAP.md` dengan prinsip penyusunan fase baru.
- [x] **T-0.10** Tulis `TASK_LIST.md` baru berisi breakdown seluruh fase.
- [x] **T-0.11** Tulis `UI_UX_DESIGN_TASKS.md` baru.
- [x] **T-0.12** Perbarui `docs/README.md`: pohon dokumen, daftar ADR, jalur
      baca.
- [x] **T-0.13** Tulis ulang `.claude/CLAUDE.md` dan `.claude/AGENT_CONTEXT.md`.
      ⚠ Kedua berkas ini disuntik ke konteks tiap sesi. Isi yang basi bukan
      cuma memboroskan, tapi menyesatkan agent berikutnya.
- [x] **T-0.14** Verifikasi seluruh tautan relatif `docs/` hidup, tidak ada ADR
      yang dirujuk tapi belum ada, lalu commit dan push.
      Terverifikasi 17 September 2026: seluruh tautan relatif di `docs/` dan
      `.claude/` resolve, tidak ada ADR yang dirujuk tapi belum ada, dan
      `git diff --name-only 13c7939..HEAD -- lib test pubspec.yaml assets tool`
      mengembalikan **nol berkas** — bukti lebih kuat daripada menjalankan
      ulang `analyze`/`test`, karena tidak ada kode yang bisa berubah
      hasilnya. `flutter analyze` tetap 0 isu.

## Fase 1: Domain inti — dompet dan transaksi

Tanpa UI sama sekali. Fase ini membangun buku besar yang belum pernah ada di
Saldough 1.0.

⚠ **Invarian fase ini dan Fase 2.** Tidak satu pun berkas di
`lib/features/{cycle,card,investment,grocery,income}` atau `lib/shared/goal`
boleh disentuh. Dibuktikan tiap PR dengan `git diff --stat`. Seluruh uji lama
wajib tetap lulus tanpa disunting — kalau ada yang gagal, itu bukti fitur baru
menyentuh sesuatu yang seharusnya tidak. Lihat
[ADR-014](../02-architecture/adr/0014-strategi-pivot-saldough-2.md).

### Dompet

- [x] **T-1.1** Buat `shared/wallet/domain/`: entitas `Wallet` dan antarmuka
      `WalletRepository`.
      ⚠ `Wallet` masuk `shared/`, bukan `features/`, karena dibaca
      `transaction`, `budget`, `freelance`, dan `home` — ambang "2+ konsumen"
      [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md)
      terpenuhi sejak awal.
      Memenuhi FR-WAL-001 dan FR-WAL-002.
- [x] **T-1.2** Buat `shared/wallet/data/`: `WalletModel` dengan
      `schemaVersion`, dan `WalletRepositoryImpl` di atas kunci `wallet/all`.
      Memenuhi FR-WAL-001 dan NFR-REL-003.

### Transaksi

- [x] **T-1.3** Buat `shared/transaction/domain/`: `Transaction` sebagai
      `sealed class` dengan `IncomeTransaction`, `ExpenseTransaction`, dan
      `TransferTransaction`, beserta antarmuka `TransactionRepository`.
      ⚠ Nominal selalu positif; arah uang ditentukan jenis transaksinya. Dan
      `fromWalletId` tidak boleh sama dengan `toWalletId`.
      ⚠ `ExpenseTransaction` **dan** `TransferTransaction` sama-sama punya
      `budgetItemId`. Transfer bisa memenuhi pos anggaran berupa rencana
      pemindahan, misalnya setoran tabungan.
      Memenuhi FR-TXN-001, FR-TXN-002, dan FR-TXN-003.
- [x] **T-1.4** Buat `shared/transaction/data/`: `TransactionModel` dan
      `TransactionRepositoryImpl` dengan **partisi per bulan** — kunci
      `transaction/YYYY-MM` plus indeks `transaction/_index`.
      ⚠ Bulan tujuan ditentukan `transaction.date`, bukan `DateTime.now()`.
      ⚠ Penyuntingan yang memindahkan transaksi antar bulan wajib menghapus
      dari dokumen asal **sebelum** menambah ke dokumen tujuan, supaya
      kegagalan di tengah tidak menghasilkan transaksi ganda.
      Memenuhi FR-TXN-004, FR-TXN-005, dan NFR-PERF-002.
- [x] **T-1.5** Buat use case `CalculateWalletBalance` — Dart murni, menghitung
      saldo dari `initialBalance` ditambah seluruh transaksi yang menyentuh
      dompet itu.
      Memenuhi FR-WAL-003 dan NFR-ACC-003.
- [x] **T-1.6** Terapkan pemeliharaan `Wallet.currentBalance` saat transaksi
      dicatat, disunting, atau dihapus, beserta `recomputeWalletBalances()`.
      ⚠ Urutan penulisan mengikat: dokumen transaksi lebih dulu, dokumen dompet
      menyusul. Transaksi adalah kebenaran, saldo adalah cache-nya. Lihat
      [ADR-012](../02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md).
      Diterapkan sebagai `RecordTransaction` (shared/transaction/domain/
      usecases/) yang membungkus `TransactionRepository.saveTransaction`/
      `deleteTransaction` lalu memanggil `RecomputeWalletBalances.forWallets`
      untuk dompet yang terdampak — bukan aritmetika delta, supaya tidak ada
      kelas galat "drift" akibat penjumlahan bertahap.
      Memenuhi NFR-ACC-003 dan NFR-PERF-002.

### Verifikasi dan wiring

- [x] **T-1.7** Tulis uji domain dan data dengan angka nyata: `netPay` kotor
      3.117.500 pajak 2,5% menghasilkan 3.039.563 (sudah ada di
      `test/shared/income/`, dari sebelum pivot); saldo awal 5.000.000 dengan
      masuk 2.615.438, keluar 3.068.500, dan transfer keluar 1.000.000
      menghasilkan 3.546.938.
      ⚠ **Uji saldo tersimpan versus saldo turunan wajib ada.** Tanpa uji yang
      membuktikan `wallet.currentBalance` identik dengan hasil
      `recomputeWalletBalances()`, keputusan menyimpan nilai turunan di ADR-012
      tidak boleh diambil sama sekali.
      ⚠ Uji juga wajib membuktikan transfer tidak mengubah total saldo seluruh
      dompet.
      Memenuhi NFR-ACC-001, NFR-ACC-002, dan NFR-ACC-003.
- [x] **T-1.8** Daftarkan `WalletRepository` dan `TransactionRepository` di
      `RootModule`.
      ⚠ Hanya **ditambahi**. Tidak satu pun baris lama di `RootModule` boleh
      diubah atau dihapus sampai Fase 3.
      ⚠ **Selesai penuh.** `WalletRepository` terdaftar bersama T-1.1/T-1.2,
      `TransactionRepository` terdaftar bersama T-1.3/T-1.4.
- [x] **T-1.9** Tambahkan namespace i18n `wallet` dan `transaction` di
      `assets/i18n/{id,en}.i18n.json`, lalu regenerasi slang.
      ⚠ Namespace lama (`cycle`, `grocery`, `card`, `investment`, `worklog`,
      `income`) **tidak** dihapus di fase ini — layar lama masih memakainya dan
      penghapusannya akan membuat `flutter analyze` merah. Dihapus di T-3.6.
      ⚠ **Kotak baru dicentang saat cutover (25 September 2026).** Namespace
      `wallet` dan `transaction` sudah ada dan dipakai layar Fase 2 sejak
      lama; hanya kotaknya yang terlewat.
      Memenuhi NFR-UX-004.

## Fase 2: Layar inti — CATAT, Transaksi, Dompet

Akhir fase ini aplikasi baru sudah bisa dipakai sehari-hari: mencatat
pemasukan, pengeluaran, dan transfer, lalu melihat saldonya.

⚠ Invarian "jangan sentuh fitur lama" dari Fase 1 masih berlaku penuh.

### Fondasi tampilan

- [x] **T-2.1** Buat `AppIcon(IconKey)` di `lib/core/presentation/widgets/`
      dengan 32 kunci semantik dalam tujuh kelompok.
      ⚠ `IconKey` adalah `enum` supaya kunci yang belum dipetakan gagal saat
      kompilasi, bukan saat dijalankan.
      ⚠ **Diselesaikan lebih awal dari rencana semula** — rencana T-2.1 di
      atas ditulis sebelum paket aset pemilik tiba, dan mengasumsikan seluruh
      ikon memakai isian Material sampai T-7.4. ADR-015 (sudah *Accepted*
      sebelum T-2.1 dikerjakan) mengubah itu secara eksplisit: 67 SVG asli
      32×32 di `docs/stitch_pixel_finance_tracker/icon_*/code.html` "siap
      dikonversi jadi aset Flutter... saat T-7.4/T-2.1 dikerjakan". 23 dari 32
      `IconKey` memakai SVG asli itu (dikonversi ke `assets/icons/*.svg`,
      dirender lewat `flutter_svg`, ditambahkan sebagai dependensi baru);
      sisanya tetap ikon Material sementara karena memang belum ada padanan
      asetnya (ADR-015 §7 "Aset cadangan"): `add`, `edit`, `delete`,
      `chevronLeft`, `chevronRight`, tiga kunci kategori
      (`categoryHousehold`, `categoryBills`, `categoryOther`, menunggu
      daftar kategori final), dan `empty` (asetnya satu lembar sprite
      1024×1024 belum terpotong per keadaan kosong — pemotongannya
      ditunda ke saat layar keadaan-kosong nyata dibangun, T-2.7/T-2.11 dst,
      bukan bagian lapisan kunci ikon murni).
      Memenuhi NFR-UX-002.
- [x] **T-2.2** Tambahkan slot warna `accent`, `onAccent`, `transfer`, dan
      `pending` ke `AppColorsExtension`, beserta uji kontrasnya.
      ⚠ Slot lama (`investment`, `rollUp`, `needsReview`, `onNeedsReview`, dan
      keenam varian `…OnLight`) **tidak** dihapus di fase ini — layar lama
      memakainya. Dihapus di T-3.5.
      ⚠ Nilai hex dan rasio kontrasnya sudah ditetapkan di
      [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md).
      Jangan mengarang nilai baru. `overBudget` dan `transfer` masing-masing
      berbagi hex dengan `expense` dan `textMuted` — itu disengaja, bukan
      salah salin.
      ⚠ **Dikerjakan literal sesuai cakupan di atas** — hanya EMPAT slot ini
      yang ditambahkan. ADR-015 sendiri menyatakan "enam slot semantik
      dipertahankan dari ADR-013; nilainya diganti seluruhnya" (mencakup
      `income`, `expense`, `overBudget` juga, bukan cuma keempat slot di
      atas), tetapi TASK_LIST ini secara eksplisit hanya meminta menambah
      `accent`/`onAccent`/`transfer`/`pending` — nilai `income`, `expense`,
      `overBudget`, `background`, `cardBackground`, `textPrimary`,
      `textMuted` di kelas ini **tidak disentuh**, tetap ADR-0006 lama.
      Belum ada tugas bernomor yang menugaskan penggantian penuh ketujuh
      slot itu (T-3.5 hanya menghapus empat slot `investment`/`rollUp`/
      `needsReview`/`onNeedsReview`, bukan mengganti nilai `income`/
      `expense`/dst). **Keputusan terbuka** untuk pemilik: kapan/di tugas
      mana palet penuh ADR-015 (termasuk bayangan keras dan bilah progres
      tersegmentasi yang disebut ADR-015 §7) diadopsi untuk seluruh
      aplikasi — kandidat wajar adalah menjelang/saat T-3.5 (cutover),
      karena baru di situ layar lama yang bergantung ke nilai ADR-0006
      dihapus.
      ⚠ **Celah ADR-015 diisi manual**: ADR-015 hanya menyatakan kontras
      teks putih di atas `accent` untuk mode TERANG (6,46:1); tidak ada
      padanan mode gelap. Teks putih di atas `accent` gelap (`#E95100`)
      cuma 3,72:1 — gagal ambang 4,5:1. `onAccent` gelap di sini memakai
      `#14120F` (nilai `background` gelap ADR-015 sendiri, bukan warna
      baru) yang menghasilkan 5,02:1 terhadap `accent` gelap — ADR-015
      sudah mencatat pasangan hex yang sama itu di tabelnya. Ini pengisi
      celah, bukan keputusan ADR-015 — tinjau ulang kalau pemilik punya
      preferensi lain untuk warna teks di atas tombol CATAT mode gelap.
      Memenuhi NFR-UX-003.
- [x] **T-2.3** Buat `AppShellPage` di `lib/core/presentation/shell/` — lima
      tujuan dengan CATAT di tengah, `IndexedStack`, didaftarkan di rute
      sementara `/shell`.
      ⚠ Berkas baru dengan nama baru. `main_shell_page.dart` yang lama tidak
      disentuh sampai T-3.4.
      ⚠ CATAT bukan tujuan navigasi biasa: ia tidak mengganti isi
      `IndexedStack`, melainkan membuka lembar pilihan.
      Isi keempat tab lain (Beranda/Anggaran/Transaksi/Dompet) dan lembar
      CATAT masih `_ComingSoonTab`/isian sementara — fiturnya sendiri belum
      ada (Transaksi T-2.5, Dompet T-2.7, Anggaran Fase 4, Beranda Fase 6,
      CATAT sungguhan T-2.4). Menukarnya jadi layar nyata adalah edit
      lokal di `app_shell_page.dart`, bukan menulis ulang shell.
      `AppRouteRegistry.build` ditambahi param opsional `shellBuilder`
      untuk mendaftarkan `/shell` — `homePath`/`MainShellPage` tidak
      disentuh, rute `/shell` hanya bisa dibuka manual (mis. lewat
      `context.go('/shell')` atau navigasi langsung saat uji manual T-2.10),
      belum ditautkan dari mana pun di alur pemakaian normal.
      Memenuhi FR-REC-001.
- [x] **T-2.12** Sistem desain ADR-015 penuh untuk layar baru: palet
      `pixelLight`/`pixelDark`, tiga peran huruf (Space Grotesk/Plus
      Jakarta Sans/Space Mono), `AppHardCard` (bayangan keras offset), dan
      `AppSegmentedProgressBar`, dipasang lewat `PixelTheme` yang
      membungkus `AppShellPage`.
      ⚠ **Dimajukan atas permintaan eksplisit pemilik** — sebelumnya ini
      terpecah antara `D-2.1` (kanvas desain, belum dikerjakan) dan
      **T-7.5** (kode, aslinya dijadwalkan akhir MVP: "kalau belum
      dikerjakan langsung di fase masing-masing"). Pemilik memilih
      mengerjakannya sekarang supaya seluruh layar Fase 2 dan seterusnya
      langsung memakai bahasa visual final, bukan menambal di T-7.5.
      ⚠ **`PixelTheme` bukan tema aplikasi global.** `AppTheme`/ADR-0006
      tetap dipakai `MaterialApp` (layar lama tidak disentuh dan tidak
      berubah tampilannya). `PixelTheme` dipasang SATU KALI di
      `AppShellPage`, membungkus seluruh tab dan lembar yang dibukanya
      (termasuk lembar CATAT — `Theme` Flutter otomatis diteruskan ke
      `showModalBottomSheet`/`showDialog` lewat `InheritedTheme.capture`,
      dibuktikan lewat tes). Layar baru berikutnya (T-2.5 dst.) otomatis
      mewarisi bahasa visual ini cukup dengan dirender di dalam shell,
      tanpa perlu membungkus dirinya sendiri.
      ⚠ `income`/`expense`/`overBudget`/`background`/`cardBackground`/
      `textPrimary`/`textMuted` versi ADR-015 TIDAK menimpa slot lama
      `AppColorsExtension.light`/`dark` (dipakai layar lama, dan ada uji
      regresi yang menegaskan nilai itu tidak berubah) — disimpan sebagai
      instance BARU `AppColorsExtension.pixelLight`/`pixelDark` (`copyWith`
      dari yang lama), dipilih otomatis lewat `PixelTheme` berdasar
      `Brightness` ambient. Ini menuntaskan keputusan terbuka T-2.2 soal
      kapan/di mana palet penuh ADR-015 diadopsi.
      ⚠ Token baru (`AppRadius.pixelSm`, `AppBorder.pixelThick`,
      `AppElevation.pixelCard`/`pixelInteractive`) ditambahkan sebagai
      ANGGOTA BARU di kelas token yang sudah ada (bukan kelas baru maupun
      menimpa nilai lama) — `AppRadius.sm`/`AppBorder.thick`/dst. milik
      ADR-0006 tidak berubah, tetap dipakai layar lama.
      ⚠ Ambang warna `AppSegmentedProgressBar` (income <70%, pending
      70–100%, overBudget ≥100%) mengisi celah kecil di teks ADR-015
      sendiri (yang hanya eksplisit menyebut "70–90%" untuk `pending`) —
      lihat komentar kelasnya untuk penalarannya, tinjau ulang kalau
      pemilik menginginkan potongan persen berbeda.
      ⚠ Belum dikerjakan: kanvas desain visual `D-2.1` itu sendiri (mockup
      di alat desain), dan retrofit `AppButton`/`AppChip`/`AppCard` supaya
      bentuknya (bukan cuma warnanya) ikut ADR-015 — keduanya bukan
      penghalang untuk mulai memakai `PixelTheme` di layar baru.
      Memenuhi NFR-UX-003. Sebagian memenuhi maksud `D-2.1` dan `T-7.5`
      (dicatat silang di kedua tempat itu).

### Pencatatan dan riwayat

- [x] **T-2.4** Buat `features/record/`: lembar CATAT beserta tiga formulir —
      pemasukan, pengeluaran, dan transfer.
      ⚠ Ini satu-satunya jalur pembuatan transaksi manual. Jangan membuat
      formulir pencatatan tersendiri di layar mana pun.
      ⚠ Kosakata tombol dan pesan menyatakan pencatatan, bukan tindakan
      keuangan. "Catat Transfer", bukan "Transfer Sekarang".
      ⚠ **Kategori transaksi adalah field teks bebas**, bukan daftar pilihan
      tertutup — `PROJECT_GLOSSARY.md` §"Konvensi penamaan" eksplisit:
      "Nama dompet dan kategori disimpan sebagai data, bukan sebagai enum.
      Pemilik bisa menambah atau mengubahnya tanpa mengubah kode." Enam
      `categoryFood`/`categoryTransport`/dst. di `IconKey` (T-2.1) TIDAK
      dipakai sebagai daftar pilihan formulir ini — itu kunci ikon, bukan
      kamus kategori.
      ⚠ Tautan ke pos anggaran (bagian FR-TXN-002) belum ada di formulir
      pengeluaran — `Budget` baru dibangun Fase 4 (T-4.4), mengikuti pola
      "tidak ditampilkan, bukan ditampilkan kosong" yang sama seperti baris
      anggaran di T-2.11.
      ⚠ FR-TXN-003 ("menolak transfer ke dompet yang sama") ditegakkan DUA
      kali: `assert` di `TransferTransaction` (Fase 1, tidak berjalan di
      rilis production) DAN tombol Catat yang dinonaktifkan di formulir ini
      kalau dompet asal/tujuan sama — baris pertahanan yang benar-benar
      jalan di production adalah yang di formulir.
      ⚠ **Tampilan direvisi mengikuti rujukan visual** (`pixel_kas_catat_transaksi`,
      `..._pemasukan`, `..._pengeluaran`, `..._transfer_antar_dompet`) setelah
      pembangunan awal yang masih widget Material polos. Pemilih jenis dan
      ketiga formulir kini layar penuh (`showFullScreenSheet`: `isScrollControlled` +
      `useSafeArea`) berkerangka `RecordFormFrame` (kop "Langkah 2 // Transaksi",
      kartu bantuan, tombol simpan berwarna jenis, catatan kaki). Nominal =
      kartu berkotak angka besar + pilihan cepat `+10rb`; tanggal = pintasan
      Hari Ini/Kemarin + kotak tanggal (jam dipertahankan saat hari digeser);
      tiap formulir menutup dengan kartu ringkasan akibat pada saldo.
      ⚠ **Kategori dan dompet dipilih lewat dropdown yang SAMA dengan penyaring
      layar Transaksi** (`AppMenuSelectButton`, dulu `_FilterMenuButton`
      privat, kini di `core/presentation/widgets/`), bukan kisi ubin, daftar
      terbuka, atau lembar pemilih -- keputusan pemilik supaya seluruh pilihan
      dropdown di aplikasi seragam. `RecordCategoryField`: menu berisi saran +
      "Lainnya" (membuka kolom ketik bebas) + "Tanpa kategori". `WalletSelectField`
      (transfer memakai kop titik + lencana selisih, `showDelta`): nama dompet
      membungkus pada tombolnya, tidak dipotong.
      ⚠ Pemilih jenis dibedakan menurut fungsinya: kop = bilah datar, kartu info
      = pita tanpa bayangan, dan tiga kartu jenis masing-masing bernuansa warna
      jenisnya (garis aksen, latar, bilah aksi penuh) dengan diagram alur uang
      (`Luar → + Dompet`, `− Dompet → Luar`, `− Dompet asal → + Dompet tujuan`).
      Seluruh warna dari token ADR-016 (`kindInk`/
      `kindFill`), tanpa hex harfiah. `TransactionSlab`, `TransactionKind`,
      `transactionLabelStyle`, dan `categoryIconFor` dipindah ke
      `lib/core/presentation/widgets/` supaya `record` dan `transaction`
      memakainya tanpa saling mengimpor (aturan tiga zona).
      ⚠ Bagian rujukan yang SENGAJA tidak dibangun: "Biaya Admin / Transfer"
      (`TransferRecorded` tidak punya biaya; mencatatnya = keputusan domain
      baru berupa transaksi pengeluaran pendamping), "Alokasikan ke Anggaran
      Bulanan?" (Fase 4, T-4.4), kartu "Catat ke Freelance Worklog" (Fase 5),
      dan gamifikasi "LVL +10 EXP" (bukan kebutuhan produk). Tombol "+ Kustom"
      di kop kategori digantikan ubin "Lainnya".
      ⚠ Ikon kategori pemasukan (Gaji/Bonus/Penjualan/Hadiah) masih ikon
      `income` generik -- paket ikon pemilik belum punya ikon per kategori
      pemasukan.
      `RecordBloc` dipasang lewat `ScopeWidget<RecordScope>` yang
      membungkus `AppShellPage` (bukan dibuat ulang tiap lembar CATAT
      dibuka), supaya efek galat/berhasilnya tetap tampil walau kedua
      lembar (pilihan lalu formulir) sudah tertutup.
      Memenuhi FR-REC-001, FR-TXN-001, FR-TXN-002, FR-TXN-003, NFR-UX-001, dan
      NFR-UX-005.
- [x] **T-2.5** Buat `features/transaction/`: daftar riwayat dikelompokkan per
      tanggal, dengan penyaring jenis, dompet, dan kategori.
      ⚠ **Bidang pencarian teks DIBANGUN belakangan**, bukan di T-2.5 semula
      (yang sengaja menundanya karena tidak dituntut FR-TXN-004): ditambahkan
      saat layar disesuaikan dengan rujukan visual `pixel_kas_daftar_transaksi`.
      `TransactionSearchChanged` mencocokkan kategori, catatan, dan nama dompet;
      ikut menyaring daftar dan hitungan per jenis, tetapi TIDAK memengaruhi
      ringkasan bulan (`rawTransactions`).
      ⚠ Sistem desain ADR-015 (`PixelTheme`/`AppHardCard`/`AppChip`/
      `AppMoneyText`) dipakai SEJAK AWAL, bukan retrofit belakangan seperti
      T-2.4 -- setiap section (header ringkasan bulan, tiap kelompok tanggal)
      adalah `AppHardCard` tersendiri.
      ⚠ **Kategori tetap field bebas, bukan enum** -- `categoryOptions`
      dihitung `TransactionBloc` dari kunci kategori DISTINCT yang benar-benar
      muncul di transaksi bulan berjalan, dihitung ulang tiap bulan berganti,
      bukan daftar tetap (`PROJECT_GLOSSARY.md` §"Konvensi penamaan").
      ⚠ Penyaring dompet dan kategori dibangun sebagai DUA DROPDOWN ringkas
      berdampingan, bukan meniru persis baris chip mockup untuk elemen ini --
      FR-TXN-004 hanya menuntut "penyaring dompet dan kategori" ada, bentuk
      persisnya keputusan implementasi. Filter JENIS kini satu konsol
      segmen empat tab bergambar (`Row` + `Expanded`, BUKAN `Wrap` -- `Wrap`
      adalah bug yang sempat membuat chip CATAT tampil bertumpuk vertikal,
      lihat catatan T-2.4). Sesudah penyesuaian visual, kedua dropdown
      sama lebar di bawah kolom cari (sebelumnya kategori berdiri sendiri di
      satu baris), item dropdown bergambar (ikon jenis dompet dari
      `Wallet.iconKey`, ikon kategori lewat pencocokan kata kunci karena
      kategori teks bebas).
      ⚠ **`TransactionScope` dipasang BERSEBELAHAN dengan `RecordScope`**, di
      level `AppShellPage`, keduanya dibangun dari kontainer akar yang sama
      (ditangkap sekali di awal `build`) -- BUKAN bersarang di dalam
      `RecordScope` (yang kebetulan membawa `WalletRepository`/
      `TransactionRepository` juga, tapi mengandalkan itu akan membuat
      `TransactionScope` diam-diam bergantung pada `RecordScope`). Dipasang
      di level shell (bukan di dalam `TransactionListPage` sendiri) karena tab
      ini persisten selama shell hidup (`IndexedStack` menjaga seluruh tab
      tetap ada di pohon widget).
      ⚠ `AppShellPage._openRecordSheet` DIEKSTRAK jadi fungsi tingkat atas
      `openRecordSheet` (`features/record/presentation/open_record_sheet.dart`)
      supaya CTA keadaan kosong bulan bisa memicu alur CATAT yang SAMA persis
      (CLAUDE.md aturan 8), bukan formulir pencatatan tersendiri.
      ⚠ Dua keadaan kosong DIBEDAKAN: bulan genuinely belum ada transaksi
      (`rawTransactions` kosong) menampilkan ilustrasi + CTA CATAT; filter
      menyisakan nol hasil (transaksi ADA tapi tersaring semua) menampilkan
      pesan lebih singkat + tombol hapus filter, TANPA ilustrasi "belum ada
      transaksi" yang akan menyesatkan. Kegagalan pembacaan (`loadFailed`)
      keadaan KETIGA yang terpisah dari keduanya (pola `RecordState.loadFailed`
      T-2.4).
      ⚠ Warna dan ikon direvisi setelah pembangunan awal: palet pixel diganti
      [ADR-016](../02-architecture/adr/0016-revisi-palet-satu-peran-satu-warna.md)
      (satu peran satu warna; transfer biru, menyimpang dari ADR-015 atas
      keputusan pemilik) dan warna tertanam ikon pixel-art diselaraskan.
      Memenuhi FR-TXN-004.
- [x] **T-2.6** Tambahkan penyuntingan dan penghapusan transaksi.
      ⚠ Saat dompet sebuah transaksi berpindah, saldo dompet lama **dan** baru
      sama-sama dihitung ulang.
      ⚠ Pembetulan dilakukan dengan menyunting atau menghapus, tidak pernah
      dengan mencatat transaksi penyeimbang.
      ⚠ Logika domainnya sudah ada sejak T-1.6 (`RecordTransaction` dengan
      `previousTransaction` dan `delete`); tugas ini lapisan presentasinya:
      `TransactionBloc` menerima `TransactionUpdated`/`TransactionDeleted`,
      menulis lewat `RecordTransaction`, lalu memuat ulang dompet DAN transaksi
      bulan itu TANPA `isLoading` (daftar tidak berkedip jadi kerangka).
      Kegagalan tulis memancarkan galat dan tidak mengubah daftar maupun saldo.
      ⚠ **Sunting memakai ulang tiga formulir CATAT** (parameter `initial`),
      bukan formulir baru; pembukanya `openEditTransactionSheet` ada di
      `features/record` karena formulirnya milik fitur itu. Ini bukan jalur
      pembuatan (CLAUDE.md aturan 8): `id` dipertahankan dan transaksinya
      ditimpa. Objek hasil dibangun BARU, bukan lewat `copyWith`, karena
      `copyWith` (`?? this.x`) tidak bisa mengosongkan kategori yang dihapus.
      ⚠ **Formulir sunting menerima dompet dengan saldo SEBELUM transaksi itu
      ada.** `currentBalance` sudah memuat transaksi yang disunting, jadi tanpa
      pembalikan itu pratinjau saldo ("sebelum -> sesudah") mengurangkannya dua
      kali. Ditemukan lewat uji emulator (Rp425.000 -> Rp350.000 padahal tidak
      ada perubahan); tes regresinya ada di `transaction_list_page_test.dart`.
      ⚠ **`EffectListener<TransactionBloc>` dipasang di shell.** Sebelumnya
      efek `TransactionBloc` tidak didengarkan siapa pun, jadi snackbar hasil
      sunting/hapus tidak akan pernah tampil.
      ⚠ Keterbatasan yang diketahui: formulir hanya menerima rupiah utuh, jadi
      transaksi yang nominalnya punya sen pecahan dibulatkan ke bawah saat
      disunting. Belum bisa terjadi lewat UI (formulir CATAT juga rupiah utuh),
      tetapi bisa lewat data hasil impor.
      Memenuhi FR-TXN-005.
- [x] **T-2.11** Buat layar rincian satu transaksi: jenis, nominal, kategori,
      dompet, tanggal, catatan, beserta aksi sunting dan hapus.
      ⚠ Transfer memakai judul **Transfer tercatat** dan tata letak "Dari / Ke /
      Jumlah". Dilarang memakai "Transfer berhasil", "Pembayaran berhasil",
      atau "Kirim Uang" di mana pun. (Diuji: seluruh `Text` di layar transfer
      dipindai terhadap kosakata terlarang.)
      ⚠ Baris anggaran tertaut baru terisi setelah Fase 4; sampai itu bagiannya
      tidak ditampilkan, bukan ditampilkan kosong. Yang juga SENGAJA tidak
      dibangun dari rujukan visual: "ID catatan" (transaksi tidak punya nomor
      tampilan) dan kartu "Format Entri Transfer" (ilustrasi desain, bukan
      fitur).
      ⚠ Layar rincian adalah rute yang di-push, dan rute itu TIDAK mewarisi
      `Theme` maupun `BlocProvider` dari pohon asalnya (beda dengan
      `showModalBottomSheet`). `openTransactionDetail` memasang ulang
      `PixelTheme` dan `BlocProvider.value` dengan `TransactionBloc` yang SAMA,
      supaya sunting/hapus memuat ulang daftar di belakangnya.
      ⚠ Baris di daftar riwayat kini bisa diketuk; sebelumnya sengaja tidak
      interaktif karena layar ini belum ada.
      ⚠ Konten layar rincian TIDAK boleh terpotong atau meluap: kartu Dari/Ke
      ditumpuk vertikal (bukan berdampingan) dengan nama dompet yang membungkus
      ke banyak baris; baris label/nilai memakai `Wrap` sehingga nilai turun di
      bawah label kalau tidak muat. Diuji pada 360px + teks 2x dengan nama dompet,
      kategori, catatan, dan nominal miliaran; tes yang sama ikut menangkap
      header kelompok tanggal di daftar yang meluap.
      ⚠ `WalletPickerField` (kartu "Dari Dompet"/"Ke Dompet"/"Masuk ke Dompet"
      di tiga formulir CATAT) mengalami masalah yang sama dan diperbaiki: nama
      dompet + "Ganti" + panah + pratinjau saldo tidak lagi berdesakan dalam satu
      `Row` (kolom nama hanya ~150px di layar 360px; pratinjau saldo meluap 742px
      pada tes). Kini baris atas = ikon jenis dompet + nama membungkus + panah;
      pratinjau saldo (`Wrap` + `FittedBox`) dan "Ganti" di bawahnya. Ikon dompet
      kini per jenis (`walletIconKey`), bukan ikon generik.
      Memenuhi FR-TXN-006.

### Dompet

- [x] **T-2.7** Buat `features/wallet/`: daftar dompet, total saldo, serta
      tambah dan sunting dompet.
      ⚠ Saldo awal adalah pernyataan keadaan, bukan transaksi setoran. Ia tidak
      muncul di riwayat.
      ⚠ Diuji: dompet baru disimpan dengan `currentBalance == initialBalance`
      dan TIDAK ada `Transaction` yang lahir. Menyunting nama/ikon/status tidak
      menyentuh saldo tercatat; hanya mengganti saldo awal yang menghitungnya
      ulang lewat `RecomputeWalletBalances.forWallets` (penyeimbang tunggal,
      ADR-012). Kolom saldo awal hanya menerima rupiah utuh >= 0 (sama seperti
      formulir CATAT), jadi pada mode sunting saldo awal yang TIDAK disentuh
      dikirim `null` = tidak diubah, supaya nilai tersimpan yang tak terwakili
      kolom (negatif atau bersen pecahan) tidak tertimpa diam-diam.
      ⚠ Cakupan FR-WAL-001 penuh: tambah, sunting nama/ikon, nonaktifkan
      (sakelar "Dompet aktif"; dompet nonaktif tampil di bagian tersendiri dan
      tidak ikut total maupun pemilih dompet CATAT), dan hapus HANYA kalau
      belum punya transaksi sama sekali (`listAllTransactions` diperiksa untuk
      dompet pemasukan/pengeluaran DAN asal/tujuan transfer; ditolak dengan
      pesan "nonaktifkan saja"), dengan konfirmasi.
      ⚠ Saldo negatif tampil dengan warna `expense` dan tanda minus, bukan
      sebagai kesalahan (FR-WAL-003); total hanya menjumlahkan dompet aktif.
      ⚠ `WalletBloc` dipasang di shell lewat `WalletScope` (ketiga
      `ScopeWidget` bersarang, jadi uji shell butuh tiga `pump()`). Saldo
      disegarkan (`WalletRefreshed`, tanpa kerangka pemuatan) tiap tab Dompet
      dibuka dan sesudah alur CATAT, karena saldo bisa berubah lewat transaksi
      yang disunting/dihapus di tab lain.
      ⚠ Bagian rujukan yang sengaja tidak dibangun: "Atur Urutan" dan lencana
      "UTAMA" (tidak ada konsep urutan/dompet utama di domain), subjudul dan
      "Catatan tambahan" per dompet (`Wallet` tidak punya field catatan),
      "Tipe kategori" (jenis diturunkan dari ikon), tombol "Transfer Kas"
      (transfer hanya lewat CATAT, aturan 8), hitungan "transaksi bulan ini"
      per dompet, dan kartu "Konsep Kantong Kas". Kartu dompet sementara
      membuka formulir sunting; T-2.8 menggantinya dengan layar rincian.
      ⚠ Komponen yang dipakai bersama `record` dan `wallet` diangkat ke
      `lib/core/presentation/widgets/`: `AppSectionLabel`, `AppQuickChip`,
      `FitStart`, `showFullScreenSheet`, dan helper input rupiah
      (`core/utils/formatters/rupiah_input.dart`).
      Memenuhi FR-WAL-001, FR-WAL-002, dan FR-WAL-003.
- [x] **T-2.8** Buat layar rincian dompet: riwayat tersaring dan pintasan ke
      CATAT dengan dompet ini sudah terpilih.
      ⚠ `WalletDetailPage` (`features/wallet/presentation/pages/`) dibuka
      lewat `openWalletDetail`, dipush dari `WalletListPage` -- kartu dompet
      TIDAK lagi membuka formulir sunting langsung (T-2.7), sekarang membuka
      layar ini; tombol "Sunting" pindah ke bilah atasnya. Sunting yang
      berhasil MENUTUP layar ini (pola sama seperti `TransactionDetailPage._edit`);
      hapus baru menutupnya kalau sungguhan berhasil (bisa diblokir kalau
      dompet sudah punya transaksi, lihat T-2.7), supaya pesan blokirnya
      tetap terlihat di layar yang sama.
      ⚠ Riwayat di layar ini HANYA transaksi BULAN BERJALAN, diambil dari
      `TransactionBloc.rawTransactions` yang sudah dimuat di level shell
      (bukan bloc baru) -- `TransactionRepository.listAllTransactions()`
      reserved untuk penghitungan ulang saldo, bukan untuk merender layar
      (ADR-012, buku besar dipartisi per bulan). Maks 5 transaksi terbaru
      ditampilkan; "Lihat Semua Transaksi" mengirim
      `TransactionWalletFilterChanged` ke `TransactionBloc` yang SAMA lalu
      mem-push `TransactionListPage` (pola push+`BlocProvider.value` sama
      seperti `openTransactionDetail`) -- filternya bertahan sampai
      pengguna menghapusnya sendiri, bukan sesuatu yang salah.
      ⚠ Pintasan CATAT (FR-REC-002) menambah parameter `initialWalletId` pada
      `openRecordSheet`/`IncomeFormSheet`/`ExpenseFormSheet`/`TransferFormSheet`
      -- diabaikan kalau mode sunting (`initial` terisi). Untuk transfer,
      dompet pintasan mengisi ASAL (`_fromWalletId`), bukan tujuan, karena
      pintasan dari satu dompet paling wajar dibaca "dari dompet ini". Tetap
      memakai alur dan entitas CATAT yang sama persis (loop pilihan lalu
      formulir di `openRecordSheet`), bukan implementasi tersendiri.
      ⚠ Ronde kedua (umpan balik pemilik): ditambah ringkasan Masuk/Keluar/
      Neto bulan ini di atas daftar riwayat (`_MonthSummaryRow`) -- dihitung
      dari SELURUH transaksi bulan yang menyentuh dompet ini (bukan hanya 5
      baris yang ditampilkan), dan transfer TIDAK ikut dihitung (CLAUDE.md
      aturan 7), sama seperti `TransactionMonthHeader._totals` di tab
      Transaksi. Keadaan kosong riwayat diganti dari teks polos menjadi
      ikon + judul + deskripsi (`_EmptyRecentTransactions`), bahasa visual
      yang sama dengan `TransactionEmptyMonthState`/`WalletEmptyState`
      lainnya, diperkecil skalanya karena ini bagian dari halaman, bukan
      seluruh layar (CTA "Catat" sudah ada di atas, tidak diulang).
      ⚠ **Direvisi 25 September 2026 (masukan pemilik):** ringkasan bulan
      dompet kini Pemasukan / Pengeluaran (tetap tanpa transfer, aturan 7),
      Transfer masuk / Transfer keluar berwarna `transfer` (hanya tampil kalau
      ada), dan "Perubahan saldo" = pemasukan − pengeluaran + transfer masuk −
      transfer keluar, menggantikan "Neto". Tanpa ini dompet yang hanya diisi
      lewat transfer (mis. Tabungan) selalu tampil Rp0 walau saldonya naik.
      "Neto" di tab Transaksi tetap pemasukan − pengeluaran.
      Memenuhi FR-WAL-004 dan FR-REC-002.

### Verifikasi

- [x] **T-2.9** Tulis uji bloc untuk `record`, `transaction`, dan `wallet`
      memakai `mocktail` dan `bloc_test`.
      ⚠ Menulis ulang `record_bloc_test.dart`/`transaction_bloc_test.dart`/
      `wallet_bloc_test.dart` (T-2.4/T-2.5/T-2.7 sebelumnya memakai fake
      tulis tangan di atas `InMemoryKeyValueStorage`, menyimpang dari
      ADR-0010). `WalletRepository`/`TransactionRepository` di-mock lewat
      `test/helpers/mocks.dart` (dipakai lintas ketiga berkas, sesuai batasan
      ADR-0010 §8 "≥3 berkas"); `RecordTransaction`/`RecomputeWalletBalances`
      TIDAK di-mock -- keduanya `final class`, tidak bisa `implements` dari
      luar library-nya, dan lagipula logikanya murni Dart yang justru ingin
      diuji SUNGGUHAN di atas repository yang di-mock (pola ADR-0010 §4
      "use case diuji dengan mock yang sama").
      ⚠ Jebakan yang persis diperingatkan tugas ini: karena mock tidak
      mengingat pemanggilan sebelumnya (beda dari fake/`InMemoryKeyValueStorage`),
      `listWallets()` yang dipanggil ULANG setelah `saveWallet()`/recompute
      (pola "tulis lalu muat ulang" di `_afterWrite`) harus di-stub eksplisit
      mengembalikan nilai "seolah sudah tersimpan" -- lihat komentar di
      `transaction_bloc_test.dart` uji "menyunting nominal...". Tanpa ini,
      state akhir yang dibaca ulang tetap menunjukkan nilai lama walau
      `saveWallet` sudah diverifikasi terpanggil dengan argumen yang benar.
      ⚠ `registerFallbackValue` wajib untuk SETIAP tipe non-primitif yang
      dipakai lewat `any()`/`captureAny()` -- lupa satu tipe (mis. `Transaction`
      untuk `verifyNever(() => repo.saveTransaction(any()))`) melempar
      `Bad state` yang GAGALNYA baru terlihat di uji sesudahnya, bukan di
      uji yang sebenarnya salah (mirip gejala ADR-0010 §7's "ketahuan saat
      runtime, bukan lebih awal").
      Memenuhi NFR-ACC-002.
- [x] **T-2.10** Jalankan di perangkat atau emulator, telusuri loop inti: buat
      dompet, catat pemasukan, catat pengeluaran, catat transfer, dan pastikan
      saldo bergerak persis seperti yang dijanjikan model.
      ⚠ Ditelusuri di emulator (`emulator-5554`): dompet baru "Dompet Uji"
      (CASH, saldo awal Rp0) dibuat lewat tab Dompet, lalu tiga transaksi
      dicatat lewat pintasan CATAT di layar rincian dompet itu sendiri
      (T-2.8) — pemasukan Rp1.000.000 (Rp0 → Rp1.000.000), pengeluaran
      Rp250.000 (→ Rp750.000), transfer Rp500.000 ke Rekening BCA
      (→ Rp250.000, dan BCA naik Rp1.234.567.890 → Rp1.235.067.890 di layar
      Dompet). Ringkasan Masuk/Keluar/Neto (T-2.8, ronde kedua) terbukti
      benar sepanjang jalan: Rp1.000.000/Rp0/+Rp1.000.000 setelah pemasukan,
      lalu Rp1.000.000/Rp250.000/+Rp750.000 setelah pengeluaran, TIDAK
      berubah lagi setelah transfer (aturan 7 — transfer tidak dihitung).
      Setiap dompet pra-terisi dengan dompet sasaran CATAT-nya sendiri
      (FR-REC-002), dan snackbar "Income recorded."/"Expense recorded."/
      "Transfer recorded." tampil tiap kali.
      Memenuhi NFR-PERF-001 dan NFR-UX-001.

## Fase 3: Cutover

⚠ **Fase ini adalah gerbang.** Jangan memulai Fase 4 sebelum seluruh tugasnya
tercentang dan `flutter analyze` bersih. Sebelum fase ini repositori memuat dua
model domain sekaligus; sesudahnya hanya tersisa satu.

⚠ Jangan mencicil penghapusan di luar fase ini. Keenam port lintas fitur
bermuara ke `cycle`, jadi penghapusan sebagian meninggalkan galat berantai
tanpa menyelesaikan apa pun.

- [x] **T-3.1** Pindahkan `CalculateNetPay`, `DeductionRule`, dan
      `NetPayBreakdown` dari `lib/shared/income/domain/` ke
      `lib/features/freelance/domain/`, beserta ujinya.
      ⚠ **Signature berubah.** `CalculateNetPay` dulu menerima `IncomeSource`
      (entitas 1.0 yang ikut terhapus di T-3.2); kini menerima `totalHours`,
      `hourlyRate`, dan `deductionRules` mentah karena `FreelanceProject` baru
      lahir di T-5.1. `DeductionKind` dan `DeductionAmount` ikut pindah
      (keduanya dependensi langsung). Entitas di `domain/entities/`, use case
      di `domain/usecases/`. Uji ditambah kasus bukti DOMAIN_MODEL.md: 37 jam
      × Rp72.500 pajak 2,5% → 261.543.750 sen.
      ⚠ Dikerjakan **sebelum** penghapusan di T-3.2, supaya aritmetika per mil
      yang sudah teruji tidak ikut terhapus.
      ⚠ Setelah pivot hanya ada satu konsumen, sehingga ambang "2+ konsumen"
      ADR-0009 tidak lagi terpenuhi dan promosinya ke `shared/` kehilangan
      dasar.
- [x] **T-3.2** Hapus `lib/features/{cycle,card,investment,grocery,income}`,
      `lib/shared/goal/`, dan sisa `lib/shared/income/`.
      ⚠ **`lib/features/worklog/` (worklog 1.0) ikut dihapus** walau tidak
      tercantum di sini: ia bergantung pada `cycle` dan `shared/income` lewat
      `IncomeWorklogGateway`/`CycleIncomeWriter` sehingga tidak bisa
      dikompilasi tanpa keduanya, dan namespace i18n-nya memang dihapus
      T-3.6. Freelance 2.0 dibangun ulang di Fase 5. `example_note`
      dipertahankan — tidak bergantung pada fitur lama, masih dicapai lewat
      menu pengembang.
- [x] **T-3.3** Hapus tes fitur lama di `test/features/` dan `test/shared/`.
      ⚠ Uji `test/shared/{wallet,transaction}` milik 2.0 dan TIDAK dihapus.
- [x] **T-3.4** Bersihkan `RootModule` dari seluruh adapter lintas fitur lama,
      tukar rute `/home` ke `AppShellPage`, lalu hapus `main_shell_page.dart`
      dan rute sementara `/shell`.
      `AppRouteRegistry.build` kehilangan parameter `shellBuilder` dan
      konstanta `shellPath`; `/home` kini lokasi awal.
- [x] **T-3.5** Hapus slot warna `investment`, `rollUp`, `needsReview`,
      `onNeedsReview`, dan keenam varian `…OnLight` dari `AppColorsExtension`,
      lalu perbarui uji kontrasnya.
      Pengganti di pemakai yang tersisa: `AppMoneyText` → `income`/
      `overBudget` (di palet pixel identik dengan varian `…OnLight` yang
      dihapus, jadi tampilan tidak berubah); snackbar `info` → `textPrimary`
      (netral, padanan `inverseSurface`); `AppChip` terpilih → selalu
      `background`; tombol `ElevatedButton` gelap di `AppTheme` →
      `background`. Uji kontras: grup varian on-light ADR-0006 dihapus,
      `overBudget` ditambahkan ke uji teks-aman palet pixel.
      ⚠ Palet lama `light`/`dark` (ADR-0006) masih tema global `AppTheme`;
      di sana `income` sebagai teks hanya 3,48:1. Aman selama seluruh layar
      berada di bawah `PixelTheme` — kandidat dihapus/diganti di T-7.x.
- [x] **T-3.6** Hapus namespace i18n `cycle`, `grocery`, `card`, `investment`,
      `worklog`, dan `income`, lalu regenerasi slang.
      Namespace `shell` (label tab `MainShellPage`) ikut dihapus.
- [x] **T-3.7** Hapus `tool/seed_import.dart`.
      ⚠ Skrip itu mengimpor repository fitur lama dan tidak akan kompilasi
      setelah T-3.2. `tool/seed_data.json` **dipertahankan** sebagai rekaman
      data historis nyata pemilik.
      Dev dependency `hive_ce` (hanya dipakai skrip ini) ikut dihapus dari
      `pubspec.yaml`.
- [x] **T-3.8** Perbarui `description` di `pubspec.yaml` yang masih berbunyi
      "pengganti sistem spreadsheet manual".
- [x] **T-3.9** Catat baseline uji yang baru apa adanya di catatan pengerjaan.
      ⚠ Jumlah uji akan **turun tajam** karena sekitar 2.900 baris uji hilang
      bersama fiturnya. Jangan mengejar angka lama dengan menulis uji yang
      tidak bermakna.
      **Baseline 25 September 2026:** `flutter analyze` bersih (dua info
      `cascade_invocations` di `RootModule` dan `ExampleNoteScope`
      diperbaiki); **333 uji lulus** di 33 berkas uji; 11.369 baris Dart di
      `lib/` (115 berkas, tanpa `.g.dart`). Angka uji lebih tinggi dari 169
      pra-pivot karena uji Fase 1–2 sudah lebih banyak daripada uji 1.0 yang
      hilang. Cutover menghapus ±17.800 baris (termasuk ±1.280 baris keluaran
      slang).

## Fase 4: Anggaran

- [x] **T-4.1** Buat `features/budget/domain/`: `Budget`, `BudgetItem`,
      `BudgetPeriod`, dan `BudgetItemStatus`.
      ⚠ `Budget.walletId` wajib terisi, dan ikatan itu menyaring transaksi mana
      yang terhitung.
      ⚠ `Budget.isArchived` adalah satu-satunya bagian siklus hidup yang
      disimpan. Status `aktif` dan `selesai` turunan dari periodenya.
      ⚠ **Keputusan pengisi celah:** akhir periode EKSKLUSIF
      (`BudgetPeriod.endFrom`); bulanan dijepit ke hari terakhir bulan
      berikutnya (mulai 31 Jan → akhir 28/29 Feb, bukan 3 Mar). Status siklus
      hidup memakai `BudgetStatus` (aktif/selesai/nonaktif). `BudgetItem`
      menyimpan `enteredAmount` ATAU `quantity`+`unitPrice`; `plannedAmount`
      getter turunan.
      ⚠ **Direvisi ADR-017 (25 September 2026):** `Budget.plannedAmount`
      juga turunan, `Σ item.plannedAmount`, tidak lagi diketik terpisah.
      `BudgetModel` skema 2 berhenti menulisnya dan mengabaikannya saat
      membaca skema 1.
      Memenuhi FR-BUD-001 dan FR-BUD-002.
- [x] **T-4.2** Buat use case `CalculateBudgetProgress` — Dart murni,
      menghasilkan `spent`, `remaining`, `progress`, status tiap pos, dan status
      anggaran.
      ⚠ `spent` menjumlahkan **dua** jenis transaksi: pengeluaran yang
      `walletId`-nya cocok, dan transfer yang `fromWalletId`-nya cocok.
      Melewatkan salah satunya membuat angka anggaran salah tanpa gejala.
      ⚠ Tidak satu pun nilai itu disimpan. Semuanya dihitung ulang saat
      diakses.
      Rencana nol tidak bisa dibagi: `progress` 0 kalau belum terpakai, 1
      kalau sudah (statusnya tetap `overspent`). `BudgetProgress` juga
      membawa `spendingStatus` tingkat anggaran (empat kondisi yang sama).
      Memenuhi FR-BUD-004.
- [x] **T-4.3** Buat `features/budget/data/`: `BudgetModel` dan repositorinya
      di atas kunci `budget/all`.
      `BudgetRepository` didaftarkan di `RootModule`, bukan di
      `BudgetScope`, karena juga dibaca CATAT dan rincian transaksi lewat
      port `BudgetItemCatalog` (ADR-0009).
      Memenuhi FR-BUD-001 dan NFR-REL-003.
- [x] **T-4.4** Tambahkan pemilih pos anggaran di formulir pengeluaran **dan**
      formulir transfer CATAT.
      ⚠ Di formulir pengeluaran, pemilih menyaring terhadap `walletId`; di
      formulir transfer, terhadap `fromWalletId`.
      ⚠ Satu transaksi hanya boleh menaikkan satu pos. Jangan menawarkan tautan
      ke anggaran dompet tujuan juga — itu hitung ganda.
      ⚠ **Direvisi ADR-018:** pos berjenis. Pengeluaran hanya ditawari pos
      pengeluaran dompet asal; transfer hanya pos transfer yang asal DAN
      tujuannya cocok (pemilih tampil sesudah kedua dompet dipilih).
      Port `BudgetItemCatalog` milik `record`, implementasi
      `BudgetItemCatalogImpl` di `budget/data/adapters/`. Hanya pos anggaran
      AKTIF dompet asal yang ditawarkan, ditambah pos yang sedang dipakai
      transaksi yang disunting. Pilihan batal otomatis kalau dompet asal
      diganti. Pemilih tidak tampil kalau dompet belum punya pos. Sunting
      transaksi kini ikut bisa mengubah tautan pos (sebelumnya dipertahankan
      apa adanya).
      Memenuhi FR-BUD-003, FR-TXN-002, dan FR-TXN-003.
- [x] **T-4.5** Buat layar Anggaran: ringkasan lintas anggaran di puncak (total
      rencana, terpakai, sisa), lalu daftar kartu anggaran.
      ⚠ **Layar ini daftar seluruh anggaran, bukan papan satu anggaran.**
      Beberapa anggaran boleh aktif sekaligus, berbagi dompet, dan berbeda
      periode. Jangan membuat objek anggaran bulanan global.
      ⚠ Tiap kartu wajib memuat delapan hal: nama, dompet, periode, nominal
      rencana, terpakai, sisa, progres, dan status. Nama dompet harus terbaca
      tanpa membuka anggarannya.
      ⚠ **Progres dihitung dari `listAllTransactions`**, bukan transaksi
      sebulan: rumus `spent` tidak punya saringan tanggal, jadi transaksi
      tertaut di luar bulan periode tetap harus terhitung. NFR-PERF-002 hanya
      mengikat Beranda dan Dompet; tinjau ulang kalau buku besar membesar.
      Ringkasan puncak hanya menjumlahkan anggaran AKTIF.
      `AppSegmentedProgressBar.colorFor` dibetulkan: tepat 100% (pos
      selesai) `pending`, `overBudget` baru di atas 100% sesuai ADR-015.
      Memenuhi FR-BUD-001 dan FR-BUD-004.
- [x] **T-4.6** Buat layar sunting anggaran beserta posnya, termasuk jumlah dan
      harga satuan opsional.
      ⚠ Jumlah dikali harga satuan ada supaya daftar belanja pemilik yang
      sungguhan berisi 35 item tetap bisa dicatat serinci sebelumnya.
      ⚠ **Direvisi ADR-017:** kolom nominal rencana dan baris "Selisih
      dengan rencana" dihapus, diganti kartu "Total rencana anggaran" yang
      menjumlahkan pos. Minimal satu pos wajib sebelum bisa disimpan.
      ⚠ **Direvisi ADR-018:** formulir pos punya pilihan jenis (pengeluaran/
      transfer, dikunci kalau pos sudah punya transaksi tertaut); pos transfer
      memilih dompet tujuan dan tidak bisa dirinci jumlah × harga. Bagian
      rujukan yang sengaja tidak dibangun: periode "Kustom" dan "buat dari
      template" (Fase 7).
      Memenuhi FR-BUD-002.
- [x] **T-4.7** Tulis uji: membuat anggaran tidak mengubah saldo dompet mana
      pun; pengeluaran dari dompet lain tidak menambah `spent`; status pos
      benar di keempat kondisinya.
      ⚠ Wajib juga: transfer yang tertaut pos menambah `spent` pos itu; transfer
      yang `fromWalletId`-nya bukan dompet anggaran **tidak** menambah; dan
      transfer yang tertaut anggaran tetap tidak mengubah total saldo.
      Bukti: `calculate_budget_progress_test` (angka nyata Rp3.068.500,
      empat status, transfer asal/tujuan, total saldo tetap),
      `budget_bloc_test` (tambah/arsip/hapus `verifyNever` pada tulis dompet
      dan transaksi), `budget_repository_impl_test` (saldo dompet utuh
      sesudah anggaran dibuat dan diarsipkan).
      Memenuhi NFR-ACC-002.
- [x] **T-4.8** Tambahkan namespace i18n `budget` dan daftarkan `BudgetScope`.
      `BudgetScope` dipasang di `AppShellPage` bersebelahan dengan scope
      lain; uji shell butuh satu `pump()` tambahan per scope bersarang.
      Memenuhi NFR-UX-004.
- [x] **T-4.9** Tambahkan pengarsipan anggaran dan penyaring daftar: status
      (semua, aktif, selesai, nonaktif) dan dompet.
      ⚠ Mengarsipkan tidak menghapus transaksi yang sudah tertaut, dan tidak
      mengubah saldo dompet mana pun.
      ⚠ Jaga penyaringnya tetap sederhana — daftar dan pilihan, bukan antarmuka
      akuntansi.
      Keadaan "tidak ada yang cocok" dibedakan dari "belum ada anggaran",
      dengan tombol atur ulang penyaring. Tanpa dompet aktif, layar
      menjelaskan perlunya dompet dan tidak menawarkan tombol buat.
      Memenuhi FR-BUD-001 dan FR-BUD-006.
- [x] **T-4.10** Buat layar rincian satu anggaran: nama, dompet, periode, angka
      anggaran, seluruh pos beserta progres dan statusnya, transaksi yang sudah
      tertaut, serta pintasan **Catat Pengeluaran** dan **Catat Transfer**.
      ⚠ Kedua pintasan membuka CATAT dengan dompet dan pos sudah terpilih —
      bukan formulir pencatatan tersendiri. Itu aturan produk, bukan preferensi.
      ⚠ Status pos ada empat: belum terpakai, terpakai sebagian, selesai, lewat
      anggaran. Yang lewat anggaran memakai warna `overBudget`, bukan gaya
      kesalahan.
      ⚠ **Direvisi ADR-018 (25 September 2026):** pintasan tingkat anggaran
      dihapus (transaksi tanpa pos tidak terhitung). Tiap pos punya SATU
      tombol sesuai jenisnya; pos transfer juga mengisi dompet tujuan
      (`openRecordSheet(initialChoice:, initialBudgetItemId:,
      initialToWalletId:)`, lembar pilihan dilewati tetapi tombol kembali
      tetap kembali ke sana).
      Pintasan di kartu pos juga mengisi nominal dengan SISA pos (rencana −
      terpakai; kosong kalau sisa ≤ 0), permintaan pemilik 25 September 2026
      — sisa, bukan rencana penuh, supaya pos yang terpakai sebagian tidak
      langsung lewat anggaran. Pintasan disembunyikan untuk anggaran nonaktif. Progres disegarkan
      sesudah CATAT dan sesudah transaksi tertaut disunting/dihapus.
      ⚠ **Diverifikasi di emulator (25 September 2026):** dompet BCA
      Rp5.000.000 → anggaran "Rumah tangga" Rp3.068.500 (saldo tetap
      Rp5.000.000) → pos Beras 2 × Rp75.000 → pintasan pos membuka formulir
      pengeluaran dengan BCA dan "Beras · Rumah tangga" terpilih → catat
      Rp75.000: saldo Rp4.925.000, terpakai Rp75.000, sisa Rp2.993.500, pos
      50% "terpakai sebagian", transaksi muncul di daftar tertaut, seketika
      tanpa menutup layar.
      Memenuhi FR-BUD-007 dan FR-REC-002.
- [x] **T-4.11** Lengkapi baris anggaran tertaut di layar rincian transaksi
      (T-2.11), beserta jalan ke anggarannya.
      Blok anggaran diteruskan ke rute rincian transaksi secara opsional
      (`context.read<X?>()`): tanpa `BudgetBloc` barisnya tetap tampil,
      hanya tanpa tautan. Diverifikasi di emulator bersama T-4.10.
      Memenuhi FR-TXN-006.

## Fase 5: Freelance

- [x] **T-5.1** Buat `features/freelance/domain/`: `FreelanceProject`,
      `WorklogEntry`, `FreelancePayment`, dan `PaymentStatus`, di samping
      `CalculateNetPay` yang sudah dipindahkan di T-3.1.
      Revisi [ADR-019](../02-architecture/adr/0019-tarif-di-entri-dan-transaksi-milik-pembayaran.md):
      entri menyimpan `hourlyRate`, pembayaran menyimpan salinan
      `deductionRules` dan `receivedDate`, sehingga mengubah proyek tidak
      mengubah kerja atau pembayaran lama. `CalculateNetPay` kini menerima
      `grossPay` langsung.
      Memenuhi FR-FRL-001 dan FR-FRL-002.
- [x] **T-5.2** Buat `features/freelance/data/`: repositori di atas kunci
      `freelance/projects`, `freelance/worklog`, dan `freelance/payments`.
      ⚠ Ketiganya sengaja tidak dipartisi karena lajunya rendah. Tinjau ulang
      kalau entrinya melewati beberapa ratus.
      Satu `FreelanceRepository` untuk ketiga kunci, didaftarkan di
      `RootModule`.
      Memenuhi NFR-REL-003.
- [x] **T-5.3** Buat layar worklog: catat, sunting, dan hapus entri berisi
      proyek, tanggal, jam, dan catatan opsional, dengan
      nominal yang diperoleh dihitung dari jam dikali tarif.
      ⚠ **Tidak pernah menyentuh saldo dompet.** Mencatat kerja bukan menerima
      uang.
      Tarif terisi dari proyek dan boleh diubah per entri. Entri yang sudah
      masuk pembayaran terkunci. Proyek dikelola di tab yang sama, dan hanya
      bisa dihapus selama belum punya entri (ADR-019).
      Memenuhi FR-FRL-002.
- [x] **T-5.4** Buat pengelompokan worklog jadi pembayaran, menampilkan gaji
      kotor, potongan, dan gaji bersih terpisah.
      ⚠ Potongan persentase selalu dihitung dari gaji kotor, tidak pernah dari
      nilai berjalan setelah potongan sebelumnya. Potongan tidak beranak.
      ⚠ Periode pembayaran tidak mengikuti batas bulan kalender.
      Entri dipilih satu per satu dari entri belum ditagih satu proyek.
      Pembayaran tertunda boleh diubah tanggalnya atau dihapus (entrinya
      kembali belum ditagih). Entri ditandai lebih dulu, pembayaran menyusul;
      `paymentId` yang menunjuk pembayaran yang tidak ada dibaca sebagai belum
      ditagih.
      Memenuhi FR-FRL-003.
- [x] **T-5.5** Terapkan pencatatan pembayaran diterima, yang membuat tepat
      satu `IncomeTransaction` sebesar gaji bersih.
      ⚠ `incomeTransactionId` yang sudah terisi adalah penjaga supaya
      pembayaran yang sama tidak bisa dicatat dua kali. Status dan id transaksi
      berubah dalam satu operasi, tidak pernah terpisah.
      `ReceiveFreelancePayment`: transaksi lebih dulu dengan id
      `freelance-<paymentId>` (pengulangan menimpa, tidak menggandakan), baru
      pembayaran. Transaksinya membawa `freelancePaymentId` dan tidak bisa
      disunting/dihapus dari tab Transaksi; gantinya aksi **Batalkan
      penerimaan** (ADR-019).
      Memenuhi FR-FRL-004 dan NFR-UX-005.
- [x] **T-5.6** Buat layar **Ikhtisar Freelance** dengan dua tab — Worklog
      sebagai tab bawaan, dan Pembayaran — beserta kedua titik masuknya.
      ⚠ Kedua titik masuk mendarat di layar yang **sama**: ringkasan di Beranda,
      dan CATAT → Catat Pemasukan → Freelance.
      ⚠ Freelance bukan tujuan navigasi bawah.
      ⚠ Tab ketiga (Template) baru ditambahkan di T-7.7. Buat `TabBar`-nya
      menerima jumlah tab yang bervariasi sekarang, supaya penambahannya nanti
      tidak membongkar layar ini.
      `openFreelanceOverview` mendorong layar penuh dengan `FreelanceScope`
      sendiri. Titik masuk CATAT: kartu Freelance di formulir pemasukan
      (rujukan `pixel_kas_catat_pemasukan` "PATH B") yang mengembalikan
      `OpenFreelance`. Titik masuk Beranda menyusul di T-6.3.
      Diverifikasi di emulator (build rilis, `emulator-5554`): CATAT →
      Pemasukan → Freelance, tambah proyek dengan pajak 2,5%, worklog 37 jam,
      buat pembayaran (gaji bersih Rp2.615.438), catat diterima ke BCA (saldo
      naik tepat Rp2.615.438), rincian transaksinya terkunci, batalkan
      penerimaan (saldo kembali), lalu hapus pembayaran, entri, dan proyek
      uji. Temuan yang diperbaiki: bilah porsi ringkasan tidak tampil (tinggi
      nol), tinggi ubin ringkasan tidak sejajar, label jamak bahasa Inggris,
      dan tombol konfirmasi "Cancel"/"Cancel receipt" yang membingungkan.
      Penyesuaian UI atas permintaan pemilik: tab Worklog berisi kartu
      proyek (ikon, tarif, potongan, belum ditagih, bilah porsi, entri
      terakhir) yang membuka **rincian proyek** — entri proyek itu saja,
      penyaring status (bawaan belum ditagih), dikelompokkan per bulan
      dengan subtotal, dimuat bertahap. Tombol utama menempel di dasar layar
      (Buat Pembayaran; + Worklog/Tagih di rincian proyek). Worklog hanya
      ditambahkan dari rincian proyek; kartu Tambah Proyek di atas daftar proyek.
      Tab Pembayaran mengikuti pola yang sama: total tertunda/diterima lalu
      kartu proyek versi pembayaran (tertunda beserta perkiraan terdekat,
      diterima), urut perkiraan terdekat. Pembayaran tampil di tab
      Pembayaran rincian proyek dengan penyaring (bawaan Tertunda) dan
      kelompok bulan; menagih hanya lewat Tagih di rincian proyek. Ikon pixel
      `hourly_rate`, `invoice`, `work_completed` dikonversi dari rujukan
      (sebagian T-7.4) dan dipakai bersama ilustrasi keadaan kosong.
      Memenuhi FR-FRL-005.
- [x] **T-5.7** Tulis uji: worklog tidak mengubah saldo; pembayaran yang dicatat
      diterima menambah saldo tepat satu kali; `netPay` 37 jam pada tarif
      72.500 dengan pajak 2,5% menghasilkan 2.615.438.
      Diuji ujung ke ujung di atas penyimpanan memori (bloc, use case, layar
      lewat shell), termasuk pengulangan sesudah kegagalan penulisan.
      Memenuhi NFR-ACC-001 dan NFR-ACC-002.
- [x] **T-5.8** Tambahkan namespace i18n `freelance` dan daftarkan
      `FreelanceScope`.
      Memenuhi NFR-UX-004.
- [x] **T-5.9** Rombak Ikhtisar Freelance jadi **satu layar utama tanpa
      tab** (keputusan pemilik, 25 Sep 2026, sesudah mencoba versi dua tab
      di emulator). PRD FR-FRL-005 dan glosarium sudah direvisi.
      ⚠ **Selesai** (27 Sep 2026, branch `claude/freelance-t-5-9`): Ikhtisar
      satu `ListView`; ringkasan memakai ubin kotor (keterangan kini
      menyebut "Gaji kotor") ditambah baris "Tertunda (bersih)" dan
      "Diterima (bersih)" dari `FreelanceState.paymentTotals`, yang hanya
      tampil kalau ada isinya; `ProjectCard` gabungan menggantikan
      `ProjectPaymentCard`, barisnya memakai `FreelanceAmountLine`;
      `showPayments`, `_PaymentsTab`, `_TotalTile`, dan empat kunci i18n
      yatim dihapus. 454 uji lulus (termasuk uji state baru, diuji mutasi).
      Diverifikasi di emulator dengan build rilis: proyek → 3 entri → tagih
      2 → Catat Diterima menambah saldo BCA tepat Rp848.250 satu kali.
      Catatan serah terima aslinya di bawah dibiarkan sebagai jejak.

      **Keadaan kode sekarang** (branch `claude/freelance-fase-5`, commit
      `da8e927`, 428 uji lulus):
      - `pages/freelance_overview_page.dart`: `DefaultTabController` dua tab
        (`_WorklogTab`: kartu aturan, `FreelanceSummaryCard`, label Proyek,
        `AddProjectCard`, `ProjectCard` per proyek; `_PaymentsTab`: kartu
        aturan, dua `_TotalTile`, `ProjectPaymentCard` per proyek urut
        `projectsByNextPayment`).
      - `pages/freelance_project_page.dart`: rincian proyek, **sudah**
        bertab Worklog dan Pembayaran dengan penyaring, kelompok bulan, dan
        bilah dasar + Worklog / Tagih (n). `openFreelanceProject(context,
        project, showPayments:)`.
      - `widgets/project_widgets.dart`: `ProjectCard` (sisi worklog) dan
        `ProjectPaymentCard` (sisi pembayaran), plus `FreelanceIconBox`,
        `FreelanceShareBar`, `AddProjectCard`, `FreelanceEmptyState`,
        `FreelanceBottomBar`, `WorklogMonthHeader`.
      - `bloc/freelance_state.dart`: `summary`, `statsOf` (`ProjectStats`,
        kotor), `paymentStatsOf` (`ProjectPaymentStats`, bersih),
        `projectsByNextPayment`, `pendingNetTotal`, `paidNetTotal`.

      **Yang harus dibangun:**
      1. Ikhtisar Freelance = satu `ListView` tanpa `TabBar`/`DefaultTabController`,
         urutan: kartu aturan (`ruleBody`), ringkasan upah & jam, label
         Proyek, `AddProjectCard` (tetap di atas daftar), lalu kartu proyek
         gabungan. Tanpa bilah tombol di dasar layar.
      2. **Ringkasan** menggabungkan `FreelanceSummaryCard` (jam, diperoleh,
         diterima, belum diterima — kotor) dengan total tertunda dan diterima
         versi bersih dari `_PaymentsTab`. ⚠ Jangan menampilkan dua angka
         "diterima" (kotor dan bersih) berdampingan tanpa label yang
         membedakan; usulan: ubin kotor tetap, lalu satu baris "Tertunda
         (bersih) · perkiraan terdekat" dan "Diterima (bersih)".
      3. **Kartu proyek gabungan** menggantikan `ProjectCard` dan
         `ProjectPaymentCard`: ikon, nama, tarif dan potongan; baris belum
         ditagih (jam + nominal kotor); baris tertunda (bersih, jumlah
         tagihan, perkiraan terdekat); baris diterima (bersih); bilah porsi
         diterima/tertunda/belum ditagih; tanggal entri terakhir. Satu
         ketukan membuka rincian proyek di tab Worklog. Urutan kartu: yang
         punya tagihan tertunda di atas menurut perkiraan terdekat, sisanya
         menyusul (`projectsByNextPayment`).
      4. Rincian proyek **tidak berubah** (sudah bertab). Parameter
         `showPayments` boleh dihapus kalau tidak ada pemanggil lagi.
      5. Bersihkan kunci i18n yang tak terpakai (`worklogTab`/`paymentsTab`
         tetap dipakai rincian proyek); perbarui uji
         `test/features/freelance/presentation/pages/freelance_pages_test.dart`
         (alur Catat Diterima sekarang: Ikhtisar → kartu proyek → tab
         Pembayaran di rincian). Verifikasi di emulator dengan build rilis
         (`flutter run --release`; build debug memicu ANR di emulator ini).

      Template freelance (T-7.7) deprecated 26 Sep 2026, jadi Ikhtisar
      tidak perlu menyediakan tempat untuknya.
      Memenuhi FR-FRL-005.

## Fase 6: Beranda

Beranda dikerjakan terakhir di antara layar karena ia hanya bermakna setelah
seluruh fitur di atasnya menghasilkan data.

- [x] **T-6.1** Tampilkan total saldo, pemasukan bulan berjalan, dan pengeluaran
      bulan berjalan.
      ⚠ Transfer tidak dihitung sebagai pemasukan maupun pengeluaran. Kalau ia
      ikut dihitung, satu pemindahan Rp1.000.000 akan tampil sebagai pemasukan
      sekaligus pengeluaran — dua angka yang sama-sama salah.
      ⚠ Selesai (27 Sep 2026, branch `claude/beranda-fase-6`): UI di
      `features/home/` (`HomeScope`, `HomeBloc`, `HomePage`, `home_cards.dart`),
      rujukan `pixel_kas_beranda`. Arus dibaca dari SATU dokumen bulan
      (`listTransactionsInMonth`), bukan seluruh riwayat.
      Catatan domain sebelumnya: `CalculateCashFlow` di
      `shared/transaction` (diekspor barrel) menjumlahkan pemasukan dan
      pengeluaran bulan kalender, transfer dilewati; diuji mutasi (transfer
      ikut dihitung → merah). Total saldo tetap `Σ currentBalance` dompet
      aktif, seperti `WalletState.totalBalance`.
      Memenuhi FR-HOME-001.
- [x] **T-6.2** Tampilkan ringkasan anggaran — total rencana, terpakai, dan
      sisa — beserta jalan ke layar Anggaran.
      ⚠ Sebagian: domain selesai, UI belum. Port `BudgetOverviewSource` milik
      `home` (ADR-0009), diimplementasikan `BudgetOverviewSourceImpl` di
      `budget/data/adapters/` memakai `CalculateBudgetProgress` yang sama
      dengan layar Anggaran, dikawat di `RootModule`. Hanya anggaran aktif;
      sisa boleh negatif. Diuji mutasi (anggaran nonaktif ikut → merah).
      Memenuhi FR-HOME-002.
- [x] **T-6.3** Tampilkan ringkasan freelance: total jam, diperoleh, sudah
      dibayar, belum dibayar, dan tanggal pembayaran terdekat yang belum
      diterima. Sembunyikan sepenuhnya kalau tidak ada pembayaran tertunda.
      ⚠ **Jangan menampilkan entri worklog satu per satu di Beranda.** Beranda
      memuat ringkasan; daftar kerjanya ada di Ikhtisar Freelance.
      ⚠ Sebagian: domain selesai, UI belum. Port `FreelanceOverviewSource`
      milik `home` mengembalikan `null` kalau tidak ada pembayaran tertunda,
      selain itu jam, diperoleh, dibayar, belum dibayar (semuanya **kotor**,
      sama dengan puncak Ikhtisar), jumlah tertunda, dan perkiraan terdekat.
      Rumus ringkasan dipindah ke `SummarizeWorklog` (domain `freelance`) dan
      dipakai bersama `FreelanceState.summary`, supaya Beranda dan Ikhtisar
      tidak pernah berbeda. Diuji mutasi (tertunda dianggap dibayar → merah;
      perkiraan terjauh → merah).
      ⚠ Label UI harus menyebut "kotor" — lihat peringatan T-5.9 tentang dua
      angka "diterima".
      Memenuhi FR-HOME-003.
- [x] **T-6.4** Tampilkan transaksi terbaru beserta jalan ke layar Transaksi.
      ⚠ Selesai: lima transaksi terbaru lewat `listRecentTransactions(limit)`
      baru di `TransactionRepository`, yang membaca dokumen bulan dari yang
      terbaru dan berhenti begitu limit terpenuhi (diuji dengan dokumen
      bulan lama yang dirusak, diuji mutasi). "Lihat semua" pindah ke tab
      Transaksi; baris membuka rincian transaksi.
      Memenuhi FR-HOME-004.
- [x] **T-6.5** Jalankan di perangkat, ukur waktu tampil Beranda, dan telusuri
      loop inti penuh sampai pencatatan pembayaran freelance.
      ⚠ Selesai (emulator API 35, build rilis): buka dingin sampai frame
      pertama 515–628 ms (tiga kali `am start -W`), di bawah 1 detik.
      Loop: dompet → proyek → worklog → tagih → Catat Diterima → anggaran →
      Beranda memperbarui saldo, arus, kartu anggaran, dan kartu freelance.
      ⚠ **Terbuka untuk pemilik:** ringkasan anggaran masih memindai seluruh
      riwayat — lihat **KT-1** di bagian "Keputusan terbuka".
      Memenuhi NFR-PERF-001 dan NFR-PERF-002.
- [x] **T-6.6** Buat keadaan kosong Beranda: "Belum ada transaksi" beserta
      ajakan **Catat Transaksi**, dan arahan membuat dompet pertama kalau belum
      ada dompet sama sekali.
      ⚠ Ajakannya membuka alur CATAT yang sama, bukan formulir tersendiri.
      ⚠ Kartu ringkasan yang belum punya isi disembunyikan, bukan ditampilkan
      sebagai deretan angka nol. Layar pertama menentukan apakah aplikasi ini
      dipakai lagi besok.
      ⚠ Selesai: tanpa dompet, tombol utamanya "Buat Dompet Pertama" (ke tab
      Dompet); dengan dompet, "Catat Transaksi" membuka alur CATAT yang
      sama. Pemasukan/pengeluaran, anggaran, dan freelance disembunyikan
      kalau belum punya isi — **menyimpang dari rujukan**
      `pixel_kas_beranda_belum_ada_data` yang menampilkan Rp0, karena PRD
      menang. Panduan singkat tiga aturan mengikuti rujukan.
      Memenuhi FR-HOME-005.

## Fase 7: Template dan poles

- [x] **T-7.1** Buat `BudgetTemplate` beserta repositorinya di atas kunci
      `budget_template/all`.
      `BudgetTemplate` (nama, pos, `isEnabled`; rencana = jumlah pos seperti
      ADR-017) memakai `BudgetItem` dan `BudgetItemModel` yang sama dengan
      anggaran, tanpa dompet maupun periode. `BudgetTemplateRepository`
      didaftarkan di `RootModule` di samping `BudgetRepository`. Diuji di atas
      penyimpanan memori, termasuk bahwa template dan anggaran tidak saling
      menimpa (diuji mutasi: kunci sengaja disamakan → uji merah).
      Memenuhi FR-BUD-005.
- [x] **T-7.2** Buat layar template: buat, sunting, gandakan, aktifkan,
      nonaktifkan, dan hapus.
      ⚠ Membuat atau menyunting template tidak mengubah saldo dompet mana pun.
      ⚠ Selesai (27 Sep 2026, branch `claude/template-poles-fase-7`):
      `BudgetTemplatePage` dibuka dari layar Anggaran (tombol "Template
      Anggaran"), dengan `BudgetTemplateScope`/`BudgetTemplateBloc` sendiri
      yang hidup selama layar terbuka. Kartu per template mengikuti rujukan
      `pixel_kas_template_anggaran`; aktif/nonaktif dan hapus ada di
      `BudgetTemplateFormSheet`. Gandakan memberi id pos baru. Diuji bloc
      (saldo dompet tetap) dan layar.
      Memenuhi FR-BUD-005.
- [x] **T-7.3** Terapkan pembuatan anggaran dari template.
      ⚠ Anggaran hasil template berdiri sendiri. Menyuntingnya tidak mengubah
      templatenya, dan sebaliknya.
      ⚠ Sebagian: domain selesai, UI belum. `CreateBudgetFromTemplate`
      (Dart murni) menyalin nama dan pos ke `Budget` baru untuk dompet,
      periode, dan tanggal yang dipilih, dengan **id pos baru** dari
      `newItemId` (id pos template yang dipakai ulang membuat satu transaksi
      terhitung di dua anggaran). Pos transfer yang dompet tujuannya sama
      dengan dompet anggaran menghasilkan `BudgetFromTemplateNeedsTarget`:
      **pemilik diminta menyesuaikan dompet tujuannya** (keputusan pemilik,
      26 Sep 2026), lalu use case dipanggil ulang dengan `targetWalletIds`.
      Diuji mutasi (id dipakai ulang → merah; deteksi bentrok dimatikan →
      merah). Sisa: UI pemilihan template di formulir anggaran dan pemilih
      dompet tujuan pengganti.
      ⚠ `newItemId` harus unik di dalam satu putaran — id
      `microsecondsSinceEpoch` polos bisa kembar kalau dipanggil beruntun.
      ⚠ Selesai: "Gunakan template ini" membuka formulir anggaran yang SAMA,
      terisi lewat `CreateBudgetFromTemplate.draftItems` (id pos baru,
      `stamp-urutan`). Dompet dan periode dipilih di formulir; pos transfer
      yang tujuannya bentrok ditandai dan menahan simpan sampai tujuannya
      diganti — mekanisme formulir yang sudah ada. Diuji mutasi (id pos
      dipakai ulang → uji domain, bloc, dan layar merah).
      Memenuhi FR-BUD-005.
- [ ] ~~**T-7.7**~~ **Deprecated 26 Sep 2026 atas keputusan pemilik; tidak
      dikerjakan dan tidak dihitung di ringkasan.** Catatan semula:
      Buat `FreelanceTemplate` beserta repositori, layar CRUD-nya
      sebagai tab ketiga Ikhtisar Freelance, dan pembuatan proyek dari template.
      ⚠ Hubungannya sama persis dengan `BudgetTemplate` terhadap `Budget`:
      template adalah definisi, proyek adalah salinan mandiri. Menyunting
      template tidak mengubah proyek yang sudah dibuat darinya.
      ⚠ Template tidak pernah menyentuh saldo dompet mana pun.
      Memenuhi FR-FRL-006.
- [x] **T-7.4** Konversi 67 SVG dari `docs/stitch_pixel_finance_tracker/icon_*/
      code.html` jadi aset Flutter di `assets/icons/`, lalu masukkan ke peta
      `AppIcon` menggantikan isian Material — padanannya sudah ditetapkan di
      [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md).
      ⚠ Asetnya sudah tersedia di repositori sejak sebelum Fase 1 — bukan lagi
      menunggu kiriman pemilik. Kunci yang belum punya padanan (`add`, `edit`,
      `delete`, `chevronLeft`, `chevronRight`) tetap Material sampai ada.
      ⚠ Selesai (27 Sep 2026): 44 kunci memakai SVG di `assets/icons/`
      (diselaraskan ADR-016 lewat `tool/recolor_icons.py`). Terakhir
      ditambahkan `locked` (`icon_status_locked`) dan `empty` (peti simpanan,
      sama dengan ilustrasi "Inventaris kosong" rujukan). Yang tetap Material
      karena tidak punya padanan: `add`, `edit`, `delete`, `chevronLeft`,
      `chevronRight`, `dropdown`, `close`. Ikon rujukan lain (mis.
      `transaction_recurring_*`, `status_warning`) belum punya kunci pemakai,
      jadi tidak dikonversi.
      Memenuhi NFR-UX-002.
- [x] **T-7.5** Terapkan sistem elevasi bayangan keras (`AppHardCard`) dan
      bilah progres tersegmentasi (`AppSegmentedProgressBar`) dari ADR-015 ke
      seluruh kartu dan bilah progres yang sudah dibangun Fase 2–6, kalau
      belum dikerjakan langsung di fase masing-masing.
      ⚠ Widget `AppHardCard`/`AppSegmentedProgressBar` dan `PixelTheme`
      pembungkusnya sudah dibuat di **T-2.12** (dimajukan atas permintaan
      pemilik). Sisa tugas ini di sini: pastikan SETIAP layar Fase 2–6
      benar-benar memakainya (bukan `Container`/`ProgressIndicator`
      polos), dan retrofit bentuk `AppButton`/`AppChip`/`AppCard` supaya
      radius/garis tepinya juga ikut ADR-015 (T-2.12 baru menyamakan
      warna dan tipografi, belum bentuk ketiga widget itu).
      ⚠ Selesai (27 Sep 2026): audit tidak menemukan bilah progres polos
      (`BudgetProgressBar` sudah `AppSegmentedProgressBar`). Bentuk
      diretrofit: `AppButton` radius pixel 4 + tepi 2px dan varian baru
      `AppButton.secondary` (9 tombol abu gelap jadi sekunder), `AppChip`
      sudut tegas 0px + tepi 2px, `AppCard` radius pixel 4 + tepi 2px.
      Kartu utama tiap tab memakai `AppHeroCard` (Fase 6). Enam `BoxShadow`
      manual `Offset(0, 2)` (tab terpilih, kotak ikon) sengaja dibiarkan:
      itu bayangan BAWAH ala `TransactionSlab` dari rujukan, sedangkan
      `AppElevation.hardShadow` kanan-bawah — menggantinya mengubah tampilan.
- [x] **T-7.6** Poles: skeleton pemuatan pertama, keadaan kosong tiap layar, dan
      konfirmasi tiap tindakan merusak.
      ⚠ Pakai ulang `AppSkeleton` dan `showConfirmDelete` yang sudah ada.
      ⚠ Selesai (27 Sep 2026), hasil audit:
      - Skeleton: semua layar yang memuat sendiri sudah punya skeleton dan
        layar "coba lagi". Satu celah diperbaiki: riwayat di rincian dompet
        menampilkan ruang kosong saat memuat (terbaca "belum ada transaksi"),
        kini kerangka tiga baris.
      - Keadaan kosong: ada di setiap layar (Beranda, Anggaran + hasil
        penyaring, Transaksi + penyaring, Dompet, rincian dompet, Freelance,
        rincian proyek, Template). Ilustrasi Beranda kini peti kosong.
      - Konfirmasi: hapus anggaran, template, dompet, transaksi, proyek,
        entri worklog, pembayaran, dan batalkan penerimaan semuanya lewat
        `showConfirmDelete`. Arsip dan nonaktif dapat dibalik, jadi tanpa
        konfirmasi.
      - Mode gelap dicek di perangkat: `AppHeroCard` memakai `surfaceHigh`
        di mode gelap karena `surfaceMid` di sana sama dengan warna kartu.
      Memenuhi NFR-UX-001.

## Fase 8: Tindak lanjut pasca-MVP

- [x] **T-8.1** Batasi hitungan anggaran ke bulan periodenya (keputusan
      KT-1, NFR-PERF-002).
      Keputusan pemilik 27 Sep 2026: transaksi hanya boleh ditautkan ke pos
      anggaran yang periodenya mencakup tanggal transaksi — belanja sebelum
      periode dimulai tidak pernah terjadi. Pilihan "indeks tautan pos" tidak
      dipakai.
      - `countsTowardBudgetItem` menambah syarat tanggal di dalam periode,
        jadi hitungan progres dan daftar transaksi tertaut tetap satu aturan.
        Tautan lama di luar periode tidak terhitung, tanpa migrasi.
      - CATAT menawarkan pos berdasarkan tanggal transaksi, bukan hari ini.
        Mengubah tanggal ke luar periode melepas tautan dan memberi tahu.
      - Ringkasan anggaran Beranda dan layar Anggaran hanya membaca dokumen
        bulan yang disentuh periode anggaran yang ditampilkan.
      - Penyaring bawaan layar Anggaran menjadi **Aktif**. Anggaran selesai
        dan nonaktif dihitung saat penyaringnya dipilih.
      Hasil: `Budget.covers`/`Budget.months`, `ReadTransactionsInMonths`
      (membaca dokumen bulan tertentu saja). `BudgetOverviewSourceImpl` dan
      `BudgetBloc` tidak lagi memanggil `listAllTransactions`; pemakai yang
      tersisa hanya hitung ulang saldo dan hapus dompet. `BudgetBloc`
      menyimpan `statuses` untuk penyaring, menghitung progres hanya untuk
      anggaran aktif, yang lolos penyaring, dan yang sudah pernah dihitung
      (layar rincian tetap punya angka), membaca bulan yang belum dibaca
      saja, dan mengantrekan pemuatan dengan penggantian penyaring supaya
      penyaring tidak tertimpa. `BudgetItemOption` membawa periode dan
      `isArchived` alih-alih `isActive`; CATAT menampilkan pemberitahuan
      saat tautan lepas karena tanggal. Diuji termasuk mutasi (syarat
      tanggal, pilihan CATAT, `months`, anggaran yang lolos penyaring).
- [x] **T-8.2** (Opsional, dari UX-6 langkah 2) Mode pencarian Transaksi
      lintas bulan. Saat ini pencarian dan penyaring hanya mencakup bulan
      yang dibuka, dan teksnya sudah menyebut itu. Perlu cara membaca bulan
      lain tanpa `listAllTransactions` di jalur layar (NFR-PERF-002).
      ⚠ **Selesai (28 September 2026):** `TransactionRepository.listAvailableMonths()`
      baru (bulan yang pernah punya transaksi, dibaca dari dokumen indeks
      saja) memberi tahu `TransactionBloc` bulan mana yang ADA sebelum
      membukanya satu per satu lewat `listTransactionsInMonth` yang sudah
      ada — `listAllTransactions()` tetap reserved untuk penghitungan ulang
      saldo, tidak pernah dipanggil dari jalur ini.
      ⚠ Tombol "Cari di bulan lain" hanya tampil saat filter aktif bulan ini
      genuinely kosong DAN ada kata kunci pencarian (`TransactionSearchAcrossMonthsRequested`)
      -- menyaring jenis/dompet/kategori tanpa kata kunci tidak pernah
      menawarkan ini, karena bulan lain tidak akan pernah "cocok" dengan
      filter jenis semata. Tiap ketukan memindai maksimal 3 bulan sebelum
      bulan yang dibuka (`_crossMonthBatchSize`), menandainya "sudah
      dipindai", dan mengumpulkan transaksi yang lolos filter/kata kunci
      AKTIF ke `TransactionState.crossMonthGroups` -- diulang lewat tombol
      "Cari lebih jauh" sampai `crossMonthExhausted` (habis riwayat sebelum
      bulan ini).
      ⚠ Mengubah bulan, filter, atau kata kunci mereset seluruh state lintas
      bulan (`_recomputed` membangun `TransactionState` lewat konstruktor
      langsung, bukan `copyWith`, jadi field lintas bulan otomatis kembali
      ke bawaan) -- hasil pindaian lama tidak pernah tertinggal menempel ke
      kriteria yang baru. Kriteria di-jepret di awal tiap pemindaian batch
      dan dicocokkan ulang sebelum `emit` hasilnya, supaya kalau kriteria
      berubah sebelum satu batch (hingga 3 pembacaan dokumen bulan) selesai,
      hasil basi itu dibuang, bukan ditimpakan ke state yang sudah tidak
      berlaku.
      Diuji: `transaction_repository_impl_test.dart` (`listAvailableMonths`
      terurut naik, kosong kalau belum ada riwayat) dan
      `transaction_bloc_test.dart` (tanpa kata kunci tidak memindai apa
      pun/`listAvailableMonths` tidak pernah dipanggil; memindai dan
      menemukan transaksi lintas bulan lalu berhenti karena riwayat habis;
      mengubah kata kunci mereset hasil pindaian).
- [ ] **T-8.3** Ganti nama aplikasi menjadi **Tanukonomy** *(29 Sep 2026:
      pemilik melaporkan prasyarat di luar repo — merek dagang, domain, nama
      toko, setelan Firebase — sudah selesai; sisanya kode/dokumen: sapuan
      nama di dokumen (B-1) dan ikon iOS (B-12).)* (dipilih pemilik
      27 Sep 2026, riset di
      [ASO_NAME_RESEARCH.md](../03-release/ASO_NAME_RESEARCH.md)).
      Prasyarat: cek merek dagang resmi (DJKI, USPTO, EUIPO, WIPO; kelas 9
      dan 36), amankan domain dan nama di Play Console/App Store Connect.
      Lalu ADR penggantian nama; nama tampilan, ID aplikasi (sebelum rilis
      pertama), teks i18n yang menyebut "Saldough", ikon, dokumen. Nama
      paket Dart `saldough` boleh tetap.
      ⚠ **Sebagian dikerjakan (28 September 2026), lihat
      [ADR-022](../02-architecture/adr/0022-ganti-nama-aplikasi-menjadi-tanukonomy.md)
      untuk rinciannya.** Bagian yang murni kosmetik dan gampang dibatalkan
      sudah selesai TANPA menunggu prasyarat: `android:label` dan
      `CFBundleDisplayName`/`CFBundleName` jadi "Tanukonomy"; keempat
      kemunculan "Saldough" di teks i18n yang dibaca pengguna
      (`app.title`, `record.disclaimerMessage`,
      `transaction.detailManualNote`, `freelance.receiveRuleBody`) diganti.
      **ID aplikasi juga sudah diganti** (atas instruksi eksplisit pemilik,
      bukan menunggu prasyarat toko selesai lebih dulu): `com.saldough.saldough`
      → **`com.arkarizdev.tanukonomy`** di `android/app/build.gradle.kts`
      (`namespace`+`applicationId`), `ios/Runner.xcodeproj/project.pbxproj`
      (`PRODUCT_BUNDLE_IDENTIFIER`, termasuk `RunnerTests`), dan direktori
      paket Kotlin `MainActivity.kt` dipindah + `package`-nya disesuaikan.
      **Ikon peluncur dan splash screen Android selesai (28 Sep 2026)**,
      dari artwork ikon persegi (`assets/illustration/app_icon.png`,
      diserahkan pemilik) via `flutter_launcher_icons` dan
      `flutter_native_splash` (konfigurasi di `pubspec.yaml`; sumber
      turunan di `assets/icon/`). Latar ikon adaptif dan chip splash
      Android 12+ memakai warna isian asli artwork `#BD5D41`, bukan
      `colors.accent` aplikasi -- keduanya mirip tapi sengaja dibedakan
      supaya ikon tetap identik dengan artwork yang diserahkan. Splash
      memakai `colors.background` terang/gelap (`#FFF8F5`/`#231F1B`) supaya
      menyambung mulus ke layar pertama. **Hanya Android**; ikon iOS
      ditunda (lihat di bawah, butuh sumber tanpa transparansi terpisah
      karena iOS mengabaikan kanal alfa).
      **Belum dikerjakan, dan SENGAJA menunggu pemilik**: kedua prasyarat
      di atas (cek merek dagang, amankan domain/nama toko -- belum ada
      bukti keduanya sudah dilakukan; ID aplikasi di kode TIDAK
      menggantikan verifikasi ini), ikon iOS (artwork Android transparan
      tidak bisa dipakai langsung -- App Store mengabaikan alfa dan
      menampilkannya hitam), dan sapuan penggantian nama di seluruh dokumen
      produk (README, PRD, glosarium -- ditunda supaya tidak dikerjakan dua
      kali kalau cek merek dagang menggagalkan nama ini). **Jangan rilis ke
      toko sebelum ketiga hal ini selesai.**
- [x] **T-8.4** Desain arsitektur fitur online — **identitas, Analytics,
      Crashlytics selesai 29 September 2026**, lihat
      [ADR-023](../02-architecture/adr/0023-identitas-opsional-firebase-auth-analitik-crashlytics.md).
      Firebase Auth (Google Sign-In + email/sandi untuk peninjau Play),
      Firebase Analytics, dan Crashlytics terpasang; `lib/shared/auth/`,
      `lib/core/foundation/analytics/`, `lib/features/account/` (layar
      Akun, ikon di app bar Beranda). Akun sepenuhnya opsional — pencatatan
      inti tidak menyentuhnya sama sekali (NFR-REL-001 terjaga; diverifikasi
      `flutter analyze` bersih dan 555 uji lulus, semuanya sebelum
      perubahan ini juga sudah lulus).
      **Belum digarap** (bukan bagian ADR-023, lihat §2-nya): sinkronisasi
      dompet/transaksi/anggaran ke server — proyek terpisah, jauh lebih
      besar (skema, aturan keamanan, resolusi konflik), ADR sendiri nanti.
      Ikon `IconKey.account` masih `Icons.person_outline`
      (`_materialFallback`) sampai ada artwork pixel-art.
      **Aksi pemilik di luar repo (selesai per 29 Sep 2026, dilaporkan
      pemilik; closed testing sudah terbit):** taruh `google-services.json`, aktifkan provider Google
      dan Email/Password di Firebase Console, isi
      `FirebaseConfig.googleServerClientId`, daftarkan SHA-1/SHA-256 upload
      key DAN Play App Signing key ke Firebase — daftar lengkap di
      [PLAY_DATA_SAFETY.md](../03-release/PLAY_DATA_SAFETY.md) "Sebelum submit ke Play
      Console".
      **Belum ada uji otomatis** untuk `FirebaseAuthRepositoryImpl`/
      `AccountBloc` (butuh mock `firebase_auth`/`google_sign_in`) — susulan,
      dicatat di sini supaya tidak terlupa, bukan diam-diam dilewati.
      Disusul di T-8.5.
- [x] **T-8.5** Akun yang lebih matang, tetap opsional (29 Sep 2026) —
      [ADR-024](../02-architecture/adr/0024-kepemilikan-data-lokal-dan-akun.md).
      Layar Akun (kartu profil, metode masuk, "Data kamu", zona bahaya,
      form email/sandi peninjau di balik tautan), tawaran masuk di slide
      akhir onboarding, avatar status akun di Beranda, galat auth lewat
      i18n, hapus akun email/sandi meminta sandi saat sesi lama, dan uji
      `FirebaseAuthRepositoryImpl`/`AccountBloc`/layar Akun. Aturan
      kepemilikan data untuk sinkronisasi nanti ada di ADR-024 §3.3 (tanpa
      kode). `flutter analyze` bersih, 578 uji lulus; uji mutasi re-auth
      hapus akun merah tanpa cabangnya. Diperiksa di emulator Pixel 9 Pro:
      onboarding → "Sudah punya akun? Masuk" → layar Akun, form email, dan
      validasi kosong. **Belum diverifikasi agen:** masuk Google/email
      sungguhan dan hapus akun (butuh kredensial asli — dicoba pemilik).
- [x] **T-8.6** Dukungan mata uang selain Rupiah (29 Sep 2026) —
      [ADR-025](../02-architecture/adr/0025-satu-mata-uang-per-aplikasi.md).
      Satu mata uang untuk seluruh aplikasi (14 pilihan, bawaan IDR),
      dipilih di layar Akun bagian "Pengaturan", tanpa konversi saat diganti
      (dialog menampilkan contoh `Rp50.000 → $50.000,00`). Satuan simpanan
      tetap sen, jadi tanpa migrasi data. Pemisah ribuan/desimal mengikuti
      bahasa aplikasi. Kolom nominal CATAT, saldo awal dompet, dan
      `BudgetMoneyField` menerima desimal untuk mata uang berdesimal;
      pilihan cepat dihitung dari langkah per mata uang (IDR tetap sama
      persis). `flutter analyze` tanpa isu baru, 605 uji lulus; uji
      pembangun ulang terbukti merah tanpa penandaan ulangnya.
      Onboarding pertama kali kini menanyakan mata uang sebagai gerbang
      yang tidak bisa terlewat (ADR-025 §3.7): semua jalan keluar melewatinya,
      tanpa tombol lewati dan tanpa pilihan otomatis (saran wilayah perangkat
      hanya di urutan teratas), tombol lanjut nonaktif sampai ada pilihan,
      dan onboarding baru ditandai selesai setelah mata uang tersimpan. 16 uji
      onboarding lulus; tiga jaminan gerbang dibuktikan lewat uji mutasi.
      Sesudah perubahan onboarding: seluruh rangkaian uji lulus (612 uji,
      29 Sep 2026) dan `flutter analyze` tanpa error atau peringatan (11
      info `unnecessary_unawaited` di berkas uji, sudah ada sebelumnya —
      lihat B-9). **Belum:** klaim situs `tanukonomy-web` (B-4).
      **Belum diverifikasi agen di emulator:** keyboard desimal, layar Akun,
      dan langkah mata uang di onboarding (dicoba pemilik, B-5).
- [x] **T-8.7** Persiapan rilis Android — pekerjaan di luar tugas tercatat,
      direkonstruksi dari riwayat commit 28–29 Sep 2026.
      **Selesai 29 Sep 2026 atas laporan pemilik:** build rilis sudah dibuat,
      diunggah, dan dipublikasikan ke **closed testing** di Play Console;
      formulir Keamanan Data, listing, dan keputusan §1 listing sudah diisi
      pemilik. (Diverifikasi pemilik, bukan agen; detail penandatanganan di
      bawah tetap benar dan berguna untuk rilis berikutnya.)
      - `a081bfe` `android/app/build.gradle.kts` membaca `android/key.properties`
        (gitignore, begitu pula `*.jks`) dan memasang `signingConfigs.release`;
        tanpa berkas itu, rilis jatuh ke kunci debug supaya
        `flutter run --release` tetap jalan. Ini kunci **unggah** untuk Play App
        Signing. ⚠ Keystore PKCS12: `storePassword` dan `keyPassword` harus
        sama persis, kalau beda build gagal "Given final block not properly
        padded". Cadangkan `.jks` dan `key.properties` di luar repo.
      - Izin `INTERNET` ada di manifes utama (bukan hanya debug/profile),
        dibutuhkan Firebase Auth/Analytics/Crashlytics di build rilis
        (`ec2721a` hanya menghapus komentar penjelasnya).
      - `8b0ff57`, `a2de9d1` `android/app/google-services.json` masuk repo
        dan `FirebaseConfig.googleServerClientId` diisi dari klien OAuth web
        di dalamnya (ADR-023).
      - `05c6e21` versi `0.1.0+1` → **`0.2.0+3`**, dan `shorebird.yaml`
        (`app_id`, bukan rahasia) didaftarkan sebagai aset di `pubspec.yaml`
        untuk pembaruan kode lewat Shorebird.
      - `7ed1a93` [PLAY_STORE_LISTING.md](../03-release/PLAY_STORE_LISTING.md) (draf listing)
        dan tambahan di ASO_NAME_RESEARCH.md.
      ⚠ Tiap `flutter build`/`flutter run` menulis ulang `minSdk` di
      `android/app/build.gradle.kts` menjadi `flutter.minSdkVersion`;
      kembalikan ke `23` sebelum commit (`flutter_secure_storage` 10
      menuntutnya).
- [x] **T-8.8** Label navigasi bawah tidak terbungkus di 360dp, dan chip
      nominal cepat mengikuti bahasa (29 Sep 2026; ditemukan saat merender
      tangkapan layar Play Store di emulator 1080×2160, densitas 420).
      - Label tab "Transactions" terbungkus jadi "Transaction" + "s" (lebar
        teks 83,8dp di slot 72dp; SpaceMono 11px tebal). Mengecilkan font
        dilarang ADR-020 §3.2 (minimum 11px), jadi labelnya diganti: tab dan
        judul layar riwayat kini **Riwayat** (id) dan **History** (en),
        `appShell.transactionsTabLabel` dan `transaction.pageTitle`. Kata
        "transaksi" sebagai benda ("Catat Transaksi", "Transaksi terbaru",
        "Filter Transaksi") tidak diganti. Nama kunci i18n dibiarkan.
      - Sufiks chip nominal cepat pindah dari `money_input.dart` ke i18n
        (`common.quickAmountThousands`/`quickAmountMillions`): `+10rb`/`+5jt`
        (id), `+10k`/`+5M` (en). Di HEAD sebelumnya kodenya sudah memilih per
        bahasa lewat percabangan; kini teksnya di berkas terjemahan.
      Diuji: `app_shell_page_test.dart` (lebar 360dp, kedua bahasa, font asli
      SpaceMono dimuat; tiap label sebaris, tanpa overflow; terbukti merah
      dengan label lama) dan `record_amount_field_test.dart` (chip `+10k`,
      tanpa `rb`, di bahasa Inggris). ⚠ Uji yang mengganti bahasa di
      `testWidgets` harus memuat pustaka `en` lewat
      `tester.runAsync(() => LocaleSettings.setLocale(AppLocale.en))`;
      `setLocale` langsung menggantung dan `setLocaleSync` melempar
      "Deferred library l_en was not loaded". Di luar PRD (polish).
      Tangkapan layar Play Store dan situs perlu dirender ulang (B-3).

- [x] **T-8.9** Hapus fitur contoh `example_note` (dari B-10, 29 Sep 2026,
      diputuskan pemilik). Sisa templat proyek yang hanya dapat dicapai dari
      menu pengembang debug. Dihapus `lib/features/example_note/` dan
      `test/features/example_note/`, pendaftarannya di
      `lib/core/di/src/root_module.dart` (`_featureModules` kini kosong), baris
      di peta konteks skill `ux-review` dan pohon ARCHITECTURE_OVERVIEW.md.
      Verifikasi: `flutter analyze` tanpa isu baru dan seluruh uji lulus
      (609 uji lulus; 3 uji `example_note` ikut dihapus dari 612). Di luar PRD (kebersihan).
- [x] **T-8.10** `PixelTheme` jadi tema global aplikasi (1 Okt 2026,
      keputusan pemilik,
      [ADR-031](../02-architecture/adr/0031-pixeltheme-jadi-tema-global.md)).
      Alasan dua tema (layar 1.0 memakai `AppTheme`) hilang sejak cutover
      Fase 3, tetapi `PixelTheme(child: …)` masih dipasang ulang di 12 tempat,
      snackbar akar dan menu pengembang masih bergaya 1.0, dan `google_fonts`
      mengunduh huruf yang tidak dipakai. Kerjakan: tema pixel jadi
      `theme`/`darkTheme` `MaterialApp`, hapus 12 pembungkus, hapus
      `AppTheme`, palet `AppColorsExtension.light`/`dark`, `AppChip`, dan
      dependensi `google_fonts`; cadangan `context.appColors` jadi
      `pixelLight`; ganti `pixel_theme_test`; perbarui komentar
      `capturedThemes` di `route_navigation.dart`.
      ⚠ Cari pemakaian `colorScheme.`/`Theme.of(context).` yang dulu jatuh ke
      `AppTheme` (mis. `primary` hijau 1.0). Jangan mengubah palet pixel.
      Verifikasi: `flutter analyze` bersih, seluruh uji lulus, tidak ada
      `PixelTheme(`/`AppTheme`/`GoogleFonts` di `lib/`, cek di HP terang dan
      gelap (daftar layar di ADR-031 §6). Di luar PRD (kebersihan arsitektur).
      Hasil kode (1 Okt 2026): 12 pembungkus dihapus, `PixelTheme` jadi
      penyusun tema (`PixelTheme.light`/`.dark`), `AppTheme`, palet 1.0,
      `AppChip` (+ ujinya), dan `google_fonts` dihapus. Uji kontras garis
      ikon (`iconTile`) ternyata selama ini memeriksa palet 1.0 — kini
      memeriksa palet pixel dan lulus. Uji halaman yang memasang
      `AppShellPage` kini memakai `theme: PixelTheme.light` seperti aplikasi.
      844 uji lulus (867 dikurangi uji palet 1.0 dan `AppChip`), analyze
      bersih. Dicek di emulator Slim_Pixel (1080×2340, atas permintaan
      pemilik), pemasangan bersih, terang dan gelap: langkah bahasa dan mata
      uang onboarding, Beranda, tur spotlight, tab Dompet + lembar tambah
      dompet + snackbar, rincian dompet, CATAT, lembar suara, Akun,
      Kategori + dialognya, template anggaran, pemilih tanggal — semua
      memakai palet dan huruf pixel; mode gelap arang hangat. Di emulator
      Pixel_9_Pro sempat ANR saat peluncuran ketika emulator kelebihan beban
      (system_server sendiri tertahan 5,7 dtk); tidak terulang di
      Slim_Pixel, tetapi tidak dibandingkan dengan build sebelum perubahan.
      Temuan di luar tugas ini: B-17 (kini T-11.16), B-18 (kini T-8.11).

- [x] **T-8.11** Dialog dan pemilih tanggal bergaya pixel (dari B-18,
      1 Okt 2026). `PixelTheme` belum punya `dialogTheme`/`datePickerTheme`,
      jadi dialog memakai bentuk bulat besar Material berlatar putih dan
      pemilih tanggal mode gelap berlatar hitam dingin. Kini keduanya
      berlatar `colors.background`, sudut `pixelSm`, garis tepi `edge`
      `pixelThick`, tanpa elevasi/tint.
      Verifikasi: uji `pixel_theme_test` (terang dan gelap); 846 uji lulus,
      analyze bersih; emulator Slim_Pixel: dialog "New category" (terang) dan
      pemilih tanggal CATAT (gelap). Di luar PRD (konsistensi ADR-015).

- [x] **T-8.12** Fokus CATAT tidak melompat kembali ke nominal (1 Okt
      2026, permintaan pemilik; teramati sejak verifikasi M1). Kolom nominal
      `autofocus` tidak pernah kehilangan fokus saat pemilih tanggal, menu,
      atau dialog dibuka, sehingga Flutter mengembalikan fokus ke nominal saat
      ditutup dan papan ketik muncul lagi. Kini kolom nominal dan catatan
      memakai `onTapOutside: dismissKeyboardOnTapOutside`
      (`lib/core/presentation/widgets/dismiss_keyboard.dart`).
      Verifikasi: uji `record_amount_field_test` (gagal tanpa perbaikan);
      847 uji lulus, analyze bersih; emulator Slim_Pixel: CATAT → ketuk di
      luar (papan ketik tertutup) → pemilih tanggal → Batal → papan ketik tetap
      tertutup. Kolom di formulir lain menyusul (B-19). Di luar PRD (UX).

## Fase 9: Onboarding, info, dan tur spotlight

Rincian, konten, dan key spotlight ada di
[ONBOARDING_PLAN.md](../01-product/features/ONBOARDING_PLAN.md). T-9.1 menunggu keputusan pemilik
KO-1..KO-7 di dokumen itu (dijawab 27 Sep 2026). Berkaitan dengan UX-1: edukasi CATAT pindah dari
lembar pilihan ke onboarding dan tur CATAT.

- [x] **T-9.1** ADR-021 onboarding dan spotlight, plus teks final `id`/`en`.
      [ADR-021](../02-architecture/adr/0021-onboarding-dan-tur-spotlight.md)
      disetujui pemilik 28 Sep 2026; namespace slang `onboarding`, `tour`,
      `info`, plus label pengalih CATAT.
- [x] **T-9.1a** Maskot dan ilustrasi onboarding: maskot tanuki juru catat
      dipilih; pemilik membuat gambar dari brief konten
      [ONBOARDING_ART_BRIEF.md](../01-product/features/ONBOARDING_ART_BRIEF.md). Lima PNG
      (`assets/illustration/onboarding_{1..5}.png`, latar transparan)
      diserahkan 28 Sep 2026; dipasang di T-9.3.
- [x] **T-9.2** Repositori progres onboarding/tur di atas `KeyValueStorage`
      (`lib/core/tutorial/`).
- [x] **T-9.3** Layar onboarding dan gerbangnya saat aplikasi dibuka, dengan
      adegan bergerak (`lib/core/presentation/motion/`).
- [x] **T-9.4** Komponen `SpotlightOverlay`, `SpotlightController`,
      `SpotlightTarget` (plus `TourTrigger`, `TourVisibility`).
- [x] **T-9.5** Tur Beranda (TR-HOME). Diperiksa di emulator 384dp terang dan
      gelap 28 Sep 2026; titik tinjau kedua disetujui pemilik (mode gelap
      dilunakkan, ADR-016 §7).
- [x] **T-9.6** Tur CATAT (TR-CATAT), bersama UX-1: CATAT langsung ke
      formulir Pengeluaran dengan pengalih tiga jenis; tur menyorot pengalih,
      nominal, dompet, dan pos anggaran (bila ditawarkan).
- [x] **T-9.7** Tur Dompet, Transaksi, Anggaran. Transaksi hanya saat bulan
      tampil berisi; Anggaran kosong menyorot Template dulu, ringkasan dan
      penyaring menyusul begitu ada anggaran.
- [x] **T-9.8** Tur rincian anggaran dan Freelance: pos pertama dan tombol
      catatnya; proyek pertama di ikhtisar; tab worklog di rincian proyek;
      "catat diterima" disorot saat tab Pembayaran dibuka.
- [x] **T-9.9** Lapis info: putar ulang tur, lihat pengenalan, setel ulang.
      Ikon info di kartu utama keempat tab (`AppHeroCard.tour`) dan di bilah
      atas ikhtisar Freelance.
- [x] **T-9.10** Verifikasi menyeluruh di emulator (28 Sep 2026, build rilis,
      emulator 384dp): pengguna lama (build `main` berisi dompet, lalu
      diperbarui) melihat onboarding sekali dengan data utuh (KO-1) dan tidak
      lagi sesudah dibuka ulang; menu info (putar ulang, pengenalan mode
      tinjau, setel ulang dengan konfirmasi); pengguna baru: onboarding,
      tur Beranda, CATAT, transaksi pertama memunculkan sorotan kartu Beranda
      yang baru tampil, tur Transaksi dan Anggaran; mode gelap. Freelance dan
      rincian anggaran diverifikasi lewat uji widget shell sungguhan.

## Fase 11: Catat Cerdas — kategori dan suara

Riset, keputusan pemilik, dan rencana rinci di
[VOICE_INPUT_RESEARCH.md](../01-product/features/VOICE_INPUT_RESEARCH.md);
keputusan arsitektur di [ADR-026](../02-architecture/adr/0026-sistem-kategori.md)
(kategori) dan [ADR-027](../02-architecture/adr/0027-catat-cerdas-interpreter-yang-bisa-diganti.md)
(bukti teks suara/notifikasi/foto, interpreter yang bisa diganti, draf CATAT).
Nomor 11, karena Fase 10 dicadangkan untuk sinkronisasi (B-7). Dari B-13 dan
B-14.
Verifikasi mendalam dilakukan per milestone (M1: T-11.1–11.4, M2:
T-11.5–11.6, M3: T-11.7–11.9) — lihat
[VERIFICATION_PLAN_FASE_11.md](VERIFICATION_PLAN_FASE_11.md).

- [x] **T-11.1** Sistem kategori (dari B-13, ADR-026): entitas `Category`,
      repository, set bawaan, migrasi `categoryKey` → `categoryId` (label
      transfer dibuang), pemilih kategori CATAT dengan "Tambah kategori",
      penyaring/judul Transaksi memakai id, layar Kategori dari Akun.
      ⚠ Jebakan: migrasi menyentuh data closed testing — tulis dokumen
      kategori lebih dulu, id `legacy.*` deterministik, uji idempoten.
      Verifikasi: uji migrasi, `flutter analyze`, seluruh uji lulus, cek di
      emulator dengan data lama.
      Hasil (30 Sep 2026): `lib/shared/category/` (entitas, 17 kategori
      bawaan dengan alias, `CategoryRepositoryImpl`, `CreateCategory`,
      `MigrateLegacyCategories` lewat port `LegacyCategoryLabels` yang
      diimplementasikan `TransactionRepositoryImpl`, `ActiveCategories`),
      skema transaksi 2 (`categoryId`), pemilih kategori CATAT dengan
      "Tambah kategori", layar Kategori dari Akun. 621 uji lulus,
      `flutter analyze` bersih. Emulator Pixel 9 Pro: pemasangan baru
      menanam kategori bawaan, layar Kategori dan pemilih CATAT berjalan,
      "Tambah kategori" langsung terpilih. **Belum dicek di emulator dengan
      data skema 1 sungguhan** (migrasi hanya diuji dengan dokumen JSON skema
      1 di penyimpanan memori) — cek di perangkat closed testing pemilik
      sebelum rilis.
- [x] **T-11.2** Tipe domain Catat Cerdas (`CaptureEvidence`,
      `TransactionInterpreter`, `InterpretedTransaction`, `RecordDraft`,
      `DraftIssue`) dan `SpokenAmountParser` (ADR-027 §3.1–3.3).
      Hasil (30 Sep 2026): `lib/features/record/domain/capture/`,
      `lib/core/utils/formatters/spoken_amount_parser.dart` (bilangan kata,
      satuan lisan, slang, "Rp35.000,00", aritmetika rasional `int`, tanpa
      `double`); 32 uji nominal.
- [x] **T-11.3** `CaptureDraftResolver` + `RuleBasedTransactionInterpreter`
      dengan dataset benchmark teks (§10 dokumen riset) sebagai uji.
      Hasil (30 Sep 2026): 30 kasus §10 (sederhana, alami, dompet, transfer,
      ambigu, campur bahasa) lulus 100% di interpreter aturan, plus uji pagar
      halusinasi (nominal/dompet/kategori karangan ditolak). Angka ini dari
      kalimat teks, **bukan** transkrip suara nyata — ukur ulang di T-11.9.
- [x] **T-11.4** `openRecordSheet(draft:)` dan tiga formulir menerima draf
      parsial (catatan, kategori, tanggal) dan menyorot issue.
      Hasil (30 Sep 2026): `RecordDraftCard` di atas formulir (teks
      tertangkap + daftar hal yang perlu diperiksa); dompet tidak dikenal
      dan transfer tanpa asal tidak diisi dompet bawaan. 691 uji lulus.
- [ ] **T-11.5** STT sistem (`speech_to_text`), izin mikrofon/ucapan Android
      dan iOS, sheet rekam, tombol mikrofon di CATAT.
      Progres (30 Sep 2026, belum dicentang): `SpeechTranscriber` +
      `SystemSpeechTranscriber`, `VoiceCaptureBloc` (4 uji), lembar rekam,
      tombol mikrofon di samping pengalih CATAT, izin `RECORD_AUDIO` +
      `<queries>` Android, dua kunci Info.plist iOS. 695 uji lulus.
      Emulator Pixel 9 Pro: tombol mikrofon, lembar rekam, dan "Ketik saja"
      kembali ke CATAT berjalan; emulator tidak punya layanan pengenal
      terpilih ("no selected voice recognition service") dan aplikasi kini
      melaporkannya dengan benar sebagai "belum punya pengenal ucapan". ANR
      sekali terlihat sesudah pasang ulang build debug, tidak terulang di
      dua percobaan berikutnya. **Belum teruji:** ucapan sungguhan sampai
      formulir terisi, dan jalur izin ditolak — butuh perangkat (atau
      emulator dengan layanan pengenal dipilih).
      Perbaikan dari pemilik (30 Sep 2026): (1) umpan balik rekam — lencana
      REKAM berkedip dengan penghitung waktu, cincin berdenyut mengikuti
      kekuatan suara, teks status per tahap; (2) pilihan bahasa di awal
      onboarding dan di Akun, satu pilihan untuk tampilan dan ucapan
      ([ADR-028](../02-architecture/adr/0028-bahasa-aplikasi-dipilih-pengguna.md));
      (3) rekaman tidak lagi mulai sendiri — lembar dibuka di tahap siap;
      (4) satu tombol bulat untuk mulai/berhenti/rekam ulang, plus "Ketik
      saja"; (5) CATAT dan suara jadi dua FAB bertumpuk di kanan bawah,
      navigasi bawah 4 tab, langkah tur baru `homeVoice`. 729 uji lulus.
      Dicek di Samsung SM-M156B 30 Sep 2026: tur `homeVoice` muncul sekali,
      lembar suara terbuka di tahap siap, REKAM + cincin + indikator mikrofon
      Android tampil saat merekam, hening ±5 dtk berakhir di "Rekam ulang",
      "Ketik saja" membuka CATAT kosong, ganti bahasa di Akun mengubah semua
      teks dan nama kategori bawaan (nama yang diganti pengguna tetap).
      Temuan: FAB menutupi nominal baris terakhir — diperbaiki dengan
      `AppSpacing.fabClearance` di keempat tab. Sisa: ucapan sungguhan oleh
      pemilik, langkah bahasa onboarding (perlu pemasangan bersih).
      Gagal jaringan (ADR-027 §3.5 butir 7): pesan "butuh internet" dan
      "Ketik saja" jadi tombol utama; diuji di `voice_capture_sheet_test`.
      Berhenti otomatis (keputusan pemilik 30 Sep 2026, tombol berhenti
      tidak bekerja normal di HP): tombol berhenti manual dan
      `SpeechTranscriber.stop` dihapus; selama merekam tombol bulat hanya
      penanda ("Mendengarkan"), sesi berakhir sendiri sesudah diam 3 dtk
      atau 20 dtk. Diuji di `voice_capture_sheet_test`; belum dicek di HP.
      Hierarki teks lembar suara (keputusan pemilik 30 Sep 2026, terlalu
      banyak teks yang mirip): per tahap satu pesan utama (transkrip
      `titleMedium`, petunjuk/galat `bodyLarge`) dan paling banyak satu
      keterangan kecil redup (`bodySmall`); label di bawah tombol hanya saat
      gagal; saat memahami cukup transkrip + bilah kemajuan; "Merekam" tidak
      diulang karena lencana REKAM sudah ada.
      Paket bahasa luring (temuan pemilik 30 Sep 2026: English di mode
      pesawat gagal "belum punya pengenal ucapan", Indonesia aman):
      `error_language_unavailable` kini `SpeechFailure.languageOffline`
      dengan pesan "sambungkan internet atau unduh paket bahasanya", "Ketik
      saja" jadi utama; kode galat mentah pengenal (kecuali diam/tak
      terdengar) dilaporkan non-fatal ke Crashlytics tanpa isi ucapan.
      **Belum dicek di HP** bahwa Samsung memang mengirim kode itu.
- [ ] **T-11.6** Pembaruan formulir Keamanan Data dan kebijakan privasi
      (audio diproses Google/Apple; teks transaksi yang tidak yakin dikirim ke
      Firebase AI / Gemini). Pemberitahuan ke penguji closed testing bahwa
      tier gratis memakai data untuk pelatihan (ADR-027 §3.5).
- [x] **T-11.7** `FirebaseAiTransactionInterpreter` (`firebase_ai`,
      `googleAI()`, `responseSchema` = kontrak §3.2, model flash-lite
      stabil terkini) + `CascadingTransactionInterpreter` (aturan dulu, cloud
      bila ragu) + `firebase_app_check`. Tier gratis (Spark).
      Kaskade sudah disiapkan di T-11.13 (`CaptureDraftComposer`): cukup
      daftarkan interpreter Firebase AI di slot cloud-nya, yang juga
      mengisi `date` + `dateText` (ADR-029 §3.2).
      Hasil (30 Sep 2026): `firebase_ai` 4.0.0 + `firebase_app_check`
      0.4.8; `firebase_ai_transaction_interpreter.dart` (model
      `gemini-3.5-flash-lite`, temperatur 0, `responseSchema` kutipan +
      `date` YYYY-MM-DD, prompt hanya teks + nama dompet/kategori + tanggal +
      bahasa; model dibuat saat pertama dipakai, jadi Firebase yang belum
      terinisialisasi menjadi `Left`); tanggal yang tidak ada di kalender
      dibuang; terdaftar di slot cloud `CaptureDraftComposer`. App Check
      diaktifkan di `AppBootstrap.run` (Play Integrity / App Attest, penyedia
      debug di mode debug). Uji: prompt tanpa saldo/id, JSON rusak, galat
      jaringan, keluaran model lewat resolver (nominal karangan ditolak).
      **Menunggu pemilik:** aktifkan Firebase AI Logic (Gemini Developer
      API) di Console, daftarkan App Check (Play Integrity + SHA-256 kunci
      rilis; token debug untuk build debug), biarkan penegakan App Check
      mati sampai metrik menunjukkan permintaan sah.       Pemilik melaporkan Firebase AI Logic sudah aktif (1 Okt 2026).
      Terverifikasi (1 Okt 2026, pemilik): token debug App Check terdaftar,
      panggilan Gemini dari aplikasi berhasil dan tercatat di monitor AI
      Logic Console.
      Sampai Console diaktifkan, panggilan cloud gagal dan draf aturan
      dipakai tanpa pesan galat (sesuai desain).
      ⚠ Jebakan: jangan kirim saldo/riwayat/id; offline dan kuota habis
      harus jatuh ke draf aturan tanpa galat ke pengguna. Penerimaan
      koneksi (ADR-027 §3.5 butir 7): tanpa cek koneksi di muka, batas
      waktu ±5 dtk, tanpa antrean kirim ulang; uji dengan fake yang
      melempar galat jaringan dan yang tidak pernah menjawab.
- [ ] **T-11.8** Pindah ke tier berbayar (Blaze) sebelum rilis publik:
      billing, batas anggaran, cek ulang harga; tanpa perubahan kode.
      Dikerjakan pemilik; agen memperbarui dokumen.
- [x] **T-11.10** Perbaiki temuan verifikasi M1
      ([VERIFICATION_PLAN_FASE_11.md](VERIFICATION_PLAN_FASE_11.md)).
      Hasil (30 Sep 2026): F1 dibiarkan (KT-3, belum ada pengguna). F2
      "setengah", "koma", sisa angka tak tersusun sesudah skala dipisah, batas
      nominal 1 triliun satuan; F3 deret digit > 15 bukan nominal; F4 kata
      pemasukan lemah kalah oleh tanda pengeluaran; F5 alias `air`, `data`,
      `anak`, `les`, `fee`, `project` dibuang; F6 kategori bawaan disimpan
      sebelum label dibaca + kegagalan migrasi ke Crashlytics
      (`AppBootstrap.recordNonFatal`). Kasus probe jadi uji regresi; 724 uji
      lulus. F7–F10 ke antrean B-16. Uji migrasi di HP tidak diulang: F1
      diterima, dan perubahan F6 hanya mengubah urutan tulis (diuji unit).
- [x] **T-11.14** Tanya bahasa ucapan sekali untuk pengguna lama (30 Sep
      2026, keputusan pemilik; ADR-028 §3.8). Pengguna yang update tidak
      melihat langkah bahasa onboarding, sehingga bahasa ucapan diam-diam
      mengikuti bahasa HP. Sebelum lembar suara dibuka pertama kali tanpa
      pilihan tersimpan, tampilkan pilihan bahasa; simpan lewat
      `ChangeAppLanguage`.
      Verifikasi: uji `SpeechLanguagePrompt` dan lembar pilihannya.
      Di luar PRD: perluasan ADR-028.
      Hasil (30 Sep 2026): `SpeechLanguagePrompt` (`lib/core/language/`),
      `speech_language_sheet.dart`, `openVoiceRecord` bertanya sebelum
      lembar rekam; `RecordBloc.speechLanguagePrompt` lewat `RecordScope`.
      **Belum dicek di HP** (butuh data pengguna lama tanpa
      `settings/language`).
- [ ] **T-11.9** Benchmark lengkap: dataset §10 lewat aturan vs aturan+cloud,
      transkrip suara nyata di perangkat, laju panggilan cloud, latensi.
      ⚠ Sebagian (1 Okt 2026): bagian teks selesai, transkrip suara nyata
      belum. Dataset bersama `test/shared/capture/benchmark/` (52 kasus
      aturan id/en yang sudah ada + 35 kasus sulit baru: slang, susunan
      bebas, "narik tunai", "dibayarin klien"); benchmark perangkat
      `integration_test/capture_cloud_benchmark_test.dart` (aturan, kaskade
      seperti aplikasi, dan Gemini untuk semua kasus). Hasil di HP Xiaomi
      22021211RG, `gemini-3.5-flash-lite`, ringkasannya di
      VOICE_INPUT_RESEARCH §10.1: kasus aturan id 100% / kaskade 95% /
      Gemini 86% benar semua; kasus sulit id 73% / 73% / 93%, en 40% / 60% /
      100%. Kaskade hanya memanggil Gemini 14 dari 87 kasus dan **tidak
      sekali pun** di 30 kasus sulit id, karena aturan yakin walau salah
      jenis. Gemini: 87/87 berhasil, p50 1,56 dtk, p95 1,84 dtk, maks 2,1 dtk
      (jauh di bawah batas 5 dtk). Temuan jadi T-11.22–11.24.
      ⚠ `flutter test` di perangkat **meng-uninstall aplikasi** di akhir
      putaran (data lokal hilang, token debug App Check berganti): selalu
      pakai `--no-uninstall`, lalu pasang ulang build biasa dengan
      `adb install -r`. Kuota harian tier gratis bisa habis di putaran kedua
      dalam sehari (3 panggilan "exceeded your current quota"). Token debug harus didaftarkan untuk perangkat itu;
      `firebase_ai` selalu mengirim token App Check bila pluginnya terpasang,
      jadi token yang tidak sah ditolak walau penegakan mati.
- [x] **T-11.22** Gerbang kaskade: aturan yang yakin tetapi salah jenis
      tidak pernah sampai ke Gemini (temuan T-11.9). "barusan dibayarin klien
      … tiga juta setengah", "hadiah ulang tahun dari tante", "jual sepatu
      bekas", "narik tunai dari BCA", "gopay aku isi … pakai BCA", "moved 1
      million from BCA to GoPay" terbaca pengeluaran dengan yakin. Pilihan:
      jenis yang hanya hasil bawaan (tanpa kata arah) dianggap ragu, atau
      kategori kosong ikut membuat ragu. Butuh keputusan pemilik soal biaya
      panggilan (KT baru bila perlu).
      Verifikasi: benchmark T-11.9, kasus sulit kaskade mendekati Gemini;
      kasus aturan tetap 100%.
      Di luar PRD: ketepatan Catat Cerdas (ADR-027/029).
      ⚠ Sebagian (1 Okt 2026): pemilik memilih gerbang "jenis tanpa kata
      arah" (ADR-029 §3.4 revisi). Perkiraan dari hasil benchmark: kasus sulit
      71% → 89% benar, kasus aturan tetap 94%, Gemini terpanggil 25% → 33%
      (kasus aturan) dan 3% → 40% (kasus sulit). Kode:
      `InterpretedTransaction.kindGuessed` diisi interpreter aturan bila tidak
      ada kata transfer/pemasukan/tanda pengeluaran; `CaptureDraftComposer`
      tetap memanggil cloud untuknya, dan cloud gagal → draf aturan apa
      adanya. Uji penyusun draf + 2 kasus; 916 uji lulus.
      Benchmark ulang di perangkat (1 Okt 2026, VOICE_INPUT_RESEARCH §10.1):
      kaskade kasus sulit id 73% → 90%, en 60% → 80%; kasus aturan tetap
      (95% id, 89% en: sisanya kasus dua nominal yang kini sengaja tetap
      disorot, T-11.23). Gemini terpanggil 31 dari 87 kasus (16% → 36%).
      Satu kemunduran: "langganan netflix bulanan …" kini Tagihan, bukan
      Hiburan (kategori yang wajar). Jalankan uji perangkat dengan
      `flutter test --no-uninstall` supaya data dan token debug App Check
      tidak hilang.
- [x] **T-11.23** Gemini tidak boleh menghapus masalah yang benar dari
      aturan (temuan T-11.9): "kopi 25 ribu roti 15 ribu" dan "coffee 25
      thousand and bread 15 thousand" punya `amountMultiple` di aturan, tetapi
      kaskade mengganti draf dengan Rp25.000 tanpa peringatan; "dapat 10
      dolar" mendapat kategori karangan. Masalah `amountMultiple`,
      `amountAmbiguous`, dan `currencyUnsupported` dari aturan dibawa ke draf
      cloud (atau cloud tidak dipanggil untuknya).
      Verifikasi: uji penyusun draf dengan cloud palsu; benchmark kasus aturan
      kaskade kembali 100%.
      Di luar PRD: ketepatan Catat Cerdas.
      Hasil (1 Okt 2026): cloud tetap dipanggil (pilihannya berguna, mis.
      "kopi 35 ribu tadi, roti 15 ribu itu salah"), tetapi
      `CaptureDraftComposer` membawa `amountMultiple`/`amountAmbiguous`/
      `currencyUnsupported` dari draf aturan ke draf cloud: nominal pilihan
      Gemini terisi dan tetap disorot, draf tidak yakin, jadi notifikasi
      seperti ini tidak tercatat otomatis. Uji penyusun draf diperbarui +
      kasus "kopi 25 ribu roti 15 ribu". 914 uji lulus. Benchmark perangkat
      belum diulang (butuh HP uji; `flutter test` meng-uninstall aplikasi).
- [x] **T-11.24** "tiga juta setengah" terbaca Rp3.000.000, bukan
      Rp3.500.000, di aturan maupun lewat kutipan Gemini (`SpokenAmountParser`;
      temuan T-11.9). "satu setengah juta" sudah benar.
      Verifikasi: uji parser + kasus benchmark.
      Di luar PRD: ketepatan Catat Cerdas.
      Hasil (1 Okt 2026): "setengah" tepat sesudah skala menambah setengah
      skala itu ("tiga juta setengah" = 3.500.000, "dua ribu setengah" =
      2.500); "setengah juta"/"satu setengah juta" tetap. Uji parser lulus.
- [x] **T-11.11** Paket bahasa Catat Cerdas (30 Sep 2026, tinjauan pemilik;
      [ADR-029](../02-architecture/adr/0029-catat-cerdas-paket-bahasa-tanggal-dan-jalur-cloud.md) §3.1).
      Kosakata Indonesia tertanam di interpreter, resolver, dan
      `SpokenAmountParser`; bahasa Inggris ditafsirkan dengan aturan
      Indonesia. Pindahkan ke `CaptureLanguage` + `NumberLexicon`, registri
      `CaptureLanguages` berisi `id` dan `en`, parser nominal generik.
      ⚠ Jebakan: pemisah ribuan ikut bahasa ("35.000" id vs "5,000" en);
      "may" dan "and" hanya bermakna di sebelah angka.
      Verifikasi: benchmark §10 tetap lulus lewat paket `id`; benchmark
      bahasa Inggris setara lewat paket `en`; `flutter analyze` bersih.
      Di luar PRD: perluasan Catat Cerdas (ADR-027).
      Hasil (30 Sep 2026): `lib/core/utils/formatters/number_lexicon.dart`
      (`indonesian`, `english`, `neutral`), `SpokenAmountParser` membaca
      peran kata dari leksikon (termasuk kata sambung "and"/"a" dan pemisah
      ribuan per bahasa), `lib/features/record/domain/capture/language/`
      (`CaptureLanguage`, `CaptureLanguages`, paket `id` dan `en`);
      interpreter aturan dan resolver tidak lagi berisi kata bahasa apa pun.
      Benchmark §10 tetap lulus lewat paket `id`; 9 kasus benchmark bahasa
      Inggris + uji bilangan kata Inggris lulus.
- [x] **T-11.12** Tanggal pasti dan angka polos IDR (30 Sep 2026, tinjauan
      pemilik; ADR-029 §3.2–3.3). "beli kopi 5000 tanggal 27 september"
      harus menghasilkan Rp5.000 pada 27 Sep. `SpokenDateParser` +
      `DateLexicon`, field `InterpretedTransaction.date`, resolver hanya
      memvalidasi (kutipan ada, tidak di masa depan), issue `dateUnclear`.
      Tanpa tahun = tanggal terdekat yang sudah lewat.
      `AppCurrency.plainAmountMinUnits` (IDR 100).
      ⚠ Jebakan: rentang tanggal dikeluarkan dari pencarian nominal sebelum
      memilih nominal; 31 Feb dan tahun masa depan → `dateUnclear`.
      Verifikasi: uji parser tanggal (id/en, pergantian tahun, hari
      saja, angka), kasus benchmark baru, pagar karangan tanggal.
      Di luar PRD: perluasan Catat Cerdas (ADR-027).
      Hasil (30 Sep 2026): `spoken_date_parser.dart` (`DateLexicon`
      id/en: relatif, "N hari lalu", hari + bulan (+ tahun), "tanggal N" /
      "on the Nth", angka H/B atau B/H; tanda hubung wajib bertahun supaya
      "2-3 kopi" bukan tanggal), `InterpretedTransaction.date`,
      `DraftIssue.dateUnclear` + teks i18n, `AppCurrency.plainAmountMinUnits`
      (IDR 100) lewat `SpokenAmountParser.select`. "beli kopi 5000 tanggal
      27 september" → Rp5.000, 27 Sep 2026, catatan "beli kopi". 808 uji
      lulus, `flutter analyze` bersih.
- [x] **T-11.13** `CaptureDraftComposer`: aturan → cloud, dan bahasa tanpa
      paket langsung ke cloud (30 Sep 2026, tinjauan pemilik; ADR-029 §3.4).
      Menggantikan rencana `CascadingTransactionInterpreter` di T-11.7.
      `CaptureEvidence.languageCode`; slot cloud `null` sampai T-11.7.
      ⚠ Jebakan: galat atau lewat batas waktu cloud tidak boleh menjadi
      pesan galat; tanpa paket dan tanpa cloud → draf kosong, bukan gagal.
      Verifikasi: uji komposer dengan fake (yakin, tidak yakin, tanpa paket,
      cloud galat, cloud tidak menjawab); uji bloc suara.
      Di luar PRD: perluasan Catat Cerdas (ADR-027).
      Hasil (30 Sep 2026): `capture_draft_composer.dart` (domain),
      `VoiceCaptureBloc` memakai penyusun (tidak ada lagi tahap gagal karena
      tafsir), `VoiceCaptureStarted.languageCode` dari `ActiveLanguage`,
      DI mendaftarkan penyusun dengan slot cloud `null`. 8 uji penyusun
      (yakin, ragu → cloud, cloud galat/melempar/tidak menjawab, tanpa paket
      → cloud, tanpa paket dan tanpa cloud → draf kosong, kode locale `en_US`)
      + uji bloc bahasa tanpa paket. **Belum teruji:** ucapan nyata bahasa
      Inggris di perangkat (masuk T-11.9).
- [x] **T-11.15** Perbaiki temuan verifikasi kode M2 dan M3
      ([VERIFICATION_PLAN_FASE_11.md](VERIFICATION_PLAN_FASE_11.md), G1–G3,
      H1–H4).
      Hasil (30 Sep 2026): jalur aturan `CaptureDraftComposer` dipulihkan
      (G1, sempat dikomentari di `48851ff` sehingga semua transkrip ke
      Gemini dan draf luring kosong); pendengar `SpeechToText` dipasang ulang
      tiap sesi (G2); `listen` gagal/tidak mulai → `SpeechFailure.other`
      (G3); kutipan nominal dan tanggal dari model dicek terhadap
      `SpokenAmountParser`/`SpokenDateParser` (H1, H2; ADR-029 §3.2);
      penyusun dan interpreter cloud menangkap `Object` (H3); App Check
      sesudah Crashlytics (H4). 836 uji lulus, `flutter analyze` bersih.
      **Belum dicek di HP.**

- [x] **T-11.16** Bahasa bawaan onboarding ikut tersimpan (dari B-17,
      1 Okt 2026). Di pemasangan baru, menekan lanjut di langkah bahasa
      tanpa mengetuk pilihan bawaan tidak menyimpan `settings/language`,
      sehingga lembar bahasa ucapan T-11.14 bertanya lagi saat suara pertama
      dibuka. Kini tombol lanjut menyimpan pilihan yang terpilih
      (`OnboardingPage._confirmLanguage`).
      Verifikasi: uji `onboarding_test` "lanjut tanpa mengetuk pilihan tetap
      menyimpan bahasa bawaan (B-17)" (gagal tanpa perbaikan, lulus dengan
      perbaikan); 845 uji lulus, analyze bersih; emulator Slim_Pixel,
      pemasangan bersih: lanjut tanpa mengganti bahasa → lembar suara
      langsung terbuka tanpa pertanyaan bahasa. Di luar PRD: perluasan ADR-028.

### M4: Catat dari notifikasi ([ADR-032](../02-architecture/adr/0032-catat-dari-notifikasi.md))

Keputusan pemilik 1 Okt 2026: sumber, kata kunci, dan dompet dipilih
pengguna; pola bawaan + pola pengguna; tiga tingkat otomatis; mode pengingat +
kotak masuk atau kotak masuk saja; Gemini bila aturan ragu; diproses saat
aplikasi hidup/dibuka; daftar "Tercatat otomatis" 7 hari. Android saja.

- [ ] **T-11.17** Domain dan interpreter notifikasi: sumber, setelan, pola
      (`{amount}`/`{note}`/`{*}`) + pencocok templat + katalog pola bawaan,
      interpreter aturan notifikasi (saldo/referensi/jam bukan nominal, kata
      arah), `DraftIssue.kindUnclear`, `NotificationDraftComposer` (pola →
      aturan → Gemini, dompet sumber, arah transfer), `AutoRecordPolicy`
      (3 tingkat + dugaan ganda), draf → `Transaction`.
      ⚠ Jebakan: pola bawaan tanpa sampel asli harus ditandai di kode; ganti
      contoh umum dengan sampel dari layar debug sebelum dicentang.
      Verifikasi: uji pencocok, tiap pola bawaan, interpreter, kebijakan, mapper.
      Memenuhi FR-NOT-001.
      Progres (1 Okt 2026, belum dicentang): `lib/features/record/domain/capture/notification/`
      (sumber, setelan, pola + `NotificationTemplate`, katalog pola bawaan
      12 paket — semua `verified: false`, `NotificationText` masking/OTP/
      (saringan promo dibuang 1 Okt 2026 — diganti filter whitelist sumber,
      bawaan `defaultNotificationKeywords`), `NotificationDraftComposer` pola terverifikasi → aturan/Gemini →
      pola belum terverifikasi, deteksi bahasa notifikasi dari teks,
      `AutoRecordPolicy`, `transactionFromDraft`), `NotificationLexicon` di
      paket id/en, `DraftIssue.kindUnclear`,
      `data/capture/notification_rule_interpreter.dart`. 44+ uji domain
      lulus. **Sisa:** contoh teks masih umum — ganti dengan sampel asli dari
      layar debug, tandai pola bawaan yang cocok `verified: true`.
- [ ] **T-11.18** Native Android: `NotificationListenerService`, antrean
      serah-terima, filter sumber/kata kunci/OTP, pengingat, kanal Flutter,
      ring buffer debug, manifest (`POST_NOTIFICATIONS`, kueri `LAUNCHER`).
      ⚠ Jebakan: jangan `QUERY_ALL_PACKAGES`; OTP tidak pernah disimpan.
      Verifikasi: `adb shell cmd notification post` dari `com.android.shell`.
      Memenuhi FR-NOT-001.
      Progres (1 Okt 2026, belum dicentang): Kotlin `notificationcapture/`
      (`TransactionNotificationListener`, `CaptureQueue`, `CaptureConfig`,
      `CaptureReminders`, `NotificationCapturePlugin`), `MainActivity`,
      manifest. APK debug dan profile terbangun. Emulator: akses terdeteksi,
      sumber tersimpan. **Belum teruji:** tangkapan sampai tercatat — uji
      terputus karena emulator tertutup; ANR sekali saat pasang ulang build
      debug (sistem mengikat layanan selagi mesin Flutter debug memulai di
      thread utama, sama dengan catatan T-11.5), ulangi dengan build profile.
- [ ] **T-11.19** Data dan pemrosesan: gateway kanal (Android/tidak didukung),
      repository Hive (setelan, kotak masuk, log, id terproses, pola),
      `ProcessCapturedNotifications` (single-flight, idempoten, kedaluwarsa
      7 hari), port Beranda, DI.
      Verifikasi: uji pemroses dengan fake (tiap tingkat, ragu, ganda, cloud
      galat, crash sebelum ack, Batalkan memulihkan saldo).
      Memenuhi FR-NOT-001.
      Progres (1 Okt 2026, belum dicentang): `MethodChannelNotificationCaptureGateway`
      + `UnsupportedNotificationCaptureGateway`, `NotificationCaptureStoreImpl`,
      `ProcessCapturedNotifications` + `CaptureInboxActions` +
      `CaptureInboxChanges`, `NotificationCaptureModule` di `RootModule`.
      11 uji pemroses (repository asli di penyimpanan memori) lulus. Kartu
      Beranda lewat slot `HomePage.notice` yang diisi shell, bukan port
      `HomeBloc` (lebih kecil; uji Beranda tidak berubah).
- [ ] **T-11.20** Tampilan: setelan (pengungkapan, akses, mode, tingkat,
      sumber, pola), pembuat pola dari contoh, kotak masuk (Perlu ditinjau /
      Tercatat otomatis), kartu Beranda, baris Akun, host pemroses di shell,
      i18n id/en, layar sampel debug.
      Verifikasi: uji widget setelan, kotak masuk, pembuat pola.
      Memenuhi FR-NOT-001.
      Progres (1 Okt 2026, belum dicentang): rute `notificationSettings` dan
      `captureInbox`, `NotificationCaptureScope`, bloc setelan dan kotak masuk,
      halaman setelan/sumber/pola/kotak masuk, pemilih aplikasi, kartu
      Beranda, `NotificationCaptureHost` di shell, entri Akun (Android),
      `RecordState.saveCount` (CATAT melaporkan "tersimpan"), i18n id/en.
      6 uji widget + 1 uji bloc lulus. Temuan emulator: kartu pilihan
      terpilih gelap (warna transparan di atas bayangan) — diperbaiki dengan
      warna buram, belum dilihat ulang.
      Review UX 1 Okt 2026 (ADR-032 §3.9), dilihat di Samsung: setelan
      diurut ulang (aktif + izin → Kotak masuk → Aplikasi → satu kartu "Saat
      transaksi tertangkap"); 5 kartu radio jadi 3 sakelar (Catat otomatis,
      Walau kategori belum terbaca, Kabari lewat notifikasi); baris aplikasi
      ringkas (dompet, peringatan filter/dompet kosong); halaman aplikasi
      memakai `WalletSelectField`, filter dan pola terlipat; pembuat pola
      pakai penanda + ketuk, jenis Keluar/Masuk/Transfer; kotak masuk dengan
      **ikon notifikasi** (ikon besar atau ikon aplikasi, juga jadi ikon
      besar pengingat), nominal berwarna, "Buat pola" di menu ⋮; kosakata
      "cek" menggantikan "tinjau"; judul notifikasi tidak lagi masuk catatan.
      Ikon di riwayat (ADR-032 §3.10, 1 Okt 2026): `Transaction.sourceIconId`
      + penyimpanan ikon `source_icon/<id>` (dedup isi); `TransactionIcon`
      (kategori dalam kotak berwarna jenis + lencana notifikasi) di Riwayat,
      Beranda, rincian dompet/anggaran/transaksi, dan kotak masuk. Belum
      dilihat di perangkat.
- [ ] **T-11.21** Privasi dan verifikasi perangkat: Keamanan Data (isi
      notifikasi, bersama T-11.6), kebijakan privasi (B-20), uji di HP pemilik
      (tingkat 1/2/3, aplikasi tertutup, OTP, pola pengguna).
      Memenuhi FR-NOT-001.
      *Progres 1 Okt 2026 (Samsung SM-M156B, Android 16, build profile, sumber
      `adb shell`):* lolos — tingkat 2 mencatat otomatis Rp25.000 (bukan saldo)
      dan Rp48.500, pemasukan tanpa kategori ke kotak masuk dan CATAT terisi
      benar, OTP dan promo tidak tertangkap, activity tertutup → pengingat
      generik → ketuk → diproses. Ditemukan dan diperbaiki: host dan kartu
      Beranda mencari modul di `HomeScope` yang terisolasi sehingga tak pernah
      memproses; kini container akar diberikan shell. Belum: tingkat 1/3,
      pola pengguna di perangkat, panggilan Gemini dari aplikasi, catatan
      draf masih diawali judul notifikasi bila judul ≠ nama aplikasi.

## Fase 12: Rapikan batas arsitektur

Hasil review arsitektur 30 Sep 2026 (temuan A1–A11) dan keputusannya di
[ADR-030](../02-architecture/adr/0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md).
Satu commit per tugas, urutan mengikat: sinkronisasi (T-12.4) sebelum
navigasi (T-12.5), karena halaman rincian baru bisa dibuka lewat rute
setelah tidak lagi meminjam bloc fitur lain. Tanpa perubahan perilaku yang
terlihat pengguna; setiap tugas ditutup dengan `flutter analyze` bersih dan
seluruh uji lulus.

- [x] **T-12.1** Tahap 0: keputusan dan ADR-030 (30 Sep 2026, review
      arsitektur). Pemilik memutuskan A1 memakai kunci rute (ADR-0004
      ditegakkan ulang) dan A7 mengizinkan `shared/<module>/presentation/`.
      Hasil: ADR-030; catatan revisi ADR-0004 dan ADR-0009; Fase 12 di
      ROADMAP; indeks ADR di `docs/README.md`.
      Di luar PRD: kualitas arsitektur.
- [x] **T-12.2** Tahap 1: pindah berkas tanpa ubah perilaku (ADR-030 §3.1,
      §3.5, §3.7). Akar komposisi (`RootModule`, `di.dart`, `SaldoughApp`,
      `AppShellPage`) ke `lib/app/`; `BudgetItemCatalog` ke
      `shared/budget_catalog/`; `budget_form_fields.dart` ke
      `core/presentation/widgets/` sebagai `AppForm*`; `wallet_select_field`
      ke `shared/wallet/presentation/`; parser ucapan ke
      `features/record/domain/capture/`; `Icons.` di `app.dart` dan warna
      harfiah `spotlight_overlay.dart` lewat token.
      ⚠ Hanya jalur impor dan nama kelas yang berubah; kalau satu uji lama
      gagal, itu tanda ada perilaku yang ikut berubah.
      Verifikasi: `flutter analyze`, seluruh uji lulus, `core/` tidak lagi
      mengimpor `shared/`/`features/`.
      Di luar PRD: kualitas arsitektur.
      Hasil (30 Sep 2026): 15 berkas dipindah, impor 53 berkas ditulis
      ulang. Barrel kedua `wallet_presentation.dart` dan
      `category_presentation.dart` (presentasi tidak lagi diekspor barrel
      utama, ADR-030 §3.2). Onboarding tidak lagi mengenal shell: ia
      mengirim `OnboardingOutcome`, akar komposisi menerjemahkannya ke
      `ShellStartAction`. `IconKey.debugMenu` (isian Material) dan slot warna
      `scrim`. Impor `core/` → `shared`/`features`: 39 → 0; impor
      antarfitur 40 → 29. `flutter analyze` bersih, 836 uji lulus; isi uji
      tidak berubah selain jalur impor dan `OnboardingOutcome`.
      `transaction_date_group_card` pindah di T-12.3, `account_avatar` di
      T-12.5.
- [x] **T-12.3** Tahap 2: logika query transaksi jadi fungsi murni (ADR-030
      §3.6). Penyaring jenis/dompet/kategori, pencarian, pengelompokan per
      tanggal, dan jumlah bersih dari `TransactionBloc` ke
      `shared/transaction/domain/`; `transaction_date_group_card` ke
      `shared/transaction/presentation/`.
      ⚠ Transfer tidak pernah dihitung sebagai pemasukan maupun pengeluaran
      (aturan 7).
      Verifikasi: uji unit fungsi murni dengan angka nyata; uji bloc lama
      tetap lulus tanpa diubah.
      Memenuhi FR-TXN-004.
      Hasil (30 Sep 2026): `shared/transaction/domain/transaction_query.dart`
      (`filterTransactions`, `countTransactionsByType`,
      `distinctCategoryIds`, `groupTransactionsByDate`, `netSenOf`,
      `walletIdsOf`; nama kategori disuntikkan supaya tetap Dart murni);
      `TransactionTypeFilter` dan `TransactionDateGroup` ikut pindah dari
      state. `RecordTransaction` memakai `walletIdsOf` yang sama.
      `TransactionBloc` 439 → 372 baris. Kartu grup tanggal dan
      `transactionTitle`/`transactionTime` ke
      `shared/transaction/presentation/` (barrel
      `transaction_presentation.dart`). 9 uji baru (gaji 2.615.438, belanja
      3.068.500, transfer 1.000.000); uji bloc lama lulus tanpa diubah; 845
      uji lulus, `flutter analyze` bersih. Impor antarfitur 29 → 26.
- [x] **T-12.4** Tahap 3: sinyal buku besar `LedgerChanges` (ADR-030 §3.4).
      Dipancarkan `RecordTransaction` dan `WalletBloc` sesudah unit kerja
      `Right`; `TransactionBloc`, `WalletBloc`, `BudgetBloc`, `HomeBloc`
      berlangganan; shell berhenti memuat ulang bloc lain sesudah CATAT.
      ⚠ Jangan memancar dari repository (saldo menyusul transaksi, ADR-012);
      batalkan langganan di `close`; stub uji bloc mencerminkan penulisan
      terakhir (AGENT_CONTEXT jebakan 3).
      Verifikasi: uji `RecordTransaction` (memancar hanya saat `Right`), uji
      bloc pelanggan (memuat ulang tanpa kerangka), uji shell.
      Di luar PRD: kualitas arsitektur.
      Hasil (30 Sep 2026): `shared/transaction/domain/ledger_changes.dart`
      (sinyal membawa sumbernya; `from(self)` untuk pelanggan).
      `RecordTransaction` memancar sesudah transaksi dan saldo tertulis;
      `WalletBloc` sesudah tulis dompet. Empat bloc berlangganan, batal di
      `close`. Pemuatan ulang manual dihapus dari shell sesudah CATAT dan
      dari rincian anggaran/dompet/transaksi dan keadaan kosong Riwayat;
      penyegaran saat tab Anggaran/Beranda/Dompet dipilih tetap. Temuan saat
      uji: bloc penulis yang menerima sinyalnya sendiri memuat ulang
      bersamaan dan menimpa state pesan berhasil (`UiState` membandingkan
      `effect`), maka sinyal membawa `source`. Uji baru: urutan (saldo sudah
      tertulis saat sinyal tiba), tidak memancar saat gagal, pelanggan
      memuat ulang tanpa kerangka, penulis memancar sekali dengan dirinya
      sebagai sumber, dan uji shell ujung ke ujung (dicek mutasi: gagal bila
      langganan `TransactionBloc` diputus). 850 uji lulus, `flutter analyze`
      bersih.
- [x] **T-12.5** Tahap 4: kunci dan modul rute per fitur (ADR-030 §3.3,
      ADR-0004). Semua layar penuh jadi `RouteNode` dengan scope sendiri;
      CATAT dan sunting transaksi jadi rute lembar (`slideFromBottom`);
      helper `context.pushRoute`; nol `MaterialPageRoute` di `features/`;
      `account_avatar` ke `shared/auth/presentation/`; halaman besar yang
      tersentuh dipecah (A9).
      ⚠ Tampilan dan alur tidak boleh berubah: lembar tetap lembar, snackbar
      hasil simpan tetap tampil sesudah lembar tertutup.
      Verifikasi: uji widget navigasi (rincian dompet/anggaran/transaksi,
      CATAT dari rincian), seluruh uji lulus, cek manual di emulator.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): `context.pushRoute` bertipe
      (`core/foundation/navigation/route_navigation.dart`); kunci dan modul
      rute untuk account, budget, freelance, record, transaction, wallet
      (9 rute) di `RootModule.featureModules`. CATAT, sunting transaksi,
      dan suara jadi rute alur transparan (`RouteTransition.none`) yang
      memegang `RecordScope`, jadi shell tidak lagi memasang `RecordBloc`.
      Rincian dompet/anggaran/transaksi memasang scope sendiri; rincian
      dompet memakai `WalletActivityBloc` baru (bukan `TransactionBloc` tab
      Riwayat), "Lihat semua transaksi" jadi rute `transaction.history`
      yang penyaringnya tidak lagi terbawa ke tab Riwayat. Rute yang menulis
      lalu menutup diri menunggu hasilnya; "Urungkan" lewat
      `RecordTransaction` langsung (`TransactionRestored` dihapus). Tombol
      akun ke `shared/auth/presentation/`. Tiga halaman rincian dipecah ke
      berkas `part` (`*_detail_sections.dart`, halaman utama 146–175 baris).
      Layar anak satu fitur (template, proyek freelance, kategori) tetap
      `Navigator.push` (ADR-030 §3.3 butir 1 direvisi). Impor antarfitur
      26 → 13: 11 ke `*_route_keys.dart` dan 2 adapter port Beranda. Uji
      baru: `pushRoute` (halaman, lembar bertema pemanggil, alur transparan,
      kunci tak terdaftar), `WalletActivityBloc`, dan `GoRouter` aplikasi
      dengan seluruh rute bernama. Uji asap emulator Pixel 7a API 35:
      onboarding → buat dompet (aksi awal shell), CATAT pengeluaran →
      snackbar dan saldo tab Dompet segar, rincian dompet → riwayat
      tersaring → rincian transaksi → hapus → Urungkan, Akun dari Beranda,
      CATAT → Masuk → Freelance; tanpa galat di log. Perubahan kecil yang
      terlihat: rincian yang dibuka menampilkan kerangka sesaat karena
      memuat datanya sendiri.
- [x] **T-12.6** Tahap 5: penutup. Fake tulis tangan di uji → `mocktail`
      (ADR-0010); `test/architecture/import_boundaries_test.dart` (ADR-030
      §3.8); sapuan ARCHITECTURE_OVERVIEW, AGENT_CONTEXT, dan CLAUDE.md.
      Verifikasi: uji batas impor lulus dan gagal bila satu impor terlarang
      ditambahkan.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): `test/architecture/import_boundaries_test.dart`
      (8 aturan: impor package saja; `core/` tanpa app/shared/features;
      shared/features tanpa app; shared tanpa features; antarfitur hanya
      kunci rute atau adapter port; shared lewat barrel; domain tanpa
      Flutter/infra/data/presentation/barrel presentasi; presentation tanpa
      data). Uji ini menemukan 6 impor jalur dalam antarmodul `shared/`
      (dibetulkan ke barrel), dan terbukti gagal saat impor Beranda →
      halaman rincian dompet ditambahkan. Fake tanpa keadaan jadi
      `mocktail` + penyetel stub di `helpers/mocks.dart`
      (`stubBudgetItemCatalog`, `stubBudgetOverviewSource`,
      `stubFreelanceOverviewSource`, `failingWalletRepository`), begitu juga
      repository mata uang onboarding, interpreter cloud penyusun draf, dan
      repository freelance yang gagal sesaat. Fake berperilaku
      (`FakeAuthRepository`, `_FakeTranscriber`, `_FakeSpeech`) tetap, dicatat
      sebagai pengecualian di ADR-0010. ARCHITECTURE_OVERVIEW (struktur,
      navigasi, sinkronisasi, aturan), AGENT_CONTEXT, dan CLAUDE.md disapu.
      867 uji lulus, `flutter analyze` bersih.

## Fase 13: Pecah fitur `record`

Audit 1 Okt 2026: `features/record` berisi empat tanggung jawab (CATAT, mesin
tafsir, suara, notifikasi; 11.249 baris) yang sudah terpisah secara alami di
peta impor tetapi tidak dijaga uji batas. Keputusannya di
[ADR-033](../02-architecture/adr/0033-pecah-fitur-record.md); perbaikan
penangkap notifikasi di
[ADR-032 §10](../02-architecture/adr/0032-catat-dari-notifikasi.md).
Satu commit per tugas. Setiap tugas ditutup dengan `flutter analyze` bersih
dan seluruh uji lulus.

- [x] **T-13.1** Perbaikan penangkap notifikasi (audit 1 Okt 2026, ADR-032
      §10): dedup native per kunci + waktu + isi dalam 1 jam (N1); ack hanya
      tangkapan yang simpanannya berhasil (N2); penanganan native di thread
      latar, ikon sebagai berkas (N3); Gemini menerima teks tersamar (N4);
      `capturedAt` di log otomatis, uji kesamaan kata OTP Kotlin/Dart, hapus
      `instance` plugin.
      ⚠ Mengubah kode native; uji Dart tidak menjangkau Kotlin, jadi butuh
      build Android dan tangkapan nyata di emulator atau HP.
      Verifikasi: uji pemroses (simpan gagal → tidak di-ack; teks cloud
      tersamar), uji kesamaan OTP, `flutter build apk --debug`.
      Memenuhi FR-NOT-001.
      Hasil (1 Okt 2026): dedup native kini hanya membuang posting ulang
      (kunci + `when` + isi dalam 1 jam, atau kunci + isi dalam 2 menit);
      penanganan di executor latar; ikon berkas PNG per tangkapan, dikirim
      sebagai bytes dan dihapus saat di-ack; `_save` mengembalikan berhasil
      atau tidak (kotak masuk dan log dulu, id terproses terakhir) dan hanya
      tangkapan tersimpan yang di-ack; `CaptureDraftComposer.compose(cloudText:)`
      untuk teks tersamar; `AutoRecordedEntry.capturedAt`; uji kesamaan kata
      OTP membaca berkas Kotlin. Uji baru: simpan kotak masuk gagal → tidak
      di-ack lalu pulih, cloud menerima teks tanpa saldo/rekening, kesamaan
      OTP. 911 uji lulus. Emulator (Pixel 7a API 35, sumber `com.android.shell`
      lewat `cmd notification post`): dua "Pembayaran Rp5.000 ke PARKIR
      berhasil" dengan tag berbeda keduanya tertampung, posting ulang tag
      yang sama dibuang, ikon tersimpan sebagai berkas, tanpa galat. Jalur
      Dart di perangkat nyata ikut verifikasi T-11.21.
- [x] **T-13.2** Mesin tafsir ke `shared/capture/` (ADR-033 §3.1), barrel
      `capture.dart`.
      ⚠ Hanya jalur impor yang berubah.
      Verifikasi: uji batas impor, seluruh uji lulus tanpa perubahan isi.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): 14 berkas `lib/` (domain, paket bahasa, interpreter
      aturan dan Firebase AI) dan 6 berkas uji ke `shared/capture/`; impor
      dari luar modul lewat barrel. Mesin tafsir hanya bergantung pada
      `shared/category`, `shared/wallet`, dan `core/currency`. 911 uji lulus,
      isi uji tidak berubah.
- [x] **T-13.3** Fitur `notification_capture` (ADR-033 §3.3): pindah
      domain/data/presentation/DI, kunci rute
      `NotificationCaptureRouteKeys.settings`/`.inbox`, pemakai di Akun dan
      shell.
      ⚠ Nama kunci penyimpanan tidak berubah.
      Verifikasi: uji batas impor, seluruh uji lulus.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): 32 berkas `lib/` dan 7 berkas uji pindah langsung
      ke susunan akhir ADR-033 §3.3 (`domain/entities|services|repositories|
      usecases`, `data/`, `presentation/bloc|pages|widgets|host|navigation`,
      `di/`), termasuk `notification_rule_interpreter` yang tadinya di luar
      folder notifikasi. `NotificationCaptureRouteModule` baru menggantikan
      dua rute di `RecordRouteModule`; Akun, banner, host, dan uji memakai
      `NotificationCaptureRouteKeys`. Fitur ini hanya mengimpor kunci rute
      `record` dan `transaction`. `record` kini 4.055 baris, fitur notifikasi
      4.863. 911 uji lulus.
- [x] **T-13.4** Fitur `voice_capture` (ADR-033 §3.2): kunci
      `VoiceCaptureRouteKeys.capture`, scope sendiri, lalu
      `RecordBloc` tanpa `voiceCaptureFactory`/`speechLanguagePrompt` (R1).
      Verifikasi: uji suara dan shell lulus; alur suara → CATAT di emulator.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): transkriptor, bloc, dua lembar, dan alur pindah ke
      `features/voice_capture/` (8 berkas `lib/`, 4 berkas uji);
      `VoiceCaptureScope` memasang transkriptor, penyusun draf, dan bloc
      rekam (*factory*), lalu membuka CATAT lewat `RecordRouteKeys.sheet`.
      `RecordScope` tidak lagi mendaftarkan transkriptor/penyusun draf, dan
      `RecordBloc` tanpa `voiceCaptureFactory`/`speechLanguagePrompt`.
      `FlowRunner` di `core/foundation/navigation/` menggantikan `_Runner`
      privat. Dompet gagal dibaca → CATAT kosong yang menampilkan galatnya
      (dulu galat `RecordBloc`). `record` kini 2.945 baris, `voice_capture` 1.145. 911 uji lulus.
      Emulator: tombol mikrofon → lembar rekam → *Ketik saja* → CATAT →
      tutup → Beranda, lalu CATAT biasa; tanpa galat di log aplikasi.
- [x] **T-13.5** Rapikan fitur notifikasi (ADR-033 §2 R2/R3): domain per
      subfolder, `CaptureInboxActions` ke berkasnya sendiri, satu tempat untuk
      "pola aktif" dan "dompet aktif".
      Verifikasi: seluruh uji lulus.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): subfolder domain sudah terbentuk di T-13.3.
      `CaptureInboxActions` di `usecases/capture_inbox_actions.dart` (134
      baris); `process_captured_notifications.dart` 405 → 286 baris.
      `loadActivePatterns`/`loadActiveWallets` di
      `services/active_capture_inputs.dart` dipakai pemroses dan tafsir
      ulang. 911 uji lulus.
- [x] **T-13.6** Penutup: ARCHITECTURE_OVERVIEW, AGENT_CONTEXT, CLAUDE.md,
      rujukan kode di ADR-027/029/032; baseline baris dan uji.
      Di luar PRD: kualitas arsitektur.
      Hasil (1 Okt 2026): ARCHITECTURE_OVERVIEW (pohon `lib/`, letak mesin
      tafsir, alur transparan + `FlowRunner`, shell), glosarium
      (`VoiceCaptureRouteKeys.capture`), rujukan kode ADR-027/029/032, dan
      CLAUDE.md (status Fase 13, batas fitur Catat Cerdas, tag
      `0.3.0+4-patch-3`). AGENT_CONTEXT tidak menyebut letak berkas `record`,
      jadi tidak berubah. Riwayat lama (hasil tugas Fase 11/12, ADR-030 §2,
      VOICE_INPUT_RESEARCH) sengaja dibiarkan sebagai catatan sejarah.
      Baseline: 39.746 baris Dart di `lib/` tanpa `.g.dart`, 95 berkas uji,
      911 uji lulus, `flutter analyze` tanpa error/peringatan.

## Fase 14: Bahasa visual baru

Pemilik menilai tampilan berantakan, sulit dibaca, dan tata letaknya jelek
(3 Okt 2026). Desain baru disetujui lewat sampel bertahap:
[ADR-034](../02-architecture/adr/0034-bahasa-visual-buku-catatan-piksel.md).
**Setiap tugas fase ini memakai skill `tanukonomy-ui`**: baca
[design system](https://claude.ai/artifact/HHq7YfEY5Wtc1JXtBhzBQS) (README,
`flutter.md`, komponen terkait) dan layar padanannya di
[prototipe](https://claude.ai/artifact/L4176HPgR9gCXACe3gyRbZ) sebelum
menulis widget; tanpa alat Artifact, pakai salinan di `docs/03-design/`.
Perilaku, rute, dan bloc tidak berubah kecuali disebut. Satu commit per
tugas, ditutup `flutter analyze` bersih dan seluruh uji lulus.

- [ ] **T-14.1** Token dan tema (3 Okt 2026, ADR-034 §3.3).
      `AppColors` dengan nama dan nilai token design system (terang dan
      gelap, termasuk `cat-*`, `brand-deep`), `ColorScheme`, `TextTheme`
      Plus Jakarta Sans, `AppNumberStyles` (angka tabular), `AppSpacing`/
      `AppRadius`/`AppSize`/`pixel-step`. Hapus Space Grotesk dan Space Mono
      dari aset dan `pubspec.yaml`. `PixelTheme` tetap tema global
      (ADR-031), isinya diganti.
      ⚠ Uji kontras `test/core/theme/app_colors_extension_test.dart` ikut
      diganti ke pasangan baru; jangan longgarkan ambangnya.
      Verifikasi: uji kontras 4,5:1 semua pasangan teks di kedua tema, uji
      tema memakai Plus Jakarta Sans, `flutter analyze` dan seluruh uji.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.2** Ikon (ADR-034 §3.3). Tambah `material_symbols_icons`;
      `AppIconTile` dua varian (ikon piksel 32px di tile `surface-2`,
      Material Symbols di tile `cat-*`); pemetaan kategori dan dompet persis
      README design system bagian Ikon; `IconKey` disesuaikan.
      ⚠ Ikon piksel hanya 32px atau 64px dengan `FilterQuality.none`;
      kategori tanpa ikon piksel memakai cadangan (B-22), jangan menggambar.
      Verifikasi: uji widget pemetaan kategori/dompet ke ikon.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.3** Komponen dasar (design system bagian Komponen).
      `PixelCornerBorder`, `AppCard`, `AppButton` (primary, secondary, text,
      danger, kecil), `AppChip`, `AppSegmentedControl`, `AppBadge`,
      `AppProgressBar` (kotak 6px + penanda waktu), `AppListRow`,
      `AppSectionHeader`, `AppBanner`, tema snackbar, dialog, sheet,
      skeleton, `AppHeroCard`, `AppMoneyText` sesuai aturan tanda dan warna.
      Hapus `AppHardCard`, `kind_surfaces`, animasi piksel antarmuka
      (pemetaan di `flutter.md`).
      Verifikasi: uji widget tiap komponen (varian, keadaan nonaktif,
      semantik), uji golden opsional.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.4** Navigasi bawah: 4 tab + tombol Catat di tengah (kotak
      bersudut piksel, bayangan piksel); tekan lama membuka Catat pakai
      suara; FAB suara dihapus, mikrofon pindah ke bar atas sheet Catat.
      ⚠ Tur spotlight (ADR-021) menyorot FAB lama: pindahkan
      `SpotlightTarget` ke tombol baru.
      Verifikasi: uji widget navigasi (pindah tab, ketuk dan tekan lama
      Catat), uji tur.
      Memenuhi FR-REC-001.
- [ ] **T-14.5** Sheet Catat sesuai prototipe `Catat.dc.html`: kontrol
      segmen jenis, keypad, pemilih kategori petak ikon, baris Dompet/
      Tanggal/Catatan/Anggaran, "Saldo jadi …" di baris dompet, tombol
      Simpan menyebut jenisnya. Banner "Aturan Kas" dan ringkasan ganda
      dihapus.
      ⚠ Jangan mengubah `RecordBloc` selain yang dibutuhkan tampilan;
      validasi (dompet sama, periode anggaran) tetap.
      Verifikasi: uji widget alur pengeluaran, pemasukan, transfer; uji
      bloc lama tetap lulus.
      Memenuhi FR-REC-001, FR-REC-002.
- [ ] **T-14.6** Beranda sesuai `Main.dc.html`: kartu saldo terakota
      dengan tanuki, banner kotak masuk, kartu bulan berjalan (pemasukan,
      pengeluaran, selisih), kartu anggaran dengan penanda waktu, transaksi
      terbaru, kartu Freelance sebagai pintu masuk Freelance, tombol
      sembunyikan nominal (usulan baru yang disetujui bersama desain).
      ⚠ Sembunyikan nominal perlu setelan tersimpan (Akun) dan berlaku di
      semua nominal; tanyakan pemilik bila cakupannya ragu.
      Verifikasi: uji widget isi dan keadaan tersembunyi.
      Di luar PRD: sembunyikan nominal dan pintu Freelance (ADR-034 §4).
- [ ] **T-14.7** Riwayat sesuai `Riwayat.dc.html`: pemilih bulan,
      ringkasan, chip jenis, banner kotak masuk, grup per hari dengan
      selisih harian, baris dengan ikon piksel.
      Verifikasi: uji widget penyaring dan pengelompokan.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.8** Anggaran dan rincian anggaran sesuai `Anggaran.dc.html`
      dan `RincianAnggaran.dc.html`: kontrol segmen status, sisa total,
      kartu dengan status Aman/Hampir habis/Lewat, daftar pos dengan bar
      tipis, sheet tindakan pos, tombol Catat pengeluaran menempel di bawah.
      Verifikasi: uji widget status bar dan sheet pos.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.9** Dompet sesuai `Dompet.dc.html`: total, bar sebaran saldo
      per dompet (usulan baru), daftar dengan ikon dompet piksel dan persen,
      dompet nonaktif.
      Verifikasi: uji widget sebaran (persen dibulatkan, jumlah 100).
      Di luar PRD: bar sebaran (ADR-034 §4).
- [ ] **T-14.10** Halaman turunan: Freelance, Kotak masuk notifikasi,
      Catat pakai suara, Akun, formulir dompet/anggaran/pos/proyek, rincian
      transaksi dan dompet, kategori, template anggaran — semua memakai
      komponen T-14.3. Layar tanpa padanan di prototipe disusun dari
      komponen yang ada dan dilaporkan.
      Verifikasi: uji widget yang ada tetap lulus setelah disesuaikan.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.11** Keadaan kosong, memuat, dan galat di semua layar
      (komponen EmptyState, Skeleton, Banner); Beranda pertama kali
      sesuai `BerandaKosong.dc.html` (daftar tiga langkah).
      Verifikasi: uji widget keadaan per layar.
      Di luar PRD: perombakan tampilan (ADR-034).
- [ ] **T-14.12** Sapuan teks i18n id/en mengikuti glosarium `writing.md`
      (dompet, transaksi, transfer, selisih; hapus kas, log, mutasi, netto,
      inventaris, label langkah "Catat // Transaksi", kapital semua), lalu
      render ulang tangkapan situs (B-4) dan perbarui tur.
      ⚠ Kunci i18n tetap; yang berubah teksnya. `slang` dijalankan ulang.
      Verifikasi: uji i18n (kunci lengkap id/en), pencarian kata terlarang
      di `assets/i18n/` kosong.
      Di luar PRD: perombakan tampilan (ADR-034).
## Fase 15: Rencana dan rutin (R1)

Permintaan pemilik 2 Okt 2026: transaksi rutin, uang nganggur, dan perkiraan
arus kas, dengan tab Anggaran menjadi **Rencana**. Keputusannya di
[ADR-035](../02-architecture/adr/0035-transaksi-rutin-rencana-dan-perkiraan.md) (Accepted 2 Okt 2026);
perilaku dan rumus di [RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md); tata letak di
[PLAN_TAB_LAYOUT.md](../01-product/features/PLAN_TAB_LAYOUT.md). R1 dibagi dua rilis yang masing-masing bisa
dirilis sendiri: **R1a (rutin)** T-15.1–15.9 dan **R1b (Bulan ini)**
T-15.10–15.14. R2 dan R3 ada di antrean (B-27, B-28). Satu commit per tugas;
setiap tugas ditutup dengan `flutter analyze` bersih dan seluruh uji lulus.

### R1a: rutin

- [x] **T-15.1** Domain `RecurringRule` di `shared/recurring/`: entitas,
      jadwal (mingguan/bulanan/tahunan, selang, patokan), berakhir (tidak
      pernah/tanggal/N kali), `occurrencesOf`, repository `recurring` / `all`
      (ADR-035 §3.1).
      ⚠ Hari patokan disimpan terpisah: patokan 31 → 28 Feb → 31 Mar, jangan
      bergeser permanen. Penjepitan sama dengan `BudgetPeriod.endFrom`.
      Verifikasi: uji unit kasus wajib RECURRING_AND_FORECAST §7.7 (patokan 31,
      berakhir setelah 12 kali), uji repository, uji batas impor.
      Memenuhi FR-RUT-001, FR-RUT-005.
- [x] **T-15.2** Tautan kemunculan: `Transaction.recurrence`
      (`ruleId`, `occurrenceDate`, `linkedBy`) di ketiga jenis transaksi dan
      modelnya; status kemunculan turunan (tercatat/dilewati/menunggu/
      terlewat); invarian 14–15 (ADR-035 §3.2).
      ⚠ Field opsional, jadi data lama harus tetap terbaca. Hapus transaksi →
      kemunculan kembali menunggu.
      Verifikasi: uji serialisasi tiga jenis dengan dan tanpa `recurrence`, uji
      status turunan, uji invarian 15 (pasangan unik).
      Memenuhi FR-RUT-002.
- [x] **T-15.3** CATAT mode jadwal: baris **Ulangi** (tertutup), Atur lebih
      lanjut (berakhir, nominal kira-kira, cara bayar), tombol "Catat &
      Jadwalkan"/"Simpan Jadwal"; **Jadikan Rutin** di rincian transaksi
      (transaksi asal = kemunculan pertama); chip pembuka lokal.
      ⚠ Aturan 8: tidak ada formulir rutin terpisah. Tanggal masa depan tidak
      boleh membuat transaksi.
      Verifikasi: uji bloc/widget CATAT (tanggal lampau → transaksi + rutin;
      masa depan → rutin saja), uji Jadikan Rutin tidak menggandakan.
      Memenuhi FR-RUT-001.
      Selesai 2 Okt 2026: chip pembuka (`features/recurring`, tanggal bawaan
      = kemunculan berikutnya yang belum lewat) dipasang di keadaan kosong
      segmen Rutin pada T-15.5. Belum: chip mengisi dari transaksi riwayat
      yang mirip (J1 langkah 2), menunggu pencocokan T-15.7.
- [x] **T-15.4** Tab Rencana: `AppSubTabs` (`core/presentation/widgets/`),
      label `appShell.planTabLabel` (Rencana/Plan), `PlanPage` dengan segmen
      Anggaran (`BudgetListPage` tanpa app bar; penyaring status jadi chip,
      KT-L2) dan Rutin; shell bisa dibuka ke tab + segmen; tur `planTabs`.
      ⚠ Tanpa geser antarsegmen. Kunci i18n `budgetTabLabel` tetap dipakai
      untuk label segmen (kebiasaan T-8.8). Uji label en di 360dp, skala teks
      1,3.
      Verifikasi: uji `app_shell_page_test.dart` dan uji tur diperbarui, uji
      widget sub-tab 360dp, uji batas impor.
      Memenuhi FR-PLN-001.
      Selesai 2 Okt 2026: `PlanPage` menerima isi segmen dari shell (fitur
      `plan` tidak mengimpor `budget`/`recurring`); langkah tur `planTabs`
      jadi langkah pertama tur Anggaran supaya dua tur tidak berebut;
      penyaring status jadi `AppChoiceChip`. Membuka tab + segmen dari luar
      shell (notifikasi) menyusul di T-15.8.
- [x] **T-15.5** Segmen Rutin dan rincian rutin: kartu utama "Sisa rutin
      keluar", chip jenis, kelompok Menunggu/Bulan ini/Nanti/Dijeda/Selesai,
      baris dengan kolom tanggal; rincian (riwayat tercatat, berikutnya +
      Lewati, Ubah/Jeda/Akhiri/Hapus); total langganan (W5); kenaikan harga
      dari nominal tercatat (W3).
      ⚠ Aturan PLAN_TAB_LAYOUT §4.9: angka dan label pendek saja.
      Verifikasi: uji widget per kelompok dan keadaan kosong; uji ambang W3
      (≥5% dan ≥Rp5.000).
      Memenuhi FR-PLN-001, FR-RUT-005.
      Selesai 2 Okt 2026: hitungan di `shared/recurring/domain/recurring_overview.dart`
      (contoh §6.1 teruji: 3.979.000 dari 5.879.000). "Langganan" W5 =
      kategori bawaan Hiburan (tidak ada kategori Langganan). Ubah rutin
      lewat CATAT (`RecordSheetInput.editRule`): jadwal lama dipertahankan
      bila tanggalnya masih kemunculan jadwal itu. Tombol aksi kartu Menunggu
      menyusul di T-15.6.
- [x] **T-15.6** Kartu **Menunggu dicatat** di Beranda dan segmen Rutin: catat
      satu ketuk lewat `RecordTransaction` + Batalkan, ubah dulu (CATAT terisi),
      lewati + Batalkan, catat semua; tanggal bawaan = tanggal kemunculan;
      penjagaan E4 (mirip transaksi yang sudah ada), E5 (nominal tidak wajar
      untuk rutin), E11 (tanggal jauh dari kemunculan).
      ⚠ Pengecualian kedua aturan 8 (ADR-035 §3.3) hanya untuk nominal tetap;
      nominal kira-kira selalu membuka CATAT.
      Verifikasi: uji bloc (satu ketuk → satu transaksi bertautan; batalkan →
      dihapus; lewati → `skippedDates`), uji widget Beranda.
      Memenuhi FR-RUT-002.
      Selesai 2 Okt 2026: kartu di Beranda lewat slot `pendingRecurring`
      dari shell (fitur `home` tidak mengimpor `recurring`). E4 memakai
      `matchCandidates` (dialog Tautkan / Catat baru); E5 dan E11 berupa
      pemberitahuan ringan di CATAT "Ubah dulu", tidak menahan simpan.
      Catat semua melewati rutin yang punya transaksi mirip.
- [x] **T-15.7** Pencocokan dengan catat dari notifikasi: `matchOccurrences`
      (ADR-035 §3.4); tautan otomatis untuk kecocokan persis satu kandidat,
      log `recurring` / `match_log` 7 hari + Lepaskan; label "Cocok dengan
      rutin" dan isian dari rutin pada draf kotak masuk; saran "Sudah
      tercatat? Tautkan".
      ⚠ Penangkap notifikasi hanya mengimpor `shared/recurring`, tidak fitur
      `recurring`. Dua kandidat, nominal beda, dompet beda → ditanyakan.
      Verifikasi: uji unit pencocokan (kasus §7.7: persis, ditolak, dua
      kandidat), uji pemroses notifikasi menautkan.
      Memenuhi FR-RUT-003.
      Selesai 2 Okt 2026: tautan otomatis hanya untuk rutin bernominal tetap,
      nominal persis, satu kandidat, dan tanpa transaksi lain yang juga
      cocok (kasus "dua kandidat"); rutin kira-kira ±10% hanya disarankan.
      Daftar "Tercocok dengan rutin" + Lepaskan ada di kotak masuk
      notifikasi. "Sudah tercatat? Tautkan" untuk jalur lain = dialog E4
      di kartu Menunggu (T-15.6).
- [x] **T-15.8** Notifikasi lokal (ADR-035 §3.8): dependensi
      `flutter_local_notifications` + `timezone`; saluran `recurring_reminders`;
      jadwal disusun ulang saat aplikasi dibuka dan saat rutin berubah (35 hari
      ke depan, id dari `(ruleId, occurrenceDate)`); H−n untuk bayar sendiri
      dan ringkasan hari jatuh tempo; aksi Catat membuka aplikasi lalu catat
      satu ketuk; sakelar per rutin dan global di Akun; izin diminta saat
      pertama dinyalakan.
      ⚠ Dependensi baru: cek ulang formulir Keamanan Data (tidak ada data
      keluar perangkat). Butuh pengujian Android 13+ dan iOS di perangkat.
      Verifikasi: uji unit penyusun jadwal (tanpa ganda saat disusun ulang),
      build Android dan iOS, notifikasi nyata muncul dan aksi Catat bekerja.
      Memenuhi FR-RUT-004.
      Selesai 2 Okt 2026 (kode, uji unit, dan build APK debug): sakelar
      global di Akun › Pengingat rutin (bawaan mati, izin diminta saat
      dinyalakan), sakelar per rutin di rincian rutin. Jadwal = instan UTC
      dari jam lokal 09.00, disusun ulang saat dibuka, kembali ke depan, dan
      tiap rutin/buku besar berubah. **Belum diuji di perangkat** Android 13+
      dan iOS: masuk T-15.9.
- [ ] **T-15.9** Verifikasi milestone R1a di perangkat
      ([VERIFICATION_PLAN_FASE_15](VERIFICATION_PLAN_FASE_15.md) D1–D13): alur J1–J3, J7, J8 dokumen perilaku;
      pencocokan dengan notifikasi BRImo/BCA nyata; pengingat H−1.
      Verifikasi: temuan dicatat di tugas ini, perbaikan sebagai tugas baru.
      Memenuhi FR-RUT-001..005, FR-PLN-001.

### R1b: Bulan ini

- [x] **T-15.10** Bulan keuangan bisa diatur: preferensi `settings` /
      `financial_month_start` (1–28, bawaan 1) dengan pola
      `CurrencyPreferenceRepository`; pengaturan di Akun; fungsi rentang bulan
      keuangan.
      ⚠ Tidak mengubah arus bulan berjalan di Beranda (FR-HOME-001). Rentang
      yang tidak mulai tanggal 1 selalu ditulis ("25 Okt – 24 Nov").
      Verifikasi: uji rentang (mulai 25, mulai 1, Februari), uji repository.
      Memenuhi FR-PLN-004.
      Selesai 2 Okt 2026: `core/financial_month/` (rentang, label,
      `ActiveFinancialMonth` diisi `main.dart`), entri di Akun.
- [x] **T-15.11** `monthPlan`: uang nganggur rencana dan sisa
      (RECURRING_AND_FORECAST §7.2, §7.2a; KT-R14 transfer tidak dihitung;
      invarian 17).
      Verifikasi: uji contoh §7.2a (3.052.500 → sisa 2.995.500), uji pos
      tertaut tidak ganda, uji transfer Tabungan tidak mengurangi.
      Memenuhi FR-PLN-002.
- [x] **T-15.12** `projectCashflow`: saldo harian, akhir bulan, paling tipis
      (§7.3–7.5), per dompet dan total, di luar rencana (nyala bila riwayat ≥1
      bulan penuh, KT-R3), freelance belum dibayar sebagai "belum pasti"
      (KT-R6); invarian 16.
      ⚠ Pembagian harian: sisa pembagian di hari terakhir; semua `int` sen.
      Verifikasi: uji kasus wajib §7.7 (pembagian 100.000.001 sen, transfer
      tidak mengubah total) dan contoh §7.6 (paling tipis 561.000 pada 24 Okt,
      akhir Okt 10.921.000).
      Memenuhi FR-PLN-003.
      Selesai 2 Okt 2026: rentang R1b = bulan keuangan berjalan; bulan depan
      (Nov/Des §7.6) menunggu anggaran rutin di R2 (B-27). Pos tertaut rutin
      (`keluar_pos = max(...)`) juga R2: di R1 belum ada tautan pos.
- [x] **T-15.13** Segmen **Bulan ini** (PLAN_TAB_LAYOUT §4 dan §4.9): pemilih
      bulan, kartu Uang nganggur + lembar ⓘ, kartu Saldo dompet ≈ + grafik
      yang bisa digeser + lembar Rincian, Menunggu + 3 berikutnya, keadaan
      kosong; baris perkiraan di Beranda; tur `planUnplanned`, `planForecast`;
      awal sesi membuka Bulan ini (KT-L4).
      ⚠ Kata "saldo" hanya untuk isi dompet. Garis grafik tinta netral,
      bukan hijau/merah.
      Verifikasi: uji widget kartu (angka besar = jumlah baris), uji
      semantik grafik, uji 360dp.
      Memenuhi FR-PLN-001, FR-PLN-002, FR-PLN-003.
      Selesai 2 Okt 2026: `features/plan` (port `PlanBudgetSource` dan
      `PlanFreelanceSource`, adapter di `budget`/`freelance`); kartu Menunggu
      dan chip pembuka disisipkan shell. Pemilih bulan belum ada karena
      bulan depan R2 (FR-PLN-005); chip dompet sudah ada. Segmen Rutin dan
      Anggaran diselaraskan dengan §4.9 (kartu Sisa rutin keluar, chip tanpa
      angka, kolom tanggal, Lewati + Catat dan ketuk baris = Ubah dulu;
      chip Anggaran Aktif · Selesai · Semua, penyaring dompet bila >1).
- [ ] **T-15.14** Verifikasi milestone R1b di perangkat: angka Bulan ini cocok
      dengan perhitungan manual satu bulan nyata; bulan keuangan mulai 25.
      Memenuhi FR-PLN-001..004.
      Daftar periksa: VERIFICATION_PLAN_FASE_15 E1–E6.
- [ ] **T-15.15** Penyusunan ulang pengingat tidak menghapus notifikasi yang
      sedang tampil (temuan K1 T-15.9): `replaceAll` memakai
      `cancelAllPendingNotifications()`, bukan `cancelAll()` yang juga
      menghapus pengingat pagi itu dan pengingat catat notifikasi.
      Verifikasi: VERIFICATION_PLAN_FASE_15 D13.
      Memenuhi FR-RUT-004.

## Antrean (belum dijadwalkan)

Hal yang sudah diketahui perlu dikerjakan tapi belum masuk fase. Cara
menambah dan memindahkannya ada di
[Menambah tugas baru](#menambah-tugas-baru-improvement-atau-fitur). Kolom
**Siapa**: *pemilik* = butuh aksi di luar repo atau keputusan pemilik,
*agen* = bisa dikerjakan langsung.

| ID | Tugas | Siapa | Sumber |
|---|---|---|---|
| B-1 | Sapuan penggantian nama "Saldough" → "Tanukonomy" di README, PRD, glosarium, dan dokumen lain (prasyarat merek dagang/domain/toko sudah dipenuhi pemilik 29 Sep 2026, jadi tidak lagi tertahan). Nama kode repositori dan paket Dart `saldough` tetap. Lakukan dengan sekali sapuan, bukan sepotong-sepotong. | agen | T-8.3, ADR-022 §4 |
| B-4 | Selaraskan klaim situs `tanukonomy-web` (repo terpisah, `docs/TASKS.md` di sana) dengan aplikasi: **akun opsional dan analitik/Crashlytics sudah ada** (ADR-023, dikonfirmasi pemilik 29 Sep 2026), jadi klaim lama "tanpa akun, tanpa analitik" harus diganti; tambahkan pilihan mata uang (ADR-025). Cocokkan dengan kebijakan privasi dan formulir Keamanan Data yang sudah diisi di Play Console. Render ulang tangkapan layar (label Riwayat/History). | agen | T-8.4, T-8.6, T-8.8 |
| B-5 | Verifikasi di perangkat/emulator yang belum tercatat: keyboard desimal untuk mata uang berdesimal, layar Akun, langkah mata uang di onboarding, masuk Google/email sungguhan, hapus akun. Catat hasilnya di T-8.5/T-8.6. | pemilik | T-8.5, T-8.6 |
| B-7 | Rancang **sinkronisasi data keuangan** ke server (ADR baru, `## Fase 10`). Wajib mematuhi ADR-024 §3.3 (ganti akun = data diganti dengan peringatan, tanpa penggabungan) dan menjawab KT-2. Proyek besar: skema, aturan keamanan, resolusi konflik. | pemilik memutuskan, lalu agen | T-8.4, ADR-024 |
| B-9 | Bersihkan 11 info lint `unnecessary_unawaited` di berkas uji (mis. `test/core/currency/active_currency_rebuilder_test.dart:27`). | agen | `flutter analyze` 29 Sep 2026 |
| B-11 | Lanjutan opsional UX-6 di luar T-8.2: pencarian lintas bulan kini memindai 3 bulan per ketukan; pertimbangkan indeks teks kalau riwayat pemakai sudah panjang (NFR-PERF-002). Tunggu data nyata, jangan dikerjakan spekulatif. | agen | T-8.2 |
| B-12 | Ikon peluncur dan splash **iOS**: belum ada di repo (`flutter_launcher_icons` dan `flutter_native_splash` di `pubspec.yaml` diset `ios: false`); butuh artwork tanpa transparansi karena App Store mengabaikan alfa. Kerjakan begitu artwork diserahkan. | pemilik menyerahkan artwork | T-8.3 |
| B-13 | **Sistem kategori** (prasyarat Catat lewat Suara): entitas `Category` bawaan + bisa diubah, datar, dipisah per jenis, transfer tanpa kategori, migrasi label `categoryKey` lama, alias bawaan. Butuh ADR-0026. Desain di [VOICE_INPUT_RESEARCH.md](../01-product/features/VOICE_INPUT_RESEARCH.md) §3A dan Fase 1A. | dijadwalkan: T-11.1 | riset 30 Sep 2026 |
| B-19 | Terapkan `dismissKeyboardOnTapOutside` (T-8.12) ke kolom teks formulir lain yang bisa punya gejala fokus kembali sama: `AppFormTextField`/`AppFormMoneyField`/`AppFormQuantityField` (anggaran, freelance), formulir dompet, pencarian Riwayat, dialog nama kategori. | agen | T-8.12 |
| B-16 | Temuan kecil verifikasi M1 ([VERIFICATION_PLAN_FASE_11.md](VERIFICATION_PLAN_FASE_11.md)): F7 label skema 1 hilang bila transaksi dipindah bulan sebelum migrasi berhasil; F8 `ActiveCategories` memberi tahu di setiap baca (bangun ulang seluruh aplikasi); F9 ganti nama boleh kembar, "Catat lagi" bisa ke kategori terarsip; F10 `RecordBloc.createCategory` metode publik. | agen | verifikasi M1 |
| B-15 | **Gemma lokal** (ditunda 30 Sep 2026, ADR-027 §3.5): spike model termurah (Gemma 3 270M → 1B → Gemma 4 E2B) lewat `flutter_gemma`, mirror HF publik + NOTICE Gemma, unduhan opt-in, gating perangkat. Rincian di VOICE_INPUT_RESEARCH.md §5–6. | pemilik memutuskan kapan | ADR-027 §3.5 |
| B-20 | Kebijakan privasi di repo `tanukonomy-web`: catat dari notifikasi (isi notifikasi aplikasi yang dipilih dibaca di perangkat, teks yang ragu dikirim ke Gemini, disimpan paling lama 7 hari, OTP tidak diproses). | agen | ADR-032, T-11.21 |
| B-21 | Pemrosesan notifikasi memanggil Gemini satu per satu (maks. 5 dtk per item) dan setiap catatan otomatis memancarkan `LedgerChanges` sendiri (N tangkapan = N muat ulang tiap tab). Pertimbangkan satu sinyal per putaran; tunggu keluhan nyata. | agen | audit `record` 1 Okt 2026 (N6) |
| B-22 | Ikon piksel 32×32 untuk kategori Keluarga, Donasi, Bonus, Hadiah, Lainnya, dan untuk akun (menggantikan B-8). Sampai ada, design system memakai Material Symbols di tile berwarna. Butuh artwork pemilik; jangan merancang sendiri. | pemilik | ADR-034 §4 |
| B-23 | Varian ikon piksel untuk mode gelap: garis tepi `#1E1B19` menyatu dengan tile gelap. Butuh artwork pemilik atau aturan pewarnaan ulang yang disetujui. | pemilik | ADR-034 §4 |
| B-25 | Peringatan nominal tidak wajar di **seluruh CATAT** (KT-R12): bandingkan dengan nominal biasa untuk kategori/catatan yang sama, misalnya ≥5× atau ≤⅕. Fase 15 hanya menerapkannya untuk rutin (T-15.6). | agen | [RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md) §7A E5 |
| B-26 | Kartu lembut "Ada yang belum dicatat sejak …?" sesudah 3 hari tanpa catatan apa pun, **tanpa streak** dan tanpa hitungan hari terputus (KT-R13). | agen | [RECURRING_AND_FORECAST.md](../01-product/features/RECURRING_AND_FORECAST.md) §7A E12 |
| B-27 | **R2 Rencana**: anggaran rutin (FR-BUD-008), bulan depan dan horizon (FR-PLN-005), perkiraan per dompet + "siapkan dana" (W1, termasuk notifikasinya), tinjau awal bulan (J4), W7–W10. Fase baru sesudah R1 dirilis. | agen | ADR-035 §3.9, RECURRING_AND_FORECAST §12 |
| B-28 | **R3 Otomasi**: catat otomatis per rutin (nominal tetap), "belum terlihat" H+2, kenaikan harga dari notifikasi, rutin menganggur (W6), saran pola rutin dari riwayat/notifikasi, rutin lewat suara, gabung kartu menunggu (KT-R7). | agen | RECURRING_AND_FORECAST §12 |
| B-14 | **Catat lewat Suara**: STT sistem (`speech_to_text`) + parser aturan + Gemma lokal mulai dari model termurah, 270M → 1B → Gemma 4 E2B (unduhan opt-in dari Hugging Face) → form CATAT terisi draf; adaptor Firebase AI sebagai jalur pivot. ADR-027. Riset & rencana di [VOICE_INPUT_RESEARCH.md](../01-product/features/VOICE_INPUT_RESEARCH.md). | dijadwalkan: T-11.2–T-11.9 | riset 30 Sep 2026 |

## Cakupan requirement

Tabel ini memastikan tidak ada kebutuhan di
[PRD 2.0](../01-product/prd-saldough-2.0.md) yang tidak punya tugas.

| Requirement | Tugas |
|---|---|
| FR-WAL-001 | T-1.1, T-1.2, T-2.7 |
| FR-WAL-002 | T-1.1, T-2.7 |
| FR-WAL-003 | T-1.5, T-2.7 |
| FR-WAL-004 | T-2.8 |
| FR-TXN-001 | T-1.3, T-2.4 |
| FR-TXN-002 | T-1.3, T-2.4, T-4.4 |
| FR-TXN-003 | T-1.3, T-2.4, T-4.4 |
| FR-TXN-004 | T-1.4, T-2.5 |
| FR-TXN-005 | T-1.4, T-2.6 |
| FR-TXN-006 | T-2.11, T-4.11 |
| FR-REC-001 | T-2.3, T-2.4 |
| FR-REC-002 | T-2.8, T-4.10 |
| FR-BUD-001 | T-4.1, T-4.3, T-4.5, T-4.9 |
| FR-BUD-002 | T-4.1, T-4.6 |
| FR-BUD-003 | T-4.4 |
| FR-BUD-006 | T-4.9 |
| FR-BUD-004 | T-4.2, T-4.5 |
| FR-BUD-005 | T-7.1, T-7.2, T-7.3 |
| FR-BUD-007 | T-4.10 |
| FR-FRL-001 | T-5.1 |
| FR-FRL-002 | T-5.1, T-5.3 |
| FR-FRL-003 | T-5.4 |
| FR-FRL-004 | T-5.5 |
| FR-FRL-005 | T-5.6, T-5.9 |
| FR-FRL-006 | — (deprecated) |
| FR-HOME-001 | T-6.1 |
| FR-HOME-002 | T-6.2 |
| FR-HOME-003 | T-6.3 |
| FR-HOME-004 | T-6.4 |
| FR-HOME-005 | T-6.6 |
| NFR-ACC-001 | T-1.7, T-5.7 |
| NFR-ACC-002 | T-1.7, T-2.9, T-4.7, T-5.7 |
| NFR-ACC-003 | T-1.5, T-1.6, T-1.7 |
| NFR-PERF-001 | T-2.10, T-6.5 |
| NFR-PERF-002 | T-1.4, T-1.6, T-6.5 |
| NFR-REL-001 | Terpenuhi sendirinya di MVP — tidak ada panggilan jaringan sama sekali; direvisi 28 Sep 2026 untuk fitur online mendatang, lihat T-8.4 |
| NFR-REL-002 | T-1.2, T-1.4 |
| NFR-REL-003 | T-1.2, T-4.3, T-5.2 |
| NFR-UX-001 | T-2.4, T-2.10, T-6.6, T-7.6 |
| NFR-UX-002 | T-2.1, T-7.4 |
| NFR-UX-003 | T-2.2, T-3.5 |
| NFR-UX-004 | T-1.9, T-4.8, T-5.8 |
| NFR-UX-005 | T-2.4, T-2.11, T-5.5 |
| FR-CAT-001 | T-11.1 |
| FR-LANG-001 | T-11.5 (pilihan bahasa), T-11.14, T-11.16 |
| FR-VOI-001 | T-11.2–T-11.5, T-11.11–T-11.13; jalur cloud T-11.7 |
| FR-NOT-001 | T-11.17–T-11.21 |
| FR-RUT-001 | T-15.1, T-15.3 |
| FR-RUT-002 | T-15.2, T-15.6 |
| FR-RUT-003 | T-15.7 |
| FR-RUT-004 | T-15.8, T-15.15 |
| FR-RUT-005 | T-15.1, T-15.5 |
| FR-PLN-001 | T-15.4, T-15.5, T-15.13 |
| FR-PLN-002 | T-15.11, T-15.13 |
| FR-PLN-003 | T-15.12, T-15.13 |
| FR-PLN-004 | T-15.10 |
| FR-PLN-005 | B-27 (R2) |
| FR-BUD-008 | B-27 (R2) |
| NFR-SEC-001 | Terpenuhi sendirinya di MVP — tidak ada panggilan jaringan sama sekali; direvisi 28 Sep 2026 untuk fitur online mendatang, lihat T-8.4 |
| NFR-PLAT-001 | Diwarisi dari Saldough 1.0, sudah terbukti berjalan |

## Catatan pengerjaan (Fase 0)

**17 September 2026** — Pivot diputuskan setelah analisa yang membandingkan
model 1.0 terhadap arah produk baru. Dua temuan menentukan bentuk seluruh
rencana ini:

- Saldough 1.0 **tidak punya konsep transaksi maupun saldo dompet**.
  `IncomeLine` dan `BudgetLine` adalah baris rencana milik sebuah bulan, tanpa
  tanggal dan tanpa dompet. Satu-satunya entitas berbentuk transaksi nyata di
  seluruh 13.777 baris kode adalah `CardTransaction`, terkunci di fitur kartu.
  Karena itu pivot ini membangun buku besar yang belum pernah ada, bukan
  me-refactor yang sudah ada.
- **Dompet dan transaksi menyerap tiga domain lama tanpa konsep baru.** Enam pos
  investasi jadi enam dompet tabungan; alokasi persentase dan pinjaman antar pos
  jadi transfer; belanja kartu jadi pengeluaran dari dompet kartu. Fitur
  investasi (1.600 baris) dan sebagian besar fitur kartu (2.063 baris) hilang
  bukan karena dibuang, melainkan karena primitif transfer sudah
  mengerjakannya.

Tiga keputusan diambil pemilik lewat `AskUserQuestion`: aset ikon pixel-art akan
dikirim pemilik (sehingga UI dibangun dengan lapisan `AppIcon` dan tidak
menunggu); ikatan anggaran ke dompet bersifat **wajib dan menyaring**; dan data
lama **tidak diimpor sama sekali** — aplikasi mulai dari saldo awal.

Dua hal berbeda dari rencana awal, keduanya diambil sadar saat menulis dokumen:

- `Wallet` dan `Transaction` ditempatkan di `shared/`, bukan `features/`. Ambang
  "2+ konsumen" ADR-0009 terpenuhi jelas, dan bentuknya sama dengan
  `shared/income` + `features/income` di 1.0.
- Aksen utama indigo `#3B3A8F` dipilih dengan rasio kontras dihitung sungguhan
  (7,96 di atas krem, 9,60 di atas kartu), bukan diperkirakan. Slot `transfer`
  sengaja netral supaya tidak menyaingi makna pemasukan dan pengeluaran, dan
  keenam varian `…OnLight` dihapus karena tiap slot kini satu nilai yang sudah
  pasti terbaca sebagai teks.

Strategi pengerjaannya — bangun berdampingan lalu cutover sekali, di repositori
yang sama — dipilih karena biaya token dan batas laju pemakaian agen adalah
pertimbangan nyata di proyek ini. Alasan lengkapnya di
[ADR-014](../02-architecture/adr/0014-strategi-pivot-saldough-2.md).
