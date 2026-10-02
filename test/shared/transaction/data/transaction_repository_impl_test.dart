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
        categoryId: 'builtin.salary',
        walletId: 'w1',
      );

      await repository.saveTransaction(income);
      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));

      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs.single, income);
    });

    test('tautan rutin (recurrence) tersimpan di ketiga jenis; dokumen lama tanpa kunci tetap terbaca', () async {
      final link = RecurrenceLink(ruleId: 'netflix', occurrenceDate: DateTime(2026, 10, 1, 8));
      final auto = RecurrenceLink(
        ruleId: 'gaji',
        occurrenceDate: DateTime(2026, 10, 25),
        linkedBy: RecurrenceLinkedBy.auto,
      );
      final txs = <Transaction>[
        IncomeTransaction(id: 'i', date: DateTime(2026, 10, 25), amount: 1, note: '', walletId: 'w1', recurrence: auto),
        ExpenseTransaction(id: 'e', date: DateTime(2026, 10, 3), amount: 1, note: '', walletId: 'w1', recurrence: link),
        TransferTransaction(
          id: 't',
          date: DateTime(2026, 10, 5),
          amount: 1,
          note: '',
          fromWalletId: 'w1',
          toWalletId: 'w2',
          recurrence: RecurrenceLink(ruleId: 'tabungan', occurrenceDate: DateTime(2026, 10, 5)),
        ),
        ExpenseTransaction(id: 'lama', date: DateTime(2026, 10, 6), amount: 1, note: '', walletId: 'w1'),
      ];
      for (final t in txs) {
        await repository.saveTransaction(t);
      }

      final read = (await repository.listTransactionsInMonth(DateTime(2026, 10))).getOrElse((_) => throw StateError('expected Right'));
      expect(read, containsAll(txs));
      expect(read.firstWhere((t) => t.id == 'e').recurrence?.occurrenceDate, DateTime(2026, 10));
      expect(read.firstWhere((t) => t.id == 'lama').recurrence, isNull);
    });

    test('ikon notifikasi asal (sourceIconId) tersimpan dan terbaca kembali', () async {
      final expense = ExpenseTransaction(
        id: 'n1',
        date: DateTime(2026, 9, 3),
        amount: 2500000,
        note: 'KOPI',
        walletId: 'bri',
        sourceIconId: 'ikon1',
      );
      await repository.saveTransaction(expense);
      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      expect(result.getOrElse((_) => const []).single.sourceIconId, 'ikon1');
    });

    test('transaksi bulan berbeda tidak saling bercampur', () async {
      final agustus = ExpenseTransaction(id: 't1', date: DateTime(2026, 8, 20), amount: 50000, note: 'kopi', walletId: 'w1');
      final september = ExpenseTransaction(id: 't2', date: DateTime(2026, 9, 2), amount: 75000, note: 'makan', walletId: 'w1');
      await repository.saveTransaction(agustus);
      await repository.saveTransaction(september);

      final resultAgustus = await repository.listTransactionsInMonth(DateTime(2026, 8));
      final resultSeptember = await repository.listTransactionsInMonth(DateTime(2026, 9));

      expect(resultAgustus.getOrElse((_) => throw StateError('expected Right')), [agustus]);
      expect(resultSeptember.getOrElse((_) => throw StateError('expected Right')), [september]);
    });

    test('listAllTransactions mengembalikan transaksi lintas bulan', () async {
      final agustus = ExpenseTransaction(id: 't1', date: DateTime(2026, 8, 20), amount: 50000, note: 'kopi', walletId: 'w1');
      final september = ExpenseTransaction(id: 't2', date: DateTime(2026, 9, 2), amount: 75000, note: 'makan', walletId: 'w1');
      await repository.saveTransaction(agustus);
      await repository.saveTransaction(september);

      final result = await repository.listAllTransactions();
      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs, containsAll([agustus, september]));
      expect(txs, hasLength(2));
    });

    test('listRecentTransactions: terbaru di atas lintas bulan, tanpa membuka bulan yang tidak perlu', () async {
      final lama = ExpenseTransaction(id: 'lama', date: DateTime(2020, 1, 5), amount: 1, note: 'lama', walletId: 'w1');
      final agustus = ExpenseTransaction(id: 'agu', date: DateTime(2026, 8, 30), amount: 1, note: 'agu', walletId: 'w1');
      final sep1 = ExpenseTransaction(id: 'sep1', date: DateTime(2026, 9, 2), amount: 1, note: 'a', walletId: 'w1');
      final sep9 = ExpenseTransaction(id: 'sep9', date: DateTime(2026, 9, 9), amount: 1, note: 'b', walletId: 'w1');
      for (final t in [lama, agustus, sep9, sep1]) {
        await repository.saveTransaction(t);
      }
      // Dokumen bulan lama dirusak: kalau sampai dibaca, hasilnya Left.
      await storage.write('transaction_2020-01', '{rusak');

      final result = await repository.listRecentTransactions(3);
      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs.map((t) => t.id), ['sep9', 'sep1', 'agu']);
    });

    test('listRecentTransactions dengan riwayat lebih pendek dari limit mengembalikan semuanya', () async {
      final a = ExpenseTransaction(id: 'a', date: DateTime(2026, 8, 30), amount: 1, note: 'a', walletId: 'w1');
      await repository.saveTransaction(a);
      final result = await repository.listRecentTransactions(5);
      expect(result.getOrElse((_) => throw StateError('expected Right')), [a]);
    });

    test('menyimpan ulang transaksi ber-id sama pada bulan sama menimpa, bukan menambah', () async {
      final original = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 2), amount: 50000, note: 'kopi', walletId: 'w1');
      await repository.saveTransaction(original);
      await repository.saveTransaction(original.copyWith(amount: 60000, note: 'kopi + kue'));

      final result = await repository.listTransactionsInMonth(DateTime(2026, 9));
      final txs = result.getOrElse((_) => throw StateError('expected Right'));
      expect(txs, hasLength(1));
      expect((txs.single as ExpenseTransaction).amount, 60000);
      expect((txs.single as ExpenseTransaction).note, 'kopi + kue');
    });

    test('menyunting transaksi yang memindahkan bulan menghapus dari dokumen lama', () async {
      final original = ExpenseTransaction(id: 't1', date: DateTime(2026, 8, 30), amount: 50000, note: 'kopi', walletId: 'w1');
      await repository.saveTransaction(original);

      final moved = original.copyWith(date: DateTime(2026, 9));
      await repository.saveTransaction(moved, previousDate: original.date);

      final agustus = await repository.listTransactionsInMonth(DateTime(2026, 8));
      final september = await repository.listTransactionsInMonth(DateTime(2026, 9));
      expect(agustus.getOrElse((_) => throw StateError('expected Right')), isEmpty);
      expect(september.getOrElse((_) => throw StateError('expected Right')), [moved]);
    });

    test('menyunting transaksi yang tetap di bulan sama tidak menggandakannya', () async {
      final original = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 2), amount: 50000, note: 'kopi', walletId: 'w1');
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

    test('listAvailableMonths mengembalikan bulan yang pernah ditulis, terurut naik', () async {
      final september = ExpenseTransaction(id: 't1', date: DateTime(2026, 9, 2), amount: 1, note: 'a', walletId: 'w1');
      final januari = ExpenseTransaction(id: 't2', date: DateTime(2026, 1, 5), amount: 1, note: 'b', walletId: 'w1');
      final agustus = ExpenseTransaction(id: 't3', date: DateTime(2026, 8, 20), amount: 1, note: 'c', walletId: 'w1');
      await repository.saveTransaction(september);
      await repository.saveTransaction(januari);
      await repository.saveTransaction(agustus);

      final result = await repository.listAvailableMonths();
      final months = result.getOrElse((_) => throw StateError('expected Right'));
      expect(months, [DateTime(2026), DateTime(2026, 8), DateTime(2026, 9)]);
    });

    test('listAvailableMonths kosong kalau belum pernah ada transaksi', () async {
      final result = await repository.listAvailableMonths();
      expect(result.getOrElse((_) => throw StateError('expected Right')), isEmpty);
    });

    test('IncomeTransaction, ExpenseTransaction, dan TransferTransaction bulat-pergi (round-trip) dalam satu bulan', () async {
      final income = IncomeTransaction(id: 't1', date: DateTime(2026, 9), amount: 500000000, note: 'gaji', walletId: 'bca');
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
    });
  });
}
