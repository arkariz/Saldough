import 'package:bloc_test/bloc_test.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:saldough/features/example_note/domain/entities/example_note.dart';
import 'package:saldough/features/example_note/domain/repositories/example_note_repository.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_bloc.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_state.dart';
import 'package:state_management/state_management.dart';

class MockExampleNoteRepository extends Mock implements ExampleNoteRepository {}

void main() {
  late MockExampleNoteRepository repository;

  setUp(() {
    repository = MockExampleNoteRepository();
  });

  group('ExampleNoteBloc', () {
    blocTest<ExampleNoteBloc, ExampleNoteState>(
      'ExampleNoteStarted memuat catatan yang sudah tersimpan',
      build: () {
        when(() => repository.listNotes()).thenAnswer(
          (_) async => right(const [ExampleNote(id: '1', text: 'halo')]),
        );
        return ExampleNoteBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ExampleNoteStarted()),
      expect: () => [
        isA<ExampleNoteState>().having((s) => s.isLoading, 'isLoading', true),
        isA<ExampleNoteState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.notes, 'notes', [const ExampleNote(id: '1', text: 'halo')]),
      ],
    );

    blocTest<ExampleNoteBloc, ExampleNoteState>(
      'ExampleNoteStarted gagal menampilkan efek galat dan tetap idle',
      build: () {
        when(() => repository.listNotes()).thenAnswer(
          (_) async => left(const SystemFailure(code: FailureCode.unknown, message: 'boom')),
        );
        return ExampleNoteBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ExampleNoteStarted()),
      expect: () => [
        isA<ExampleNoteState>().having((s) => s.isLoading, 'isLoading', true),
        isA<ExampleNoteState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
    );

    blocTest<ExampleNoteBloc, ExampleNoteState>(
      'ExampleNoteAdded menambah catatan baru dan menampilkan efek sukses',
      build: () {
        when(() => repository.addNote(any())).thenAnswer(
          (_) async => right(const ExampleNote(id: '2', text: 'baru')),
        );
        return ExampleNoteBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const ExampleNoteAdded('baru')),
      expect: () => [
        isA<ExampleNoteState>()
            .having((s) => s.notes, 'notes', [const ExampleNote(id: '2', text: 'baru')])
            .having((s) => s.effect, 'effect', isA<ShowSnackBarEffect>()),
      ],
    );
  });
}
