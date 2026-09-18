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

  /// Tindakan utama, termasuk tombol CATAT. Nilai resmi ADR-015 — jangan
  /// dipakai untuk menyatakan makna keuangan (nominal), hanya untuk tombol
  /// dan aksi.
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

  /// Transfer antar dompet. Nilai resmi ADR-015 — sengaja berbagi hex dengan
  /// [textMuted] versi ADR-015 (bukan [textMuted] lama di sini, lihat
  /// dokumentasi kelas), supaya transfer tetap netral dan tidak menyaingi
  /// makna [income]/[expense].
  final Color transfer;

  /// Penghasilan freelance yang belum dibayar. Nilai resmi ADR-015.
  final Color pending;

  /// Palet mode terang penuh ADR-015 — dipakai layar Saldough 2.0 lewat
  /// `PixelTheme`, BUKAN [light]. `income`/`expense`/`overBudget`/
  /// `background`/`cardBackground`/`textPrimary`/`textMuted`/`edge` diganti
  /// nilai resmi ADR-015 (lihat tabel §"Palet" ADR-015); `accent`/
  /// `onAccent`/`transfer`/`pending` sudah sama sejak T-2.2. Slot yang
  /// murni milik layar lama (`investment`, `rollUp`, `needsReview`, dan
  /// varian `…OnLight`) sengaja diwariskan apa adanya dari [light] — layar
  /// baru tidak pernah membacanya.
  ///
  /// `divider` dan `shimmerBase`/`shimmerHighlight` tidak didefinisikan
  /// ADR-015; diturunkan dari `textPrimary`/`background`/`cardBackground`
  /// barunya dengan proporsi yang sama seperti [light] menurunkannya dari
  /// nilai ADR-0006, bukan warna karangan baru.
  static final AppColorsExtension pixelLight = light.copyWith(
    income: const Color(0xFF006948),
    expense: const Color(0xFFBA1A1A),
    overBudget: const Color(0xFFBA1A1A),
    background: const Color(0xFFFFF8F5),
    cardBackground: const Color(0xFFFFFFFF),
    edge: const Color(0xFF1E1B19),
    textPrimary: const Color(0xFF1E1B19),
    textMuted: const Color(0xFF3D4A42),
    divider: const Color(0x241E1B19),
    shimmerBase: const Color(0xFFFAF2EE),
    shimmerHighlight: const Color(0xFFFFFFFF),
  );

  /// Palet mode gelap penuh ADR-015 — pasangan [pixelLight]. Lihat
  /// dokumentasi [pixelLight] untuk aturan penurunan tiap slot.
  static final AppColorsExtension pixelDark = dark.copyWith(
    income: const Color(0xFF009767),
    expense: const Color(0xFFEA4B4B),
    overBudget: const Color(0xFFEA4B4B),
    background: const Color(0xFF14120F),
    cardBackground: const Color(0xFF1F1C18),
    edge: const Color(0xFFF2ECE7),
    textPrimary: const Color(0xFFF2ECE7),
    textMuted: const Color(0xFF708A7A),
    divider: const Color(0x2EF2ECE7),
    shimmerBase: const Color(0xFF1F1C18),
    // +13 tiap kanal dari cardBackground barunya -- rasio relatif yang
    // sama dengan cardBackground->shimmerHighlight [dark] lama (ADR-015
    // tidak mendefinisikan slot ini).
    shimmerHighlight: const Color(0xFF2C2925),
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
    );
  }
}

/// Akses singkat ke [AppColorsExtension] dari [BuildContext].
///
/// Jatuh ke [AppColorsExtension.light] kalau ekstensi belum terpasang,
/// sehingga tidak pernah melempar.
extension AppColorsContext on BuildContext {
  /// Slot warna semantik tema aktif.
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ?? AppColorsExtension.light;
}
