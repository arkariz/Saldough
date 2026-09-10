import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';

/// Menampilkan nominal (sen) lewat [AppMoneyFormatter], dengan huruf Archivo
/// Black tabular dan warna otomatis berdasarkan tanda nilainya.
///
/// Bawaan: positif → [AppColorsExtension.income], negatif →
/// [AppColorsExtension.overBudget] (bukan `expense` — lihat antipola
/// ADR-0006: sisa negatif selalu `overBudget`), nol → warna teks biasa.
/// Pakai [color] untuk menimpa pemilihan otomatis ini pada konteks yang
/// warnanya ditentukan oleh makna baris, bukan tandanya (misalnya baris
/// anggaran yang nominalnya selalu disimpan positif tapi semantiknya
/// pengeluaran).
class AppMoneyText extends StatelessWidget {
  /// Membuat [AppMoneyText] untuk [sen].
  const AppMoneyText({
    required this.sen,
    this.style,
    this.color,
    super.key,
  });

  /// Nominal dalam satuan sen.
  final int sen;

  /// Gaya teks dasar. Bawaan `textTheme.headlineSmall`.
  final TextStyle? style;

  /// Menimpa warna otomatis berdasarkan tanda [sen].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final autoColor = sen > 0
        ? colors.income
        : sen < 0
            ? colors.overBudget
            : colors.textPrimary;

    final base = style ?? Theme.of(context).textTheme.headlineSmall;

    return Text(
      AppMoneyFormatter.format(sen),
      style: base?.copyWith(
        color: color ?? autoColor,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
