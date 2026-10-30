/// ⚠ PLACEHOLDER: data tiruan untuk bagian acuan Beranda yang belum punya
/// data atau aturan (level, mood maskot, misi harian, slide rutin dan
/// hadiah). Sesuai keputusan pemilik 30 Okt 2026, tampil di semua build
/// lewat satu saklar.
///
/// Sebelum rilis publik: ubah [kHomePlaceholderPreview] menjadi `false`
/// (menyembunyikan seluruhnya) atau ganti dengan data dan aturan nyata
/// setelah keputusan produk soal gamifikasi (XP, level, misi, hadiah).
/// Teksnya ada di i18n `home.preview.*`.
library;

/// Saklar tunggal untuk semua data tiruan di Beranda.
const bool kHomePlaceholderPreview = true;

/// Kesehatan keuangan tiruan untuk kartu mood (0–1).
const double kHomePlaceholderMood = 0.84;
