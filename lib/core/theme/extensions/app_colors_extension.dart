import 'package:flutter/material.dart';

/// Slot warna semantik Saldough, dipasang lewat [ThemeData.extensions].
///
/// Enam slot keuangan lama (`income`, `expense`, `overBudget`, `investment`,
/// `rollUp`, `needsReview`, nilai ADR-0006) plus slot netral untuk
/// panel/teks/skeleton, dan empat slot baru dari ADR-015 (`accent`,
/// `onAccent`, `transfer`, `pending`) untuk layar Saldough 2.0. Jangan
/// menulis warna harfiah di widget, selalu lewat `context.appColors`.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  /// Membuat [AppColorsExtension] dengan seluruh slot wajib diisi.
  const AppColorsExtension({
    required this.income,
    required this.expense,
    required this.overBudget,
    required this.investment,
    required this.rollUp,
    required this.needsReview,
    required this.onNeedsReview,
    required this.incomeOnLight,
    required this.expenseOnLight,
    required this.overBudgetOnLight,
    required this.investmentOnLight,
    required this.rollUpOnLight,
    required this.needsReviewOnLight,
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
  });

  /// Nominal masuk, dan sisa siklus yang positif.
  final Color income;

  /// Nominal keluar.
  final Color expense;

  /// Sisa siklus yang negatif. Jangan pakai [expense] untuk ini.
  final Color overBudget;

  /// Pos tujuan dan alokasi dana investasi.
  final Color investment;

  /// Baris yang nominalnya dihitung dari sumber lain (roll-up belanja/kartu).
  final Color rollUp;

  /// Baris hasil rollover yang belum ditinjau/dikonfirmasi pemilik.
  final Color needsReview;

  /// Warna teks/ikon di atas isian [needsReview].
  final Color onNeedsReview;

  /// Varian [income] untuk dipakai sebagai TEKS atau IKON di atas dasar
  /// terang. Slot aslinya hanya 3.48:1 di atas kartu putih — cukup sebagai
  /// isian dengan teks gelap di atasnya, tidak cukup sebagai teks itu sendiri.
  /// Lihat ADR-0006 bagian "Varian on-light". Di mode gelap nilainya sama
  /// dengan slot aslinya, karena di sana kontrasnya sudah memadai.
  final Color incomeOnLight;

  /// Varian [expense] untuk teks/ikon di atas dasar terang.
  final Color expenseOnLight;

  /// Varian [overBudget] untuk teks/ikon di atas dasar terang. Dipakai antara
  /// lain oleh sisa siklus yang negatif — angka terpenting di layar utama.
  final Color overBudgetOnLight;

  /// Varian [investment] untuk teks/ikon di atas dasar terang.
  final Color investmentOnLight;

  /// Varian [rollUp] untuk teks/ikon di atas dasar terang.
  final Color rollUpOnLight;

  /// Varian [needsReview] untuk teks/ikon di atas dasar terang. Slot aslinya
  /// hanya 1.43:1 di atas kartu putih — praktis tak terlihat.
  final Color needsReviewOnLight;

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

  /// Palet mode terang layar Saldough 2.0 (`PixelTheme`), BUKAN [light].
  ///
  /// Dibangun dengan konstruktor EKSPLISIT, bukan `light.copyWith(...)`:
  /// dengan `copyWith`, tiap slot yang lupa diisi diwarisi diam-diam dari
  /// palet lama (itulah yang membuat `AppMoneyText` sempat memakai
  /// oranye-coklat untuk angka negatif). Kini slot baru wajib diisi di sini
  /// saat kompilasi. Nilainya: tabel §"Palet" ADR-015 sebagaimana direvisi
  /// ADR-016 (satu peran, satu warna).
  ///
  /// Slot milik layar lama (`investment`, `rollUp`, `needsReview`) tidak
  /// dibaca layar baru; diisi dengan padanan keluarga hue ADR-016 supaya
  /// kalau suatu saat terbaca, hasilnya tetap selaras.
  static const AppColorsExtension pixelLight = AppColorsExtension(
    income: Color(0xFF15803D),
    expense: Color(0xFFB91C1C),
    overBudget: Color(0xFFB91C1C),
    investment: Color(0xFFD97706),
    rollUp: Color(0xFF2563EB),
    needsReview: Color(0xFFFACC15),
    onNeedsReview: Color(0xFF1E1B19),
    incomeOnLight: Color(0xFF15803D),
    expenseOnLight: Color(0xFFB91C1C),
    overBudgetOnLight: Color(0xFFB91C1C),
    investmentOnLight: Color(0xFFA16207),
    rollUpOnLight: Color(0xFF1D4ED8),
    needsReviewOnLight: Color(0xFFA16207),
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
  );

  /// Palet mode gelap layar Saldough 2.0 -- pasangan [pixelLight], juga
  /// konstruktor eksplisit. Pada mode gelap nilai teks-aman dan isian sama
  /// (ADR-016).
  static const AppColorsExtension pixelDark = AppColorsExtension(
    income: Color(0xFF22C55E),
    expense: Color(0xFFF87171),
    overBudget: Color(0xFFF87171),
    investment: Color(0xFFF59E0B),
    rollUp: Color(0xFF60A5FA),
    needsReview: Color(0xFFFACC15),
    onNeedsReview: Color(0xFF14120F),
    incomeOnLight: Color(0xFF22C55E),
    expenseOnLight: Color(0xFFF87171),
    overBudgetOnLight: Color(0xFFF87171),
    investmentOnLight: Color(0xFFF59E0B),
    rollUpOnLight: Color(0xFF60A5FA),
    needsReviewOnLight: Color(0xFFFACC15),
    background: Color(0xFF14120F),
    cardBackground: Color(0xFF1F1C18),
    edge: Color(0xFFF2ECE7),
    textPrimary: Color(0xFFF2ECE7),
    textMuted: Color(0xFFA8A29E),
    divider: Color(0x2EF2ECE7),
    shimmerBase: Color(0xFF1F1C18),
    // +13 tiap kanal dari cardBackground -- rasio relatif yang sama dengan
    // cardBackground->shimmerHighlight palet gelap lama.
    shimmerHighlight: Color(0xFF2C2925),
    accent: Color(0xFFE95100),
    // Putih di atas accent gelap hanya 3,72:1; latar gelap 5,02:1.
    onAccent: Color(0xFF14120F),
    transfer: Color(0xFF60A5FA),
    pending: Color(0xFFF59E0B),
    incomeFill: Color(0xFF22C55E),
    expenseFill: Color(0xFFF87171),
    transferFill: Color(0xFF60A5FA),
  );

  /// Palet mode terang, nilai resmi dari ADR-0006.
  static const light = AppColorsExtension(
    income: Color(0xFF1E9E46),
    expense: Color(0xFFE13553),
    overBudget: Color(0xFFF07B12),
    investment: Color(0xFFD99B00),
    rollUp: Color(0xFF2D6FE0),
    needsReview: Color(0xFFFFD400),
    onNeedsReview: Color(0xFF161310),
    incomeOnLight: Color(0xFF15702F),
    expenseOnLight: Color(0xFFB01C3A),
    overBudgetOnLight: Color(0xFFA84F05),
    investmentOnLight: Color(0xFF7A5400),
    rollUpOnLight: Color(0xFF2159BE),
    needsReviewOnLight: Color(0xFF756000),
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
  );

  /// Palet mode gelap, nilai resmi dari ADR-0006.
  static const dark = AppColorsExtension(
    income: Color(0xFF3DDC68),
    expense: Color(0xFFFF4D6A),
    overBudget: Color(0xFFFF8C3D),
    investment: Color(0xFFFFD23F),
    rollUp: Color(0xFF5B9CFF),
    needsReview: Color(0xFFFFE14D),
    onNeedsReview: Color(0xFF14120F),
    // Mode gelap tidak butuh varian: rasio terendah slot aslinya 5.39:1.
    // Disetel sama supaya pemakai token tidak perlu bercabang per tema.
    incomeOnLight: Color(0xFF3DDC68),
    expenseOnLight: Color(0xFFFF4D6A),
    overBudgetOnLight: Color(0xFFFF8C3D),
    investmentOnLight: Color(0xFFFFD23F),
    rollUpOnLight: Color(0xFF5B9CFF),
    needsReviewOnLight: Color(0xFFFFE14D),
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
  );

  @override
  AppColorsExtension copyWith({
    Color? income,
    Color? expense,
    Color? overBudget,
    Color? investment,
    Color? rollUp,
    Color? needsReview,
    Color? onNeedsReview,
    Color? incomeOnLight,
    Color? expenseOnLight,
    Color? overBudgetOnLight,
    Color? investmentOnLight,
    Color? rollUpOnLight,
    Color? needsReviewOnLight,
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
  }) {
    return AppColorsExtension(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      overBudget: overBudget ?? this.overBudget,
      investment: investment ?? this.investment,
      rollUp: rollUp ?? this.rollUp,
      needsReview: needsReview ?? this.needsReview,
      onNeedsReview: onNeedsReview ?? this.onNeedsReview,
      incomeOnLight: incomeOnLight ?? this.incomeOnLight,
      expenseOnLight: expenseOnLight ?? this.expenseOnLight,
      overBudgetOnLight: overBudgetOnLight ?? this.overBudgetOnLight,
      investmentOnLight: investmentOnLight ?? this.investmentOnLight,
      rollUpOnLight: rollUpOnLight ?? this.rollUpOnLight,
      needsReviewOnLight: needsReviewOnLight ?? this.needsReviewOnLight,
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
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      overBudget: Color.lerp(overBudget, other.overBudget, t)!,
      investment: Color.lerp(investment, other.investment, t)!,
      rollUp: Color.lerp(rollUp, other.rollUp, t)!,
      needsReview: Color.lerp(needsReview, other.needsReview, t)!,
      onNeedsReview: Color.lerp(onNeedsReview, other.onNeedsReview, t)!,
      incomeOnLight: Color.lerp(incomeOnLight, other.incomeOnLight, t)!,
      expenseOnLight: Color.lerp(expenseOnLight, other.expenseOnLight, t)!,
      overBudgetOnLight: Color.lerp(overBudgetOnLight, other.overBudgetOnLight, t)!,
      investmentOnLight: Color.lerp(investmentOnLight, other.investmentOnLight, t)!,
      rollUpOnLight: Color.lerp(rollUpOnLight, other.rollUpOnLight, t)!,
      needsReviewOnLight: Color.lerp(needsReviewOnLight, other.needsReviewOnLight, t)!,
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
}
