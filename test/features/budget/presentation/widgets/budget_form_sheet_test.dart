import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_form_sheet.dart';
import 'package:saldough/shared/wallet/wallet.dart';

void main() {
  const bca = Wallet(id: 'bca', name: 'BCA', iconKey: 'walletBank', initialBalance: 0, currentBalance: 500000000);

  Future<void> pumpForm(WidgetTester tester, {Budget? initial}) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: PixelTheme(
          child: Scaffold(
            body: BudgetFormSheet(wallets: const [bca], initial: initial),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppButton saveButton(WidgetTester tester, String label) =>
      tester.widget<AppButton>(find.widgetWithText(AppButton, label));

  group('BudgetFormSheet (ADR-017)', () {
    testWidgets('tidak ada kolom nominal rencana; tanpa pos, simpan mati dan alasannya tampil', (tester) async {
      await pumpForm(tester);
      await tester.enterText(find.byType(TextField).first, 'Rumah tangga');
      await tester.pump();

      expect(find.text(t.budget.totalPlannedLabel.toUpperCase()), findsOneWidget);
      expect(find.text('Rp0'), findsOneWidget);
      expect(find.text(t.budget.itemsRequiredHint), findsOneWidget);
      expect(saveButton(tester, t.budget.saveAddAction).onPressed, isNull);
    });

    testWidgets('total rencana = jumlah pos', (tester) async {
      await pumpForm(
        tester,
        initial: Budget(
          id: 'b1',
          name: 'Rumah tangga',
          walletId: 'bca',
          period: BudgetPeriod.monthly,
          startDate: DateTime(2026, 9),
          items: const [
            BudgetItem(id: 'mingguan', name: 'Belanja mingguan', quantity: 4, unitPrice: 57660000),
            BudgetItem(id: 'bulanan', name: 'Belanja bulanan', enteredAmount: 76210000),
          ],
        ),
      );

      // 4 × Rp576.600 + Rp762.100 = Rp3.068.500 (DOMAIN_MODEL.md).
      expect(find.text('Rp3.068.500'), findsOneWidget);
      expect(find.text(t.budget.itemsRequiredHint), findsNothing);
      expect(saveButton(tester, t.transaction.saveChangesAction).onPressed, isNotNull);
    });
  });
}
