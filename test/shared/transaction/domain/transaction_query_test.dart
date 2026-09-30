import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Fungsi saring dan kelompok riwayat (ADR-030 §3.6), dengan angka dari
/// kasus uji wajib AGENT_CONTEXT.
void main() {
  final gaji = IncomeTransaction(
    id: 'gaji',
    date: DateTime(2026, 9, 25, 9),
    amount: 261543800,
    note: 'Gaji freelance September',
    walletId: 'bca',
    categoryId: 'salary',
  );
  final belanja = ExpenseTransaction(
    id: 'belanja',
    date: DateTime(2026, 9, 25, 19, 30),
    amount: 306850000,
    note: 'Belanja bulanan',
    walletId: 'bca',
    categoryId: 'groceries',
  );
  final tabungan = TransferTransaction(
    id: 'tabungan',
    date: DateTime(2026, 9, 25, 20),
    amount: 100000000,
    note: '',
    fromWalletId: 'bca',
    toWalletId: 'jago',
  );
  final kopi = ExpenseTransaction(
    id: 'kopi',
    date: DateTime(2026, 9, 27, 8),
    amount: 3500000,
    note: 'Kopi pagi',
    walletId: 'gopay',
    categoryId: 'coffee',
  );
  final all = [gaji, belanja, tabungan, kopi];
  const categories = {'salary': 'Gaji', 'groceries': 'Belanja Dapur', 'coffee': 'Kopi'};
  String? categoryName(String id) => categories[id];
  const walletNames = {'bca': 'BCA', 'jago': 'Bank Jago', 'gopay': 'GoPay'};

  List<String> ids(Iterable<Transaction> transactions) => [for (final t in transactions) t.id];

  group('netSenOf', () {
    test('pemasukan dikurangi pengeluaran; transfer tidak dihitung (aturan 7)', () {
      expect(netSenOf([gaji, belanja, tabungan]), 261543800 - 306850000);
    });

    test('hanya transfer = nol', () {
      expect(netSenOf([tabungan]), 0);
    });
  });

  group('groupTransactionsByDate', () {
    test('tanggal terbaru dulu, jam terbaru dulu, net per tanggal', () {
      final groups = groupTransactionsByDate(all);
      expect([for (final g in groups) g.date], [DateTime(2026, 9, 27), DateTime(2026, 9, 25)]);
      expect(ids(groups[0].transactions), ['kopi']);
      expect(groups[0].netSen, -3500000);
      expect(ids(groups[1].transactions), ['tabungan', 'belanja', 'gaji']);
      expect(groups[1].netSen, -45306200);
    });
  });

  group('filterTransactions', () {
    List<String> filter({
      String? walletId,
      String? categoryId,
      String query = '',
      TransactionTypeFilter type = TransactionTypeFilter.all,
    }) => ids(
      filterTransactions(
        all,
        categoryName: categoryName,
        walletNames: walletNames,
        walletId: walletId,
        categoryId: categoryId,
        query: query,
        type: type,
      ),
    );

    test('dompet cocok sebagai asal maupun tujuan transfer', () {
      expect(filter(walletId: 'jago'), ['tabungan']);
      expect(filter(walletId: 'bca'), ['gaji', 'belanja', 'tabungan']);
    });

    test('kategori dan jenis', () {
      expect(filter(categoryId: 'coffee'), ['kopi']);
      expect(filter(type: TransactionTypeFilter.expense), ['belanja', 'kopi']);
      expect(filter(type: TransactionTypeFilter.transfer), ['tabungan']);
    });

    test('kata kunci: nama kategori, catatan, atau nama dompet, tanpa beda huruf', () {
      expect(filter(query: '  dapur '), ['belanja']);
      expect(filter(query: 'PAGI'), ['kopi']);
      expect(filter(query: 'jago'), ['tabungan']);
      expect(filter(query: 'tidak ada'), isEmpty);
    });
  });

  test('countTransactionsByType menghitung tiap chip, termasuk semua', () {
    expect(countTransactionsByType(all), {
      TransactionTypeFilter.all: 4,
      TransactionTypeFilter.income: 1,
      TransactionTypeFilter.expense: 2,
      TransactionTypeFilter.transfer: 1,
    });
  });

  test('distinctCategoryIds tanpa duplikat, urut nama; id tak dikenal pakai id-nya', () {
    final extra = ExpenseTransaction(
      id: 'x',
      date: DateTime(2026, 9, 28),
      amount: 1000000,
      note: '',
      walletId: 'bca',
      categoryId: 'aaa-unknown',
    );
    expect(distinctCategoryIds([...all, kopi, extra], categoryName: categoryName), [
      'aaa-unknown',
      'groceries',
      'salary',
      'coffee',
    ]);
  });

  test('walletIdsOf: satu dompet, atau asal dan tujuan transfer', () {
    expect(walletIdsOf(gaji), {'bca'});
    expect(walletIdsOf(tabungan), {'bca', 'jago'});
  });
}
