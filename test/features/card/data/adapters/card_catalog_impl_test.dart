import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/card/data/adapters/card_catalog_impl.dart';
import 'package:saldough/features/card/domain/entities/credit_card.dart';
import 'package:saldough/features/card/domain/repositories/credit_card_repository.dart';
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';

class MockCreditCardRepository extends Mock implements CreditCardRepository {}

void main() {
  late MockCreditCardRepository repository;
  late CardCatalogImpl catalog;

  setUp(() {
    repository = MockCreditCardRepository();
    catalog = CardCatalogImpl(repository: repository);
  });

  group('CardCatalogImpl', () {
    test(
      'listCards memetakan CreditCard ke CardSummary (id+nama saja)',
      () async {
        when(() => repository.listCards()).thenAnswer(
          (_) async => right(const [
            CreditCard(id: 'c1', name: 'CC TOKPED', statementDayOfMonth: 15),
            CreditCard(id: 'c2', name: 'CC BRI', statementDayOfMonth: 5),
          ]),
        );

        final result = await catalog.listCards();

        switch (result) {
          case Left():
            fail('Seharusnya Right, bukan Left');
          case Right(value: final cards):
            expect(cards, const [
              CardSummary(id: 'c1', name: 'CC TOKPED'),
              CardSummary(id: 'c2', name: 'CC BRI'),
            ]);
        }
      },
    );

    test('listCards meneruskan Failure dari CreditCardRepository', () async {
      const failure = PersistenceFailure(
        code: FailureCode('STORAGE_ERROR'),
        message: 'gagal baca',
        userMessage: 'Gagal memuat kartu.',
      );
      when(
        () => repository.listCards(),
      ).thenAnswer((_) async => left(failure));

      final result = await catalog.listCards();

      switch (result) {
        case Left(value: final actualFailure):
          expect(actualFailure, same(failure));
        case Right():
          fail('Seharusnya Left, bukan Right');
      }
    });
  });
}
