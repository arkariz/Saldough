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

Terakhir diperbarui: 28 September 2026.

| Tingkat | Item | Selesai |
|---|---|---|
| 🟠 Friksi | 12 | 12 |
| 🟡 Polish | 10 | 10 |
| **Total** | **22** | **22** |

Semua keputusan pemilik yang dibutuhkan sudah dijawab 28 Sep 2026 (lihat
bagian di bawah). ADR-020 disetujui dan dikerjakan penuh (UX-14, UX-15,
UX-16, UX-18, UX-20, UX-21), beserta UX-10, UX-4, dan UX-8. **UX-1**
dikerjakan bersama T-9.6 Fase 9 (28 Sep 2026), jadi seluruh 22 item
selesai.

## Keputusan pemilik yang dibutuhkan

Empat item mengubah alur atau aturan yang sudah disepakati. Jangan dikerjakan
sebelum pemilik memilih. Hapus tanda ⛔ dan catat keputusannya di item begitu
dijawab.

- ~~**UX-1**~~ — diputuskan 27 Sep 2026 lewat KO-5 ONBOARDING_PLAN: langsung
  ke formulir Pengeluaran dengan pengalih jenis.
- ~~**UX-4**~~ — diputuskan 28 Sep 2026: **tombol "Catat lagi" saja** di
  rincian transaksi (bukan juga favorit transaksi tersimpan).
- ~~**UX-8**~~ — diputuskan 28 Sep 2026: **ganti ke Urungkan** — hapus
  transaksi langsung tanpa dialog, snackbar Urungkan mengembalikannya.
  Konfirmasi tetap untuk hapus dompet, anggaran, dan proyek.
- ~~**UX-10**~~ — diputuskan 28 Sep 2026: **terapkan usulan penuh** — warna
  netral/amber/merah menggantikan hijau, DAN penanda laju waktu periode.
- ~~**ADR-020**~~ — **disetujui apa adanya** 28 Sep 2026. Membuka UX-14,
  UX-15, UX-16, UX-18, UX-20, UX-21.

## Friksi

Delapan item berikut memperlambat atau membingungkan tugas harian, terutama
mencatat. Urutannya dari dampak terbesar.

- [x] **UX-1** 🟠 [B] **CATAT selalu melewati lembar pilihan layar penuh.**
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
      **Diputuskan 27 Sep 2026 (KO-5):** CATAT langsung ke formulir
      Pengeluaran dengan pengalih tiga segmen; lembar pilihan dihapus;
      edukasinya pindah ke onboarding dan tur CATAT. Dikerjakan bersama T-9.6
      ([ONBOARDING_PLAN.md](ONBOARDING_PLAN.md)).
      ✅ Selesai (28 Sep 2026, T-9.6): `openRecordSheet` membuka satu
      `RecordFormHost` yang langsung berisi formulir Pengeluaran, dengan
      `RecordKindSwitcher` (Keluar | Masuk | Transfer, `AppSegmented` yang
      dipindah dari fitur budget) di bawah kop. `RecordChoiceSheet`, loop
      pilihan, dan `BackToChoice` dihapus; tombol kembali menutup CATAT.
      `initialChoice`/`prefillFrom` menentukan segmen awal. Label langkah
      jadi "Catat // Transaksi". Edukasinya pindah ke OB-3 dan tur CATAT.
      Uji shell: satu ketukan ke formulir, pengalih mengganti formulir,
      kembali menutup alur.
- [x] **UX-2** 🟠 [B] **Dompet tidak pernah terisi otomatis.**
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
      ✅ Selesai 27 Sep 2026: `RecordDefaults` (dari
      `listRecentTransactions(100)` di `RecordBloc`) dan `initialWalletFor` —
      pintasan menang, lalu satu-satunya dompet aktif, lalu dompet terakhir per
      jenis (transfer: pasangan asal/tujuan terakhir). Diuji unit, bloc, dan
      uji shell.
- [x] **UX-3** 🟠 [B] **Kategori tidak belajar dari riwayat.**
      `expense_form_sheet.dart:22-28` — saran kategori daftar tetap. Kategori
      yang diketik lewat "Lainnya" harus diketik ulang tiap kali, dan ejaan
      berbeda ("listrik" vs "Listrik PLN") memecah penyaring kategori layar
      Transaksi.
      Perbaikan: gabungkan saran bawaan dengan kategori paling sering dipakai
      untuk jenis itu (dari transaksi yang sudah dimuat), tanpa duplikat
      beda huruf besar-kecil.
      Verifikasi: uji unit fungsi penggabung saran.
      ✅ Selesai: kategori riwayat per jenis (paling sering, beda huruf
      digabung) lewat `mergeCategorySuggestions`, ditawarkan sebelum saran
      bawaan.
- [x] **UX-4** 🟠 [B] **Tidak ada "catat ulang" untuk transaksi rutin.**
      Belanja mingguan, token listrik, dan sejenisnya diisi dari nol.
      Usulan minimum: tombol **Catat lagi** di rincian transaksi yang membuka
      `openRecordSheet` dengan jenis, dompet, kategori, nominal, dan catatan
      terisi, tanggal hari ini. Perluasan (keputusan pemilik): favorit
      transaksi tersimpan.
      Verifikasi: uji widget rincian → formulir terisi.
      ✅ Selesai (28 Sep 2026), keputusan pemilik: **tombol "Catat lagi"
      saja**, tanpa favorit transaksi tersimpan. `openRecordSheet` menerima
      parameter baru `prefillFrom` (jenis diturunkan dari tipe transaksinya,
      lewati lembar pilihan) yang menuju param baru `prefill` di ketiga
      formulir CATAT -- BEDA dari `initial` (mode sunting): formulir terisi
      awal (nominal, kategori, catatan, dompet, pos anggaran) tapi TETAP
      mode CATAT (judul dan tombol tidak berubah jadi "Simpan Perubahan")
      dan tanggalnya tetap HARI INI, bukan tanggal transaksi sumber --
      menghasilkan transaksi baru, bukan menimpa yang lama.
      Tombol `AppButton.secondary` (ADR-020, bukan primary kedua di layar
      yang sama dengan "Ubah Catatan Ini") ditambahkan di
      `TransactionDetailPage`, disembunyikan untuk transaksi milik
      pembayaran freelance (sama seperti ubah/hapus). Pos anggaran yang
      tidak lagi berlaku untuk tanggal hari ini otomatis tidak ikut terisi
      (memakai ulang `_validBudgetItemId`/`expenseBudgetChoicesFor` yang
      sudah ada, T-8.1). Kalau dompet transaksi sumber sudah nonaktif,
      dropdown dompet formulir tampil kosong -- pemakai memilih dompet baru
      (dompet nonaktif memang tidak ditawarkan CATAT).
      Diuji: widget test rincian transaksi -- "Catat lagi" membuka formulir
      CATAT (bukan lembar sunting) terisi nominal dan kategori dari
      transaksi sumber, menyimpan menghasilkan DUA transaksi (lama tetap
      ada) dan saldo terpotong dua kali.
- [x] **UX-5** 🟠 [D] **Komponen bawaan Material tetap berbahasa Inggris.**
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
      ✅ Selesai: `flutter_localizations`, `SaldoughApp.localizationsDelegates`,
      `locale`/`supportedLocales` dari slang. Uji pemilih tanggal berbahasa
      Indonesia.
- [x] **UX-6** 🟠 [B] **Pencarian Transaksi hanya mencakup bulan terbuka.**
      `transaction_bloc.dart:119` memuat satu bulan; petunjuk "Cari catatan /
      kategori..." tidak menyebutnya. Mencari tagihan bulan lalu tidak
      menemukan apa pun.
      Perbaikan langkah 1: ubah petunjuk dan keadaan kosong penyaring jadi
      menyebut "di bulan ini". Langkah 2 (opsional, catat sebagai tugas
      baru): mode pencarian lintas bulan.
      Verifikasi: kunci i18n `id`/`en`, uji widget keadaan kosong.
      ✅ Langkah 1 selesai: petunjuk cari dan keadaan kosong penyaring menyebut
      "bulan ini". Langkah 2 dicatat sebagai T-8.2.
- [x] **UX-7** 🟠 [A] **Beranda kosong punya ajakan buntu dan ganda.**
      `home_cards.dart:498` — tautan "Atau buat anggaran pengeluaran" tampil
      walau belum ada dompet, lalu layar Anggaran berkata "Buat dompet dulu".
      Kartu saldo dan kartu kosong sama-sama mengajak membuat dompet
      ("+ Dompet" dan "Buat Dompet Pertama").
      Perbaikan: sembunyikan tautan anggaran selama `hasNoWallets`; sisakan
      satu ajakan membuat dompet.
      Verifikasi: uji widget Beranda tanpa dompet.
      ✅ Selesai: tautan anggaran disembunyikan tanpa dompet; pil "+ Dompet" di
      kartu saldo dihapus, tersisa "Buat Dompet Pertama".
- [x] **UX-8** 🟠 [C] **Hapus transaksi lewat dialog, tanpa Urungkan.**
      Tujuh titik `showConfirmDelete`, termasuk
      `transaction_detail_page.dart:87`. Menghapus transaksi mengubah saldo;
      konfirmasi yang terlalu sering membuat orang menekan "Hapus" tanpa
      membaca (NN/g).
      Usulan: hapus transaksi langsung, lalu snackbar **Urungkan** beberapa
      detik yang menyimpan ulang transaksi yang sama (id sama, saldo
      dihitung ulang). Konfirmasi dipertahankan untuk aksi yang tak bisa
      dibalik.
      Verifikasi: uji bloc hapus → urungkan mengembalikan saldo persis.
      ✅ Selesai (28 Sep 2026), keputusan pemilik: **ganti ke Urungkan**,
      HANYA untuk transaksi -- enam titik `showConfirmDelete` lain (dompet,
      anggaran, template, proyek, entri worklog, pembayaran, batalkan
      penerimaan) TETAP memakai dialog konfirmasi, tidak disentuh.
      `TransactionDetailPage._delete` menghapus langsung (tanpa
      `showConfirmDelete`) lalu menutup layar; `TransactionBloc._onDeleted`
      memancarkan `CallbackEffect` (framework `state_management`, sudah
      terdaftar global) yang menampilkan `SnackBar` berlatar netral dengan
      aksi "Urungkan" selama 5 detik -- BUKAN
      `ShowSnackBarEffect.actionLabel`/`actionIntentId`, yang menurut
      catatan `snackbar_effect_handler.dart` sendiri memang belum
      disambungkan ke bloc mana pun (keputusan mekanisme yang diminta
      catatan itu: pakai `CallbackEffect` yang sudah ada, bukan
      menyambungkan mekanisme baru). Menekan "Urungkan" mengirim event baru
      `TransactionRestored`, yang menyimpan ulang transaksi (id sama) lewat
      `RecordTransaction` biasa (bukan use case baru) dan menghitung ulang
      saldo dompet yang tersentuh.
      Kunci i18n `transaction.deleteConfirmTitle`/`deleteConfirmMessage`
      yang jadi tak terpakai dihapus; kunci baru
      `undoDeleteAction`/`restoredMessage`.
      Diuji: bloc (`CallbackEffect` dipancarkan sesudah hapus;
      `TransactionRestored` mengembalikan saldo persis dan HANYA menulis
      ulang transaksi, tidak mencatat transaksi baru) dan widget (hapus
      langsung tanpa dialog lalu menampilkan snackbar Urungkan; menekan
      Urungkan mengembalikan baris dan saldo, `listAllTransactions` tetap
      satu transaksi).

## Polish

Lima item berikut soal konsistensi dan aksesibilitas. Tidak menghalangi
tugas, tetapi murah dan menaikkan kualitas terasa.

- [x] **UX-9** 🟡 [D] **Penafian "hanya mencatat" berulang di banyak tempat.**
      Lembar pilihan (`t.record.disclaimerMessage`), kartu aturan tiap
      formulir (`expense_form_sheet.dart:169`, `transfer_form_sheet.dart:185`),
      catatan kaki tiap formulir (`record_form_frame.dart:78`), rincian
      transaksi, rincian dompet, dan kartu aturan freelance. Pengulangan
      membuat pesannya diabaikan.
      Perbaikan: pertahankan di satu tempat per alur (rincian transaksi dan
      dompet, pemakaian pertama); kosakata tombol "Catat…" sudah membawa
      maknanya (NFR-UX-005 tetap terpenuhi).
      ✅ Selesai: catatan kaki `footnote` di tiap formulir CATAT dihapus.
      Penafian tetap di lembar pilihan CATAT, rincian transaksi, dan rincian
      dompet; kartu aturan jenis (mis. saldo terpotong) dipertahankan karena
      menjelaskan aturan, bukan penafian.
- [x] **UX-10** 🟡 [E] **Bilah progres anggaran: warna dan laju waktu.**
      `AppSegmentedProgressBar.colorFor` memakai `income` (hijau = uang
      masuk, ADR-016) untuk pemakaian sehat; ADR-016 baris 136 mencatatnya
      "belum diputuskan". Bilah juga tidak menjawab "apakah aku masih di
      jalur".
      Usulan: netral untuk sehat, amber mendekati batas, merah hanya lewat
      rencana; tambahkan penanda laju ("terpakai 60%, periode berjalan 40%")
      di kartu anggaran Beranda dan rincian anggaran. Catat keputusan di
      ADR-016.
      ✅ Selesai (28 Sep 2026): sisi sehat `AppSegmentedProgressBar.colorFor`
      diganti `textPrimary` (netral) dari `income` -- amber (`pending`)
      mendekati batas dan merah (`overBudget`) lewat rencana tidak berubah.
      Penanda laju waktu baru `Budget.elapsedRatio(now)` (domain, fraksi
      periode yang berlalu) dipakai di rincian anggaran (`budget_detail_page.dart`,
      baris baru "Periode berjalan (X%)" di bawah bilah progres).
      ⚠ **Sebagian**: penanda laju TIDAK ditambahkan ke kartu anggaran
      Beranda -- `BudgetOverview` (port `BudgetOverviewSource`) mengagregasi
      SEMUA anggaran aktif jadi satu total tanpa periode tunggal (anggaran
      berbeda boleh berbeda periode/tanggal mulai sekaligus), jadi "laju
      waktu" gabungan tidak punya makna tunggal yang jujur tanpa keputusan
      produk baru (mis. anggaran mana yang jadi acuan, atau bagaimana
      merata-ratakannya) -- di luar cakupan perbaikan UX murni. Kartu
      Beranda tetap menampilkan warna netral/amber/merah yang benar dari
      `colorFor`.
- [x] **UX-11** 🟡 [B] **Menu pilihan dompet hanya menampilkan nama.**
      Terlihat di render: saldo baru tampil sesudah dompet dipilih.
      Perbaikan: saldo kecil di tiap baris menu `WalletSelectField`.
      ✅ Selesai: `AppMenuSelectButton.detailFor`; saldo tampil di bawah nama
      dompet (bukan rata kanan, supaya tidak meluap di 360dp/teks 2x).
- [x] **UX-12** 🟡 [F] **Elemen yang bisa diketuk tanpa label semantik.**
      `GestureDetector` tanpa `Semantics` di `freelance_cards.dart:250`,
      `wallet_detail_page.dart:240` (baris kembali), dan
      `project_widgets.dart:185,293`. Tautan "Atau buat anggaran" di Beranda
      kosong tergabung ke label kartu sehingga tidak bisa diaktifkan
      tersendiri oleh pembaca layar.
      Perbaikan: bungkus dengan `Semantics(button: true, label: …)`; pisahkan
      semantik tautan di kartu kosong.
      ✅ Selesai: `AppTappable` (Semantics tombol + GestureDetector) di baris
      kembali tiga layar rincian, kartu pembayaran freelance, kartu dompet, dan
      baris transaksi; `project_widgets` sudah bersemantik. Tautan kartu kosong
      Beranda jadi simpul semantik sendiri (`container: true`).
- [x] **UX-13** 🟡 [A] **Slot CATAT di navigasi bawah tidak menonjol.**
      `app_shell_page.dart` — tampil setara empat tab lain, padahal prinsip
      produk #5 menjadikannya tindakan utama.
      Perbaikan: penekanan visual (kotak aksen terracotta atau ukuran lebih
      besar) sesuai ADR-015.
      Catatan review UI: ADR-015 baris 182 sudah menetapkan "FAB CATAT"
      berelevasi interaktif, jadi item ini **menyelaraskan kode dengan ADR
      yang berlaku**, bukan keputusan baru. Label tab 10px juga masuk UX-15.
      ✅ Selesai: ikon CATAT di navigasi bawah jadi kotak `accent` bergaris tepi
      2px dan bayangan keras level Interaktif ADR-015.

## UI: penekanan, warna, tipografi, tata letak

Sembilan item dari review UI, semuanya selesai. Enam (UX-14, UX-15, UX-16,
UX-18, UX-20, UX-21) menunggu persetujuan
[ADR-020](../02-architecture/adr/0020-hierarki-penekanan-bahasa-visual-pixel.md)
karena mengubah cara komponen ADR-015 dipakai -- disetujui dan dikerjakan
28 Sep 2026. Tiga lainnya (UX-13, UX-17, UX-19) menegakkan aturan yang
sudah berlaku dan sudah selesai lebih dulu.

- [x] **UX-14** 🟠 [E] **Semua tombol memakai penekanan tertinggi.**
      `app_button.dart` hanya punya satu gaya (isian, garis tepi 2px,
      bayangan keras), dipakai 40 kali; tidak ada gaya bergaris tepi atau
      tonal. "Simpan", "Hapus", "Tambah Dompet Baru", dan "Buat Anggaran
      Baru" sama kuatnya; Beranda kosong punya dua ajakan dompet yang
      bersaing.
      Perbaikan (ADR-020 §3.1): varian `primary`/`secondary`/`tertiary`,
      bawaan `primary`; paling banyak satu `primary` per layar. Tinjau 40
      titik pakai.
      Verifikasi: uji widget tiap varian; render tiap tab.
      ✅ Selesai (28 Sep 2026): `AppButton` punya `AppButtonVariant`
      (`primary`/`secondary`/`tertiary`, bawaan `primary`) -- `secondary`
      kini TANPA bayangan (elevasi 0, sebelumnya ikut memakai bayangan keras
      primary) dan menerima `textColor` untuk aksi destruktif; `tertiary`
      baru (tautan teks tanpa bingkai, pola `HomeTextLink`). Tujuh tombol
      hapus isian merah (`color: colors.expense`) di formulir sunting
      (dompet, entri worklog, proyek, potongan, pos anggaran, template,
      anggaran) diganti `AppButton.secondary(textColor: colors.expense)` --
      isian merah solid dipertahankan HANYA kalau memang di dalam dialog
      konfirmasi (tidak ada, `showConfirmDelete` sudah `TextButton` polos).
      Dua pelanggaran "satu primary per layar" ditemukan dan diperbaiki:
      bilah bawah rincian proyek freelance ("+ Worklog" dan "Tagih (n)"
      tampil bersamaan -- "+ Worklog" analog "Tambah pos" jadi secondary,
      "Tagih" tetap primary sebagai aksi penyelesaian); footer "Tambah
      Template" di layar Template Anggaran (bersaing dengan "Pakai Template
      Ini" tiap kartu) jadi secondary.
- [x] **UX-15** 🟠 [F] **Label mikro terlalu kecil dan terlalu sering kapital.**
      `kind_surfaces.dart:58` — `transactionLabelStyle` bawaan 10px, dipakai
      112 kali (sekitar 78 di 10px, 10 di 9px); 71 `toUpperCase()`. Label
      navigasi bawah 10px (`pixel_theme.dart:115`).
      Perbaikan (ADR-020 §3.2): bawaan 11px, tidak ada label di bawah 11px;
      kapital hanya untuk lencana dan kop 1–3 kata.
      Verifikasi: render 360dp dan 390dp, tidak ada teks terpotong baru.
      ✅ Sebagian selesai (28 Sep 2026): `transactionLabelStyle` menjepit
      [size] ke minimum `kMinLabelSize` (11px, `pixel_theme.dart`) --
      seluruh pemanggil `size: 9` (7 titik) otomatis naik ke 11px tanpa
      perlu disunting satu-satu. Label navigasi bawah (`pixel_theme.dart:115`)
      juga naik ke 11px. Kenaikan ini menyebabkan satu regresi nyata:
      `HomeSectionHeader` (dipakai `HomeGuide`) meluap 18px di 360px+teks 2x
      karena `trailing`-nya tidak dibungkus `Flexible` -- diperbaiki
      (`Flexible` + `overflow: ellipsis`), diuji lewat suite Freelance yang
      kebetulan melewati Beranda. **Belum dikerjakan**: audit "kapital hanya
      untuk lencana dan kop 1–3 kata" terhadap 71 pemanggilan
      `toUpperCase()` -- itu tinjauan per-kasus (mana yang lencana/kop
      pendek vs label lebih panjang), bukan perubahan mekanis seperti
      kenaikan ukuran, dan disengaja ditunda supaya tidak menghabiskan
      anggaran token untuk sapuan 71 titik dengan risiko regresi visual
      yang tinggi per titik.
- [x] **UX-16** 🟡 [E] **Empat penanda merah di satu baris transaksi.**
      Garis aksen, kotak ikon, nominal, dan lencana "−KELUAR" sekaligus
      (`TransactionRow`, `transaction_date_group_card.dart`). Daftar
      pengeluaran jadi dinding merah dan merah kehilangan fungsi sinyalnya.
      Perbaikan (ADR-020 §3.3): tanda `−` dan warna nominal, ditambah satu
      penanda jenis; lencana hanya di rincian.
      ✅ Selesai (28 Sep 2026): garis aksen kiri (`ColoredBox`) dan lencana
      `_TypeBadge` dihapus dari `TransactionRow` -- satu-satunya penanda
      warna jenis yang tersisa di baris daftar adalah kotak ikon (`iconTile`),
      ditambah tanda `+`/`−` dan warna pada nominal (tidak dihitung sebagai
      penanda terpisah, itu baseline wajib ADR-020). Lencana jenis tetap
      ada di layar rincian transaksi (tidak disentuh). Kunci i18n
      `transaction.{income,expense,transfer}Badge` yang jadi tak terpakai
      ikut dihapus (padanan `record.*Badge` untuk formulir CATAT TETAP ada,
      beda namespace).
- [x] **UX-17** 🟠 [E] **Snackbar sukses memakai hijau "uang masuk".**
      `snackbar_effect_handler.dart:18` — `success → colors.income`.
      "Pengeluaran tercatat." tampil hijau, bertentangan dengan ADR-016.
      Perbaikan: latar netral (`textPrimary`, teks `background`) dengan ikon
      centang; galat tetap `expense`. Menegakkan ADR-016, tidak terkunci.
      Verifikasi: uji widget warna snackbar per `FeedbackSeverity`.
      ✅ Selesai: sukses berlatar `textPrimary` dengan ikon centang. Uji warna
      per severity.
- [x] **UX-18** 🟡 [E] **Bilah bersegmen punya dua arti.**
      `transaction_month_header.dart:183` memakai bilah untuk proporsi
      masuk/keluar tanpa legenda; di anggaran bilah yang sama berarti
      terpakai dari rencana. Dengan satu pengeluaran, bilah penuh merah dan
      terbaca "anggaran habis".
      Perbaikan (ADR-020 §3.5): ganti dengan angka Masuk dan Keluar kecil di
      bawah Netto.
      ✅ Selesai (28 Sep 2026): `_ShareBar` (bilah bersegmen kop Transaksi)
      dihapus, diganti `_FlowNumbers` -- dua angka kecil "MASUK Rp…" / "KELUAR
      Rp…" berwarna `income`/`expense` di bawah Netto. `AppSegmentedProgressBar`
      kini HANYA dipakai untuk progres anggaran (Beranda, Anggaran,
      rincian). Kunci i18n baru `transaction.flowIncomeLabel`/`flowExpenseLabel`.
- [x] **UX-19** 🟠 [E] **Ikon jenis transaksi nyaris hilang di mode gelap.**
      Terlihat di render gelap: ikon pixel di kotak Pemasukan/Pengeluaran
      Beranda dan kotak ikon baris transaksi berkontras rendah. Uji kontras
      otomatis (`app_colors_extension_test.dart`) hanya mencakup teks.
      Perbaikan: isian kotak ikon mode gelap lebih terang (alfa `…Fill` lebih
      tinggi) atau bingkai terang tipis. Menegakkan NFR-UX-003.
      Verifikasi: render mode gelap Beranda dan Transaksi.
      ✅ Selesai: `AppColorsExtension.iconTile` — mode gelap memakai latar
      pastel terang; dipakai kotak ikon Beranda, baris transaksi, CATAT, dan
      Freelance. Uji kontras garis ikon >= 3:1 di kedua mode (mutasi: perilaku
      lama gagal 5 kasus gelap). Dicek di emulator mode gelap.
- [x] **UX-20** 🟡 [A] **Kartu dompet terlalu tinggi untuk isinya.**
      `wallet_card.dart` — sekitar 130px untuk nama, jenis, dan saldo; tiga
      dompet memenuhi layar, dan "SALDO AKTIF" diulang di tiap kartu.
      Perbaikan: varian baris ringkas (64–72px: ikon, nama dan jenis, saldo
      rata kanan) di daftar; kartu besar cukup di rincian dompet.
      ✅ Selesai (28 Sep 2026): `WalletCard` dirombak jadi satu baris (ikon
      40px, nama + jenis/status di bawahnya, nominal rata kanan lebar
      dijepit 130px mengikuti pola kolom nominal `TransactionRow`, lalu
      panah). Kotak lencana `_Badge` dan baris "SALDO AKTIF" berulang
      dihapus dari daftar (kartu besar berlabel tetap di `WalletDetailPage`,
      tidak disentuh). Kunci i18n `wallet.balanceLabel` yang jadi tak
      terpakai ikut dihapus.
      ⚠ Baris dibungkus `IntrinsicHeight` (pola sama dengan
      `TransactionRow`) -- tanpa ini `FittedBox` nominal menerima tinggi tak
      terhingga dari `Row` dan meluap horizontal secara tidak kentara,
      ketahuan uji 360px+teks 2x+nama panjang. Baris jenis/status memakai
      `Wrap`, bukan `Row`, karena label jenis dompet ID ("Bank / Rekening")
      tidak selalu muat sebaris pada kolom yang menyempit akibat nominal di
      sebelahnya.
- [x] **UX-21** 🟡 [A] **Kop Transaksi sekitar 480px sebelum isi pertama.**
      Konsol bulan, kartu utama, kolom cari, dua dropdown, dan empat tab
      jenis; transaksi pertama baru di y≈520 pada layar 844.
      Perbaikan: gabungkan penyaring dompet dan kategori ke satu tombol
      "Filter" yang membuka lembar; kartu utama lebih pendek (tanpa bilah,
      lihat UX-18).
      ✅ Selesai (28 Sep 2026): kartu utama sudah lebih pendek lewat UX-18
      (bilah bersegmen kop Transaksi diganti dua angka kecil). Baris
      `TransactionWalletCategoryRow` (dua dropdown berdampingan) dihapus,
      digantikan `TransactionFilterButton` -- satu tombol 44×44 di samping
      kolom cari (bukan baris sendiri di bawahnya, menghilangkan satu baris
      penuh) yang membuka `_TransactionFilterSheet` berisi kedua dropdown
      lama (`AppMenuSelectButton` dompet dan kategori, ditata vertikal) plus
      tombol "Selesai". Tombol Filter menampilkan lencana angka (0/1/2)
      untuk jumlah filter aktif. Kunci i18n baru `transaction.filterButtonLabel`/
      `filterSheetTitle`/`filterSheetDoneAction`. Diuji: tombol membuka
      lembar, memilih dompet menyaring daftar dan menampilkan lencana "1"
      (widget test baru); uji `WalletDetailPage` yang sebelumnya mengecek
      label dompet terpilih langsung di halaman diperbarui mengecek lencana
      tombol Filter sebagai gantinya, karena label itu sekarang di dalam
      lembar, bukan di halaman.
- [x] **UX-22** 🟡 [D] **Label ganda untuk satu angka.**
      Kartu arus Beranda (`home_cards.dart`, `_FlowTile`): "PEMASUKAN SEP",
      lalu "+ MASUK", lalu nominal. Label kedua mubazir karena tanda `+`/`−`
      sudah ada di nominal.
      Perbaikan: hapus label kedua beserta kunci i18n-nya bila tak terpakai.
      ✅ Selesai: label "+ Masuk"/"− Keluar" dihapus beserta kuncinya; nominal
      kini bertanda `+`/`−`.

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
