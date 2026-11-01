import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
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
  Widget build(BuildContext context) {
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DsIconTile.asset(asset: ClayIcons.walletNav, size: DsIconTileSize.lg),
          const SizedBox(height: 12),
          Text(t.wallet.emptyTitle, textAlign: TextAlign.center, style: ds.typography.titleMd.copyWith(fontSize: 17)),
          const SizedBox(height: 4),
          Text(
            t.wallet.emptyBody,
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
          ),
          const SizedBox(height: 16),
          DsButton(label: t.wallet.addAction, icon: Icons.add, onPressed: onAdd),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) => DsErrorState(
    illustration: SvgPicture.asset(ClayIcons.warning, width: 40, height: 40),
    title: t.wallet.loadErrorTitle,
    body: t.wallet.loadErrorSubtitle,
    retryLabel: t.common.retry,
    onRetry: onRetry,
  );
}
