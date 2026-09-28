import 'package:flutter/widgets.dart';

/// Pembaca tunggal preferensi "kurangi gerakan" (ADR-021 §3.7, §3.8).
///
/// Saat [reduced], loop berhenti, transisi instan, dan adegan tampil di
/// keadaan akhirnya.
abstract final class MotionPolicy {
  MotionPolicy._();

  /// True kalau sistem meminta animasi dikurangi.
  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], atau nol saat [reduced].
  static Duration duration(BuildContext context, Duration duration) => reduced(context) ? Duration.zero : duration;
}
