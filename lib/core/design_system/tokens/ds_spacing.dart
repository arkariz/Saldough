/// Jarak dan tata letak design system baru (`spec.md` bagian `spacing` dan
/// Layout & Spacing, ADR-043). Grid ritme 8 poin.
abstract final class DsSpacing {
  DsSpacing._();

  /// `space-xs` (4px).
  static const double xs = 4;

  /// `space-sm` (8px).
  static const double sm = 8;

  /// Jarak antarkartu di satu tumpukan (14px, referensi `gap-3.5`).
  static const double stack = 14;

  /// `space-md` (16px). Juga padding kartu ringkas (referensi 14–16px).
  static const double md = 16;

  /// `space-lg` (24px): padding kartu metrik.
  static const double lg = 24;

  /// `space-xl` (40px): jarak antarwilayah besar.
  static const double xl = 40;

  /// `margin-mobile` (20px): margin samping layar ponsel.
  static const double marginMobile = 20;

  /// `gutter-mobile` (16px): jarak antarkolom ponsel (4 kolom).
  static const double gutterMobile = 16;

  /// Margin tablet (32px, 8 kolom).
  static const double marginTablet = 32;

  /// Gutter tablet (20px).
  static const double gutterTablet = 20;

  /// `margin` (48px): desktop, 12 kolom.
  static const double margin = 48;

  /// `gutter` (24px): desktop.
  static const double gutter = 24;

  /// Lebar minimum tata letak tablet.
  static const double breakpointTablet = 641;

  /// Lebar minimum tata letak desktop.
  static const double breakpointDesktop = 1025;

  /// Lebar isi maksimum desktop.
  static const double maxContentWidth = 1280;

  /// Tinggi minimum target sentuh.
  static const double minTapTarget = 44;
}
