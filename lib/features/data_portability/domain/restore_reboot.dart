/// Memulai ulang aplikasi supaya penerapan pemulihan berjalan di jalur
/// bootstrap (ADR-040 §3.7). Diisi akar komposisi (`AppReboot`); fitur tidak
/// boleh mengimpor `lib/app/`. [onboarding] menandai pemulihan dari onboarding
/// (daftar langkah tanpa cadangan pengaman).
typedef RestoreReboot = Future<void> Function({required bool onboarding});
