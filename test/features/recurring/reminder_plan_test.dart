import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/recurring/data/reminder_settings_repository_impl.dart';
import 'package:saldough/features/recurring/domain/reminder_plan.dart';
import 'package:saldough/features/recurring/domain/reminder_scheduler.dart';
import 'package:saldough/features/recurring/domain/sync_recurring_reminders.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';

final class _FakeScheduler implements ReminderScheduler {
  List<PlannedReminder>? scheduled;

  @override
  Future<ReminderResponse?> initialize() async => null;

  @override
  Stream<ReminderResponse> get responses => const Stream.empty();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> replaceAll(List<PlannedReminder> reminders) async => scheduled = reminders;
}

void main() {
  final now = DateTime(2026, 10, 2, 15);

  RecurringRule rule(
    String id,
    int day, {
    RecurringPaymentMode? payment = RecurringPaymentMode.manual,
    RecurringKind kind = RecurringKind.expense,
    bool reminders = true,
    bool paused = false,
  }) => RecurringRule(
    id: id,
    kind: kind,
    amount: 6500000,
    walletId: 'bca',
    note: id,
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, day)),
    paymentMode: kind == RecurringKind.income ? null : payment,
    reminders: reminders,
    isPaused: paused,
  );

  test('bayar sendiri: H−1 jam 9 dan hari jatuh tempo, hanya dalam 35 hari dan belum lewat', () {
    final plan = planReminders([rule('Netflix', 10)], now: now, transactions: const []);
    expect(
      [for (final r in plan) (r.kind, r.at)],
      [
        (ReminderKind.dueSoon, DateTime(2026, 10, 9, 9)),
        (ReminderKind.dueToday, DateTime(2026, 10, 10, 9)),
      ],
    );
    expect(plan.first.payload, 'record|Netflix|2026-10-10');
    expect(plan.first.canRecord, isTrue);
  });

  test('autodebet dan pemasukan tanpa H−1; dijeda, pengingat mati, dan sudah tercatat tidak dijadwalkan', () {
    final recorded = ExpenseTransaction(
      id: 't',
      date: DateTime(2026, 10, 2),
      amount: 6500000,
      note: '',
      walletId: 'bca',
      recurrence: RecurrenceLink(ruleId: 'Kos', occurrenceDate: DateTime(2026, 10, 5)),
    );
    final plan = planReminders(
      [
        rule('Spotify', 12, payment: RecurringPaymentMode.autoDebit),
        rule('Gaji', 25, kind: RecurringKind.income),
        rule('Gym', 15, paused: true),
        rule('Sabun', 16, reminders: false),
        rule('Kos', 5),
      ],
      now: now,
      transactions: [recorded],
    );
    expect(
      [for (final r in plan) (r.kind, r.at, r.items.single.rule.id)],
      [
        (ReminderKind.dueToday, DateTime(2026, 10, 12, 9), 'Spotify'),
        (ReminderKind.dueToday, DateTime(2026, 10, 25, 9), 'Gaji'),
        // Kos 5 Okt sudah tercatat; 5 Nov masih dalam 35 hari.
        (ReminderKind.dueSoon, DateTime(2026, 11, 4, 9), 'Kos'),
        (ReminderKind.dueToday, DateTime(2026, 11, 5, 9), 'Kos'),
      ],
    );
  });

  test('dua rutin di hari yang sama: satu ringkasan tanpa aksi Catat; id stabil saat disusun ulang', () {
    final rules = [rule('Netflix', 10, payment: RecurringPaymentMode.autoDebit), rule('Kos', 10, payment: null)];
    final first = planReminders(rules, now: now, transactions: const []);
    final day = first.where((r) => r.kind == ReminderKind.dueToday).single;
    expect(day.items.map((i) => i.rule.id), ['Kos', 'Netflix']);
    expect(day.canRecord, isFalse);
    expect(day.payload, 'open');
    final again = planReminders(rules, now: now, transactions: const []);
    expect(again.map((r) => r.id), first.map((r) => r.id));
    expect(first.map((r) => r.id).toSet(), hasLength(first.length));
  });

  test('payload satu kemunculan bisa dibaca kembali', () {
    expect(parseReminderPayload(reminderPayload('kos', DateTime(2026, 11))), (
      ruleId: 'kos',
      date: DateTime(2026, 11),
    ));
    expect(parseReminderPayload('open'), isNull);
  });

  test('sinkron: sakelar global mati membatalkan semua; nyala menjadwalkan', () async {
    final storage = InMemoryKeyValueStorage();
    final rules = RecurringRuleRepositoryImpl(storage: storage);
    final settings = ReminderSettingsRepositoryImpl(storage: storage);
    final scheduler = _FakeScheduler();
    await rules.saveRule(rule('Netflix', 10));
    final sync = SyncRecurringReminders(
      scheduler: scheduler,
      settings: settings,
      rules: rules,
      transactions: TransactionRepositoryImpl(storage: storage),
      clock: () => now,
    );

    expect(await sync(), 0);
    expect(scheduler.scheduled, isEmpty);

    await settings.setEnabled(enabled: true);
    expect(await sync(), 2);
    expect(scheduler.scheduled, hasLength(2));
  });

  test('dokumen rutin lama tanpa kunci reminders: pengingat nyala', () {
    final json = RecurringRuleModel.toJson(rule('Netflix', 10))..remove('reminders');
    expect(RecurringRuleModel.fromJson(json).reminders, isTrue);
  });
}
