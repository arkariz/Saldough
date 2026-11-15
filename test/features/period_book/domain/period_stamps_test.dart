import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_content.dart';
import 'package:saldough/features/period_book/domain/services/period_stamps.dart';

PeriodBookContent content({int count = 12, int untagged = 0, BookPlan? plan}) => PeriodBookContent(
  period: ClosedPeriod(period: financialPeriodOf(DateTime(2026, 10), FinancialMonthSchedule.initial), transactionCount: count),
  flow: const BookFlow(income: 1, expense: 1),
  uncategorizedCount: untagged,
  plan: plan,
);

void main() {
  test('Periode rapi: >=3 transaksi dan tidak ada yang tanpa kategori', () {
    expect(periodStampsOf(content()), [periodStampTidy]);
    expect(periodStampsOf(content(untagged: 1)), isEmpty);
    expect(periodStampsOf(content(count: 2)), isEmpty, reason: 'pencegah kebetulan (G-2)');
  });

  test('Rutin tak terlewat: ada rutin dan semuanya beres', () {
    expect(periodStampsOf(content(plan: const BookPlan(recorded: 2, skipped: 1))), [periodStampTidy, periodStampRecurringClear]);
    expect(periodStampsOf(content(plan: const BookPlan(recorded: 2, open: 1))), [periodStampTidy]);
    expect(periodStampsOf(content(plan: const BookPlan(planned: 1, spent: 1))), [periodStampTidy], reason: 'anggaran saja bukan rutin');
  });
}
