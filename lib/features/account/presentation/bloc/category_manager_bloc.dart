import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_state.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:state_management/state_management.dart';

part 'category_manager_event.dart';

/// Bloc layar Kategori (ADR-026 §3.6): daftar per jenis, tambah, ganti nama,
/// arsipkan dan pulihkan. Kategori tidak pernah dihapus.
final class CategoryManagerBloc extends Bloc<CategoryManagerEvent, CategoryManagerState> {
  /// Membuat [CategoryManagerBloc].
  CategoryManagerBloc({required this._repository, required this._createCategory})
    : super(const CategoryManagerState(categories: [], isLoading: true)) {
    on<CategoryManagerStarted>(_onStarted);
    on<CategoryManagerAdded>(_onAdded);
    on<CategoryManagerRenamed>(_onRenamed);
    on<CategoryManagerArchiveToggled>(_onArchiveToggled);
  }

  final CategoryRepository _repository;
  final CreateCategory _createCategory;

  Future<void> _onStarted(CategoryManagerStarted event, Emitter<CategoryManagerState> emit) async {
    await _reload(emit);
  }

  Future<void> _onAdded(CategoryManagerAdded event, Emitter<CategoryManagerState> emit) async {
    switch (await _createCategory(event.kind, event.name)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        await _reload(emit);
    }
  }

  Future<void> _onRenamed(CategoryManagerRenamed event, Emitter<CategoryManagerState> emit) async {
    await _save(event.category.copyWith(name: event.name.trim()), emit);
  }

  Future<void> _onArchiveToggled(CategoryManagerArchiveToggled event, Emitter<CategoryManagerState> emit) async {
    final archived = !event.category.isArchived;
    await _save(
      event.category.copyWith(isArchived: archived),
      emit,
      message: archived
          ? t.category.archivedMessage(name: event.category.name)
          : t.category.restoredMessage(name: event.category.name),
    );
  }

  Future<void> _save(Category category, Emitter<CategoryManagerState> emit, {String? message}) async {
    switch (await _repository.saveCategory(category)) {
      case Left(value: final failure):
        emit(state.copyWith(effect: _error(failure)));
      case Right():
        await _reload(emit, message: message);
    }
  }

  Future<void> _reload(Emitter<CategoryManagerState> emit, {String? message}) async {
    switch (await _repository.listCategories()) {
      case Left(value: final failure):
        emit(state.copyWith(isLoading: false, effect: _error(failure)));
      case Right(value: final categories):
        final sorted = [...categories]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        emit(
          state.copyWith(
            categories: sorted,
            isLoading: false,
            effect: message == null ? null : ShowSnackBarEffect(message: message, severity: .success),
          ),
        );
    }
  }

  UiEffect _error(Failure failure) =>
      ShowSnackBarEffect(message: failure.userMessage ?? t.common.genericErrorMessage, severity: .error);
}
