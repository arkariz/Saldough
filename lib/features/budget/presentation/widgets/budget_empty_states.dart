import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Keadaan kosong layar Anggaran (design system EmptyState, ilustrasi
/// Anggaran).
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
    final hasWallet = onAdd != null;
    return AppEmptyState(
      art: EmptyArt.budget,
      title: hasWallet ? t.budget.emptyTitle : t.budget.noWalletTitle,
      body: hasWallet ? t.budget.emptyBody : t.budget.noWalletBody,
      actionLabel: t.budget.addAction,
      actionIcon: IconKey.add,
      onAction: onAdd,
    );
  }
}

/// Kosong karena penyaring: tanpa ilustrasi, tombol teks mengembalikan
/// penyaring (design system EmptyState, varian penyaring).
class BudgetFilteredEmptyState extends StatelessWidget {
  /// Membuat [BudgetFilteredEmptyState].
  const BudgetFilteredEmptyState({required this.onReset, super.key});

  /// Mengembalikan penyaring ke semua status dan semua dompet.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    title: t.budget.emptyFilteredTitle,
    body: t.budget.emptyFilteredBody,
    actionLabel: t.budget.resetFilterAction,
    onAction: onReset,
    textAction: true,
  );
}

/// Keadaan galat layar Anggaran: pembacaan gagal, dengan tombol coba lagi.
class BudgetLoadErrorState extends StatelessWidget {
  /// Membuat [BudgetLoadErrorState].
  const BudgetLoadErrorState({required this.onRetry, super.key});

  /// Dipanggil saat tombol coba lagi ditekan.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppErrorState(
    title: t.budget.loadErrorTitle,
    body: t.budget.loadErrorSubtitle,
    retryLabel: t.common.retry,
    onRetry: onRetry,
  );
}
