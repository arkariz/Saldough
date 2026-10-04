import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// State `RecurringBloc`: rutin, transaksi bulan-bulan yang dibaca, dan
/// dompet untuk nama. Kemunculan dan kelompok dihitung dari sini, tidak
/// disimpan (ADR-035 §3.2).
final class RecurringState extends UiState<RecurringState> {
  /// Membuat [RecurringState].
  const RecurringState({
    required this.rules,
    required this.transactions,
    required this.wallets,
    required this.today,
    this.isLoading = true,
    this.loadFailed = false,
    this.kindFilter,
    this.budgetOptions = const [],
    this.dismissedSuggestions = const {},
    this.autoRecorded = const [],
    super.effect,
  });

  /// State awal sebelum dimuat.
  factory RecurringState.initial(DateTime today) =>
      RecurringState(rules: const [], transactions: const [], wallets: const [], today: today);

  /// Seluruh rutin.
  final List<RecurringRule> rules;

  /// Transaksi bulan-bulan yang dibaca (lihat `RecurringBloc`).
  final List<Transaction> transactions;

  /// Seluruh dompet, untuk nama di baris.
  final List<Wallet> wallets;

  /// Hari ini saat terakhir dimuat.
  final DateTime today;

  /// Sedang memuat pertama kali.
  final bool isLoading;

  /// Pemuatan terakhir gagal.
  final bool loadFailed;

  /// Chip jenis terpilih; `null` = semua.
  final RecurringKind? kindFilter;

  /// Pos anggaran untuk tautan rutin ke pos (ADR-036 §3.4).
  final List<BudgetItemOption> budgetOptions;

  /// Kunci saran "Sepertinya rutin" yang ditolak (ADR-037 §3.3).
  final Set<String> dismissedSuggestions;

  /// Catatan otomatis 7 hari terakhir yang belum dibatalkan (ADR-037 §3.2).
  final List<AutoRecordEntry> autoRecorded;

  /// Awal bulan berjalan.
  DateTime get monthStart => DateTime(today.year, today.month);

  /// Awal bulan berikutnya.
  DateTime get monthEnd => DateTime(today.year, today.month + 1);

  /// Rutin ber-`id` [id], atau `null`.
  RecurringRule? ruleOf(String id) {
    for (final rule in rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }

  /// Nama dompet [id], atau `null`.
  String? walletName(String? id) {
    for (final wallet in wallets) {
      if (wallet.id == id) return wallet.name;
    }
    return null;
  }

  /// Transaksi yang mencatat rutin [ruleId], terbaru dulu.
  List<Transaction> recordedFor(String ruleId) => [
    for (final t in transactions)
      if (t.recurrence?.ruleId == ruleId) t,
  ]..sort((a, b) => b.recurrence!.occurrenceDate.compareTo(a.recurrence!.occurrenceDate));

  @override
  RecurringState copyWith({
    List<RecurringRule>? rules,
    List<Transaction>? transactions,
    List<Wallet>? wallets,
    DateTime? today,
    bool? isLoading,
    bool? loadFailed,
    RecurringKind? Function()? kindFilter,
    List<BudgetItemOption>? budgetOptions,
    Set<String>? dismissedSuggestions,
    List<AutoRecordEntry>? autoRecorded,
    UiEffect? effect,
  }) {
    return RecurringState(
      rules: rules ?? this.rules,
      transactions: transactions ?? this.transactions,
      wallets: wallets ?? this.wallets,
      today: today ?? this.today,
      isLoading: isLoading ?? this.isLoading,
      loadFailed: loadFailed ?? this.loadFailed,
      kindFilter: kindFilter == null ? this.kindFilter : kindFilter(),
      budgetOptions: budgetOptions ?? this.budgetOptions,
      dismissedSuggestions: dismissedSuggestions ?? this.dismissedSuggestions,
      autoRecorded: autoRecorded ?? this.autoRecorded,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [
    rules,
    transactions,
    wallets,
    today,
    isLoading,
    loadFailed,
    kindFilter,
    budgetOptions,
    dismissedSuggestions,
    autoRecorded,
  ];
}
