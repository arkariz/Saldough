# Akun tetap opsional, dan aturan kepemilikan data lokal terhadap akun

## 1. Metadata

- **Decision ID:** ADR-024
- **Tanggal:** 2026-09-29
- **Fase roadmap:** T-8.5 (akun yang lebih matang), persiapan desain
  sinkronisasi
- **Status:** Accepted
- **Cakupan:** `lib/shared/auth/`, `lib/features/account/`,
  `lib/features/onboarding/`, dan setiap ADR sinkronisasi/cadangan di masa
  depan
- **Melanjutkan:** [ADR-023](0023-identitas-opsional-firebase-auth-analitik-crashlytics.md)

## 2. Konteks

ADR-023 memasang identitas opsional (Firebase Auth: Google, plus email/sandi
khusus peninjau Play). Pemilik (29 September 2026) meminta akun dibuat "lebih
serius" dan bertanya: **apakah pengguna sebaiknya wajib masuk, atau tetap
opsional**, dengan mempertimbangkan sinkronisasi/cadangan data ke server yang
akan datang.

Pertanyaan itu sebenarnya dua:

1. Apakah akun menjadi gerbang aplikasi?
2. Apa hubungan data lokal (dompet, transaksi, anggaran, freelance) dengan
   akun — hari ini, dan begitu sinkronisasi ada?

Pertanyaan kedua yang menentukan desain sinkronisasi nanti. Kalau tidak
ditetapkan sekarang, setiap keputusan kecil hari ini (apa yang terjadi saat
keluar, saat menghapus akun, saat ganti akun) diam-diam menjadi kontrak yang
sulit diubah.

## 3. Keputusan

### 3.1 Akun tetap opsional

Tidak ada layar masuk sebelum Beranda. Pencatatan inti (CATAT, Transaksi,
Dompet, Anggaran, Freelance) tidak pernah menanyakan status akun.

Alasan:

- **NFR-REL-001**: inti wajib berfungsi penuh tanpa koneksi. Login wajib
  berarti pembukaan pertama butuh internet.
- **Gesekan**: aplikasi keuangan yang meminta akun sebelum pengguna mencatat
  satu rupiah pun kehilangan pengguna di pintu masuk, padahal nilai
  utamanya (mencatat) tidak butuh akun.
- **Janji produk**: situs `tanukonomy-web` menjual "catatanmu tetap di HP".
- **Peninjauan Play**: fitur utama bisa dinilai tanpa kredensial khusus
  (App access).

Akun ditawarkan, bukan dipaksakan, di dua titik:

- Tautan tersier "Sudah punya akun? Masuk" di slide terakhir onboarding —
  di bawah "Buat Dompet" yang tetap menjadi aksi utama.
- Ikon/avatar akun di app bar Beranda (sudah ada sejak ADR-023, kini
  menunjukkan status masuk).

Satu-satunya fitur yang kelak mensyaratkan akun adalah sinkronisasi/cadangan,
dan itu diaktifkan pengguna secara eksplisit.

### 3.2 Hari ini: data lokal milik perangkat, bukan milik akun

Sampai sinkronisasi ada, **masuk, keluar, ganti akun, dan hapus akun tidak
menyentuh data lokal sama sekali.** Ini sudah perilaku sejak ADR-023; ADR ini
menjadikannya invarian tertulis, dan layar Akun menyatakannya kepada pengguna
("Data kamu tersimpan di perangkat ini").

### 3.3 Aturan yang wajib dipatuhi ADR sinkronisasi nanti

Ini kerangka, bukan implementasi. Tidak ada kode untuk aturan ini di ADR ini
— penanda dan alurnya dibuat bersama desain sinkronisasi.

1. **Sinkronisasi diaktifkan eksplisit** dan satu-satunya fitur yang
   mensyaratkan akun.
2. **Pengikatan.** Saat sinkronisasi pertama kali diaktifkan, penyimpanan
   lokal diikat ke `uid` akun itu (penanda semacam `boundUid` di meta lokal).
   Data lokal yang sudah ada saat itu diunggah sebagai milik akun tersebut.
3. **Ganti akun di perangkat yang sudah terikat: tidak ada penggabungan.**
   Aplikasi menampilkan peringatan jelas bahwa data di perangkat ini akan
   **diganti** dengan data akun yang baru; pengguna melanjutkan atau batal.
   Tidak pernah ada penggabungan dua set data, diam-diam maupun atas pilihan
   (diputuskan pemilik 29 September 2026: sederhana dulu).
4. **Keluar saat terikat.** Sinkronisasi berhenti. Nasib data lokal (tetap,
   atau ditawarkan untuk dihapus) diputuskan pemilik saat sinkronisasi
   didesain — lihat "Keputusan terbuka" di TASK_LIST.
5. **Hapus akun saat sinkronisasi ada.** Data server dihapus lebih dulu, baru
   identitas Firebase; kalau urutannya terbalik, data yatim tertinggal di
   server tanpa pemilik yang bisa memintanya dihapus. Data lokal tetap
   kecuali pengguna memilih menghapusnya.

### 3.4 Email/sandi tetap khusus peninjau

Tanpa pendaftaran, verifikasi email, maupun lupa sandi (ADR-023 tetap
berlaku). Form-nya disembunyikan di balik tautan tersier "Masuk dengan email"
di layar Akun — tetap terlihat, tanpa gestur rahasia, supaya instruksi App
access Play bisa menunjuknya dengan kalimat sederhana.

Konsekuensi teknis yang ikut diperbaiki: hapus akun untuk pengguna email/sandi
yang sesinya sudah lama (`requires-recent-login`) sekarang meminta sandi,
bukan mencoba re-autentikasi lewat Google (yang pasti gagal karena akunnya
berbeda).

## 4. Opsi yang dipertimbangkan

- **Opsi A — Login wajib sebelum Beranda.** Ditolak: melanggar NFR-REL-001,
  menambah gesekan, bertentangan dengan janji situs. Keuntungannya
  (semua data terikat `uid` sejak awal) bisa dicapai dengan aturan pengikatan
  §3.3 poin 2 tanpa memaksa semua pengguna.
- **Opsi B — Firebase Anonymous Auth sejak pembukaan pertama**, lalu
  `linkWithCredential` saat pengguna masuk. Ditolak: panggilan jaringan
  diam-diam di pembukaan pertama (melanggar syarat ADR-023 "panggilan jaringan
  tidak boleh diam-diam"), dan membuat akun anonim sampah di Firebase untuk
  setiap instalasi yang tidak pernah masuk.
- **Opsi C — Penggabungan data saat ganti akun** (pilih gabung/ganti/batal).
  Ditolak pemilik: kompleks, rawan transaksi tercatat dua kali, dan
  mengubah saldo dengan cara yang sulit dijelaskan kepada pengguna.
- **Opsi D — Akun opsional, data lokal milik perangkat sampai sinkronisasi
  diaktifkan, ganti akun = ganti data dengan peringatan (Dipilih).**

## 5. Konsekuensi

### Yang menjadi lebih mudah

- ADR sinkronisasi nanti tidak perlu memutuskan ulang soal gerbang login,
  penggabungan, dan urutan hapus akun.
- Layar Akun bisa menjelaskan dengan jujur apa yang terjadi pada data.

### Yang menjadi lebih sulit

- Pengguna yang ganti akun di perangkat terikat kehilangan data lokal yang
  belum tersinkron ke akun lamanya. Peringatan wajib menyebut ini.

### Risiko yang diterima

- Sampai sinkronisasi ada, akun hampir tidak memberi manfaat nyata bagi
  pengguna. Teks tawaran masuk harus jujur (menyiapkan cadangan yang akan
  datang), tidak menjanjikan cadangan yang belum ada.

## 6. Kriteria peninjauan ulang

- Sinkronisasi/cadangan mulai didesain — ADR baru wajib merujuk §3.3.
- Pemilik membuka pendaftaran email/sandi untuk umum.
- Sign in with Apple digarap bersama iOS.

## 7. Artefak terkait

- `lib/shared/auth/`, `lib/features/account/`,
  `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- `docs/04-planning/TASK_LIST.md` T-8.5, "Keputusan terbuka" KT-2

---

**Penulis keputusan:** Claude (bersama pemilik, 29 September 2026)
**Tanggal disetujui:** 2026-09-29
**Status implementasi:** Berjalan
