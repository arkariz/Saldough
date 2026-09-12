import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/cycle/data/adapters/grocery_cycle_gateway_impl.dart';
import 'package:saldough/features/cycle/domain/repositories/cycle_repository.dart';

class MockCycleRepository extends Mock implements CycleRepository {}

void main() {
  late MockCycleRepository repository;

  setUp(() {
    repository = MockCycleRepository();
  });

  group('GroceryCycleGatewayImpl', () {
    test('listCycleIds meneruskan hasil dari CycleRepository', () async {
      when(
        () => repository.listCycleIds(),
      ).thenAnswer((_) async => right(const ['2026-08', '2026-09']));
      final gateway = GroceryCycleGatewayImpl(cycleRepository: repository);

      final result = await gateway.listCycleIds();

      switch (result) {
        case Left():
          fail('seharusnya Right, dapat Left');
        case Right(value: final ids):
          expect(ids, ['2026-08', '2026-09']);
      }
    });

    test('listCycleIds meneruskan Failure dari CycleRepository', () async {
      const failure = BusinessRuleFailure(
        code: FailureCode('STORAGE_ERROR'),
        message: 'gagal baca index',
        userMessage: 'Gagal memuat daftar siklus.',
      );
      when(() => repository.listCycleIds()).thenAnswer((_) async => left(failure));
      final gateway = GroceryCycleGatewayImpl(cycleRepository: repository);

      final result = await gateway.listCycleIds();

      switch (result) {
        case Left(value: final f):
          expect(f, failure);
        case Right():
          fail('seharusnya Left, dapat Right');
      }
    });
  });
}
