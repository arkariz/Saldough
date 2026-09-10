import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';

/// Kontrak akses data siklus tagihan kartu. Lihat ADR-0005 — selalu
/// `Either<Failure, T>`, tidak pernah `throw Failure`.
abstract interface class CardStatementRepository {
  /// Seluruh siklus tagihan milik kartu ber-`id` [cardId], terurut dari yang
  /// terlama.
  Future<Either<Failure, List<CardStatement>>> listStatements(String cardId);

  /// Siklus tagihan kartu [cardId] yang sedang terbuka (belum ditutup), atau
  /// `Right(null)` kalau belum ada (kartu baru).
  Future<Either<Failure, CardStatement?>> getOpenStatement(String cardId);

  /// Mencatat [transaction] ke siklus tagihan kartu [cardId] yang mencakup
  /// tanggalnya — dihitung dari [statementDayOfMonth], membuat siklus baru
  /// kalau belum ada yang mencakupnya (FR-CARD-002: "otomatis"). Mengembalikan
  /// siklus yang menerima transaksi ini.
  Future<Either<Failure, CardStatement>> addTransaction({
    required String cardId,
    required int statementDayOfMonth,
    required CardTransaction transaction,
  });

  /// Menyimpan [statement] apa adanya — dipakai use case penutupan siklus
  /// yang sudah menyiapkan salinan `close()`-nya sendiri.
  Future<Either<Failure, Unit>> saveStatement(CardStatement statement);
}
