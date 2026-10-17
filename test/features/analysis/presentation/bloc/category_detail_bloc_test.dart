import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/analysis/presentation/bloc/category_detail_bloc.dart';
import 'package:saldough/features/analysis/presentation/bloc/category_detail_state.dart';
import 'package:saldough/features/analysis/presentation/navigation/analysis_route_keys.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

import '../../analysis_fixtures.dart';

/// Bloc Rincian kategori (T-19.5): batas 20 transaksi, kecocokan dengan Daftar
/// tersaring, pilihan kolom tren, dan segar lewat LedgerChanges.
void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl repository;
  late LedgerChanges ledger;
  late List<CategoryDetailBloc> blocs;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = TransactionRepositoryImpl(storage: storage);
    ledger = LedgerChanges();
    blocs = [];
  });

  tearDown(() async {
    ActiveFinancialMonth.notifier.value = FinancialMonthSchedule.initial;
    for (final bloc in blocs) {
      await bloc.close();
    }
  });

  CategoryDetailBloc create({String? category = 'makan', String? walletId}) {
    final bloc = CategoryDetailBloc(
      transactionRepository: repository,
      walletRepository: WalletRepositoryImpl(storage: storage),
      ledgerChanges: ledger,
      input: CategoryDetailInput(
        categoryId: category,
        kind: category == null ? CategoryKind.income : CategoryKind.expense,
        periodStart: DateTime(2026, 9, 15),
        walletId: walletId,
      ),
      categoryOf: analysisCategoryOf,
      now: () => DateTime(2026, 10, 10, 9),
    );
    blocs.add(bloc);
    return bloc;
  }

  Future<CategoryDetailState> loaded(CategoryDetailBloc bloc) {
    bloc.add(const CategoryDetailStarted());
    return bloc.stream.firstWhere((s) => !s.isLoading);
  }

  test('paling banyak 20 transaksi terbaru, jumlah dan total tetap seluruhnya (sama dengan Daftar tersaring)', () async {
    for (var i = 0; i < 25; i++) {
      await repository.saveTransaction(expenseOn(DateTime(2026, 9, 1 + i, 9), 1000, category: 'makan'));
    }
    await repository.saveTransaction(expenseOn(DateTime(2026, 9, 3), 5, category: 'belanja'));
    final state = await loaded(create());
    final shown = state.groups.fold(0, (n, g) => n + g.transactions.length);
    expect(shown, categoryDetailTransactionLimit);
    expect(state.hasMore, isTrue);
    expect(state.groups.first.date, DateTime(2026, 9, 25), reason: 'terbaru dulu');
    expect(state.detail!.amount, rp(25000));
    expect(state.detail!.frequency.count, 25);
  });

  test('memilih kolom tren tidak berpindah periode; indeks bawaan kolom terakhir', () async {
    await repository.saveTransaction(expenseOn(DateTime(2026, 7, 5), 100000, category: 'makan'));
    await repository.saveTransaction(expenseOn(DateTime(2026, 9, 5), 300000, category: 'makan'));
    final bloc = create();
    final state = await loaded(bloc);
    expect(state.detail!.trend.length, 3);
    expect(state.trendIndex, 2);
    bloc.add(const CategoryDetailTrendSelected(0));
    final picked = await bloc.stream.firstWhere((s) => s.trendSelected == 0);
    expect(picked.period.label, 'September 2026');
    expect(picked.trendIndex, 0);
  });

  test('segar lewat LedgerChanges: transaksi disunting ke kategori lain, angka dan daftar berkurang', () async {
    final tx = expenseOn(DateTime(2026, 9, 5), 300000, category: 'makan');
    await repository.saveTransaction(tx);
    final bloc = create();
    final first = await loaded(bloc);
    expect(first.detail!.amount, rp(300000));

    await repository.saveTransaction(
      ExpenseTransaction(
        id: tx.id,
        date: tx.date,
        amount: tx.amount,
        note: '',
        walletId: 'bca',
        categoryId: 'belanja',
      ),
    );
    ledger.notifyChanged();
    final next = await bloc.stream.firstWhere((s) => s.detail!.amount == 0);
    expect(next.groups, isEmpty);
  });

  test('Freelance: hanya pembayaran freelance tanpa kategori', () async {
    await repository.saveTransaction(
      IncomeTransaction(
        id: 'f',
        date: DateTime(2026, 9, 26),
        amount: rp(2000000),
        note: '',
        walletId: 'bca',
        freelancePaymentId: 'p1',
      ),
    );
    await repository.saveTransaction(
      IncomeTransaction(
        id: 'g',
        date: DateTime(2026, 9, 25),
        amount: rp(12000000),
        note: '',
        walletId: 'bca',
        categoryId: 'gaji',
      ),
    );
    final state = await loaded(create(category: null));
    expect(state.detail!.amount, rp(2000000));
    expect(state.groups.single.transactions.single.id, 'f');
    expect(state.name, 'Freelance');
  });

  test('satu dompet: hanya transaksi dompet itu', () async {
    await repository.saveTransaction(expenseOn(DateTime(2026, 9, 5), 100000, category: 'makan'));
    await repository.saveTransaction(expenseOn(DateTime(2026, 9, 6), 40000, category: 'makan', wallet: 'tabungan'));
    final state = await loaded(create(walletId: 'tabungan'));
    expect(state.detail!.amount, rp(40000));
  });
}
