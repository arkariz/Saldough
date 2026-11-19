import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/wallet/presentation/bloc/wealth_history_bloc.dart';
import 'package:saldough/features/wallet/presentation/pages/wealth_history_page.dart';
import 'package:saldough/shared/savings_goal/savings_goal.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:state_management/state_management.dart';

import '../../../../helpers/reduced_motion.dart';

/// Layar Riwayat kekayaan (B-100): batas Gratis, keadaan kosong, dan teks besar
/// tanpa meluap.
void main() {
  final now = DateTime(2026, 11, 19, 12);

  Future<WealthHistoryBloc> bloc({required bool plus, required int months}) async {
    final storage = InMemoryKeyValueStorage();
    final wallets = WalletRepositoryImpl(storage: storage);
    final transactions = TransactionRepositoryImpl(storage: storage);
    await wallets.saveWallet(
      Wallet(
        id: 'a',
        name: 'A',
        iconKey: 'walletBank',
        initialBalance: 1000000,
        currentBalance: 1000000,
        createdAt: DateTime(2026, 11 - months + 1),
      ),
    );
    for (var i = 0; i < months; i++) {
      await transactions.saveTransaction(
        IncomeTransaction(
          id: 'i$i',
          date: DateTime(2026, 11 - months + 1 + i, 10),
          amount: 100000,
          note: '',
          walletId: 'a',
        ),
      );
    }
    return WealthHistoryBloc(
      walletRepository: wallets,
      transactionRepository: transactions,
      goalRepository: SavingsGoalRepositoryImpl(storage: storage),
      schedule: () => FinancialMonthSchedule.initial,
      isPlus: () => plus,
      freePeriods: () => 6,
      now: () => now,
    )..add(const WealthHistoryStarted());
  }

  Future<void> pump(WidgetTester tester, WealthHistoryBloc b, {double scale = 1, double width = 360}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
          child: reducedMotion(context, child),
        ),
        theme: AppThemeBridge.build(DsThemePresets.fallback, Brightness.light),
        home: BlocProvider.value(value: b, child: const WealthHistoryPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Gratis dengan 8 periode: grafik 6 periode dan kartu Plus', (tester) async {
    await tester.runAsync(() async {
      final b = await bloc(plus: false, months: 8);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await pump(tester, b);
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wealth-chart-card')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const ValueKey('wealth-locked')), 300);
    expect(find.text(t.assets.wealth.lockedTitle), findsOneWidget);
  });

  testWidgets('Plus: tanpa kartu Plus', (tester) async {
    await tester.runAsync(() async {
      final b = await bloc(plus: true, months: 8);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await pump(tester, b);
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wealth-locked')), findsNothing);
  });

  testWidgets('satu periode saja: keadaan kosong', (tester) async {
    await tester.runAsync(() async {
      final b = await bloc(plus: true, months: 1);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await pump(tester, b);
    });
    await tester.pumpAndSettle();
    expect(find.text(t.assets.wealth.emptyTitle), findsOneWidget);
  });

  testWidgets('teks 1,8x di 320dp: tanpa overflow', (tester) async {
    await tester.runAsync(() async {
      final b = await bloc(plus: false, months: 8);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await pump(tester, b, scale: 1.8, width: 320);
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('wealth-change-card')), findsOneWidget);
  });
}
