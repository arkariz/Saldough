import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

/// Keadaan kosong layar Dompet: belum ada dompet sama sekali, dengan ajakan
/// menambah dompet pertama (design system EmptyState, ilustrasi Dompet).
class WalletEmptyState extends StatelessWidget {
  /// Membuat [WalletEmptyState].
  const WalletEmptyState({required this.onAdd, super.key});

  /// Dipanggil saat tombol tambah dompet ditekan.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    art: EmptyArt.wallets,
    title: t.wallet.emptyTitle,
    body: t.wallet.emptyBody,
    actionLabel: t.wallet.addAction,
    actionIcon: IconKey.add,
    onAction: onAdd,
  );
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
  Widget build(BuildContext context) => AppErrorState(
    title: t.wallet.loadErrorTitle,
    body: t.wallet.loadErrorSubtitle,
    retryLabel: t.common.retry,
    onRetry: onRetry,
  );
}
