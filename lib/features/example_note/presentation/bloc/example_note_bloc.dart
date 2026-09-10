import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/example_note/domain/repositories/example_note_repository.dart';
import 'package:saldough/features/example_note/presentation/bloc/example_note_state.dart';
import 'package:state_management/state_management.dart';

part 'example_note_event.dart';
part 'example_note_effect.dart';

/// Bloc contoh — lihat catatan di [ExampleNote]. Membuktikan pola
/// domain→data→presentation dari ujung ke ujung untuk T-1.12.
final class ExampleNoteBloc extends Bloc<ExampleNoteEvent, ExampleNoteState> {
  /// Membuat [ExampleNoteBloc] dengan [_repository].
  ExampleNoteBloc({required ExampleNoteRepository repository})
      : _repository = repository,
        super(ExampleNoteState.initial()) {
    on<ExampleNoteStarted>(_onStarted);
    on<ExampleNoteAdded>(_onAdded);
  }

  final ExampleNoteRepository _repository;

  Future<void> _onStarted(ExampleNoteStarted event, Emitter<ExampleNoteState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.listNotes();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final notes):
        emit(state.copyWith(notes: notes, isLoading: false));
    }
  }

  Future<void> _onAdded(ExampleNoteAdded event, Emitter<ExampleNoteState> emit) async {
    final result = await _repository.addNote(event.text);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right(value: final note):
        emit(state.copyWith(notes: [...state.notes, note], effect: _effectNoteAdded()));
    }
  }
}
