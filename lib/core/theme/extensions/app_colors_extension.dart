import 'package:flutter/material.dart';

/// Slot warna semantik Saldough, dipasang lewat [ThemeData.extensions].
///
/// Tiga slot keuangan (`income`, `expense`, `overBudget`) plus slot netral
/// untuk panel/teks/skeleton, empat slot dari ADR-015 (`accent`, `onAccent`,
/// `transfer`, `pending`), dan tiga slot isian ADR-016 (`…Fill`). Slot khusus
/// layar Saldough 1.0 (`investment`, `rollUp`, `needsReview`, beserta varian
/// `…OnLight`) dihapus saat cutover T-3.5. Jangan menulis warna harfiah di
/// widget, selalu lewat `context.appColors`.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  /// Membuat [AppColorsExtension] dengan seluruh slot wajib diisi.
  const AppColorsExtension({
    required this.income,
    required this.expense,
    required this.overBudget,
    required this.background,
    required this.cardBackground,
    required this.edge,
    required this.textPrimary,
    required this.textMuted,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.accent,
    required this.onAccent,
    required this.transfer,
    required this.pending,
    required this.incomeFill,
    required this.expenseFill,
    required this.transferFill,
    required this.scrim,
  });

  /// Nominal masuk, dan sisa siklus yang positif.
  final Color income;

  /// Nominal keluar.
  final Color expense;

  /// Sisa siklus yang negatif. Jangan pakai [expense] untuk ini.
  final Color overBudget;

  /// Dasar layar.
  final Color background;

  /// Dasar panel/kartu.
  final Color cardBackground;

  /// Garis tepi tebal khas panel komik.
  final Color edge;

  /// Teks utama.
  final Color textPrimary;

  /// Teks sekunder/keterangan — tingkat ketiga hierarki teks.
  final Color textMuted;

  /// Pemisah baris di dalam satu panel. Dipakai jarang — gaya komik lebih
  /// mengandalkan garis tepi tebal daripada garis pembagi tipis.
  final Color divider;

  /// Dasar skeleton loading.
  final Color shimmerBase;

  /// Kilau skeleton loading.
  final Color shimmerHighlight;

  /// Tindakan utama: tombol utama, CATAT, kursor, tab aktif. Palet pixel:
  /// terracotta `#C2410C` sejak ADR-016 (sebelumnya `#A73A00` ADR-015).
  /// Jangan dipakai untuk menyatakan makna keuangan (nominal), hanya untuk
  /// tombol dan aksi.
  final Color accent;

  /// Warna teks/ikon di atas isian [accent].
  ///
  /// Mode terang memakai putih persis seperti dinyatakan ADR-015 ("teks
  /// putih di atas `accent` menghasilkan 6,46:1"). ADR-015 tidak menyebutkan
  /// padanan mode gelap — putih di atas `accent` gelap (`#E95100`) hanya
  /// 3,72:1, di bawah ambang 4,5:1. Nilai mode gelap di sini memakai
  /// [background] gelap (`#14120F`), bukan warna baru: ADR-015 sendiri sudah
  /// mencatat pasangan hex yang sama (`accent` gelap terhadap latar gelap)
  /// menghasilkan 5,02:1. Ini keputusan pengisi celah, bukan nilai ADR-015
  /// — tinjau ulang kalau pemilik punya preferensi lain.
  final Color onAccent;

  /// Transfer antar dompet, versi TEKS-AMAN. Palet lama: netral abu-hijau
  /// (ADR-015). Palet pixel: BIRU sejak ADR-016 -- transfer dibedakan lewat
  /// hue yang jauh dari [income]/[expense], bukan lagi lewat netralitas.
  /// Untuk bidang besar pakai [transferFill].
  final Color transfer;

  /// Status menunggu/mendekati batas: penghasilan freelance yang belum
  /// dibayar, anggaran mendekati batas. Amber (ADR-016), BUKAN jenis
  /// transaksi. Teks-aman.
  final Color pending;

  /// Isian [income] untuk BIDANG BESAR (garis aksen, kotak ikon, bilah
  /// segmen) -- ADR-016. Di palet pixel mode terang lebih cerah dari [income]
  /// (yang dijaga >= 4,5:1 sebagai teks), cukup >= 3:1 sebagai komponen
  /// non-teks. Jangan dipakai untuk TEKS. Palet lama dan mode gelap: sama
  /// dengan [income].
  final Color incomeFill;

  /// Isian [expense] untuk bidang besar. Lihat [incomeFill].
  final Color expenseFill;

  /// Isian [transfer] untuk bidang besar. Lihat [incomeFill].
  final Color transferFill;

  /// Tirai gelap di belakang sorotan tur (ADR-021 §3.3), dipakai dengan
  /// alfa di titik pakainya. Sama di semua palet: tirai selalu gelap.
  final Color scrim;

  /// Palet mode terang layar Saldough 2.0 (`PixelTheme`), BUKAN [light].
  ///
  /// Dibangun dengan konstruktor EKSPLISIT, bukan `light.copyWith(...)`:
  /// dengan `copyWith`, tiap slot yang lupa diisi diwarisi diam-diam dari
  /// palet lama (itulah yang membuat `AppMoneyText` sempat memakai
  /// oranye-coklat untuk angka negatif). Kini slot baru wajib diisi di sini
  /// saat kompilasi. Nilainya: tabel §"Palet" ADR-015 sebagaimana direvisi
  /// ADR-016 (satu peran, satu warna).
  static const AppColorsExtension pixelLight = AppColorsExtension(
    income: Color(0xFF15803D),
    expense: Color(0xFFB91C1C),
    overBudget: Color(0xFFB91C1C),
    background: Color(0xFFFFF8F5),
    cardBackground: Color(0xFFFFFFFF),
    edge: Color(0xFF1E1B19),
    textPrimary: Color(0xFF1E1B19),
    textMuted: Color(0xFF57534E),
    // `divider`/`shimmer*` tidak didefinisikan ADR-015; diturunkan dari
    // `textPrimary`/`background`/`cardBackground` dengan proporsi yang sama
    // seperti palet lama menurunkannya dari nilai ADR-0006.
    divider: Color(0x241E1B19),
    shimmerBase: Color(0xFFFAF2EE),
    shimmerHighlight: Color(0xFFFFFFFF),
    accent: Color(0xFFC2410C),
    onAccent: Color(0xFFFFFFFF),
    transfer: Color(0xFF1D4ED8),
    pending: Color(0xFFA16207),
    incomeFill: Color(0xFF16A34A),
    expenseFill: Color(0xFFDC2626),
    transferFill: Color(0xFF2563EB),
    scrim: Color(0xFF120F0E),
  );

  /// Palet mode gelap layar Saldough 2.0 -- pasangan [pixelLight], juga
  /// konstruktor eksplisit. Pada mode gelap nilai teks-aman dan isian sama
  /// (ADR-016).
  static const AppColorsExtension pixelDark = AppColorsExtension(
    income: Color(0xFF22C55E),
    expense: Color(0xFFF87171),
    overBudget: Color(0xFFF87171),
    // Arang hangat, bukan hampir-hitam (amandemen ADR-016, 28 Sep 2026):
    // `#14120F` dengan garis tepi krem terang terlalu keras kontrasnya.
    // Teks tetap 14:1 di latar dan 12,5:1 di kartu.
    background: Color(0xFF231F1B),
    cardBackground: Color(0xFF2D2823),
    // Garis tepi dan bayangan keras redup (4,1:1 terhadap latar, 3,6:1
    // terhadap kartu; ambang batas komponen 3:1), bukan warna teks. Di mode terang `edge`
    // sama dengan teks, jadi mode terang tidak berubah.
    edge: Color(0xFF8A7D6E),
    textPrimary: Color(0xFFF2ECE7),
    textMuted: Color(0xFFA8A29E),
    divider: Color(0x2EF2ECE7),
    shimmerBase: Color(0xFF2D2823),
    // +13 tiap kanal dari cardBackground, sama seperti palet sebelumnya.
    shimmerHighlight: Color(0xFF3A3530),
    // Sedikit lebih terang dari `#E95100` sejak latar jadi arang (amandemen
    // ADR-016): sebagai teks 4,84:1 di kartu dan 5,43:1 di latar.
    accent: Color(0xFFF46B1C),
    // Teks gelap di atas accent 6,2:1 (putih tidak lolos).
    onAccent: Color(0xFF14120F),
    transfer: Color(0xFF60A5FA),
    pending: Color(0xFFF59E0B),
    incomeFill: Color(0xFF22C55E),
    expenseFill: Color(0xFFF87171),
    transferFill: Color(0xFF60A5FA),
    scrim: Color(0xFF120F0E),
  );

  /// Palet mode terang, nilai resmi dari ADR-0006.
  static const light = AppColorsExtension(
    income: Color(0xFF1E9E46),
    expense: Color(0xFFE13553),
    overBudget: Color(0xFFF07B12),
    background: Color(0xFFF2E9D8),
    cardBackground: Color(0xFFFFFFFF),
    edge: Color(0xFF161310),
    textPrimary: Color(0xFF161310),
    textMuted: Color(0xFF5B5346),
    divider: Color(0x24161310),
    shimmerBase: Color(0xFFEFE6D2),
    shimmerHighlight: Color(0xFFFFFFFF),
    accent: Color(0xFFA73A00),
    onAccent: Color(0xFFFFFFFF),
    transfer: Color(0xFF3D4A42),
    pending: Color(0xFF8D4B00),
    // Palet lama tidak membedakan teks dan isian -- disetel sama.
    incomeFill: Color(0xFF1E9E46),
    expenseFill: Color(0xFFE13553),
    transferFill: Color(0xFF3D4A42),
    scrim: Color(0xFF120F0E),
  );

  /// Palet mode gelap, nilai resmi dari ADR-0006.
  static const dark = AppColorsExtension(
    income: Color(0xFF3DDC68),
    expense: Color(0xFFFF4D6A),
    overBudget: Color(0xFFFF8C3D),
    background: Color(0xFF0E0D0B),
    cardBackground: Color(0xFF1C1A17),
    edge: Color(0xFFF2E9D8),
    textPrimary: Color(0xFFF2E9D8),
    textMuted: Color(0xFFB9AF9E),
    divider: Color(0x2EF2E9D8),
    shimmerBase: Color(0xFF1C1A17),
    shimmerHighlight: Color(0xFF29271F),
    accent: Color(0xFFE95100),
    // Lihat dokumentasi field onAccent — pengisi celah, bukan nilai ADR-015.
    onAccent: Color(0xFF14120F),
    transfer: Color(0xFF708A7A),
    pending: Color(0xFFCA6C00),
    incomeFill: Color(0xFF3DDC68),
    expenseFill: Color(0xFFFF4D6A),
    transferFill: Color(0xFF708A7A),
    scrim: Color(0xFF120F0E),
  );

  @override
  AppColorsExtension copyWith({
    Color? income,
    Color? expense,
    Color? overBudget,
    Color? background,
    Color? cardBackground,
    Color? edge,
    Color? textPrimary,
    Color? textMuted,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? accent,
    Color? onAccent,
    Color? transfer,
    Color? pending,
    Color? incomeFill,
    Color? expenseFill,
    Color? transferFill,
    Color? scrim,
  }) {
    return AppColorsExtension(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      overBudget: overBudget ?? this.overBudget,
      background: background ?? this.background,
      cardBackground: cardBackground ?? this.cardBackground,
      edge: edge ?? this.edge,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      transfer: transfer ?? this.transfer,
      pending: pending ?? this.pending,
      incomeFill: incomeFill ?? this.incomeFill,
      expenseFill: expenseFill ?? this.expenseFill,
      transferFill: transferFill ?? this.transferFill,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      overBudget: Color.lerp(overBudget, other.overBudget, t)!,
      background: Color.lerp(background, other.background, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      edge: Color.lerp(edge, other.edge, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      incomeFill: Color.lerp(incomeFill, other.incomeFill, t)!,
      expenseFill: Color.lerp(expenseFill, other.expenseFill, t)!,
      transferFill: Color.lerp(transferFill, other.transferFill, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

/// Akses singkat ke [AppColorsExtension] dari [BuildContext].
///
/// Jatuh ke [AppColorsExtension.light] kalau ekstensi belum terpasang,
/// sehingga tidak pernah melempar.
extension AppColorsContext on BuildContext {
  /// Slot warna semantik tema aktif.
  AppColorsExtension get appColors => Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}

/// Tiga tingkat permukaan hangat di atas [AppColorsExtension.background]
/// ("surface-container" pada rujukan visual), dan pewarna tint -- diturunkan
/// dari `background`/`textPrimary`/`cardBackground`, bukan hex tetap, jadi
/// otomatis benar di kedua mode. Satu-satunya tempat turunan ini dihitung;
/// widget tidak boleh lagi menulis `Color.alphaBlend(...)` sendiri.
extension AppColorsSurfaces on AppColorsExtension {
  Color _tone(double alpha) => Color.alphaBlend(textPrimary.withValues(alpha: alpha), background);

  /// Setingkat di atas `background` (`surface-container-low`).
  Color get surfaceLow => _tone(0.025);

  /// `surface-container` -- konsol bulan, wadah tab.
  Color get surfaceMid => _tone(0.05);

  /// `surface-container-high` -- lencana netral.
  Color get surfaceHigh => _tone(0.085);

  /// [fill] dilarutkan ke [cardBackground] sebesar [strength] (0..1) -- latar
  /// pucat berwarna untuk kotak ikon, nuansa kartu, dan lencana lembut.
  Color tinted(Color fill, double strength) => Color.alphaBlend(fill.withValues(alpha: strength), cardBackground);

  /// Latar kotak ikon pixel berwarna [fill] (`null` = netral). Ikon pixel
  /// bergaris hampir hitam, jadi di mode gelap latarnya pastel TERANG — isian
  /// tipis di atas kartu gelap membuat garis ikonnya hilang (NFR-UX-003,
  /// UX-19). Mode terang tetap [tinted] 0,22.
  Color iconTile(Color? fill) {
    final isDark = cardBackground.computeLuminance() < 0.5;
    if (!isDark) return fill == null ? surfaceMid : tinted(fill, 0.22);
    return Color.alphaBlend((fill ?? textMuted).withValues(alpha: 0.3), textPrimary);
  }
}
