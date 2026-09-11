/// Lebar garis tepi tebal khas panel komik — bukan pelengkap, melainkan
/// motif wajib (ADR-0006: "garis tepi tebal 2.5–3px" di kedua mode). Pakai
/// ini, bukan angka harfiah, di setiap `Border.all`/`BorderSide` yang
/// membentuk panel/tombol/chip komik.
///
/// Sebelum token ini ada, nilainya ditulis harfiah di lima tempat dan sudah
/// melenceng di satu (`AppChip` memakai `2`, yang lain `2.5`) — justru nilai
/// yang paling mendefinisikan gaya ini yang tidak ikut berubah kalau token
/// direvisi nanti (UX-29). Diselaraskan ke satu nilai: tidak ditemukan alasan
/// `AppChip` sengaja dibuat lebih tipis dari panel/tombol lain.
abstract final class AppBorder {
  AppBorder._();

  /// Lebar baku garis tepi komik — dipakai `AppCard`, `AppButton`,
  /// `AppChip`, dan `ThemeData` (`cardTheme`/`elevatedButtonTheme`).
  static const double thick = 2.5;
}
