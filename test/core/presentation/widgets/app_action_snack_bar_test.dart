import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

void main() {
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                actionSnackBar(
                  context,
                  content: const Text('Terhapus'),
                  action: SnackBarAction(label: 'Urungkan', onPressed: () {}),
                ),
              ),
              child: const Text('tampil'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('tampil'));
    await tester.pumpAndSettle();
  }

  testWidgets('snackbar ber-aksi hilang sendiri sesudah durasinya', (tester) async {
    await show(tester);
    expect(find.text('Urungkan'), findsOneWidget);
    await tester.pump(actionSnackBarDuration - const Duration(seconds: 1));
    expect(find.text('Urungkan'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Terhapus'), findsNothing);
  });

  testWidgets('dengan pembaca layar aktif, snackbar ber-aksi tetap ditahan', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      accessibleNavigation: true,
    );
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await show(tester);
    await tester.pump(actionSnackBarDuration * 2);
    await tester.pumpAndSettle();
    expect(find.text('Terhapus'), findsOneWidget);
  });
}
