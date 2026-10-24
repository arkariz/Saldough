import 'package:saldough/core/financial_month/financial_period.dart';

/// Hari terakhir uji coba yang dimulai [start] (ADR-041 §3.4, FREEMIUM_PAYWALL
/// §8.1): akhir periode keuangan berjalan bila sisanya (inklusif) minimal
/// [minDays] hari, selain itu akhir periode berikutnya. Dihitung sekali dan
/// disimpan; perubahan [schedule] sesudahnya tidak menghitung ulang.
DateTime trialEndsOn(
  DateTime start,
  FinancialMonthSchedule schedule, {
  int minDays = 14,
}) {
  final day = _day(start);
  final period = financialPeriodOf(day, schedule);
  final remaining = DateTime.utc(
    period.end.year,
    period.end.month,
    period.end.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  if (remaining >= minDays) return period.lastDay;
  return schedule.nextOf(period).lastDay;
}

/// Hari mulai uji coba akun yang masuk (ADR-041 §3.4, §3.13 butir 5), atau
/// `null` bila uji coba belum boleh dimulai.
///
/// - [launchAt] `null` (pra-peluncuran): tidak ada uji coba.
/// - Akun yang dibuat ([accountCreatedAt], dari server) pada atau sesudah
///   [launchAt]: hari pembuatan akun, sama di semua perangkat.
/// - Akun yang lebih lama: [firstSeenLocal], hari pertama akun itu masuk di
///   perangkat ini sesudah peluncuran, tidak lebih awal dari [launchAt];
///   `null` bila belum pernah tercatat (pemanggil mencatat hari ini).
DateTime? trialAnchor({
  required DateTime? launchAt,
  required DateTime? accountCreatedAt,
  required DateTime? firstSeenLocal,
}) {
  if (launchAt == null) return null;
  final launch = _day(launchAt);
  if (accountCreatedAt != null && !_day(accountCreatedAt).isBefore(launch)) {
    return _day(accountCreatedAt);
  }
  if (firstSeenLocal == null) return null;
  final seen = _day(firstSeenLocal);
  return seen.isBefore(launch) ? launch : seen;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
