import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  RecurringRule netflix({Set<DateTime> skipped = const {}, bool paused = false}) => RecurringRule(
    id: 'netflix',
    kind: RecurringKind.expense,
    amount: 6500000,
    walletId: 'bca',
    note: 'Netflix',
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 7)),
    skippedDates: skipped,
    isPaused: paused,
  );

  ExpenseTransaction recorded(String ruleId, DateTime occurrence) => ExpenseTransaction(
    id: '$ruleId-$occurrence',
    date: occurrence.add(const Duration(days: 2)),
    amount: 6500000,
    note: 'Netflix',
    walletId: 'bca',
    recurrence: RecurrenceLink(ruleId: ruleId, occurrenceDate: occurrence),
  );

  Map<DateTime, OccurrenceStatus> statuses(RecurringRule rule, List<Transaction> transactions) => {
    for (final o in occurrenceStatusesOf(
      rule,
      from: DateTime(2026, 7),
      until: DateTime(2026, 12),
      today: DateTime(2026, 10, 2, 21),
      transactions: transactions,
    ))
      o.date: o.status,
  };

  test('tercatat, dilewati, terlewat, menunggu (terbaru yang sudah tiba), dan akan datang', () {
    final result = statuses(netflix(skipped: {DateTime(2026, 8)}), [
      recorded('netflix', DateTime(2026, 7)),
      recorded('lain', DateTime(2026, 9)),
    ]);
    expect(result, {
      DateTime(2026, 7): OccurrenceStatus.recorded,
      DateTime(2026, 8): OccurrenceStatus.skipped,
      DateTime(2026, 9): OccurrenceStatus.missed,
      DateTime(2026, 10): OccurrenceStatus.pending,
      DateTime(2026, 11): OccurrenceStatus.upcoming,
    });
  });

  test('menghapus transaksinya mengembalikan kemunculan ke menunggu', () {
    final october = DateTime(2026, 10);
    expect(statuses(netflix(), [recorded('netflix', october)])[october], OccurrenceStatus.recorded);
    expect(statuses(netflix(), const [])[october], OccurrenceStatus.pending);
  });

  test('kemunculan terbaru tercatat: yang lebih lama tetap terlewat, tidak ada yang menunggu', () {
    final result = statuses(netflix(), [recorded('netflix', DateTime(2026, 10))]);
    expect(result.values.where((s) => s == OccurrenceStatus.pending), isEmpty);
    expect(result[DateTime(2026, 9)], OccurrenceStatus.missed);
  });

  test('rutin dijeda tidak memunculkan menunggu maupun terlewat', () {
    final result = statuses(netflix(paused: true), const []);
    expect(result[DateTime(2026, 10)], OccurrenceStatus.paused);
    expect(result[DateTime(2026, 9)], OccurrenceStatus.paused);
    expect(result[DateTime(2026, 11)], OccurrenceStatus.upcoming);
  });

  test('transaksi tercatat ikut di kemunculannya', () {
    final tx = recorded('netflix', DateTime(2026, 7));
    final first = occurrenceStatusesOf(
      netflix(),
      from: DateTime(2026, 7),
      until: DateTime(2026, 8),
      today: DateTime(2026, 10, 2),
      transactions: [tx],
    ).single;
    expect(first.transaction, tx);
  });

  group('belum terlihat H+2 (E3, T-17.1)', () {
    final debit = netflix().copyWith(paymentMode: RecurringPaymentMode.autoDebit);
    Occurrence october(RecurringRule rule, DateTime today) => occurrenceStatusesOf(
      rule,
      from: DateTime(2026, 10),
      until: DateTime(2026, 10, 2),
      today: today,
      transactions: const [],
    ).single;

    test('autodebet: H+1 masih menunggu biasa, H+2 belum terlihat', () {
      expect(isUnseen(october(debit, DateTime(2026, 10, 2, 23)), today: DateTime(2026, 10, 2, 23)), isFalse);
      expect(isUnseen(october(debit, DateTime(2026, 10, 3)), today: DateTime(2026, 10, 3)), isTrue);
    });

    test('bayar sendiri, tercatat, dan dilewati tidak pernah belum terlihat', () {
      final today = DateTime(2026, 10, 9);
      expect(isUnseen(october(netflix(), today), today: today), isFalse);
      final recordedOne = occurrenceStatusesOf(
        debit,
        from: DateTime(2026, 10),
        until: DateTime(2026, 10, 2),
        today: today,
        transactions: [recorded('netflix', DateTime(2026, 10))],
      ).single;
      expect(isUnseen(recordedOne, today: today), isFalse);
      final skipped = debit.copyWith(skippedDates: {DateTime(2026, 10)});
      expect(isUnseen(october(skipped, today), today: today), isFalse);
    });

    test('"Belum terjadi" menunda sampai snoozedUntil', () {
      final snoozed = debit.copyWith(snoozedUntil: DateTime(2026, 10, 5));
      expect(isUnseen(october(snoozed, DateTime(2026, 10, 4)), today: DateTime(2026, 10, 4)), isFalse);
      expect(isUnseen(october(snoozed, DateTime(2026, 10, 5)), today: DateTime(2026, 10, 5)), isTrue);
    });

    test('model menyimpan dan membaca snoozedUntil; dokumen lama tanpa kunci terbaca', () {
      final snoozed = debit.copyWith(snoozedUntil: DateTime(2026, 10, 5));
      expect(RecurringRuleModel.fromJson(RecurringRuleModel.toJson(snoozed)), snoozed);
      final old = RecurringRuleModel.toJson(debit)..remove('snoozedUntil');
      expect(RecurringRuleModel.fromJson(old).snoozedUntil, isNull);
    });
  });
}
