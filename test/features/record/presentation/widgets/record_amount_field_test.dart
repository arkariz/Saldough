import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';

void main() {
  group('RecordAmountField -- formatter pemisah ribuan', () {
    testWidgets('digit yang diketik dirender berpemisah titik ribuan', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: RecordAmountField(controller: controller, label: 'Nominal'))),
      );

      await tester.enterText(find.byType(TextField), '5000000');
      await tester.pump();

      expect(controller.text, '5.000.000');
      expect(parseRecordAmount(controller.text), 5000000);
    });

    testWidgets('chip pilihan cepat menambah ke nilai yang sudah terurai, lalu memformat ulang', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecordAmountField(controller: controller, label: 'Nominal', quickAmounts: const [10000, 50000]),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '20000');
      await tester.pump();
      expect(controller.text, '20.000');

      await tester.tap(find.text('+Rp10.000'));
      await tester.pump();

      expect(controller.text, '30.000');
      expect(parseRecordAmount(controller.text), 30000);
    });
  });

  group('parseRecordAmount', () {
    test('membaca balik teks berpemisah ribuan jadi int rupiah', () {
      expect(parseRecordAmount('5.000.000'), 5000000);
    });

    test('mengembalikan null untuk teks kosong, nol, atau negatif', () {
      expect(parseRecordAmount(''), isNull);
      expect(parseRecordAmount('0'), isNull);
    });
  });
}
