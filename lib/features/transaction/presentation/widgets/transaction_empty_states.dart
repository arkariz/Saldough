import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Keadaan kosong saat bulan berjalan GENUINELY belum punya transaksi sama
/// sekali (`rawTransactions` kosong, bukan gagal dibaca) -- rujukan visual
/// `pixel_kas_riwayat_transaksi_kosong`. CTA-nya membuka alur CATAT
/// sungguhan lewat [onRecord] (dipasang pemanggil ke `openRecordSheet`,
/// CLAUDE.md aturan 8 -- bukan formulir pencatatan tersendiri).
class TransactionEmptyMonthState extends StatelessWidget {
  /// Membuat [TransactionEmptyMonthState].
  const TransactionEmptyMonthState({required this.onRecord, super.key});

  /// Dipanggil saat CTA ditekan.
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(IconKey.empty, size: 64, color: colors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(t.transaction.emptyMonthTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.transaction.emptyMonthSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.transaction.emptyMonthCta, onPressed: onRecord),
          ],
        ),
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
