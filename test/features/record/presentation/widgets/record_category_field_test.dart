import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';

void main() {
  group('RecordCategoryField', () {
    testWidgets('mengetuk chip saran mengisi field teks', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordCategoryField(controller: controller, suggestions: const ['Makan', 'Transport']),
          ),
        ),
      );

      await tester.tap(find.text('Makan'));
      await tester.pump();

      expect(controller.text, 'Makan');
    });

    testWidgets('nilai tetap teks bebas -- mengetik selain saran tetap diterima', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordCategoryField(controller: controller, suggestions: const ['Makan', 'Transport']),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Oleh-oleh liburan');
      await tester.pump();

      expect(controller.text, 'Oleh-oleh liburan');
    });
  });
}
