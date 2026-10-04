import 'package:dependencies/dependencies.dart';
import 'package:flutter/foundation.dart';
import 'package:saldough/core/utils/formatters/cycle_month_formatter.dart';

/// Rentang satu bulan keuangan: `start <= d < end` (KT-R2, ADR-035 §3.6).
final class FinancialMonthRange extends Equatable {
  /// Membuat [FinancialMonthRange].
  const FinancialMonthRange({required this.start, required this.end});

  /// Hari pertama.
  final DateTime start;

  /// Hari sesudah hari terakhir (eksklusif).
  final DateTime end;

  /// Hari terakhir (inklusif).
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  /// Jumlah hari.
  int get days =>
      DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  /// Apakah [date] termasuk rentang ini.
  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  /// Label: "Oktober 2026" bila mulai tanggal 1; selain itu rentangnya
  /// selalu ditulis, mis. "25 Okt – 24 Nov" (bulan keuangan bisa berbeda
  /// dari bulan kalender di Beranda).
  String get label => start.day == 1
      ? CycleMonthFormatter.format('${start.year}-${start.month.toString().padLeft(2, '0')}')
      : '${CycleMonthFormatter.formatDayMonth(start)} – ${CycleMonthFormatter.formatDayMonth(lastDay)}';

  @override
  List<Object?> get props => [start, end];
}

/// Tanggal awal bulan keuangan yang boleh dipilih: 1–28, supaya setiap bulan
/// punya tanggal itu.
const ({int min, int max}) financialMonthStartDays = (min: 1, max: 28);

/// Bulan keuangan yang memuat [date], bila bulan keuangan dimulai tanggal
/// [startDay] (1–28). Tanggal mulai 25: 3 Nov → 25 Okt – 24 Nov.
FinancialMonthRange financialMonthOf(DateTime date, int startDay) {
  assert(startDay >= financialMonthStartDays.min && startDay <= financialMonthStartDays.max, 'Awal bulan 1–28.');
  final start = date.day >= startDay
      ? DateTime(date.year, date.month, startDay)
      : DateTime(date.year, date.month - 1, startDay);
  return FinancialMonthRange(start: start, end: DateTime(start.year, start.month + 1, startDay));
}

/// Tanggal awal bulan keuangan aktif (1–28), dibaca tab Rencana. Diisi
/// `main.dart` dari `FinancialMonthPreferenceRepository` sebelum `runApp`,
/// pola `ActiveCurrency`. Beranda tetap memakai bulan kalender.
abstract final class ActiveFinancialMonth {
  ActiveFinancialMonth._();

  /// Pemegang nilai.
  static final ValueNotifier<int> notifier = ValueNotifier(1);

  /// Tanggal awal aktif.
  static int get startDay => notifier.value;
}
