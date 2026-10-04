import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';

/// Jadwal anggaran rutin (ADR-036 §3.1): template yang punya jadwal
/// melahirkan anggaran tiap periode, dengan dompet dan panjang periode ini.
///
/// Periode ke-n dimulai `anchorDate + n` minggu atau bulan. Anggaran bulanan
/// hanya boleh berpatokan tanggal 1–28, supaya setiap bulan punya tanggal
/// mulai dan akhir periode (`BudgetPeriod.endFrom`) tepat jatuh di awal
/// periode berikutnya, tanpa celah atau tumpang tindih. Pembuatnya wajib
/// memeriksa [canRepeat] lebih dulu.
final class BudgetSchedule extends Equatable {
  /// Membuat [BudgetSchedule].
  const BudgetSchedule({
    required this.walletId,
    required this.period,
    required this.anchorDate,
    this.isActive = true,
  });

  /// Tanggal patokan terakhir yang boleh untuk anggaran rutin bulanan.
  static const maxMonthlyAnchorDay = 28;

  /// Apakah anggaran yang mulai pada [startDate] dengan [period] bisa
  /// dijadikan rutin.
  static bool canRepeat(BudgetPeriod period, DateTime startDate) =>
      period != BudgetPeriod.monthly || startDate.day <= maxMonthlyAnchorDay;

  /// Dompet anggaran yang lahir.
  final String walletId;

  /// Panjang periode.
  final BudgetPeriod period;

  /// Awal periode pertama; hanya tanggalnya yang dipakai.
  final DateTime anchorDate;

  /// Mati: tidak ada periode baru yang lahir; yang sudah lahir tetap ada.
  final bool isActive;

  DateTime get _anchor => DateTime(anchorDate.year, anchorDate.month, anchorDate.day);

  /// Awal periode ke-[n] (0 = [anchorDate]).
  DateTime startOf(int n) => switch (period) {
    BudgetPeriod.weekly => DateTime(_anchor.year, _anchor.month, _anchor.day + 7 * n),
    BudgetPeriod.monthly => DateTime(_anchor.year, _anchor.month + n, _anchor.day),
  };

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
        if (period.endFrom(startOf(n)).isAfter(from)) startOf(n),
    ];
  }

  /// Salinan dengan field yang disebutkan diganti.
  BudgetSchedule copyWith({String? walletId, BudgetPeriod? period, DateTime? anchorDate, bool? isActive}) =>
      BudgetSchedule(
        walletId: walletId ?? this.walletId,
        period: period ?? this.period,
        anchorDate: anchorDate ?? this.anchorDate,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [walletId, period, _anchor, isActive];
}
