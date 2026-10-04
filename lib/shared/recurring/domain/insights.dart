import 'package:saldough/shared/recurring/domain/month_plan.dart';
import 'package:saldough/shared/recurring/domain/occurrences.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Nominal [rule] setahun dari jadwalnya (bulanan ×12, mingguan ×52,
/// tahunan ×1, dibagi selang), dalam sen.
int perYearOf(RecurringRule rule) {
  final timesPerYear = switch (rule.schedule.frequency) {
    RecurringFrequency.weekly => 52,
    RecurringFrequency.monthly => 12,
    RecurringFrequency.yearly => 1,
  };
  return rule.amount * timesPerYear ~/ rule.schedule.interval;
}

/// W7 bebas cicilan (ADR-036 §3.7): pengeluaran rutin yang berakhir (N kali
/// atau sampai tanggal) dengan kemunculan terakhir mulai [today] sampai 12
/// bulan ke depan. [from] adalah bulan kalender sesudah kemunculan terakhir;
/// [perMonth] nominal setahun ÷ 12, dibulatkan ke bawah.
typedef InstallmentFree = ({RecurringRule rule, DateTime from, int perMonth});

/// [InstallmentFree] untuk [rule], atau `null` bila tidak memenuhi syarat.
InstallmentFree? installmentFreeOf(RecurringRule rule, {required DateTime today}) {
  if (rule.isPaused || rule.kind != RecurringKind.expense) return null;
  final last = lastOccurrence(rule);
  if (last == null) return null;
  final day = DateTime(today.year, today.month, today.day);
  if (last.isBefore(day) || !last.isBefore(DateTime(day.year + 1, day.month, day.day))) return null;
  return (rule: rule, from: DateTime(last.year, last.month + 1), perMonth: perYearOf(rule) ~/ 12);
}

/// W7 yang paling dekat di antara [rules] (satu baris di Bulan ini).
InstallmentFree? nearestInstallmentFree(Iterable<RecurringRule> rules, {required DateTime today}) {
  InstallmentFree? nearest;
  for (final rule in rules) {
    final free = installmentFreeOf(rule, today: today);
    if (free != null && (nearest == null || free.from.isBefore(nearest.from))) nearest = free;
  }
  return nearest;
}

/// W8 porsi terikat (ADR-036 §3.7): `(rutin keluar + anggaran) ÷ pemasukan
/// terencana`, dalam persen dibulatkan ke terdekat; `null` bila pemasukan
/// terencana nol.
int? committedShare(MonthPlan plan) {
  final income = plan.plannedIncome;
  if (income <= 0) return null;
  final committed = plan.plannedRecurringOut + plan.budgetPlanned;
  return (committed * 200 + income) ~/ (income * 2);
}
