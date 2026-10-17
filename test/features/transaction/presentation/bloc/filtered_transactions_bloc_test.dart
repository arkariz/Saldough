import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/transaction/presentation/bloc/filtered_transactions_bloc.dart';
import 'package:saldough/features/transaction/presentation/bloc/filtered_transactions_state.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Daftar tersaring satu periode (T-19.3): jumlah dan total sama dengan
/// Analisis, segar sekembalinya dari sunting.
void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl transactions;
  late LedgerChanges ledger;
  late FilteredTransactionsBloc bloc;

  final filter = PeriodTransactionFilter(
    from: DateTime(2026, 9),
    until: DateTime(2026, 10),
    type: TransactionTypeFilter.expense,
    uncategorized: true,
  );

  ExpenseTransaction expense(String id, int day, {String? category, int amount = 12000}) => ExpenseTransaction(
    id: id,
    date: DateTime(2026, 9, day, 9),
    amount: amount,
    note: id,
    walletId: 'bca',
    categoryId: category,
  );

  setUp(() async {
    storage = InMemoryKeyValueStorage();
    transactions = TransactionRepositoryImpl(storage: storage);
    ledger = LedgerChanges();
    await WalletRepositoryImpl(storage: storage).saveWallet(
      const Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 0),
    );
    bloc = FilteredTransactionsBloc(
      transactionRepository: transactions,
      walletRepository: WalletRepositoryImpl(storage: storage),
      ledgerChanges: ledger,
      filter: filter,
      isKnownCategory: (id) => id == 'makan',
    );
  });

  tearDown(() => bloc.close());

  Future<FilteredTransactionsState> started() {
    bloc.add(const FilteredTransactionsStarted());
    return bloc.stream.firstWhere((s) => !s.isLoading);
  }

  test('memuat hanya yang lolos: Tanpa kategori di periode itu, dikelompokkan per hari, dengan jumlah dan total', () async {
    for (final t in [
      expense('a', 3),
      expense('b', 3, amount: 5000),
      expense('c', 20),
      expense('makan', 5, category: 'makan'),
      expense('hilang', 6, category: 'tidak-dikenal'),
      expense('oktober', 1).copyWith(date: DateTime(2026, 10, 2)),
    ]) {
      await transactions.saveTransaction(t);
    }
    final state = await started();
    expect(state.count, 4, reason: 'a, b, c, dan id kategori yang tidak dikenal');
    expect(state.total, 12000 + 5000 + 12000 + 12000);
    expect(state.groups.map((g) => g.date), [DateTime(2026, 9, 20), DateTime(2026, 9, 6), DateTime(2026, 9, 3)]);
    expect(state.walletsById['bca']!.name, 'BCA');
  });

  test('sekembalinya dari sunting daftar sudah berkurang (LedgerChanges), tanpa kerangka pemuatan', () async {
    await transactions.saveTransaction(expense('a', 3));
    await transactions.saveTransaction(expense('b', 4));
    final first = await started();
    expect(first.count, 2);

    // Memberi kategori pada satu transaksi di layar lain.
    await transactions.saveTransaction(expense('a', 3, category: 'makan'));
    ledger.notifyChanged(source: Object());
    final refreshed = await bloc.stream.firstWhere((s) => s.count == 1);
    expect(refreshed.isLoading, isFalse);
    expect(refreshed.groups.single.transactions.single.id, 'b');
  });

  test('periode tanpa hasil: kosong, bukan galat', () async {
    final state = await started();
    expect(state.count, 0);
    expect(state.groups, isEmpty);
    expect(state.loadFailed, isFalse);
  });
}
