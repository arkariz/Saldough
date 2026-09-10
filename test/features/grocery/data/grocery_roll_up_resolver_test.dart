import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/grocery/data/grocery_roll_up_resolver.dart';
import 'package:saldough/features/grocery/data/repositories/grocery_plan_repository_impl.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';

void main() {
  late GroceryPlanRepositoryImpl repository;
  late GroceryRollUpResolver resolver;

  setUp(() {
    repository = GroceryPlanRepositoryImpl(storage: InMemoryKeyValueStorage());
    resolver = GroceryRollUpResolver(repository: repository);
  });

  group('GroceryRollUpResolver', () {
    test('menghitung roll-up sungguhan untuk GroceryRollUpSource dari plan tersimpan', () async {
      await repository.savePlan(const GroceryPlan(
        weeklyItems: [GroceryItem(id: 'w1', name: 'A', quantity: 1, unitPrice: 57660000)],
        monthlyItems: [GroceryItem(id: 'm1', name: 'B', quantity: 1, unitPrice: 76210000)],
      ));

      final resolution = await resolver.resolve(RollUpSource.grocery);

      expect(resolution.isAvailable, isTrue);
      expect(resolution.amount, 306850000);
    });

    test('rencana belum tersimpan menghasilkan roll-up nol tapi tetap tersedia', () async {
      final resolution = await resolver.resolve(RollUpSource.grocery);

      expect(resolution.isAvailable, isTrue);
      expect(resolution.amount, 0);
    });

    test('CardRollUpSource masih tidak tersedia (kartu belum dibangun)', () async {
      final resolution = await resolver.resolve(RollUpSource.card('card-1'));

      expect(resolution.isAvailable, isFalse);
      expect(resolution.amount, 0);
    });
  });
}
