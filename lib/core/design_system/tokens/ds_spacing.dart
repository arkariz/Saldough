/// Jarak dan tata letak design system baru (spek bagian `spacing` dan
/// "Layout & Spacing", ADR-043). Ritme 4px dan 8px.
abstract final class DsSpacing {
  DsSpacing._();

  /// `space-xs` (4px).
  static const double xs = 4;

  /// `space-sm` (8px).
  static const double sm = 8;

  /// `space-md` (16px).
  static const double md = 16;

  /// `space-lg` (24px).
  static const double lg = 24;

  /// `space-xl` (40px).
  static const double xl = 40;

  /// `margin-mobile` (16px): margin samping layar ponsel.
  static const double marginMobile = 16;

  /// `gutter-mobile` (16px): jarak antarkolom ponsel (4 kolom).
  static const double gutterMobile = 16;

  /// Margin tablet (32px, 768–1023px, 8 kolom).
  static const double marginTablet = 32;

  /// Gutter tablet (20px).
  static const double gutterTablet = 20;

  /// `margin` (40px): desktop, 12 kolom.
  static const double margin = 40;

  /// `gutter` (24px): desktop.
  static const double gutter = 24;

  /// Lebar minimum tata letak tablet.
  static const double breakpointTablet = 768;

  /// Lebar minimum tata letak desktop.
  static const double breakpointDesktop = 1024;

  /// Lebar isi maksimum desktop.
  static const double maxContentWidth = 1360;

  /// Tinggi minimum target sentuh.
  static const double minTapTarget = 44;
}
