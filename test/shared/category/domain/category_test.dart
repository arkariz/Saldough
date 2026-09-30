import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/data/category_model.dart';

/// Pencocokan, urutan pemilih, dan pembuatan kategori (ADR-026).
void main() {
  const food = Category(id: 'builtin.food', kind: CategoryKind.expense, name: 'Makan & Minum', builtInKey: 'food');
  const salary = Category(id: 'builtin.salary', kind: CategoryKind.income, name: 'Gaji', builtInKey: 'salary');
  const arisan = Category(id: 'u1', kind: CategoryKind.expense, name: 'Arisan', sortOrder: 5);
  const archived = Category(id: 'u2', kind: CategoryKind.expense, name: 'Kos lama', isArchived: true, sortOrder: 1);

  tearDown(() => ActiveCategories.notifier.value = const []);

  group('matchCategory', () {
    test('cocok nama tanpa peduli huruf besar dan spasi', () {
      expect(matchCategory(const [food, arisan], CategoryKind.expense, '  ARISAN '), arisan);
    });

    test('cocok alias kategori bawaan, hanya utuh -- bukan sebagian kalimat', () {
      expect(matchCategory(const [food], CategoryKind.expense, 'ngopi'), food);
      expect(matchCategory(const [food], CategoryKind.expense, 'makan siang di kantor'), isNull);
    });

    test('jenis harus sama', () {
      expect(matchCategory(const [salary], CategoryKind.expense, 'gaji'), isNull);
    });
  });

  test('selectableCategories: aktif sejenis, yang sering dipakai di atas, sisanya urut sortOrder', () {
    final list = selectableCategories(
      const [arisan, archived, food, salary],
      CategoryKind.expense,
      frequentIds: ['u1'],
    );
    expect(list.map((c) => c.id), ['u1', 'builtin.food']);
  });

  test('CategoryModel pulang-pergi JSON tanpa kehilangan field', () {
    const category = Category(
      id: 'x',
      kind: CategoryKind.income,
      name: 'Bonus',
      builtInKey: 'bonus',
      iconKey: 'income',
      isArchived: true,
      sortOrder: 3,
    );
    expect(CategoryModel.fromJson(CategoryModel.fromEntity(category).toJson()).toEntity(), category);
  });

  group('CreateCategory', () {
    late CategoryRepositoryImpl repository;
    late CreateCategory create;

    setUp(() {
      repository = CategoryRepositoryImpl(storage: InMemoryKeyValueStorage());
      create = CreateCategory(repository: repository, clock: () => DateTime.fromMicrosecondsSinceEpoch(42));
    });

    test('membuat kategori baru di urutan terakhir dan memperbarui ActiveCategories', () async {
      await repository.saveCategories(const [food, arisan]);

      final created = (await create(CategoryKind.expense, '  Oleh-oleh ')).getOrElse((_) => throw StateError('x'));

      expect(created.id, 'user.42');
      expect(created.name, 'Oleh-oleh');
      expect(created.sortOrder, 6);
      expect(ActiveCategories.byId('user.42'), created);
    });

    test('nama yang sudah ada dipakai ulang, yang terarsip dipulihkan', () async {
      await repository.saveCategories(const [arisan, archived]);

      expect((await create(CategoryKind.expense, 'arisan')).getOrElse((_) => throw StateError('x')), arisan);
      final restored = (await create(CategoryKind.expense, 'Kos Lama')).getOrElse((_) => throw StateError('x'));
      expect(restored.id, 'u2');
      expect(restored.isArchived, isFalse);
      expect((await repository.listCategories()).getOrElse((_) => const []), hasLength(2));
    });

    test('nama sama beda jenis tetap kategori baru', () async {
      await repository.saveCategories(const [arisan]);
      final created = (await create(CategoryKind.income, 'Arisan')).getOrElse((_) => throw StateError('x'));
      expect(created.kind, CategoryKind.income);
      expect(created.id, isNot('u1'));
    });
  });
}
