import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Panel datar dengan bayangan keras HANYA di sisi bawah, persis
/// `shadow-[0_3px_0_0_#1e1b19]` pada rujukan visual layar ini (beda dari
/// `AppHardCard` yang bergaris tepi penuh + bayangan kanan-bawah).
class TransactionSlab extends StatelessWidget {
  /// Membuat [TransactionSlab].
  const TransactionSlab({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(AppSpacing.space4),
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
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? colors.lineStrong,
            offset: Offset(0, shadow),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Teks label kecil (`label-sm`, angka tabular).
///
/// [size] dijepit ke minimum [kMinLabelSize] -- pemanggil boleh minta lebih
/// kecil untuk kompatibilitas layar lama, tapi hasilnya tidak akan pernah
/// lebih kecil dari itu.
TextStyle transactionLabelStyle(
  BuildContext context, {
  double size = kMinLabelSize,
  Color? color,
}) {
  final clamped = size < kMinLabelSize ? kMinLabelSize : size;
  final colors = context.appColors;
  return appTextStyle(clamped, clamped * 4 / 3, FontWeight.w600, color ?? colors.ink2, tabular: true);
}

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
extension TransactionKindPalette on AppColors {
  /// Warna isian bidang besar untuk [kind].
  Color kindFill(TransactionKind kind) => switch (kind) {
    TransactionKind.income => positive,
    TransactionKind.expense => ink2,
    TransactionKind.transfer => info,
  };

  /// Warna teks/lencana untuk [kind], kontras aman di atas putih.
  Color kindInk(TransactionKind kind) => switch (kind) {
    TransactionKind.income => positive,
    TransactionKind.expense => ink,
    TransactionKind.transfer => ink2,
  };
}
