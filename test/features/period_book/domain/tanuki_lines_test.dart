import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/services/tanuki_lines.dart';

PeriodBookContent content({
  int count = 12,
  int income = 850000000,
  int expense = 470500000,
  int uncategorized = 0,
  bool topCategory = true,
  BookPlan? plan,
  bool spending = true,
}) => PeriodBookContent(
  period: ClosedPeriod(period: financialPeriodOf(DateTime(2026, 10), FinancialMonthSchedule.initial), transactionCount: count),
  flow: BookFlow(income: income, expense: expense),
  uncategorizedCount: uncategorized,
  spending: spending
      ? BookSpending(
          total: expense,
          count: count,
          rows: [
            if (topCategory)
              const BookSpendRow(kind: BookRowKind.category, amount: 164000000, count: 5, percent: 35, categoryId: 'makan', categoryName: 'Makan')
            else
              const BookSpendRow(kind: BookRowKind.uncategorized, amount: 100, count: 1, percent: 100),
          ],
        )
      : null,
  plan: plan,
);

const clearPlan = BookPlan(recorded: 2, skipped: 1);

void main() {
  test('Rani: catatan, arus, kategori terbesar, rutin beres, tertib = lima berlaku, catatan dibuang, empat tersisa', () {
    final lines = tanukiLinesOf(content(plan: clearPlan));
    expect(lines.length, tanukiMaxLines);
    expect(lines, [
      const TanukiFlow(income: 850000000, expense: 470500000),
      const TanukiTopCategory(name: 'Makan', percent: 35),
      const TanukiRecurringClear(recorded: 2, skipped: 1),
      const TanukiTidy(),
    ]);
  });

  test('tanpa rutin: catatan, arus, kategori, tertib (urut tampil)', () {
    expect(tanukiLinesOf(content()), [
      const TanukiRecords(12),
      const TanukiFlow(income: 850000000, expense: 470500000),
      const TanukiTopCategory(name: 'Makan', percent: 35),
      const TanukiTidy(),
    ]);
  });

  test('rutin yang masih menunggu atau terlewat tidak dibilang beres', () {
    final lines = tanukiLinesOf(content(plan: const BookPlan(recorded: 1, skipped: 1, open: 1)));
    expect(lines.whereType<TanukiRecurringClear>(), isEmpty);
  });

  test('ada transaksi tanpa kategori: tanpa kalimat tertib; tanpa pengeluaran berkategori: tanpa kategori terbesar', () {
    final lines = tanukiLinesOf(content(uncategorized: 2, topCategory: false));
    expect(lines, [const TanukiRecords(12), const TanukiFlow(income: 850000000, expense: 470500000)]);
  });

  test('selalu dua sampai empat kalimat, termasuk periode tanpa pengeluaran', () {
    for (final c in [
      content(spending: false, uncategorized: 1),
      content(plan: clearPlan),
      content(count: 3, income: 0, expense: 0, spending: false),
    ]) {
      expect(tanukiLinesOf(c).length, inInclusiveRange(2, tanukiMaxLines));
    }
  });

  test('selisih: sisanya bila ≥ 0, negatif tetap fakta yang sama (selisih dihitung)', () {
    expect(const TanukiFlow(income: 100, expense: 40).net, 60);
    expect(const TanukiFlow(income: 40, expense: 100).net, -60);
  });

  test('deterministik: input sama, kalimat sama', () {
    expect(tanukiLinesOf(content(plan: clearPlan)), tanukiLinesOf(content(plan: clearPlan)));
  });
}
