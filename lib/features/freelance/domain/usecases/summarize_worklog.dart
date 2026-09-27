import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';

/// Ringkasan worklog: jam dan gaji KOTOR (jam × tarif), dengan
/// [paid] + [unpaid] = [earned]. Dipakai puncak Ikhtisar Freelance
/// (FR-FRL-005) dan ringkasan Beranda (FR-HOME-003).
final class FreelanceSummary {
  /// Membuat [FreelanceSummary].
  const FreelanceSummary({required this.totalHours, required this.earned, required this.paid});

  /// Total jam seluruh entri.
  final int totalHours;

  /// Total diperoleh (kotor), sen.
  final int earned;

  /// Bagian [earned] yang pembayarannya sudah dicatat diterima, sen.
  final int paid;

  /// Bagian [earned] yang belum diterima — belum ditagihkan maupun tertunda.
  int get unpaid => earned - paid;
}

/// Menghitung [FreelanceSummary] dari [entries] dan [payments]. Dart murni.
///
/// ⚠ Sebuah entri terhitung `paid` hanya kalau pembayarannya berstatus
/// diterima. Entri yang menunjuk pembayaran yang sudah terhapus dihitung
/// belum diterima — kerja selesai bukan uang diterima (aturan 6).
final class SummarizeWorklog {
  /// Membuat [SummarizeWorklog].
  const SummarizeWorklog();

  /// Ringkasan seluruh [entries].
  FreelanceSummary call(Iterable<WorklogEntry> entries, Iterable<FreelancePayment> payments) {
    final paidIds = {
      for (final payment in payments)
        if (payment.isPaid) payment.id,
    };
    var hours = 0;
    var earned = 0;
    var paid = 0;
    for (final entry in entries) {
      hours += entry.hours;
      earned += entry.earnedAmount;
      if (paidIds.contains(entry.paymentId)) paid += entry.earnedAmount;
    }
    return FreelanceSummary(totalHours: hours, earned: earned, paid: paid);
  }
}
