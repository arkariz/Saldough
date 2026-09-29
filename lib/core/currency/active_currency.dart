import 'package:flutter/foundation.dart';
import 'package:saldough/core/currency/app_currency.dart';

/// Mata uang aktif seluruh aplikasi (ADR-025 §3.5).
///
/// Dibaca statis oleh formatter, sama seperti `LocaleSettings` untuk bahasa.
/// Diisi `main.dart` dari `CurrencyPreferenceRepository` sebelum `runApp`.
abstract final class ActiveCurrency {
  ActiveCurrency._();

  /// Pemegang nilai; didengar akar aplikasi untuk membangun ulang layar.
  static final ValueNotifier<AppCurrency> notifier = ValueNotifier(AppCurrency.idr);

  /// Mata uang aktif.
  static AppCurrency get value => notifier.value;
}
