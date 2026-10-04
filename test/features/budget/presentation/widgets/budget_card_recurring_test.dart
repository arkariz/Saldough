import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_card.dart';

/// Lencana Rutin di kartu anggaran (T-16.16 K6).
void main() {
  Future<void> pump(WidgetTester tester, {required bool recurring}) => tester.pumpWidget(
    MaterialApp(
      theme: PixelTheme.light,
      home: Scaffold(
        body: BudgetCard(
          budget: Budget(
            id: 'b',
            name: 'Harian',
            walletId: 'bca',
            period: BudgetPeriod.monthly,
            startDate: DateTime(2026, 10),
          ),
          progress: const BudgetProgress(
            plannedAmount: 0,
            spent: 0,
            status: BudgetStatus.active,
            spendingStatus: BudgetItemStatus.planned,
            items: [],
          ),
          walletName: 'BCA',
          onTap: () {},
          isRecurring: recurring,
        ),
      ),
    ),
  );

  testWidgets('anggaran rutin berlencana Rutin; anggaran biasa tidak', (tester) async {
    await pump(tester, recurring: true);
    expect(find.byKey(const ValueKey('budget-recurring-badge')), findsOneWidget);
    await pump(tester, recurring: false);
    expect(find.byKey(const ValueKey('budget-recurring-badge')), findsNothing);
  });
}
