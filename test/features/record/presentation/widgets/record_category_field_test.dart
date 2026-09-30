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

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(AppMenuSelectButton<String>));
    await tester.pumpAndSettle();
  }

  group('RecordCategoryField (ADR-026)', () {
    testWidgets('menu menawarkan kategori aktif sejenis dan "Tanpa kategori" -- bukan pemasukan, bukan terarsip', (
      tester,
    ) async {
      await tester.pumpWidget(pumpable());
      expect(find.text(t.record.categoryPlaceholder), findsOneWidget);

      await openMenu(tester);

      expect(find.text('Makan'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Gaji'), findsNothing);
      expect(find.text('Arisan lama'), findsNothing);
      expect(find.text(t.record.categoryNoneLabel), findsOneWidget);
      expect(find.text(t.record.categoryAddLabel), findsNothing, reason: 'tanpa onCreate');
    });

    testWidgets('kategori yang sering dipakai tampil paling atas', (tester) async {
      await tester.pumpWidget(pumpable(frequentIds: const ['transport']));
      await openMenu(tester);

      final transportY = tester.getTopLeft(find.text('Transport')).dy;
      final foodY = tester.getTopLeft(find.text('Makan')).dy;
      expect(transportY, lessThan(foodY));
    });

    testWidgets('memilih kategori mengirim id-nya; tombol menampilkan nama dan ikonnya', (tester) async {
      String? picked;
      await tester.pumpWidget(pumpable(onChanged: (id) => picked = id));
      await openMenu(tester);
      await tester.tap(find.text('Makan'));
      await tester.pumpAndSettle();
      expect(picked, 'food');

      await tester.pumpWidget(pumpable(value: 'food'));
      expect(
        find.descendant(
          of: find.byType(AppMenuSelectButton<String>),
          matching: find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == IconKey.categoryFood),
        ),
        findsOneWidget,
      );
      expect(find.text('Makan'), findsOneWidget);
    });

    testWidgets('"Tanpa kategori" mengirim null', (tester) async {
      String? picked = 'food';
      await tester.pumpWidget(pumpable(value: 'food', onChanged: (id) => picked = id));
      await openMenu(tester);
      await tester.tap(find.text(t.record.categoryNoneLabel));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });

    testWidgets('kategori terarsip yang sedang terpilih (mode sunting) tetap tampil namanya', (tester) async {
      await tester.pumpWidget(pumpable(value: 'old'));
      expect(find.text('Arisan lama'), findsOneWidget);
    });

    testWidgets('"Tambah kategori" menanyakan nama, membuatnya, lalu memilihnya', (tester) async {
      String? picked;
      String? createdName;
      await tester.pumpWidget(
        pumpable(
          onChanged: (id) => picked = id,
          onCreate: (name) async {
            createdName = name;
            return Category(id: 'new', kind: CategoryKind.expense, name: name);
          },
        ),
      );
      await openMenu(tester);
      await tester.tap(find.text(t.record.categoryAddLabel));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Oleh-oleh  ');
      await tester.pump();
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();

      expect(createdName, 'Oleh-oleh');
      expect(picked, 'new');
    });

    testWidgets('membatalkan dialog nama tidak membuat apa pun', (tester) async {
      var created = false;
      await tester.pumpWidget(
        pumpable(
          onCreate: (name) async {
            created = true;
            return null;
          },
        ),
      );
      await openMenu(tester);
      await tester.tap(find.text(t.record.categoryAddLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();

      expect(created, isFalse);
    });
  });
}
