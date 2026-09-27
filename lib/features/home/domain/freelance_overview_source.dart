// Satu method disengaja — port kecil untuk satu kebutuhan baca lintas fitur
// (ADR-0009), sama seperti `BudgetItemCatalog` milik `record`.
// ignore_for_file: one_member_abstracts

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Ringkasan freelance untuk Beranda (FR-HOME-003). Bentuk transport milik
/// `home` — fitur ini tidak mengimpor domain `freelance`.
///
/// Nominal jam dan uang sama dengan ringkasan di puncak Ikhtisar Freelance:
/// gaji KOTOR (jam × tarif), [paid] + [unpaid] = [earned].
final class FreelanceOverview extends Equatable {
  /// Membuat [FreelanceOverview].
  const FreelanceOverview({
    required this.totalHours,
    required this.earned,
    required this.paid,
    required this.pendingCount,
    required this.nextExpectedDate,
  });

  /// Total jam seluruh entri worklog.
  final int totalHours;

  /// Total diperoleh (kotor), sen.
  final int earned;

  /// Bagian [earned] yang pembayarannya sudah dicatat diterima, sen.
  final int paid;

  /// Bagian [earned] yang belum diterima — belum ditagih maupun tertunda.
  int get unpaid => earned - paid;

  /// Jumlah pembayaran tertunda. Selalu ≥ 1; tanpa pembayaran tertunda,
  /// ringkasan ini tidak ada sama sekali.
  final int pendingCount;

  /// Tanggal perkiraan terdekat di antara pembayaran tertunda.
  final DateTime nextExpectedDate;

  @override
  List<Object?> get props => [totalHours, earned, paid, pendingCount, nextExpectedDate];
}

/// Port milik `home`: ringkasan freelance. Diimplementasikan fitur
/// `freelance` dan dikawat di `RootModule`.
abstract interface class FreelanceOverviewSource {
  /// Ringkasan freelance, atau `null` kalau tidak ada pembayaran tertunda —
  /// Beranda lalu menyembunyikan ringkasannya sepenuhnya (FR-HOME-003).
  Future<Either<Failure, FreelanceOverview?>> freelanceOverview();
}
