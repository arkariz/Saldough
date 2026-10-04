import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/insights.dart';
import 'package:saldough/shared/recurring/domain/occurrence_status.dart';
import 'package:saldough/shared/recurring/domain/occurrences.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Kepala segmen Rutin untuk satu bulan (PLAN_TAB_LAYOUT §6.1): berapa rutin
/// keluar yang masih akan keluar, berapa yang sudah tercatat, dan pemasukan
/// terjadwal. Transfer tidak dihitung keluar maupun masuk (aturan 7).
final class RecurringMonthSummary extends Equatable {
  /// Membuat [RecurringMonthSummary].
  const RecurringMonthSummary({
    required this.totalOut,
    required this.recordedOut,
    required this.scheduledIn,
    required this.hasEstimate,
  });

  /// Seluruh kemunculan pengeluaran rutin di bulan itu yang tidak dilewati,
  /// dalam sen. Yang tercatat memakai nominal transaksinya.
  final int totalOut;

  /// Bagian [totalOut] yang sudah tercatat.
  final int recordedOut;

  /// Seluruh kemunculan pemasukan rutin di bulan itu yang tidak dilewati.
  final int scheduledIn;

  /// Ada nominal kira-kira di antara yang belum tercatat: angka tampil
  /// berawalan `≈`.
  final bool hasEstimate;

  /// "Masih akan keluar": [totalOut] − [recordedOut].
  int get remainingOut => totalOut - recordedOut;

  @override
  List<Object?> get props => [totalOut, recordedOut, scheduledIn, hasEstimate];
}

/// Ringkasan rutin bulan `from <= d < until` per [today].
///
/// Rutin yang dijeda hanya menyumbang kemunculan yang sudah tercatat:
/// transaksi itu nyata, sisanya tidak lagi direncanakan.
RecurringMonthSummary summarizeRecurringMonth(
  Iterable<RecurringRule> rules, {
  required DateTime from,
  required DateTime until,
  required DateTime today,
  required Iterable<Transaction> transactions,
}) {
  var totalOut = 0;
  var recordedOut = 0;
  var scheduledIn = 0;
  var hasEstimate = false;
  for (final rule in rules) {
    if (rule.kind == RecurringKind.transfer) continue;
    for (final o in occurrenceStatusesOf(rule, from: from, until: until, today: today, transactions: transactions)) {
      if (o.status == OccurrenceStatus.skipped || o.status == OccurrenceStatus.paused) continue;
      final recorded = o.transaction;
      if (recorded == null && rule.isPaused) continue;
      final amount = recorded?.amount ?? rule.amount;
      if (recorded == null && rule.amountMode == RecurringAmountMode.estimated) hasEstimate = true;
      if (rule.kind == RecurringKind.expense) {
        totalOut += amount;
        if (recorded != null) recordedOut += amount;
      } else {
        scheduledIn += amount;
      }
    }
  }
  return RecurringMonthSummary(
    totalOut: totalOut,
    recordedOut: recordedOut,
    scheduledIn: scheduledIn,
    hasEstimate: hasEstimate,
  );
}

/// Kelompok segmen Rutin (PLAN_TAB_LAYOUT §6.2), urut tampil.
enum RecurringGroup {
  /// Ada kemunculan menunggu atau terlewat.
  pending,

  /// Punya kemunculan di bulan berjalan.
  thisMonth,

  /// Kemunculan berikutnya sesudah bulan berjalan.
  later,

  /// Dijeda.
  paused,

  /// Sudah berakhir.
  ended,
}

/// Satu baris segmen Rutin.
final class RecurringEntry extends Equatable {
  /// Membuat [RecurringEntry].
  const RecurringEntry({
    required this.rule,
    required this.group,
    this.occurrence,
    this.missedCount = 0,
    this.position,
  });

  /// Rutinnya.
  final RecurringRule rule;

  /// Kelompoknya.
  final RecurringGroup group;

  /// Kemunculan yang mewakili baris ini: yang menunggu (atau terlewat
  /// terlama), yang di bulan berjalan, atau yang berikutnya. `null` untuk
  /// rutin dijeda atau berakhir.
  final Occurrence? occurrence;

  /// Kemunculan terlewat selain yang menunggu (J8: "n terlewat").
  final int missedCount;

  /// Urutan [occurrence] di jadwal (mulai 1), untuk "k/N" rutin N kali.
  final int? position;

  @override
  List<Object?> get props => [rule, group, occurrence, missedCount, position];
}

/// Baris segmen Rutin untuk bulan `monthStart <= d < monthEnd`.
///
/// Menunggu dan terlewat hanya dicari sejak [windowStart] (bulan
/// sebelumnya, ADR-035 §3.2), karena [transactions] hanya memuat bulan-bulan
/// itu; kemunculan yang lebih lama tidak dianggap terlewat.
List<RecurringEntry> recurringEntries(
  Iterable<RecurringRule> rules, {
  required DateTime windowStart,
  required DateTime monthStart,
  required DateTime monthEnd,
  required DateTime today,
  required Iterable<Transaction> transactions,
}) {
  final entries = <RecurringEntry>[];
  for (final rule in rules) {
    if (rule.isPaused) {
      entries.add(RecurringEntry(rule: rule, group: RecurringGroup.paused));
      continue;
    }
    final statuses = occurrenceStatusesOf(
      rule,
      from: windowStart,
      until: monthEnd,
      today: today,
      transactions: transactions,
    );
    final waiting = [
      for (final o in statuses)
        if (o.status == OccurrenceStatus.pending || o.status == OccurrenceStatus.missed) o,
    ];
    if (waiting.isNotEmpty) {
      final shown = waiting.firstWhere((o) => o.status == OccurrenceStatus.pending, orElse: () => waiting.first);
      entries.add(
        RecurringEntry(
          rule: rule,
          group: RecurringGroup.pending,
          occurrence: shown,
          missedCount: waiting.length - 1,
          position: _positionOf(rule, shown.date),
        ),
      );
      continue;
    }
    final inMonth = [
      for (final o in statuses)
        if (!o.date.isBefore(monthStart)) o,
    ];
    if (inMonth.isNotEmpty) {
      // Mingguan: yang belum tercatat lebih berguna daripada yang sudah.
      final shown = inMonth.firstWhere((o) => o.status == OccurrenceStatus.upcoming, orElse: () => inMonth.last);
      entries.add(
        RecurringEntry(
          rule: rule,
          group: RecurringGroup.thisMonth,
          occurrence: shown,
          position: _positionOf(rule, shown.date),
        ),
      );
      continue;
    }
    final next = nextOccurrence(rule, monthEnd);
    if (next == null) {
      entries.add(RecurringEntry(rule: rule, group: RecurringGroup.ended));
    } else {
      entries.add(
        RecurringEntry(
          rule: rule,
          group: RecurringGroup.later,
          occurrence: Occurrence(rule: rule, date: next, status: OccurrenceStatus.upcoming),
          position: _positionOf(rule, next),
        ),
      );
    }
  }
  int byDate(RecurringEntry a, RecurringEntry b) => a.occurrence!.date.compareTo(b.occurrence!.date);
  int byName(RecurringEntry a, RecurringEntry b) => a.rule.note.toLowerCase().compareTo(b.rule.note.toLowerCase());
  return [
    for (final group in RecurringGroup.values)
      ...(entries.where((e) => e.group == group).toList()
        ..sort(group == RecurringGroup.paused || group == RecurringGroup.ended ? byName : byDate)),
  ];
}

/// Urutan [date] di jadwal [rule] (mulai 1), hanya untuk rutin N kali.
int? _positionOf(RecurringRule rule, DateTime date) {
  if (rule.end is! RecurringEndsAfter) return null;
  return occurrencesOf(
    rule,
    from: rule.schedule.anchorDate,
    until: DateTime(date.year, date.month, date.day + 1),
  ).length;
}

/// W3 (kenaikan harga, RECURRING_AND_FORECAST §7B): nominal tercatat
/// [recorded] naik ≥5% **dan** ≥Rp5.000 dari nominal rutin [planned].
/// Keduanya dalam sen.
bool isPriceIncrease({required int planned, required int recorded}) {
  final increase = recorded - planned;
  return increase >= 500000 && increase * 100 >= planned * 5;
}

/// Kategori yang dihitung sebagai langganan untuk W5. Kategori bawaan tidak
/// punya "Langganan" sendiri; chip pembuka Langganan memakai Hiburan.
const subscriptionCategoryIds = {'builtin.entertainment'};

/// W5: total langganan per bulan dan per tahun, dalam sen, dari rutin aktif
/// berkategori langganan; `null` bila kurang dari dua.
///
/// Per tahun dihitung dari jadwal (bulanan ×12, mingguan ×52, tahunan ×1,
/// dibagi selang); per bulan = per tahun ÷ 12, dibulatkan ke bawah.
({int perMonth, int perYear})? subscriptionTotals(Iterable<RecurringRule> rules) {
  final subscriptions = [
    for (final rule in rules)
      if (!rule.isPaused && rule.kind == RecurringKind.expense && subscriptionCategoryIds.contains(rule.categoryId))
        rule,
  ];
  if (subscriptions.length < 2) return null;
  final perYear = subscriptions.fold(0, (sum, rule) => sum + perYearOf(rule));
  return (perMonth: perYear ~/ 12, perYear: perYear);
}
