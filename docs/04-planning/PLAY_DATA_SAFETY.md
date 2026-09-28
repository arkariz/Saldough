# Draf formulir Keamanan Data Play Console

Diperbarui 28 September 2026. Draf jawaban untuk bagian **App content → Data
safety** di Play Console, disiapkan lebih dulu karena fitur akun,
sinkronisasi, dan analitik pemakaian direncanakan (lihat
`docs/04-planning/TASK_LIST.md` dan repo `arkariz/tanukonomy-web`
`docs/TASKS.md` W-9).

## Aturan paling penting

**Formulir ini berlaku per rilis** — per APK/AAB yang diunggah, bukan sekali
untuk selamanya. Google memverifikasi lewat pemindaian SDK di build yang
sungguhan diunggah. Isi formulir sesuai **build yang sedang kamu unggah**,
bukan rencana produk:

- Build sekarang (uji coba tertutup, tanpa backend sama sekali) → **jawaban
  di bagian "Sekarang" di bawah.**
- Build nanti, sesudah akun/sinkronisasi/analitik sungguhan ditambahkan ke
  kode → **jawaban di bagian "Nanti" di bawah**, dan isi ulang formulirnya
  persis sebelum build itu diunggah.

Mengisi "Ya, mengumpulkan data" untuk build yang faktanya tidak melakukan itu
(atau sebaliknya) melanggar kebijakan Play dan bisa berujung penurunan
aplikasi atau penangguhan akun developer.

Kapan pun formulir ini diisi ulang, **cocokkan dengan kebijakan privasi**
(`privasi.astro`/`en/privacy.astro` §6–§7 di repo `tanukonomy-web`) —
keduanya harus bercerita hal yang sama tentang data apa yang diambil dan
untuk apa.

## Sekarang (build tanpa akun/sinkronisasi/analitik)

| Pertanyaan | Jawaban |
|---|---|
| Apakah aplikasi mengumpulkan atau membagikan data pengguna wajib? | **Tidak** |

Alasannya sesuai arsitektur aplikasi saat ini: tanpa server, tanpa
`http`/panggilan jaringan sama sekali (`CLAUDE.md` "Fakta proyek"). Kalau
pertanyaan susulan "Apakah semua data pengguna dienkripsi saat pengiriman"
tetap muncul meski jawaban di atas "Tidak", pilih **Tidak berlaku** kalau
ada, atau biarkan default Play Console (biasanya pertanyaan itu tersembunyi
begitu jawaban pertama "Tidak").

## Nanti (build dengan akun OAuth, sinkronisasi, dan analitik pemakaian)

Metode akun yang direncanakan: **OAuth (Google/Apple Sign-In)**, bukan
nama-pengguna-dan-sandi buatan sendiri — paling sedikit gesekan pendaftaran,
dan keamanan kredensial diserahkan ke Google/Apple, bukan ditangani sendiri.

| Pertanyaan | Jawaban | Catatan |
|---|---|---|
| Mengumpulkan/membagikan data pengguna wajib? | **Ya** | |
| Semua data dienkripsi saat pengiriman? | **Ya** | Wajib TLS/HTTPS untuk seluruh panggilan API sinkronisasi — bukan pilihan, ini syarat teknis minimum sebelum backend-nya boleh dianggap selesai. |
| Metode pembuatan akun (pilih semua yang sesuai) | **OAuth** | Kalau nanti Apple Sign-In juga ditambahkan (wajib oleh Apple kalau ada OAuth lain di versi iOS), tetap satu kotak "OAuth" — Play Console tidak memisahkan per penyedia. |
| Bisakah pengguna meminta datanya dihapus? | **Ya** | Sediakan **hapus akun di dalam aplikasi** (bukan cuma lewat email/tiket) — cara paling gampang lolos syarat ini dan sudah dijanjikan di kebijakan privasi §6 ("cara menghapus akun kembali"). |

### Jenis data yang dideklarasikan

Formulir lalu meminta detail per **jenis data**: dikumpulkan/dibagikan,
wajib/opsional, dan tujuannya. Untuk cakupan akun + sinkronisasi + analitik
pemakaian saja (belum termasuk catat-otomatis dari foto struk/suara — itu
jenis data lain, didaftarkan terpisah kalau fitur itu digarap):

| Kategori Play | Sub-jenis | Dikumpulkan | Dibagikan | Wajib/opsional | Tujuan |
|---|---|---|---|---|---|
| Info pribadi | Alamat email | Ya | Tidak | **Opsional** | Fungsionalitas aplikasi, manajemen akun |
| Info pribadi | ID pengguna | Ya | Tidak | Opsional | Fungsionalitas aplikasi |
| Info finansial | Info finansial lainnya (dompet, transaksi, anggaran) | Ya | Tidak | Opsional | Fungsionalitas aplikasi (sinkronisasi) — **bukan** analitik atau iklan |
| Aktivitas aplikasi | Interaksi aplikasi | Ya | Tergantung penyedia analitik | Opsional* | Analitik |

`*` Data akun boleh ditandai opsional karena pencatatan inti tetap jalan
tanpa akun (dijanjikan di landing dan kebijakan privasi). Analitik pemakaian
sendiri biasanya tidak bisa dimatikan per pengguna kecuali penyedianya
menyediakan opt-out — kalau begitu, tandai kolom "wajib" untuk baris
Interaksi aplikasi dan jelaskan di kebijakan privasi (sudah ada janji soal
ini di §7).

**"Dibagikan" untuk baris Interaksi aplikasi bergantung pada penyedia
analitik yang dipilih** (belum diputuskan). Contoh:

- **Firebase Analytics/Google Analytics for Firebase** — Google punya
  [halaman pemetaan Data safety resmi](https://support.google.com/faqs/answer/9022221)
  per SDK; datanya umumnya ditandai "dikumpulkan, tidak dibagikan" kalau
  cuma dipakai lewat jalur first-party mereka sendiri.
- Penyedia analitik lain (Mixpanel, PostHog, Amplitude, dst.) sering
  ditandai "dibagikan" karena datanya diproses di server pihak ketiga di
  luar Google.

Cek [pemetaan Data safety SDK Google](https://developer.android.com/guide/topics/data/collect-share)
persis untuk SDK yang akhirnya dipakai sebelum mengisi kolom "dibagikan".

### Belum termasuk di draf ini

- **Info pembayaran** (langganan premium/freemium) — biasanya lewat Google
  Play Billing, yang punya jalur deklarasi sendiri di Play Console
  (Play Billing tidak mengharuskan kamu mendeklarasikan info kartu sebagai
  data yang "dikumpulkan aplikasi", karena diproses Google, bukan kode
  sendiri) — verifikasi ulang saat langganan digarap.
- **Foto struk dan catatan suara** (item "Catat otomatis" di
  `docs/TASKS.md` W-10 repo `tanukonomy-web`) — kalau digarap, tambah baris
  "Foto dan video" serta "Berkas audio: rekaman suara/audio" di tabel jenis
  data, plus jelaskan di kebijakan privasi bahwa berkasnya diproses untuk
  jadi draf CATAT lalu (idealnya) dihapus, bukan disimpan mentah selamanya.

## Sebelum mengisi ulang formulir untuk rilis "Nanti"

1. Backend sinkronisasi sudah pakai HTTPS/TLS untuk semua panggilannya.
2. Penyedia analitik sudah dipilih dan dicek halaman pemetaan Data safety-nya.
3. Hapus akun bisa dilakukan dari dalam aplikasi.
4. Kebijakan privasi (`privasi.astro`/`en/privacy.astro`) diperbarui
   menyebut penyedia analitik dan server sinkronisasi yang sungguhan
   dipakai (§6–§7 sudah menjanjikan ini; P-8 di `docs/TASKS.md` repo
   `tanukonomy-web` mencatatnya sebagai syarat sebelum fitur aktif).
5. `LEGAL_EFFECTIVE_DATE` di `src/config.ts` (repo `tanukonomy-web`)
   diperbarui bersamaan.
