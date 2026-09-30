import 'package:saldough/shared/category/category.dart';
import 'package:state_management/state_management.dart';

/// State [CategoryManagerBloc].
final class CategoryManagerState extends UiState<CategoryManagerState> {
  /// Membuat [CategoryManagerState].
  const CategoryManagerState({required this.categories, required this.isLoading, super.effect});

  /// Seluruh kategori, aktif maupun terarsip, urut `sortOrder`.
  final List<Category> categories;

  /// Sedang memuat daftar pertama kali.
  final bool isLoading;

  /// Kategori berjenis [kind], dipisah aktif dan terarsip.
  ({List<Category> active, List<Category> archived}) ofKind(CategoryKind kind) => (
    active: [
      for (final c in categories)
        if (c.kind == kind && !c.isArchived) c,
    ],
    archived: [
      for (final c in categories)
        if (c.kind == kind && c.isArchived) c,
    ],
  );

  @override
  CategoryManagerState copyWith({List<Category>? categories, bool? isLoading, UiEffect? effect}) {
    return CategoryManagerState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      effect: effect,
    );
  }

  @override
  List<Object?> get props => [categories, isLoading];
}
