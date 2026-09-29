# Identitas opsional dengan Firebase Auth, ditambah Analytics dan Crashlytics

## 1. Metadata

- **Decision ID:** ADR-023
- **Tanggal:** 2026-09-29
- **Fase roadmap:** T-8.4 (arsitektur fitur online), persiapan rilis Play
  Store pertama
- **Status:** Accepted
- **Cakupan:** `lib/shared/auth/`, `lib/core/foundation/analytics/`,
  `lib/features/account/`, `pubspec.yaml`, `android/`
- **Merevisi:** Melaksanakan T-8.4 dan NFR-SEC-001/NFR-REL-001 hasil revisi
  28 September 2026 di `prd-saldough-2.0.md` §8 dan §13.

## 2. Konteks

Pemilik menyiapkan pengajuan pertama ke Play Store dan meminta empat hal
sekaligus (29 September 2026):

1. Firebase Analytics.
2. Firebase Crashlytics.
3. Masuk memakai akun Google/Apple.
4. Cara menghapus akun, dari dalam aplikasi maupun halaman web (untuk kolom
   "URL hapus akun" di Play Console — lihat
   `docs/04-planning/PLAY_DATA_SAFETY.md`).

Tiga keputusan pemilik yang membingkai cakupan ADR ini:

- **Firebase project sudah ada**; pemilik sudah punya `google-services.json`.
- **Sign in with Apple ditunda** sampai iOS digarap — Play Store tidak
  mensyaratkannya, dan itu satu-satunya alasan Apple mewajibkannya (kalau
  aplikasi menawarkan login pihak ketiga lain di App Store). Menyiapkannya
  sekarang berarti kode yang tidak bisa diuji (butuh Apple Developer
  Program) sampai iOS benar-benar disentuh.
- **Cakupan hari ini cuma identitas, analitik, dan crash reporting** — belum
  menyimpan dompet/transaksi/anggaran di server mana pun. Sinkronisasi data
  keuangan (disebut di ADR-016 §7 dan situs `tanukonomy-web` sebagai
  rencana) adalah proyek terpisah yang jauh lebih besar (skema Firestore,
  aturan keamanan, resolusi konflik offline-first) — didesain lewat ADR
  tersendiri begitu waktunya tiba, bukan bagian ADR ini.

Ini pertama kalinya aplikasi melakukan panggilan jaringan sama sekali sejak
pivot 2.0. NFR-SEC-001/NFR-REL-001 sudah direvisi 28 September 2026 untuk
mengizinkan ini (lihat commit "Revisi invarian 'tanpa panggilan jaringan
sama sekali' untuk fitur online"), dengan syarat: pencatatan inti (CATAT,
Transaksi, Dompet, Anggaran, Freelance) tetap wajib berfungsi penuh tanpa
koneksi, dan panggilan jaringan tidak boleh diam-diam — pengguna harus tahu
apa yang terjadi (akun Google diminta secara eksplisit, bukan latar
belakang).

## 3. Keputusan

### Identitas: `shared/auth`

Modul baru `lib/shared/auth/` (bukan `features/`, karena bakal dipakai 2+
fitur mendatang — premium, sinkronisasi, seperti `shared/wallet` dan
`shared/transaction`):

- **`AppUser`** (domain entity): `uid`, `displayName`, `email`, `photoUrl`.
  Tidak menyimpan token akses — itu urusan `firebase_auth` sendiri.
- **`AuthRepository`** (port, `Either<Failure, T>` seperti repository lain):
  `authStateChanges()` (stream), `signInWithGoogle()`, `signOut()`,
  `deleteAccount()`.
- **`FirebaseAuthRepositoryImpl`** (adapter di `data/`): membungkus
  `firebase_auth` + `google_sign_in`. `deleteAccount()` menangani error
  `requires-recent-login` dengan re-autentikasi Google sekali, baru
  menghapus — supaya pengguna tidak gagal menghapus akun cuma karena sesi
  masuknya sudah lama.
- Didaftarkan sebagai singleton akar di `RootModule`, seperti
  `WalletRepository`.

**Akun sepenuhnya opsional.** Tidak ada layar yang mengunci pencatatan inti
di belakang status masuk. Ini juga yang membuat aplikasi mudah ditinjau
Play Store — peninjau tidak perlu kredensial khusus untuk menguji fitur
utama (App content → App access).

### Dua metode masuk: Google DAN email/sandi

Ditambah di tengah pengerjaan (29 September 2026): pemilik juga minta masuk
email/sandi, khusus untuk kebutuhan peninjau Google Play. Alasannya nyata —
kalau layar consent OAuth proyek Firebase belum diverifikasi Google, Google
Sign-In membatasi masuk ke daftar tester eksplisit saja, dan peninjau Play
bukan salah satunya. Email/sandi menghindari masalah itu sama sekali.

- `AuthRepository.signInWithEmailAndPassword` ditambah di samping
  `signInWithGoogle`, keduanya menuju `AppUser` yang sama.
- **Tidak ada jalur pendaftaran mandiri di aplikasi.** Akun tester dibuat
  manual oleh pemilik di Firebase Console (Authentication → Users → Add
  user), lalu kredensialnya ditaruh di kolom "App access" Play Console.
  Membuka pendaftaran umum lewat email/sandi adalah keputusan produk
  terpisah (verifikasi email, pemulihan sandi, dll.) yang tidak diminta di
  sini.
- Play Console: kedua metode dicentang di "Metode pembuatan akun" (bukan
  cuma OAuth) — lihat `PLAY_DATA_SAFETY.md`.

### Titik masuk: fitur `account`

Layar penuh baru `lib/features/account/`, dibuka lewat `openAccountPage`
dari ikon `IconKey.account` di app bar Beranda — pola yang sama seperti
`openFreelanceOverview`: `MaterialPageRoute` + `PixelTheme` +
`ScopeWidget<AccountScope>`, bukan tujuan navigasi bawah (akun bukan
aktivitas harian).

- Belum masuk: tombol "Masuk dengan Google".
- Sudah masuk: email/nama akun, tombol "Keluar", dan tombol "Hapus Akun"
  (dialog konfirmasi eksplisit, menjelaskan ini menghapus identitas
  Firebase — BUKAN data dompet/transaksi/anggaran lokal, yang tetap ada
  sampai aplikasi dihapus/data dibersihkan manual, karena keduanya memang
  belum terhubung sama sekali di cakupan ADR ini).

### Analytics dan Crashlytics: `core/foundation/analytics`

Bukan port per fitur (bukan keputusan domain, cross-cutting seperti
`effect_handler`):

- `firebase_analytics`: dipasang lewat `FirebaseAnalyticsObserver` pada
  `GoRouter` untuk `screen_view` otomatis, plus event bawaan Firebase
  (`first_open`, `app_open`). **Tidak ada event kustom dulu** — taksonomi
  event kustom (mis. "transaksi dicatat", "anggaran dibuat") adalah
  keputusan produk tersendiri, belum diambil (PRD §3 masih menyebut ini
  terbuka); menambahnya diam-diam lewat ADR ini akan melebihi apa yang
  pemilik minta.
- `firebase_crashlytics`: `FlutterError.onError` dan
  `PlatformDispatcher.instance.onError` diarahkan ke
  `FirebaseCrashlytics.instance.recordFlutterFatalError`/`recordError`.
  Nonaktif di mode debug (`setCrashlyticsCollectionEnabled(!kDebugMode)`)
  supaya crash saat pengembangan tidak mengotori dasbor.
- Keduanya jalan **tanpa syarat masuk** — mengumpulkan pemakaian/crash
  anonim, bukan terikat identitas `AppUser` (tidak memanggil
  `setUserId`/`setUserProperty` di ADR ini). Menautkan analitik ke identitas
  pengguna adalah keputusan lebih lanjut, bukan bagian cakupan ini.

### Yang berubah di luar kode Dart

- **Izin `INTERNET`** ditambahkan ke `AndroidManifest.xml` utama (build
  debug sudah otomatis dapat ini lewat manifest debug bawaan Flutter, tapi
  build rilis tidak) — pertama kalinya aplikasi butuh ini.
- **`android/app/google-services.json`**: ditaruh pemilik sendiri (bukan
  dibuat lewat kode), diabaikan git seperti `key.properties`? **Tidak** —
  berkas ini aman dikomit (ini pengenal publik proyek Firebae, bukan kunci
  rahasia; berbeda dari `key.properties`/keystore yang memang rahasia).
- **Plugin Gradle** `com.google.gms.google-services` dan
  `com.google.firebase.crashlytics` ditambahkan ke `settings.gradle.kts`
  (blok `plugins`, `apply false`) dan diterapkan di `android/app/build.gradle.kts`.
- **SHA-1/SHA-256** dari kunci upload DAN kunci Play App Signing (setelah
  Play Console menandatangani ulang aplikasi) harus didaftarkan ke Firebase
  Console oleh pemilik — kalau cuma SHA-1 debug/upload yang didaftarkan,
  Google Sign-In akan gagal di build produksi dari Play Store meski lolos
  saat diuji lokal. **Tindakan pemilik, di luar kode.**

## 4. Opsi yang dipertimbangkan

- **Opsi A — Tunda semuanya sampai desain sinkronisasi penuh selesai.**
  Ditolak: pemilik eksplisit minta ini sekarang untuk pengajuan Play Store,
  dan identitas+analitik+crash tidak perlu menunggu desain sinkronisasi.
- **Opsi B — Backend kustom (bukan Firebase) untuk auth.** Ditolak:
  Firebase project sudah dibuat pemilik; membangun backend sendiri untuk
  hal yang Firebase sediakan gratis tidak masuk akal di tahap ini.
- **Opsi C — Sign in with Apple sekalian sekarang.** Ditolak (pemilik
  memilih menunda): butuh Apple Developer Program yang belum tentu aktif,
  dan kodenya tidak bisa diuji sampai iOS digarap.
- **Opsi D — Identitas opsional, analitik dan crash tanpa syarat masuk,
  Google Sign-In saja, sinkronisasi data ditunda (Dipilih).**

## 5. Konsekuensi

### Yang menjadi lebih mudah

- Play Store: kolom "URL hapus akun" dan metode pembuatan akun di Data
  safety punya jawaban nyata, bukan draf (lihat `PLAY_DATA_SAFETY.md`).
- Crash sungguhan dari pengguna uji coba tertutup mulai terlihat, bukan
  cuma laporan manual.
- Fondasi identitas siap dipakai fitur premium/sinkronisasi nanti tanpa
  menulis ulang lapisan auth.

### Yang menjadi lebih sulit

- Aplikasi punya panggilan jaringan pertamanya — permukaan kegagalan baru
  (tanpa internet saat mencoba masuk, token kedaluwarsa) yang perlu
  ditangani dengan pesan yang jelas, bukan sekadar melempar `Failure`
  generik.
- Dua berkas rahasia baru di luar git (`google-services.json` boleh
  dikomit, tapi *App Check*/kunci API Firebase pihak lain kalau ditambah
  nanti tidak boleh) — perlu kedisiplinan yang sama seperti
  `key.properties`.

### Risiko yang diterima

- Event Analytics bawaan Firebase (`screen_view`, dsb.) mulai terkumpul
  begitu fitur ini rilis, sebelum kebijakan privasi situs
  (`tanukonomy-web`) menyebut nama "Firebase"/"Google Analytics" secara
  eksplisit di §7 — **harus diperbarui bersamaan**, bukan sesudahnya (lihat
  §6 Catatan implementasi).

## 6. Catatan implementasi

- Perbarui `docs/04-planning/PLAY_DATA_SAFETY.md`: ganti "penyedia belum
  dipilih" dengan Firebase/Google, tambah baris "App info dan performa:
  Log error" untuk Crashlytics.
- Perbarui `tanukonomy-web`: `privasi.astro`/`en/privacy.astro` §6–§7 sebut
  Firebase Authentication (Google Sign-In) dan Firebase Analytics/
  Crashlytics secara eksplisit; `hapus-akun.astro`/`en/delete-account.astro`
  §3 ditulis ulang jadi langkah pasti (Pengaturan/ikon akun → Hapus Akun),
  bukan janji "belum tersedia" lagi. **Jangan submit ke Play Store sebelum
  ini diperbarui** — janji P-8 di `docs/TASKS.md` repo itu.
- Verifikasi manual sebelum rilis: cabut Wi-Fi, pastikan CATAT/Transaksi/
  Dompet/Anggaran/Freelance tetap penuh berfungsi (NFR-REL-001); coba masuk
  Google dari mode pesawat, pastikan pesan galatnya jelas, bukan macet.
- Uji mutasi untuk `deleteAccount()`: putuskan alur re-autentikasi lalu
  pastikan uji yang menegaskan itu benar-benar merah tanpanya.

## 7. Kriteria peninjauan ulang

- Pemilik memutuskan taksonomi event Analytics kustom — ADR ini tidak
  mengatur itu, tulis amandemen atau ADR baru.
- Sinkronisasi data keuangan mulai didesain — proyek terpisah, ADR sendiri,
  yang wajib mematuhi aturan kepemilikan data di
  [ADR-024](0024-kepemilikan-data-lokal-dan-akun.md) §3.3.
- Artwork ikon akun pixel-art tersedia — ganti `IconKey.account` dari
  `_materialFallback` ke `_assetPaths`.

## 8. Artefak terkait

### Dokumentasi

- `docs/04-planning/PLAY_DATA_SAFETY.md`
- `docs/01-product/prd-saldough-2.0.md` §8.5, §13
- `docs/04-planning/TASK_LIST.md` T-8.4 / Fase 10

### Rujukan kode

- `lib/shared/auth/`
- `lib/core/foundation/analytics/`
- `lib/features/account/`
- `lib/core/di/src/root_module.dart`
- `android/app/src/main/AndroidManifest.xml`

---

**Penulis keputusan:** Claude (bersama pemilik, 29 September 2026)
**Ditinjau oleh:** —
**Tanggal disetujui:** 2026-09-29
**Status implementasi:** Berjalan
