import 'package:navigation/navigation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

// Satu-satunya berkas fitur `wallet` yang boleh diimpor fitur lain
// (ADR-0004, ADR-030 §3.3).

/// Input rincian satu dompet (FR-WAL-004).
final class WalletDetailInput extends RouteInput {
  /// Membuat [WalletDetailInput].
  const WalletDetailInput(this.wallet);

  /// Dompet yang dibuka (cuplikan; layar memakai salinan terbaru dari
  /// `WalletBloc` begitu termuat).
  final Wallet wallet;
}

/// Kunci rute fitur `wallet`.
abstract final class WalletRouteKeys {
  /// Rincian satu dompet.
  static const detail = RouteKey<WalletDetailInput>('wallet.detail');
}
