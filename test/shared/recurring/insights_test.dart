import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// W7 bebas cicilan dan W8 porsi terikat (ADR-036 §3.7, T-16.10).
void main() {
  final today = DateTime(2026, 10, 4);

  RecurringRule cicilan({
    RecurringEnd end = const RecurringEndsAfter(12),
    RecurringKind kind = RecurringKind.expense,
    RecurringFrequency frequency = RecurringFrequency.monthly,
    DateTime? anchor,
  }) => RecurringRule(
    id: 'c',
    kind: kind,
    amount: 291400000,
    walletId: 'bca',
    note: 'Cicilan',
    schedule: RecurringSchedule(frequency: frequency, anchorDate: anchor ?? DateTime(2025, 7, 10)),
    end: end,
  );

  group('W7 installmentFreeOf', () {
    test('12× sejak Jul 2025 berakhir Jun 2026: sudah lewat, tidak tampil', () {
      expect(installmentFreeOf(cicilan(), today: today), isNull);
    });

    test('24× sejak Jul 2025: terakhir 10 Jun 2027, mulai Jul 2027 ruang bebas Rp2.914.000/bln', () {
      final free = installmentFreeOf(cicilan(end: const RecurringEndsAfter(24)), today: today)!;
      expect(free.from, DateTime(2027, 7));
      expect(free.perMonth, 291400000);
    });

    test('kemunculan terakhir lebih dari 12 bulan lagi tidak tampil', () {
      expect(installmentFreeOf(cicilan(end: const RecurringEndsAfter(36)), today: today), isNull);
      expect(installmentFreeOf(cicilan(end: RecurringEndsOn(DateTime(2027, 10, 10))), today: today), isNull);
      expect(
        installmentFreeOf(cicilan(end: RecurringEndsOn(DateTime(2027, 10, 9))), today: today)!.from,
        DateTime(2027, 10),
      );
    });

    test('tanpa akhir atau pemasukan tidak tampil', () {
      expect(installmentFreeOf(cicilan(end: const RecurringNeverEnds()), today: today), isNull);
      expect(
        installmentFreeOf(
          cicilan(end: const RecurringEndsAfter(24), kind: RecurringKind.income),
          today: today,
        ),
        isNull,
      );
    });

    test('mingguan dihitung per bulan dari setahun: ×52 ÷12', () {
      final free = installmentFreeOf(
        cicilan(end: const RecurringEndsAfter(10), frequency: RecurringFrequency.weekly, anchor: DateTime(2026, 10)),
        today: today,
      )!;
      expect(free.perMonth, 291400000 * 52 ~/ 12);
    });

    test('yang paling dekat dipilih', () {
      final near = cicilan(end: const RecurringEndsAfter(20));
      final far = cicilan(end: const RecurringEndsAfter(24));
      expect(nearestInstallmentFree([far, near], today: today)!.from, DateTime(2027, 3));
    });
  });

  test('W8 §7B: (5.879.000 + 3.068.500) ÷ 12.000.000 = 74,56% → 75%; tanpa pemasukan → null', () {
    MonthPlan plan(int income) => MonthPlan(
      plannedIncome: income,
      recordedIncome: 0,
      plannedRecurringOut: 587900000,
      recordedRecurringOut: 0,
      budgetPlanned: 306850000,
      budgetSpent: 0,
      unplannedOut: 0,
      unplannedIn: 0,
      budgetOverrun: 0,
      recurringDifference: 0,
      moved: 0,
      hasEstimate: false,
    );
    expect(committedShare(plan(1200000000)), 75);
    expect(committedShare(plan(0)), isNull);
  });
}
