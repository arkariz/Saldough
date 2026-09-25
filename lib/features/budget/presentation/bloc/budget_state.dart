import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Penyaring status di layar Anggaran (FR-BUD-006).
enum BudgetStatusFilter {
  /// Seluruh anggaran.
  all,

  /// Hanya [BudgetStatus.active].
  active,

  /// Hanya [BudgetStatus.finished].
  finished,

  /// Hanya [BudgetStatus.archived].
  archived;

  /// Apakah anggaran berstatus [status] lolos penyaring ini.
  bool matches(BudgetStatus status) => switch (this) {
    BudgetStatusFilter.all => true,
    BudgetStatusFilter.active => status == BudgetStatus.active,
    BudgetStatusFilter.finished => status == BudgetStatus.finished,
    BudgetStatusFilter.archived => status == BudgetStatus.archived,
  };
}

/// State `BudgetBloc`.
///
/// [progress] dihitung ulang oleh bloc setiap kali anggaran atau transaksi
/// dimuat — tidak pernah disimpan ke penyimpanan (FR-BUD-003).
final class BudgetState extends UiState<BudgetState> {
  /// Membuat [BudgetState].
  const BudgetState({
    required this.budgets,
    required this.wallets,
    required this.transactions,
    required this.progress,
    required this.isLoading,
    this.loadFailed = false,
    this.statusFilter = BudgetStatusFilter.all,
    this.walletFilter,
    super.effect,
  });

  /// State awal, sebelum apa pun dimuat.
  factory BudgetState.initial() => const BudgetState(
    budgets: [],
    wallets: [],
    transactions: [],
    progress: {},
    isLoading: true,
  );

  /// Seluruh anggaran, termasuk yang diarsipkan, urut penyimpanan.
  final List<Budget> budgets;

  /// Seluruh dompet, aktif maupun tidak — nama dompet anggaran harus tetap
  /// terbaca walau dompetnya sudah dinonaktifkan.
  final List<Wallet> wallets;

  /// Seluruh transaksi yang dipakai menghitung [progress].
  final List<Transaction> transactions;

  /// Progres tiap anggaran, per `Budget.id`.
  final Map<String, BudgetProgress> progress;

  /// Sedang memuat untuk pertama kali.
  final bool isLoading;

  /// Pembacaan terakhir gagal — dibedakan dari daftar yang memang kosong.
  final bool loadFailed;

  /// Penyaring status aktif.
  final BudgetStatusFilter statusFilter;

  /// Penyaring dompet aktif, `null` = semua dompet.
  final String? walletFilter;

  /// Dompet ber-`id` [walletId], atau `null` kalau sudah dihapus.
  Wallet? walletOf(String walletId) {
    for (final wallet in wallets) {
      if (wallet.id == walletId) return wallet;
    }
    return null;
  }

  /// Dompet aktif — pilihan dompet saat membuat anggaran baru.
  List<Wallet> get activeWallets => wallets.where((w) => w.isActive).toList();

  /// Anggaran yang lolos kedua penyaring, urut: aktif, selesai, nonaktif;
  /// di dalam tiap kelompok yang periodenya paling baru di atas.
  List<Budget> get visibleBudgets {
    final visible =
        budgets
            .where((b) => walletFilter == null || b.walletId == walletFilter)
            .where((b) => statusFilter.matches(progress[b.id]!.status))
            .toList()
          ..sort((a, b) {
            final byStatus = progress[a.id]!.status.index.compareTo(progress[b.id]!.status.index);
            return byStatus != 0 ? byStatus : b.startDate.compareTo(a.startDate);
          });
    return visible;
  }

  /// Jumlah anggaran per penyaring status, dalam lingkup [walletFilter].
  Map<BudgetStatusFilter, int> get statusCounts {
    final inWallet = budgets.where((b) => walletFilter == null || b.walletId == walletFilter);
    return {
      for (final filter in BudgetStatusFilter.values)
        filter: inWallet.where((b) => filter.matches(progress[b.id]!.status)).length,
    };
  }

  /// Progres seluruh anggaran AKTIF (lintas dompet, mengabaikan penyaring) —
  /// ringkasan puncak layar Anggaran (FR-BUD-004).
  List<BudgetProgress> get activeProgress => progress.values.where((p) => p.status == BudgetStatus.active).toList();

  /// Total rencana anggaran aktif, sen.
  int get activePlanned => activeProgress.fold(0, (sum, p) => sum + p.plannedAmount);

  /// Total terpakai anggaran aktif, sen.
  int get activeSpent => activeProgress.fold(0, (sum, p) => sum + p.spent);

  /// Transaksi yang tertaut ke salah satu pos [budget] dan benar-benar
  /// terhitung (aturan yang sama dengan progres, [countsTowardBudgetItem]),
  /// terbaru di atas.
  List<Transaction> linkedTransactions(Budget budget) {
    final itemsById = {for (final item in budget.items) item.id: item};
    return transactions.where((transaction) {
      final itemId = switch (transaction) {
        ExpenseTransaction(:final budgetItemId) || TransferTransaction(:final budgetItemId) => budgetItemId,
        IncomeTransaction() => null,
      };
      final item = itemsById[itemId];
      return item != null && countsTowardBudgetItem(budget, item, transaction);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// `id` pos [budget] yang sudah punya transaksi tertaut — jenisnya dikunci
  /// (ADR-018), supaya transaksi lama tidak diam-diam berhenti terhitung.
  Set<String> lockedItemIds(Budget budget) => {
    for (final transaction in linkedTransactions(budget))
      if (transaction case ExpenseTransaction(:final budgetItemId?) || TransferTransaction(:final budgetItemId?))
        budgetItemId,
  };

  @override
  BudgetState copyWith({
    List<Budget>? budgets,
    List<Wallet>? wallets,
    List<Transaction>? transactions,
    Map<String, BudgetProgress>? progress,
    bool? isLoading,
    bool? loadFailed,
    BudgetStatusFilter? statusFilter,
    String? Function()? walletFilter,
    UiEffect? effect,
  }) {
    return BudgetState(
      budgets: budgets ?? this.budgets,
      wallets: wallets ?? this.wallets,
      transactions: transactions ?? this.transactions,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      statusFilter: statusFilter ?? this.statusFilter,
      walletFilter: walletFilter != null ? walletFilter() : this.walletFilter,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [
    budgets,
    wallets,
    transactions,
    progress,
    isLoading,
    loadFailed,
    statusFilter,
    walletFilter,
  ];
}
