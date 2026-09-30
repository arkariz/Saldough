import 'package:saldough/shared/transaction/transaction.dart';
import 'package:state_management/state_management.dart';

/// State `WalletActivityBloc`.
final class WalletActivityState extends UiState<WalletActivityState> {
  /// Membuat [WalletActivityState].
  const WalletActivityState({required this.transactions, required this.isLoading, super.effect});

  /// State awal, sebelum transaksi dimuat.
  factory WalletActivityState.initial() => const WalletActivityState(transactions: [], isLoading: true);

  /// Transaksi bulan berjalan yang menyentuh dompet, terbaru dulu.
  final List<Transaction> transactions;

  /// Sedang memuat untuk pertama kali.
  final bool isLoading;

  @override
  WalletActivityState copyWith({List<Transaction>? transactions, bool? isLoading, UiEffect? effect}) {
    return WalletActivityState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [transactions, isLoading];
}
