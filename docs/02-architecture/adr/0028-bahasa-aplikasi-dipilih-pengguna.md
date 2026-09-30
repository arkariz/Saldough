# Bahasa aplikasi dipilih pengguna (tampilan + ucapan)

## 1. Metadata

- **Decision ID:** ADR-028
- **Tanggal:** 2026-09-30
- **Fase roadmap:** Fase 11, perbaikan T-11.5
- **Status:** Accepted
- **Cakupan:** `lib/core/language/`, `main.dart`, onboarding, layar Akun,
  Catat Cerdas suara (ADR-027), nama kategori bawaan (ADR-026)
- **Mengubah:** ADR-0007 (slang) — bahasa tidak lagi selalu mengikuti
  perangkat; ADR-026 §3.1 — nama kategori bawaan ikut berganti bahasa selama
  belum diganti pengguna.

## 2. Konteks

Sampai ADR ini aplikasi memakai bahasa perangkat (`useDeviceLocale`). Catat
Cerdas suara (ADR-027) membutuhkan bahasa ucapan yang jelas: pengguna di HP
berbahasa Inggris yang mencatat dalam bahasa Indonesia mendapat transkrip
yang salah. Pemilik (30 Sep 2026) memutuskan **satu pilihan bahasa** yang
mengatur tampilan aplikasi sekaligus bahasa ucapan, dipilih di onboarding
dan bisa diubah di layar Akun — mirip pilihan mata uang (ADR-025).

## 3. Keputusan

1. **Pilihan:** `AppLocale.id` (Bahasa Indonesia) atau `AppLocale.en`
   (English) — daftar mengikuti locale slang yang ada.
2. **Penyimpanan:** dokumen `settings/language` `{schemaVersion, code}`
   (`LanguagePreferenceRepository`). Belum pernah dipilih = bahasa perangkat,
   seperti sebelumnya.
3. **Penerapan:** `main.dart` memasang bahasa tersimpan sebelum layar pertama
   (sebelum migrasi kategori, supaya nama bawaan ditanam dalam bahasa itu).
   `ChangeAppLanguage` menyimpan pilihan, memanggil `LocaleSettings.setLocale`,
   memperbarui `ActiveLanguage.notifier` (didengar pembangun ulang akar,
   seperti mata uang), lalu menjalankan kait sesudah-ganti.
4. **Onboarding:** langkah **pertama** mode pertama kali adalah pilih bahasa,
   dengan bahasa saat ini terpilih; mengetuk pilihan langsung mengganti teks
   layar. Langkah mata uang (ADR-025 §3.7) tetap di akhir.
5. **Akun:** bagian Pengaturan memuat "Bahasa" di samping mata uang.
6. **Ucapan:** bahasa pengenal suara diturunkan dari bahasa aplikasi
   (`id` → `id_ID`, `en` → `en_US`).
7. **Kategori bawaan:** saat bahasa berganti, kategori bawaan yang namanya
   masih sama dengan nama bawaan bahasa lama diganti ke nama bahasa baru;
   yang sudah diganti pengguna tidak disentuh (`RelocalizeBuiltInCategories`).

## 4. Opsi yang dipertimbangkan

- **Opsi A — Bahasa ucapan terpisah dari bahasa tampilan**
- **Opsi B — Dua pilihan terpisah**
- **Opsi C — Satu pilihan untuk tampilan dan ucapan (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A / B
Lebih lentur untuk pengguna dwibahasa, tetapi menambah satu keputusan lagi di
onboarding dan dua setelan yang bisa saling bertentangan.

### Opsi C (Dipilih)
Paling sederhana dan sesuai kebiasaan pengguna sasaran. Kelemahan: pengguna
yang ingin tampilan Inggris tetapi berbicara bahasa Indonesia harus memilih
salah satu.

## 6. Konsekuensi

### Yang menjadi lebih mudah
- Transkrip suara memakai bahasa yang memang diucapkan.
- Nama kategori bawaan dan teks onboarding konsisten dengan pilihan.

### Yang menjadi lebih sulit
- Onboarding satu langkah lebih panjang.

### Risiko yang diterima
- Bahasa lain di luar id/en belum didukung.

## 7. Catatan implementasi

- Jangan membaca bahasa perangkat langsung di fitur; pakai
  `LocaleSettings.currentLocale` / `ActiveLanguage`.
- Pemisah ribuan dan desimal mengikuti bahasa aplikasi (ADR-025 §3), jadi
  ikut berganti.

## 8. Kriteria peninjauan ulang

- Ada permintaan bahasa ketiga, atau pengguna dwibahasa meminta bahasa ucapan
  terpisah.

## 9. Artefak terkait

### Dokumentasi
- ADR-025, ADR-026, ADR-027; TASK_LIST T-11.5

### Rujukan kode
- `lib/core/language/`

---

**Penulis keputusan:** Claude (agen), atas keputusan pemilik
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-09-30
**Status implementasi:** berjalan (T-11.5)
