import 'package:flutter/material.dart';
import 'package:saldough/core/theme/extensions/app_colors.dart';
import 'package:saldough/core/theme/pixel_theme.dart';

/// Skala Angka design system (`tokens.json` grup Angka): Plus Jakarta Sans
/// dengan angka tabular supaya digit sejajar di daftar.
///
/// - [amountDisplay] hanya nominal yang sedang diketik di Catat.
/// - [amountHero] satu angka utama per layar.
/// - [amountLg] angka utama kartu ringkasan.
/// - [amount] nominal baris daftar.
/// - [amountSm] angka pendukung.
///
/// Warna bawaannya `ink`; nominal bertanda memilih warnanya lewat
/// `AppMoneyText`.
class AppNumberStyles extends ThemeExtension<AppNumberStyles> {
  /// Membuat [AppNumberStyles] dengan seluruh gaya wajib diisi.
  const AppNumberStyles({
    required this.amountDisplay,
    required this.amountHero,
    required this.amountLg,
    required this.amount,
    required this.amountSm,
  });

  /// Skala Angka dengan warna `ink` dari [colors].
  factory AppNumberStyles.from(AppColors colors) {
    TextStyle style(
      double size,
      double height,
      FontWeight weight, {
      double? letterSpacing,
    }) => appTextStyle(
      size,
      height,
      weight,
      colors.ink,
      letterSpacing: letterSpacing,
      tabular: true,
    );
    return AppNumberStyles(
      amountDisplay: style(40, 48, FontWeight.w700, letterSpacing: -0.8),
      amountHero: style(32, 40, FontWeight.w700, letterSpacing: -0.64),
      amountLg: style(22, 28, FontWeight.w700, letterSpacing: -0.22),
      amount: style(16, 24, FontWeight.w600),
      amountSm: style(14, 20, FontWeight.w600),
    );
  }

  /// `amount-display` (40/48, 700).
  final TextStyle amountDisplay;

  /// `amount-hero` (32/40, 700).
  final TextStyle amountHero;

  /// `amount-lg` (22/28, 700).
  final TextStyle amountLg;

  /// `amount` (16/24, 600).
  final TextStyle amount;

  /// `amount-sm` (14/20, 600).
  final TextStyle amountSm;

  @override
  AppNumberStyles copyWith({
    TextStyle? amountDisplay,
    TextStyle? amountHero,
    TextStyle? amountLg,
    TextStyle? amount,
    TextStyle? amountSm,
  }) {
    return AppNumberStyles(
      amountDisplay: amountDisplay ?? this.amountDisplay,
      amountHero: amountHero ?? this.amountHero,
      amountLg: amountLg ?? this.amountLg,
      amount: amount ?? this.amount,
      amountSm: amountSm ?? this.amountSm,
    );
  }

  @override
  AppNumberStyles lerp(ThemeExtension<AppNumberStyles>? other, double t) {
    if (other is! AppNumberStyles) return this;
    return AppNumberStyles(
      amountDisplay: TextStyle.lerp(amountDisplay, other.amountDisplay, t)!,
      amountHero: TextStyle.lerp(amountHero, other.amountHero, t)!,
      amountLg: TextStyle.lerp(amountLg, other.amountLg, t)!,
      amount: TextStyle.lerp(amount, other.amount, t)!,
      amountSm: TextStyle.lerp(amountSm, other.amountSm, t)!,
    );
  }
}

/// Akses singkat ke [AppNumberStyles] dari [BuildContext].
extension AppNumberStylesContext on BuildContext {
  /// Skala Angka tema aktif; jatuh ke versi terang kalau tema belum terpasang.
  AppNumberStyles get numberStyles =>
      Theme.of(this).extension<AppNumberStyles>() ?? AppNumberStyles.from(AppColors.light);
}
