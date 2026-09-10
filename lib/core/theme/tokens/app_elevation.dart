import 'package:flutter/painting.dart';

/// Token "elevasi" gaya komik: bukan blur material standar, melainkan jarak
/// bayangan keras offset (`box-shadow: Npx Npx 0 warna`, tanpa blur). Lihat
/// ADR-0006 — bayangan keras adalah motif yang disengaja, menggantikan
/// `elevation` bawaan Material di kedua mode.
abstract final class AppElevation {
  AppElevation._();

  /// Tanpa bayangan — elemen rata dengan latar.
  static const double none = 0;

  /// Bayangan tipis, dipakai pada tombol ikon dan chip.
  static const double sm = 2;

  /// Bayangan bawaan kartu dan panel.
  static const double md = 4;

  /// Bayangan besar, dipakai pada panel hero/banner.
  static const double lg = 6;

  /// Bangun bayangan keras offset (kanan-bawah, tanpa blur) sejauh [offset]
  /// piksel dengan warna [edge] — tiru motif `box-shadow: Npx Npx 0 edge`
  /// dari Design Canvas.
  static List<BoxShadow> hardShadow(Color edge, {double offset = md}) => [
        BoxShadow(color: edge, offset: Offset(offset, offset)),
      ];
}
