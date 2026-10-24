import 'package:saldough/core/financial_month/financial_period.dart';

/// Periode yang lebih tua dari batas Analisis Gratis (ADR-041 §3.8): Gratis
/// melihat periode berjalan dan [freePeriods] - 1 periode sebelumnya; yang
/// lebih tua terkunci di Analisis (Riwayat Daftar tetap penuh). Batas selalu
/// minimal satu periode, jadi periode berjalan tidak pernah terkunci.
bool isAnalysisPeriodLocked({
  required FinancialPeriod period,
  required DateTime now,
  required FinancialMonthSchedule schedule,
  required int freePeriods,
}) {
  var oldestFree = schedule.periodOf(now);
  for (var i = 1; i < freePeriods; i++) {
    oldestFree = schedule.previousOf(oldestFree);
  }
  return period.start.isBefore(oldestFree.start);
}
