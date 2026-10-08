import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';

/// Baris Tanggal Catat (T-14.5): "Hari ini, 14.20", diketuk membuka pemilih.
void main() {
  // 14:20 hari ini: jamnya tetap sama saat harinya digeser.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 14, 20);

  Future<List<DateTime>> pump(WidgetTester tester, {DateTime? date}) async {
    final changes = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecordDateField(date: date ?? today, kind: TransactionKind.expense, onChanged: changes.add),
        ),
      ),
    );
    return changes;
  }

  group('RecordDateField', () {
    testWidgets('label Tanggal di atas "Hari ini, 14.20" (jam bertitik)', (tester) async {
      await pump(tester);

      expect(find.text(t.record.dateFieldLabel), findsOneWidget);
      expect(find.text('${t.transaction.todayLabel}, 14.20'), findsOneWidget);
    });

    testWidgets('kemarin ditulis "Kemarin", hari lain tanggal singkat', (tester) async {
      await pump(tester, date: today.subtract(const Duration(days: 1)));
      expect(find.text('${t.transaction.yesterdayLabel}, 14.20'), findsOneWidget);

      await pump(tester, date: today.subtract(const Duration(days: 9)));
      expect(find.textContaining(t.transaction.todayLabel), findsNothing);
      expect(find.textContaining('14.20'), findsOneWidget);
    });

    testWidgets('mengetuk baris membuka pemilih tanggal; jam dipertahankan', (tester) async {
      final changes = await pump(tester);

      await tester.tap(find.byKey(const ValueKey('record-date')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);

      await tester.tap(find.text('1'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(changes.single.day, 1);
      expect((changes.single.hour, changes.single.minute), (14, 20));
    });
  });
}
