import 'dart:async';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/transaction/presentation/bloc/filtered_transactions_state.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

/// Peristiwa [FilteredTransactionsBloc].
sealed class FilteredTransactionsEvent {
  /// Membuat [FilteredTransactionsEvent].
  const FilteredTransactionsEvent();
}

/// Layar dibuka.
final class FilteredTransactionsStarted extends FilteredTransactionsEvent {
  /// Membuat [FilteredTransactionsStarted].
  const FilteredTransactionsStarted();
}

/// Muat ulang tanpa kerangka (transaksi disunting atau dihapus di layar lain).
final class FilteredTransactionsRefreshed extends FilteredTransactionsEvent {
  /// Membuat [FilteredTransactionsRefreshed].
  const FilteredTransactionsRefreshed();
}

/// Bloc Daftar tersaring satu periode (T-19.3, F4/F5): semua transaksi yang
/// lolos [PeriodTransactionFilter], dibaca dari dokumen bulan yang disentuh
/// periode ± 7 hari ([ListPeriodTransactions]). Segar lewat `LedgerChanges`,
/// jadi sekembalinya dari sunting daftar sudah berkurang.
final class FilteredTransactionsBloc extends Bloc<FilteredTransactionsEvent, FilteredTransactionsState> {
  /// Membuat [FilteredTransactionsBloc].
  FilteredTransactionsBloc({
    required TransactionRepository transactionRepository,
    required WalletRepository walletRepository,
    required LedgerChanges ledgerChanges,
    required this._filter,
    bool Function(String id)? isKnownCategory,
  }) : _transactions = transactionRepository,
       _wallets = walletRepository,
       _isKnownCategory = isKnownCategory ?? ((id) => ActiveCategories.byId(id) != null),
       super(const FilteredTransactionsState.initial()) {
    on<FilteredTransactionsStarted>((event, emit) => _load(emit, firstLoad: true));
    on<FilteredTransactionsRefreshed>((event, emit) => _load(emit, firstLoad: false));
    _ledgerSubscription = ledgerChanges.from(this).listen((_) => add(const FilteredTransactionsRefreshed()));
  }

  late final StreamSubscription<void> _ledgerSubscription;
  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final PeriodTransactionFilter _filter;
  final bool Function(String id) _isKnownCategory;

  Future<void> _load(Emitter<FilteredTransactionsState> emit, {required bool firstLoad}) async {
    final (wallets, all) = await (
      _wallets.listWallets(),
      ListPeriodTransactions(_transactions)(from: _filter.from, until: _filter.until),
    ).wait;
    switch ((wallets, all)) {
      case (Right(value: final wallets), Right(value: final all)):
        final matched = [
          for (final transaction in all)
            if (_filter.matches(transaction, isKnownCategory: _isKnownCategory)) transaction,
        ];
        emit(
          FilteredTransactionsState(
            wallets: wallets,
            groups: groupTransactionsByDate(matched),
            count: matched.length,
            total: matched.fold(0, (sum, t) => sum + t.amount),
            isLoading: false,
          ),
        );
      default:
        final failure = <Either<Failure, Object?>>[
          wallets,
          all,
        ].map((result) => result.fold((failure) => failure, (_) => null)).nonNulls.first;
        final effect = ShowSnackBarEffect(
          message: failure.userMessage ?? t.common.genericErrorMessage,
          severity: .error,
        );
        emit(
          firstLoad
              ? state.copyWith(isLoading: false, loadFailed: true, effect: effect)
              : state.copyWith(effect: effect),
        );
    }
  }

  @override
  Future<void> close() async {
    await _ledgerSubscription.cancel();
    return super.close();
  }
}
