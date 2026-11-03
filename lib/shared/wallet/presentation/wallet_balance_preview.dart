import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/fit_start.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Saldo [wallet] saat ini; kalau [previewAmountSen] sudah nominal yang valid,
/// jadi pratinjau `saldo lama (dicoret) → saldo baru`.
///
/// [previewIsCredit] `true` -- saldo naik (pemasukan, dompet tujuan transfer);
/// `false` -- turun (pengeluaran, dompet asal transfer). Dipakai daftar dompet
/// pemasukan/pengeluaran dan kartu dompet transfer.
///
/// `Wrap` + [FitStart]: dua nominal besar (sebelum -> sesudah) tidak muat
/// sebaris pada layar sempit atau teks besar. Wrap menurunkan yang kedua ke
/// baris berikutnya; [FitStart] memperkecil satu nominal yang sendirian lebih
/// lebar dari ruangnya, alih-alih meluap.
class WalletBalancePreview extends StatelessWidget {
  /// Membuat [WalletBalancePreview].
  const WalletBalancePreview({
    required this.wallet,
    required this.previewAmountSen,
    required this.previewIsCredit,
    this.style,
    super.key,
  });

  /// Dompet yang saldonya ditampilkan.
  final Wallet wallet;

  /// Nominal yang sedang diisi (sen), atau `null`/nol kalau belum valid.
  final int? previewAmountSen;

  /// Arah perubahan saldo.
  final bool previewIsCredit;

  /// Gaya dasar nominal. Bawaan `amountSm` (angka tabular).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final base = style ?? context.ds.typography.amountSm;
    final amount = previewAmountSen;
    final hasPreview = amount != null && amount > 0;
    if (!hasPreview) {
      return FitStart(
        child: Text(AppMoneyFormatter.format(wallet.currentBalance), style: base.copyWith(color: colors.textSecondary)),
      );
    }

    final after = previewIsCredit ? wallet.currentBalance + amount : wallet.currentBalance - amount;
    final afterColor = previewIsCredit ? colors.income : colors.textPrimary;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        FitStart(
          child: Text(
            AppMoneyFormatter.format(wallet.currentBalance),
            style: base.copyWith(color: colors.textSecondary, decoration: TextDecoration.lineThrough),
          ),
        ),
        // Panah dan nominal sesudah SATU anak `Wrap`: keduanya turun baris
        // bersama, panah tidak pernah tertinggal sendirian di ujung baris.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('→', style: base.copyWith(color: colors.textSecondary)),
            const SizedBox(width: 4),
            Flexible(
              child: FitStart(
                child: Text(
                  AppMoneyFormatter.format(after),
                  style: base.copyWith(color: afterColor, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
