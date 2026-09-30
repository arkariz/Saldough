part of 'wallet_activity_bloc.dart';

/// Event [WalletActivityBloc].
sealed class WalletActivityEvent {
  /// Membuat [WalletActivityEvent].
  const WalletActivityEvent();
}

/// Memuat transaksi bulan berjalan yang menyentuh dompet [walletId].
final class WalletActivityStarted extends WalletActivityEvent {
  /// Membuat [WalletActivityStarted].
  const WalletActivityStarted(this.walletId);

  /// Dompet yang ditampilkan.
  final String walletId;
}

/// Memuat ulang tanpa kerangka sesudah `LedgerChanges`.
final class _WalletActivityRefreshed extends WalletActivityEvent {
  const _WalletActivityRefreshed();
}
