import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/recurring/domain/reminder_plan.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Siapkan dana (W1, E3; ADR-036 §3.6; T-16.7). Contoh PLAN_TAB_LAYOUT:
/// BCA ≈Rp1.200.000, Cicilan iPhone Rp2.914.000 autodebet 10 Okt.
void main() {
  final cicilan = RecurringRule(
    id: 'cicilan',
    kind: RecurringKind.expense,
    amount: 291400000,
    walletId: 'bca',
    note: 'Cicilan iPhone',
    schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 9, 10)),
    paymentMode: RecurringPaymentMode.autoDebit,
  );

  List<FundingWarning> warn(DateTime today, {RecurringRule? rule}) => fundingWarnings(
    [rule ?? cicilan],
    today: today,
    transactions: const [],
    walletName: (_) => 'BCA',
    projectionOf: (walletId) => projectCashflow(
      const [],
      startBalance: 120000000,
      today: today,
      until: DateTime(2026, 11),
      pendingFrom: DateTime(2026, 10),
      transactions: const [],
      walletId: walletId,
    ),
  );

  test('H−3: kurang ≈Rp1.714.000 di BCA', () {
    final warning = warn(DateTime(2026, 10, 7, 9)).single;
    expect(warning.date, DateTime(2026, 10, 10));
    expect(warning.balance, 120000000);
    expect(warning.shortfall, 171400000);
    expect(warning.walletName, 'BCA');
  });

  test('H−4 belum, H0 masih; bayar sendiri tidak pernah', () {
    expect(warn(DateTime(2026, 10, 6, 9)), isEmpty);
    expect(warn(DateTime(2026, 10, 10, 7)), hasLength(1));
    final manual = cicilan.copyWith(paymentMode: RecurringPaymentMode.manual);
    expect(warn(DateTime(2026, 10, 7), rule: manual), isEmpty);
  });

  test('pengingat siapkan dana H−1 09.00, id stabil, tanpa aksi Catat', () {
    final now = DateTime(2026, 10, 7, 10);
    final warnings = warn(now);
    List<PlannedReminder> plan() => planReminders(const [], now: now, transactions: const [], funding: warnings);
    final reminder = plan().single;
    expect(reminder.kind, ReminderKind.funding);
    expect(reminder.at, DateTime(2026, 10, 9, 9));
    expect(reminder.canRecord, isFalse);
    expect(plan().single.id, reminder.id);
    // H−1 sudah lewat: tidak dijadwalkan.
    expect(
      planReminders(const [], now: DateTime(2026, 10, 9, 10), transactions: const [], funding: warnings),
      isEmpty,
    );
  });
}
