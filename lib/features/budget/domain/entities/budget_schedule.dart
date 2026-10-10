import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';

/// Jadwal anggaran rutin (ADR-036 §3.1): template yang punya jadwal
/// melahirkan anggaran tiap periode, dengan dompet dan panjang periode ini.
///
/// Periode ke-n dimulai `anchorDate + n` minggu atau bulan. Anggaran bulanan
/// berpatokan tanggal 1–28, atau hari terakhir bulan ([onLastDay], ADR-038
/// §3.3), supaya setiap bulan punya tanggal mulai; akhir tiap periode adalah
/// awal periode berikutnya ([endOf]), tanpa celah atau tumpang tindih.
/// Pembuatnya wajib memeriksa [canRepeat] lebih dulu.
final class BudgetSchedule extends Equatable {
  /// Membuat [BudgetSchedule].
  const BudgetSchedule({
    required this.walletId,
    required this.period,
    required this.anchorDate,
    this.isActive = true,
    this.onLastDay = false,
  });

  /// Jadwal anggaran rutin yang periode pertamanya dimulai [startDate]:
  /// bulanan yang mulai di hari terakhir bulan (di atas tanggal 28)
  /// berpatokan [onLastDay].
  factory BudgetSchedule.startingAt({
    required String walletId,
    required BudgetPeriod period,
    required DateTime startDate,
  }) => BudgetSchedule(
    walletId: walletId,
    period: period,
    anchorDate: startDate,
    onLastDay: period == BudgetPeriod.monthly && startDate.day > maxMonthlyAnchorDay && _isLastDayOfMonth(startDate),
  );

  /// Tanggal patokan terakhir yang boleh untuk anggaran rutin bulanan.
  static const maxMonthlyAnchorDay = 28;

  /// Apakah anggaran yang mulai pada [startDate] dengan [period] bisa
  /// dijadikan rutin: mingguan selalu; bulanan bila mulai tanggal 1–28 atau
  /// hari terakhir bulan.
  static bool canRepeat(BudgetPeriod period, DateTime startDate) =>
      period != BudgetPeriod.monthly || startDate.day <= maxMonthlyAnchorDay || _isLastDayOfMonth(startDate);

  static bool _isLastDayOfMonth(DateTime date) => DateTime(date.year, date.month, date.day + 1).day == 1;

  /// Dompet anggaran yang lahir.
  final String walletId;

  /// Panjang periode.
  final BudgetPeriod period;

  /// Awal periode pertama; hanya tanggalnya yang dipakai.
  final DateTime anchorDate;

  /// Mati: tidak ada periode baru yang lahir; yang sudah lahir tetap ada.
  final bool isActive;

  /// Bulanan berpatokan hari terakhir tiap bulan (31 Okt, 30 Nov, 28 Feb).
  final bool onLastDay;

  DateTime get _anchor => DateTime(anchorDate.year, anchorDate.month, anchorDate.day);

  /// Awal periode ke-[n] (0 = [anchorDate]).
  DateTime startOf(int n) => switch (period) {
    BudgetPeriod.weekly => DateTime(_anchor.year, _anchor.month, _anchor.day + 7 * n),
    BudgetPeriod.monthly when onLastDay => DateTime(_anchor.year, _anchor.month + n + 1, 0),
    BudgetPeriod.monthly => DateTime(_anchor.year, _anchor.month + n, _anchor.day),
  };

  /// Akhir (eksklusif) periode yang dimulai [start]: awal periode
  /// berikutnya.
  DateTime endOf(DateTime start) => startOf((indexAt(start) ?? 0) + 1);

  /// Indeks periode yang mencakup [date], atau `null` bila [date] sebelum
  /// [anchorDate].
  int? indexAt(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(_anchor)) return null;
    var n = switch (period) {
      BudgetPeriod.weekly =>
        DateTime.utc(
              day.year,
              day.month,
              day.day,
            ).difference(DateTime.utc(_anchor.year, _anchor.month, _anchor.day)).inDays ~/
            7,
      BudgetPeriod.monthly => (day.year - _anchor.year) * 12 + day.month - _anchor.month,
    };
    if (startOf(n).isAfter(day)) n--;
    return n;
  }

  /// Awal periode yang mencakup [date], atau `null` bila sebelum
  /// [anchorDate].
  DateTime? startAt(DateTime date) {
    final n = indexAt(date);
    return n == null ? null : startOf(n);
  }

  /// Awal periode yang beririsan dengan `from <= d < until`, urut naik.
  List<DateTime> startsBetween(DateTime from, DateTime until) {
    final first = indexAt(from) ?? 0;
    return [
      for (var n = first; startOf(n).isBefore(until); n++)
        if (endOf(startOf(n)).isAfter(from)) startOf(n),
    ];
  }

  /// Salinan dengan field yang disebutkan diganti.
  BudgetSchedule copyWith({
    String? walletId,
    BudgetPeriod? period,
    DateTime? anchorDate,
    bool? isActive,
    bool? onLastDay,
  }) => BudgetSchedule(
    walletId: walletId ?? this.walletId,
    period: period ?? this.period,
    anchorDate: anchorDate ?? this.anchorDate,
    isActive: isActive ?? this.isActive,
    onLastDay: onLastDay ?? this.onLastDay,
  );

  @override
  List<Object?> get props => [walletId, period, _anchor, isActive, onLastDay];
}
