# Daftar tugas dan progres

Dokumen ini adalah daftar kerja Saldough beserta status penyelesaiannya.
Perbarui kotak centang di sini setiap kali sebuah tugas selesai.

Untuk alasan di balik urutan fase, lihat [ROADMAP.md](ROADMAP.md). Untuk
pekerjaan desain visual, lihat
[UI_UX_DESIGN_TASKS.md](UI_UX_DESIGN_TASKS.md). Daftar kerja Saldough 1.0
beserta seluruh catatan pengerjaannya diarsipkan di
[TASK_LIST-1.0.md](../99-archive/TASK_LIST-1.0.md).

## Cara memakai dokumen ini

Setiap tugas punya identitas `T-<fase>.<nomor>` dan diakhiri baris
`Memenuhi FR-xxx.` yang menautkannya ke
[PRD 2.0](../01-product/prd-saldough-2.0.md). Tanda `⚠` menandai jebakan yang
sudah diketahui — baca sebelum mengerjakan tugasnya, bukan sesudah.

Kotak dicentang hanya kalau pekerjaannya benar-benar selesai **dan**
terverifikasi. Pekerjaan sebagian tetap kosong disertai catatan `⚠ Sebagian`.

## Ringkasan progres

Terakhir diperbarui: 17 September 2026.

| Fase | Tugas | Selesai | Status |
|---|---|---|---|
| 0 — Dokumen Saldough 2.0 | 14 | 8 | Sedang dikerjakan |
| 1 — Domain inti: dompet dan transaksi | 9 | 0 | Belum dimulai |
| 2 — Layar inti: CATAT, Transaksi, Dompet | 10 | 0 | Belum dimulai |
| 3 — Cutover | 9 | 0 | Gerbang |
| 4 — Anggaran | 8 | 0 | Belum dimulai |
| 5 — Freelance | 8 | 0 | Belum dimulai |
| 6 — Beranda | 5 | 0 | Belum dimulai |
| 7 — Template dan poles | 6 | 0 | Belum dimulai |
| **Total MVP** | **69** | **8** | |

## Fase 0: Dokumen Saldough 2.0

Tidak ada kode aplikasi di fase ini. Urutannya meniru urutan penulisan Saldough
1.0: istilah dulu, lalu produk, lalu domain, lalu keputusan arsitektur, baru
rencana kerja.

- [x] **T-0.1** Buat tag git `pre-pivot-1.0`, pindahkan dokumen perencanaan 1.0
      ke `docs/99-archive/`, dan tulis indeks arsipnya.
      ⚠ Tag ini satu-satunya jalur pemulihan kode 1.0 setelah Fase 3. Ia harus
      ada di remote, bukan cuma lokal.
- [x] **T-0.2** Tulis ulang `PROJECT_GLOSSARY.md` dengan istilah baru, sekalian
      betulkan drift `Failure` yang usang sejak ADR-0005 dibalik.
- [x] **T-0.3** Tulis `prd-saldough-2.0.md` mengikuti kerangka §1–§14 versi 1.0.
- [x] **T-0.4** Tulis ulang `user-stories.md`.
- [x] **T-0.5** Tulis ulang `DOMAIN_MODEL.md` dengan delapan entitas, rumus, dan
      invariannya.
- [x] **T-0.6** Tulis ADR-011 sampai ADR-014.
- [x] **T-0.7** Tandai ADR-0006 dan ADR-0008 digantikan; beri ADR-0002 catatan
      perluasan.
- [x] **T-0.8** Sunting terarah `ARCHITECTURE_OVERVIEW.md`.
- [ ] **T-0.9** Tulis ulang `ROADMAP.md` dengan prinsip penyusunan fase baru.
- [ ] **T-0.10** Tulis `TASK_LIST.md` baru berisi breakdown seluruh fase.
- [ ] **T-0.11** Tulis `UI_UX_DESIGN_TASKS.md` baru.
- [ ] **T-0.12** Perbarui `docs/README.md`: pohon dokumen, daftar ADR, jalur
      baca.
- [ ] **T-0.13** Tulis ulang `.claude/CLAUDE.md` dan `.claude/AGENT_CONTEXT.md`.
      ⚠ Kedua berkas ini disuntik ke konteks tiap sesi. Isi yang basi bukan
      cuma memboroskan, tapi menyesatkan agent berikutnya.
- [ ] **T-0.14** Verifikasi seluruh tautan relatif `docs/` hidup, tidak ada ADR
      yang dirujuk tapi belum ada, lalu commit dan push.
      ⚠ `flutter analyze` dan `flutter test` harus tetap sama persis dengan
      sebelum fase ini, karena tidak ada kode yang disentuh.

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

- [ ] **T-1.1** Buat `shared/wallet/domain/`: entitas `Wallet` dan antarmuka
      `WalletRepository`.
      ⚠ `Wallet` masuk `shared/`, bukan `features/`, karena dibaca
      `transaction`, `budget`, `freelance`, dan `home` — ambang "2+ konsumen"
      [ADR-0009](../02-architecture/adr/0009-core-shared-features-zone-layout.md)
      terpenuhi sejak awal.
      Memenuhi FR-WAL-001 dan FR-WAL-002.
- [ ] **T-1.2** Buat `shared/wallet/data/`: `WalletModel` dengan
      `schemaVersion`, dan `WalletRepositoryImpl` di atas kunci `wallet/all`.
      Memenuhi FR-WAL-001 dan NFR-REL-003.

### Transaksi

- [ ] **T-1.3** Buat `shared/transaction/domain/`: `Transaction` sebagai
      `sealed class` dengan `IncomeTransaction`, `ExpenseTransaction`, dan
      `TransferTransaction`, beserta antarmuka `TransactionRepository`.
      ⚠ Nominal selalu positif; arah uang ditentukan jenis transaksinya. Dan
      `fromWalletId` tidak boleh sama dengan `toWalletId`.
      Memenuhi FR-TXN-001, FR-TXN-002, dan FR-TXN-003.
- [ ] **T-1.4** Buat `shared/transaction/data/`: `TransactionModel` dan
      `TransactionRepositoryImpl` dengan **partisi per bulan** — kunci
      `transaction/YYYY-MM` plus indeks `transaction/_index`.
      ⚠ Bulan tujuan ditentukan `transaction.date`, bukan `DateTime.now()`.
      ⚠ Penyuntingan yang memindahkan transaksi antar bulan wajib menghapus
      dari dokumen asal **sebelum** menambah ke dokumen tujuan, supaya
      kegagalan di tengah tidak menghasilkan transaksi ganda.
      Memenuhi FR-TXN-004, FR-TXN-005, dan NFR-PERF-002.
- [ ] **T-1.5** Buat use case `CalculateWalletBalance` — Dart murni, menghitung
      saldo dari `initialBalance` ditambah seluruh transaksi yang menyentuh
      dompet itu.
      Memenuhi FR-WAL-003 dan NFR-ACC-003.
- [ ] **T-1.6** Terapkan pemeliharaan `Wallet.currentBalance` saat transaksi
      dicatat, disunting, atau dihapus, beserta `recomputeWalletBalances()`.
      ⚠ Urutan penulisan mengikat: dokumen transaksi lebih dulu, dokumen dompet
      menyusul. Transaksi adalah kebenaran, saldo adalah cache-nya. Lihat
      [ADR-012](../02-architecture/adr/0012-tata-letak-penyimpanan-buku-besar.md).
      Memenuhi NFR-ACC-003 dan NFR-PERF-002.

### Verifikasi dan wiring

- [ ] **T-1.7** Tulis uji domain dan data dengan angka nyata: `netPay` kotor
      3.117.500 pajak 2,5% menghasilkan 3.039.563; saldo awal 5.000.000 dengan
      masuk 2.615.438, keluar 3.068.500, dan transfer keluar 1.000.000
      menghasilkan 3.546.938.
      ⚠ **Uji saldo tersimpan versus saldo turunan wajib ada.** Tanpa uji yang
      membuktikan `wallet.currentBalance` identik dengan hasil
      `recomputeWalletBalances()`, keputusan menyimpan nilai turunan di ADR-012
      tidak boleh diambil sama sekali.
      ⚠ Uji juga wajib membuktikan transfer tidak mengubah total saldo seluruh
      dompet.
      Memenuhi NFR-ACC-001, NFR-ACC-002, dan NFR-ACC-003.
- [ ] **T-1.8** Daftarkan `WalletRepository` dan `TransactionRepository` di
      `RootModule`.
      ⚠ Hanya **ditambahi**. Tidak satu pun baris lama di `RootModule` boleh
      diubah atau dihapus sampai Fase 3.
- [ ] **T-1.9** Tambahkan namespace i18n `wallet` dan `transaction` di
      `assets/i18n/{id,en}.i18n.json`, lalu regenerasi slang.
      ⚠ Namespace lama (`cycle`, `grocery`, `card`, `investment`, `worklog`,
      `income`) **tidak** dihapus di fase ini — layar lama masih memakainya dan
      penghapusannya akan membuat `flutter analyze` merah. Dihapus di T-3.6.
      Memenuhi NFR-UX-004.

## Fase 2: Layar inti — CATAT, Transaksi, Dompet

Akhir fase ini aplikasi baru sudah bisa dipakai sehari-hari: mencatat
pemasukan, pengeluaran, dan transfer, lalu melihat saldonya.

⚠ Invarian "jangan sentuh fitur lama" dari Fase 1 masih berlaku penuh.

### Fondasi tampilan

- [ ] **T-2.1** Buat `AppIcon(IconKey)` di `lib/core/presentation/widgets/`
      dengan 22 kunci semantik, diisi ikon Material sebagai isian sementara.
      ⚠ `IconKey` adalah `enum` supaya kunci yang belum dipetakan gagal saat
      kompilasi, bukan saat dijalankan.
      ⚠ Aset pixel-art dari pemilik masuk di T-7.4. Lapisan ini ada supaya
      penggantiannya jadi satu berkas, bukan puluhan berkas halaman.
      Memenuhi NFR-UX-002.
- [ ] **T-2.2** Tambahkan slot warna `accent`, `onAccent`, `transfer`, dan
      `pending` ke `AppColorsExtension`, beserta uji kontrasnya.
      ⚠ Slot lama (`investment`, `rollUp`, `needsReview`, `onNeedsReview`, dan
      keenam varian `…OnLight`) **tidak** dihapus di fase ini — layar lama
      memakainya. Dihapus di T-3.5.
      ⚠ Nilai hex dan rasio kontrasnya sudah ditetapkan di
      [ADR-013](../02-architecture/adr/0013-bahasa-visual-dan-sistem-ikon.md).
      Jangan mengarang nilai baru.
      Memenuhi NFR-UX-003.
- [ ] **T-2.3** Buat `AppShellPage` di `lib/core/presentation/shell/` — lima
      tujuan dengan CATAT di tengah, `IndexedStack`, didaftarkan di rute
      sementara `/shell`.
      ⚠ Berkas baru dengan nama baru. `main_shell_page.dart` yang lama tidak
      disentuh sampai T-3.4.
      ⚠ CATAT bukan tujuan navigasi biasa: ia tidak mengganti isi
      `IndexedStack`, melainkan membuka lembar pilihan.
      Memenuhi FR-REC-001.

### Pencatatan dan riwayat

- [ ] **T-2.4** Buat `features/record/`: lembar CATAT beserta tiga formulir —
      pemasukan, pengeluaran, dan transfer.
      ⚠ Ini satu-satunya jalur pembuatan transaksi manual. Jangan membuat
      formulir pencatatan tersendiri di layar mana pun.
      ⚠ Kosakata tombol dan pesan menyatakan pencatatan, bukan tindakan
      keuangan. "Catat Transfer", bukan "Transfer Sekarang".
      Memenuhi FR-REC-001, FR-TXN-001, FR-TXN-002, FR-TXN-003, NFR-UX-001, dan
      NFR-UX-005.
- [ ] **T-2.5** Buat `features/transaction/`: daftar riwayat dikelompokkan per
      tanggal, dengan penyaring jenis, dompet, dan kategori.
      Memenuhi FR-TXN-004.
- [ ] **T-2.6** Tambahkan penyuntingan dan penghapusan transaksi.
      ⚠ Saat dompet sebuah transaksi berpindah, saldo dompet lama **dan** baru
      sama-sama dihitung ulang.
      ⚠ Pembetulan dilakukan dengan menyunting atau menghapus, tidak pernah
      dengan mencatat transaksi penyeimbang.
      Memenuhi FR-TXN-005.

### Dompet

- [ ] **T-2.7** Buat `features/wallet/`: daftar dompet, total saldo, serta
      tambah dan sunting dompet.
      ⚠ Saldo awal adalah pernyataan keadaan, bukan transaksi setoran. Ia tidak
      muncul di riwayat.
      Memenuhi FR-WAL-001, FR-WAL-002, dan FR-WAL-003.
- [ ] **T-2.8** Buat layar rincian dompet: riwayat tersaring dan pintasan ke
      CATAT dengan dompet ini sudah terpilih.
      ⚠ Pintasan kontekstual memakai alur dan entitas CATAT yang sama persis,
      bukan implementasi tersendiri.
      Memenuhi FR-WAL-004 dan FR-REC-002.

### Verifikasi

- [ ] **T-2.9** Tulis uji bloc untuk `record`, `transaction`, dan `wallet`
      memakai `mocktail` dan `bloc_test`.
      ⚠ `Bloc` tidak memancarkan state yang sama dengan state sebelumnya.
      Stub repository yang mengembalikan data statis akan membuat pemuatan
      ulang tampak seperti tidak memancarkan apa pun. Buat stub mencerminkan
      hasil penulisan terakhir.
      Memenuhi NFR-ACC-002.
- [ ] **T-2.10** Jalankan di perangkat atau emulator, telusuri loop inti: buat
      dompet, catat pemasukan, catat pengeluaran, catat transfer, dan pastikan
      saldo bergerak persis seperti yang dijanjikan model.
      Memenuhi NFR-PERF-001 dan NFR-UX-001.

## Fase 3: Cutover

⚠ **Fase ini adalah gerbang.** Jangan memulai Fase 4 sebelum seluruh tugasnya
tercentang dan `flutter analyze` bersih. Sebelum fase ini repositori memuat dua
model domain sekaligus; sesudahnya hanya tersisa satu.

⚠ Jangan mencicil penghapusan di luar fase ini. Keenam port lintas fitur
bermuara ke `cycle`, jadi penghapusan sebagian meninggalkan galat berantai
tanpa menyelesaikan apa pun.

- [ ] **T-3.1** Pindahkan `CalculateNetPay`, `DeductionRule`, dan
      `NetPayBreakdown` dari `lib/shared/income/domain/` ke
      `lib/features/freelance/domain/`, beserta ujinya.
      ⚠ Dikerjakan **sebelum** penghapusan di T-3.2, supaya aritmetika per mil
      yang sudah teruji tidak ikut terhapus.
      ⚠ Setelah pivot hanya ada satu konsumen, sehingga ambang "2+ konsumen"
      ADR-0009 tidak lagi terpenuhi dan promosinya ke `shared/` kehilangan
      dasar.
- [ ] **T-3.2** Hapus `lib/features/{cycle,card,investment,grocery,income}`,
      `lib/shared/goal/`, dan sisa `lib/shared/income/`.
- [ ] **T-3.3** Hapus tes fitur lama di `test/features/` dan `test/shared/`.
- [ ] **T-3.4** Bersihkan `RootModule` dari seluruh adapter lintas fitur lama,
      tukar rute `/home` ke `AppShellPage`, lalu hapus `main_shell_page.dart`
      dan rute sementara `/shell`.
- [ ] **T-3.5** Hapus slot warna `investment`, `rollUp`, `needsReview`,
      `onNeedsReview`, dan keenam varian `…OnLight` dari `AppColorsExtension`,
      lalu perbarui uji kontrasnya.
- [ ] **T-3.6** Hapus namespace i18n `cycle`, `grocery`, `card`, `investment`,
      `worklog`, dan `income`, lalu regenerasi slang.
- [ ] **T-3.7** Hapus `tool/seed_import.dart`.
      ⚠ Skrip itu mengimpor repository fitur lama dan tidak akan kompilasi
      setelah T-3.2. `tool/seed_data.json` **dipertahankan** sebagai rekaman
      data historis nyata pemilik.
- [ ] **T-3.8** Perbarui `description` di `pubspec.yaml` yang masih berbunyi
      "pengganti sistem spreadsheet manual".
- [ ] **T-3.9** Catat baseline uji yang baru apa adanya di catatan pengerjaan.
      ⚠ Jumlah uji akan **turun tajam** karena sekitar 2.900 baris uji hilang
      bersama fiturnya. Jangan mengejar angka lama dengan menulis uji yang
      tidak bermakna.

## Fase 4: Anggaran

- [ ] **T-4.1** Buat `features/budget/domain/`: `Budget`, `BudgetItem`,
      `BudgetPeriod`, dan `BudgetItemStatus`.
      ⚠ `Budget.walletId` wajib terisi, dan ikatan itu menyaring pengeluaran
      mana yang terhitung.
      Memenuhi FR-BUD-001 dan FR-BUD-002.
- [ ] **T-4.2** Buat use case `CalculateBudgetProgress` — Dart murni,
      menghasilkan `spent`, `remaining`, `progress`, dan status tiap pos.
      ⚠ Tidak satu pun nilai itu disimpan. Semuanya dihitung ulang saat
      diakses.
      Memenuhi FR-BUD-004.
- [ ] **T-4.3** Buat `features/budget/data/`: `BudgetModel` dan repositorinya
      di atas kunci `budget/all`.
      Memenuhi FR-BUD-001 dan NFR-REL-003.
- [ ] **T-4.4** Tambahkan pemilih pos anggaran di formulir pengeluaran CATAT.
      ⚠ Pemilih hanya menawarkan pos yang dompet anggarannya sama dengan dompet
      asal pengeluaran.
      Memenuhi FR-BUD-003 dan FR-TXN-002.
- [ ] **T-4.5** Buat layar Anggaran: daftar anggaran aktif beserta progresnya.
      ⚠ Beberapa anggaran boleh aktif sekaligus, berbagi dompet, dan berbeda
      periode. Jangan membuat objek anggaran bulanan global.
      Memenuhi FR-BUD-001 dan FR-BUD-004.
- [ ] **T-4.6** Buat layar sunting anggaran beserta posnya, termasuk jumlah dan
      harga satuan opsional.
      ⚠ Jumlah dikali harga satuan ada supaya daftar belanja pemilik yang
      sungguhan berisi 35 item tetap bisa dicatat serinci sebelumnya.
      Memenuhi FR-BUD-002.
- [ ] **T-4.7** Tulis uji: membuat anggaran tidak mengubah saldo dompet mana
      pun; pengeluaran dari dompet lain tidak menambah `spent`; status pos
      benar di keempat kondisinya.
      Memenuhi NFR-ACC-002.
- [ ] **T-4.8** Tambahkan namespace i18n `budget` dan daftarkan `BudgetScope`.
      Memenuhi NFR-UX-004.

## Fase 5: Freelance

- [ ] **T-5.1** Buat `features/freelance/domain/`: `FreelanceProject`,
      `WorklogEntry`, `FreelancePayment`, dan `PaymentStatus`, di samping
      `CalculateNetPay` yang sudah dipindahkan di T-3.1.
      Memenuhi FR-FRL-001 dan FR-FRL-002.
- [ ] **T-5.2** Buat `features/freelance/data/`: repositori di atas kunci
      `freelance/projects`, `freelance/worklog`, dan `freelance/payments`.
      ⚠ Ketiganya sengaja tidak dipartisi karena lajunya rendah. Tinjau ulang
      kalau entrinya melewati beberapa ratus.
      Memenuhi NFR-REL-003.
- [ ] **T-5.3** Buat layar worklog: catat, sunting, dan hapus entri, dengan
      nominal yang diperoleh dihitung dari jam dikali tarif.
      ⚠ **Tidak pernah menyentuh saldo dompet.** Mencatat kerja bukan menerima
      uang.
      Memenuhi FR-FRL-002.
- [ ] **T-5.4** Buat pengelompokan worklog jadi pembayaran, menampilkan gaji
      kotor, potongan, dan gaji bersih terpisah.
      ⚠ Potongan persentase selalu dihitung dari gaji kotor, tidak pernah dari
      nilai berjalan setelah potongan sebelumnya. Potongan tidak beranak.
      ⚠ Periode pembayaran tidak mengikuti batas bulan kalender.
      Memenuhi FR-FRL-003.
- [ ] **T-5.5** Terapkan pencatatan pembayaran diterima, yang membuat tepat
      satu `IncomeTransaction` sebesar gaji bersih.
      ⚠ `incomeTransactionId` yang sudah terisi adalah penjaga supaya
      pembayaran yang sama tidak bisa dicatat dua kali. Status dan id transaksi
      berubah dalam satu operasi, tidak pernah terpisah.
      Memenuhi FR-FRL-004 dan NFR-UX-005.
- [ ] **T-5.6** Buat ringkasan freelance beserta titik masuknya dari Beranda dan
      dari CATAT pemasukan.
      ⚠ Freelance bukan tujuan navigasi bawah.
      Memenuhi FR-FRL-005.
- [ ] **T-5.7** Tulis uji: worklog tidak mengubah saldo; pembayaran yang dicatat
      diterima menambah saldo tepat satu kali; `netPay` 37 jam pada tarif
      72.500 dengan pajak 2,5% menghasilkan 2.615.438.
      Memenuhi NFR-ACC-001 dan NFR-ACC-002.
- [ ] **T-5.8** Tambahkan namespace i18n `freelance` dan daftarkan
      `FreelanceScope`.
      Memenuhi NFR-UX-004.

## Fase 6: Beranda

Beranda dikerjakan terakhir di antara layar karena ia hanya bermakna setelah
seluruh fitur di atasnya menghasilkan data.

- [ ] **T-6.1** Tampilkan total saldo, pemasukan bulan berjalan, dan pengeluaran
      bulan berjalan.
      ⚠ Transfer tidak dihitung sebagai pemasukan maupun pengeluaran. Kalau ia
      ikut dihitung, satu pemindahan Rp1.000.000 akan tampil sebagai pemasukan
      sekaligus pengeluaran — dua angka yang sama-sama salah.
      Memenuhi FR-HOME-001.
- [ ] **T-6.2** Tampilkan ringkasan anggaran beserta jalan ke layar Anggaran.
      Memenuhi FR-HOME-002.
- [ ] **T-6.3** Tampilkan ringkasan freelance, dan sembunyikan sepenuhnya kalau
      tidak ada pembayaran yang tertunda.
      Memenuhi FR-HOME-003.
- [ ] **T-6.4** Tampilkan transaksi terbaru beserta jalan ke layar Transaksi.
      Memenuhi FR-HOME-004.
- [ ] **T-6.5** Jalankan di perangkat, ukur waktu tampil Beranda, dan telusuri
      loop inti penuh sampai pencatatan pembayaran freelance.
      Memenuhi NFR-PERF-001 dan NFR-PERF-002.

## Fase 7: Template dan poles

- [ ] **T-7.1** Buat `BudgetTemplate` beserta repositorinya di atas kunci
      `budget_template/all`.
      Memenuhi FR-BUD-005.
- [ ] **T-7.2** Buat layar template: buat, sunting, gandakan, aktifkan,
      nonaktifkan, dan hapus.
      ⚠ Membuat atau menyunting template tidak mengubah saldo dompet mana pun.
      Memenuhi FR-BUD-005.
- [ ] **T-7.3** Terapkan pembuatan anggaran dari template.
      ⚠ Anggaran hasil template berdiri sendiri. Menyuntingnya tidak mengubah
      templatenya, dan sebaliknya.
      Memenuhi FR-BUD-005.
- [ ] **T-7.4** Masukkan aset ikon pixel-art dari pemilik ke peta `AppIcon`.
      ⚠ Terhambat sampai asetnya tersedia. Kalau belum tiba saat fase ini
      selesai, keputusan identitas ikon perlu diambil ulang — "sementara" yang
      berlangsung selamanya bukan keputusan.
      Memenuhi NFR-UX-002.
- [ ] **T-7.5** Sesuaikan aksen terhadap aset kalau perlu, dan perbarui ADR-013
      dengan hasilnya.
- [ ] **T-7.6** Poles: skeleton pemuatan pertama, keadaan kosong tiap layar, dan
      konfirmasi tiap tindakan merusak.
      ⚠ Pakai ulang `AppSkeleton` dan `showConfirmDelete` yang sudah ada.
      Memenuhi NFR-UX-001.

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
| FR-TXN-003 | T-1.3, T-2.4 |
| FR-TXN-004 | T-1.4, T-2.5 |
| FR-TXN-005 | T-1.4, T-2.6 |
| FR-REC-001 | T-2.3, T-2.4 |
| FR-REC-002 | T-2.8 |
| FR-BUD-001 | T-4.1, T-4.3, T-4.5 |
| FR-BUD-002 | T-4.1, T-4.6 |
| FR-BUD-003 | T-4.4 |
| FR-BUD-004 | T-4.2, T-4.5 |
| FR-BUD-005 | T-7.1, T-7.2, T-7.3 |
| FR-FRL-001 | T-5.1 |
| FR-FRL-002 | T-5.1, T-5.3 |
| FR-FRL-003 | T-5.4 |
| FR-FRL-004 | T-5.5 |
| FR-FRL-005 | T-5.6 |
| FR-HOME-001 | T-6.1 |
| FR-HOME-002 | T-6.2 |
| FR-HOME-003 | T-6.3 |
| FR-HOME-004 | T-6.4 |
| NFR-ACC-001 | T-1.7, T-5.7 |
| NFR-ACC-002 | T-1.7, T-2.9, T-4.7, T-5.7 |
| NFR-ACC-003 | T-1.5, T-1.6, T-1.7 |
| NFR-PERF-001 | T-2.10, T-6.5 |
| NFR-PERF-002 | T-1.4, T-1.6, T-6.5 |
| NFR-REL-001 | Terpenuhi sendirinya — tidak ada panggilan jaringan di MVP |
| NFR-REL-002 | T-1.2, T-1.4 |
| NFR-REL-003 | T-1.2, T-4.3, T-5.2 |
| NFR-UX-001 | T-2.4, T-2.10, T-7.6 |
| NFR-UX-002 | T-2.1, T-7.4 |
| NFR-UX-003 | T-2.2, T-3.5 |
| NFR-UX-004 | T-1.9, T-4.8, T-5.8 |
| NFR-UX-005 | T-2.4, T-5.5 |
| NFR-SEC-001 | Terpenuhi sendirinya — tidak ada panggilan jaringan di MVP |
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
