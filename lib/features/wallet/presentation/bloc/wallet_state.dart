import 'package:saldough/shared/investment/investment.dart';
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
    this.instruments = const [],
    this.investmentsFailed = false,
    this.sheetLinked = false,
    this.sheetFetchedAt,
    this.sheetRefreshing = false,
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

  /// Ringkasan instrumen investasi (ADR-049 §3.10), urut dibuat.
  final List<InstrumentSummary> instruments;

  /// Pembacaan investasi terakhir gagal: segmen Investasi menampilkan galat
  /// dan lapis Investasi tidak dihitung (rupa B-97 §1.3).
  final bool investmentsFailed;

  /// Sheet harga sudah terhubung (ADR-051).
  final bool sheetLinked;

  /// Kapan harga terakhir diambil dari Sheet, untuk penanda "· 19.25".
  final DateTime? sheetFetchedAt;

  /// Pengambilan harga sedang berjalan.
  final bool sheetRefreshing;

  /// Instrumen Aktif, nilai pasar terbesar dulu (rupa B-97 §1.2).
  List<InstrumentSummary> get activeInstruments =>
      instruments.where((s) => s.position.isActive).toList()..sort((a, b) => b.marketValue.compareTo(a.marketValue));

  /// Instrumen Selesai.
  List<InstrumentSummary> get closedInstruments => instruments.where((s) => !s.position.isActive).toList();

  /// Id dompet milik tujuan (ADR-048 §8.3): tidak tampil di grid dompet dan
  /// daftar nonaktif.
  Set<String> get goalWallets => goalWalletIds(goals);

  /// Total aset per lapis (ADR-050).
  WealthLayers get layers => WealthLayers.of(
    wallets,
    goalWalletIds: goalWallets,
    investment: investmentsFailed ? 0 : investmentLayerValue(instruments),
  );

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
    List<InstrumentSummary>? instruments,
    bool? investmentsFailed,
    bool? sheetLinked,
    DateTime? Function()? sheetFetchedAt,
    bool? sheetRefreshing,
    UiEffect? effect,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      goals: goals ?? this.goals,
      instruments: instruments ?? this.instruments,
      investmentsFailed: investmentsFailed ?? this.investmentsFailed,
      sheetLinked: sheetLinked ?? this.sheetLinked,
      sheetFetchedAt: sheetFetchedAt == null ? this.sheetFetchedAt : sheetFetchedAt(),
      sheetRefreshing: sheetRefreshing ?? this.sheetRefreshing,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [
    wallets,
    isLoading,
    loadFailed,
    goals,
    instruments,
    investmentsFailed,
    sheetLinked,
    sheetFetchedAt,
    sheetRefreshing,
  ];
}
