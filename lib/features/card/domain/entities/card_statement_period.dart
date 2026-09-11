import 'package:dependencies/dependencies.dart';

/// Rentang satu siklus tagihan kartu, ditentukan murni dari
/// `CreditCard.statementDayOfMonth` — bukan bulan kalender (T-4.7).
final class CardStatementPeriod extends Equatable {
  /// Membuat [CardStatementPeriod].
  const CardStatementPeriod({required this.start, required this.end});

  /// Menghitung periode yang mencakup [date], untuk kartu ber-tanggal cetak
  /// [statementDayOfMonth].
  ///
  /// Periode berjalan dari sehari setelah tanggal cetak bulan sebelumnya
  /// sampai tanggal cetak bulan ini (inklusif) — misalnya tanggal cetak 15:
  /// periode 16 Agustus s.d. 15 September.
  factory CardStatementPeriod.forDate(DateTime date, int statementDayOfMonth) {
    final normalized = DateTime(date.year, date.month, date.day);
    final endThisMonth = DateTime(normalized.year, normalized.month, statementDayOfMonth);
    final end = normalized.isAfter(endThisMonth)
        ? DateTime(normalized.year, normalized.month + 1, statementDayOfMonth)
        : endThisMonth;
    final start = DateTime(end.year, end.month - 1, statementDayOfMonth + 1);
    return CardStatementPeriod(start: start, end: end);
  }

  /// Periode setelah `this` — dipakai saat membuka siklus tagihan berikutnya
  /// (FR-CARD-003).
  CardStatementPeriod next(int statementDayOfMonth) =>
      CardStatementPeriod.forDate(end.add(const Duration(days: 1)), statementDayOfMonth);

  /// Tanggal mulai (inklusif).
  final DateTime start;

  /// Tanggal cetak, akhir periode (inklusif).
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}
