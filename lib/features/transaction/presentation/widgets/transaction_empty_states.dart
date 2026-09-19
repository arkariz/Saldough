import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Keadaan kosong saat bulan berjalan GENUINELY belum punya transaksi sama
/// sekali (`rawTransactions` kosong, bukan gagal dibaca) -- rujukan visual
/// `pixel_kas_riwayat_transaksi_kosong`. CTA-nya membuka alur CATAT
/// sungguhan lewat [onRecord] (dipasang pemanggil ke `openRecordSheet`,
/// CLAUDE.md aturan 8 -- bukan formulir pencatatan tersendiri).
///
/// Dua kartu terpisah, PERSIS urutan rujukan visual: kartu utama (lencana
/// "Inventaris Kosong", ilustrasi, judul, subjudul, tombol CATAT), lalu di
/// bawahnya kartu "Panduan Catatan Kas" yang menjelaskan tiga jenis
/// transaksi -- bukan cuma ikon+judul+tombol polos tanpa bingkai kartu
/// seperti versi sebelumnya.
class TransactionEmptyMonthState extends StatelessWidget {
  /// Membuat [TransactionEmptyMonthState].
  const TransactionEmptyMonthState({required this.onRecord, super.key});

  /// Dipanggil saat CTA ditekan.
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          AppHardCard(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(color: colors.pending.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Text(
                    t.transaction.emptyMonthBadge.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.pending, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppIcon(IconKey.empty, size: 96, color: colors.textMuted),
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.transaction.emptyMonthTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.transaction.emptyMonthSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(label: t.transaction.emptyMonthCta, onPressed: onRecord),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppHardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.transaction.emptyGuideTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _GuideRow(
                  icon: IconKey.income,
                  color: colors.income,
                  title: t.transaction.emptyGuideIncomeTitle,
                  description: t.transaction.emptyGuideIncomeDescription,
                ),
                const SizedBox(height: AppSpacing.xs),
                _GuideRow(
                  icon: IconKey.expense,
                  color: colors.expense,
                  title: t.transaction.emptyGuideExpenseTitle,
                  description: t.transaction.emptyGuideExpenseDescription,
                ),
                const SizedBox(height: AppSpacing.xs),
                _GuideRow(
                  icon: IconKey.transfer,
                  color: colors.transfer,
                  title: t.transaction.emptyGuideTransferTitle,
                  description: t.transaction.emptyGuideTransferDescription,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.transaction.trustFooterMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Satu baris "Panduan Catatan Kas" -- ikon jenis transaksi, judul berwarna
/// sesuai token semantiknya, dan penjelasan singkat.
class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.icon, required this.color, required this.title, required this.description});

  final IconKey icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(icon, size: 28, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
              Text(description, style: TextStyle(color: colors.textMuted)),
            ],
          ),
        ),
      ],
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
            AppButton(label: t.transaction.clearFiltersButton, onPressed: onClearFilters),
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
            Text(t.transaction.loadErrorTitle, style: Theme.of(context).textTheme.titleMedium),
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
