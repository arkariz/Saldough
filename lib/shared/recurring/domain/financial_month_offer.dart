import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Tanggal mulai bulan keuangan yang ditawarkan sesudah [rule] disimpan
/// (FINANCIAL_PERIOD F2), atau `null` bila tidak ditawarkan. Hanya untuk
/// rutin **pemasukan** tiap bulan bertanggal selain 1, selama awal bulan
/// keuangan masih bawaan dan belum pernah diubah pengguna, dan sekali per
/// rutin. Gajian tanggal 29–31 hanya ditawari "hari terakhir bulan" bila
/// tanggalnya memang hari terakhir bulan itu.
FinancialMonthStart? financialMonthOfferFor(
  RecurringRule rule, {
  required FinancialMonthSchedule schedule,
  required FinancialMonthOffer offer,
}) {
  if (rule.kind != RecurringKind.income || rule.schedule.frequency != RecurringFrequency.monthly) return null;
  if (offer.changedByUser || offer.offeredRuleIds.contains(rule.id)) return null;
  if (schedule != FinancialMonthSchedule.initial) return null;
  final anchor = rule.schedule.anchorDate;
  if (anchor.day == 1) return null;
  if (anchor.day <= FinancialMonthStart.maxDay) return FinancialMonthStart.day(anchor.day);
  final isLastDay = DateTime(anchor.year, anchor.month, anchor.day + 1).day == 1;
  return isLastDay ? FinancialMonthStart.lastDay : null;
}
