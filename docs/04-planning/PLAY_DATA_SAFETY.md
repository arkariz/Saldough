# Draf formulir Keamanan Data Play Console

Diperbarui 29 September 2026 (ADR-023: identitas, Analytics, Crashlytics
sudah masuk kode). Draf jawaban untuk bagian **App content → Data safety**
di Play Console.

## Aturan paling penting

**Formulir ini berlaku per rilis** — per APK/AAB yang diunggah, bukan sekali
untuk selamanya. Google memverifikasi lewat pemindaian SDK di build yang
sungguhan diunggah. Isi formulir sesuai **build yang sedang kamu unggah**:

- Build tanpa `google-services.json`/sebelum ADR-023 → bagian "Sebelum
  ADR-023" di bawah.
- Build yang sudah menyertakan Firebase Auth, Analytics, dan Crashlytics
  (kode sudah ada per 29 September 2026) → bagian "Rilis ini (ADR-023)".
  **Ini yang berlaku untuk pengajuan Play Store pertama.**
- Sinkronisasi data dompet/transaksi/anggaran ke server **belum ada di
  kode** — bagian "Nanti" tetap berupa rencana, ADR tersendiri belum
  ditulis.

Mengisi "Ya, mengumpulkan data" untuk build yang faktanya tidak melakukan itu
(atau sebaliknya) melanggar kebijakan Play dan bisa berujung penurunan
aplikasi atau penangguhan akun developer.

Kapan pun formulir ini diisi, **cocokkan dengan kebijakan privasi**
(`privasi.astro`/`en/privacy.astro` di repo `tanukonomy-web`) — keduanya
harus bercerita hal yang sama tentang data apa yang diambil dan untuk apa.

## Sebelum ADR-023 (tanpa jaringan sama sekali)

| Pertanyaan | Jawaban |
|---|---|
| Apakah aplikasi mengumpulkan atau membagikan data pengguna wajib? | **Tidak** |

Sudah tidak relevan lagi untuk pengajuan Play Store pertama — dicatat di
sini hanya sebagai riwayat, kalau build lama ini pernah diunggah ke jalur
uji coba.

## Rilis ini (ADR-023): identitas, Analytics, Crashlytics

**Belum ada sinkronisasi data keuangan.** Dompet, transaksi, anggaran, dan
proyek freelance tetap 100% lokal — hanya identitas akun (kalau pengguna
memilih masuk), event pemakaian dasar, dan log crash yang meninggalkan
perangkat.

| Pertanyaan | Jawaban | Catatan |
|---|---|---|
| Mengumpulkan/membagikan data pengguna wajib? | **Ya** | |
| Semua data dienkripsi saat pengiriman? | **Ya** | Firebase Auth/Analytics/Crashlytics SDK memakai HTTPS/TLS bawaan — tidak ada konfigurasi tambahan dari kita. |
| Metode pembuatan akun (pilih semua yang sesuai) | **OAuth**, **Nama pengguna dan sandi** | Google Sign-In (OAuth) untuk pengguna sungguhan; email/sandi ditambahkan khusus supaya peninjau Google Play bisa masuk tanpa akun Google sungguhan (layar consent OAuth proyek belum diverifikasi Google membatasi ke tester eksplisit). Sign in with Apple **ditunda** sampai iOS digarap — Play Store tidak mensyaratkannya. |
| Bisakah pengguna meminta datanya dihapus? | **Ya** | Di dalam aplikasi (ikon Akun di Beranda → Hapus Akun) DAN lewat halaman web — isi kolom "URL hapus akun" dengan `https://tanukonomy.app/hapus-akun/` (atau domain aktif; lihat repo `tanukonomy-web`). |

### App access (peninjau Play)

Akun **sepenuhnya opsional** — tidak ada fitur pencatatan yang terkunci di
baliknya, jadi secara ketat peninjau tidak perlu kredensial apa pun untuk
menguji aplikasi. Tetap isi kolom "App access" dengan salah satu:

- **Termudah:** tulis bahwa seluruh fitur bisa diuji tanpa masuk/akun.
- **Kalau tetap ingin memberi akun uji:** buat satu akun email/sandi manual
  di Firebase Console (Authentication → Users → Add user), lalu tempel
  kredensialnya di App access. **Jangan** pakai akun Google pribadi pemilik.
  Instruksi untuk peninjau (ADR-024): "Ketuk ikon akun di kanan atas
  Beranda → *Sign in with email* → masukkan kredensial di atas."

### Jenis data yang dideklarasikan

| Kategori Play | Sub-jenis | Dikumpulkan | Dibagikan | Wajib/opsional | Tujuan |
|---|---|---|---|---|---|
| Info pribadi | Alamat email | Ya (kalau masuk) | Tidak | Opsional | Manajemen akun |
| Info pribadi | ID pengguna | Ya (kalau masuk) | Tidak | Opsional | Manajemen akun |
| Aktivitas aplikasi | Interaksi aplikasi | Ya | Tidak\* | Wajib\*\* | Analitik |
| App info dan performa | Log error/crash | Ya | Tidak\* | Wajib\*\* | Diagnostik |

`*` Firebase Analytics dan Crashlytics adalah produk Google sendiri (bukan
SDK pihak ketiga di luar Google) — per
[pemetaan Data safety resmi Google](https://support.google.com/faqs/answer/9022221),
keduanya ditandai **"dikumpulkan, tidak dibagikan"** selama dipakai lewat
jalur default (tanpa mengekspor ke BigQuery/produk Google lain yang
membagikannya lebih lanjut — kita tidak melakukan itu). Verifikasi ulang di
halaman itu kalau ada perubahan konfigurasi.

`**` Analytics dan Crashlytics **tidak terikat status masuk** — berjalan
untuk semua pengguna, bahkan yang tidak pernah membuat akun (ADR-023 §3),
jadi ditandai wajib, bukan opsional. Ini beda dari data akun (opsional,
karena akunnya sendiri opsional).

**Tidak ada** baris "Info finansial" di rilis ini — dompet/transaksi/
anggaran tidak pernah meninggalkan perangkat (beda dari draf sebelumnya,
lihat riwayat git dokumen ini).

### Belum termasuk di draf ini

- **Sinkronisasi data keuangan ke server** — belum ada di kode. Kalau
  digarap, tambah baris "Info finansial: Info finansial lainnya" dengan
  status opsional, dan pilih "Dibagikan: Tidak" kalau backend tetap
  Firebase/Google, atau "Ya" kalau pindah ke penyedia lain.
- **Info pembayaran** (langganan premium/freemium) — biasanya lewat Google
  Play Billing, yang punya jalur deklarasi sendiri di Play Console (tidak
  perlu dideklarasikan sebagai data yang "dikumpulkan aplikasi", karena
  diproses Google, bukan kode sendiri) — verifikasi ulang saat langganan
  digarap.
- **Foto struk dan catatan suara** (item "Catat otomatis" di
  `docs/TASKS.md` W-10 repo `tanukonomy-web`) — kalau digarap, tambah baris
  "Foto dan video" serta "Berkas audio: rekaman suara/audio" di tabel jenis
  data.

## Sebelum mengisi ulang formulir untuk sinkronisasi data keuangan ("Nanti")

1. ADR baru ditulis untuk arsitektur sinkronisasi (T-8.4 di TASK_LIST) —
   backend apa, data apa yang boleh keluar perangkat.
2. Backend sinkronisasi sudah pakai HTTPS/TLS untuk semua panggilannya.
3. Hapus akun di dalam aplikasi juga menghapus data tersinkronnya di server
   (bukan cuma identitas), dalam tenggat yang disebut kebijakan privasi.
4. Kebijakan privasi (`privasi.astro`/`en/privacy.astro`) dan halaman hapus
   akun (`hapus-akun.astro`/`en/delete-account.astro`) diperbarui menyebut
   server sinkronisasi yang sungguhan dipakai (P-8 di `docs/TASKS.md` repo
   `tanukonomy-web` mencatatnya sebagai syarat sebelum fitur aktif).
5. `LEGAL_EFFECTIVE_DATE` di `src/config.ts` (repo `tanukonomy-web`)
   diperbarui bersamaan.

## Sebelum submit ke Play Console (rilis ini)

1. `android/app/google-services.json` sudah ditaruh pemilik.
2. Provider **Google** dan **Email/Password** diaktifkan di Firebase
   Console → Authentication → Sign-in method (dua-duanya, bukan cuma satu).
3. `FirebaseConfig.googleServerClientId` (`lib/core/config/firebase_config.dart`)
   diisi dengan OAuth Web client ID dari proyek Firebase yang sama —
   Google Sign-In di Android tidak akan menghasilkan `idToken` yang valid
   untuk Firebase tanpa ini.
4. SHA-1 **dan** SHA-256 dari kunci upload **dan** kunci Play App Signing
   (Play Console → Setup → App integrity, setelah upload pertama)
   didaftarkan di Firebase Console → Project settings → Your apps. Kalau
   cuma SHA debug/upload yang didaftarkan, Google Sign-In gagal di build
   sungguhan dari Play Store meski lolos saat diuji lokal.
5. Satu akun email/sandi tester dibuat manual di Firebase Console untuk
   dicantumkan di App access (opsional, lihat di atas).
6. Kebijakan privasi `tanukonomy-web` §6/§7 menyebut Firebase Authentication
   dan Firebase Analytics/Crashlytics secara eksplisit (bukan lagi
   "penyedia belum dipilih"), dan halaman hapus akun §3 sudah jadi langkah
   pasti, bukan janji "belum tersedia".
