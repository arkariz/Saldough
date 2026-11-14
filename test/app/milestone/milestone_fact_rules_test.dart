import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/milestone/inbox_clear_tracker.dart';
import 'package:saldough/app/milestone/milestone_fact_rules.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_def.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

final DateTime today = DateTime(2026, 11, 14);
final FinancialMonthSchedule schedule = FinancialMonthSchedule.initial;

Wallet wallet({bool active = true}) =>
    Wallet(id: 'w', name: 'Dompet', iconKey: 'wallet', initialBalance: 0, currentBalance: 0, isActive: active);

ExpenseTransaction expense(String id, DateTime date, {String? categoryId = 'makan', String? budgetItemId, RecurrenceLink? recurrence}) =>
    ExpenseTransaction(
      id: id,
      date: date,
      amount: 1000,
      note: '',
      walletId: 'w',
      categoryId: categoryId,
      budgetItemId: budgetItemId,
      recurrence: recurrence,
    );

Set<MilestoneFact> facts({
  List<Wallet>? wallets,
  List<Transaction> transactions = const [],
  List<RecurringRule> rules = const [],
  bool backupDone = false,
  bool inboxCleared = false,
}) => milestoneFactsFrom(
  wallets: wallets ?? [wallet()],
  transactions: transactions,
  rules: rules,
  schedule: schedule,
  today: today,
  backupDone: backupDone,
  inboxCleared: inboxCleared,
);

List<Transaction> octTxs({int n = 3, String? uncategorizedId}) => [
  for (var i = 0; i < n; i++) expense('t$i', DateTime(2026, 10, 3 + i)),
  if (uncategorizedId != null) expense(uncategorizedId, DateTime(2026, 10, 20), categoryId: null),
];

RecurringRule rule({DateTime? anchor, Set<DateTime> skipped = const {}, bool paused = false}) => RecurringRule(
  id: 'r',
  kind: RecurringKind.expense,
  amount: 1000,
  walletId: 'w',
  schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: anchor ?? DateTime(2026, 9, 10)),
  skippedDates: skipped,
  isPaused: paused,
);

void main() {
  group('fakta sederhana', () {
    test('dompet: hanya yang aktif', () {
      expect(facts(wallets: []), isNot(contains(MilestoneFact.walletExists)));
      expect(facts(wallets: [wallet(active: false)]), isNot(contains(MilestoneFact.walletExists)));
      expect(facts(), contains(MilestoneFact.walletExists));
    });

    test('catatan, anggaran terpakai, dan pembayaran freelance', () {
      expect(facts(), isNot(contains(MilestoneFact.recordExists)));
      final f = facts(
        transactions: [
          expense('a', DateTime(2026, 11, 2), budgetItemId: 'pos'),
          IncomeTransaction(
            id: 'b',
            date: DateTime(2026, 11, 3),
            amount: 5,
            note: '',
            walletId: 'w',
            freelancePaymentId: 'p',
          ),
        ],
      );
      expect(f, containsAll([MilestoneFact.recordExists, MilestoneFact.budgetItemLinked, MilestoneFact.freelancePaid]));
      expect(facts(transactions: [expense('a', DateTime(2026, 11, 2))]), isNot(contains(MilestoneFact.budgetItemLinked)));
    });

    test('cadangan dan kotak masuk diteruskan', () {
      expect(facts(backupDone: true, inboxCleared: true), containsAll([MilestoneFact.backupDone, MilestoneFact.inboxCleared]));
      expect(facts(), isNot(contains(MilestoneFact.backupDone)));
      expect(facts(), isNot(contains(MilestoneFact.inboxCleared)));
    });
  });

  group('Periode rapi', () {
    test('periode tertutup, 3 transaksi, semua berkategori', () {
      expect(facts(transactions: octTxs()), contains(MilestoneFact.tidyPeriodClosed));
    });

    test('satu transaksi tanpa kategori membatalkan periode itu', () {
      expect(facts(transactions: octTxs(uncategorizedId: 'u')), isNot(contains(MilestoneFact.tidyPeriodClosed)));
    });

    test('kurang dari 3 transaksi tidak cukup', () {
      expect(facts(transactions: octTxs(n: 2)), isNot(contains(MilestoneFact.tidyPeriodClosed)));
    });

    test('periode berjalan belum tertutup', () {
      final txs = [for (var i = 0; i < 3; i++) expense('t$i', DateTime(2026, 11, 1 + i))];
      expect(facts(transactions: txs), isNot(contains(MilestoneFact.tidyPeriodClosed)));
    });

    test('transfer tidak dihitung; freelance tanpa kategori tidak dianggap tanpa kategori', () {
      final txs = [
        ...octTxs(n: 2),
        IncomeTransaction(
          id: 'f',
          date: DateTime(2026, 10, 9),
          amount: 5,
          note: '',
          walletId: 'w',
          freelancePaymentId: 'p',
        ),
        TransferTransaction(
          id: 'x',
          date: DateTime(2026, 10, 10),
          amount: 5,
          note: '',
          fromWalletId: 'w',
          toWalletId: 'v',
        ),
      ];
      expect(facts(transactions: txs), contains(MilestoneFact.tidyPeriodClosed));
    });
  });

  group('Rutin tak terlewat', () {
    test('semua kemunculan periode tertutup tercatat', () {
      final txs = [
        expense('a', DateTime(2026, 9, 10), recurrence: RecurrenceLink(ruleId: 'r', occurrenceDate: DateTime(2026, 9, 10))),
        expense('b', DateTime(2026, 10, 10), recurrence: RecurrenceLink(ruleId: 'r', occurrenceDate: DateTime(2026, 10, 10))),
      ];
      expect(facts(transactions: txs, rules: [rule()]), contains(MilestoneFact.recurringClearClosed));
    });

    test('kemunculan terlewat membuat periode itu tidak bersih', () {
      expect(
        facts(rules: [rule(anchor: DateTime(2026, 10, 10))]),
        isNot(contains(MilestoneFact.recurringClearClosed)),
      );
    });

    test('dilewati dihitung selesai', () {
      expect(
        facts(rules: [rule(anchor: DateTime(2026, 10, 10), skipped: {DateTime(2026, 10, 10)})]),
        contains(MilestoneFact.recurringClearClosed),
      );
    });

    test('rutin dijeda dan tanpa rutin tidak memenuhi', () {
      expect(facts(rules: [rule(paused: true)]), isNot(contains(MilestoneFact.recurringClearClosed)));
      expect(facts(), isNot(contains(MilestoneFact.recurringClearClosed)));
    });
  });

  test('inboxDroppedToZero: hanya dari ≥1 ke nol dengan titik awal diketahui', () {
    expect(inboxDroppedToZero(previous: 2, current: 0), isTrue);
    expect(inboxDroppedToZero(previous: 1, current: 0), isTrue);
    expect(inboxDroppedToZero(previous: 0, current: 0), isFalse);
    expect(inboxDroppedToZero(previous: null, current: 0), isFalse);
    expect(inboxDroppedToZero(previous: 2, current: 1), isFalse);
  });
}
