import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/budget_catalog/budget_catalog.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Tautan rutin ke pos anggaran rutin (ADR-036 §3.4, E9; T-16.5).
void main() {
  RecurringRule kos({String wallet = 'bca', String? key, int amount = 190000000, String note = 'Kos'}) => RecurringRule(
    id: 'kos',
    kind: RecurringKind.expense,
    amount: amount,
    walletId: wallet,
    note: note,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9)),
    budgetItemKey: key,
  );

  BudgetItemOption option(
    String itemId,
    DateTime start, {
    String? key = 'k-kos',
    String name = 'Kos',
    int planned = 200000000,
  }) => BudgetItemOption(
    budgetId: 'b-$itemId',
    budgetName: 'Bulanan',
    itemId: itemId,
    itemName: name,
    walletId: 'bca',
    startDate: start,
    endDate: DateTime(start.year, start.month + 1, start.day),
    templateItemId: key,
    plannedAmount: planned,
  );

  final options = [option('kos-okt', DateTime(2026, 10)), option('kos-nov', DateTime(2026, 11))];

  test('kemunculan tertaut masuk pos periode yang mencakup tanggalnya', () {
    final rule = kos(key: 'k-kos');
    expect(budgetItemForOccurrence(rule, DateTime(2026, 10, 1), options), 'kos-okt');
    expect(budgetItemForOccurrence(rule, DateTime(2026, 11, 1), options), 'kos-nov');
    expect(budgetItemForOccurrence(rule, DateTime(2026, 12, 1), options), isNull);
    expect(budgetItemForOccurrence(kos(), DateTime(2026, 10, 1), options), isNull);
    final transaction = transactionForOccurrence(
      rule,
      DateTime(2026, 10),
      id: 't',
      now: DateTime(2026, 10, 1, 8),
      budgetItemId: budgetItemForOccurrence(rule, DateTime(2026, 10), options),
    );
    expect((transaction as ExpenseTransaction).budgetItemId, 'kos-okt');
  });

  test('dompet beda dan pos tanpa kunci tidak ditawarkan; satu entri per kunci', () {
    expect(linkableBudgetItems(kos(wallet: 'jago'), options), isEmpty);
    expect(linkableBudgetItems(kos(), [...options, option('lain', DateTime(2026, 10), key: null)]).length, 1);
    final list = linkableBudgetItems(kos(), options);
    expect(list.single.itemId, 'kos-nov');
  });

  test('saran E9: nama sama dulu, lalu nominal sama; dua kandidat tidak disarankan', () {
    expect(suggestBudgetLink(kos(note: ' kos '), options)?.templateItemId, 'k-kos');
    expect(suggestBudgetLink(kos(note: 'Sewa', amount: 200000000), options)?.templateItemId, 'k-kos');
    expect(suggestBudgetLink(kos(note: 'Sewa'), options), isNull);
    expect(suggestBudgetLink(kos(key: 'k-kos'), options), isNull);
    final twins = [...options, option('kos2', DateTime(2026, 10), key: 'k-kos2')];
    expect(suggestBudgetLink(kos(), twins), isNull);
  });
}
