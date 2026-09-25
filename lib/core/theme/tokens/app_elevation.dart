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

  /// Bayangan kartu ADR-015 ("Level 1 — Kartu": `3px 3px 0px`). Nilai
  /// berbeda dari [md] ADR-0006 (4px) — jangan disamakan, keduanya milik
  /// bahasa visual yang berbeda (lihat `PixelTheme`).
  static const double pixelCard = 3;

  /// Bayangan elemen interaktif ADR-015 ("Level 2 — Interaktif": tombol
  /// terisi, FAB CATAT — `4px 4px 0px`, ditekan jadi `0px 0px 0px`).
  static const double pixelInteractive = 4;

  /// Bangun bayangan keras offset (kanan-bawah, tanpa blur) sejauh [offset]
  /// piksel dengan warna [edge] — tiru motif `box-shadow: Npx Npx 0 edge`
  /// dari Design Canvas.
  static List<BoxShadow> hardShadow(Color edge, {double offset = md}) => [
        BoxShadow(color: edge, offset: Offset(offset, offset)),
      ];

  /// Bayangan lembar bawah ADR-015 ("Level 3 — Lembar bawah": `0px -4px 0px`,
  /// mengarah ke atas karena lembar berada di bawah layar).
  static List<BoxShadow> pixelBottomSheetShadow(Color edge) => [
        BoxShadow(color: edge, offset: const Offset(0, -pixelInteractive)),
      ];
}
