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
    this.laterBudgets = const [],
    this.selected = 0,
    super.effect,
  });

  /// Horizon perkiraan: bulan berjalan + 2 (ADR-036 §3.5, keputusan pemilik).
  static const horizon = 2;

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

  /// Anggaran bulan depan dan sesudahnya (indeks 0 = bulan berjalan + 1),
  /// termasuk periode virtual anggaran rutin (ADR-036 §3.5).
  final List<List<PlanBudget>> laterBudgets;

  /// Bulan terpilih di pemilih bulan: 0 = bulan berjalan.
  final int selected;

  /// Bulan berjalan dan [horizon] bulan sesudahnya.
  List<FinancialMonthRange> get months => [
    range,
    for (var k = 1; k <= horizon; k++)
      financialMonthOf(DateTime(range.start.year, range.start.month + k, range.start.day), range.start.day),
  ];

  /// Bulan terpilih.
  FinancialMonthRange get selectedRange => months[selected];

  /// Bulan terpilih adalah bulan depan: seluruh isinya perkiraan.
  bool get isFuture => selected > 0;

  /// Anggaran yang terhitung di bulan ke-[k].
  List<PlanBudget> budgetsFor(int k) => k == 0
      ? budgets
      : k - 1 < laterBudgets.length
      ? laterBudgets[k - 1]
      : const [];

  /// Belum ada rencana sama sekali: keadaan kosong.
  bool get isEmpty => rules.isEmpty && budgets.isEmpty;

  /// Uang nganggur bulan terpilih (§7.2, §7.2a).
  MonthPlan get plan => planFor(selected);

  /// Uang nganggur bulan ke-[k]. Bulan depan belum punya transaksi.
  MonthPlan planFor(int k) {
    final m = months[k];
    return monthPlan(
      rules,
      from: m.start,
      until: m.end,
      today: today,
      transactions: [
        for (final t in transactions)
          if (m.contains(t.date)) t,
      ],
      budgetLines: [for (final b in budgetsFor(k)) ...b.lines],
    );
  }

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

  /// Perkiraan saldo bulan terpilih (§7.3–7.5).
  CashflowProjection get projection => projectionFor(selected);

  /// Perkiraan bulan ke-[k]: satu hitungan sejak hari ini, dilaporkan mulai
  /// awal bulan itu, jadi saldo awalnya = perkiraan akhir bulan sebelumnya
  /// (invarian 20).
  CashflowProjection projectionFor(int k) => projectCashflow(
    rules,
    startBalance: currentBalance,
    today: today,
    until: months[k].end,
    pendingFrom: range.start,
    transactions: transactions,
    budgets: [
      for (var i = 0; i <= k; i++)
        for (final b in budgetsFor(i))
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
    reportFrom: k == 0 ? null : months[k].start,
  );

  /// Peringatan siapkan dana (W1, ADR-036 §3.6) dari perkiraan per dompet,
  /// tidak tergantung dompet atau bulan yang sedang dipilih.
  List<FundingWarning> get fundingWarnings => planFundingWarnings(this);

  /// Tiga kemunculan berikutnya di bulan terpilih (bulan berjalan: sesudah
  /// hari ini).
  List<Occurrence> get nextOccurrences {
    final m = selectedRange;
    final from = isFuture ? m.start : DateTime(today.year, today.month, today.day + 1);
    final all = [
      for (final rule in rules)
        if (!rule.isPaused)
          ...occurrenceStatusesOf(
            rule,
            from: from,
            until: m.end,
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
    List<List<PlanBudget>>? laterBudgets,
    int? selected,
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
    laterBudgets: laterBudgets ?? this.laterBudgets,
    selected: selected ?? this.selected,
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
    laterBudgets,
    selected,
  ];
}

/// Perkiraan satu dompet sampai akhir bulan depan (cukup untuk H−3), dengan
/// rata-rata di luar rencana dompet itu (ADR-036 §3.6).
List<FundingWarning> planFundingWarnings(PlanMonthState state) {
  final months = state.months;
  return fundingWarnings(
    state.rules,
    today: state.today,
    transactions: state.transactions,
    walletName: (id) => state.wallets.where((w) => w.id == id).firstOrNull?.name ?? '',
    projectionOf: (walletId) => projectCashflow(
      state.rules,
      startBalance: state.wallets.where((w) => w.id == walletId).fold(0, (sum, w) => sum + w.currentBalance),
      today: state.today,
      until: months[1].end,
      pendingFrom: state.range.start,
      transactions: state.transactions,
      budgets: [
        for (var i = 0; i <= 1; i++)
          for (final b in state.budgetsFor(i))
            for (final line in b.lines)
              (
                walletId: b.walletId,
                key: line.key,
                remaining: line.planned > line.spent ? line.planned - line.spent : 0,
                periodEnd: b.periodEnd,
              ),
      ],
      unplannedPerDay: state.includeUnplanned
          ? unplannedDailyAverage(
              state.transactions,
              months: [
                for (var back = 1; back <= 3; back++)
                  () {
                    final r = financialMonthOf(
                      DateTime(state.range.start.year, state.range.start.month - back, state.range.start.day),
                      state.range.start.day,
                    );
                    return (start: r.start, end: r.end);
                  }(),
              ],
              historyStart: state.historyStart,
              ruleIds: {for (final rule in state.rules) rule.id},
              walletId: walletId,
            )
          : null,
      uncertainIncome: state.uncertain,
      walletId: walletId,
    ),
  );
}
