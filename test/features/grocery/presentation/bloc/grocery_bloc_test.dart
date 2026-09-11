import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/card/presentation/navigation/card_route_keys.dart';
import 'package:saldough/features/grocery/domain/repositories/grocery_plan_repository.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_bloc.dart';
import 'package:saldough/features/grocery/presentation/bloc/grocery_state.dart';
import 'package:state_management/state_management.dart';

class MockGroceryPlanRepository extends Mock implements GroceryPlanRepository {}

void main() {
  late MockGroceryPlanRepository repository;

  setUp(() {
    repository = MockGroceryPlanRepository();
  });

  group('GroceryBloc', () {
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
