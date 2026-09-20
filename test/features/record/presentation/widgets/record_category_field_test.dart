import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';

void main() {
  Widget pumpable(TextEditingController controller, {List<String> suggestions = const ['Makan', 'Transport']}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecordCategoryField(controller: controller, suggestions: suggestions, kind: TransactionKind.expense),
        ),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(AppMenuSelectButton<String>));
    await tester.pumpAndSettle();
  }

  group('RecordCategoryField (dropdown)', () {
    testWidgets('tombol menampilkan ajakan memilih; menu menawarkan saran, Lainnya, dan Tanpa kategori', (
      tester,
    ) async {
      await tester.pumpWidget(pumpable(TextEditingController()));
      expect(find.text(t.record.categoryPlaceholder), findsOneWidget);

      await openMenu(tester);

      expect(find.text('Makan'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text(t.record.categoryOtherLabel), findsOneWidget);
      expect(find.text(t.record.categoryNoneLabel), findsOneWidget);
    });

    testWidgets('memilih saran mengisi kategori dan tombol menampilkannya dengan ikonnya', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(pumpable(controller));

      await openMenu(tester);
      await tester.tap(find.text('Makan'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Makan');
      expect(find.text('Makan'), findsOneWidget, reason: 'label tombol, menu sudah tertutup');
      expect(
        find.descendant(
          of: find.byType(AppMenuSelectButton<String>),
          matching: find.byWidgetPredicate((w) => w is AppIcon && w.iconKey == categoryIconFor('Makan')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('memilih saran lain menggantikan pilihan sebelumnya', (tester) async {
      final controller = TextEditingController(text: 'Makan');
      await tester.pumpWidget(pumpable(controller));

      await openMenu(tester);
      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Transport');
    });

    testWidgets('"Tanpa kategori" mengosongkan kategori (opsional)', (tester) async {
      final controller = TextEditingController(text: 'Makan');
      await tester.pumpWidget(pumpable(controller));

      await openMenu(tester);
      await tester.tap(find.text(t.record.categoryNoneLabel));
      await tester.pumpAndSettle();

      expect(controller.text, isEmpty);
      expect(find.text(t.record.categoryPlaceholder), findsOneWidget);
    });

    testWidgets('kolom ketik tersembunyi sampai "Lainnya" dipilih', (tester) async {
      await tester.pumpWidget(pumpable(TextEditingController()));
      expect(find.byType(TextField), findsNothing);

      await openMenu(tester);
      await tester.tap(find.text(t.record.categoryOtherLabel));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('nilai tetap teks bebas -- mengetik selain saran tetap diterima dan tampil di tombol', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(pumpable(controller));

      await openMenu(tester);
      await tester.tap(find.text(t.record.categoryOtherLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Oleh-oleh liburan');
      await tester.pump();

      expect(controller.text, 'Oleh-oleh liburan');
      expect(
        find.descendant(of: find.byType(AppMenuSelectButton<String>), matching: find.text('Oleh-oleh liburan')),
        findsOneWidget,
      );
    });

    testWidgets('kategori kustom yang sudah ada (mode sunting) langsung membuka kolom ketik', (tester) async {
      final controller = TextEditingController(text: 'Oleh-oleh liburan');
      await tester.pumpWidget(pumpable(controller));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('memilih saran atau "Tanpa kategori" menutup kolom ketik kustom', (tester) async {
      final controller = TextEditingController(text: 'Oleh-oleh liburan');
      await tester.pumpWidget(pumpable(controller));
      expect(find.byType(TextField), findsOneWidget);

      await openMenu(tester);
      await tester.tap(find.text('Makan'));
      await tester.pumpAndSettle();

      expect(controller.text, 'Makan');
      expect(find.byType(TextField), findsNothing);
    });
  });
}
