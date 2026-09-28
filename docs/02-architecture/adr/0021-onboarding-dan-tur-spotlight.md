# Onboarding, tur spotlight, dan lapis info

## 1. Metadata

- **Decision ID:** ADR-021
- **Tanggal:** 2026-09-28
- **Fase roadmap:** Fase 9 (T-9.1)
- **Status:** Proposed (menunggu tinjauan pemilik)
- **Cakupan:** Global — gerbang saat aplikasi dibuka, penyimpanan progres
  tutorial, komponen spotlight, bahasa gerak (motion), alur CATAT (UX-1).
- **Berkaitan:** [ONBOARDING_PLAN.md](../../04-planning/ONBOARDING_PLAN.md)
  (konten, key spotlight, keputusan KO-1..KO-7),
  [ONBOARDING_ART_BRIEF.md](../../04-planning/ONBOARDING_ART_BRIEF.md),
  [ADR-015](0015-adopsi-bahasa-visual-pixel-kas.md),
  [ADR-016](0016-revisi-palet-satu-peran-satu-warna.md),
  [ADR-020](0020-hierarki-penekanan-bahasa-visual-pixel.md),
  [UX-1](../../04-planning/UX_REVIEW_FIXES.md).

## 2. Konteks

Pemilik sudah menjawab KO-1..KO-7 (27 Sep 2026) dan menyerahkan lima
ilustrasi onboarding (`assets/illustration/onboarding_{1..5}.png`, latar
transparan). Saat rencana ditinjau (28 Sep 2026), pemilik menambahkan satu
syarat: visual onboarding dan spotlight harus menarik, **dengan animasi dan
ilustrasi pendukung yang bergerak**.

Keadaan kode saat ini:

- Belum ada penyimpanan preferensi. "Dompet terakhir" dihitung dari
  transaksi, bukan disimpan.
- Router (`AppRouteRegistry.build`) punya satu rute buatan tangan, `/home`,
  tanpa `redirect`. `main.dart` sudah menunggu `di.run` sebelum `runApp`.
- `PixelTheme` dipasang di dalam `AppShellPage`, bukan di `MaterialApp`.
- Uji widget memompa `MaterialApp(home: AppShellPage())` tanpa router dan
  tanpa `SaldoughApp`, di atas `InMemoryKeyValueStorage` yang kosong.
- CATAT selalu melewati `RecordChoiceSheet`, yaitu tiga kartu edukasi
  (UX-1). Menurut KO-5, lembar itu dihapus.

## 3. Keputusan

### 3.1 Penyimpanan progres

Satu dokumen `KeyValueStorage` dengan kunci
`StorageKey(namespace: 'tutorial', name: 'progress')`:

```json
{ "schemaVersion": 1, "onboardingDone": true, "completedTours": ["home", "wallet"] }
```

- `TutorialProgressRepository` beserta implementasinya ada di
  `lib/core/tutorial/`, dengan pola `RepositoryGuard` + `StoredValue.json`
  seperti `WalletRepositoryImpl`. Letaknya di `core` karena komponen
  spotlight di `core` memakainya, dan data ini bukan data keuangan.
- Operasi: `load`, `markOnboardingDone`, `markTourDone`, `resetTour`,
  `resetAll`. Semuanya mengembalikan `Either<Failure, T>`.
- **Dokumen rusak dianggap belum dilihat.** Pemanggil memetakan `Left`
  menjadi `TutorialProgress.empty`. Id tur yang tidak dikenal diabaikan.
  Akibat terburuknya pengguna melihat pengenalan sekali lagi, dan itu jauh
  lebih ringan daripada aplikasi gagal dibuka.
- Tanpa analitik dan tanpa jaringan (prinsip 8 ONBOARDING_PLAN).

### 3.2 Gerbang onboarding (KO-1)

- `main.dart` memuat progres sesudah `di.run` dan sebelum `runApp`.
  `AppRouteRegistry.build` menerima `initialLocation` (`/onboarding` atau
  `/home`) dan satu `GoRoute('/onboarding')` buatan tangan. Tidak ada frame
  yang berkedip, dan `redirect` tidak dibutuhkan.
- Pemicunya hanya `onboardingDone`, bukan ada-tidaknya dompet. Karena itu
  pengguna lama juga melihat pengenalan sekali (KO-1).
- "Lewati", "Mulai", dan "Nanti saja" menandai selesai lalu `go('/home')`.
  "Buat Dompet Pertama" menandai selesai lalu
  `go('/home', extra: HomeStartAction.createWallet)`. `AppShellPage` kemudian
  membuka `WalletFormSheet` yang sudah ada sesudah frame pertama (KO-6: tidak
  ada formulir baru, dan dompet tidak diwajibkan).
- Mode tinjau (dari menu info) memakai `push('/onboarding', extra: review)`.
  Tombol akhirnya "Tutup", yang melakukan pop tanpa mengubah progres.
- Halaman onboarding memasang `PixelTheme` sendiri karena berada di luar
  `AppShellPage`.

### 3.3 Komponen spotlight (KO-3: dibuat sendiri)

- **`SpotlightHost`** dipasang di `MaterialApp.builder`, di atas
  `Navigator`, sehingga lapisannya juga menutupi lembar modal (penting untuk
  tur CATAT). Host memegang registri `SpotlightKey → GlobalKey` dan
  `SpotlightController`.
- **`SpotlightTarget(spotlightKey:, child:)`** mendaftarkan `GlobalKey`
  targetnya ke host. Target dipasang di **titik pemakaian** widget, sehingga
  widget privat (`_TemplatesButton`, `_ItemCard`, `_RecordNavIcon`) tidak
  perlu dibuka.
- **`TourTrigger(tour:, ready:)`** memulai tur sesudah frame pertama hanya
  jika tiga syarat terpenuhi:
  - `ready` (data termuat dan syarat tur terpenuhi)
  - `TickerMode` aktif, supaya tab tersembunyi di `IndexedStack` tidak ikut
    memicu
  - rutenya sedang di depan

  Trigger memeriksa ulang saat salah satu syarat berubah.
- **`SpotlightController.maybeStart(tour, {force})`** melakukan hal berikut:
  - memeriksa progres
  - menyaring langkah yang targetnya tidak terpasang (langkah bersyarat
    dilewati diam-diam)
  - menggulir target ke dalam layar
  - menampilkan overlay

  Lanjut di langkah terakhir, Lewati tur, dan tombol kembali sistem
  (`BackButtonListener`) semuanya menandai tur selesai.
- **Overlay menyerap semua ketukan.** Target tidak menjalankan aksinya
  selama tur.
- **Tanpa host, semuanya diam.** `SpotlightTarget` hanya meneruskan `child`,
  dan `TourTrigger` tidak melakukan apa pun. Uji lama (tanpa `SaldoughApp`)
  tetap hijau tanpa perubahan, sedangkan uji tur memasang host sendiri.

### 3.4 Daftar tur

Isinya mengikuti ONBOARDING_PLAN §4.3, dengan tiga penyesuaian:

| Tur (`TourId`) | Layar | Syarat `ready` |
|---|---|---|
| `home` | Beranda | termuat dan ≥1 dompet |
| `record` | CATAT | selalu |
| `wallet` | Dompet | termuat |
| `transaction` | Transaksi | termuat dan ≥1 transaksi bulan tampil |
| `budget` | Anggaran | termuat |
| `budgetDetail` | Rincian anggaran | termuat |
| `freelance` | Ikhtisar Freelance | termuat |
| `freelanceProject` | Rincian proyek | termuat |

- **Freelance dipecah menjadi dua tur.** Tur ikhtisar (`freelance.project`)
  dan tur rincian proyek (`freelance.worklog`, `freelance.receive`) masing-masing
  tampil di layarnya sendiri, sesuai prinsip "sekali per layar". Satu tur yang
  langkahnya tersebar di dua layar akan terputus di tengah jalan.
- **Teks tur Transaksi diperbarui** karena pencarian lintas bulan (T-8.2) dan
  tombol Filter (UX-21) sekarang ada. Teks di ONBOARDING_PLAN mengatakan
  pencarian "hanya mencakup bulan ini", dan itu tidak lagi benar.
- **`record.kind` menyorot pengalih tiga segmen** (§3.6), bukan lembar
  pilihan.

### 3.5 Lapis info (KO-4)

- `AppHeroCard` mendapat parameter opsional `onInfo`, yang merender ikon info
  kecil sesudah `trailing`. Ikon ini dipasang di kartu utama Beranda, Dompet,
  Transaksi, dan Anggaran. Ikhtisar Freelance tidak memakai `AppHeroCard`, jadi
  ikonnya dipasang di aksi bilah atasnya.
- Menu berisi tiga item:
  - **Tur layar ini** memanggil `maybeStart(tour, force: true)`.
  - **Pengenalan Tanukonomy** membuka onboarding dalam mode tinjau.
  - **Setel ulang semua tutorial** meminta konfirmasi, lalu menjalankan
    `resetAll`. Item ini ada juga di build rilis.

### 3.6 CATAT tanpa lembar pilihan (UX-1, KO-5)

- `RecordChoiceSheet`, loop pilihan, dan `BackToChoice` dihapus.
- CATAT membuka satu lembar penuh dengan pengalih **Keluar | Masuk |
  Transfer** di atas formulir, dan Pengeluaran menjadi bawaan. `initialChoice`
  dan `prefillFrom` tetap menentukan segmen awal.
- `BudgetSegmented<T>` dipindah ke `core` sebagai `AppSegmented<T>`, supaya
  fitur record tidak mengimpor fitur budget.
- Edukasi dari kartu pilihan (arah uang dan efek saldo) pindah ke OB-3 dan
  tur `record`. Penafian "hanya mencatat" tetap terwakili lewat kosakata dan
  onboarding. Aturan per formulir (misalnya "Aturan Kas: Saldo Terpotong")
  tetap di tempatnya (UX-9).

### 3.7 Bahasa gerak pixel

Semua gerak memakai animasi bawaan Flutter, tanpa Lottie atau Rive. Tidak
ada aset animasi, dan dependensi seperti itu melawan alasan KO-3.

**Primitif** — `lib/core/presentation/motion/`:

| Primitif | Perilaku |
|---|---|
| `SteppedCurve(steps)` | Progres dikuantisasi ke 6–8 anak tangga. Gerak terasa seperti sprite, bukan meluncur |
| `PixelBob` | Naik-turun 2px dalam dua "frame", siklus sekitar 1,2 detik |
| `PixelPop` | Skala 0 → 1,15 → 1, bertangga. Dipakai untuk kemunculan ikon dan gelembung |
| `PixelSparkle` | Kilau piksel 2×2 berwarna amber/krem yang berkedip |
| `MotionPolicy` | Membaca `MediaQuery.disableAnimationsOf`. Jika aktif, loop berhenti, transisi instan, dan adegan tampil di keadaan akhirnya |

Posisi dibulatkan ke grid logis 2px.

**Adegan onboarding.** Setiap adegan adalah ilustrasi pemilik ditambah
lapisan ikon pixel dari `assets/icons/` yang bergerak:

| Layar | Gerak |
|---|---|
| OB-1 | Maskot bob. Ikon dompet, transaksi, dan kalender pop satu per satu (pratinjau tiga layar berikutnya), lalu melayang |
| OB-2 | Ikon bank, e-wallet, dan tunai jatuh bertangga. Garis piksel mengalir ke satu plakat "total" yang berdenyut |
| OB-3 | Tombol CATAT berdenyut. Token hijau masuk, merah keluar, dan biru berputar di antara dua dompet. **Ini satu-satunya layar yang memakai warna arah uang** (ADR-016) |
| OB-4 | Bilah bersegmen terisi segmen demi segmen, dan tanda centang muncul berurutan |
| Akhir | Maskot bob dengan kilau piksel, dan tombol utama berdenyut satu kali |

Gerak antarlayar:
- Ilustrasi berparalaks 0,5× kecepatan geser.
- Judul dan isi masuk bergantian.
- Indikator halaman berupa blok piksel yang memanjang.
- Label "Lanjut" berganti menjadi "Mulai" di layar akhir.

Loop hanya berjalan di halaman yang aktif.

**Spotlight:**
- Lapisan gelap memudar masuk.
- Lubang berpindah bertangga dari target ke target.
- Bingkai aksen 2px berkedip dua frame, seperti kursor.
- Gelembung muncul dengan `PixelPop` dan punya ekor segitiga bertangga ke
  target.
- Avatar maskot kecil bob di sudut gelembung.
- Penanda langkah berupa blok piksel.
- Tanda centang muncul dengan pop di akhir tur.

**Aset:**
- Ruang transparan kelima PNG dipangkas satu kali ke kotak isi dengan margin
  seragam. Piksel yang terlihat tidak berubah.
- Avatar gelembung adalah kepala maskot yang dipotong dari
  `onboarding_1.png` (`mascot_head.png`). Jika pemilik memberikan
  `mascot_idle.png` (ART_BRIEF §5), berkas itu yang dipakai.
- Semua gambar dirender dengan `FilterQuality.none`.
- Animasi frame asli (mengedip, melambai) butuh sprite dari pemilik dan
  **di luar keputusan ini**.

### 3.8 Aksesibilitas

- Gelembung tur adalah dialog semantik (`scopesRoute`, `namesRoute`) dengan
  label "Langkah n dari m: judul. isi". Fokus pindah ke gelembung.
- Indikator onboarding diumumkan sebagai "Halaman n dari m".
- Tata letak tidak meluap di 360dp dengan teks 2x. Gelembung menyusut dan
  isinya bisa digulir.
- "Kurangi gerakan" dari sistem dihormati sepenuhnya (§3.7, `MotionPolicy`).

## 4. Alternatif yang ditolak

| Alternatif | Alasan ditolak |
|---|---|
| Paket `showcaseview` / `tutorial_coach_mark` | Bentuk pixel ADR-015 dan gerak bertangga sulit ditiru, dan menambah dependensi (KO-3) |
| Lottie/Rive untuk ilustrasi bergerak | Tidak ada aset animasi, dan dependensi serta ukuran biner bertambah. Gerak berbasis kode cukup untuk ilustrasi statis ditambah lapisan ikon |
| `redirect` di GoRouter | Harus membaca status async di setiap navigasi. Status cukup dibaca sekali di `main` |
| Gerbang di dalam `AppShellPage` | Semua uji shell akan melihat onboarding dan harus diubah |
| Satu tur Freelance lintas dua layar | Tur terputus di tengah saat berpindah layar |
| Progres di `shared/` | Komponen `core` tidak boleh bergantung ke `shared` |

## 5. Akibat

- Dokumen `tutorial/progress` menjadi dokumen preferensi pertama di
  penyimpanan. Hapus data aplikasi berarti pengenalan tampil lagi.
- Uji lama tidak berubah. Uji onboarding dan tur memasang `SpotlightHost` dan
  `MediaQuery(disableAnimations: true)`, supaya loop tanpa akhir tidak
  membuat `pumpAndSettle` macet. Satu uji khusus memeriksa loop dengan
  `pump(Duration)`.
- Uji alur CATAT yang mengetuk kartu pilihan berubah menjadi mengetuk segmen.
  Kunci i18n lembar pilihan yang tak terpakai lagi dihapus.
- UX_REVIEW_FIXES menjadi 22/22 saat T-9.6 selesai.
