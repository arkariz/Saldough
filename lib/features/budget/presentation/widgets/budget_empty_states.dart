import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Keadaan kosong layar Anggaran, dengan ilustrasi yang bergerak terus.
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
    final ds = context.ds;
    final hasWallet = onAdd != null;
    return DsReveal(
      child: DsCard(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          children: [
            DsEmptyHero(
              asset: hasWallet ? ClayIcons.piggy : ClayIcons.walletNav,
              orbit: hasWallet
                  ? const [ClayIcons.cash, ClayIcons.calendar, ClayIcons.chart]
                  : const [ClayIcons.bank, ClayIcons.ewallet, ClayIcons.cash],
            ),
            const SizedBox(height: 12),
            Text(
              hasWallet ? t.budget.emptyTitle : t.budget.noWalletTitle,
              textAlign: TextAlign.center,
              style: ds.typography.titleMd.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              hasWallet ? t.budget.emptyBody : t.budget.noWalletBody,
              textAlign: TextAlign.center,
              style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
            ),
            if (hasWallet) ...[
              const SizedBox(height: 16),
              DsButton(label: t.budget.addAction, icon: Icons.add, onPressed: onAdd),
            ],
          ],
        ),
      ),
    );
  }
}

/// Kosong karena penyaring: tombol hantu mengembalikan penyaring.
class BudgetFilteredEmptyState extends StatelessWidget {
  /// Membuat [BudgetFilteredEmptyState].
  const BudgetFilteredEmptyState({required this.onReset, super.key});

  /// Mengembalikan penyaring ke semua status dan semua dompet.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsReveal(
      child: DsCard(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
        child: Column(
          children: [
            const DsEmptyHero(asset: ClayIcons.emptyTray, orbit: [ClayIcons.tag], size: 104),
            const SizedBox(height: 8),
            Text(t.budget.emptyFilteredTitle, textAlign: TextAlign.center, style: ds.typography.titleMd),
            const SizedBox(height: 4),
            Text(
              t.budget.emptyFilteredBody,
              textAlign: TextAlign.center,
              style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
            ),
            const SizedBox(height: 12),
            DsButton.ghost(label: t.budget.resetFilterAction, onPressed: onReset),
          ],
        ),
      ),
    );
  }
}

/// Keadaan galat layar Anggaran: pembacaan gagal, dengan tombol coba lagi.
class BudgetLoadErrorState extends StatelessWidget {
  /// Membuat [BudgetLoadErrorState].
  const BudgetLoadErrorState({required this.onRetry, super.key});

  /// Dipanggil saat tombol coba lagi ditekan.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => DsErrorState(
    title: t.budget.loadErrorTitle,
    body: t.budget.loadErrorSubtitle,
    retryLabel: t.common.retry,
    onRetry: onRetry,
  );
}
