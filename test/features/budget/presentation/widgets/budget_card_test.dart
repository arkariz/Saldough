import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/features/budget/domain/entities/budget.dart';
import 'package:saldough/features/budget/domain/entities/budget_item_status.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/features/budget/domain/usecases/calculate_budget_progress.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_card.dart';

/// Kartu anggaran v2: meter bernada menurut ambang, penanda waktu hanya untuk
/// anggaran berjalan, dan tanpa luap di 360dp dengan teks 200%.
void main() {
  BudgetProgress progress({
    required int planned,
    required int spent,
    BudgetStatus status = BudgetStatus.active,
    BudgetItemStatus spending = BudgetItemStatus.partiallySpent,
  }) => BudgetProgress(plannedAmount: planned, spent: spent, status: status, spendingStatus: spending, items: const []);

  Future<void> pump(WidgetTester tester, BudgetProgress progress, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: BudgetCard(
              budget: Budget(
                id: 'b',
                name: 'Belanja bulanan keluarga besar',
                walletId: 'bca',
                period: BudgetPeriod.monthly,
                startDate: DateTime(2026, 10),
              ),
              progress: progress,
              walletName: 'BCA Tabungan Utama',
              onTap: () {},
            ),
          ),
        ),
      ),
    );
  }

  DsMeterTone toneOf(WidgetTester tester) => tester.widget<DsSegmentMeter>(find.byType(DsSegmentMeter)).tone;

  testWidgets('nada meter mengikuti ambang 85% dan 100%', (tester) async {
    await pump(tester, progress(planned: 100000, spent: 50000));
    expect(toneOf(tester), DsMeterTone.normal);
    await pump(tester, progress(planned: 100000, spent: 90000));
    expect(toneOf(tester), DsMeterTone.warning);
    await pump(tester, progress(planned: 100000, spent: 120000, spending: BudgetItemStatus.overspent));
    expect(toneOf(tester), DsMeterTone.danger);
  });

  testWidgets('penanda waktu hanya untuk anggaran yang sedang berjalan', (tester) async {
    await pump(tester, progress(planned: 100000, spent: 10000));
    expect(tester.widget<DsSegmentMeter>(find.byType(DsSegmentMeter)).pace, isNotNull);
    await pump(tester, progress(planned: 100000, spent: 10000, status: BudgetStatus.finished));
    expect(tester.widget<DsSegmentMeter>(find.byType(DsSegmentMeter)).pace, isNull);
  });

  testWidgets('muat di 360dp dengan teks 200% untuk anggaran lewat batas', (tester) async {
    await pump(
      tester,
      progress(planned: 1500000000, spent: 1800000000, spending: BudgetItemStatus.overspent),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
