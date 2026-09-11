import 'package:saldough/core/i18n/strings.g.dart';

/// Mengubah identitas siklus (`"YYYY-MM"`) menjadi nama bulan yang terbaca,
/// mengikuti locale aktif (misalnya `"2026-08"` → `"Agustus 2026"` dalam
/// bahasa Indonesia, `"August 2026"` dalam bahasa Inggris).
///
/// Nama bulan ditulis tangan di sini (bukan lewat `intl`'s `DateFormat`)
/// karena aplikasi ini tidak memuat `flutter_localizations` — `DateFormat`
/// untuk locale non-Inggris butuh `initializeDateFormatting()` yang
/// dependensinya tidak ada. Dua bahasa yang didukung (`id`/`en`, lihat
/// `PROJECT_GLOSSARY.md`) tidak berubah, jadi daftar tetap ini aman.
abstract final class CycleMonthFormatter {
  CycleMonthFormatter._();

  static const _idMonths = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// Memformat [cycleId]. Mengembalikan [cycleId] apa adanya kalau
  /// formatnya tidak sesuai `"YYYY-MM"` — seharusnya tidak pernah terjadi
  /// untuk `MonthlyCycle.id` yang valid, tapi lebih aman daripada melempar.
  static String format(String cycleId) {
    final parts = cycleId.split('-');
    if (parts.length != 2) return cycleId;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return cycleId;
    final months = LocaleSettings.currentLocale == AppLocale.en ? _enMonths : _idMonths;
    return '${months[month - 1]} $year';
  }

  /// Memformat [date] lengkap dengan tanggal (UX-21) — mis. `11 September
  /// 2026`, bukan `2026-09-11` yang disusun tangan. Memakai daftar bulan
  /// yang sama seperti [format], tidak menduplikasinya.
  static String formatDate(DateTime date) {
    final months = LocaleSettings.currentLocale == AppLocale.en ? _enMonths : _idMonths;
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
