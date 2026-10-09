import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Keadaan kosong saat bulan berjalan GENUINELY belum punya transaksi sama
/// sekali (`rawTransactions` kosong, bukan gagal dibaca). CTA-nya membuka
/// alur CATAT sungguhan lewat [onRecord] (dipasang pemanggil ke
/// `openRecordSheet`, CLAUDE.md aturan 8 -- bukan formulir tersendiri).
///
/// Design system EmptyState (ilustrasi Riwayat), lalu panduan tiga jenis
/// transaksi sebagai daftar bertile dan catatan privasi. TIDAK menggulir
/// sendiri -- pemanggil (`TransactionListPage`) menaruhnya di dalam
/// `CustomScrollView`.
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppEmptyState(
          art: EmptyArt.history,
          title: t.transaction.emptyMonthTitle,
          body: t.transaction.emptyMonthSubtitle,
          actionLabel: t.transaction.emptyMonthCta,
          actionIcon: IconKey.add,
          onAction: onRecord,
        ),
        AppSectionHeader(t.transaction.emptyGuideTitle),
        AppListCard(
          children: [
            for (final (kind, icon, title, description) in [
              (
                TransactionKind.income,
                IconKey.income,
                t.transaction.emptyGuideIncomeTitle,
                t.transaction.emptyGuideIncomeDescription,
              ),
              (
                TransactionKind.expense,
                IconKey.expense,
                t.transaction.emptyGuideExpenseTitle,
                t.transaction.emptyGuideExpenseDescription,
              ),
              (
                TransactionKind.transfer,
                IconKey.transfer,
                t.transaction.emptyGuideTransferTitle,
                t.transaction.emptyGuideTransferDescription,
              ),
            ])
              AppListRow(
                leading: AppIconTile(icon, tint: _guideTint[kind]),
                title: title,
                subtitle: description,
                wrapTitle: true,
                wrapSubtitle: true,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(IconKey.locked, size: 18, color: colors.ink3),
            const SizedBox(width: AppSpacing.space2),
            Flexible(
              child: Text(
                t.transaction.trustFooterMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colors.ink3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const Map<TransactionKind, TileTint> _guideTint = {
  TransactionKind.income: TileTint.green,
  TransactionKind.expense: TileTint.rose,
  TransactionKind.transfer: TileTint.slate,
};

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
  Widget build(BuildContext context) => Center(
    child: AppEmptyState(
      title: t.transaction.emptyFilterTitle,
      body: t.transaction.emptyFilterSubtitle,
      actionLabel: t.transaction.clearFiltersButton,
      onAction: onClearFilters,
      textAction: true,
    ),
  );
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
        padding: const EdgeInsets.only(top: AppSpacing.space4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSpacing.space2),
            Text(t.transaction.crossMonthSearchingLabel, style: TextStyle(color: colors.ink2)),
          ],
        ),
      );
    }

    if (!hasScanned) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space4),
        child: Center(
          child: AppButton.secondary(label: t.transaction.crossMonthSearchButton, onPressed: onSearch),
        ),
      );
    }

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space4),
        child: Column(
          children: [
            Text(
              t.transaction.crossMonthNoMoreResults,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.ink2),
            ),
            if (!exhausted) ...[
              const SizedBox(height: AppSpacing.space2),
              AppButton.secondary(label: t.transaction.crossMonthLoadMoreButton, onPressed: onSearch),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.transaction.crossMonthResultsHeader,
            style: labelSmStyle(context, color: colors.ink2),
          ),
          const SizedBox(height: AppSpacing.space2),
          for (final group in groups) ...[
            TransactionDateGroupCard(group: group, walletsById: walletsById, onTransactionTap: onTransactionTap),
            const SizedBox(height: AppSpacing.space4),
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
  Widget build(BuildContext context) => AppErrorState(
    title: t.transaction.loadErrorTitle,
    body: t.transaction.loadErrorSubtitle,
    retryLabel: t.common.retry,
    onRetry: onRetry,
  );
}
