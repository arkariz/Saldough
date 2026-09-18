import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';

void main() {
  group('AppChip', () {
    testWidgets('tanpa icon -- hanya menampilkan label, tidak merender AppIcon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppChip(label: 'Makan'))),
      );

      expect(find.text('Makan'), findsOneWidget);
      expect(find.byType(AppIcon), findsNothing);
    });

    testWidgets('dengan icon -- merender AppIcon di samping label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppChip(label: 'Makan', icon: IconKey.categoryFood))),
      );

      expect(find.text('Makan'), findsOneWidget);
      expect(find.byType(AppIcon), findsOneWidget);
      final icon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(icon.iconKey, IconKey.categoryFood);
    });

    testWidgets('selected true tetap merender icon bersama label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppChip(label: 'Transport', icon: IconKey.categoryTransport, selected: true)),
        ),
      );

      expect(find.text('Transport'), findsOneWidget);
      expect(find.byType(AppIcon), findsOneWidget);
    });
  });
}
