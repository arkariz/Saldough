import 'package:intl/intl.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Menulis jumlah dengan pemisah ribuan menurut bahasa aplikasi: "5.008" (id),
/// "5,008" (en). Hanya untuk jumlah benda ("5.008 transaksi"); nominal uang
/// lewat `AppMoneyFormatter`.
abstract final class CountFormatter {
  CountFormatter._();

  /// Menulis [n] dengan pemisah ribuan.
  static String format(int n) => NumberFormat.decimalPattern(LocaleSettings.currentLocale.languageCode).format(n);
}
