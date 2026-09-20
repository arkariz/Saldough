import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/record/presentation/widgets/fit_start.dart';
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

  /// Gaya dasar nominal. Bawaan `bodySmall` Space Mono.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final base = style ?? PixelTypography.tabularMono(context, fontSize: 12);
    final amount = previewAmountSen;
    final hasPreview = amount != null && amount > 0;
    if (!hasPreview) {
      return FitStart(
        child: Text(AppMoneyFormatter.format(wallet.currentBalance), style: base.copyWith(color: colors.textMuted)),
      );
    }

    final after = previewIsCredit ? wallet.currentBalance + amount : wallet.currentBalance - amount;
    final afterColor = previewIsCredit ? colors.income : colors.expense;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        FitStart(
          child: Text(
            AppMoneyFormatter.format(wallet.currentBalance),
            style: base.copyWith(color: colors.textMuted, decoration: TextDecoration.lineThrough),
          ),
        ),
        // Panah dan nominal sesudah SATU anak `Wrap`: keduanya turun baris
        // bersama, panah tidak pernah tertinggal sendirian di ujung baris.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('→', style: base.copyWith(color: colors.textMuted)),
            const SizedBox(width: AppSpacing.xs),
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
