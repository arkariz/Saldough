import 'package:flutter/foundation.dart';
import 'package:saldough/core/appearance/appearance_settings.dart';

/// Tampilan aktif aplikasi, dibaca statis seperti `AmountVisibility`.
///
/// Diisi `bootstrap.dart` dari [AppearanceRepository] sebelum `runApp`;
/// perubahannya disimpan lewat pendengar yang dipasang di sana. `MaterialApp`
/// mendengarkan [notifier] dan membangun ulang tema.
abstract final class ActiveAppearance {
  ActiveAppearance._();

  /// Pemegang nilai.
  static final ValueNotifier<AppearanceSettings> notifier = ValueNotifier(AppearanceSettings.initial);

  /// Setelan saat ini.
  static AppearanceSettings get value => notifier.value;
}
