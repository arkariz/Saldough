import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/plan/domain/plan_sources.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State `PlanMonthBloc`: data mentah satu bulan keuangan. Uang nganggur dan
/// perkiraan dihitung dari sini lewat fungsi murni `shared/recurring`, tidak
/// disimpan (ADR-035 §3.5).
final class PlanMonthState extends UiState<PlanMonthState> {
  /// Membuat [PlanMonthState].
  const PlanMonthState({
    required this.today,
    required this.range,
    this.isLoading = true,
    this.loadFailed = false,
    this.wallets = const [],
    this.rules = const [],
    this.transactions = const [],
    this.budgets = const [],
    this.uncertain = const [],
    this.historyStart,
    this.walletId,
    this.includeUnplanned = true,
    super.effect,
  });

  /// Hari ini saat dimuat.
  final DateTime today;

  /// Bulan keuangan berjalan.
  final FinancialMonthRange range;

  /// Sedang memuat pertama kali.
  final bool isLoading;

  /// Pemuatan terakhir gagal.
  final bool loadFailed;

  /// Dompet aktif.
  final List<Wallet> wallets;

  /// Seluruh rutin.
  final List<RecurringRule> rules;

  /// Transaksi tiga bulan keuangan lalu sampai akhir bulan ini.
  final List<Transaction> transactions;

  /// Anggaran yang dimulai di bulan ini.
  final List<PlanBudget> budgets;

  /// Freelance belum dibayar.
  final List<UncertainIncome> uncertain;

  /// Tanggal transaksi pertama di riwayat, untuk "di luar rencana" (KT-R3).
  final DateTime? historyStart;

  /// Dompet pada kartu saldo; `null` = semua.
  final String? walletId;

  /// Sakelar "Hitung jajan harian" (di luar rencana, §7.5).
  final bool includeUnplanned;

  /// Belum ada rencana sama sekali: keadaan kosong.
  bool get isEmpty => rules.isEmpty && budgets.isEmpty;

  /// Uang nganggur bulan ini (§7.2, §7.2a).
  MonthPlan get plan => monthPlan(
    rules,
    from: range.start,
    until: range.end,
    today: today,
    transactions: [
      for (final t in transactions)
        if (range.contains(t.date)) t,
    ],
    budgetLines: [for (final b in budgets) ...b.lines],
  );

  /// Tiga bulan keuangan penuh sebelum bulan ini, terbaru dulu.
  List<({DateTime start, DateTime end})> get _previousMonths => [
    for (var back = 1; back <= 3; back++)
      () {
        final r = financialMonthOf(
          DateTime(range.start.year, range.start.month - back, range.start.day),
          range.start.day,
        );
        return (start: r.start, end: r.end);
      }(),
  ];

  /// Rata-rata harian di luar rencana untuk [walletId], atau `null` bila
  /// riwayat belum sebulan penuh.
  int? get unplannedAverage => unplannedDailyAverage(
    transactions,
    months: _previousMonths,
    historyStart: historyStart,
    ruleIds: {for (final rule in rules) rule.id},
    walletId: walletId,
  );

  /// Saldo nyata dompet terpilih atau seluruh dompet aktif.
  int get currentBalance =>
      wallets.where((w) => walletId == null || w.id == walletId).fold(0, (sum, w) => sum + w.currentBalance);

  /// Perkiraan saldo sampai akhir bulan keuangan (§7.3–7.5).
  CashflowProjection get projection => projectCashflow(
    rules,
    startBalance: currentBalance,
    today: today,
    until: range.end,
    pendingFrom: range.start,
    transactions: transactions,
    budgets: [
      for (final b in budgets)
        for (final line in b.lines)
          (
            walletId: b.walletId,
            key: line.key,
            remaining: line.planned > line.spent ? line.planned - line.spent : 0,
            periodEnd: b.periodEnd,
          ),
    ],
    unplannedPerDay: includeUnplanned ? unplannedAverage : null,
    uncertainIncome: uncertain,
    walletId: walletId,
  );

  /// Tiga kemunculan berikutnya sesudah hari ini di bulan ini.
  List<Occurrence> get nextOccurrences {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final all = [
      for (final rule in rules)
        if (!rule.isPaused)
          ...occurrenceStatusesOf(
            rule,
            from: tomorrow,
            until: range.end,
            today: today,
            transactions: transactions,
          ).where((o) => o.status == OccurrenceStatus.upcoming),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return all.take(3).toList();
  }

  @override
  PlanMonthState copyWith({
    DateTime? today,
    FinancialMonthRange? range,
    bool? isLoading,
    bool? loadFailed,
    List<Wallet>? wallets,
    List<RecurringRule>? rules,
    List<Transaction>? transactions,
    List<PlanBudget>? budgets,
    List<UncertainIncome>? uncertain,
    DateTime? historyStart,
    String? Function()? walletId,
    bool? includeUnplanned,
    UiEffect? effect,
  }) => PlanMonthState(
    today: today ?? this.today,
    range: range ?? this.range,
    isLoading: isLoading ?? this.isLoading,
    loadFailed: loadFailed ?? this.loadFailed,
    wallets: wallets ?? this.wallets,
    rules: rules ?? this.rules,
    transactions: transactions ?? this.transactions,
    budgets: budgets ?? this.budgets,
    uncertain: uncertain ?? this.uncertain,
    historyStart: historyStart ?? this.historyStart,
    walletId: walletId == null ? this.walletId : walletId(),
    includeUnplanned: includeUnplanned ?? this.includeUnplanned,
    effect: effect,
  );

  @override
  List<Object?> get props => [
    today,
    range,
    isLoading,
    loadFailed,
    wallets,
    rules,
    transactions,
    budgets,
    uncertain,
    historyStart,
    walletId,
    includeUnplanned,
  ];
}
