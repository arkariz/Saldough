import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';

/// Satu transaksi tanpa kategori yang ditampilkan ringkas di langkah 1 ritual
/// (rupa D4). Hanya yang perlu untuk daftar ringkas dan membuka penyunting.
final class RitualUntagged extends Equatable {
  /// Membuat [RitualUntagged].
  const RitualUntagged({
    required this.transactionId,
    required this.date,
    required this.amount,
    required this.note,
    required this.isIncome,
  });

  /// Id transaksi.
  final String transactionId;

  /// Tanggal transaksi.
  final DateTime date;

  /// Nominal, sen.
  final int amount;

  /// Catatan transaksi (boleh kosong).
  final String note;

  /// Pemasukan (selain itu pengeluaran).
  final bool isIncome;

  @override
  List<Object?> get props => [transactionId, date, amount, note, isIncome];
}

/// Bahan tiga langkah ritual Tutup buku (BP-5, BP-6, rupa D4): transaksi tanpa
/// kategori, rutin yang masih menunggu, dan kilas balik rencana.
final class RitualInfo extends Equatable {
  /// Membuat [RitualInfo].
  const RitualInfo({
    required this.period,
    required this.untagged,
    required this.openRoutines,
    this.planned,
    this.spent,
  });

  /// Periodenya.
  final ClosedPeriod period;

  /// Semua transaksi tanpa kategori di periode ini (urut tanggal).
  final List<RitualUntagged> untagged;

  /// Kemunculan rutin yang belum beres (Menunggu atau Terlewat).
  final int openRoutines;

  /// Total rencana anggaran, sen; `null` bila tidak ada anggaran.
  final int? planned;

  /// Total terpakai, sen; `null` bila tidak ada anggaran.
  final int? spent;

  /// Langkah 3 punya kilas balik untuk ditampilkan.
  bool get hasReview => planned != null;

  @override
  List<Object?> get props => [period, untagged, openRoutines, planned, spent];
}

/// Tiga langkah ritual, urut (BP-6: semuanya boleh dilewati).
enum RitualStep {
  /// Transaksi tanpa kategori.
  uncategorized,

  /// Rutin yang masih menunggu.
  routines,

  /// Kilas balik rencana dan kenyataan.
  review,
}
