import 'package:saldough/core/currency/app_currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Nama mata uang di bahasa aktif.
String currencyName(AppCurrency currency) => switch (currency) {
  AppCurrency.idr => t.currency.names.idr,
  AppCurrency.usd => t.currency.names.usd,
  AppCurrency.eur => t.currency.names.eur,
  AppCurrency.gbp => t.currency.names.gbp,
  AppCurrency.jpy => t.currency.names.jpy,
  AppCurrency.cny => t.currency.names.cny,
  AppCurrency.krw => t.currency.names.krw,
  AppCurrency.inr => t.currency.names.inr,
  AppCurrency.sgd => t.currency.names.sgd,
  AppCurrency.myr => t.currency.names.myr,
  AppCurrency.thb => t.currency.names.thb,
  AppCurrency.php => t.currency.names.php,
  AppCurrency.vnd => t.currency.names.vnd,
  AppCurrency.aud => t.currency.names.aud,
};
