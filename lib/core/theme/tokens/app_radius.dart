import 'package:flutter/widgets.dart';

/// Skala sudut dua tingkat: nilai mentah (`double`) untuk dipakai di tempat
/// yang butuh satu sisi saja, dan getter [BorderRadius] siap pakai untuk
/// `decoration.borderRadius`.
abstract final class AppRadius {
  AppRadius._();

  /// Tanpa sudut membulat — dipakai pada elemen yang sengaja tajam.
  static const double none = 0;

  /// Sudut kecil, dipakai pada tombol ikon dan chip.
  static const double sm = 8;

  /// Sudut bawaan kartu dan panel.
  static const double md = 16;

  /// Sudut besar, dipakai pada bottom sheet dan modal penuh.
  static const double lg = 24;

  /// Sudut sangat besar, cukup untuk bentuk pil pada tombol/badge bulat.
  static const double full = 999;

  /// [BorderRadius] seragam dari [sm].
  static BorderRadius get smAll => BorderRadius.circular(sm);

  /// [BorderRadius] seragam dari [md].
  static BorderRadius get mdAll => BorderRadius.circular(md);

  /// [BorderRadius] seragam dari [lg].
  static BorderRadius get lgAll => BorderRadius.circular(lg);

  /// [BorderRadius] seragam dari [full], cukup besar untuk bentuk pil.
  static BorderRadius get fullAll => BorderRadius.circular(full);

  /// Sudut "comic cut" khas panel hero: dua sudut tajam berselang-seling
  /// dengan dua sudut sangat membulat, meniru potongan panel komik. Lihat
  /// ADR-0006 dan Design Canvas — motif ini khusus untuk panel hero/banner,
  /// bukan kartu biasa.
  static const comicCut = BorderRadius.only(
    topLeft: Radius.circular(sm / 2),
    topRight: Radius.circular(lg - 2),
    bottomLeft: Radius.circular(sm / 2),
    bottomRight: Radius.circular(lg - 2),
  );
}
