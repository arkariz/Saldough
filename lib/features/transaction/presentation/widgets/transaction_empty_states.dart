import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
    final ds = context.ds;
    final c = ds.colors;
    final guide = [
      (
        ClayIcons.incomeArrow,
        DsIconTileTone.income,
        t.transaction.emptyGuideIncomeTitle,
        t.transaction.emptyGuideIncomeDescription,
      ),
      (
        ClayIcons.expenseArrow,
        DsIconTileTone.neutral,
        t.transaction.emptyGuideExpenseTitle,
        t.transaction.emptyGuideExpenseDescription,
      ),
      (
        ClayIcons.transfer,
        DsIconTileTone.info,
        t.transaction.emptyGuideTransferTitle,
        t.transaction.emptyGuideTransferDescription,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
              const SizedBox(height: 12),
              Text(
                t.transaction.emptyMonthTitle,
                textAlign: TextAlign.center,
                style: ds.typography.titleMd,
              ),
              const SizedBox(height: 4),
              Text(
                t.transaction.emptyMonthSubtitle,
                textAlign: TextAlign.center,
                style: ds.typography.bodySm.copyWith(color: c.textMuted),
              ),
              const SizedBox(height: 16),
              DsButton(label: t.transaction.emptyMonthCta, icon: Icons.add, onPressed: onRecord),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DsSectionHeader(title: t.transaction.emptyGuideTitle),
        const SizedBox(height: 8),
        DsCard(
          child: Column(
            children: [
              for (final (i, (asset, tone, title, description)) in guide.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsIconTile.asset(asset: asset, tone: tone),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: ds.typography.titleMd.copyWith(fontSize: 14)),
                          Text(description, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 16, color: c.textMuted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                t.transaction.trustFooterMessage,
                textAlign: TextAlign.center,
                style: ds.typography.bodySm.copyWith(color: c.textMuted),
              ),
            ),
          ],
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
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
          const SizedBox(height: 12),
          Text(t.transaction.emptyFilterTitle, textAlign: TextAlign.center, style: ds.typography.titleMd),
          const SizedBox(height: 4),
          Text(
            t.transaction.emptyFilterSubtitle,
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
          ),
          const SizedBox(height: 12),
          DsButton.ghost(label: t.transaction.clearFiltersButton, onPressed: onClearFilters),
        ],
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
    final ds = context.ds;
    final c = ds.colors;

    if (isSearching) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text(t.transaction.crossMonthSearchingLabel, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
          ],
        ),
      );
    }

    if (!hasScanned) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Center(
          child: DsButton.secondary(label: t.transaction.crossMonthSearchButton, onPressed: onSearch),
        ),
      );
    }

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Text(
              t.transaction.crossMonthNoMoreResults,
              textAlign: TextAlign.center,
              style: ds.typography.bodySm.copyWith(color: c.textSecondary),
            ),
            if (!exhausted) ...[
              const SizedBox(height: 8),
              DsButton.secondary(label: t.transaction.crossMonthLoadMoreButton, onPressed: onSearch),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.transaction.crossMonthResultsHeader,
            style: ds.typography.labelMd.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          for (final group in groups) ...[
            TransactionDateGroupCard(group: group, walletsById: walletsById, onTransactionTap: onTransactionTap),
            const SizedBox(height: 16),
          ],
          if (!exhausted)
            Center(
              child: DsButton.secondary(label: t.transaction.crossMonthLoadMoreButton, onPressed: onSearch),
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
  Widget build(BuildContext context) => DsErrorState(
    title: t.transaction.loadErrorTitle,
    body: t.transaction.loadErrorSubtitle,
    retryLabel: t.common.retry,
    onRetry: onRetry,
  );
}
