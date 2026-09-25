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

Terakhir diperbarui: 25 September 2026.

| Fase | Tugas | Selesai | Status |
|---|---|---|---|
| 0 — Dokumen Saldough 2.0 | 14 | 14 | Selesai |
| 1 — Domain inti: dompet dan transaksi | 9 | 9 | Selesai |
| 2 — Layar inti: CATAT, Transaksi, Dompet | 12 | 12 | Selesai |
| 3 — Cutover | 9 | 9 | Selesai |
| 4 — Anggaran | 11 | 11 | Selesai |
| 5 — Freelance | 8 | 0 | Belum dimulai |
| 6 — Beranda | 6 | 0 | Belum dimulai |
| 7 — Template dan poles | 7 | 0 | Belum dimulai |
| **Total MVP** | **76** | **55** | |

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
      ⚠ Di emulator baru terlihat kartu Freelance di formulir pemasukan;
      emulator terlalu lambat (ANR berulang) untuk menelusuri sisanya. Alur
      lengkapnya diuji lewat shell sungguhan di uji widget, dan ditelusuri di
      perangkat bersama T-6.5.
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

## Fase 6: Beranda

Beranda dikerjakan terakhir di antara layar karena ia hanya bermakna setelah
seluruh fitur di atasnya menghasilkan data.

- [ ] **T-6.1** Tampilkan total saldo, pemasukan bulan berjalan, dan pengeluaran
      bulan berjalan.
      ⚠ Transfer tidak dihitung sebagai pemasukan maupun pengeluaran. Kalau ia
      ikut dihitung, satu pemindahan Rp1.000.000 akan tampil sebagai pemasukan
      sekaligus pengeluaran — dua angka yang sama-sama salah.
      Memenuhi FR-HOME-001.
- [ ] **T-6.2** Tampilkan ringkasan anggaran — total rencana, terpakai, dan
      sisa — beserta jalan ke layar Anggaran.
      Memenuhi FR-HOME-002.
- [ ] **T-6.3** Tampilkan ringkasan freelance: total jam, diperoleh, sudah
      dibayar, belum dibayar, dan tanggal pembayaran terdekat yang belum
      diterima. Sembunyikan sepenuhnya kalau tidak ada pembayaran tertunda.
      ⚠ **Jangan menampilkan entri worklog satu per satu di Beranda.** Beranda
      memuat ringkasan; daftar kerjanya ada di Ikhtisar Freelance.
      Memenuhi FR-HOME-003.
- [ ] **T-6.4** Tampilkan transaksi terbaru beserta jalan ke layar Transaksi.
      Memenuhi FR-HOME-004.
- [ ] **T-6.5** Jalankan di perangkat, ukur waktu tampil Beranda, dan telusuri
      loop inti penuh sampai pencatatan pembayaran freelance.
      Memenuhi NFR-PERF-001 dan NFR-PERF-002.
- [ ] **T-6.6** Buat keadaan kosong Beranda: "Belum ada transaksi" beserta
      ajakan **Catat Transaksi**, dan arahan membuat dompet pertama kalau belum
      ada dompet sama sekali.
      ⚠ Ajakannya membuka alur CATAT yang sama, bukan formulir tersendiri.
      ⚠ Kartu ringkasan yang belum punya isi disembunyikan, bukan ditampilkan
      sebagai deretan angka nol. Layar pertama menentukan apakah aplikasi ini
      dipakai lagi besok.
      Memenuhi FR-HOME-005.

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
- [ ] **T-7.7** Buat `FreelanceTemplate` beserta repositori, layar CRUD-nya
      sebagai tab ketiga Ikhtisar Freelance, dan pembuatan proyek dari template.
      ⚠ Hubungannya sama persis dengan `BudgetTemplate` terhadap `Budget`:
      template adalah definisi, proyek adalah salinan mandiri. Menyunting
      template tidak mengubah proyek yang sudah dibuat darinya.
      ⚠ Template tidak pernah menyentuh saldo dompet mana pun.
      Memenuhi FR-FRL-006.
- [ ] **T-7.4** Konversi 67 SVG dari `docs/stitch_pixel_finance_tracker/icon_*/
      code.html` jadi aset Flutter di `assets/icons/`, lalu masukkan ke peta
      `AppIcon` menggantikan isian Material — padanannya sudah ditetapkan di
      [ADR-015](../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md).
      ⚠ Asetnya sudah tersedia di repositori sejak sebelum Fase 1 — bukan lagi
      menunggu kiriman pemilik. Kunci yang belum punya padanan (`add`, `edit`,
      `delete`, `chevronLeft`, `chevronRight`) tetap Material sampai ada.
      Memenuhi NFR-UX-002.
- [ ] **T-7.5** Terapkan sistem elevasi bayangan keras (`AppHardCard`) dan
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
| FR-FRL-005 | T-5.6, T-7.7 |
| FR-FRL-006 | T-7.7 |
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
| NFR-REL-001 | Terpenuhi sendirinya — tidak ada panggilan jaringan di MVP |
| NFR-REL-002 | T-1.2, T-1.4 |
| NFR-REL-003 | T-1.2, T-4.3, T-5.2 |
| NFR-UX-001 | T-2.4, T-2.10, T-6.6, T-7.6 |
| NFR-UX-002 | T-2.1, T-7.4 |
| NFR-UX-003 | T-2.2, T-3.5 |
| NFR-UX-004 | T-1.9, T-4.8, T-5.8 |
| NFR-UX-005 | T-2.4, T-2.11, T-5.5 |
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
