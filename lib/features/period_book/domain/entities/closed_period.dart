import 'package:dependencies/dependencies.dart';
import 'package:saldough/core/financial_month/financial_month.dart';

/// Id periode untuk ingatan dan rute buku: tanggal awal periode `YYYY-MM-DD`
/// (ADR-045 §3.5). Stabil selama jadwal periode lampau tidak dipotong ulang
/// (ADR-038: riwayat berlaku-sejak).
String periodBookIdOf(FinancialPeriod period) {
  final d = period.start;
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Satu periode keuangan yang sudah berakhir beserta jumlah transaksinya
/// (pemasukan, pengeluaran, dan transfer; keanggotaan lewat `periodDateOf`).
final class ClosedPeriod extends Equatable {
  /// Membuat [ClosedPeriod].
  const ClosedPeriod({required this.period, required this.transactionCount});

  /// Periodenya.
  final FinancialPeriod period;

  /// Jumlah transaksi di periode itu.
  final int transactionCount;

  /// Id buku periode ini.
  String get id => periodBookIdOf(period);

  @override
  List<Object?> get props => [period, transactionCount];
}
