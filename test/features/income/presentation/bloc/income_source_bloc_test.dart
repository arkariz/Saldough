import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_bloc.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_state.dart';
import 'package:saldough/features/worklog/presentation/navigation/worklog_route_keys.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

class MockIncomeSourceRepository extends Mock implements IncomeSourceRepository {}

void main() {
  late MockIncomeSourceRepository repository;

  setUpAll(() {
    registerFallbackValue(
      IncomeSource(id: 'x', name: 'x', kind: IncomeSourceKind.adHoc),
    );
  });

  setUp(() {
    repository = MockIncomeSourceRepository();
  });

  final source = IncomeSource(id: 's1', name: 'Gaji Koko', kind: IncomeSourceKind.fixedSalary, fixedAmount: 1280000000);

  group('IncomeSourceBloc', () {
    blocTest<IncomeSourceBloc, IncomeSourceState>(
      'IncomeSourcesLoaded memuat daftar sumber',
      build: () {
        when(() => repository.listSources()).thenAnswer((_) async => right([source]));
        return IncomeSourceBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const IncomeSourcesLoaded()),
      expect: () => [
        isA<IncomeSourceState>().having((s) => s.isLoading, 'isLoading', true),
        isA<IncomeSourceState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.sources, 'sources', [source]),
      ],
    );

    blocTest<IncomeSourceBloc, IncomeSourceState>(
      'IncomeSourceSaved menyimpan lalu memuat ulang daftar',
      build: () {
        when(() => repository.saveSource(any())).thenAnswer((_) async => right(unit));
        when(() => repository.listSources()).thenAnswer((_) async => right([source]));
        return IncomeSourceBloc(repository: repository);
      },
      act: (bloc) => bloc.add(IncomeSourceSaved(source)),
      expect: () => [
        isA<IncomeSourceState>().having((s) => s.isLoading, 'isLoading', true),
        isA<IncomeSourceState>().having((s) => s.sources, 'sources', [source]),
      ],
      verify: (_) => verify(() => repository.saveSource(source)).called(1),
    );

    blocTest<IncomeSourceBloc, IncomeSourceState>(
      'IncomeSourceDeleted menampilkan efek galat kalau gagal',
      build: () {
        when(() => repository.deleteSource('s1')).thenAnswer(
          (_) async => left(const BusinessRuleFailure(
            code: FailureCode('X'),
            message: 'gagal',
          )),
        );
        return IncomeSourceBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const IncomeSourceDeleted('s1')),
      expect: () => [
        isA<IncomeSourceState>().having((s) => s.effect, 'effect', isNotNull),
      ],
    );

    blocTest<IncomeSourceBloc, IncomeSourceState>(
      'WorklogEntryPointTapped mendorong efek navigasi ke layar worklog',
      build: () => IncomeSourceBloc(repository: repository),
      act: (bloc) => bloc.add(const WorklogEntryPointTapped()),
      expect: () => [
        isA<IncomeSourceState>().having(
          (s) => s.effect,
          'effect',
          isA<NavigatePushEffect>().having((e) => e.keyId, 'keyId', WorklogRouteKeys.page.id),
        ),
      ],
    );
  });
}
