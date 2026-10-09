import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Arti sebuah nominal, menentukan tanda dan warnanya (komponen Amount).
enum MoneyKind {
  /// Pengeluaran: `−Rp45.000`, `ink`.
  expense,

  /// Pemasukan: `+Rp8.500.000`, `positive`.
  income,

  /// Transfer: `Rp300.000` tanpa tanda, `ink2`.
  transfer,

  /// Saldo dompet: tanpa tanda; negatif ditulis `−Rp36.000` tetap `ink`
  /// (saldo negatif bukan kesalahan, FR-WAL-003).
  balance,

  /// Sisa anggaran: tanpa tanda; negatif (lewat) `danger`, selalu disertai
  /// badge yang menyebut selisihnya.
  remaining,
}

/// Ukuran nominal (skala Angka, [AppNumberStyles]).
enum MoneySize {
  /// `amount-display`: nominal yang sedang diketik di Catat.
  display,

  /// `amount-hero`: satu angka utama layar.
  hero,

  /// `amount-lg`: angka utama kartu ringkasan.
  large,

  /// `amount`: nominal baris daftar.
  regular,

  /// `amount-sm`: angka pendukung.
  small,
}

/// Nominal uang dengan aturan tanda, warna, dan ukuran yang sama di seluruh
/// aplikasi (komponen Amount, ADR-034). [sen] selalu `int` satuan sen;
/// format mata uang dari [AppMoneyFormatter]. Angka tabular.
///
/// Untuk [MoneyKind.expense], [MoneyKind.income], dan [MoneyKind.transfer]
/// tanda [sen] diabaikan: yang menentukan adalah jenisnya.
class AppMoneyText extends StatelessWidget {
  /// Membuat [AppMoneyText] untuk [sen].
  const AppMoneyText(
    this.sen, {
    this.kind = MoneyKind.balance,
    this.size = MoneySize.regular,
    this.color,
    this.textAlign,
    super.key,
  });

  /// Nominal dalam satuan sen.
  final int sen;

  /// Arti nominal.
  final MoneyKind kind;

  /// Ukuran angka.
  final MoneySize size;

  /// Menimpa warna bawaan [kind].
  final Color? color;

  /// Perataan teks.
  final TextAlign? textAlign;

  /// Teks nominal bertanda sesuai [kind], tanpa widget. Nol tidak diberi
  /// tanda ("Rp0", bukan "−Rp0").
  static String format(int sen, MoneyKind kind) => switch (kind) {
    MoneyKind.expense || MoneyKind.income when sen == 0 => AppMoneyFormatter.format(0),
    MoneyKind.expense => '−${AppMoneyFormatter.format(sen.abs())}',
    MoneyKind.income => '+${AppMoneyFormatter.format(sen.abs())}',
    MoneyKind.transfer => AppMoneyFormatter.format(sen.abs()),
    MoneyKind.balance || MoneyKind.remaining => AppMoneyFormatter.format(sen),
  };

  /// Warna bawaan [kind] untuk [sen].
  static Color colorOf(AppColors colors, int sen, MoneyKind kind) =>
      switch (kind) {
        MoneyKind.expense => colors.ink,
        MoneyKind.income => colors.positive,
        MoneyKind.transfer => colors.ink2,
        MoneyKind.balance => colors.ink,
    MoneyKind.remaining => sen < 0 ? colors.danger : colors.ink,
      };

  @override
  Widget build(BuildContext context) {
    final numbers = context.numberStyles;
    final style = switch (size) {
      MoneySize.display => numbers.amountDisplay,
      MoneySize.hero => numbers.amountHero,
      MoneySize.large => numbers.amountLg,
      MoneySize.regular => numbers.amount,
      MoneySize.small => numbers.amountSm,
    };
    return Text(
      format(sen, kind),
      maxLines: 1,
      softWrap: false,
      textAlign: textAlign,
      style: style.copyWith(
        color: color ?? colorOf(context.appColors, sen, kind),
      ),
    );
  }
}
