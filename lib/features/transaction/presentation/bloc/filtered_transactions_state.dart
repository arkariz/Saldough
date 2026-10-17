import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Keadaan Daftar tersaring satu periode.
final class FilteredTransactionsState extends UiState<FilteredTransactionsState> {
  /// Membuat [FilteredTransactionsState].
  const FilteredTransactionsState({
    required this.wallets,
    required this.groups,
    required this.count,
    required this.total,
    required this.isLoading,
    this.loadFailed = false,
    super.effect,
  });

  /// Keadaan awal, sebelum dimuat.
  const FilteredTransactionsState.initial()
    : wallets = const [],
      groups = const [],
      count = 0,
      total = 0,
      isLoading = true,
      loadFailed = false,
      super();

  /// Seluruh dompet, untuk nama dompet di baris.
  final List<Wallet> wallets;

  /// Transaksi yang lolos, dikelompokkan per hari (terbaru dulu).
  final List<TransactionDateGroup> groups;

  /// Jumlah transaksi yang lolos.
  final int count;

  /// Jumlah nominalnya (sen), dari jenis yang disaring.
  final int total;

  /// Sedang memuat pertama kali.
  final bool isLoading;

  /// Pembacaan pertama gagal.
  final bool loadFailed;

  /// Peta id → dompet untuk baris transaksi.
  Map<String, Wallet> get walletsById => {for (final w in wallets) w.id: w};

  @override
  FilteredTransactionsState copyWith({bool? isLoading, bool? loadFailed, UiEffect? effect}) => FilteredTransactionsState(
    wallets: wallets,
    groups: groups,
    count: count,
    total: total,
    isLoading: isLoading ?? this.isLoading,
    loadFailed: loadFailed ?? this.loadFailed,
    effect: effect,
  );

  @override
  List<Object?> get props => [wallets, groups, count, total, isLoading, loadFailed];
}
