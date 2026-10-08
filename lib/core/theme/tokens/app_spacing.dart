/// Skala jarak design system (`tokens.json` grup spacing), grid 4px. Pakai
/// ini, bukan angka harfiah, di mana pun widget butuh padding, margin, atau
/// gap.
///
/// Aturan pakai (README design system bagian Ruang): margin samping layar dan
/// padding kartu [space4], jarak antarkartu dalam satu bagian [space3], jarak
/// antarbagian [space6], ruang bawah halaman tab [space12].
abstract final class AppSpacing {
  AppSpacing._();

  /// `space-1` (4px).
  static const double space1 = 4;

  /// `space-2` (8px).
  static const double space2 = 8;

  /// `space-3` (12px).
  static const double space3 = 12;

  /// `space-4` (16px).
  static const double space4 = 16;

  /// `space-5` (20px).
  static const double space5 = 20;

  /// `space-6` (24px).
  static const double space6 = 24;

  /// `space-8` (32px).
  static const double space8 = 32;

  /// `space-10` (40px).
  static const double space10 = 40;

  /// `space-12` (48px).
  static const double space12 = 48;
}
