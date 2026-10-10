import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/home/domain/budget_overview_source.dart';
import 'package:saldough/features/home/domain/freelance_overview_source.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State `HomeBloc`. Seluruh nominal dalam sen.
final class HomeState extends UiState<HomeState> {
  /// Membuat [HomeState].
  const HomeState({
    required this.wallets,
    required this.recentTransactions,
    required this.hasTransactions,
    required this.period,
    required this.cashFlow,
    required this.budget,
    required this.freelance,
    required this.isLoading,
    this.loadFailed = false,
    super.effect,
  });

  /// State awal, sebelum apa pun dimuat.
  factory HomeState.initial() => HomeState(
    wallets: const [],
    recentTransactions: const [],
    hasTransactions: false,
    period: FinancialPeriod(start: DateTime(2000), end: DateTime(2000, 2)),
    cashFlow: const CashFlow(income: 0, expense: 0),
    budget: null,
    freelance: null,
    isLoading: true,
  );

  /// Seluruh dompet, aktif maupun tidak — nama dompet di transaksi lama tetap
  /// harus terbaca.
  final List<Wallet> wallets;

  /// Beberapa transaksi terbaru, tanggal terbaru di atas (FR-HOME-004).
  final List<Transaction> recentTransactions;

  /// Apakah sudah ada satu pun transaksi tercatat (FR-HOME-005).
  final bool hasTransactions;

  /// Periode keuangan berjalan saat dimuat (FR-HOME-001, ADR-038 §3.6).
  final FinancialPeriod period;

  /// Pemasukan dan pengeluaran [period]; transfer tidak dihitung.
  final CashFlow cashFlow;

  /// Ringkasan anggaran aktif, atau `null` kalau tidak ada anggaran aktif —
  /// kartunya disembunyikan, bukan diisi angka nol (FR-HOME-005).
  final BudgetOverview? budget;

  /// Ringkasan freelance, atau `null` kalau tidak ada pembayaran tertunda
  /// (FR-HOME-003).
  final FreelanceOverview? freelance;

  /// Sedang memuat untuk pertama kali.
  final bool isLoading;

  /// Pembacaan terakhir gagal.
  final bool loadFailed;

  /// Dompet aktif.
  List<Wallet> get activeWallets => wallets.where((w) => w.isActive).toList();

  /// Belum ada dompet sama sekali.
  bool get hasNoWallets => wallets.isEmpty;

  /// Total saldo tercatat dompet aktif (FR-HOME-001), sama dengan
  /// `WalletState.totalBalance`. Boleh negatif.
  int get totalBalance => activeWallets.fold(0, (sum, w) => sum + w.currentBalance);

  /// Peta `id` → dompet, untuk baris transaksi.
  Map<String, Wallet> get walletsById => {for (final w in wallets) w.id: w};

  @override
  HomeState copyWith({bool? isLoading, bool? loadFailed, UiEffect? effect}) => HomeState(
    wallets: wallets,
    recentTransactions: recentTransactions,
    hasTransactions: hasTransactions,
    period: period,
    cashFlow: cashFlow,
    budget: budget,
    freelance: freelance,
    isLoading: isLoading ?? this.isLoading,
    loadFailed: loadFailed ?? this.loadFailed,
    effect: effect,
  );

  @override
  List<Object?> get props => [
    wallets,
    recentTransactions,
    hasTransactions,
    period,
    cashFlow,
    budget,
    freelance,
    isLoading,
    loadFailed,
  ];
}
