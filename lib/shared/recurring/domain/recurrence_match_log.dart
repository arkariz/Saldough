import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Satu tautan otomatis (ADR-035 §3.4, §7A): transaksi dari catat
/// notifikasi yang ditautkan ke kemunculan rutin tanpa ketukan. Disimpan
/// 7 hari supaya pengguna bisa melihat dan **Lepaskan**.
final class RecurrenceMatchEntry extends Equatable {
  /// Membuat [RecurrenceMatchEntry].
  const RecurrenceMatchEntry({
    required this.transactionId,
    required this.transactionDate,
    required this.ruleId,
    required this.ruleName,
    required this.occurrenceDate,
    required this.amount,
    required this.matchedAt,
  });

  /// Transaksi yang ditautkan.
  final String transactionId;

  /// Tanggal transaksinya (untuk membaca dokumen bulannya).
  final DateTime transactionDate;

  /// Rutinnya.
  final String ruleId;

  /// Nama rutin saat ditautkan.
  final String ruleName;

  /// Tanggal kemunculan.
  final DateTime occurrenceDate;

  /// Nominal transaksi, sen.
  final int amount;

  /// Kapan ditautkan.
  final DateTime matchedAt;

  @override
  List<Object?> get props => [transactionId, transactionDate, ruleId, ruleName, occurrenceDate, amount, matchedAt];
}

/// Log tautan otomatis, `recurring` / `match_log`.
abstract interface class RecurrenceMatchLogRepository {
  /// Entri yang belum lewat 7 hari dari [now], terbaru dulu.
  Future<Either<Failure, List<RecurrenceMatchEntry>>> list(DateTime now);

  /// Menambah [entry] di depan.
  Future<Either<Failure, Unit>> add(RecurrenceMatchEntry entry);

  /// Menghapus entri transaksi [transactionId].
  Future<Either<Failure, Unit>> remove(String transactionId);
}
