import 'package:flutter/widgets.dart';

/// Skala sudut lengkung design system baru (spek bagian `rounded`, ADR-043).
///
/// Postur "Soft (Level 1)": kontrol mikro 2–4px, input dan tombol 4px,
/// kartu/panel/dialog 8px. Lingkaran penuh hanya untuk avatar dan titik
/// status.
abstract final class DsRadius {
  DsRadius._();

  /// Tanpa lengkung.
  static const double none = 0;

  /// `sm` (2px): badge, checkbox, switch.
  static const double sm = 2;

  /// `DEFAULT` (4px): input, tombol, chip.
  static const double base = 4;

  /// `md` (6px).
  static const double md = 6;

  /// `lg` (8px): kartu, panel, dialog.
  static const double lg = 8;

  /// `xl` (12px): sudut atas bottom sheet.
  static const double xl = 12;

  /// `full`: avatar dan titik status.
  static const double full = 9999;

  /// [BorderRadius] seragam [sm].
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// [BorderRadius] seragam [base].
  static const BorderRadius baseAll = BorderRadius.all(Radius.circular(base));

  /// [BorderRadius] seragam [md].
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] seragam [lg].
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  /// Sudut atas [xl] untuk bottom sheet.
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(xl));
}
