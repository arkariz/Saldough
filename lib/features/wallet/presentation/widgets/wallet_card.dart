import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Satu kartu dompet di daftar (rujukan visual `pixel_kas_daftar_dompet`):
/// ikon jenis, nama (membungkus, tidak pernah dipotong), lencana jenis, dan
/// saldo tercatat. Saldo negatif tampil dengan warna `expense` dan tanda
/// minus (FR-WAL-003). Dompet nonaktif diredupkan dan berlencana "Nonaktif".
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: wallet.isActive ? 1 : 0.6,
        child: TransactionSlab(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
                    child: AppIcon(walletIconKey(wallet.iconKey), size: 36),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wallet.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                        const SizedBox(height: 4),
                        // `Wrap`: lencana jenis dan status turun baris kalau
                        // tidak muat.
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          children: [
                            if (typeLabel != null) _Badge(label: typeLabel, color: colors.textMuted),
                            if (!wallet.isActive) _Badge(label: t.wallet.inactiveBadge, color: colors.pending),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const AppIcon(IconKey.chevronRight),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: 2,
                  children: [
                    Text(
                      t.wallet.balanceLabel.toUpperCase(),
                      style: transactionLabelStyle(context, color: colors.textMuted),
                    ),
                    FitStart(
                      child: Text(
                        AppMoneyFormatter.format(wallet.currentBalance),
                        style: PixelTypography.tabularMono(
                          context,
                          fontSize: 16,
                          color: negative ? colors.expense : colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(4)),
      child: Text(label.toUpperCase(), style: transactionLabelStyle(context, size: 9, color: color)),
    );
  }
}
