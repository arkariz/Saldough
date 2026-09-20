import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';

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
    testWidgets('menampilkan pintasan Hari Ini / Kemarin dan tanggal beserta jamnya', (tester) async {
      await pump(tester);

      expect(find.text(t.transaction.todayLabel), findsOneWidget);
      expect(find.text(t.transaction.yesterdayLabel), findsOneWidget);
      expect(find.textContaining('14:20'), findsOneWidget);
    });

    testWidgets('pintasan Hari Ini dan Kemarin sebaris, tidak bertumpuk vertikal', (tester) async {
      await pump(tester);

      final today = tester.getTopLeft(find.text(t.transaction.todayLabel)).dy;
      final yesterday = tester.getTopLeft(find.text(t.transaction.yesterdayLabel)).dy;
      expect(today, yesterday);
    });

    testWidgets('"Kemarin" menggeser hari ke kemarin dan mempertahankan jam', (tester) async {
      final changes = await pump(tester);

      await tester.tap(find.text(t.transaction.yesterdayLabel));

      final yesterday = DateTime(today.year, today.month, today.day - 1, 14, 20);
      expect(changes, [yesterday]);
    });

    testWidgets('"Hari Ini" dari tanggal lampau kembali ke hari ini dengan jam yang sama', (tester) async {
      final past = DateTime(2024, 10, 26, 9, 5);
      final changes = await pump(tester, date: past);

      await tester.tap(find.text(t.transaction.todayLabel));

      expect(changes, [DateTime(today.year, today.month, today.day, 9, 5)]);
    });

    testWidgets('mengetuk kotak tanggal membuka pemilih tanggal', (tester) async {
      await pump(tester);

      await tester.tap(find.textContaining('14:20'));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('layar 360px + teks 2x: pintasan dan kotak tanggal tidak overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await pump(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
