import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_item.dart';
import 'package:saldough/features/grocery/domain/entities/grocery_plan.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_cycle_gateway.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_state.dart';

class MockGroceryPlanRepository extends Mock implements GroceryPlanRepository {}

class MockGroceryCycleGateway extends Mock implements GroceryCycleGateway {}

void main() {
  late MockGroceryPlanRepository repository;
  late MockGroceryCycleGateway cycleGateway;

  setUpAll(() {
    registerFallbackValue(GroceryPlan.empty('2026-09'));
  });

  setUp(() {
    repository = MockGroceryPlanRepository();
    cycleGateway = MockGroceryCycleGateway();
    when(() => cycleGateway.listCycleIds()).thenAnswer((_) async => right(const []));
  });

  GroceryBloc buildBloc() => GroceryBloc(repository: repository, cycleGateway: cycleGateway);

  group('GroceryBloc', () {
    blocTest<GroceryBloc, GroceryState>(
      'GroceryPlanLoaded memuat daftar id siklus dan plan bulan bawaan',
      setUp: () {
        when(() => cycleGateway.listCycleIds())
            .thenAnswer((_) async => right(const ['2026-08', '2026-09']));
        when(() => repository.getPlan(any()))
            .thenAnswer((invocation) async => right(GroceryPlan.empty(invocation.positionalArguments.first as String)));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const GroceryPlanLoaded()),
      expect: () => [
        isA<GroceryState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<GroceryState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.cycleIds, 'cycleIds', ['2026-08', '2026-09']),
      ],
    );

    blocTest<GroceryBloc, GroceryState>(
      'GroceryCycleSelected berpindah memuat plan bulan lain',
      setUp: () {
        when(() => repository.getPlan('2026-08')).thenAnswer(
          (_) async => right(const GroceryPlan(
            id: '2026-08',
            weeklyItems: [GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000)],
            monthlyItems: [],
          )),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const GroceryCycleSelected('2026-08')),
      expect: () => [
        isA<GroceryState>().having((s) => s.cycleId, 'cycleId', '2026-08'),
        isA<GroceryState>()
            .having((s) => s.cycleId, 'cycleId', '2026-08')
            .having((s) => s.plan.weeklyItems, 'plan.weeklyItems', hasLength(1)),
      ],
    );

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
      build: buildBloc,
      seed: () => const GroceryState(
        plan: GroceryPlan(
          id: '2026-09',
          weeklyItems: [
            GroceryItem(id: 'w1', name: 'Beras', quantity: 1, unitPrice: 5000000),
          ],
          monthlyItems: [],
        ),
        cycleId: '2026-09',
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
}
