import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';
import 'package:saldough/shared/category/category.dart';

void main() {
  const food = Category(id: 'food', kind: CategoryKind.expense, name: 'Makan', iconKey: 'categoryFood');
  const transport = Category(id: 'transport', kind: CategoryKind.expense, name: 'Transport', sortOrder: 1);
  const salary = Category(id: 'salary', kind: CategoryKind.income, name: 'Gaji', sortOrder: 2);
  const oldCategory = Category(
    id: 'old',
    kind: CategoryKind.expense,
    name: 'Arisan lama',
    isArchived: true,
    sortOrder: 3,
  );

  setUp(() {
    ActiveCategories.notifier.value = const [food, transport, salary, oldCategory];
    addTearDown(() => ActiveCategories.notifier.value = const []);
  });

  Widget pumpable({
    String? value,
    ValueChanged<String?>? onChanged,
    List<String> frequentIds = const [],
    Future<Category?> Function(String name)? onCreate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecordCategoryField(
            value: value,
            onChanged: onChanged ?? (_) {},
            categoryKind: CategoryKind.expense,
            frequentIds: frequentIds,
            onCreate: onCreate,
          ),
        ),
      ),
    );
  }

  Future<void> openAll(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('category-all')));
    await tester.pumpAndSettle();
  }

  group('RecordCategoryField (ADR-026, T-14.5)', () {
    testWidgets('petak menampilkan kategori aktif sejenis dan "Semua kategori" -- bukan pemasukan, bukan terarsip', (
      tester,
    ) async {
      await tester.pumpWidget(pumpable());

      expect(find.text('Makan'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Gaji'), findsNothing);
      expect(find.text('Arisan lama'), findsNothing);
      expect(find.text(t.record.allCategories), findsOneWidget);
      expect(find.byType(AppIconTile), findsNWidgets(3));
    });

    testWidgets('kategori yang sering dipakai tampil paling depan', (tester) async {
      await tester.pumpWidget(pumpable(frequentIds: const ['transport']));

      expect(tester.getTopLeft(find.text('Transport')).dx, lessThan(tester.getTopLeft(find.text('Makan')).dx));
    });

    testWidgets('mengetuk kategori mengirim id-nya; yang terpilih ditandai, ketuk lagi melepasnya', (tester) async {
      final picked = <String?>[];
      await tester.pumpWidget(pumpable(onChanged: picked.add));
      await tester.tap(find.text('Makan'));
      expect(picked, ['food']);

      await tester.pumpWidget(pumpable(value: 'food', onChanged: picked.add));
      expect(tester.widget<AppIconTile>(find.byType(AppIconTile).first).selected, isTrue);
      expect(tester.getSemantics(find.byKey(const ValueKey('category-food'))), isSemantics(isSelected: true));
      await tester.tap(find.text('Makan'));
      expect(picked.last, isNull);
    });

    testWidgets('kategori terpilih yang terarsip tetap tampil di petak', (tester) async {
      await tester.pumpWidget(pumpable(value: 'old'));
      expect(find.text('Arisan lama'), findsOneWidget);
    });

    testWidgets('"Semua kategori" membuka sheet: memilih kategori dan "Tanpa kategori"', (tester) async {
      final picked = <String?>[];
      await tester.pumpWidget(pumpable(value: 'food', onChanged: picked.add));
      await openAll(tester);

      expect(find.text(t.record.categoryNoneLabel), findsOneWidget);
      expect(find.byKey(const ValueKey('category-sheet-transport')), findsOneWidget);
      expect(find.byKey(const ValueKey('category-sheet-old')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('category-sheet-transport')));
      await tester.pumpAndSettle();
      expect(picked, ['transport']);

      await openAll(tester);
      await tester.tap(find.text(t.record.categoryNoneLabel));
      await tester.pumpAndSettle();
      expect(picked.last, isNull);
    });

    testWidgets('"Tambah kategori" menanyakan nama, membuatnya, lalu memilihnya', (tester) async {
      const created = Category(id: 'new', kind: CategoryKind.expense, name: 'Arisan');
      final names = <String>[];
      final picked = <String?>[];
      await tester.pumpWidget(
        pumpable(
          onChanged: picked.add,
          onCreate: (name) async {
            names.add(name);
            return created;
          },
        ),
      );
      await openAll(tester);
      await tester.tap(find.text(t.record.categoryAddLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Arisan');
      await tester.pump();
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(names, ['Arisan']);
      expect(picked, ['new']);
    });

    testWidgets('membatalkan dialog nama tidak membuat apa pun', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        pumpable(
          onCreate: (name) async {
            calls++;
            return null;
          },
        ),
      );
      await openAll(tester);
      await tester.tap(find.text(t.record.categoryAddLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}
