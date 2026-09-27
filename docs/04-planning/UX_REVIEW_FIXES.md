# Perbaikan hasil review UX — Saldough 2.0

Dokumen ini adalah daftar kerja untuk menindaklanjuti review produk/UX yang
dijalankan skill [`ux-review`](../../.claude/skills/ux-review/SKILL.md) pada
**27 September 2026**, terhadap commit `c44106b` (`main` sesudah Fase 6).
Review itu dilengkapi riset pola aplikasi keuangan yang sukses (Money
Manager, Copilot, Monarch, YNAB) dan pedoman umum NN/g. Sumbernya ada di
bagian [Sumber riset](#sumber-riset).

Pada hari yang sama menyusul **review UI** (tata letak, jenis komponen, warna,
penekanan) terhadap commit `185455f`, dengan tujuh layar dirender di Flutter
Web 390×844, termasuk mode gelap. Temuannya jadi UX-14 s.d. UX-22 di bagian
[UI: penekanan, warna, tipografi, tata letak](#ui-penekanan-warna-tipografi-tata-letak),
dan keputusan desainnya diusulkan di
[ADR-020](../02-architecture/adr/0020-hierarki-penekanan-bahasa-visual-pixel.md)
(Proposed).

Review tidak mengubah kode. Dokumen inilah jembatan dari temuan ke pekerjaan.
Setiap item memuat berkas dan barisnya, akibatnya ke pemilik, langkah
perbaikan, dan cara memverifikasinya, supaya bisa dikerjakan tanpa menjalankan
ulang review.

Daftar ini **terpisah dari MVP**: item-item di sini tidak dihitung di total
MVP [TASK_LIST.md](TASK_LIST.md), tetapi progresnya tampil di tabel ringkasan
TASK_LIST sebagai baris sendiri. Perbarui keduanya setiap kali sebuah item
selesai.

## Cara memakai dokumen ini

Aturan pencentangan sama dengan TASK_LIST: kotak hanya dicentang kalau
perbaikannya **selesai dan terverifikasi**. Pekerjaan setengah jalan dibiarkan
kosong dengan catatan `⚠ Sebagian`.

| Penanda | Arti |
|---|---|
| `- [ ]` | Belum dikerjakan |
| `- [x]` | Selesai dan terverifikasi |
| 🔴 | Blocker — menghalangi tugas inti. **Tidak ada di review ini.** |
| 🟠 | Friksi — bisa diselesaikan tapi berputar-putar atau butuh tebakan |
| 🟡 | Polish — kosmetik/konsistensi, tidak menghalangi siapa pun |
| ⛔ | Terkunci — butuh keputusan pemilik dulu (lihat bagian di bawah) |

Identitas item: `UX-<nomor>`. Kolom "Kat." merujuk kategori checklist
`ux-review` (`references/checklist.md`): A navigasi, B alur, C state, D copy,
E bahasa visual, F aksesibilitas.

## Aturan yang berlaku untuk semua item

Aturan berikut sudah ada di proyek dan mengikat. Baca sebelum menyentuh kode.

1. **CATAT satu-satunya jalur pembuatan transaksi** (aturan 8 CLAUDE.md).
   Pintasan apa pun ("Catat lagi", isian bawaan) memanggil `openRecordSheet`
   dengan parameter awal, bukan formulir baru.
2. **Teks lewat slang**, kunci baru ditambahkan ke `id` dan `en` sekaligus.
   Paritas saat review: 501/501 kunci.
3. **Warna, jarak, sudut lewat token** (`context.appColors`, `AppSpacing`,
   `AppRadius`). Warna mengikuti "satu peran, satu warna" ADR-016.
4. **Format dengan `dart format -l 120`**, hanya berkas yang disentuh. Tanpa
   `-l 120`, formatter menata ulang puluhan berkas lain (terjadi di `4149642`
   dan sesi 26 Sep 2026).
5. **Tutup setiap perubahan dengan** `flutter analyze` (0 issue) dan
   `flutter test` (baseline saat review: 452 lulus, jangan turun). Untuk
   perubahan perilaku, uji mutasi: rusak jalurnya, pastikan uji merah,
   pulihkan.
6. **Verifikasi tampilan** di emulator (`flutter run --release`; build debug
   memicu ANR di emulator pemilik). Tanpa emulator, pakai Flutter Web
   sementara dengan `--no-web-resources-cdn` (lihat
   `references/render-method.md` skill `ux-review`). Keterbatasannya: input
   teks lewat Playwright tidak masuk ke kolom Flutter Web.

## Ringkasan progres

Terakhir diperbarui: 27 September 2026.

| Tingkat | Item | Selesai |
|---|---|---|
| 🟠 Friksi | 12 | 0 |
| 🟡 Polish | 10 | 0 |
| **Total** | **22** | **0** |

Terkunci menunggu keputusan pemilik: UX-1, UX-4, UX-8, UX-10, dan UX-14,
UX-15, UX-16, UX-18, UX-20, UX-21 (keenamnya lewat persetujuan ADR-020).

## Keputusan pemilik yang dibutuhkan

Empat item mengubah alur atau aturan yang sudah disepakati. Jangan dikerjakan
sebelum pemilik memilih. Hapus tanda ⛔ dan catat keputusannya di item begitu
dijawab.

- **UX-1** — CATAT langsung membuka formulir Pengeluaran (dengan pengalih
  jenis), atau tetap lewat lembar pilihan? Mengubah alur T-2.4.
- **UX-4** — Bentuk "catat ulang": tombol "Catat lagi" di rincian transaksi
  saja, atau juga favorit transaksi tersimpan (pola Money Manager)?
- **UX-8** — Hapus transaksi tanpa dialog, diganti snackbar **Urungkan**?
  Konfirmasi tetap untuk hapus dompet, anggaran, dan proyek.
- **UX-10** — Warna bilah progres anggaran (ADR-016 baris 136 menyebutnya
  "belum diputuskan") dan penanda laju waktu periode.
- **ADR-020** — Setujui, ubah, atau tolak usulan hierarki penekanan
  (varian tombol, label minimal 11px, satu penanda warna per baris, bilah
  hanya untuk progres). Membuka UX-14, UX-15, UX-16, UX-18, UX-20, UX-21.

## Friksi

Delapan item berikut memperlambat atau membingungkan tugas harian, terutama
mencatat. Urutannya dari dampak terbesar.

- [ ] **UX-1** 🟠⛔ [B] **CATAT selalu melewati lembar pilihan layar penuh.**
      `open_record_sheet.dart` (loop pilihan), `record_choice_sheet.dart:43-101`.
      Setiap pencatatan: CATAT → tiga kartu edukasi (alur, contoh, efek saldo,
      "Info Pencatatan") → pilih jenis → formulir. Di layar 390×844 kartu
      Transfer terpotong, tombolnya baru terlihat sesudah menggulir. Berguna
      di pemakaian pertama, penghambat di pemakaian ke-100. Riset: pencatatan
      manual adalah penyebab utama aplikasi pencatat ditinggalkan.
      Usulan: CATAT langsung ke formulir Pengeluaran dengan pengalih tiga
      segmen (Masuk/Keluar/Transfer) di atasnya; kartu edukasi hanya di
      pemakaian pertama atau lewat ikon info. Pintasan kontekstual
      (`initialChoice`) tetap berlaku.
      Verifikasi: uji widget alur CATAT; render di 390×844 memperlihatkan
      formulir dalam satu ketukan.
- [ ] **UX-2** 🟠 [B] **Dompet tidak pernah terisi otomatis.**
      `expense_form_sheet.dart:85,94` — `_walletId` hanya dari
      `initialWalletId`, selain itu `null`; pola sama di pemasukan dan
      transfer. Walau hanya satu dompet aktif, pemakai membuka menu tiap kali,
      dan tombol Catat mati tanpa alasan yang terlihat.
      Perbaikan: isi dengan dompet terakhir yang dipakai untuk jenis itu
      (turunkan dari transaksi terbaru di `RecordBloc`, tanpa penyimpanan
      baru); kalau hanya satu dompet aktif, pilih dompet itu. Pintasan
      `initialWalletId` tetap menang.
      Verifikasi: uji bloc/widget untuk tiga kasus (satu dompet, riwayat ada,
      pintasan).
- [ ] **UX-3** 🟠 [B] **Kategori tidak belajar dari riwayat.**
      `expense_form_sheet.dart:22-28` — saran kategori daftar tetap. Kategori
      yang diketik lewat "Lainnya" harus diketik ulang tiap kali, dan ejaan
      berbeda ("listrik" vs "Listrik PLN") memecah penyaring kategori layar
      Transaksi.
      Perbaikan: gabungkan saran bawaan dengan kategori paling sering dipakai
      untuk jenis itu (dari transaksi yang sudah dimuat), tanpa duplikat
      beda huruf besar-kecil.
      Verifikasi: uji unit fungsi penggabung saran.
- [ ] **UX-4** 🟠⛔ [B] **Tidak ada "catat ulang" untuk transaksi rutin.**
      Belanja mingguan, token listrik, dan sejenisnya diisi dari nol.
      Usulan minimum: tombol **Catat lagi** di rincian transaksi yang membuka
      `openRecordSheet` dengan jenis, dompet, kategori, nominal, dan catatan
      terisi, tanggal hari ini. Perluasan (keputusan pemilik): favorit
      transaksi tersimpan.
      Verifikasi: uji widget rincian → formulir terisi.
- [ ] **UX-5** 🟠 [D] **Komponen bawaan Material tetap berbahasa Inggris.**
      `lib/app.dart:31` — `MaterialApp.router` tanpa `localizationsDelegates`
      dan `supportedLocales`. Terbukti di render: label semantik dropdown
      "Show menu". `showDatePicker` dipakai di empat tempat
      (`record_date_field.dart`, `budget_form_sheet.dart`,
      `freelance_form_fields.dart`, `freelance_actions.dart`), jadi judul dan
      tombol pemilih tanggal serta menu salin/tempel ikut berbahasa Inggris.
      Melanggar NFR-UX-004.
      Perbaikan: tambahkan `flutter_localizations`, pasang
      `GlobalMaterialLocalizations`/`GlobalWidgetsLocalizations`/
      `GlobalCupertinoLocalizations`, `supportedLocales` dan `locale` dari
      slang (`TranslationProvider`).
      Verifikasi: uji widget yang membuka pemilih tanggal di locale `id` dan
      mencari teks bahasa Indonesia.
- [ ] **UX-6** 🟠 [B] **Pencarian Transaksi hanya mencakup bulan terbuka.**
      `transaction_bloc.dart:119` memuat satu bulan; petunjuk "Cari catatan /
      kategori..." tidak menyebutnya. Mencari tagihan bulan lalu tidak
      menemukan apa pun.
      Perbaikan langkah 1: ubah petunjuk dan keadaan kosong penyaring jadi
      menyebut "di bulan ini". Langkah 2 (opsional, catat sebagai tugas
      baru): mode pencarian lintas bulan.
      Verifikasi: kunci i18n `id`/`en`, uji widget keadaan kosong.
- [ ] **UX-7** 🟠 [A] **Beranda kosong punya ajakan buntu dan ganda.**
      `home_cards.dart:498` — tautan "Atau buat anggaran pengeluaran" tampil
      walau belum ada dompet, lalu layar Anggaran berkata "Buat dompet dulu".
      Kartu saldo dan kartu kosong sama-sama mengajak membuat dompet
      ("+ Dompet" dan "Buat Dompet Pertama").
      Perbaikan: sembunyikan tautan anggaran selama `hasNoWallets`; sisakan
      satu ajakan membuat dompet.
      Verifikasi: uji widget Beranda tanpa dompet.
- [ ] **UX-8** 🟠⛔ [C] **Hapus transaksi lewat dialog, tanpa Urungkan.**
      Tujuh titik `showConfirmDelete`, termasuk
      `transaction_detail_page.dart:87`. Menghapus transaksi mengubah saldo;
      konfirmasi yang terlalu sering membuat orang menekan "Hapus" tanpa
      membaca (NN/g).
      Usulan: hapus transaksi langsung, lalu snackbar **Urungkan** beberapa
      detik yang menyimpan ulang transaksi yang sama (id sama, saldo
      dihitung ulang). Konfirmasi dipertahankan untuk aksi yang tak bisa
      dibalik.
      Verifikasi: uji bloc hapus → urungkan mengembalikan saldo persis.

## Polish

Lima item berikut soal konsistensi dan aksesibilitas. Tidak menghalangi
tugas, tetapi murah dan menaikkan kualitas terasa.

- [ ] **UX-9** 🟡 [D] **Penafian "hanya mencatat" berulang di banyak tempat.**
      Lembar pilihan (`t.record.disclaimerMessage`), kartu aturan tiap
      formulir (`expense_form_sheet.dart:169`, `transfer_form_sheet.dart:185`),
      catatan kaki tiap formulir (`record_form_frame.dart:78`), rincian
      transaksi, rincian dompet, dan kartu aturan freelance. Pengulangan
      membuat pesannya diabaikan.
      Perbaikan: pertahankan di satu tempat per alur (rincian transaksi dan
      dompet, pemakaian pertama); kosakata tombol "Catat…" sudah membawa
      maknanya (NFR-UX-005 tetap terpenuhi).
- [ ] **UX-10** 🟡⛔ [E] **Bilah progres anggaran: warna dan laju waktu.**
      `AppSegmentedProgressBar.colorFor` memakai `income` (hijau = uang
      masuk, ADR-016) untuk pemakaian sehat; ADR-016 baris 136 mencatatnya
      "belum diputuskan". Bilah juga tidak menjawab "apakah aku masih di
      jalur".
      Usulan: netral untuk sehat, amber mendekati batas, merah hanya lewat
      rencana; tambahkan penanda laju ("terpakai 60%, periode berjalan 40%")
      di kartu anggaran Beranda dan rincian anggaran. Catat keputusan di
      ADR-016.
- [ ] **UX-11** 🟡 [B] **Menu pilihan dompet hanya menampilkan nama.**
      Terlihat di render: saldo baru tampil sesudah dompet dipilih.
      Perbaikan: saldo kecil di tiap baris menu `WalletSelectField`.
- [ ] **UX-12** 🟡 [F] **Elemen yang bisa diketuk tanpa label semantik.**
      `GestureDetector` tanpa `Semantics` di `freelance_cards.dart:250`,
      `wallet_detail_page.dart:240` (baris kembali), dan
      `project_widgets.dart:185,293`. Tautan "Atau buat anggaran" di Beranda
      kosong tergabung ke label kartu sehingga tidak bisa diaktifkan
      tersendiri oleh pembaca layar.
      Perbaikan: bungkus dengan `Semantics(button: true, label: …)`; pisahkan
      semantik tautan di kartu kosong.
- [ ] **UX-13** 🟡 [A] **Slot CATAT di navigasi bawah tidak menonjol.**
      `app_shell_page.dart` — tampil setara empat tab lain, padahal prinsip
      produk #5 menjadikannya tindakan utama.
      Perbaikan: penekanan visual (kotak aksen terracotta atau ukuran lebih
      besar) sesuai ADR-015.
      Catatan review UI: ADR-015 baris 182 sudah menetapkan "FAB CATAT"
      berelevasi interaktif, jadi item ini **menyelaraskan kode dengan ADR
      yang berlaku**, bukan keputusan baru. Label tab 10px juga masuk UX-15.

## UI: penekanan, warna, tipografi, tata letak

Sembilan item dari review UI. Enam di antaranya terkunci sampai
[ADR-020](../02-architecture/adr/0020-hierarki-penekanan-bahasa-visual-pixel.md)
disetujui, karena mengubah cara komponen ADR-015 dipakai. Tiga lainnya
menegakkan aturan yang sudah berlaku dan bisa dikerjakan sekarang.

- [ ] **UX-14** 🟠⛔ [E] **Semua tombol memakai penekanan tertinggi.**
      `app_button.dart` hanya punya satu gaya (isian, garis tepi 2px,
      bayangan keras), dipakai 40 kali; tidak ada gaya bergaris tepi atau
      tonal. "Simpan", "Hapus", "Tambah Dompet Baru", dan "Buat Anggaran
      Baru" sama kuatnya; Beranda kosong punya dua ajakan dompet yang
      bersaing.
      Perbaikan (ADR-020 §3.1): varian `primary`/`secondary`/`tertiary`,
      bawaan `primary`; paling banyak satu `primary` per layar. Tinjau 40
      titik pakai.
      Verifikasi: uji widget tiap varian; render tiap tab.
- [ ] **UX-15** 🟠⛔ [F] **Label mikro terlalu kecil dan terlalu sering kapital.**
      `kind_surfaces.dart:58` — `transactionLabelStyle` bawaan 10px, dipakai
      112 kali (sekitar 78 di 10px, 10 di 9px); 71 `toUpperCase()`. Label
      navigasi bawah 10px (`pixel_theme.dart:115`).
      Perbaikan (ADR-020 §3.2): bawaan 11px, tidak ada label di bawah 11px;
      kapital hanya untuk lencana dan kop 1–3 kata.
      Verifikasi: render 360dp dan 390dp, tidak ada teks terpotong baru.
- [ ] **UX-16** 🟡⛔ [E] **Empat penanda merah di satu baris transaksi.**
      Garis aksen, kotak ikon, nominal, dan lencana "−KELUAR" sekaligus
      (`TransactionRow`, `transaction_date_group_card.dart`). Daftar
      pengeluaran jadi dinding merah dan merah kehilangan fungsi sinyalnya.
      Perbaikan (ADR-020 §3.3): tanda `−` dan warna nominal, ditambah satu
      penanda jenis; lencana hanya di rincian.
- [ ] **UX-17** 🟠 [E] **Snackbar sukses memakai hijau "uang masuk".**
      `snackbar_effect_handler.dart:18` — `success → colors.income`.
      "Pengeluaran tercatat." tampil hijau, bertentangan dengan ADR-016.
      Perbaikan: latar netral (`textPrimary`, teks `background`) dengan ikon
      centang; galat tetap `expense`. Menegakkan ADR-016, tidak terkunci.
      Verifikasi: uji widget warna snackbar per `FeedbackSeverity`.
- [ ] **UX-18** 🟡⛔ [E] **Bilah bersegmen punya dua arti.**
      `transaction_month_header.dart:183` memakai bilah untuk proporsi
      masuk/keluar tanpa legenda; di anggaran bilah yang sama berarti
      terpakai dari rencana. Dengan satu pengeluaran, bilah penuh merah dan
      terbaca "anggaran habis".
      Perbaikan (ADR-020 §3.5): ganti dengan angka Masuk dan Keluar kecil di
      bawah Netto.
- [ ] **UX-19** 🟠 [E] **Ikon jenis transaksi nyaris hilang di mode gelap.**
      Terlihat di render gelap: ikon pixel di kotak Pemasukan/Pengeluaran
      Beranda dan kotak ikon baris transaksi berkontras rendah. Uji kontras
      otomatis (`app_colors_extension_test.dart`) hanya mencakup teks.
      Perbaikan: isian kotak ikon mode gelap lebih terang (alfa `…Fill` lebih
      tinggi) atau bingkai terang tipis. Menegakkan NFR-UX-003.
      Verifikasi: render mode gelap Beranda dan Transaksi.
- [ ] **UX-20** 🟡⛔ [A] **Kartu dompet terlalu tinggi untuk isinya.**
      `wallet_card.dart` — sekitar 130px untuk nama, jenis, dan saldo; tiga
      dompet memenuhi layar, dan "SALDO AKTIF" diulang di tiap kartu.
      Perbaikan: varian baris ringkas (64–72px: ikon, nama dan jenis, saldo
      rata kanan) di daftar; kartu besar cukup di rincian dompet.
- [ ] **UX-21** 🟡⛔ [A] **Kop Transaksi sekitar 480px sebelum isi pertama.**
      Konsol bulan, kartu utama, kolom cari, dua dropdown, dan empat tab
      jenis; transaksi pertama baru di y≈520 pada layar 844.
      Perbaikan: gabungkan penyaring dompet dan kategori ke satu tombol
      "Filter" yang membuka lembar; kartu utama lebih pendek (tanpa bilah,
      lihat UX-18).
- [ ] **UX-22** 🟡 [D] **Label ganda untuk satu angka.**
      Kartu arus Beranda (`home_cards.dart`, `_FlowTile`): "PEMASUKAN SEP",
      lalu "+ MASUK", lalu nominal. Label kedua mubazir karena tanda `+`/`−`
      sudah ada di nominal.
      Perbaikan: hapus label kedua beserta kunci i18n-nya bila tak terpakai.

## Di luar cakupan review UX

Temuan berikut kemungkinan bug korektnes, bukan UX. Cek dengan skill
`code-review` sebelum diperlakukan sebagai tugas.

- **Pengisian ulang nominal saat menyunting memotong sen.**
  `expense_form_sheet.dart:98,103`, `income_form_sheet.dart:79`,
  `transfer_form_sheet.dart:104,109` memakai `amount ~/ 100`. Nominal
  berpecahan sen akan kehilangan pecahannya diam-diam saat disimpan ulang.

## Sumber riset

Pola pembanding diambil dari sumber berikut. Angka persentase retensi di
artikel blog tidak dikutip karena metodologinya tidak jelas; yang dipakai
hanya pola kualitatifnya.

- [Confirmation Dialogs Can Prevent User Errors — NN/g](https://www.nngroup.com/articles/confirmation-dialog/)
- [User Control and Freedom — NN/g](https://www.nngroup.com/articles/user-control-and-freedom/)
- [Designing Empty States in Complex Applications — NN/g](https://www.nngroup.com/articles/empty-state-interface-design/)
- [Money Manager: How to make a bookmark — Realbyte](https://help.realbyteapps.com/hc/en-us/articles/360043328873-How-to-make-a-bookmark)
- [Monarch vs YNAB — Monarch](https://www.monarch.com/compare/ynab-alternative)
- [Copilot Money Review 2026 — The Penny Hoarder](https://www.thepennyhoarder.com/budgeting/budgeting-copilot-money-review/)
- [Why People Quit Budgeting Apps in 30 Days — SpendTrak](https://spendtrak.app/blog/why-people-quit-budgeting-apps)
- [How Great Budget App Design Increases User Retention — Onething](https://www.onething.design/post/budget-app-design)
- [Visual Hierarchy in UX: Definition — NN/g](https://www.nngroup.com/articles/visual-hierarchy-ux-definition/)
- [5 Principles of Visual Design in UX — NN/g](https://www.nngroup.com/articles/principles-visual-design/)
- [Typography for Glanceable Reading — NN/g](https://www.nngroup.com/articles/glanceable-fonts/)
- [All Caps — Stanford University](https://uit.stanford.edu/accessibility/learn-about/typography/all-caps)
- [Buttons — Material Design 3](https://m3.material.io/components/buttons/guidelines)
- [The elements of fintech typography: readable money — Bootcamp](https://medium.com/design-bootcamp/the-elements-of-fintech-typography-part-1-readable-money-b6c1226acbde)
- [Fintech App Design: Balance and Transactions Screen — floow.design](https://www.floow.design/blog/how-to-design-a-fintech-app-screen)
