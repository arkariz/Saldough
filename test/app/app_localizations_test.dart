import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Komponen bawaan Flutter ikut berbahasa Indonesia (NFR-UX-004, UX-5).
void main() {
  testWidgets('pemilih tanggal berbahasa Indonesia di locale id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: AppLocale.id.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: SaldoughApp.localizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 9, 15),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(find.textContaining('September'), findsWidgets);
  });
}
