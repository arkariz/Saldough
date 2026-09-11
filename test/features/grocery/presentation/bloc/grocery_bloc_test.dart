import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/card/presentation/navigation/card_route_keys.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_state.dart';
import 'package:state_management/state_management.dart';

class MockGroceryPlanRepository extends Mock implements GroceryPlanRepository {}

void main() {
  late MockGroceryPlanRepository repository;

  setUpAll(() {
    registerFallbackValue(GroceryPlan.empty());
  });

  setUp(() {
    repository = MockGroceryPlanRepository();
  });

  group('GroceryBloc', () {
    // UX-04: pengali minggu sebelumnya hanya tersimpan lewat `onSubmitted`
    // (menekan enter) -- field debounce baru di `grocery_page.dart` komit
    // lewat event ini juga tanpa perlu enter. Tes ini memastikan SISI BLOC-
    // nya benar (event -> state baru dengan rollUpAmount yang ikut berubah);
    // pengikatan field/debounce itu sendiri diverifikasi manual (widget
    // test pertama proyek ini belum ditulis).
    blocTest<GroceryBloc, GroceryState>(
      'WeeksPerMonthChanged menyimpan pengali baru dan rollUpAmount ikut berubah',
      setUp: () {
        when(() => repository.savePlan(any())).thenAnswer((_) async => right(unit));
      },
      build: () => GroceryBloc(repository: repository),
      seed: () => const GroceryState(
        plan: GroceryPlan(
          weeklyItems: [
            GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000),
          ],
          monthlyItems: [],
        ),
        isLoading: false,
      ),
      act: (bloc) => bloc.add(const WeeksPerMonthChanged(5)),
      expect: () => [
        isA<GroceryState>()
            .having((s) => s.plan.weeksPerMonth, 'plan.weeksPerMonth', 5)
            // 4 minggu x Rp50.000 = Rp200.000 (seed) -> 5 minggu = Rp250.000.
            // Angka pembandingnya dihitung, bukan disalin dari kode -- kalau
            // rumus roll-up berubah nanti, tes ini akan gagal dengan benar.
            .having((s) => s.rollUpAmount, 'rollUpAmount', 5 * 5000000),
      ],
      verify: (_) {
        verify(() => repository.savePlan(any())).called(1);
      },
    );
  });

  group('GroceryBloc (navigasi)', () {
    blocTest<GroceryBloc, GroceryState>(
      'CardEntryPointTapped mendorong efek navigasi ke layar card',
      build: () => GroceryBloc(repository: repository),
      act: (bloc) => bloc.add(const CardEntryPointTapped()),
      expect: () => [
        isA<GroceryState>().having(
          (s) => s.effect,
          'effect',
          isA<NavigatePushEffect>().having((e) => e.keyId, 'keyId', CardRouteKeys.page.id),
        ),
      ],
    );
  });
}
