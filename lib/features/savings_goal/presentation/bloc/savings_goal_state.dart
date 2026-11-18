part of 'savings_goal_bloc.dart';

/// Keadaan [SavingsGoalBloc].
final class SavingsGoalState extends UiState<SavingsGoalState> {
  /// Membuat [SavingsGoalState].
  const SavingsGoalState({
    required this.goals,
    required this.wallets,
    required this.transactions,
    required this.isLoading,
    this.idleAverage,
    this.loadFailed = false,
    this.saveCount = 0,
    super.effect,
  });

  /// Keadaan awal: memuat.
  factory SavingsGoalState.initial() =>
      const SavingsGoalState(goals: [], wallets: [], transactions: [], isLoading: true);

  /// Semua tujuan.
  final List<SavingsGoal> goals;

  /// Semua dompet, aktif maupun tidak.
  final List<Wallet> wallets;

  /// Semua transaksi, untuk riwayat tujuan.
  final List<Transaction> transactions;

  /// Rata-rata uang nganggur periode lengkap terakhir, atau `null`.
  final int? idleAverage;

  /// Sedang memuat pertama kali.
  final bool isLoading;

  /// Gagal memuat.
  final bool loadFailed;

  /// Bertambah tiap simpan atau hapus berhasil; formulir dan rincian menutup
  /// diri saat nilainya berubah.
  final int saveCount;

  /// Tujuan ber-`id` [id], atau `null`.
  SavingsGoal? goalById(String id) => goals.where((g) => g.id == id).firstOrNull;

  /// Kemajuan [goal] dari saldo dompet saat ini.
  SavingsGoalProgress progressOf(SavingsGoal goal) => SavingsGoalProgress.of(goal, wallets);

  /// Dompet milik [goal], atau `null`.
  Wallet? walletOf(SavingsGoal goal) => wallets.where((w) => w.id == goal.walletId).firstOrNull;

  /// Transaksi yang menyentuh dompet [goal], terbaru dulu.
  List<Transaction> historyOf(SavingsGoal goal) =>
      transactions.where((tx) => walletIdsOf(tx).contains(goal.walletId)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Perkiraan tanggal tercapai [goal] per [today] (ADR-048 §3.6, Plus).
  SavingsGoalEstimate estimateOf(SavingsGoal goal, {required DateTime today, required FinancialMonthSchedule schedule}) =>
      SavingsGoalEstimate.of(
        goal: goal,
        remaining: progressOf(goal).remaining,
        transactions: transactions,
        schedule: schedule,
        today: today,
        idleAverage: idleAverage,
      );

  @override
  SavingsGoalState copyWith({
    List<SavingsGoal>? goals,
    List<Wallet>? wallets,
    List<Transaction>? transactions,
    bool? isLoading,
    int? Function()? idleAverage,
    bool? loadFailed,
    int? saveCount,
    UiEffect? effect,
  }) {
    return SavingsGoalState(
      goals: goals ?? this.goals,
      wallets: wallets ?? this.wallets,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      idleAverage: idleAverage == null ? this.idleAverage : idleAverage(),
      loadFailed: loadFailed ?? this.loadFailed,
      saveCount: saveCount ?? this.saveCount,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [goals, wallets, transactions, idleAverage, isLoading, loadFailed, saveCount];
}
