import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Keadaan kosong layar Anggaran (rujukan `pixel_kas_anggaran_belum_ada_data`).
///
/// Tanpa [onAdd] berarti pemilik belum punya dompet aktif — anggaran wajib
/// terikat ke satu dompet, jadi yang ditawarkan penjelasan, bukan tombol
/// yang akan mengarah ke formulir tanpa pilihan dompet.
class BudgetEmptyState extends StatelessWidget {
  /// Membuat [BudgetEmptyState].
  const BudgetEmptyState({required this.onAdd, super.key});

  /// Dipanggil saat tombol buat anggaran ditekan; `null` = belum ada dompet.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final hasWallet = onAdd != null;
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
              t.budget.emptyBadge.toUpperCase(),
              style: transactionLabelStyle(context, size: 12, color: colors.pending),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppIcon(IconKey.budget, size: 96),
          const SizedBox(height: AppSpacing.lg),
          Text(
            hasWallet ? t.budget.emptyTitle : t.budget.noWalletTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasWallet ? t.budget.emptyBody : t.budget.noWalletBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          ),
          if (hasWallet) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: AppButton(label: t.budget.addAction, onPressed: onAdd),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tidak ada anggaran yang lolos penyaring — dibedakan dari "belum ada
/// anggaran sama sekali", dengan jalan mengatur ulang penyaring.
class BudgetFilteredEmptyState extends StatelessWidget {
  /// Membuat [BudgetFilteredEmptyState].
  const BudgetFilteredEmptyState({required this.onReset, super.key});

  /// Mengembalikan penyaring ke semua status dan semua dompet.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          AppIcon(IconKey.filter, size: 48, color: colors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(t.budget.emptyFilteredTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            t.budget.emptyFilteredBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: t.budget.resetFilterAction, color: colors.textMuted, onPressed: onReset),
        ],
      ),
    );
  }
}

/// Pembacaan gagal, dengan tombol coba lagi — dibedakan dari daftar kosong.
class BudgetLoadErrorState extends StatelessWidget {
  /// Membuat [BudgetLoadErrorState].
  const BudgetLoadErrorState({required this.onRetry, super.key});

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
            Text(t.budget.loadErrorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.budget.loadErrorSubtitle,
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
