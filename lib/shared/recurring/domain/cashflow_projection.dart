import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/occurrence_status.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Sisa satu pos anggaran pengeluaran yang dibagi rata ke hari tersisa
/// periodenya (§7.4). Sen; `remaining` tidak negatif. `key` = kunci pos
/// template anggaran rutin (ADR-036 §3.4), untuk rutin yang tertaut.
typedef BudgetSpendLine = ({String walletId, String? key, int remaining, DateTime periodEnd});

/// Pemasukan yang belum pasti, mis. pembayaran freelance belum dibayar
/// (KT-R6). Dihitung di perkiraan dan ditandai "belum pasti".
typedef UncertainIncome = ({String? walletId, int amount, DateTime date});

/// Saldo perkiraan di akhir satu hari.
typedef ProjectedDay = ({DateTime date, int balance});

/// Rincian perkiraan per komponen untuk lembar "Rincian" (§7.3). Semua
/// positif kecuali [transfers]; akhir = saldo nyata + [income] − [recurringOut]
/// − [budget] − [unplanned] + [uncertain] + [transfers].
typedef ProjectionBreakdown = ({
  int income,
  int recurringOut,
  int budget,
  int unplanned,
  int uncertain,
  int transfers,
});

/// Hasil perkiraan saldo (§7.3). Semua `int` sen; ini **perkiraan**, selalu
/// tampil berawalan `≈`.
final class CashflowProjection extends Equatable {
  /// Membuat [CashflowProjection].
  const CashflowProjection({
    required this.startBalance,
    required this.days,
    required this.uncertain,
    required this.unplannedPerDay,
    required this.breakdown,
  });

  /// Rincian per komponen; jumlahnya sama dengan [endBalance] − [startBalance].
  final ProjectionBreakdown breakdown;

  /// Saldo nyata saat ini.
  final int startBalance;

  /// Saldo akhir tiap hari dari hari ini sampai hari terakhir rentang.
  final List<ProjectedDay> days;

  /// Bagian yang belum pasti (freelance belum dibayar) di rentang ini.
  final int uncertain;

  /// Porsi harian "di luar rencana" yang dipakai, atau `null` bila tidak.
  final int? unplannedPerDay;

  /// Saldo perkiraan di akhir rentang.
  int get endBalance => days.isEmpty ? startBalance : days.last.balance;

  /// Titik terendah: hari pertama dengan saldo terkecil.
  ProjectedDay? get lowest {
    ProjectedDay? low;
    for (final day in days) {
      if (low == null || day.balance < low.balance) low = day;
    }
    return low;
  }

  @override
  List<Object?> get props => [startBalance, days, uncertain, unplannedPerDay, breakdown];
}

/// Perkiraan saldo dari [today] sampai sebelum [until] (§7.3–7.5).
///
/// - Hari ini: saldo nyata [startBalance], lalu kemunculan yang sudah tiba
///   tetapi belum dicatat sejak [pendingFrom] dianggap sudah terjadi.
/// - Tiap hari: kemunculan rutin bertanggal hari itu, porsi harian sisa pos
///   anggaran ([budgets]), porsi harian di luar rencana ([unplannedPerDay]),
///   dan pemasukan belum pasti ([uncertainIncome]).
/// - [walletId] `null` = seluruh dompet: transfer tidak mengubah total
///   (invarian 16). Untuk satu dompet, transfer mengurangi asal dan
///   menambah tujuan.
///
/// Pembagian harian memakai `int`: sisa pembagian jatuh di hari terakhir
/// periode, jadi jumlahnya selalu persis.
///
/// [reportFrom] (bulan depan, ADR-036 §3.5): hitungan tetap berjalan sejak
/// [today], tetapi hanya hari mulai [reportFrom] yang dilaporkan; saldo awal
/// hasilnya = perkiraan akhir hari sebelumnya, jadi bulan-bulan berantai
/// persis dalam sen (invarian 20).
CashflowProjection projectCashflow(
  Iterable<RecurringRule> rules, {
  required int startBalance,
  required DateTime today,
  required DateTime until,
  required DateTime pendingFrom,
  required Iterable<Transaction> transactions,
  Iterable<BudgetSpendLine> budgets = const [],
  int? unplannedPerDay,
  Iterable<UncertainIncome> uncertainIncome = const [],
  String? walletId,
  DateTime? reportFrom,
}) {
  final start = DateTime(today.year, today.month, today.day);
  final reported = reportFrom == null || !reportFrom.isAfter(start)
      ? start
      : DateTime(reportFrom.year, reportFrom.month, reportFrom.day);
  final changes = <DateTime, int>{};
  // Kemunculan rutin tertaut pos yang diletakkan di tanggalnya (§7.4).
  final linked = <String, List<(DateTime, int)>>{};
  var income = 0;
  var recurringOut = 0;
  var budget = 0;
  var transfers = 0;
  /// Menambah perubahan di hari [date]; `true` bila hari itu dilaporkan
  /// (masuk rincian).
  bool add(DateTime date, int amount) {
    final day = date.isBefore(start) ? start : DateTime(date.year, date.month, date.day);
    if (!day.isBefore(until)) return false;
    changes[day] = (changes[day] ?? 0) + amount;
    return !day.isBefore(reported);
  }

  for (final rule in rules) {
    final effect = _effectOn(rule, walletId);
    if (effect == 0) continue;
    for (final o in occurrenceStatusesOf(
      rule,
      from: pendingFrom.isBefore(start) ? pendingFrom : start,
      until: until,
      today: start,
      transactions: transactions,
    )) {
      // Menunggu dan terlewat dianggap sudah terjadi hari ini; yang akan
      // datang di tanggalnya. Tercatat sudah ada di saldo nyata.
      final happens = switch (o.status) {
        OccurrenceStatus.pending || OccurrenceStatus.missed || OccurrenceStatus.upcoming => true,
        OccurrenceStatus.recorded || OccurrenceStatus.skipped || OccurrenceStatus.paused => false,
      };
      if (!happens || !o.date.isBefore(until)) continue;
      if (rule.kind == RecurringKind.expense && rule.budgetItemKey != null) {
        (linked[rule.budgetItemKey!] ??= []).add((o.date, rule.amount));
      }
      if (!add(o.date, effect * rule.amount)) continue;
      switch (rule.kind) {
        case RecurringKind.income:
          income += rule.amount;
        case RecurringKind.expense:
          recurringOut += rule.amount;
        case RecurringKind.transfer:
          transfers += effect * rule.amount;
      }
    }
  }

  for (final line in budgets) {
    if (walletId != null && line.walletId != walletId) continue;
    // keluar_pos = max(sisa_pos, tertaut belum tercatat): yang tertaut sudah
    // ada di tanggalnya, porsi harian hanya selisihnya (invarian 17/21).
    final fromRules = [
      for (final (date, amount) in linked[line.key] ?? const <(DateTime, int)>[])
        if (date.isBefore(line.periodEnd)) amount,
    ].fold(0, (sum, amount) => sum + amount);
    _spread(
      line.remaining > fromRules ? line.remaining - fromRules : 0,
      from: start,
      until: line.periodEnd,
      add: (day, amount) {
        if (add(day, -amount)) budget += amount;
      },
    );
  }

  var uncertain = 0;
  for (final income in uncertainIncome) {
    if (walletId != null && income.walletId != walletId) continue;
    final day = income.date.isBefore(start) ? start : income.date;
    if (add(day, income.amount)) uncertain += income.amount;
  }

  final days = <ProjectedDay>[];
  var balance = startBalance;
  var reportedStart = startBalance;
  for (var day = start; day.isBefore(until); day = DateTime(day.year, day.month, day.day + 1)) {
    if (day == reported) reportedStart = balance;
    balance += changes[day] ?? 0;
    if (unplannedPerDay != null) balance -= unplannedPerDay;
    if (!day.isBefore(reported)) days.add((date: day, balance: balance));
  }
  return CashflowProjection(
    startBalance: reportedStart,
    days: days,
    uncertain: uncertain,
    unplannedPerDay: unplannedPerDay,
    breakdown: (
      income: income,
      recurringOut: recurringOut,
      budget: budget,
      unplanned: (unplannedPerDay ?? 0) * days.length,
      uncertain: uncertain,
      transfers: transfers,
    ),
  );
}

/// Tanda pengaruh satu kemunculan [rule] terhadap [walletId] (`null` =
/// seluruh dompet): +1, −1, atau 0.
int _effectOn(RecurringRule rule, String? walletId) => switch (rule.kind) {
  RecurringKind.income => walletId == null || rule.walletId == walletId ? 1 : 0,
  RecurringKind.expense => walletId == null || rule.walletId == walletId ? -1 : 0,
  RecurringKind.transfer => switch (walletId) {
    null => 0,
    _ when rule.walletId == walletId => -1,
    _ when rule.toWalletId == walletId => 1,
    _ => 0,
  },
};

/// Membagi [amount] rata ke hari `from <= d < until`; sisa pembagian di hari
/// terakhir (§7.7: 100.000.001 sen ÷ 3 = 33.333.333, 33.333.333,
/// 33.333.335).
void _spread(int amount, {required DateTime from, required DateTime until, required void Function(DateTime, int) add}) {
  final days = DateTime.utc(
    until.year,
    until.month,
    until.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  if (amount <= 0 || days <= 0) return;
  final portion = amount ~/ days;
  for (var i = 0; i < days; i++) {
    final day = DateTime(from.year, from.month, from.day + i);
    add(day, i == days - 1 ? amount - portion * (days - 1) : portion);
  }
}

/// Porsi harian dari [amount] untuk [days] hari, sisa di hari terakhir —
/// untuk uji dan tampilan rincian.
List<int> dailyPortions(int amount, int days) {
  if (days <= 0) return const [];
  final portion = amount ~/ days;
  return [for (var i = 0; i < days; i++) i == days - 1 ? amount - portion * (days - 1) : portion];
}

/// Rata-rata harian pengeluaran "di luar rencana" (§7.5): pengeluaran yang
/// tidak tertaut pos dan tidak berasal dari rutin yang masih ada
/// ([ruleIds]; transaksi rutin terhapus ikut dihitung, T-15.18), di bulan-bulan penuh
/// [months] (paling banyak tiga, terbaru dulu) yang seluruhnya tercakup
/// riwayat ([historyStart] = tanggal transaksi pertama). `null` bila belum
/// ada satu bulan penuh (KT-R3), atau bila [walletId] diisi, hanya
/// pengeluaran dompet itu.
int? unplannedDailyAverage(
  Iterable<Transaction> transactions, {
  required List<({DateTime start, DateTime end})> months,
  required DateTime? historyStart,
  required Set<String> ruleIds,
  String? walletId,
}) {
  if (historyStart == null) return null;
  // Bulan penuh: riwayat sudah ada sejak awal bulan itu.
  final firstDay = DateTime(historyStart.year, historyStart.month, historyStart.day);
  final full = [
    for (final m in months.take(3))
      if (!m.start.isBefore(firstDay)) m,
  ];
  if (full.isEmpty) return null;
  var total = 0;
  var days = 0;
  for (final m in full) {
    days += DateTime.utc(
      m.end.year,
      m.end.month,
      m.end.day,
    ).difference(DateTime.utc(m.start.year, m.start.month, m.start.day)).inDays;
    for (final t in transactions) {
      if (t is! ExpenseTransaction || ruleIds.contains(t.recurrence?.ruleId) || t.budgetItemId != null) continue;
      if (walletId != null && t.walletId != walletId) continue;
      if (t.date.isBefore(m.start) || !t.date.isBefore(m.end)) continue;
      total += t.amount;
    }
  }
  return days == 0 ? null : total ~/ days;
}
