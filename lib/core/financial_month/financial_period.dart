import 'package:dependencies/dependencies.dart';
import 'package:flutter/foundation.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';

/// Satu periode keuangan: `start <= d < end` (ADR-038 §3.2). Hasil hitungan
/// [financialPeriodOf], tidak pernah disimpan.
final class FinancialPeriod extends Equatable {
  /// Membuat [FinancialPeriod].
  const FinancialPeriod({required this.start, required this.end, this.isTransition = false});

  /// Hari pertama.
  final DateTime start;

  /// Hari sesudah hari terakhir (eksklusif).
  final DateTime end;

  /// Periode peralihan (FINANCIAL_PERIOD P-3): periode berjalan saat awal
  /// bulan diubah, yang diregangkan atau dipendekkan ke batas baru.
  final bool isTransition;

  /// Hari terakhir (inklusif).
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  /// Jumlah hari.
  int get days => _daysBetween(start, end);

  /// Apakah [date] termasuk periode ini.
  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  /// Label: "Oktober 2026" bila mulai tanggal 1; selain itu rentangnya
  /// selalu ditulis, mis. "25 Okt – 24 Nov" (bulan keuangan bisa berbeda
  /// dari bulan kalender di Beranda).
  String get label => start.day == 1 && !isTransition
      ? CycleMonthFormatter.format('${start.year}-${start.month.toString().padLeft(2, '0')}')
      : '${CycleMonthFormatter.formatDayMonth(start)} – ${CycleMonthFormatter.formatDayMonth(lastDay)}';

  @override
  List<Object?> get props => [start, end, isTransition];
}

/// Tanggal mulai bulan keuangan (FINANCIAL_PERIOD P-1): tanggal 1–28 atau
/// [lastDay], hari terakhir tiap bulan.
final class FinancialMonthStart extends Equatable {
  /// Tanggal [day] (1–28) tiap bulan.
  const FinancialMonthStart.day(int this.day)
    : assert(day >= minDay && day <= maxDay, 'Awal bulan 1–28 atau hari terakhir.');

  const FinancialMonthStart._lastDay() : day = null;

  /// Hari terakhir tiap bulan (31 Okt, 30 Nov, 28/29 Feb).
  static const lastDay = FinancialMonthStart._lastDay();

  /// Bawaan: tanggal 1.
  static const first = FinancialMonthStart.day(1);

  /// Tanggal terkecil yang boleh dipilih.
  static const minDay = 1;

  /// Tanggal terbesar yang boleh dipilih, supaya setiap bulan memilikinya.
  static const maxDay = 28;

  /// Tanggalnya, atau `null` untuk [lastDay].
  final int? day;

  /// Apakah ini [lastDay].
  bool get isLastDay => day == null;

  /// Tanggal mulai di bulan [month] tahun [year]; [month] boleh di luar
  /// 1–12 (dinormalkan seperti `DateTime`).
  DateTime inMonth(int year, int month) => switch (day) {
    final day? => DateTime(year, month, day),
    null => DateTime(year, month + 1, 0),
  };

  /// Batas terakhir yang `<= date`.
  DateTime floor(DateTime date) {
    final candidate = inMonth(date.year, date.month);
    return candidate.isAfter(date) ? inMonth(date.year, date.month - 1) : candidate;
  }

  /// Batas pertama yang `> date`.
  DateTime after(DateTime date) {
    final floored = floor(date);
    return inMonth(floored.year, floored.month + 1);
  }

  /// Nilai simpanan: angka tanggal, atau `"lastDay"`.
  Object toJson() => day ?? 'lastDay';

  /// Kebalikan [toJson]; `null` bila tidak sah.
  static FinancialMonthStart? fromJson(Object? json) => switch (json) {
    'lastDay' => lastDay,
    final int day when day >= minDay && day <= maxDay => FinancialMonthStart.day(day),
    _ => null,
  };

  @override
  List<Object?> get props => [day];
}

/// Satu entri riwayat: [start] berlaku sejak [effectiveFrom] (ADR-038 §3.1).
/// Untuk entri sesudah yang pertama, [effectiveFrom] adalah **awal periode
/// peralihan** — awal periode berjalan saat tanggal mulai diubah.
typedef FinancialMonthScheduleEntry = ({DateTime effectiveFrom, FinancialMonthStart start});

/// Riwayat tanggal mulai bulan keuangan (ADR-038 §3.1, FINANCIAL_PERIOD
/// P-2): daftar terurut. Entri pertama berlaku sejak awal; periode yang sudah
/// selesai tidak pernah berubah karena entri baru selalu berlaku sejak awal
/// periode berjalan.
final class FinancialMonthSchedule extends Equatable {
  /// Membuat [FinancialMonthSchedule]; [entries] tidak kosong dan urut naik
  /// menurut `effectiveFrom`.
  FinancialMonthSchedule(List<FinancialMonthScheduleEntry> entries)
    : assert(entries.isNotEmpty, 'Jadwal minimal satu entri.'),
      entries = List.unmodifiable(entries);

  /// Satu tanggal mulai sejak awal, mis. preferensi lama yang dimigrasi.
  FinancialMonthSchedule.single(FinancialMonthStart start) : this([(effectiveFrom: origin, start: start)]);

  /// Bawaan: tanggal 1 sejak awal.
  static final initial = FinancialMonthSchedule.single(FinancialMonthStart.first);

  /// `effectiveFrom` entri pertama: "sejak awal".
  static final origin = DateTime(1);

  /// Entri, urut naik.
  final List<FinancialMonthScheduleEntry> entries;

  /// Tanggal mulai terakhir yang dipilih pengguna.
  FinancialMonthStart get active => entries.last.start;

  /// Periode yang memuat [date].
  FinancialPeriod periodOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    var i = 0;
    while (i + 1 < entries.length && !entries[i + 1].effectiveFrom.isAfter(day)) {
      i++;
    }
    final start = entries[i].start;
    var period = FinancialPeriod(start: start.floor(day), end: start.after(day));
    if (i > 0) {
      final a = entries[i].effectiveFrom;
      final b = entries[i - 1].start.after(a);
      final c = _transitionEnd(a, b, start);
      if (day.isBefore(c)) period = FinancialPeriod(start: a, end: c, isTransition: c != b);
    }
    if (i + 1 < entries.length && period.end.isAfter(entries[i + 1].effectiveFrom)) {
      period = FinancialPeriod(start: period.start, end: entries[i + 1].effectiveFrom, isTransition: true);
    }
    return period;
  }

  /// Periode tepat sebelum [period].
  FinancialPeriod previousOf(FinancialPeriod period) =>
      periodOf(DateTime(period.start.year, period.start.month, period.start.day - 1));

  /// Periode tepat sesudah [period].
  FinancialPeriod nextOf(FinancialPeriod period) => periodOf(period.end);

  /// Jadwal sesudah tanggal mulai diubah ke [start] pada hari [today]
  /// (FINANCIAL_PERIOD P-3). Entri baru berlaku sejak awal periode
  /// berjalan; periode berjalan menjadi periode peralihan sampai batas baru
  /// yang paling dekat ke akhir lamanya. Mengubah lagi di periode yang sama
  /// mengganti entri itu, dan kembali ke tanggal sebelumnya menghapusnya.
  FinancialMonthSchedule changedOn(DateTime today, FinancialMonthStart start) {
    if (start == active) return this;
    final a = periodOf(today).start;
    final kept = [
      for (final (i, entry) in entries.indexed)
        if (i == 0 || entry.effectiveFrom.isBefore(a)) entry,
    ];
    if (kept.last.start == start) return FinancialMonthSchedule(kept);
    return FinancialMonthSchedule([...kept, (effectiveFrom: a, start: start)]);
  }

  @override
  List<Object?> get props => [entries];
}

/// Periode keuangan yang memuat [date] menurut [schedule] (ADR-038 §3.2).
/// Satu-satunya cara menghitung periode; jangan `DateTime(y, m, startDay)`.
FinancialPeriod financialPeriodOf(DateTime date, FinancialMonthSchedule schedule) => schedule.periodOf(date);

/// Batas baru `c > a` bertanggal mulai [start] yang paling dekat ke [b];
/// bila seri, yang lebih akhir (P-3).
DateTime _transitionEnd(DateTime a, DateTime b, FinancialMonthStart start) {
  final before = start.floor(b);
  final later = start.after(before);
  if (!before.isAfter(a)) return later;
  return _daysBetween(before, b) < _daysBetween(b, later) ? before : later;
}

int _daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Jadwal bulan keuangan aktif, dibaca Rencana dan Anggaran. Diisi
/// `main.dart` dari `FinancialMonthPreferenceRepository` sebelum `runApp`,
/// pola `ActiveCurrency` (ADR-038 §7: menyiarkan jadwal, bukan angka).
abstract final class ActiveFinancialMonth {
  ActiveFinancialMonth._();

  /// Pemegang nilai.
  static final ValueNotifier<FinancialMonthSchedule> notifier = ValueNotifier(FinancialMonthSchedule.initial);

  /// Jadwal aktif.
  static FinancialMonthSchedule get schedule => notifier.value;

  /// Periode yang memuat [date] menurut jadwal aktif.
  static FinancialPeriod periodOf(DateTime date) => schedule.periodOf(date);
}
