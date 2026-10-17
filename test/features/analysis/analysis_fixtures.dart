import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Data uji Analisis: September 2026 persis contoh FINANCIAL_ANALYSIS §10.
int rp(int rupiah) => rupiah * 100;

final Map<String, Category> analysisCategories = {
  for (final c in [
    const Category(id: 'belanja', kind: CategoryKind.expense, name: 'Belanja'),
    const Category(id: 'cicilan', kind: CategoryKind.expense, name: 'Cicilan'),
    const Category(
      id: 'tempat',
      kind: CategoryKind.expense,
      name: 'Tempat tinggal',
    ),
    const Category(id: 'makan', kind: CategoryKind.expense, name: 'Makan'),
    const Category(id: 'sedekah', kind: CategoryKind.expense, name: 'Sedekah'),
    const Category(id: 'tagihan', kind: CategoryKind.expense, name: 'Tagihan'),
    const Category(
      id: 'langganan',
      kind: CategoryKind.expense,
      name: 'Langganan',
    ),
    const Category(
      id: 'transportasi',
      kind: CategoryKind.expense,
      name: 'Transportasi',
    ),
    const Category(id: 'gaji', kind: CategoryKind.income, name: 'Gaji'),
  ])
    c.id: c,
};

Category? analysisCategoryOf(String id) => analysisCategories[id];

var _next = 0;

ExpenseTransaction expenseOn(
  DateTime date,
  int rupiah, {
  String? category,
  String wallet = 'bca',
}) => ExpenseTransaction(
  id: 'e${_next++}',
  date: date,
  amount: rp(rupiah),
  note: '',
  walletId: wallet,
  categoryId: category,
);

/// September 2026: pengeluaran Rp11.420.700, pemasukan, dan transfer Rp1.000.000.
List<Transaction> september2026() {
  DateTime d(int day) => DateTime(2026, 9, day, 9);
  return [
    expenseOn(d(3), 3068500, category: 'belanja'),
    expenseOn(d(10), 2914000, category: 'cicilan'),
    expenseOn(d(1), 1900000, category: 'tempat'),
    expenseOn(d(20), 1245000, category: 'makan'),
    expenseOn(d(28), 800000, category: 'sedekah'),
    expenseOn(d(5), 550000, category: 'tagihan'),
    expenseOn(d(3), 413200, category: 'langganan'),
    expenseOn(d(12), 410000, category: 'transportasi'),
    expenseOn(d(15), 120000),
    IncomeTransaction(
      id: 'i${_next++}',
      date: d(25),
      amount: rp(12000000),
      note: '',
      walletId: 'bca',
      categoryId: 'gaji',
    ),
    IncomeTransaction(
      id: 'i${_next++}',
      date: d(26),
      amount: 261543750,
      note: '',
      walletId: 'bca',
      freelancePaymentId: 'pay1',
    ),
    TransferTransaction(
      id: 't${_next++}',
      date: d(28),
      amount: rp(1000000),
      note: '',
      fromWalletId: 'bca',
      toWalletId: 'tabungan',
    ),
  ];
}
