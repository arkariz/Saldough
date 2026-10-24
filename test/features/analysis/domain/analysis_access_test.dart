import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/features/analysis/domain/analysis_access.dart';

/// Batas periode Analisis Gratis (ADR-041 §3.8).
void main() {
  final calendar = FinancialMonthSchedule.initial;
  final now = DateTime(2026, 9, 30, 10);

  bool locked(DateTime date, {int free = 6, FinancialMonthSchedule? schedule}) => isAnalysisPeriodLocked(
    period: (schedule ?? calendar).periodOf(date),
    now: now,
    schedule: schedule ?? calendar,
    freePeriods: free,
  );

  test('periode berjalan dan lima sebelumnya terbuka; yang keenam sebelumnya terkunci', () {
    expect(locked(DateTime(2026, 9, 15)), isFalse);
    expect(locked(DateTime(2026, 4)), isFalse, reason: 'Apr = periode ke-6 dari Sep');
    expect(locked(DateTime(2026, 3, 31)), isTrue);
    expect(locked(DateTime(2025, 1, 5)), isTrue);
  });

  test('batas dari Remote Config dipakai; minimal satu periode (berjalan tidak pernah terkunci)', () {
    expect(locked(DateTime(2026, 8, 31), free: 1), isTrue);
    expect(locked(DateTime(2026, 9), free: 1), isFalse);
    expect(locked(DateTime(2026, 9), free: 0), isFalse);
    expect(locked(DateTime(2026, 8, 31), free: 2), isFalse);
  });

  test('mengikuti jadwal periode (tanggal 25) dan peralihan', () {
    final from25 = FinancialMonthSchedule.single(const FinancialMonthStart.day(25));
    // 30 Sep masuk periode 25 Sep–24 Okt; enam periode: Apr 25 sampai Sep 25.
    expect(locked(DateTime(2026, 4, 25), schedule: from25), isFalse);
    expect(locked(DateTime(2026, 4, 24), schedule: from25), isTrue);
    final changed = calendar.changedOn(DateTime(2026, 8, 10), const FinancialMonthStart.day(25));
    expect(locked(DateTime(2026, 9), schedule: changed), isFalse);
  });
}
