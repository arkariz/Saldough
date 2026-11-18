import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/shared/category/category.dart';

/// ADR-049 §3.8: pengguna lama mendapat kategori bawaan Investasi tanpa
/// mengubah kategori yang sudah ada.
void main() {
  test('menambah kategori bawaan yang belum ada, sekali, di belakang urutan', () async {
    final repo = CategoryRepositoryImpl(storage: InMemoryKeyValueStorage());
    final old = [
      for (final (i, b) in BuiltInCategories.all.indexed)
        if (b.key != 'investment')
          Category(id: b.id, kind: b.kind, name: b.key, builtInKey: b.key, iconKey: b.iconKey, sortOrder: i),
    ];
    await repo.saveCategories([...old.take(3), old[3].copyWith(isArchived: true, name: 'Diubah'), ...old.skip(4)]);
    final add = AddMissingBuiltInCategories(categoryRepository: repo);
    await add(builtInName: (k) => 'Nama $k');
    await add(builtInName: (k) => 'Nama $k');
    final stored = (await repo.listCategories()).getOrElse((_) => const []);
    final investment = stored.where((c) => c.builtInKey == 'investment').toList();
    expect(investment, hasLength(1));
    expect(investment.single.name, 'Nama investment');
    expect(investment.single.kind, CategoryKind.income);
    expect(investment.single.sortOrder, greaterThan(old.length - 1));
    expect(stored.firstWhere((c) => c.id == old[3].id).name, 'Diubah');
  });

  test('tanpa kategori tersimpan tidak melakukan apa-apa (migrasi ADR-026 yang mengisi)', () async {
    final repo = CategoryRepositoryImpl(storage: InMemoryKeyValueStorage());
    await AddMissingBuiltInCategories(categoryRepository: repo)(builtInName: (k) => k);
    expect((await repo.listCategories()).getOrElse((_) => const []), isEmpty);
  });
}
