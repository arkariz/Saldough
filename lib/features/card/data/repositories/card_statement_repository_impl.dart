import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/foundation/repository_guard.dart';
import 'package:saldough/features/card/data/models/card_statement_model.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/card_statement_period.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';

StorageKey _statementsKey(String cardId) => StorageKey(namespace: 'card_statement', name: cardId);

/// Implementasi [CardStatementRepository] di atas [KeyValueStorage]: seluruh
/// siklus tagihan satu kartu tersimpan sebagai satu dokumen JSON, mengikuti
/// pola `WorklogRepositoryImpl` (ADR-0009).
final class CardStatementRepositoryImpl with RepositoryGuard implements CardStatementRepository {
  /// Membuat [CardStatementRepositoryImpl] di atas [_storage].
  const CardStatementRepositoryImpl({required this._storage});

  final KeyValueStorage _storage;

  StoredValue<List<CardStatementModel>> _store(String cardId) => StoredValue<List<CardStatementModel>>.json(
        key: _statementsKey(cardId),
        fromJson: (json) => (json['items'] as List<dynamic>)
            .map((e) => CardStatementModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        toJson: (models) => {
          'schemaVersion': CardStatementModel.schemaVersion,
          'items': models.map((m) => m.toJson()).toList(),
        },
        storage: _storage,
      );

  @override
  Future<Either<Failure, List<CardStatement>>> listStatements(String cardId) => guard(() async {
        final models = await _store(cardId).read();
        return (models ?? const []).map((m) => m.toEntity()).toList();
      });

  @override
  Future<Either<Failure, CardStatement?>> getOpenStatement(String cardId) => guard(() async {
        final models = await _store(cardId).read() ?? const [];
        return models.map((m) => m.toEntity()).where((s) => !s.isClosed).firstOrNull;
      });

  @override
  Future<Either<Failure, CardStatement>> addTransaction({
    required String cardId,
    required int statementDayOfMonth,
    required CardTransaction transaction,
  }) =>
      guard(() async {
        final store = _store(cardId);
        final statements = (await store.read() ?? const []).map((m) => m.toEntity()).toList();
        final period = CardStatementPeriod.forDate(transaction.date, statementDayOfMonth);

        final existing =
            statements.where((s) => s.periodStart == period.start && s.periodEnd == period.end).firstOrNull;
        final target = (existing ?? CardStatement(
          id: '${cardId}_${period.start.toIso8601String()}',
          cardId: cardId,
          periodStart: period.start,
          periodEnd: period.end,
          transactions: const [],
        )).withTransaction(transaction);

        final next = [
          ...statements.where((s) => s.id != target.id),
          target,
        ].map(CardStatementModel.fromEntity).toList();
        await store.write(next);
        return target;
      });

  @override
  Future<Either<Failure, Unit>> saveStatement(CardStatement statement) => guardVoid(() async {
        final store = _store(statement.cardId);
        final statements = await store.read() ?? const [];
        final next = [
          ...statements.where((m) => m.id != statement.id),
          CardStatementModel.fromEntity(statement),
        ];
        await store.write(next);
      });
}
