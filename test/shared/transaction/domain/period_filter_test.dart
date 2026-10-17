import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Saringan satu periode untuk Daftar tersaring dari Analisis (T-19.3).
void main() {
  final from = DateTime(2026, 9);
  final until = DateTime(2026, 10);
  bool known(String id) => id == 'makan' || id == 'gaji';

  var next = 0;
  ExpenseTransaction expense({String? category, DateTime? date, String wallet = 'bca', RecurrenceLink? recurrence}) =>
      ExpenseTransaction(
        id: 'e${next++}',
        date: date ?? DateTime(2026, 9, 12, 9),
        amount: 1000,
        note: '',
        walletId: wallet,
        categoryId: category,
        recurrence: recurrence,
      );
  IncomeTransaction income({String? category, String? freelance, DateTime? date}) => IncomeTransaction(
    id: 'i${next++}',
    date: date ?? DateTime(2026, 9, 25, 9),
    amount: 1000,
    note: '',
    walletId: 'bca',
    categoryId: category,
    freelancePaymentId: freelance,
  );
  PeriodTransactionFilter filter({
    TransactionTypeFilter type = TransactionTypeFilter.expense,
    bool uncategorized = false,
    String? categoryId,
    String? walletId,
  }) => PeriodTransactionFilter(
    from: from,
    until: until,
    type: type,
    uncategorized: uncategorized,
    categoryId: categoryId,
    walletId: walletId,
  );

  group('isUncategorizedTransaction (B-9)', () {
    test('pengeluaran tanpa kategori atau dengan id tak dikenal; transfer tidak pernah', () {
      expect(isUncategorizedTransaction(expense(), isKnownCategory: known), isTrue);
      expect(isUncategorizedTransaction(expense(category: 'hilang'), isKnownCategory: known), isTrue);
      expect(isUncategorizedTransaction(expense(category: 'makan'), isKnownCategory: known), isFalse);
      final transfer = TransferTransaction(
        id: 't',
        date: from,
        amount: 1,
        note: '',
        fromWalletId: 'a',
        toWalletId: 'b',
      );
      expect(isUncategorizedTransaction(transfer, isKnownCategory: known), isFalse);
    });

    test('pembayaran freelance tanpa kategori adalah Freelance, bukan Tanpa kategori', () {
      expect(isUncategorizedTransaction(income(freelance: 'p1'), isKnownCategory: known), isFalse);
      expect(isUncategorizedTransaction(income(), isKnownCategory: known), isTrue);
      expect(isUncategorizedTransaction(income(category: 'gaji', freelance: 'p1'), isKnownCategory: known), isFalse);
      expect(isUncategorizedTransaction(income(category: 'hilang', freelance: 'p1'), isKnownCategory: known), isTrue);
    });
  });

  group('PeriodTransactionFilter.matches', () {
    bool matches(PeriodTransactionFilter f, Transaction t) => f.matches(t, isKnownCategory: known);

    test('periode: awal masuk, awal periode berikutnya tidak; tertaut rutin ikut tanggal kemunculan', () {
      final f = filter();
      expect(matches(f, expense(date: DateTime(2026, 9))), isTrue);
      expect(matches(f, expense(date: DateTime(2026, 9, 30, 23, 59))), isTrue);
      expect(matches(f, expense(date: DateTime(2026, 10))), isFalse);
      expect(matches(f, expense(date: DateTime(2026, 8, 31))), isFalse);
      // 2 Okt tertaut kemunculan 30 Sep: milik September.
      final linked = expense(
        date: DateTime(2026, 10, 2),
        recurrence: RecurrenceLink(ruleId: 'r', occurrenceDate: DateTime(2026, 9, 30)),
      );
      expect(matches(f, linked), isTrue);
    });

    test('jenis, dompet, kategori, dan Tanpa kategori digabung dengan DAN', () {
      expect(matches(filter(), income(category: 'gaji')), isFalse, reason: 'jenis pengeluaran');
      expect(matches(filter(type: TransactionTypeFilter.income), income(category: 'gaji')), isTrue);
      expect(matches(filter(walletId: 'gopay'), expense()), isFalse);
      expect(matches(filter(walletId: 'bca'), expense()), isTrue);
      expect(matches(filter(categoryId: 'makan'), expense(category: 'makan')), isTrue);
      expect(matches(filter(categoryId: 'makan'), expense()), isFalse);
      expect(matches(filter(uncategorized: true), expense()), isTrue);
      expect(matches(filter(uncategorized: true), expense(category: 'makan')), isFalse);
    });

    test('freelance: hanya pembayaran freelance tanpa kategori (kelompok Freelance di Analisis)', () {
      final freelance = PeriodTransactionFilter(
        from: from,
        until: until,
        type: TransactionTypeFilter.income,
        freelance: true,
      );
      bool freelanceMatches(Transaction t) => freelance.matches(t, isKnownCategory: known);
      expect(freelanceMatches(income(freelance: 'p1')), isTrue);
      expect(freelanceMatches(income(freelance: 'p1', category: 'gaji')), isFalse, reason: 'berkategori = kategorinya');
      expect(freelanceMatches(income(category: 'gaji')), isFalse);
      expect(freelanceMatches(income()), isFalse, reason: 'bukan pembayaran freelance');
    });
  });
}
