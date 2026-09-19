import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Tiga tingkat permukaan hangat ("surface-container" pada rujukan visual
/// `pixel_kas_daftar_transaksi`), diturunkan dari `background` dan
/// `textPrimary` -- bukan hex tetap -- supaya otomatis benar di mode gelap.
extension TransactionSurfaceTones on AppColorsExtension {
  Color _tone(double alpha) => Color.alphaBlend(textPrimary.withValues(alpha: alpha), background);

  /// Setingkat di atas `background` (`surface-container-low`).
  Color get toneLow => _tone(0.025);

  /// `surface-container` -- konsol bulan, wadah tab jenis.
  Color get tone => _tone(0.05);

  /// `surface-container-high` -- lencana netral.
  Color get toneHigh => _tone(0.085);
}

/// Panel datar dengan bayangan keras HANYA di sisi bawah, persis
/// `shadow-[0_3px_0_0_#1e1b19]` pada rujukan visual layar ini (beda dari
/// `AppHardCard` yang bergaris tepi penuh + bayangan kanan-bawah).
class TransactionSlab extends StatelessWidget {
  /// Membuat [TransactionSlab].
  const TransactionSlab({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = 8,
    this.shadow = 3,
    this.shadowColor,
    super.key,
  });

  /// Isi panel.
  final Widget child;

  /// Warna isian. Bawaan `cardBackground`.
  final Color? color;

  /// Padding dalam.
  final EdgeInsetsGeometry padding;

  /// Radius sudut.
  final double radius;

  /// Tinggi bayangan bawah, piksel.
  final double shadow;

  /// Warna bayangan. Bawaan `edge`.
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.cardBackground,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? colors.edge,
            offset: Offset(0, shadow),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Teks kecil Space Mono tebal berhuruf-besar-gaya "label" rujukan visual.
TextStyle transactionLabelStyle(
  BuildContext context, {
  double size = 10,
  Color? color,
}) => PixelTypography.tabularMono(
  context,
  fontSize: size,
  color: color,
).copyWith(letterSpacing: size * 0.08);

/// Jenis transaksi untuk pewarnaan -- lihat [TransactionKindPalette].
enum TransactionKind {
  /// `IncomeTransaction`.
  income,

  /// `ExpenseTransaction`.
  expense,

  /// `TransferTransaction`.
  transfer,
}

/// Pemetaan jenis transaksi ke token warna semantik (ADR-016) -- tidak ada
/// hex harfiah di sini. [kindFill] untuk bidang besar (garis aksen, kotak
/// ikon, nuansa latar); [kindInk] untuk teks dan isian lencana bertulisan
/// putih, dijaga >= 4,5:1.
extension TransactionKindPalette on AppColorsExtension {
  /// Warna isian bidang besar untuk [kind].
  Color kindFill(TransactionKind kind) => switch (kind) {
    TransactionKind.income => incomeFill,
    TransactionKind.expense => expenseFill,
    TransactionKind.transfer => transferFill,
  };

  /// Warna teks/lencana untuk [kind], kontras aman di atas putih.
  Color kindInk(TransactionKind kind) => switch (kind) {
    TransactionKind.income => income,
    TransactionKind.expense => expense,
    TransactionKind.transfer => transfer,
  };
}
