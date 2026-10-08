import 'package:flutter/foundation.dart';

/// Sembunyikan nominal (design system Amount dan HeroCard, ADR-034 §4):
/// selama [hidden], `AppMoneyFormatter.format` menulis `Rp•••••` di semua
/// nominal sekaligus. Isian nominal di Catat tetap terlihat karena tidak
/// lewat formatter.
///
/// Dibaca statis seperti `ActiveCurrency`; diisi `main.dart` dari
/// [AmountVisibilityRepository] sebelum `runApp`, dan perubahannya disimpan
/// lewat pendengar yang dipasang di sana. Layar terbuka dibangun ulang oleh
/// `ActiveCurrencyRebuilder`.
abstract final class AmountVisibility {
  AmountVisibility._();

  /// Pemegang nilai; `true` = nominal disembunyikan.
  static final ValueNotifier<bool> notifier = ValueNotifier(false);

  /// Nominal sedang disembunyikan.
  static bool get hidden => notifier.value;

  /// Membalik [hidden].
  static void toggle() => notifier.value = !notifier.value;

  /// Pengganti angka saat disembunyikan.
  static const mask = '•••••';
}
