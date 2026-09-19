import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_surfaces.dart';

/// Keadaan kosong saat bulan berjalan GENUINELY belum punya transaksi sama
/// sekali (`rawTransactions` kosong, bukan gagal dibaca) -- rujukan visual
/// `pixel_kas_riwayat_transaksi_kosong`. CTA-nya membuka alur CATAT
/// sungguhan lewat [onRecord] (dipasang pemanggil ke `openRecordSheet`,
/// CLAUDE.md aturan 8 -- bukan formulir pencatatan tersendiri).
///
/// Dua kartu terpisah, PERSIS urutan rujukan visual: kartu utama (lencana
/// "Inventaris Kosong", ilustrasi, judul, subjudul, tombol CATAT), lalu di
/// bawahnya kartu "Panduan Catatan Kas" yang menjelaskan tiga jenis
/// transaksi, dan catatan privasi. TIDAK menggulir sendiri -- pemanggil
/// (`TransactionListPage`) menaruhnya di dalam `CustomScrollView`.
class TransactionEmptyMonthState extends StatelessWidget {
  /// Membuat [TransactionEmptyMonthState].
  const TransactionEmptyMonthState({required this.onRecord, super.key});

  /// Dipanggil saat CTA ditekan.
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        TransactionSlab(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.pending.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.pending,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        t.transaction.emptyMonthBadge.toUpperCase(),
                        style: transactionLabelStyle(
                          context,
                          size: 12,
                          color: colors.pending,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 160,
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.income.withValues(alpha: 0.16),
                      colors.income.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: const AppIcon(IconKey.transactions, size: 96),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                t.transaction.emptyMonthTitle,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.transaction.emptyMonthSubtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: t.transaction.emptyMonthCta,
                  onPressed: onRecord,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TransactionSlab(
          color: colors.tone,
          shadow: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppIcon(IconKey.transactions, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t.transaction.emptyGuideTitle,
                      style: textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _GuideRow(
                icon: IconKey.income,
                color: colors.kindInk(TransactionKind.income),
                title: t.transaction.emptyGuideIncomeTitle,
                description: t.transaction.emptyGuideIncomeDescription,
              ),
              const SizedBox(height: AppSpacing.sm),
              _GuideRow(
                icon: IconKey.expense,
                color: colors.kindInk(TransactionKind.expense),
                title: t.transaction.emptyGuideExpenseTitle,
                description: t.transaction.emptyGuideExpenseDescription,
              ),
              const SizedBox(height: AppSpacing.sm),
              _GuideRow(
                icon: IconKey.transfer,
                color: colors.kindInk(TransactionKind.transfer),
                title: t.transaction.emptyGuideTransferTitle,
                description: t.transaction.emptyGuideTransferDescription,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            AppIcon(IconKey.locked, size: 18, color: colors.pending),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                t.transaction.trustFooterMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Satu baris "Panduan Catatan Kas" -- kartu putih berisi ikon jenis
/// transaksi, judul berwarna sesuai token semantiknya, dan penjelasan.
class _GuideRow extends StatelessWidget {
  const _GuideRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconKey icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      radius: 4,
      shadow: 0,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, size: 32, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: transactionLabelStyle(context, size: 12, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong saat bulan berjalan PUNYA transaksi, tapi filter aktif
/// mengecualikan semuanya -- pesan yang lebih singkat, TANPA ilustrasi
/// "belum ada transaksi" (itu akan menyesatkan: seolah bulan ini genuinely
/// kosong, padahal masalahnya cuma filter).
class TransactionEmptyFilterState extends StatelessWidget {
  /// Membuat [TransactionEmptyFilterState].
  const TransactionEmptyFilterState({required this.onClearFilters, super.key});

  /// Dipanggil saat tombol hapus filter ditekan.
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.transaction.emptyFilterTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.transaction.emptyFilterSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: t.transaction.clearFiltersButton,
              onPressed: onClearFilters,
            ),
          ],
        ),
      ),
    );
  }
}

/// Keadaan galat saat pembacaan dompet/transaksi gagal -- DIBEDAKAN dari
/// kedua keadaan kosong di atas lewat `TransactionState.loadFailed`, supaya
/// kegagalan baca tidak salah tampil sebagai "belum ada transaksi".
class TransactionLoadErrorState extends StatelessWidget {
  /// Membuat [TransactionLoadErrorState].
  const TransactionLoadErrorState({required this.onRetry, super.key});

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
            Text(
              t.transaction.loadErrorTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.transaction.loadErrorSubtitle,
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
