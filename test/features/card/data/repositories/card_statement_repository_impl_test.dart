import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/card/data/repositories/card_statement_repository_impl.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late CardStatementRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = CardStatementRepositoryImpl(storage: storage);
  });

  group('CardStatementRepositoryImpl', () {
    test('transaksi dalam periode yang sama bergabung ke satu siklus tagihan', () async {
      final first = CardTransaction(id: 't1', date: DateTime(2026, 8, 20), merchant: 'A', amount: 10000);
      final second = CardTransaction(id: 't2', date: DateTime(2026, 9, 10), merchant: 'B', amount: 20000);

      await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: first);
      final result = await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: second);

      final statement = result.getOrElse((_) => throw StateError('expected Right'));
      expect(statement.transactions, hasLength(2));
      expect(statement.periodStart, DateTime(2026, 8, 16));
      expect(statement.periodEnd, DateTime(2026, 9, 15));
    });

    test('transaksi di periode berbeda membuat siklus tagihan terpisah (FR-CARD-002)', () async {
      final inCurrentPeriod = CardTransaction(id: 't1', date: DateTime(2026, 9, 10), merchant: 'A', amount: 10000);
      final inNextPeriod = CardTransaction(id: 't2', date: DateTime(2026, 9, 20), merchant: 'B', amount: 20000);

      await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: inCurrentPeriod);
      await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: inNextPeriod);

      final statements = (await repository.listStatements('cc1')).getOrElse((_) => []);
      expect(statements, hasLength(2));
    });

    test('getOpenStatement mengembalikan siklus yang belum ditutup', () async {
      final transaction = CardTransaction(id: 't1', date: DateTime(2026, 9, 10), merchant: 'A', amount: 10000);
      await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: transaction);

      final openResult = await repository.getOpenStatement('cc1');
      final open = openResult.getOrElse((_) => throw StateError('expected Right'));
      expect(open, isNotNull);
      expect(open!.isClosed, isFalse);
    });

    test('getOpenStatement mengembalikan null kalau siklus terakhir sudah ditutup', () async {
      final transaction = CardTransaction(id: 't1', date: DateTime(2026, 9, 10), merchant: 'A', amount: 10000);
      final added =
          await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: transaction);
      final statement = added.getOrElse((_) => throw StateError('expected Right'));
      await repository.saveStatement(statement.close());

      final openResult = await repository.getOpenStatement('cc1');
      expect(openResult.getOrElse((_) => throw StateError('expected Right')), isNull);
    });

    test('kartu berbeda tidak saling bercampur', () async {
      final a = CardTransaction(id: 'a1', date: DateTime(2026, 9, 10), merchant: 'A', amount: 10000);
      final b = CardTransaction(id: 'b1', date: DateTime(2026, 9, 10), merchant: 'B', amount: 20000);
      await repository.addTransaction(cardId: 'cc1', statementDayOfMonth: 15, transaction: a);
      await repository.addTransaction(cardId: 'cc2', statementDayOfMonth: 15, transaction: b);

      final statementsA = (await repository.listStatements('cc1')).getOrElse((_) => []);
      expect(statementsA, hasLength(1));
      expect(statementsA.single.transactions.single.merchant, 'A');
    });
  });
}
