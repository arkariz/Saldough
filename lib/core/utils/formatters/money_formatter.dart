import 'package:saldough/core/currency/active_currency.dart';
import 'package:saldough/core/currency/amount_visibility.dart';
import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Pemisah ribuan dan desimal, mengikuti bahasa aplikasi, bukan mata uang
/// (ADR-025 §3.3): id `1.234,56`, en `1,234.56`.
abstract final class MoneySeparators {
  MoneySeparators._();

  static bool get _en => LocaleSettings.currentLocale == AppLocale.en;

  /// Pemisah ribuan.
  static String get group => _en ? ',' : '.';

  /// Pemisah desimal.
  static String get decimal => _en ? '.' : ',';

  /// Menulis [value] (nonnegatif) dengan pemisah ribuan [group].
  static String groupThousands(int value) {
    final digits = value.toString();
    final separator = group;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) buffer.write(separator);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Mengubah nominal bertipe `int` satuan sen menjadi teks bermata uang
/// aktif ([ActiveCurrency], ADR-025).
///
/// Uang selalu disimpan dan dihitung dalam sen (lihat DOMAIN_MODEL.md dan
/// aturan arsitektur), dan pembulatan hanya terjadi di sini, saat
/// menampilkan — tidak pernah lebih awal. Memenuhi NFR-ACC-001.
abstract final class AppMoneyFormatter {
  AppMoneyFormatter._();

  /// Memformat [sen], mis. `"Rp1.234.567"`, `"−Rp1.234.567"` (tanda minus
  /// U+2212, bukan tanda hubung), atau `"$1,234.50"` untuk USD berbahasa
  /// Inggris.
  ///
  /// Mata uang tanpa desimal membulatkan setengah ke atas dengan aritmatika
  /// bilangan bulat murni lewat [_floorDiv] — tidak pernah lewat `double`,
  /// supaya tidak ada galat presisi mengambang pada nominal besar. Mata uang
  /// dua desimal selalu menulis dua angka desimal dan tidak membulatkan,
  /// karena satuan simpanannya sudah seperseratus.
  ///
  /// ⚠ `~/` bawaan Dart MEMOTONG ke nol (truncating), bukan pembagian
  /// lantai — `-7 ~/ 2` menghasilkan `-3`, bukan `-4`. Memakainya langsung
  /// untuk pembulatan setengah ke atas akan salah untuk nilai negatif
  /// (dibuktikan lewat `dart run` sebelum kode ini ditulis). [_floorDiv]
  /// mengoreksi ini.
  ///
  /// [currency] menimpa mata uang aktif; hanya untuk pratinjau, mis. contoh
  /// "sebelum → sesudah" di dialog ganti mata uang.
  static String format(int sen, {AppCurrency? currency}) => _format(sen, currency: currency);

  /// Seperti [format], tetapi tidak pernah disamarkan [AmountVisibility]:
  /// untuk nominal yang sedang diketik pengguna, yang memang tampil di layar
  /// (label pembaca layar input Catat, QA PR #43 F4).
  static String formatRevealed(int sen) => _format(sen, reveal: true);

  /// Nominal **perkiraan** (diawali `≈` oleh pemanggil): 10.000 satuan atau
  /// lebih dibulatkan ke ribuan terdekat (Rp87.212 → Rp87.000), supaya
  /// perkiraan tidak tampak sepasti saldo nyata (T-16.16 K5).
  static String formatApprox(int sen, {AppCurrency? currency}) {
    const thousand = 100000;
    if (sen.abs() < 10 * thousand) return _format(sen, currency: currency);
    return _format(_floorDiv(sen + thousand ~/ 2, thousand) * thousand, currency: currency);
  }

  static String _format(int sen, {AppCurrency? currency, bool reveal = false}) {
    final active = currency ?? ActiveCurrency.value;
    final bool isNegative;
    final String body;
    if (active.fractionDigits == 0) {
      final whole = _floorDiv(sen + 50, 100);
      isNegative = whole < 0;
      body = MoneySeparators.groupThousands(whole.abs());
    } else {
      final abs = sen.abs();
      isNegative = sen < 0;
      final cents = (abs % 100).toString().padLeft(2, '0');
      body = '${MoneySeparators.groupThousands(abs ~/ 100)}${MoneySeparators.decimal}$cents';
    }
    // Sembunyikan nominal (ADR-034): tanda tetap, angkanya tidak.
    if (AmountVisibility.hidden && !reveal) return '${isNegative ? '−' : ''}${active.symbol}${AmountVisibility.mask}';
    return '${isNegative ? '−' : ''}${active.symbol}$body';
  }

  /// Pembagian lantai murni bilangan bulat untuk pembagi [b] positif.
  static int _floorDiv(int a, int b) {
    final q = a ~/ b;
    final r = a - q * b;
    return r != 0 && (r < 0) != (b < 0) ? q - 1 : q;
  }
}
