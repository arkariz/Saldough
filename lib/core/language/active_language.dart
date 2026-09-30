import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:saldough/core/i18n/strings.g.dart';

/// Bahasa aplikasi yang sedang aktif (ADR-028). Didengar pembangun ulang akar
/// supaya teks yang dibaca lewat `t` global ikut berganti di layar yang sudah
/// terbuka, sama seperti `ActiveCurrency`.
abstract final class ActiveLanguage {
  ActiveLanguage._();

  /// Pemegang nilai.
  static final ValueNotifier<AppLocale> notifier = ValueNotifier(AppLocale.id);

  /// Bahasa aktif.
  static AppLocale get value => notifier.value;

  /// Locale pengenal ucapan untuk bahasa aktif (ADR-028 §3.6).
  static String get speechLocaleId => speechLocaleIdFor(value);
}

/// Locale pengenal ucapan untuk [locale].
String speechLocaleIdFor(AppLocale locale) => switch (locale) {
  AppLocale.id => 'id_ID',
  AppLocale.en => 'en_US',
};

/// Nama bahasa dalam bahasanya sendiri, supaya tetap terbaca apa pun bahasa
/// yang sedang aktif.
String languageName(AppLocale locale) => switch (locale) {
  AppLocale.id => 'Bahasa Indonesia',
  AppLocale.en => 'English',
};
