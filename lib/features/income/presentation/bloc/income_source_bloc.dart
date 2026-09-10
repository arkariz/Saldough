import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/income/presentation/bloc/income_source_state.dart';
import 'package:saldough/shared/income/income.dart';
import 'package:state_management/state_management.dart';

part 'income_source_effect.dart';
part 'income_source_event.dart';

/// Bloc layar pengelolaan sumber pemasukan (FR-INC-001 sampai FR-INC-003).
final class IncomeSourceBloc extends Bloc<IncomeSourceEvent, IncomeSourceState> {
  /// Membuat [IncomeSourceBloc].
  IncomeSourceBloc({required this._repository}) : super(IncomeSourceState.initial()) {
    on<IncomeSourcesLoaded>(_onLoaded);
    on<IncomeSourceSaved>(_onSaved);
    on<IncomeSourceDeleted>(_onDeleted);
  }

  final IncomeSourceRepository _repository;

  Future<void> _onLoaded(IncomeSourcesLoaded event, Emitter<IncomeSourceState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.listSources();
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _effectError(failure)));
      case Right(value: final sources):
        emit(state.copyWith(sources: sources, isLoading: false));
    }
  }

  Future<void> _onSaved(IncomeSourceSaved event, Emitter<IncomeSourceState> emit) async {
    final result = await _repository.saveSource(event.source);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(const IncomeSourcesLoaded());
    }
  }

  Future<void> _onDeleted(IncomeSourceDeleted event, Emitter<IncomeSourceState> emit) async {
    final result = await _repository.deleteSource(event.id);
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _effectError(failure)));
      case Right():
        add(const IncomeSourcesLoaded());
    }
  }
}
