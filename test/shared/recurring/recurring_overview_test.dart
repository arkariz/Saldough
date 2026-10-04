import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

void main() {
  // Contoh PLAN_TAB_LAYOUT §6.1, hari ini 2 Okt 2026 (nominal dalam sen).
  final today = DateTime(2026, 10, 2, 9);

  RecurringRule rule(
    String id,
    int amount,
    DateTime anchor, {
    RecurringKind kind = RecurringKind.expense,
    RecurringAmountMode mode = RecurringAmountMode.fixed,
    RecurringFrequency frequency = RecurringFrequency.monthly,
    RecurringEnd end = const RecurringNeverEnds(),
    String? categoryId,
    bool paused = false,
  }) => RecurringRule(
    id: id,
    kind: kind,
    amount: amount,
    amountMode: mode,
    walletId: 'bca',
    toWalletId: kind == RecurringKind.transfer ? 'tabungan' : null,
    categoryId: categoryId,
    note: id,
    schedule: RecurringSchedule(frequency: frequency, anchorDate: anchor),
    end: end,
    isPaused: paused,
  );

  final rules = [
    rule('Kos', 190000000, DateTime(2026, 9)),
    rule('Listrik', 20000000, DateTime(2026, 9, 5), mode: RecurringAmountMode.estimated),
    rule('Cicilan', 291400000, DateTime(2026, 7, 10), end: const RecurringEndsAfter(12)),
    rule('Gaji', 1200000000, DateTime(2026, 9, 25), kind: RecurringKind.income),
    rule('Tabungan', 100000000, DateTime(2026, 9, 26), kind: RecurringKind.transfer),
    rule('Sabil', 80000000, DateTime(2026, 9, 28)),
    rule('Netflix', 6500000, DateTime(2026, 9)),
    rule('Asuransi', 125000000, DateTime(2026, 3, 12), frequency: RecurringFrequency.yearly),
  ];

  // Sep sudah tercatat semuanya; Okt baru Kos.
  final transactions = <Transaction>[
    for (final r in rules)
      for (final date in occurrencesOf(r, from: DateTime(2026, 9), until: DateTime(2026, 10)))
        ExpenseTransaction(
          id: '${r.id}-$date',
          date: date,
          amount: r.amount,
          note: r.note,
          walletId: 'bca',
          recurrence: RecurrenceLink(ruleId: r.id, occurrenceDate: date),
        ),
    ExpenseTransaction(
      id: 'kos-okt',
      date: DateTime(2026, 10, 1, 8),
      amount: 190000000,
      note: 'Kos',
      walletId: 'bca',
      recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10)),
    ),
  ];

  test('kepala segmen Rutin Okt: masih akan keluar ≈Rp3.979.000 dari Rp5.879.000, masuk Rp12.000.000', () {
    final summary = summarizeRecurringMonth(
      rules,
      from: DateTime(2026, 10),
      until: DateTime(2026, 11),
      today: today,
      transactions: transactions,
    );
    expect(summary.totalOut, 587900000);
    expect(summary.recordedOut, 190000000);
    expect(summary.remainingOut, 397900000);
    expect(summary.scheduledIn, 1200000000);
    expect(summary.hasEstimate, isTrue);
  });

  test('kelompok: Netflix menunggu, sisanya bulan ini urut tanggal, Asuransi nanti; Cicilan 4/12', () {
    final entries = recurringEntries(
      rules,
      windowStart: DateTime(2026, 9),
      monthStart: DateTime(2026, 10),
      monthEnd: DateTime(2026, 11),
      today: today,
      transactions: transactions,
    );
    expect(
      [for (final e in entries) (e.rule.id, e.group)],
      [
        ('Netflix', RecurringGroup.pending),
        ('Kos', RecurringGroup.thisMonth),
        ('Listrik', RecurringGroup.thisMonth),
        ('Cicilan', RecurringGroup.thisMonth),
        ('Gaji', RecurringGroup.thisMonth),
        ('Tabungan', RecurringGroup.thisMonth),
        ('Sabil', RecurringGroup.thisMonth),
        ('Asuransi', RecurringGroup.later),
      ],
    );
    expect(entries.firstWhere((e) => e.rule.id == 'Kos').occurrence?.status, OccurrenceStatus.recorded);
    expect(entries.firstWhere((e) => e.rule.id == 'Cicilan').position, 4);
    expect(entries.last.occurrence?.date, DateTime(2027, 3, 12));
  });

  test('terlewat dihitung per rutin; dijeda dan berakhir terpisah', () {
    final entries = recurringEntries(
      [
        rule('Internet', 35000000, DateTime(2026, 9, 2)),
        rule('Gym', 30000000, DateTime(2026, 9), paused: true),
        rule('Paylater', 50000000, DateTime(2026, 6), end: const RecurringEndsAfter(3)),
      ],
      windowStart: DateTime(2026, 9),
      monthStart: DateTime(2026, 10),
      monthEnd: DateTime(2026, 11),
      today: today,
      transactions: const [],
    );
    final internet = entries.first;
    expect(internet.group, RecurringGroup.pending);
    expect(internet.occurrence?.date, DateTime(2026, 10, 2));
    expect(internet.missedCount, 1);
    expect(entries.map((e) => (e.rule.id, e.group)), contains(('Gym', RecurringGroup.paused)));
    expect(entries.map((e) => (e.rule.id, e.group)), contains(('Paylater', RecurringGroup.ended)));
  });

  test('W3: naik 3% (Rp2.000) bukan kenaikan; naik 21,5% (Rp14.000) kenaikan (§7.7)', () {
    expect(isPriceIncrease(planned: 6500000, recorded: 6700000), isFalse);
    expect(isPriceIncrease(planned: 6500000, recorded: 7900000), isTrue);
    expect(isPriceIncrease(planned: 100000000000, recorded: 100000600000), isFalse); // ≥Rp5.000 tapi <5%
  });

  test('W5: dua langganan atau lebih, per tahun dari jadwal', () {
    final netflix = rule('Netflix', 6500000, DateTime(2026, 9), categoryId: 'builtin.entertainment');
    expect(subscriptionTotals([netflix]), isNull);
    final totals = subscriptionTotals([
      netflix,
      rule('Spotify', 5499000, DateTime(2026, 9, 3), categoryId: 'builtin.entertainment'),
      rule(
        'iCloud',
        15900000,
        DateTime(2026, 2),
        categoryId: 'builtin.entertainment',
        frequency: RecurringFrequency.yearly,
      ),
    ]);
    expect(totals?.perYear, 6500000 * 12 + 5499000 * 12 + 15900000);
    expect(totals?.perMonth, (6500000 * 12 + 5499000 * 12 + 15900000) ~/ 12);
  });

  group('W6 idleRules (T-17.3)', () {
    final now = DateTime(2026, 10, 5);
    RecurringRule spotify({Set<DateTime> skipped = const {}, DateTime? dismissed, bool paused = false}) =>
        RecurringRule(
          id: 'spotify',
          kind: RecurringKind.expense,
          amount: 5499000,
          walletId: 'bca',
          note: 'Spotify',
          schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 7)),
          skippedDates: skipped,
          idleDismissedAt: dismissed,
          isPaused: paused,
        );
    List<RecurringRule> idle(RecurringRule rule) =>
        idleRules([rule], windowStart: DateTime(2026, 9), today: now, transactions: const []);

    test('dua kemunculan terakhir dilewati: menganggur', () {
      expect(idle(spotify(skipped: {DateTime(2026, 9), DateTime(2026, 10)})), hasLength(1));
    });

    test('hanya satu dilewati, dijeda, atau sudah Biarkan: tidak', () {
      expect(idle(spotify(skipped: {DateTime(2026, 10)})), isEmpty);
      expect(idle(spotify(skipped: {DateTime(2026, 9), DateTime(2026, 10)}, paused: true)), isEmpty);
      expect(
        idle(spotify(skipped: {DateTime(2026, 9), DateTime(2026, 10)}, dismissed: DateTime(2026, 10, 2))),
        isEmpty,
      );
    });

    test('autodebet belum terlihat dua kali: menganggur', () {
      final debit = spotify().copyWith(paymentMode: RecurringPaymentMode.autoDebit);
      expect(idle(debit), hasLength(1));
      expect(idle(spotify()), isEmpty);
    });
  });

  group('W3 dari notifikasi: priceIncreaseCandidate (T-17.6)', () {
    final netflix = RecurringRule(
      id: 'netflix',
      kind: RecurringKind.expense,
      amount: 6500000,
      walletId: 'bca',
      note: 'Netflix',
      schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10)),
    );
    ExpenseTransaction paid(String id, int amount, {String wallet = 'bca', int day = 2}) =>
        ExpenseTransaction(id: id, date: DateTime(2026, 10, day), amount: amount, note: '', walletId: wallet);
    Transaction? candidate(List<Transaction> txs) => priceIncreaseCandidate(netflix, DateTime(2026, 10), txs);

    test('naik ≥5% dan ≥Rp5.000 dalam ±3 hari: kandidat', () {
      expect(candidate([paid('a', 7900000)])?.id, 'a');
    });

    test('naik kecil, sama persis, dompet lain, terlalu jauh, atau dua kandidat: tidak', () {
      expect(candidate([paid('a', 6600000)]), isNull);
      expect(candidate([paid('a', 6500000)]), isNull);
      expect(candidate([paid('a', 7900000, wallet: 'jago')]), isNull);
      expect(candidate([paid('a', 7900000, day: 8)]), isNull);
      expect(candidate([paid('a', 7900000), paid('b', 8000000)]), isNull);
    });
  });
}
