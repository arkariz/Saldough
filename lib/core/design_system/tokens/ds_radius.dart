import 'package:flutter/widgets.dart';

/// Skala sudut lengkung design system baru (`spec.md` bagian `rounded` dan
/// Shapes, ADR-043).
///
/// Input, tombol, dan sel 8px; kartu dan panel ringkasan 16px; sheet 20px
/// di sudut atas; badge, tag, dan avatar transaksi pil penuh.
abstract final class DsRadius {
  DsRadius._();

  /// Tanpa lengkung.
  static const double none = 0;

  /// `sm` (4px): checkbox, segmen meter.
  static const double sm = 4;

  /// `DEFAULT` (8px): input, tombol, sel interaktif, widget data.
  static const double base = 8;

  /// `md` (12px): tile ikon, tombol di kartu, kotak statistik.
  static const double md = 12;

  /// `lg` (16px): kartu dan panel ringkasan.
  static const double lg = 16;

  /// Sudut atas bottom sheet ponsel (20px).
  static const double sheet = 20;

  /// `xl` (24px): dialog dan overlay.
  static const double xl = 24;

  /// `full`: badge, tag, chip, avatar.
  static const double full = 9999;

  /// [BorderRadius] seragam [sm].
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// [BorderRadius] seragam [base].
  static const BorderRadius baseAll = BorderRadius.all(Radius.circular(base));

  /// [BorderRadius] seragam [md].
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// [BorderRadius] seragam [lg].
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  /// [BorderRadius] seragam [xl].
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));

  /// [BorderRadius] pil.
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  /// Sudut atas [sheet] untuk bottom sheet.
  static const BorderRadius sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}
