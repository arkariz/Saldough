import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wealth/wealth.dart';
import 'package:state_management/state_management.dart';

/// State `WalletBloc`.
final class WalletState extends UiState<WalletState> {
  /// Membuat [WalletState].
  const WalletState({
    required this.wallets,
    required this.isLoading,
    this.loadFailed = false,
    this.goals = const [],
    super.effect,
  });

  /// State awal, sebelum dompet dimuat.
  factory WalletState.initial() => const WalletState(wallets: [], isLoading: true);

  /// Seluruh dompet, aktif maupun tidak, sesuai urutan penyimpanan.
  final List<Wallet> wallets;

  /// Sedang memuat dompet untuk pertama kali.
  final bool isLoading;

  /// `true` kalau pembacaan TERAKHIR gagal -- dibedakan dari [wallets] yang
  /// genuinely kosong, supaya layar tidak menampilkan "belum ada dompet" yang
  /// menyesatkan saat masalah sesungguhnya adalah pembacaan yang gagal.
  final bool loadFailed;

  /// Tujuan tabungan (ADR-048), untuk bagian Tujuan dan lencana dompet.
  final List<SavingsGoal> goals;

  /// Id dompet milik tujuan (ADR-048 §8.3): tidak tampil di grid dompet dan
  /// daftar nonaktif.
  Set<String> get goalWallets => goalWalletIds(goals);

  /// Total aset per lapis (ADR-050).
  WealthLayers get layers => WealthLayers.of(wallets, goalWalletIds: goalWallets);

  /// Dompet aktif yang bukan milik tujuan: lapis Dana operasional (ADR-050).
  List<Wallet> get operationalWallets =>
      wallets.where((w) => w.isActive && !goalWallets.contains(w.id)).toList();

  /// Dompet aktif -- yang muncul di daftar utama dan pemilih dompet.
  List<Wallet> get activeWallets => wallets.where((wallet) => wallet.isActive).toList();

  /// Dompet nonaktif -- transaksinya tetap ada dan tetap dihitung.
  List<Wallet> get inactiveWallets =>
      wallets.where((wallet) => !wallet.isActive && !goalWallets.contains(wallet.id)).toList();

  /// Total saldo tercatat SELURUH dompet aktif, dalam sen (FR-WAL-003).
  /// Dompet nonaktif tidak ikut dijumlahkan. Boleh negatif.
  int get totalBalance => activeWallets.fold(0, (sum, wallet) => sum + wallet.currentBalance);

  @override
  WalletState copyWith({
    List<Wallet>? wallets,
    bool? isLoading,
    bool? loadFailed,
    List<SavingsGoal>? goals,
    UiEffect? effect,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      goals: goals ?? this.goals,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [wallets, isLoading, loadFailed, goals];
}
