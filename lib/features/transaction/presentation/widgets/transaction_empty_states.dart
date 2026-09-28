import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/transaction/presentation/bloc/transaction_state.dart';
import 'package:saldough/features/transaction/presentation/widgets/transaction_date_group_card.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

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
                  color: colors.tinted(colors.pending, 0.15),
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
                      colors.accent.withValues(alpha: 0.16),
                      colors.accent.withValues(alpha: 0),
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
          color: colors.surfaceMid,
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
            AppIcon(IconKey.locked, size: 18, color: colors.textMuted),
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

/// Bagian pencarian lintas bulan (T-8.2, UX-6 langkah 2) -- tampil di bawah
/// [TransactionEmptyFilterState] hanya saat kata kunci pencarian sedang aktif
/// (menyaring dompet/kategori/jenis saja tidak memicu ini: bulan lain tidak
/// akan pernah "cocok" dengan filter jenis, jadi tidak ada gunanya
/// menawarkan pindai lintas bulan untuk itu).
///
/// Tiga keadaan: belum pernah diminta (tombol "Cari di bulan lain"), sedang
/// memindai (spinner), dan sudah dipindai (header + kartu hasil kalau ada,
/// lalu tombol "Cari lebih jauh" kalau riwayat sebelum bulan ini belum habis
/// atau pesan "tidak ditemukan" kalau sudah).
class TransactionCrossMonthSearchSection extends StatelessWidget {
  /// Membuat [TransactionCrossMonthSearchSection].
  const TransactionCrossMonthSearchSection({
    required this.hasScanned,
    required this.isSearching,
    required this.exhausted,
    required this.groups,
    required this.walletsById,
    required this.onSearch,
    required this.onTransactionTap,
    super.key,
  });

  /// `true` kalau setidaknya satu bulan sebelum bulan ini sudah dipindai.
  final bool hasScanned;

  /// Sedang memindai satu tumpuk bulan.
  final bool isSearching;

  /// `true` kalau seluruh bulan sebelum bulan ini sudah habis dipindai.
  final bool exhausted;

  /// Hasil yang cocok dari bulan-bulan yang sudah dipindai.
  final List<TransactionDateGroup> groups;

  /// Peta `id` dompet -> [Wallet], diteruskan ke [TransactionDateGroupCard].
  final Map<String, Wallet> walletsById;

  /// Dipanggil saat tombol "Cari di bulan lain"/"Cari lebih jauh" ditekan.
  final VoidCallback onSearch;

  /// Diteruskan ke [TransactionDateGroupCard.onTransactionTap].
  final ValueChanged<Transaction> onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (isSearching) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.sm),
            Text(t.transaction.crossMonthSearchingLabel, style: TextStyle(color: colors.textMuted)),
          ],
        ),
      );
    }

    if (!hasScanned) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Center(
          child: AppButton.secondary(label: t.transaction.crossMonthSearchButton, onPressed: onSearch),
        ),
      );
    }

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          children: [
            Text(
              t.transaction.crossMonthNoMoreResults,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textMuted),
            ),
            if (!exhausted) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(label: t.transaction.crossMonthLoadMoreButton, onPressed: onSearch),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.transaction.crossMonthResultsHeader.toUpperCase(),
            style: transactionLabelStyle(context, size: 12, color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final group in groups) ...[
            TransactionDateGroupCard(group: group, walletsById: walletsById, onTransactionTap: onTransactionTap),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!exhausted)
            Center(
              child: AppButton.secondary(label: t.transaction.crossMonthLoadMoreButton, onPressed: onSearch),
            ),
        ],
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
