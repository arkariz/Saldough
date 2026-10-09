import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_state.dart';
import 'package:saldough/shared/category/category.dart';

/// Event Kategori membawa ikon (QA PR #43 F12); hasilnya tersimpan dan
/// termuat lagi lewat repository.
void main() {
  late InMemoryKeyValueStorage storage;
  late CategoryRepositoryImpl repository;

  setUp(() {
    storage = InMemoryKeyValueStorage();
    repository = CategoryRepositoryImpl(storage: storage);
  });
  tearDown(() => ActiveCategories.notifier.value = const []);

  CategoryManagerBloc build() => CategoryManagerBloc(
    repository: repository,
    createCategory: CreateCategory(repository: repository),
  );

  Future<Category> reloaded(String name) async => (await CategoryRepositoryImpl(
    storage: storage,
  ).listCategories()).fold((_) => throw StateError('gagal'), (r) => r.singleWhere((c) => c.name == name));

  blocTest<CategoryManagerBloc, CategoryManagerState>(
    'Added dengan iconKey: kategori baru tersimpan dengan ikonnya',
    build: build,
    act: (bloc) =>
        bloc.add(const CategoryManagerAdded(kind: CategoryKind.expense, name: 'Kucing', iconKey: 'categoryPets')),
    verify: (bloc) async {
      expect(bloc.state.categories.single.iconKey, 'categoryPets');
      expect((await reloaded('Kucing')).iconKey, 'categoryPets');
    },
  );

  blocTest<CategoryManagerBloc, CategoryManagerState>(
    'Renamed dengan iconKey: nama dan ikon berubah; tanpa iconKey ikon lama tetap',
    setUp: () => repository.saveCategory(
      const Category(id: 'u1', kind: CategoryKind.expense, name: 'Kos', iconKey: 'categoryBills'),
    ),
    build: build,
    act: (bloc) async {
      const original = Category(id: 'u1', kind: CategoryKind.expense, name: 'Kos', iconKey: 'categoryBills');
      bloc.add(const CategoryManagerRenamed(category: original, name: 'Kontrakan', iconKey: 'categoryGroceries'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const CategoryManagerRenamed(
          category: Category(id: 'u1', kind: CategoryKind.expense, name: 'Kontrakan', iconKey: 'categoryGroceries'),
          name: 'Rumah',
        ),
      );
    },
    verify: (bloc) async {
      final saved = await reloaded('Rumah');
      expect(saved.iconKey, 'categoryGroceries');
    },
  );
}
