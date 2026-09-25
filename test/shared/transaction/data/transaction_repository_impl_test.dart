import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/transaction/data/transaction_repository_impl.dart';
import 'package:saldough/shared/transaction/domain/transaction.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late TransactionRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = TransactionRepositoryImpl(storage: storage);
  });

  group('TransactionRepositoryImpl', () {
    test('bulan yang belum pernah ditulis mengembalikan daftar kosong', () async {
      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      expect(result.getOrElse((_) => throw StateError('expected Right')), isEmpty);
    });

    test('menyimpan lalu membaca transaksi pada bulan yang sama mengembalikan nilai yang sama', () async {
      final income = IncomeTransaction(
        id: 't1',
        date: DateTime(2026, 9, 15),
        amount: 500000000,
        note: 'gaji bulanan',
        categoryKey: 'gaji',
        walletId: 'w1',
      );

      await repository.saveTransaction(income);
      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));

      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs.single, income);
    });

    test('transaksi bulan berbeda tidak saling bercampur', () async {
      final agustus = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 8, 20),
        amount: 50000,
        note: 'kopi',
        walletId: 'w1',
      );
      final september = ExpenseTransaction(
        id: 't2',
        date: DateTime(2026, 9, 2),
        amount: 75000,
        note: 'makan',
        walletId: 'w1',
      );
      await repository.saveTransaction(agustus);
      await repository.saveTransaction(september);

      final resultAgustus = await repository.listTransactionsInMonth(DateTime(2026, 8));
      final resultSeptember = await repository.listTransactionsInMonth(DateTime(2026, 9));

      expect(resultAgustus.getOrElse((_) => throw StateError('expected Right')), [agustus]);
      expect(resultSeptember.getOrElse((_) => throw StateError('expected Right')), [september]);
    });

    test('listAllTransactions mengembalikan transaksi lintas bulan', () async {
      final agustus = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 8, 20),
        amount: 50000,
        note: 'kopi',
        walletId: 'w1',
      );
      final september = ExpenseTransaction(
        id: 't2',
        date: DateTime(2026, 9, 2),
        amount: 75000,
        note: 'makan',
        walletId: 'w1',
      );
      await repository.saveTransaction(agustus);
      await repository.saveTransaction(september);

      final result = await repository.listAllTransactions();
      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs, containsAll([agustus, september]));
      expect(txs, hasLength(2));
    });

    test('menyimpan ulang transaksi ber-id sama pada bulan sama menimpa, bukan menambah', () async {
      final original = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 9, 2),
        amount: 50000,
        note: 'kopi',
        walletId: 'w1',
      );
      await repository.saveTransaction(original);
      await repository.saveTransaction(original.copyWith(amount: 60000, note: 'kopi + kue'));

      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs, hasLength(1));
      expect((txs.single as ExpenseTransaction).amount, 60000);
      expect((txs.single as ExpenseTransaction).note, 'kopi + kue');
    });

    test('menyunting transaksi yang memindahkan bulan menghapus dari dokumen lama', () async {
      final original = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 8, 30),
        amount: 50000,
        note: 'kopi',
        walletId: 'w1',
      );
      await repository.saveTransaction(original);

      final moved = original.copyWith(date: DateTime(2026, 9));
      await repository.saveTransaction(moved, previousDate: original.date);

      final agustus = await repository.listTransactionsInMonth(DateTime(2026, 8));
      final september = await repository.listTransactionsInMonth(DateTime(2026, 9));
      expect(agustus.getOrElse((_) => throw StateError('expected Right')), isEmpty);
      expect(september.getOrElse((_) => throw StateError('expected Right')), [moved]);
    });

    test('menyunting transaksi yang tetap di bulan sama tidak menggandakannya', () async {
      final original = ExpenseTransaction(
        id: 't1',
        date: DateTime(2026, 9, 2),
        amount: 50000,
        note: 'kopi',
        walletId: 'w1',
      );
      await repository.saveTransaction(original);

      final edited = original.copyWith(date: DateTime(2026, 9, 10), amount: 60000);
      await repository.saveTransaction(edited, previousDate: original.date);

      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs, hasLength(1));
      expect(txs.single, edited);
    });

    test('menghapus transaksi pada bulan yang benar', () async {
      final tx = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 2), amount: 50000, note: 'kopi', walletId: 'w1');
      await repository.saveTransaction(tx);
      await repository.deleteTransaction('t1', DateTime(2026, 9, 2));

      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      expect(result.getOrElse((_) => throw StateError('expected Right')), isEmpty);
    });

    test('menghapus id yang tidak ada tidak berefek', () async {
      final tx = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 2), amount: 50000, note: 'kopi', walletId: 'w1');
      await repository.saveTransaction(tx);
      await repository.deleteTransaction('tidak-ada', DateTime(2026, 9, 2));

      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      expect(result.getOrElse((_) => throw StateError('expected Right')), hasLength(1));
    });

    test(
      'IncomeTransaction, ExpenseTransaction, dan TransferTransaction bulat-pergi (round-trip) dalam satu bulan',
      () async {
        final income = IncomeTransaction(
          id: 't1',
          date: DateTime(2026, 9),
          amount: 500000000,
          note: 'gaji',
          walletId: 'bca',
        );
        final expense = ExpenseTransaction(
          id: 't2',
          date: DateTime(2026, 9, 2),
          amount: 75000,
          note: 'makan siang',
          walletId: 'bca',
          budgetItemId: 'makan',
        );
        final transfer = TransferTransaction(
          id: 't3',
          date: DateTime(2026, 9, 3),
          amount: 1000000,
          note: 'setoran tabungan',
          fromWalletId: 'bca',
          toWalletId: 'tabungan',
          budgetItemId: 'tabungan-item',
        );

        await repository.saveTransaction(income);
        await repository.saveTransaction(expense);
        await repository.saveTransaction(transfer);

        final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
        final txs = result.getOrElse((_) => throw StateError('expected Right'));
        expect(txs, containsAll([income, expense, transfer]));
      },
    );
  });
}
