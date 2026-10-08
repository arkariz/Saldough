import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Jenis transaksi untuk pewarnaan -- lihat [TransactionKindPalette].
enum TransactionKind {
  /// `IncomeTransaction`.
  income,

  /// `ExpenseTransaction`.
  expense,

  /// `TransferTransaction`.
  transfer,
}

/// Warna per [TransactionKind] (design system bagian Warna): pengeluaran
/// `ink`, pemasukan `positive`, transfer `ink2` dengan tile `info`.
extension TransactionKindPalette on AppColors {
  /// Warna aksen bidang jenis (garis, kotak ikon) di layar yang belum
  /// dirombak. Peralihan Fase 14: layar baru tidak mewarnai bidang per jenis.
  Color kindFill(TransactionKind kind) => switch (kind) {
    TransactionKind.income => positive,
    TransactionKind.expense => ink2,
    TransactionKind.transfer => info,
  };

  /// Warna nominal per jenis.
  Color kindInk(TransactionKind kind) => switch (kind) {
    TransactionKind.income => positive,
    TransactionKind.expense => ink,
    TransactionKind.transfer => ink2,
  };
}

/// Gaya `label-sm` (12/16, 600, angka tabular): label kecil, badge, meta.
///
/// [size] dijepit ke minimum [kMinLabelSize] -- tidak ada teks lebih kecil
/// dari itu.
TextStyle labelSmStyle(
  BuildContext context, {
  double size = kMinLabelSize,
  Color? color,
}) {
  final clamped = size < kMinLabelSize ? kMinLabelSize : size;
  return appTextStyle(
    clamped,
    clamped * 4 / 3,
    FontWeight.w600,
    color ?? context.appColors.ink2,
    tabular: true,
  );
}
