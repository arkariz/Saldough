import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Catat otomatis (T-17.5, ADR-037 §3.2).
void main() {
  final today = DateTime(2026, 10, 5, 9);
  final window = DateTime(2026, 9);

  RecurringRule kos({
    bool auto = true,
    RecurringAmountMode mode = RecurringAmountMode.fixed,
    RecurringPaymentMode? payment,
    int day = 5,
  }) => RecurringRule(
    id: 'kos',
    kind: RecurringKind.expense,
    amount: 190000000,
    amountMode: mode,
    walletId: 'bca',
    note: 'Kos',
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, day)),
    paymentMode: payment,
    autoRecord: auto && mode == RecurringAmountMode.fixed,
  );

  List<(RecurringRule, DateTime)> due(
    RecurringRule rule, {
    List<Transaction> transactions = const [],
    Set<(String, DateTime)> logged = const {},
  }) => dueAutoRecords([rule], windowStart: window, today: today, transactions: transactions, logged: logged);

  test('tetap + autoRecord: kemunculan hari ini dicatat', () {
    expect(due(kos()).single.$2, DateTime(2026, 10, 5));
  });

  test('tanpa autoRecord atau kira-kira: tidak', () {
    expect(due(kos(auto: false)), isEmpty);
    expect(due(kos(mode: RecurringAmountMode.estimated)), isEmpty);
  });

  test('autodebet menunggu H+1', () {
    expect(due(kos(payment: RecurringPaymentMode.autoDebit)), isEmpty);
    expect(due(kos(payment: RecurringPaymentMode.autoDebit, day: 4)).single.$2, DateTime(2026, 10, 4));
  });

  test('ragu (ada transaksi mirip), sudah tertaut, atau sudah di log: tidak', () {
    final similar = ExpenseTransaction(
      id: 'n',
      date: DateTime(2026, 10, 4),
      amount: 190000000,
      note: '',
      walletId: 'bca',
    );
    expect(due(kos(), transactions: [similar]), isEmpty);
    final linked = ExpenseTransaction(
      id: 'l',
      date: DateTime(2026, 10, 5),
      amount: 190000000,
      note: 'Kos',
      walletId: 'bca',
      recurrence: RecurrenceLink(ruleId: 'kos', occurrenceDate: DateTime(2026, 10, 5)),
    );
    expect(due(kos(), transactions: [linked]), isEmpty);
    expect(due(kos(), logged: {('kos', DateTime(2026, 10, 5))}), isEmpty);
    final raised = ExpenseTransaction(
      id: 'r',
      date: DateTime(2026, 10, 5),
      amount: 210000000,
      note: '',
      walletId: 'bca',
    );
    expect(due(kos(), transactions: [raised]), isEmpty);
  });

  test('log: tambah, tandai dibatalkan, tetap ada supaya tidak dicatat lagi', () async {
    final log = AutoRecordLogRepositoryImpl(storage: InMemoryKeyValueStorage(), clock: () => today);
    final entry = AutoRecordEntry(
      transactionId: 't1',
      ruleId: 'kos',
      ruleName: 'Kos',
      occurrenceDate: DateTime(2026, 10, 5),
      recordedAt: today,
    );
    await log.add([entry]);
    await log.markUndone('t1');
    final listed = (await log.list(today)).getOrElse((_) => const []);
    expect(listed.single.undone, isTrue);
    expect(listed.single.occurrenceDate, DateTime(2026, 10, 5));
  });
}
