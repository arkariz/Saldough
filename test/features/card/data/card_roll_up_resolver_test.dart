import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/card/data/card_roll_up_resolver.dart';
import 'package:saldough/features/card/domain/entities/card_statement.dart';
import 'package:saldough/features/card/domain/entities/card_transaction.dart';
import 'package:saldough/features/card/domain/repositories/card_statement_repository.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';

class MockCardStatementRepository extends Mock implements CardStatementRepository {}

void main() {
  late MockCardStatementRepository repository;
  late CardRollUpResolver resolver;

  setUp(() {
    repository = MockCardStatementRepository();
    resolver = CardRollUpResolver(repository: repository);
  });

  group('CardRollUpResolver', () {
    test('mengembalikan unavailable untuk sumber selain kartu (mis. grocery)', () async {
      final result = await resolver.resolve(RollUpSource.grocery);

      expect(result.isAvailable, isFalse);
      expect(result.amount, 0);
    });

    test('mengembalikan confirmedTotal siklus tagihan terbuka kartu (FR-CARD-005)', () async {
      when(() => repository.getOpenStatement('cc1')).thenAnswer(
        (_) async => right(
          CardStatement(
            id: 's1',
            cardId: 'cc1',
            periodStart: DateTime(2026, 8, 16),
            periodEnd: DateTime(2026, 9, 15),
            transactions: [
              CardTransaction(id: 't1', date: DateTime(2026, 8, 20), merchant: 'A', amount: 100000),
              CardTransaction(id: 't2', date: DateTime(2026, 8, 21), merchant: 'B', amount: 50000, isConfirmed: false),
            ],
          ),
        ),
      );

      final result = await resolver.resolve(RollUpSource.card('cc1'));

      expect(result.isAvailable, isTrue);
      expect(result.amount, 100000);
    });

    test('mengembalikan unavailable kalau kartu belum punya siklus tagihan terbuka', () async {
      when(() => repository.getOpenStatement('cc1')).thenAnswer((_) async => right(null));

      final result = await resolver.resolve(RollUpSource.card('cc1'));

      expect(result.isAvailable, isFalse);
      expect(result.amount, 0);
    });

    test('mengembalikan unavailable kalau repository gagal', () async {
      when(() => repository.getOpenStatement('cc1'))
          .thenAnswer((_) async => left(const SystemFailure(code: FailureCode.unknown, message: 'boom')));

      final result = await resolver.resolve(RollUpSource.card('cc1'));

      expect(result.isAvailable, isFalse);
    });
  });
}
