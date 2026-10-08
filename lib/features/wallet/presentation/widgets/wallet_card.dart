import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu baris ringkas dompet di daftar (UX-20 -- menggantikan kartu besar
/// ~130px lama yang mengulang "SALDO AKTIF" di tiap baris): ikon jenis,
/// nama (membungkus, tidak pernah dipotong) beserta jenis dan status di
/// bawahnya, dan saldo tercatat rata kanan. Saldo negatif tampil dengan
/// warna `expense` dan tanda minus (FR-WAL-003). Dompet nonaktif
/// diredupkan; kartu besar dengan label saldo tetap dipakai di layar
/// rincian dompet (`WalletDetailPage`), yang tidak diulang per baris di
/// sini.
class WalletCard extends StatelessWidget {
  /// Membuat [WalletCard].
  const WalletCard({required this.wallet, required this.onTap, super.key});

  /// Dompet yang ditampilkan.
  final Wallet wallet;

  /// Dipanggil saat kartu diketuk.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typeLabel = walletTypeLabel(wallet.iconKey);
    final negative = wallet.currentBalance < 0;
    return AppTappable(
      onTap: onTap,
      child: Opacity(
        opacity: wallet.isActive ? 1 : 0.6,
        child: TransactionSlab(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: AppSpacing.space2),
          // `IntrinsicHeight` -- sama seperti `TransactionRow` -- memberi
          // tinggi silang yang TERBATAS ke `Row`, supaya `FittedBox` nominal
          // di bawah tidak menerima constraint tinggi tak terhingga (yang
          // membuatnya meluap horizontal secara tidak kentara, ketahuan uji
          // 360px + teks 2x + nama panjang).
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(4)),
                  child: AppIcon(walletIconKey(wallet.iconKey), size: 26),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallet.name, style: Theme.of(context).textTheme.titleMedium),
                      if (typeLabel != null || !wallet.isActive) ...[
                        const SizedBox(height: 2),
                        // `Wrap`, bukan `Row` -- nama panjang menyempitkan
                        // kolom ini (lebar dibagi dengan kolom nominal di
                        // sebelahnya), dan label jenis dompet ID ("Bank /
                        // Rekening") tidak selalu muat sebaris pada 2x teks.
                        Wrap(
                          spacing: AppSpacing.space1,
                          runSpacing: 2,
                          children: [
                            if (typeLabel != null)
                              Text(
                                typeLabel.toUpperCase(),
                                style: transactionLabelStyle(context, color: colors.ink2),
                              ),
                            if (!wallet.isActive)
                              Text(
                                t.wallet.inactiveBadge.toUpperCase(),
                                style: transactionLabelStyle(context, color: colors.warning),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                // Lebar dijepit tetap, bukan `Flexible`/`Expanded` -- pola
                // yang sama dengan kolom nominal `TransactionRow` (T-2.11):
                // nominal mengecil di layar sempit/teks besar, bukan
                // berbagi ruang secara proporsional dengan kolom nama.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      AppMoneyFormatter.format(wallet.currentBalance),
                      style: context.numberStyles.amount.copyWith(color: negative ? colors.ink : colors.ink),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AppIcon(IconKey.chevronRight, size: 20, color: colors.ink2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
