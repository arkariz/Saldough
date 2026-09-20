import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Keadaan kosong layar Dompet: belum ada dompet sama sekali (rujukan visual
/// `pixel_kas_dompet_belum_ada_data`), dengan ajakan menambah dompet pertama.
class WalletEmptyState extends StatelessWidget {
  /// Membuat [WalletEmptyState].
  const WalletEmptyState({required this.onAdd, super.key});

  /// Dipanggil saat tombol tambah dompet ditekan.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return TransactionSlab(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: colors.tinted(colors.pending, 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              t.wallet.emptyBadge.toUpperCase(),
              style: transactionLabelStyle(context, size: 12, color: colors.pending),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppIcon(IconKey.wallets, size: 96),
          const SizedBox(height: AppSpacing.lg),
          Text(t.wallet.emptyTitle, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.wallet.emptyBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: t.wallet.addAction, onPressed: onAdd),
          ),
        ],
      ),
    );
  }
}

/// Keadaan galat layar Dompet: pembacaan gagal, dengan tombol coba lagi.
/// Dibedakan dari [WalletEmptyState] supaya layar tidak menampilkan "belum
/// ada dompet" yang menyesatkan saat masalahnya pembacaan yang gagal.
class WalletLoadErrorState extends StatelessWidget {
  /// Membuat [WalletLoadErrorState].
  const WalletLoadErrorState({required this.onRetry, super.key});

  /// Dipanggil saat tombol coba lagi ditekan.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(IconKey.overBudget, size: 48, color: colors.overBudget),
            const SizedBox(height: AppSpacing.md),
            Text(t.wallet.loadErrorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.wallet.loadErrorSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.common.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
