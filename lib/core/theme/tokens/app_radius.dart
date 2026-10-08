import 'package:flutter/widgets.dart';

/// Skala sudut lengkung design system (`tokens.json` grup radius).
///
/// Permukaan memakai sudut piksel (`AppSize.pixelStep`/`pixelStepSm`), bukan
/// lengkung; token ini hanya untuk sudut atas sheet dan bentuk pil.
abstract final class AppRadius {
  AppRadius._();

  /// Tanpa sudut membulat.
  static const double none = 0;

  /// `radius-sm` (8px).
  static const double sm = 8;

  /// `radius-md` (12px).
  static const double md = 12;

  /// `radius-lg` (20px).
  static const double lg = 20;

  /// `radius-xl` (28px): sudut atas sheet.
  static const double xl = 28;

  /// `radius-full`: bentuk pil.
  static const double full = 999;

  /// [BorderRadius] seragam dari [sm].
  static BorderRadius get smAll => BorderRadius.circular(sm);

  /// [BorderRadius] seragam dari [md].
  static BorderRadius get mdAll => BorderRadius.circular(md);

  /// [BorderRadius] seragam dari [lg].
  static BorderRadius get lgAll => BorderRadius.circular(lg);

  /// [BorderRadius] seragam dari [full], cukup besar untuk bentuk pil.
  static BorderRadius get fullAll => BorderRadius.circular(full);
}
