import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/features/account/presentation/pages/category_page.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';

/// Layar Kategori: tambah dan ubah kategori dengan ikon (QA PR #43 F12).
void main() {
  late CategoryRepositoryImpl repository;
  late CategoryManagerBloc bloc;

  // Repository dan bloc dibuat di dalam zona uji (bukan `setUp`), supaya
  // kerjanya maju bersama `pump`.
  void create() {
    repository = CategoryRepositoryImpl(storage: InMemoryKeyValueStorage());
    bloc = CategoryManagerBloc(
      repository: repository,
      createCategory: CreateCategory(repository: repository),
    );
    addTearDown(bloc.close);
    addTearDown(() => ActiveCategories.notifier.value = const []);
  }

  Future<List<Category>> stored() async => (await repository.listCategories()).fold((_) => [], (r) => r);

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(onPressed: () => openCategoryPage(context, bloc), child: const Text('open')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('tambah: nama dan ikon pilihan tersimpan', (tester) async {
    create();
    await pump(tester);
    await tester.tap(find.text(t.category.addAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('category-form-name')), 'Kucing');
    await tester.pump();
    final pets = find.byKey(const ValueKey('category-icon-categoryPets'));
    await tester.ensureVisible(pets);
    await tester.tap(pets);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('category-form-save')));
    await tester.pumpAndSettle();

    final created = (await stored()).singleWhere((c) => c.name == 'Kucing');
    expect(created.iconKey, 'categoryPets');
    expect(find.byWidgetPredicate((w) => w is AppIconTile && w.icon == IconKey.categoryPets), findsOneWidget);
  });

  testWidgets('tambah tanpa memilih ikon: iconKey kosong, ikon ditebak dari nama', (tester) async {
    create();
    await pump(tester);
    await tester.tap(find.text(t.category.addAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('category-form-name')), 'Ngopi');
    await tester.pump();
    // Pratinjau tile mengikuti tebakan nama.
    expect(find.byWidgetPredicate((w) => w is AppIconTile && w.icon == IconKey.categoryCoffee), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('category-form-save')));
    await tester.pumpAndSettle();
    expect((await stored()).singleWhere((c) => c.name == 'Ngopi').iconKey, isNull);
  });

  testWidgets('ubah kategori bawaan: ikon baru tersimpan, nama tetap', (tester) async {
    create();
    const food = Category(
      id: 'builtin.food',
      kind: CategoryKind.expense,
      name: 'Makan & Minum',
      builtInKey: 'food',
      iconKey: 'categoryFood',
    );
    await repository.saveCategory(food);
    await pump(tester);
    await tester.tap(find.text('Makan & Minum'));
    await tester.pumpAndSettle();
    expect(find.text(t.category.renameTitle), findsOneWidget);
    final coffee = find.byKey(const ValueKey('category-icon-categoryCoffee'));
    await tester.ensureVisible(coffee);
    await tester.tap(coffee);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('category-form-save')));
    await tester.pumpAndSettle();

    final saved = (await stored()).single;
    expect(saved.name, 'Makan & Minum');
    expect(saved.iconKey, 'categoryCoffee');
    expect(categoryIcon(saved), IconKey.categoryCoffee);
  });
}
